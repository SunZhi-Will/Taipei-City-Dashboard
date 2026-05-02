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
	ID               string   `json:"id"`
	Type             string   `json:"type"`
	Title            string   `json:"title"`
	Summary          string   `json:"summary,omitempty"`
	Bullets          []string `json:"bullets,omitempty"`
	Highlight        string   `json:"highlight,omitempty"`
	FocusComponentID int64    `json:"focus_component_id,omitempty"`
	ChartType        string   `json:"chart_type,omitempty"`
	MapQuery         string   `json:"map_query,omitempty"`   // location search string for map slides
	MapLng           float64  `json:"map_lng,omitempty"`    // direct longitude (skips AI geocode)
	MapLat           float64  `json:"map_lat,omitempty"`    // direct latitude  (skips AI geocode)
	DurationSec      int      `json:"duration_sec"`
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
	Log           *models.AIChatLog    `json:"log"`
	UsedTools     []string             `json:"used_tools"`
	ToolResults   map[string]string   `json:"tool_results,omitempty"`
	ToolTimeline  []ToolExecution    `json:"tool_timeline,omitempty"`
	AgentResult   *AgentResult        `json:"agent_result,omitempty"`
	DisplayPlan   *DisplayPlan        `json:"display_plan,omitempty"`
	SuggestedTags []string            `json:"suggested_tags,omitempty"`
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
		seenCallResults: make(map[string]string),
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
	seenCallResults map[string]string // dedup: key="toolName::args", value=cached result
	toolResults     map[string]string
	toolTimeline    []ToolExecution
	lastResp        *llms.ContentResponse
	lastErr         error
	startTime       time.Time
}

func (s *aiSession) run(ctx context.Context) (*AIChatResult, error) {
	maxLoops := global.TWCC.MaxToolLoops
	if maxLoops <= 0 {
		maxLoops = 5
	}
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

		// Deduplication: if same (tool, args) was already executed, reuse cached result.
		cacheKey := tc.FunctionCall.Name + "::" + tc.FunctionCall.Arguments
		if cached, exists := s.seenCallResults[cacheKey]; exists {
			logs.FInfo("Dedup: skipping duplicate call to %s", tc.FunctionCall.Name)
			s.toolTimeline = append(s.toolTimeline, ToolExecution{
				Name:   tc.FunctionCall.Name,
				Args:   tc.FunctionCall.Arguments,
				Result: "[cached] " + cached,
			})
			s.currentMessages = append(s.currentMessages, llms.MessageContent{
				Role: llms.ChatMessageTypeTool,
				Parts: []llms.ContentPart{llms.ToolCallResponse{
					ToolCallID: tc.ID, Name: tc.FunctionCall.Name, Content: cached,
				}},
			})
			continue
		}

		result, err := tools.Execute(ctx, tc.FunctionCall.Name, tc.FunctionCall.Arguments)
		if err != nil {
			result = fmt.Sprintf("Error: %v. Please verify arguments.", err)
			logs.FError("Tool Error: %v", err)
		}

		// Store tool result for potential extraction
		s.toolResults[tc.FunctionCall.Name] = result
		s.seenCallResults[cacheKey] = result
		s.toolTimeline = append(s.toolTimeline, ToolExecution{
			Name:   tc.FunctionCall.Name,
			Args:   tc.FunctionCall.Arguments,
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

	instruction := fmt.Sprintf("\nSystem Instruction:\n1. Use ONLY: [%s].\n2. NEVER nest tool calls.\n3. Arguments MUST be literal values (strings, integers, etc.), never function calls.\n4. For dependent tasks, call tools sequentially in separate turns.\n5. If stuck, respond with plain text.\n6. 若使用者要求具體數值、最近變化、趨勢比較，必須先呼叫 retrieve_components_by_query 選出元件，再呼叫 get_component_chart_data 取得資料後才能回答；回答時必須帶出數值與時間範圍。\n7. 若 retrieve_components_by_query 回傳 count=0 或 results 為空，直接告知使用者找不到相關組件，建議換用不同關鍵詞；不可捏造不存在的組件或數值。可嘗試降低 score 至 0.75 重試一次。\n8. 主題相關性自我檢查：收到 retrieve_components_by_query 結果後，必須逐一判斷每筆組件是否與使用者查詢主題直接相關。若某組件名稱或描述顯然屬於不同主題領域（例如：查詢「交通」卻出現「空氣品質」；查詢「年齡分布」卻出現「地圖測站」），必須將該組件從推薦清單中排除，不得展示給使用者，也不得呼叫 get_component_chart_data 取得其數據。\n\nSuggested Tags Rule:\n- 請在回覆的最末尾，根據當前對話上下文提供 3-5 個後續查詢建議標籤（每個標籤 2-6 字）。\n- 格式要求：必須用 [TAGS] 與 [/TAGS] 包裹，標籤間用繁體逗號分隔。例如：[TAGS] 交通流量, 捷運人流, 停車資訊 [/TAGS]\n- 若你一時無法判斷最適合的標籤，仍必須輸出 [TAGS] 區塊，提供通用但與城市資料探索相關的查詢標籤。\n\nStyle Guide:\n- Role: 你是臺北市城市大數據儀表板的智慧助理，回覆對象是一般市民。\n- 語氣：清楚、友善、專業；避免過度口語與過多 emoji。\n- 城市名：只能使用「臺北」或「雙北」，不得出現 metrotaipei 或 taipei 等技術字眼。\n- 組件推薦：若有 2 筆以上結果，使用 Markdown 表格，欄位順序為「排名｜城市名｜組件名｜數值」。\n- 數據填充：「數值」欄位必須使用呼叫 get_component_chart_data 後得到的最近數據（含單位），若尚未獲取數據或該組件無數值則留空，不可填估算值。\n- 表格規範：表格內只能放資料列，禁止把完整句子、提醒語、結語放進表格欄位。\n- 版面規範：表格結束後必須空一行，再用一般段落補充說明。\n- 說明內容：可提示「可加入個人儀表板」與下一步建議，但要放在表格外。\n- 禁忌：不得出現 RAG、tool、score、index、id、主結果、候選、檢索、關聯性、分數、相似度等技術用語。", toolNames)

	if s.req.AppMode == "ai_studio" {
		instruction += `
8. Context: AI STUDIO — 智慧專題展示模式。

你現在的角色是「指揮中心導演」。你的目標不是單純列出資料，而是為使用者策劃一場有邏輯、有洞察力的動態展示。

思考路徑（Director's Thinking）：
① **理解意圖**：分析使用者是想看具體數據、比較趨勢，還是要準備一場對外的專題簡報？
② **挑選內容**：呼叫 retrieve_components_by_query 獲取素材，並依據你的專業判斷，選出最能支撐主題的組件與圖表類型。若搜尋無結果（count=0），告知使用者並建議改換關鍵詞，不要生成空的展示計畫。
③ **策劃流暢度**（投影片數量完全由主題決定，最少 1 張，建議 3–10 張）：
   - **hero 投影片可選**：若主題需要開場說明或結語總結，可加入 type="hero"；若使用者只想直接看數據，可完全省略 hero。
   - 將組件按邏輯排列（例如：從現況展示到趨勢分析）。
   - 對需要解說的重要指標，可在 component 投影片之後插入 type="component_explain" 投影片，用 summary 欄位補充政策意涵或解讀重點。
   - 若需要穿插純文字分析、政策背景或統計摘要，使用 type="text" 投影片：summary 填寫主段落，bullets 陣列（最多 5 條）列出重點，highlight 填入最關鍵的單一數字或統計值（如「128 萬人」）。
   - 若組件有地圖屬性（搜尋結果的 has_map 欄位為 true），以 type="map" 投影片呈現空間分布；系統會顯示真實 Mapbox 互動地圖，chart_type 從工具回傳的 chart_types 中選地圖類型（map_legend、map_pin、map_heat 等）。若需聚焦特定地點，填入 map_query（中文地名，系統自動定位）。
   - **重要**：若組件的 has_map 為 false，絕對不可使用 type="map"，一律改用 type="component"。
④ **chart_type 精確規則**（務必遵守）：
   - chart_type 欄位的值必須是工具回傳結果中該組件的 chart_types 陣列的某一個精確字串，例如 "BarChart"、"ColumnChart"、"DonutChart"、"DistrictChart"、"map_legend" 等。
   - 不可自行發明 "bar"、"line"、"column"、"pie" 等縮寫或不存在的字串。
   - 若不確定或不重要，直接省略 chart_type 欄位，系統會自動選用第一個可用類型。
⑤ **一致性校驗**：文字回覆中提及的組件名稱與 ID，必須與 JSON 中的 focus_component_id 完全一致。

display_plan JSON 格式示例（slides 數量依主題靈活決定，可多可少）：
` + "```json" + `
{
  "mode": "presentation",
  "strict_render": true,
  "style": "carousel",
  "audience": "war-room",
  "slides": [
    {
      "id": "slide-component-1",
      "type": "component",
      "title": "組件名稱",
      "summary": "一句話說明此數據的關鍵意義",
      "focus_component_id": 123,
      "chart_type": "BarChart",
      "duration_sec": 12
    },
    {
      "id": "slide-map-1",
      "type": "map",
      "title": "空間分布：組件名稱",
      "summary": "地圖顯示各區域分布情形（Mapbox 實際地圖，可互動）",
      "focus_component_id": 456,
      "chart_type": "map_legend",
      "map_query": "大安區",
      "duration_sec": 14
    },
    {
      "id": "slide-text-1",
      "type": "text",
      "title": "現況總覽",
      "summary": "說明這個主題的整體背景與重要性",
      "bullets": ["關鍵指標一，帶入具體數字", "關鍵指標二，說明趨勢方向"],
      "highlight": "128 萬人",
      "duration_sec": 12
    }
  ]
}
` + "```" + `

規則提示：
- 以資訊密度和敘事流暢度為最高優先，按需靈活增減投影片。
- 有地圖數據時（has_map=true）必須納入 type="map" 投影片，讓使用者看到真實地圖。
- 只有在使用者需要精確數值進行比對時，才呼叫 get_component_chart_data。
- map 投影片的 map_query 只在確實需要聚焦特定地點時才填寫；若整體空間分布才是重點，留空即可。
- JSON 區塊必須放在回覆的最末尾，且格式完整可解析。`
	}
	
	s.currentMessages = make([]llms.MessageContent, 0)

	// Separate system messages from conversation history
	var systemMsgs []llms.MessageContent
	var historyMsgs []llms.MessageContent
	for _, m := range s.req.Messages {
		if m.Role == llms.ChatMessageTypeSystem {
			systemMsgs = append(systemMsgs, m)
		} else {
			historyMsgs = append(historyMsgs, m)
		}
	}

	// Truncate conversation history to last maxHistoryMessages to avoid TWCC context-too-long (HTTP 520)
	const maxHistoryMessages = 12
	if len(historyMsgs) > maxHistoryMessages {
		historyMsgs = historyMsgs[len(historyMsgs)-maxHistoryMessages:]
	}

	// Merge instruction into the first system message (or prepend a new one)
	merged := false
	for _, m := range systemMsgs {
		if !merged {
			s.currentMessages = append(s.currentMessages, mergeSystemMsg(m, instruction))
			merged = true
		} else {
			s.currentMessages = append(s.currentMessages, m)
		}
	}
	s.currentMessages = append(s.currentMessages, historyMsgs...)

	if !merged {
		s.currentMessages = append([]llms.MessageContent{{
			Role:  llms.ChatMessageTypeSystem,
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

	suggestedTags := extractSuggestedTags(rawAnswer)
	cleanAnswer = stripTagsFromAnswer(cleanAnswer)
	log.Answer = cleanAnswer

	return &AIChatResult{
		Log:           log,
		UsedTools:     append([]string{}, s.executedTools...),
		ToolResults:   copyToolResults(s.toolResults),
		ToolTimeline:  copyToolTimeline(s.toolTimeline),
		AgentResult:   agentResult,
		DisplayPlan:   displayPlan,
		SuggestedTags: suggestedTags,
	}, nil
}

func extractSuggestedTags(answer string) []string {
	startTag := "[TAGS]"
	endTag := "[/TAGS]"
	startIdx := strings.Index(answer, startTag)
	if startIdx == -1 {
		return nil
	}
	endIdx := strings.Index(answer[startIdx+len(startTag):], endTag)
	if endIdx == -1 {
		return nil
	}
	endIdx += startIdx + len(startTag)

	tagsStr := answer[startIdx+len(startTag) : endIdx]
	replacer := strings.NewReplacer("\n", "，", "、", "，", ",", "，", ";", "，", "；", "，")
	tags := strings.Split(replacer.Replace(tagsStr), "，")

	result := make([]string, 0)
	seen := make(map[string]struct{})
	for _, t := range tags {
		trimmed := strings.TrimSpace(t)
		if trimmed == "" {
			continue
		}
		runeLen := len([]rune(trimmed))
		if runeLen < 2 || runeLen > 12 {
			continue
		}
		if _, exists := seen[trimmed]; exists {
			continue
		}
		seen[trimmed] = struct{}{}
		result = append(result, trimmed)
		if len(result) >= 5 {
			break
		}
	}

	if len(result) == 0 {
		return nil
	}
	return result
}

func stripTagsFromAnswer(answer string) string {
	startTag := "[TAGS]"
	endTag := "[/TAGS]"
	startIdx := strings.Index(answer, startTag)
	if startIdx == -1 {
		return answer
	}
	endIdx := strings.Index(answer, endTag)
	if endIdx == -1 {
		return strings.TrimSpace(answer[:startIdx])
	}
	prefix := answer[:startIdx]
	suffix := answer[endIdx+len(endTag):]
	return strings.TrimSpace(prefix + suffix)
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

	// hero, component_explain, and text are rendered by AIStudioPresentationCanvas as text/title slides.
	// They must not be filtered out — the FE handles them natively.
	allowedType := map[string]bool{"component": true, "map": true, "hero": true, "component_explain": true, "text": true}
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
			slide.ChartType = "map_legend"
		}
		normalizedSlides = append(normalizedSlides, slide)
	}
	plan.Slides = normalizedSlides

	// ── Smart chart_type correction ────────────────────────────────────────────
	// For slides with a focus_component_id, look up the component's actual
	// chart_types from DB and auto-fix the slide type and chart_type.
	// This corrects common AI mistakes (wrong type names, map slides for
	// non-map components) without requiring prompt perfection.
	plan.Slides = fixSlidesChartTypes(plan.Slides)

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
						return "map_legend"
					}
					return "auto"
				}(),
			})
		}
	}

	return plan
}

// mapChartTypes is the set of chart type strings that represent map visualizations.
// Both snake_case (AI convention) and CamelCase (DB convention) are included.
var mapChartTypes = map[string]bool{
	"map_legend": true, "map_pin": true, "map_heat": true,
	"map_layer": true, "map_district": true,
	"MapLegend": true, "MapPin": true, "MapHeat": true,
	"MapLayer": true, "MapDistrict": true,
}

// fixSlidesChartTypes performs a DB-backed correction pass on all slides.
// For each slide that references a focus_component_id:
//   - If slide.Type == "map" but component has no map capability → degrade to "component"
//   - If slide.ChartType is not in the component's chart_types → pick the best matching type
//
// This makes the system resilient to AI errors in chart_type selection.
func fixSlidesChartTypes(slides []DisplayPlanSlide) []DisplayPlanSlide {
	for i, slide := range slides {
		if slide.FocusComponentID <= 0 {
			continue
		}
		meta, err := models.GetComponentChartMeta(slide.FocusComponentID)
		if err != nil || meta == nil || len(meta.ChartTypes) == 0 {
			continue
		}

		// Build a lookup set of the component's valid chart types
		validSet := make(map[string]bool, len(meta.ChartTypes))
		for _, ct := range meta.ChartTypes {
			validSet[ct] = true
		}

		if slide.Type == "map" {
			if !meta.HasMap {
				// Component cannot render a map — downgrade slide to component type
				slides[i].Type = "component"
				// Keep chart_type if it's valid for this component, otherwise use first
				if !validSet[slide.ChartType] {
					slides[i].ChartType = meta.ChartTypes[0]
				}
			} else {
				// Component has map capability — ensure chart_type is a map type AND
				// matches the exact DB string (e.g. "MapLegend" not "map_legend")
				if !mapChartTypes[slide.ChartType] {
					// AI gave a non-map type: find first map-compatible type in component's list
					found := ""
					for _, ct := range meta.ChartTypes {
						if mapChartTypes[ct] {
							found = ct
							break
						}
					}
					if found != "" {
						slides[i].ChartType = found
					} else {
						slides[i].ChartType = "map_legend"
					}
				} else {
					// AI gave a valid map type (e.g. "map_legend"), but DB may use CamelCase ("MapLegend").
					// Find the exact DB string so DashboardComponent.types.includes() matches precisely.
					for _, ct := range meta.ChartTypes {
						if mapChartTypes[ct] {
							slides[i].ChartType = ct
							break
						}
					}
				}
			}
		} else if slide.Type == "component" {
			// Validate chart_type: if AI invented a value not in the list, pick best match
			if slide.ChartType != "" && !validSet[slide.ChartType] {
				slides[i].ChartType = pickBestChartType(slide.ChartType, meta.ChartTypes)
			}
		}
	}
	return slides
}

// pickBestChartType attempts to find the closest matching chart type.
// Strategy: prefer types that share semantic similarity (bar↔column, donut↔pie, etc.)
// Falls back to the first available type.
func pickBestChartType(aiType string, available []string) string {
	if len(available) == 0 {
		return ""
	}
	lower := strings.ToLower(aiType)
	// Semantic equivalence map for common AI hallucinations
	semanticMap := map[string][]string{
		"bar":      {"BarChart", "ColumnChart", "BarPercentChart", "BarChartWithGoal"},
		"column":   {"ColumnChart", "BarChart", "ColumnLineChart"},
		"line":     {"TimelineSeparateChart", "ColumnLineChart"},
		"pie":      {"DonutChart"},
		"donut":    {"DonutChart"},
		"radar":    {"RadarChart"},
		"district": {"DistrictChart"},
		"treemap":  {"TreemapChart"},
		"gauge":    {"GuageChart"},
		"map":      {"map_legend"},
	}
	if candidates, ok := semanticMap[lower]; ok {
		for _, candidate := range candidates {
			for _, avail := range available {
				if avail == candidate {
					return avail
				}
			}
		}
	}
	// Substring match as fallback (e.g. "BarChart" contains "bar")
	for _, avail := range available {
		if strings.Contains(strings.ToLower(avail), lower) {
			return avail
		}
	}
	return available[0]
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
