package tools

import (
	"TaipeiCityDashboardBE/app/models"
	"context"
	"encoding/json"
	"fmt"
	"time"
)

// ToolFunc defines the signature for a tool function
type ToolFunc func(ctx context.Context, args string) (string, error)

var registry = make(map[string]ToolFunc)

func init() {
	// Register demo tools
	Register("get_current_time", GetCurrentTime)
	Register("get_population_summary", GetPopulationSummary)
	Register("retrieve_components_by_query", RetrieveComponentsByQuery)
}

// Register adds a tool to the registry
func Register(name string, fn ToolFunc) {
	registry[name] = fn
}

// Execute calls a registered tool with the given arguments
func Execute(ctx context.Context, name string, args string) (string, error) {
	fn, ok := registry[name]
	if !ok {
		return "", fmt.Errorf("tool %s not found", name)
	}
	return fn(ctx, args)
}

// PopulationArgs defines the arguments for the get_population_summary tool
type PopulationArgs struct {
	City string `json:"city"`
	Year int    `json:"year"`
}

// ComponentRetrieveArgs defines arguments for vector retrieval tool.
type ComponentRetrieveArgs struct {
	Query string  `json:"query"`
	Limit int     `json:"limit"`
	Score float64 `json:"score"`
}

// GetPopulationSummary queries the population age distribution from the dashboard database
func GetPopulationSummary(ctx context.Context, args string) (string, error) {
	var params PopulationArgs
	if err := parseArgs(args, &params); err != nil {
		return "", fmt.Errorf("invalid arguments: %v", err)
	}

	// Default to Taipei if not specified or unrecognized
	tableName := "population_age_distribution_tpe"
	cityName := "台北市"
	if params.City == "new_taipei" {
		tableName = "population_age_distribution_new_tpe"
		cityName = "新北市"
	}

	// Define result structure based on database schema
	var result struct {
		Year      int `gorm:"column:year"`
		Young     int `gorm:"column:young_population"`
		Working   int `gorm:"column:working_age_population"`
		Elderly   int `gorm:"column:elderly_population"`
		DataTime  time.Time `gorm:"column:data_time"`
	}

	// Query the dashboard database
	err := models.DBDashboard.Table(tableName).
		Where("year = ?", params.Year).
		Order("data_time DESC"). // Get the latest record for that year
		First(&result).Error

	if err != nil {
		return "", fmt.Errorf("找不到 %s %d 年的人口統計資料: %v", cityName, params.Year, err)
	}

	// Format the response for the LLM
	return fmt.Sprintf(
		"【%d年 %s 人口結構概況】\n- 幼年人口 (0-14歲)：%d 人\n- 青壯年人口 (15-64歲)：%d 人\n- 老年人口 (65歲以上)：%d 人\n- 總人口： %d 人\n- 數據更新時間：%s",
		result.Year, cityName, result.Young, result.Working, result.Elderly,
		result.Young+result.Working+result.Elderly,
		result.DataTime.Format("2006-01-02"),
	), nil
}

// GetCurrentTime is a demo tool that returns the current Taipei time
func GetCurrentTime(ctx context.Context, args string) (string, error) {
	loc, err := time.LoadLocation("Asia/Taipei")
	if err != nil {
		// Fallback to UTC if timezone data is missing
		return time.Now().Format(time.RFC3339), nil
	}
	return time.Now().In(loc).Format("2006-01-02 15:04:05"), nil
}

// RetrieveComponentsByQuery executes the Qdrant vector retrieval for Vue components.
// Enhanced to return structured component information for Chat UI rendering
func RetrieveComponentsByQuery(ctx context.Context, args string) (string, error) {
	var params ComponentRetrieveArgs
	if err := parseArgs(args, &params); err != nil {
		return "", fmt.Errorf("invalid arguments: %v", err)
	}

	if params.Query == "" {
		return "", fmt.Errorf("query is required")
	}

	if params.Limit <= 0 {
		params.Limit = 5
	}
	if params.Limit > 10 {
		params.Limit = 10
	}

	if params.Score <= 0 || params.Score > 1 {
		params.Score = 0.78
	}

	// Try to get Vue components first
	vueResults, err := models.GetVueComponentByQuery(params.Query, params.Limit, params.Score)
	if err == nil && len(vueResults) > 0 {
		// Return Vue component results with rich metadata
		payload, err := json.Marshal(map[string]interface{}{
			"query":     params.Query,
			"count":     len(vueResults),
			"type":      "vue_components",
			"results":   vueResults,
		})
		if err != nil {
			return "", fmt.Errorf("failed to marshal tool result: %v", err)
		}
		return string(payload), nil
	}

	// Fallback to dashboard components if Vue component search returns nothing
	results, err := models.GetComponentByQueryVector(params.Query, params.Limit, params.Score)
	if err != nil {
		return "", fmt.Errorf("vector retrieval failed: %v", err)
	}

	payload, err := json.Marshal(map[string]interface{}{
		"query":   params.Query,
		"count":   len(results),
		"type":    "dashboard_components",
		"results": results,
	})
	if err != nil {
		return "", fmt.Errorf("failed to marshal tool result: %v", err)
	}

	return string(payload), nil
}

// Helper to parse JSON arguments if needed in future tools
func parseArgs(args string, v interface{}) error {
	return json.Unmarshal([]byte(args), v)
}
