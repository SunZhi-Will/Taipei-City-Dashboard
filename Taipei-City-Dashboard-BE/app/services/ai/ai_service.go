package ai

import (
	"TaipeiCityDashboardBE/app/models"
	"TaipeiCityDashboardBE/app/services/ai/providers/twcc"
	"TaipeiCityDashboardBE/app/services/ai/tools"
	"TaipeiCityDashboardBE/global"
	"TaipeiCityDashboardBE/logs"
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/tmc/langchaingo/llms"
	"golang.org/x/sync/semaphore"
)

var (
	// aiSemaphore limits the number of concurrent AI requests
	aiSemaphore *semaphore.Weighted
	twccModel   llms.Model
)

func init() {
	aiSemaphore = semaphore.NewWeighted(int64(global.TWCC.MaxConcurrent))
	twccModel = twcc.New(
		global.TWCC.ApiKey,
		global.TWCC.ApiUrl,
		global.TWCC.Model,
		global.TWCC.Timeout,
	)
}

type AIChatRequest struct {
	SessionID string                 `json:"session"`
	AppMode   string                 `json:"app_mode"`
	UserID    string                 `json:"user_id"`
	IPAddress string                 `json:"ip_address"`
	Messages  []llms.MessageContent  `json:"messages"`
	Params    map[string]interface{} `json:"params"`
}

type AgentComponentCandidate struct {
	ID    int64   `json:"id"`
	Index string  `json:"index"`
	Name  string  `json:"name"`
	City  string  `json:"city"`
	Score float64 `json:"score"`
}

type AgentResult struct {
	PrimaryComponent  *AgentComponentCandidate  `json:"primary_component,omitempty"`
	RelatedComponents []AgentComponentCandidate `json:"related_components,omitempty"`
	SelectionReason   string                    `json:"selection_reason"`
	RetrievalType     string                    `json:"retrieval_type,omitempty"`
}

type DisplayPlanSlide struct {
	ID               string `json:"id"`
	Type             string `json:"type"`
	Title            string `json:"title"`
	Summary          string `json:"summary,omitempty"`
	FocusComponentID int64  `json:"focus_component_id,omitempty"`
	ChartType        string `json:"chart_type,omitempty"` // specific chart type to display for this slide
	DurationSec      int    `json:"duration_sec"`
}

type DisplayPlanBlock struct {
	Type             string `json:"type"`
	Title            string `json:"title"`
	Summary          string `json:"summary,omitempty"`
	ComponentID      int64  `json:"component_id,omitempty"`
	ComponentIndex   string `json:"component_index,omitempty"`
	City             string `json:"city,omitempty"`
	ChartType        string `json:"chart_type,omitempty"`
}

type DisplayPlan struct {
	Mode            string             `json:"mode"`
	StrictRender    bool               `json:"strict_render"`
	Style           string             `json:"style"`
	Audience        string             `json:"audience"`
	ChartPreference string             `json:"chart_preference,omitempty"`
	Slides          []DisplayPlanSlide `json:"slides"`
	Blocks          []DisplayPlanBlock `json:"blocks"`
}

type AIChatResult struct {
	Log        *models.AIChatLog    `json:"log"`
	UsedTools  []string             `json:"used_tools"`
	ToolResults map[string]string   `json:"tool_results,omitempty"`
	ToolTimeline []ToolExecution    `json:"tool_timeline,omitempty"`
	AgentResult *AgentResult        `json:"agent_result,omitempty"`
	DisplayPlan *DisplayPlan        `json:"display_plan,omitempty"`
}

type ToolExecution struct {
	Name   string `json:"name"`
	Args   string `json:"args,omitempty"`
	Result string `json:"result,omitempty"`
}

// ChatWithTWCC handles the AI conversation logic including retries, tool calling loop, and logging.
func ChatWithTWCC(ctx context.Context, req AIChatRequest, options ...llms.CallOption) (*AIChatResult, error) {
	if err := aiSemaphore.Acquire(ctx, 1); err != nil {
		return nil, fmt.Errorf("server too busy: %v", err)
	}
	defer aiSemaphore.Release(1)

	session := newSession(req, options...)
	return session.run(ctx)
}

func newSession(req AIChatRequest, options ...llms.CallOption) *aiSession {
	s := &aiSession{
		req:             req,
		options:         options,
		currentMessages: make([]llms.MessageContent, 0),
		toolResults:     make(map[string]string),
		toolTimeline:    make([]ToolExecution, 0),
		startTime:       time.Now(),
	}
	for _, opt := range options {
		opt(&s.callOpts)
	}
	s.injectInstructions()
	return s
}

type aiSession struct {
	req             AIChatRequest
	options         []llms.CallOption
	callOpts        llms.CallOptions
	currentMessages []llms.MessageContent
	totalInput      int
	totalOutput     int
	toolUsed        bool
	executedTools   []string
	toolResults     map[string]string
	toolTimeline    []ToolExecution
	lastResp        *llms.ContentResponse
	lastErr         error
	startTime       time.Time
}

func (s *aiSession) run(ctx context.Context) (*AIChatResult, error) {
	maxLoops := 5
	s.executedTools = make([]string, 0)
	for i := 0; i < maxLoops; i++ {
		s.sendHeartbeat(ctx)

		if err := s.generate(ctx); err != nil {
			break
		}

		toolCalls := s.extractToolCalls()
		if len(toolCalls) == 0 {
			break
		}

		s.toolUsed = true
		logs.FInfo("Loop %d: Processing %d tool calls", i, len(toolCalls))
		if err := s.executeTools(ctx, toolCalls); err != nil {
			break
		}
	}
	return s.finalize()
}

func (s *aiSession) sendHeartbeat(ctx context.Context) {
	if s.callOpts.StreamingFunc != nil {
		s.callOpts.StreamingFunc(ctx, []byte(": heartbeat\n\n"))
	}
}

func (s *aiSession) generate(ctx context.Context) error {
	maxRetry := global.TWCC.MaxRetry
	if s.callOpts.StreamingFunc != nil {
		maxRetry = 0
	}

	for i := 0; i <= maxRetry; i++ {
		s.lastResp, s.lastErr = twccModel.GenerateContent(ctx, s.currentMessages, s.options...)
		if s.lastErr == nil {
			s.updateTokens()
			return nil
		}
		logs.FError("Attempt %d failed: %v", i+1, s.lastErr)
		if i < maxRetry {
			time.Sleep(500 * time.Millisecond)
		}
	}
	return s.lastErr
}

func (s *aiSession) extractToolCalls() []llms.ToolCall {
	if s.lastResp == nil || len(s.lastResp.Choices) == 0 {
		return nil
	}
	tc, _ := s.lastResp.Choices[0].GenerationInfo["tool_calls"].([]llms.ToolCall)
	return tc
}

func (s *aiSession) updateTokens() {
	if s.lastResp == nil || len(s.lastResp.Choices) == 0 {
		return
	}
	if usage, ok := s.lastResp.Choices[0].GenerationInfo["usage"].(map[string]interface{}); ok {
		s.totalInput += parseUsageInt(usage["input_tokens"])
		s.totalOutput += parseUsageInt(usage["output_tokens"])
	}
}

func (s *aiSession) executeTools(ctx context.Context, toolCalls []llms.ToolCall) error {
	choice := s.lastResp.Choices[0]
	
	// Add Assistant's intent
	s.currentMessages = append(s.currentMessages, llms.MessageContent{
		Role:  llms.ChatMessageTypeAI,
		Parts: append([]llms.ContentPart{llms.TextContent{Text: choice.Content}}, toolsToParts(toolCalls)...),
	})

	for _, tc := range toolCalls {
		s.executedTools = append(s.executedTools, tc.FunctionCall.Name)
		result, err := tools.Execute(ctx, tc.FunctionCall.Name, tc.FunctionCall.Arguments)
		if err != nil {
			result = fmt.Sprintf("Error: %v. Please verify arguments.", err)
			logs.FError("Tool Error: %v", err)
		}
		
		// Store tool result for potential extraction
		s.toolResults[tc.FunctionCall.Name] = result
		s.toolTimeline = append(s.toolTimeline, ToolExecution{
			Name: tc.FunctionCall.Name,
			Args: tc.FunctionCall.Arguments,
			Result: result,
		})

		s.currentMessages = append(s.currentMessages, llms.MessageContent{
			Role: llms.ChatMessageTypeTool,
			Parts: []llms.ContentPart{llms.ToolCallResponse{
				ToolCallID: tc.ID, Name: tc.FunctionCall.Name, Content: result,
			}},
		})
	}
	return nil
}

func (s *aiSession) injectInstructions() {
	toolNames := ""
	for i, t := range s.callOpts.Tools {
		if i > 0 { toolNames += ", " }
		toolNames += t.Function.Name
	}

	instruction := fmt.Sprintf("\nSystem Instruction:\n1. Use ONLY: [%s].\n2. NEVER nest tool calls.\n3. Arguments MUST be literal values (strings, integers, etc.), never function calls.\n4. For dependent tasks, call tools sequentially in separate turns.\n5. If stuck, respond with plain text.\n6. 若使用者要求具體數值、最近變化、趨勢比較，必須先呼叫 retrieve_components_by_query 選出元件，再呼叫 get_component_chart_data 取得資料後才能回答；回答時需帶出數值與時間範圍。\n\nStyle Guide:\n- Role: 你是臺北市城市大數據儀表板的智慧助理，回覆對象是一般市民。\n- 語氣：清楚、友善、專業；避免過度口語與過多 emoji。\n- 城市名：只能使用「臺北」或「雙北」，不得出現 metrotaipei 或 taipei 等技術字眼。\n- 組件推薦：若有 2 筆以上結果，使用 Markdown 表格，欄位僅限「排名｜城市名｜組件名」。\n- 表格規範：表格內只能放資料列，禁止把完整句子、提醒語、結語放進表格欄位。\n- 版面規範：表格結束後必須空一行，再用一般段落補充說明。\n- 說明內容：可提示「可加入個人儀表板」與下一步建議，但要放在表格外。\n- 禁忌：不得出現 RAG、tool、score、index、id、主結果、候選、檢索、關聯性、分數、相似度等技術用語。", toolNames)
	
	if s.req.AppMode == "ai_studio" {
		instruction += `
7. Context: AI STUDIO — 戰情室大螢幕播映模式。

你的任務是在回覆末尾輸出一個 JSON 區塊（以 ` + "```json" + ` 包裹），作為輪播展示規劃（display_plan）。

規劃流程（必須遵守）：
① 先呼叫 retrieve_components_by_query 取得組件清單，每個組件包含 chart_types (陣列) 與 has_map (boolean)。
② 分析每個組件的 chart_types：若有多種圖表類型，為「每種類型」各建立一張投影片。
③ 若組件 has_map=true，建立一張 type="map" 的投影片（直接渲染組件的地圖視角）。
④ 純圖表組件建立 type="component" 投影片。
⑤ 不要插入 hero 或 closing 等包裝頁，第一張就是組件內容。
⑥ 投影片數量沒有上限，全部組件及圖表類型都要納入。

display_plan JSON 格式（嚴格遵守）：
{
  "mode": "presentation",
  "strict_render": true,
  "style": "carousel",
  "audience": "war-room",
  "slides": [
    {
      "id": "唯一ID",
      "type": "component" 或 "map",
      "title": "組件名稱（+圖表類型說明）",
      "summary": "一句話說明這張投影片的洞察重點",
      "focus_component_id": 組件ID（整數）,
      "chart_type": "bar|line|percent|map|two_d 等",
      "duration_sec": 12
    }
  ]
}

規則：
- 有 has_map=true 的組件，額外建立 type="map" 投影片，chart_type="map"。
- chart_type 必須從該組件的 chart_types 陣列中選擇實際存在的類型。
- duration_sec 預設 12，重要組件可設 15，地圖 15。
- 回覆文字（說明）放在 JSON 區塊之前，JSON 區塊放在最後。`
	}
	
	s.currentMessages = make([]llms.MessageContent, 0)
	merged := false
	for _, m := range s.req.Messages {
		if m.Role == llms.ChatMessageTypeSystem && !merged {
			s.currentMessages = append(s.currentMessages, mergeSystemMsg(m, instruction))
			merged = true
		} else {
			s.currentMessages = append(s.currentMessages, m)
		}
	}
	
	if !merged {
		s.currentMessages = append([]llms.MessageContent{{
			Role: llms.ChatMessageTypeSystem,
			Parts: []llms.ContentPart{llms.TextContent{Text: instruction}},
		}}, s.currentMessages...)
	}
}

func (s *aiSession) finalize() (*AIChatResult, error) {
	log := &models.AIChatLog{
		SessionID: s.req.SessionID, UserID: s.req.UserID, IPAddress: s.req.IPAddress,
		Provider: "twcc", Model: global.TWCC.Model, LatencyMS: int(time.Since(s.startTime).Milliseconds()),
		Status: "success", Tools: "[]", CreatedAt: s.startTime,
	}

	if len(s.req.Messages) > 0 {
		log.Question = extractText(s.req.Messages[len(s.req.Messages)-1])
	}

	if s.lastErr != nil {
		log.Status, log.ErrorCode, log.ErrorMessage = "error", "MODEL_ERROR", s.lastErr.Error()
		models.CreateAIChatLog(log)
		return &AIChatResult{
			Log:         log,
			UsedTools:   append([]string{}, s.executedTools...),
			ToolResults: copyToolResults(s.toolResults),
			ToolTimeline: copyToolTimeline(s.toolTimeline),
		}, s.lastErr
	}

	if s.lastResp != nil && len(s.lastResp.Choices) > 0 {
		log.Answer = s.lastResp.Choices[0].Content
		log.InputTokens, log.OutputTokens = s.totalInput, s.totalOutput
		log.TotalTokens = s.totalInput + s.totalOutput
		if s.toolUsed {
			log.ToolUsed = true
			if toolJSON, err := json.Marshal(s.executedTools); err == nil {
				log.Tools = string(toolJSON)
			}
		}
	}

	agentResult := buildAgentResult(log.Question, s.latestToolResult("retrieve_components_by_query"))
	rawAnswer := log.Answer
	displayPlan := buildDisplayPlan(log.Question, s.req.AppMode, rawAnswer, agentResult)
	cleanAnswer := stripDisplayPlanFromAnswer(rawAnswer)
	if strings.TrimSpace(cleanAnswer) == "" {
		cleanAnswer = rawAnswer
	}
	log.Answer = cleanAnswer

	if err := models.CreateAIChatLog(log); err != nil {
		logs.FError("DB Log Error: %v", err)
	}

	if displayPlan == nil {
		displayPlan = buildDisplayPlan(log.Question, s.req.AppMode, rawAnswer, agentResult)
	}

	return &AIChatResult{
		Log:         log,
		UsedTools:   append([]string{}, s.executedTools...),
		ToolResults: copyToolResults(s.toolResults),
		ToolTimeline: copyToolTimeline(s.toolTimeline),
		AgentResult: agentResult,
		DisplayPlan: displayPlan,
	}, nil
}

func (s *aiSession) latestToolResult(name string) string {
	for i := len(s.toolTimeline) - 1; i >= 0; i-- {
		if s.toolTimeline[i].Name == name {
			return s.toolTimeline[i].Result
		}
	}
	return ""
}

// stripDisplayPlanFromAnswer removes JSON planning blocks from the user-facing answer.
func stripDisplayPlanFromAnswer(answer string) string {
	text := strings.TrimSpace(answer)
	if text == "" {
		return ""
	}

	idx := strings.Index(text, "```json")
	if idx >= 0 {
		prefix := strings.TrimSpace(text[:idx])
		if prefix != "" {
			return prefix
		}
	}

	modeIdx := strings.Index(text, `"mode"`)
	if modeIdx > 0 {
		start := strings.LastIndex(text[:modeIdx], "{")
		if start >= 0 {
			prefix := strings.TrimSpace(text[:start])
			if prefix != "" {
				return prefix
			}
		}
	}

	return text
}

// extractDisplayPlanJSON parses the AI's response for a display_plan JSON block.
// The AI is instructed to output it as ```json ... ``` at the end of the message.
func extractDisplayPlanJSON(aiAnswer string) *DisplayPlan {
	if aiAnswer == "" {
		return nil
	}
	idx := strings.Index(aiAnswer, "```json")
	if idx == -1 {
		idx = strings.Index(aiAnswer, "```\n{")
	}
	if idx == -1 {
		// Try bare JSON starting with { "mode":
		start := strings.Index(aiAnswer, `"mode"`)
		if start == -1 {
			return nil
		}
		// Walk back to find the opening brace
		for i := start - 1; i >= 0; i-- {
			if aiAnswer[i] == '{' {
				start = i
				break
			}
		}
		end := strings.LastIndex(aiAnswer, "}")
		if end <= start {
			return nil
		}
		return tryParseDisplayPlan(aiAnswer[start : end+1])
	}

	// Extract content between fences
	rest := aiAnswer[idx:]
	openBrace := strings.Index(rest, "{")
	if openBrace == -1 {
		return nil
	}
	closeFence := strings.Index(rest[openBrace:], "```")
	if closeFence == -1 {
		return nil
	}
	jsonStr := rest[openBrace : openBrace+closeFence]
	// Trim trailing whitespace/newlines
	jsonStr = strings.TrimRight(jsonStr, " \t\n\r")
	return tryParseDisplayPlan(jsonStr)
}

func tryParseDisplayPlan(raw string) *DisplayPlan {
	var plan DisplayPlan
	if err := json.Unmarshal([]byte(raw), &plan); err != nil {
		logs.FError("display_plan parse error: %v", err)
		return nil
	}
	if plan.Mode == "" || len(plan.Slides) == 0 {
		return nil
	}
	normalized := normalizeDisplayPlan(plan)
	if len(normalized.Slides) == 0 {
		return nil
	}
	return &normalized
}

func normalizeDisplayPlan(plan DisplayPlan) DisplayPlan {
	if plan.Mode == "" {
		plan.Mode = "presentation"
	}
	if plan.Mode != "presentation" {
		plan.Mode = "presentation"
	}
	if plan.Style == "" {
		plan.Style = "carousel"
	}
	if plan.Audience == "" {
		plan.Audience = "war-room"
	}
	plan.StrictRender = true

	allowedType := map[string]bool{"component": true, "map": true}
	normalizedSlides := make([]DisplayPlanSlide, 0, len(plan.Slides))
	for i, slide := range plan.Slides {
		t := strings.TrimSpace(strings.ToLower(slide.Type))
		if !allowedType[t] {
			if t == "" {
				t = "component"
			} else {
				continue
			}
		}
		slide.Type = t
		if strings.TrimSpace(slide.ID) == "" {
			slide.ID = fmt.Sprintf("slide-%d", i+1)
		}
		if strings.TrimSpace(slide.Title) == "" {
			slide.Title = fmt.Sprintf("投影片 %d", i+1)
		}
		if slide.DurationSec <= 0 {
			slide.DurationSec = 12
		}
		if slide.DurationSec > 30 {
			slide.DurationSec = 30
		}
		if slide.Type == "map" && strings.TrimSpace(slide.ChartType) == "" {
			slide.ChartType = "map"
		}
		normalizedSlides = append(normalizedSlides, slide)
	}
	plan.Slides = normalizedSlides

	if len(plan.Blocks) == 0 {
		for _, s := range plan.Slides {
			plan.Blocks = append(plan.Blocks, DisplayPlanBlock{
				Type:      "component_chart",
				Title:     s.Title,
				ComponentID: s.FocusComponentID,
				ChartType: func() string {
					if s.ChartType != "" {
						return s.ChartType
					}
					if s.Type == "map" {
						return "map"
					}
					return "auto"
				}(),
			})
		}
	}

	return plan
}

func buildDisplayPlan(question string, appMode string, aiAnswer string, agentResult *AgentResult) *DisplayPlan {
	if appMode != "ai_studio" {
		return nil
	}

	// PRIMARY: try to parse AI-generated display_plan from the response
	if aiPlan := extractDisplayPlanJSON(aiAnswer); aiPlan != nil {
		// Ensure sensible defaults
		if aiPlan.Style == "" {
			aiPlan.Style = "carousel"
		}
		if aiPlan.Audience == "" {
			aiPlan.Audience = "war-room"
		}
		aiPlan.StrictRender = true
		// Normalise slide duration and ensure chart_type flows to the slide
		for i := range aiPlan.Slides {
			if aiPlan.Slides[i].DurationSec <= 0 {
				aiPlan.Slides[i].DurationSec = 12
			}
		}
		logs.FInfo("AI display_plan parsed: %d slides", len(aiPlan.Slides))
		return aiPlan
	}

	// FALLBACK: rule-based plan when AI didn't output JSON (e.g. pure Q&A mode)
	logs.FInfo("AI display_plan not found in response, using rule-based fallback")
	questionText := strings.TrimSpace(question)
	slides := make([]DisplayPlanSlide, 0)
	blocks := make([]DisplayPlanBlock, 0)

	if agentResult != nil && agentResult.PrimaryComponent != nil {
		primary := agentResult.PrimaryComponent
		slides = append(slides, DisplayPlanSlide{
			ID: fmt.Sprintf("component-%d", primary.ID), Type: "component",
			Title: primary.Name, Summary: "優先推薦的核心指標",
			FocusComponentID: primary.ID, DurationSec: 12,
		})
		blocks = append(blocks, DisplayPlanBlock{
			Type: "component_chart", Title: primary.Name, Summary: "主視覺圖表",
			ComponentID: primary.ID, ComponentIndex: primary.Index, City: primary.City,
			ChartType: detectChartPreference(questionText),
		})
		for i, related := range agentResult.RelatedComponents {
			if i >= 3 {
				break
			}
			slides = append(slides, DisplayPlanSlide{
				ID: fmt.Sprintf("related-%d", related.ID), Type: "component",
				Title: related.Name, Summary: "延伸比較指標",
				FocusComponentID: related.ID, DurationSec: 12,
			})
			blocks = append(blocks, DisplayPlanBlock{
				Type: "component_chart", Title: related.Name,
				ComponentID: related.ID, ComponentIndex: related.Index, City: related.City,
				ChartType: detectChartPreference(questionText),
			})
		}
	}

	if len(slides) == 0 {
		return nil
	}

	return &DisplayPlan{
		Mode: "presentation", StrictRender: true, Style: "carousel",
		Audience: "war-room", ChartPreference: detectChartPreference(questionText),
		Slides: slides, Blocks: blocks,
	}
}

func detectChartPreference(question string) string {
	q := strings.ToLower(question)
	switch {
	case strings.Contains(q, "長條"), strings.Contains(q, "柱狀"), strings.Contains(q, "bar"):
		return "bar"
	case strings.Contains(q, "折線"), strings.Contains(q, "趨勢"), strings.Contains(q, "line"):
		return "line"
	case strings.Contains(q, "圓餅"), strings.Contains(q, "比例"), strings.Contains(q, "pie"):
		return "pie"
	case strings.Contains(q, "地圖"), strings.Contains(q, "map"):
		return "map"
	default:
		return "auto"
	}
}

func copyToolResults(input map[string]string) map[string]string {
	if len(input) == 0 {
		return map[string]string{}
	}
	out := make(map[string]string, len(input))
	for k, v := range input {
		out[k] = v
	}
	return out
}

func copyToolTimeline(input []ToolExecution) []ToolExecution {
	if len(input) == 0 {
		return []ToolExecution{}
	}
	out := make([]ToolExecution, len(input))
	copy(out, input)
	return out
}

func buildAgentResult(userQuery, rawToolResult string) *AgentResult {
	if strings.TrimSpace(rawToolResult) == "" {
		return nil
	}

	var payload struct {
		Type    string                   `json:"type"`
		Results []map[string]interface{} `json:"results"`
	}
	if err := json.Unmarshal([]byte(rawToolResult), &payload); err != nil {
		return nil
	}
	if len(payload.Results) == 0 {
		return nil
	}

	candidates := make([]AgentComponentCandidate, 0, len(payload.Results))
	for _, item := range payload.Results {
		candidates = append(candidates, AgentComponentCandidate{
			ID:    toInt64(item["id"]),
			Index: toString(item["index"]),
			Name:  toString(item["name"]),
			City:  toString(item["city"]),
			Score: toFloat64(item["score"]),
		})
	}

	if len(candidates) == 0 {
		return nil
	}

	primary := candidates[0]
	related := make([]AgentComponentCandidate, 0, 3)
	for i := 1; i < len(candidates) && i <= 3; i++ {
		related = append(related, candidates[i])
	}

	queryNorm := normalizeText(userQuery)
	if queryNorm != "" {
		for i := range candidates {
			nameNorm := normalizeText(candidates[i].Name)
			indexNorm := normalizeText(candidates[i].Index)
			if strings.Contains(nameNorm, queryNorm) || strings.Contains(indexNorm, queryNorm) {
				if i != 0 {
					primary = candidates[i]
					related = make([]AgentComponentCandidate, 0, 3)
					for j := 0; j < len(candidates) && len(related) < 3; j++ {
						if j == i {
							continue
						}
						related = append(related, candidates[j])
					}
				}
				break
			}
		}
	}

	reason := fmt.Sprintf("優先採用語意檢索結果，主結果為 %s（score=%.4f），並保留相關候選供比對。", primary.Name, primary.Score)
	if queryNorm != "" {
		reason = fmt.Sprintf("先比對使用者關鍵詞與組件名稱/索引，再依檢索分數排序；主結果為 %s（score=%.4f）。", primary.Name, primary.Score)
	}

	return &AgentResult{
		PrimaryComponent:  &primary,
		RelatedComponents: related,
		SelectionReason:   reason,
		RetrievalType:     payload.Type,
	}
}

func normalizeText(text string) string {
	replacer := strings.NewReplacer(
		" ", "", "\n", "", "\t", "", ",", "", "，", "", ".", "", "。", "",
		"!", "", "！", "", "?", "", "？", "", "-", "", "_", "", "/", "",
		"(", "", ")", "", "（", "", "）", "", "[", "", "]", "", "【", "", "】", "",
	)
	return strings.ToLower(replacer.Replace(strings.TrimSpace(text)))
}

func toInt64(v interface{}) int64 {
	s := toString(v)
	if s == "" {
		return 0
	}
	i, err := strconv.ParseInt(s, 10, 64)
	if err == nil {
		return i
	}
	f, err := strconv.ParseFloat(s, 64)
	if err == nil {
		return int64(f)
	}
	return 0
}

func toFloat64(v interface{}) float64 {
	s := toString(v)
	if s == "" {
		return 0
	}
	f, err := strconv.ParseFloat(s, 64)
	if err == nil {
		return f
	}
	return 0
}

func toString(v interface{}) string {
	switch value := v.(type) {
	case nil:
		return ""
	case string:
		return value
	case float64:
		return strconv.FormatFloat(value, 'f', -1, 64)
	case float32:
		return strconv.FormatFloat(float64(value), 'f', -1, 32)
	case int:
		return strconv.Itoa(value)
	case int64:
		return strconv.FormatInt(value, 10)
	case int32:
		return strconv.FormatInt(int64(value), 10)
	default:
		return fmt.Sprintf("%v", value)
	}
}

func toolsToParts(calls []llms.ToolCall) []llms.ContentPart {
	parts := make([]llms.ContentPart, len(calls))
	for i, c := range calls { parts[i] = c }
	return parts
}

func mergeSystemMsg(m llms.MessageContent, instruction string) llms.MessageContent {
	newParts := make([]llms.ContentPart, len(m.Parts))
	for i, p := range m.Parts {
		if tp, ok := p.(llms.TextContent); ok {
			newParts[i] = llms.TextContent{Text: tp.Text + instruction}
		} else {
			newParts[i] = p
		}
	}
	return llms.MessageContent{Role: m.Role, Parts: newParts}
}

func extractText(m llms.MessageContent) string {
	for _, p := range m.Parts {
		if t, ok := p.(llms.TextContent); ok { return t.Text }
	}
	return ""
}

func parseUsageInt(val interface{}) int {
	switch v := val.(type) {
	case int: return v
	case float64: return int(v)
	default: return 0
	}
}
