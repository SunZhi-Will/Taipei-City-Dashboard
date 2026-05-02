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
	Register("get_component_chart_data", GetComponentChartData)
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

// ComponentChartDataArgs defines arguments for component chart data tool.
type ComponentChartDataArgs struct {
	ComponentID int    `json:"component_id"`
	City        string `json:"city"`
	TimeFrom    string `json:"time_from"`
	TimeTo      string `json:"time_to"`
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
		params.Score = 0.82
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

	// Use rich retrieval so AI knows chart_types and has_map for each component
	richResults, err := models.GetComponentByQueryVectorRich(params.Query, params.Limit, params.Score)
	if err != nil {
		return "", fmt.Errorf("vector retrieval failed: %v", err)
	}

	payload, err := json.Marshal(map[string]interface{}{
		"query":   params.Query,
		"count":   len(richResults),
		"type":    "dashboard_components",
		"results": richResults,
	})
	if err != nil {
		return "", fmt.Errorf("failed to marshal tool result: %v", err)
	}

	return string(payload), nil
}

// GetComponentChartData fetches chart data for a specific dashboard component.
func GetComponentChartData(ctx context.Context, args string) (string, error) {
	_ = ctx

	var params ComponentChartDataArgs
	if err := parseArgs(args, &params); err != nil {
		return "", fmt.Errorf("invalid arguments: %v", err)
	}

	if params.ComponentID <= 0 {
		return "", fmt.Errorf("component_id is required")
	}

	if params.City != "metrotaipei" && params.City != "taipei" {
		params.City = "taipei"
	}

	loc, _ := time.LoadLocation("Asia/Taipei")
	now := time.Now().In(loc)
	if params.TimeTo == "" {
		params.TimeTo = now.Format("2006-01-02T15:04:05+08:00")
	}
	if params.TimeFrom == "" {
		params.TimeFrom = now.AddDate(0, 0, -30).Format("2006-01-02T15:04:05+08:00")
	}

	queryType, queryString, err := models.GetComponentChartDataQuery(params.ComponentID, params.City)
	if err != nil {
		return "", fmt.Errorf("failed to get component chart query: %v", err)
	}
	if queryType == "" || queryString == "" {
		return "", fmt.Errorf("no chart data available for component_id=%d city=%s", params.ComponentID, params.City)
	}

	payload := map[string]interface{}{
		"type":         "component_chart_data",
		"component_id": params.ComponentID,
		"city":         params.City,
		"query_type":   queryType,
		"time_from":    params.TimeFrom,
		"time_to":      params.TimeTo,
	}

	switch queryType {
	case "two_d":
		chartData, err := models.GetTwoDimensionalData(&queryString, params.TimeFrom, params.TimeTo)
		if err != nil {
			return "", fmt.Errorf("failed to get two_d chart data: %v", err)
		}
		payload["data"] = chartData
	case "three_d", "percent":
		chartData, categories, err := models.GetThreeDimensionalData(&queryString, params.TimeFrom, params.TimeTo)
		if err != nil {
			return "", fmt.Errorf("failed to get three_d chart data: %v", err)
		}
		payload["data"] = chartData
		payload["categories"] = categories
	case "time":
		chartData, err := models.GetTimeSeriesData(&queryString, params.TimeFrom, params.TimeTo)
		if err != nil {
			return "", fmt.Errorf("failed to get time series data: %v", err)
		}
		payload["data"] = chartData
	case "map_legend":
		chartData, err := models.GetMapLegendData(&queryString, params.TimeFrom, params.TimeTo)
		if err != nil {
			return "", fmt.Errorf("failed to get map legend data: %v", err)
		}
		payload["data"] = chartData
	default:
		return "", fmt.Errorf("unsupported query_type: %s", queryType)
	}

	// Generate a summary for the AI to easily fill tables
	summary := ""
	switch queryType {
	case "two_d":
		if data, ok := payload["data"].([]models.TwoDimensionalDataOutput); ok && len(data) > 0 && len(data[0].Data) > 0 {
			last := data[0].Data[len(data[0].Data)-1]
			summary = fmt.Sprintf("最新數值: %.1f", last.Data)
		}
	case "three_d", "percent":
		if data, ok := payload["data"].([]models.ThreeDimensionalDataOutput); ok && len(data) > 0 {
			var total float64
			var count int
			for _, series := range data {
				for _, val := range series.Data {
					total += float64(val)
					count++
				}
			}
			if count > 0 {
				avg := total / float64(count)
				summary = fmt.Sprintf("平均值: %.1f", avg)
				if len(data) == 1 && len(data[0].Data) == 1 {
					summary = fmt.Sprintf("數值: %d", data[0].Data[0])
				}
			}
		}
	case "map_legend":
		if data, ok := payload["data"].([]models.MapLegendData); ok && len(data) > 0 {
			var total float64
			for _, item := range data {
				total += item.Value
			}
			avg := total / float64(len(data))
			summary = fmt.Sprintf("平均值: %.1f", avg)
		}
	}
	if summary != "" {
		payload["summary"] = summary
	}

	raw, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal chart data: %v", err)
	}

	return string(raw), nil
}

// Helper to parse JSON arguments if needed in future tools
func parseArgs(args string, v interface{}) error {
	return json.Unmarshal([]byte(args), v)
}
