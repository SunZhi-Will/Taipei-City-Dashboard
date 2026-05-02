// Package models stores the models for the postgreSQL databases.
package models

import (
	"encoding/json"
	"fmt"
	"math"
	"sort"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/lib/pq"
	"gorm.io/gorm"
)

/* ----- Models ----- */

// Component is the model for the components table.
type Component struct {
	ID             int64           `json:"id" gorm:"column:id;autoincrement;primaryKey"`
	Index          string          `json:"index" gorm:"column:index;type:varchar;unique;not null"     `
	Name           string          `json:"name" gorm:"column:name;type:varchar;not null"`
}

// QueryCharts is the model for the query_charts table.
type QueryCharts struct {
	Index string                   `json:"index"      gorm:"column:index;type:varchar"`
	HistoryConfig  json.RawMessage `json:"history_config" gorm:"column:history_config;type:json"`
	MapConfigIDs   pq.Int64Array   `json:"-" gorm:"column:map_config_ids;type:integer[]"`
	MapFilter      json.RawMessage `json:"map_filter" gorm:"column:map_filter;type:json"`
	TimeFrom       string          `json:"time_from" gorm:"column:time_from;type:varchar"`
	TimeTo         *string         `json:"time_to" gorm:"column:time_to;type:varchar"`
	UpdateFreq     *int64          `json:"update_freq" gorm:"column:update_freq;type:integer"`
	UpdateFreqUnit string          `json:"update_freq_unit" gorm:"column:update_freq_unit;type:varchar"`
	Source         string          `json:"source" gorm:"column:source;type:varchar"`
	ShortDesc      string          `json:"short_desc" gorm:"column:short_desc;type:text"`
	LongDesc       string          `json:"long_desc" gorm:"column:long_desc;type:text"`
	UseCase        string          `json:"use_case" gorm:"column:use_case;type:text"`
	Links          pq.StringArray  `json:"links" gorm:"column:links;type:text[]"`
	Contributors   pq.StringArray  `json:"contributors" gorm:"column:contributors;type:text[]"`
	CreatedAt      time.Time       `json:"-" gorm:"column:created_at;type:timestamp with time zone;not null"`
	UpdatedAt      time.Time       `json:"updated_at" gorm:"column:updated_at;type:timestamp with time zone;not null"`
	QueryType      string          `json:"query_type" gorm:"column:query_type;type:varchar"`
	QueryChart     string          `json:"-" gorm:"column:query_chart;type:text"`
	QueryHistory   string          `json:"-" gorm:"column:query_history;type:text"`
	City		   string          `json:"city" gorm:"column:city;type:text"`
}

type CityComponent struct{
	ID             int64           `json:"id"`
	Index          string          `json:"index"`
	Name           string          `json:"name"`
	ChartConfig    json.RawMessage `json:"chart_config"`
	HistoryConfig  json.RawMessage `json:"history_config"`
	MapConfigIDs   pq.Int64Array   `json:"-"  gorm:"type:integer[]"`
	MapConfig      json.RawMessage `json:"map_config"`
	MapFilter      json.RawMessage `json:"map_filter"`
	TimeFrom       string          `json:"time_from"`
	TimeTo         *string         `json:"time_to"`
	UpdateFreq     *int64          `json:"update_freq"`
	UpdateFreqUnit string          `json:"update_freq_unit"`
	Source         string          `json:"source"`
	ShortDesc      string          `json:"short_desc"`
	LongDesc       string          `json:"long_desc"`
	UseCase        string          `json:"use_case"`
	Links          pq.StringArray  `json:"links" gorm:"type:text[]"`
	Contributors   pq.StringArray  `json:"contributors" gorm:"type:text[]"`
	CreatedAt      time.Time       `json:"-"`
	UpdatedAt      time.Time       `json:"updated_at"`
	QueryType      string          `json:"query_type"`
	QueryChart     string          `json:"-"`
	QueryHistory   string          `json:"-"`
	City		   string          `json:"city"`
}

type CityComponentScore struct{
	ID             int64           `json:"id"`
	Index          string          `json:"index"`
	Name           string          `json:"name"`
	City		   string          `json:"city"`
	Score 		   float64         `json:"score"`
}

// CityComponentScoreRich extends CityComponentScore with chart/map metadata for AI planning.
type CityComponentScoreRich struct {
	ID         int64    `json:"id"`
	Index      string   `json:"index"`
	Name       string   `json:"name"`
	City       string   `json:"city"`
	Score      float64  `json:"score"`
	ShortDesc  string   `json:"short_desc"`
	ChartTypes []string `json:"chart_types"` // e.g. ["bar","line","percent"]
	HasMap     bool     `json:"has_map"`     // true if map_config is non-empty
}

// ComponentMap is the model for the component_maps table.
type ComponentMap struct {
	ID       int64            `json:"id" gorm:"column:id;autoincrement;primaryKey"`
	Index    string           `json:"index"      gorm:"column:index;type:varchar;not null"`
	Title    string           `json:"title"      gorm:"column:title;type:varchar;not null"`
	Type     string           `json:"type"       gorm:"column:type;type:varchar;not null"`
	Source   string           `json:"source"     gorm:"column:source;type:varchar;not null"`
	Size     *string          `json:"size"       gorm:"column:size;type:varchar"`
	Icon     *string          `json:"icon"       gorm:"column:icon;type:varchar"`
	Paint    *json.RawMessage `json:"paint" gorm:"column:paint;type:json"`
	Property *json.RawMessage `json:"property" gorm:"column:property;type:json"`
}

// ComponentChart is the model for the component_charts table.
type ComponentChart struct {
	Index string         `json:"index"      gorm:"column:index;type:varchar;primaryKey"     `
	Color pq.StringArray `json:"color" gorm:"column:color;type:varchar[]"`
	Types pq.StringArray `json:"types" gorm:"column:types;type:varchar[]"`
	Unit  string         `json:"unit" gorm:"column:unit;type:varchar"`
}

// QuertChartAndConponentForQdrant defines the structure for query_charts&component data fetched for Qdrant.
// It's a subset of fields from query_charts and components.
type QuertChartAndConponentForQdrant struct {
    ID       int64  `gorm:"column:id"`
    Index    string `gorm:"column:index"`
    Name     string `gorm:"column:name"`
    City     string `gorm:"column:city"`
    LongDesc string `gorm:"column:long_desc"`
    UseCase  string `gorm:"column:use_case"`
}

/* ----- Handlers ----- */

// GetPublicComponentsForQdrant fetches all query_charts and components that are part of a public (non-personal) dashboard.
// This data is used to rebuild the Qdrant vector index.
func GetPublicComponentsForQdrant() (results []QuertChartAndConponentForQdrant, err error) {
    // subQueryGroups := SELECT DISTINCT id FROM "groups" g WHERE is_personal IS FALSE
    subQueryGroups := DBManager.Table("groups").Select("id").Where("is_personal IS FALSE")

    // subQueryDashboards := SELECT DISTINCT dashboard_id FROM dashboard_groups dg WHERE group_id IN (subQueryGroups)
    subQueryDashboards := DBManager.Table("dashboard_groups").Select("dashboard_id").Where("group_id IN (?)", subQueryGroups)

    // subQueryComponents := SELECT DISTINCT unnest(components) FROM dashboards d WHERE id IN (subQueryDashboards)
    subQueryComponents := DBManager.Table("dashboards").Select("DISTINCT unnest(components)").Where("id IN (?)", subQueryDashboards)

    // Final Query
    err = DBManager.Table("query_charts as qc").
        Select("c.id, qc.index, c.name, qc.city, qc.long_desc, qc.use_case").
        Joins("INNER JOIN components c ON qc.index = c.index").
        Where("c.id IN (?)", subQueryComponents).
        Scan(&results).Error

    if err != nil {
        return nil, err
    }

    return results, nil
}

// createTempComponentDB joins the components, component_maps, and component_charts tables and selects the columns to return.
func createTempComponentDB() *gorm.DB {
	subQuery1 := DBManager.Table("components").
	Select("components.id,components.index,components.name,row_to_json(component_charts.*) AS chart_config").
	Joins("JOIN component_charts ON components.index = component_charts.index")

	subQuery2 := DBManager.Table("query_charts").
	Select("query_charts.index,query_charts.city,json_agg(row_to_json(component_maps.*)) as map_config").
	Joins("LEFT JOIN unnest(query_charts.map_config_ids) AS id_value on true").
	Joins("LEFT JOIN component_maps ON id_value = component_maps.id").
	Group("query_charts.index, query_charts.city")

	query := DBManager.Table("(?) as components", subQuery1).
		Select("*").
		Joins("LEFT JOIN (?) as qc ON components.index = qc.index", subQuery2).
		Joins("LEFT JOIN query_charts ON components.index = query_charts.index AND qc.city = query_charts.city")

	return query
}

func GetAllComponents(city string, pageSize int, pageNum int, sort string, order string, filterBy string, filterMode string, filterValue string, searchByIndex string, searchByName string) (components []CityComponent, totalComponents int64, resultNum int64, err error) {
	tempDB := createTempComponentDB()

	// Count the total amount of components
	tempDB.Count(&totalComponents)

	if city != ""{
		tempDB = tempDB.Where("query_charts.city = ?", city)
	}

	// Search the components
	if searchByIndex != "" {
		tempDB = tempDB.Where("components.index LIKE ?", "%"+searchByIndex+"%")
	}
	if searchByName != "" {
		tempDB = tempDB.Where("components.name LIKE ?", "%"+searchByName+"%")
	}

	componentsColumn := []string{"id","index","name"}
	queryChartsColumn := []string{"update_freq","source","short_desc","long_desc","use_case","links","contributors","query_type"}
	allColumns := append(componentsColumn, queryChartsColumn...)

	// Filter the components
	if filterBy != "" && filterValue != "" && slices.Contains(allColumns,filterBy){
		var filterByCol string
		if slices.Contains(componentsColumn,filterBy){
			filterByCol = "components"
		}

		if slices.Contains(queryChartsColumn,filterBy){
			filterByCol = "query_charts"
		}

		switch filterMode {
		case "eq": // equals
			tempDB = tempDB.Where(filterByCol + ".\"?\" = ?", gorm.Expr(filterBy), filterValue)
		case "ne": // not equals
			tempDB = tempDB.Where(filterByCol + ".\"?\" <> ?", gorm.Expr(filterBy), filterValue)
		case "gt": // greater than
			tempDB = tempDB.Where(filterByCol + ".\"?\" > ?", gorm.Expr(filterBy), filterValue)
		case "lt": // less than
			tempDB = tempDB.Where(filterByCol + ".\"?\" < ?", gorm.Expr(filterBy), filterValue)
		case "in": // value in array
			tempDB = tempDB.Where(filterByCol + ".\"?\" IN ?", gorm.Expr(filterBy), filterValue)
		default: // Default to eq
			tempDB = tempDB.Where(filterByCol + ".\"?\" = ?", gorm.Expr(filterBy), filterValue)
		}
	}

	tempDB.Count(&resultNum)

	// Sort the components
	if sort != "" && slices.Contains(allColumns,sort){
		if slices.Contains(componentsColumn,sort){
			tempDB = tempDB.Order("components." + sort + " " + order)
		}

		if slices.Contains(queryChartsColumn,sort){
			tempDB = tempDB.Order("query_charts." + sort + " " + order)
		}
	}

	// Paginate the components
	if pageSize > 0 {
		tempDB = tempDB.Limit(pageSize)
		if pageNum > 0 {
			tempDB = tempDB.Offset((pageNum - 1) * pageSize)
		}
	}

	err = tempDB.Find(&components).Error
	if err != nil {
		return components, 0, 0, err
	}

	return components, totalComponents, resultNum, nil
}

func GetComponentByID(id int, city string) (component CityComponent, err error) {
	tempDB := createTempComponentDB()
	err = tempDB.Where("components.id = ?", id).Where("query_charts.city = ?", city).First(&component).Error
	if err != nil {
		return component, err
	}
	return component, nil
}

func GetComponentByIDAll(id int) (component []CityComponent, err error) {
	tempDB := createTempComponentDB()
	err = tempDB.Where("components.id = ?", id).Find(&component).Error
	if err != nil {
		return component, err
	}
	return component, nil
}	

func GetComponentByQueryVector(queryString string, limit int, scoreThreshold float64) (component []CityComponentScore, err error) {
	rich, err := GetComponentByQueryVectorRich(queryString, limit, scoreThreshold)
	if err != nil {
		return component, err
	}
	for _, r := range rich {
		component = append(component, CityComponentScore{
			ID: r.ID, Index: r.Index, Name: r.Name, City: r.City, Score: r.Score,
		})
	}
	return component, nil
}

// GetComponentByQueryVectorRich returns vector search results enriched with chart types and map presence.
func GetComponentByQueryVectorRich(queryString string, limit int, scoreThreshold float64) ([]CityComponentScoreRich, error) {
	vector, err := GenVector(queryString)
	if err != nil {
		return nil, err
	}

	queryDomain := detectQueryDomain(queryString)

	result, err := queryQdrant(vector, limit, scoreThreshold)
	if err != nil {
		return nil, err
	}

	points := result.Result.Points
	if len(points) == 0 {
		return []CityComponentScoreRich{}, nil
	}

	// Build base results from Qdrant
	type qdrantItem struct {
		id    int64
		index string
		name  string
		city  string
		longDesc string
		useCase  string
		score float64
	}
	items := make([]qdrantItem, 0, len(points))
	ids := make([]int64, 0, len(points))

	for _, p := range points {
		payload := p.Payload
		roundedScore := math.Round(p.Score*10000) / 10000
		var id int64
		switch v := payload["id"].(type) {
		case float64:
			id = int64(v)
		case string:
			id, _ = strconv.ParseInt(v, 10, 64)
		}
		items = append(items, qdrantItem{
			id:    id,
			index: fmt.Sprintf("%v", payload["index"]),
			name:  fmt.Sprintf("%v", payload["name"]),
			city:  fmt.Sprintf("%v", payload["city"]),
			longDesc: fmt.Sprintf("%v", payload["long_desc"]),
			useCase:  fmt.Sprintf("%v", payload["use_case"]),
			score: roundedScore,
		})
		ids = append(ids, id)
	}

	// Batch-fetch chart_config + map_config + short_desc from DB
	type compMeta struct {
		ID         int64  `gorm:"column:id"`
		ChartTypes string `gorm:"column:chart_types"` // JSON array string
		HasMap     bool   `gorm:"column:has_map"`
		ShortDesc  string `gorm:"column:short_desc"`
	}
	var metas []compMeta
	// hasMap: true when map_config_ids is not empty
	DBManager.Raw(`
		SELECT c.id,
			   cc.types::text AS chart_types,
			   (qc.map_config_ids IS NOT NULL AND array_length(qc.map_config_ids,1) > 0) AS has_map,
			   qc.short_desc
		FROM components c
		JOIN component_charts cc ON c.index = cc.index
		JOIN query_charts qc ON c.index = qc.index
		WHERE c.id = ANY(?)
	`, pq.Array(ids)).Scan(&metas)

	metaByID := make(map[int64]compMeta, len(metas))
	for _, m := range metas {
		metaByID[m.ID] = m
	}

	rich := make([]CityComponentScoreRich, 0, len(items))
	for _, item := range items {
		r := CityComponentScoreRich{
			ID: item.id, Index: item.index, Name: item.name, City: item.city, Score: item.score,
		}
		if m, ok := metaByID[item.id]; ok {
			r.HasMap = m.HasMap
			r.ShortDesc = m.ShortDesc
			// Parse types JSON array e.g. "{bar,line}" or ["bar","line"]
			var types []string
			clean := strings.Trim(m.ChartTypes, "{}")
			if strings.HasPrefix(m.ChartTypes, "[") {
				_ = json.Unmarshal([]byte(m.ChartTypes), &types)
			} else if clean != "" {
				for _, t := range strings.Split(clean, ",") {
					types = append(types, strings.TrimSpace(t))
				}
			}
			r.ChartTypes = types
		}

		if queryDomain == "food_safety" {
			text := strings.ToLower(strings.Join([]string{
				item.index,
				item.name,
				item.longDesc,
				item.useCase,
				r.ShortDesc,
			}, " "))
			if !containsAnyToken(text, foodSafetyTokens()) {
				continue
			}
		}

		boost := lexicalRelevanceBoost(queryString, item.index, item.name, r.ShortDesc)
		if boost > 0 {
			r.Score = math.Round(math.Min(1.0, item.score+boost)*10000) / 10000
		}

		rich = append(rich, r)
	}

	sort.SliceStable(rich, func(i, j int) bool {
		return rich[i].Score > rich[j].Score
	})

	if limit > 0 && len(rich) > limit {
		rich = rich[:limit]
	}

	return rich, nil
}

func detectQueryDomain(query string) string {
	q := strings.ToLower(query)
	if containsAnyToken(q, foodSafetyTokens()) {
		return "food_safety"
	}
	return "general"
}

func containsAnyToken(text string, tokens []string) bool {
	for _, token := range tokens {
		if token == "" {
			continue
		}
		if strings.Contains(text, strings.ToLower(token)) {
			return true
		}
	}
	return false
}

func foodSafetyTokens() []string {
	return []string{
		"食安", "食品", "食品業者", "衛生", "稽查", "抽驗", "中毒", "農藥", "工廠", "批發市場",
		"food", "food safety", "pesticide", "inspection",
	}
}

func lexicalRelevanceBoost(query, index, name, shortDesc string) float64 {
	q := strings.ToLower(strings.TrimSpace(query))
	if q == "" {
		return 0
	}

	idx := strings.ToLower(index)
	nm := strings.ToLower(name)
	desc := strings.ToLower(shortDesc)

	boost := 0.0
	if strings.Contains(nm, q) || strings.Contains(idx, q) {
		boost += 0.20
	}

	if strings.Contains(q, nm) {
		boost += 0.10
	}

	for _, token := range queryTokens(q) {
		if strings.Contains(nm, token) {
			boost += 0.03
		}
		if strings.Contains(idx, token) {
			boost += 0.02
		}
		if strings.Contains(desc, token) {
			boost += 0.01
		}
	}

	if boost > 0.25 {
		return 0.25
	}
	return boost
}

func queryTokens(q string) []string {
	parts := strings.FieldsFunc(q, func(r rune) bool {
		switch r {
		case ' ', ',', '，', '。', '、', '\t', '\n', '\r':
			return true
		default:
			return false
		}
	})

	tokens := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		tokens = append(tokens, p)
	}

	if len(tokens) == 0 {
		tokens = append(tokens, q)
	}

	return tokens
}

// ComponentChartMeta holds chart capability metadata for a single component, used by AI planning.
type ComponentChartMeta struct {
	ChartTypes []string // Exact chart type strings, e.g. ["BarChart", "ColumnChart"]
	HasMap     bool     // Whether the component has a non-empty map_config
}

// GetComponentChartMeta returns chart_types and has_map for a single component by ID.
// It is used by normalizeDisplayPlan to validate and auto-correct AI-generated slide chart_type values.
func GetComponentChartMeta(componentID int64) (*ComponentChartMeta, error) {
	var row struct {
		ChartTypes string `gorm:"column:chart_types"`
		HasMap     bool   `gorm:"column:has_map"`
	}
	err := DBManager.Raw(`
		SELECT cc.types::text AS chart_types,
			   (qc.map_config_ids IS NOT NULL AND array_length(qc.map_config_ids,1) > 0) AS has_map
		FROM components c
		JOIN component_charts cc ON c.index = cc.index
		JOIN query_charts qc ON c.index = qc.index
		WHERE c.id = ?
		LIMIT 1
	`, componentID).Scan(&row).Error
	if err != nil {
		return nil, err
	}
	if row.ChartTypes == "" {
		return &ComponentChartMeta{}, nil
	}

	var types []string
	clean := strings.Trim(row.ChartTypes, "{}")
	if strings.HasPrefix(row.ChartTypes, "[") {
		_ = json.Unmarshal([]byte(row.ChartTypes), &types)
	} else if clean != "" {
		for _, t := range strings.Split(clean, ",") {
			trimmed := strings.Trim(strings.TrimSpace(t), `"`)
			if trimmed != "" {
				types = append(types, trimmed)
			}
		}
	}
	return &ComponentChartMeta{ChartTypes: types, HasMap: row.HasMap}, nil
}

func CreateComponent(index string, name string, city string, historyConfig json.RawMessage, mapFilter json.RawMessage, timeFrom string, timeTo *string, updateFreq *int64, updateFreqUnit string, source string, shortDesc string, longDesc string, useCase string, links pq.StringArray, contributors pq.StringArray) (cityComponent CityComponent, err error) {
    // component := Component{
	// 	Index:			 index,
    //     Name:            name,
    //     // HistoryConfig:   historyConfig,
    //     // MapFilter:       mapFilter,
    //     // TimeFrom:        timeFrom,
    //     // TimeTo:          timeTo,
    //     // UpdateFreq:      updateFreq,
    //     // UpdateFreqUnit:  updateFreqUnit,
    //     // Source:          source,
    //     // ShortDesc:       shortDesc,
    //     // LongDesc:        longDesc,
    //     // UseCase:         useCase,
    //     // Links:           links,
    //     // Contributors:    contributors,
    //     // CreatedAt:       time.Now(),
    //     // UpdatedAt:       time.Now(),
    // }

	// queryCharts := QueryCharts{
	// 	City: city,
	// 	HistoryConfig: historyConfig, 
	// 	MapFilter: mapFilter, 
	// 	TimeFrom: timeFrom, 
	// 	TimeTo: timeTo, 
	// 	UpdateFreq: updateFreq, 
	// 	UpdateFreqUnit: updateFreqUnit, 
	// 	Source: source, 
	// 	ShortDesc: shortDesc, 
	// 	LongDesc: longDesc, 
	// 	UseCase: useCase, 
	// 	Links: links, 
	// 	Contributors: contributors, 
	// 	CreatedAt: time.Now(),
	// 	UpdatedAt: time.Now(),
	// }

	// cityComponent = CityComponent{
	// 	Name: name,
	// 	City: city,
	// 	HistoryConfig: historyConfig, 
	// 	MapFilter: mapFilter, 
	// 	TimeFrom: timeFrom, 
	// 	TimeTo: timeTo, 
	// 	UpdateFreq: updateFreq, 
	// 	UpdateFreqUnit: updateFreqUnit, 
	// 	Source: source, 
	// 	ShortDesc: shortDesc, 
	// 	LongDesc: longDesc, 
	// 	UseCase: useCase, 
	// 	Links: links, 
	// 	Contributors: contributors,
	// 	CreatedAt: time.Now(),
	// 	UpdatedAt: time.Now(),
	// }

	// 建立 logic 還不確定，無法實作
	// 首先建立 components => 其次建立 query_charts ，但是 query_charts 有多個城市，不確定是一個建立還是同時建立

    // err = DBManager.Table("components").Create(&component).Error
    // if err != nil {
    //     return component, err
    // }

	// var tmp Component
	// err = DBManager.Table("components").Where("name = ?", name).First(&tmp).Error
	// if err != nil && errors.Is(err, gorm.ErrRecordNotFound){
	// 	err = DBManager.Table("components").Create(&component).Error
	// 	if err != nil {
	// 		return cityComponent, err
	// 	}	
	// }


	// err = DBManager.Table("query_charts").Create(&queryCharts).Error
    // if err != nil {
    //     return cityComponent, err
    // }

    return cityComponent, nil
}

func UpdateComponent(id int, city string, name string, historyConfig json.RawMessage, mapFilter json.RawMessage, timeFrom string, timeTo *string, updateFreq *int64, updateFreqUnit string, source string, shortDesc string, longDesc string, useCase string, links pq.StringArray, contributors pq.StringArray) (cityComponent CityComponent, err error) {
	component := Component{
		Name: name, 
		// HistoryConfig: historyConfig, 
		// MapFilter: mapFilter, 
		// TimeFrom: timeFrom, 
		// TimeTo: timeTo, 
		// UpdateFreq: updateFreq, 
		// UpdateFreqUnit: updateFreqUnit, 
		// Source: source, 
		// ShortDesc: shortDesc, 
		// LongDesc: longDesc, 
		// UseCase: useCase, 
		// Links: links, 
		// Contributors: contributors, 
		// UpdatedAt: time.Now()
	}

	queryCharts := QueryCharts{
		City: city,
		HistoryConfig: historyConfig, 
		MapFilter: mapFilter, 
		TimeFrom: timeFrom, 
		TimeTo: timeTo, 
		UpdateFreq: updateFreq, 
		UpdateFreqUnit: updateFreqUnit, 
		Source: source, 
		ShortDesc: shortDesc, 
		LongDesc: longDesc, 
		UseCase: useCase, 
		Links: links, 
		Contributors: contributors, 
		UpdatedAt: time.Now(),
	}

	cityComponent = CityComponent{
		Name: name,
		City: city,
		HistoryConfig: historyConfig, 
		MapFilter: mapFilter, 
		TimeFrom: timeFrom, 
		TimeTo: timeTo, 
		UpdateFreq: updateFreq, 
		UpdateFreqUnit: updateFreqUnit, 
		Source: source, 
		ShortDesc: shortDesc, 
		LongDesc: longDesc, 
		UseCase: useCase, 
		Links: links, 
		Contributors: contributors, 
		UpdatedAt: time.Now(),
	}

	
	var tmp Component
	err = DBManager.Table("components").Where("id = ?", id).First(&tmp).Error
	if err != nil{
		return cityComponent, err
	}

	err = DBManager.Table("components").Where("id = ?", id).Updates(&component).Error
	if err != nil {
		return cityComponent, err
	}

	err = DBManager.Table("query_charts").Where("index = ?", tmp.Index).Where("city = ?", city).Updates(&queryCharts).Error
	if err != nil {
		return cityComponent, err
	}

	err = DBManager.Table("components").Select("*").Joins("LEFT Join query_charts ON components.index = query_charts.index").Where("components.id = ?", id).Where("query_charts.city = ?", city).First(&cityComponent).Error
	if err != nil {
		return cityComponent, err
	}
	return cityComponent, nil
}

func UpdateComponentChartConfig(index string, color pq.StringArray, types pq.StringArray, unit string) (chartConfig ComponentChart, err error) {
	chartConfig = ComponentChart{Color: color, Types: types, Unit: unit}

	err = DBManager.Table("component_charts").Where("index = ?", index).Updates(&chartConfig).Error
	if err != nil {
		return chartConfig, err
	}

	err = DBManager.Where("index = ?", index).First(&chartConfig).Error
	if err != nil {
		return chartConfig, err
	}
	return chartConfig, nil
}

func UpdateComponentMapConfig(id int, index string, title string, mapType string, source string, size *string, icon *string, paint *json.RawMessage, property *json.RawMessage) (mapConfig ComponentMap, err error) {
	mapConfig = ComponentMap{Index: index, Title: title, Type: mapType, Source: source, Size: size, Icon: icon, Paint: paint, Property: property}

	err = DBManager.Table("component_maps").Where("id = ?", id).Updates(&mapConfig).Error
	if err != nil {
		return mapConfig, err
	}

	err = DBManager.Where("id = ?", id).First(&mapConfig).Error
	if err != nil {
		return mapConfig, err
	}
	return mapConfig, nil
}

func DeleteComponent(id int, index string, mapConfigIDs pq.Int64Array) (deleteChartStatus bool, deleteMapStatus bool, err error) {
	// 1. Delete component config
	err = DBManager.Table("components").Where("id = ?", id).Delete(Component{}).Error
	if err != nil {
		return false, false, err
	}

	// 2. Delete the chart config
	err = DBManager.Table("component_charts").Where("index = ?", index).Delete(ComponentChart{}).Error
	if err != nil {
		return false, false, err
	}

	// 3. Loop through mapconfigIds if it exists and delete the map config if no other components are using it
	if len(mapConfigIDs) > 0 {
		for _, mapConfigID := range mapConfigIDs {
			var mapConfigCount int64
			DBManager.Table("components").Where("map_config_ids @> ARRAY[?]::integer[]", mapConfigID).Count(&mapConfigCount)
			if mapConfigCount == 0 {
				err = DBManager.Table("component_maps").Where("id = ?", mapConfigID).Delete(ComponentMap{}).Error
			}
		}
	}
	if err != nil {
		return true, false, err
	}

	return true, true, nil
}

/* ----- Vue Component Models ----- */

// VueComponentResult represents a Vue component search result from Qdrant
type VueComponentResult struct {
	ID                string                 `json:"id"`
	Name              string                 `json:"name"`
	Path              string                 `json:"path"`
	Category          string                 `json:"category"`
	Description       string                 `json:"description"`
	Purpose           []string               `json:"purpose"`
	Props             map[string]string      `json:"props"`
	Tags              []string               `json:"tags"`
	Dependencies      []string               `json:"dependencies"`
	UsageExample      string                 `json:"usage_example"`
	RelatedComponents []string               `json:"related_components"`
	Score             float64                `json:"score"`
}

// GetVueComponentByQuery searches for Vue components using vector similarity
func GetVueComponentByQuery(queryString string, limit int, scoreThreshold float64) (results []VueComponentResult, err error) {
	// This function will be called by the AI service to search for Vue components
	// It communicates with the component search API endpoint which uses Qdrant
	
	// For now, return empty results - this will be populated by the component indexer service
	// In production, this should call the component search service via HTTP
	
	// Placeholder implementation
	results = make([]VueComponentResult, 0)
	return results, nil
}
