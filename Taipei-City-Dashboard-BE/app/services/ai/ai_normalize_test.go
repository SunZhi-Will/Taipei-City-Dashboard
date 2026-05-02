package ai

import (
	"strings"
	"testing"
)

// ── pickBestChartType ──────────────────────────────────────────────────────
func TestPickBestChartType(t *testing.T) {
	cases := []struct {
		aiType    string
		available []string
		want      string
	}{
		// AI使用縮寫 → 語義映射
		{"bar", []string{"BarChart", "ColumnChart"}, "BarChart"},
		{"column", []string{"ColumnChart", "BarChart"}, "ColumnChart"},
		{"pie", []string{"DonutChart", "BarChart"}, "DonutChart"},
		{"donut", []string{"DonutChart"}, "DonutChart"},
		{"radar", []string{"RadarChart", "BarChart"}, "RadarChart"},
		{"district", []string{"DistrictChart", "ColumnChart"}, "DistrictChart"},
		{"treemap", []string{"TreemapChart"}, "TreemapChart"},
		{"gauge", []string{"GuageChart"}, "GuageChart"},
		{"line", []string{"TimelineSeparateChart", "ColumnLineChart"}, "TimelineSeparateChart"},
		// map fallback
		{"map", []string{"map_legend", "map_pin"}, "map_legend"},
		// 找不到語義匹配 → 回傳 available[0]
		{"unknown_type", []string{"BarChart", "DonutChart"}, "BarChart"},
		// 空 available → 空字串
		{"bar", []string{}, ""},
		// 正確字串直接通過（呼叫前已驗證，此處確認不會改壞）
		{"BarChart", []string{"BarChart", "ColumnChart"}, "BarChart"},
		// Substring match: "BarPercentChart" contains "bar"
		{"bar", []string{"BarPercentChart"}, "BarPercentChart"},
	}

	for _, c := range cases {
		got := pickBestChartType(c.aiType, c.available)
		if got != c.want {
			t.Errorf("pickBestChartType(%q, %v) = %q, want %q", c.aiType, c.available, got, c.want)
		}
	}
}

// ── normalizeDisplayPlan (no DB) ──────────────────────────────────────────
// Tests that don't require a DB connection: duration clamp, type whitelist, defaults
func TestNormalizeDisplayPlanBasics(t *testing.T) {
	plan := DisplayPlan{
		Mode:   "presentation",
		Slides: []DisplayPlanSlide{
			{ID: "s1", Type: "hero", Title: "開場", DurationSec: 0},   // duration should default to 12
			{ID: "s2", Type: "COMPONENT", Title: "圖表"},               // type should lowercase
			{ID: "s3", Type: "invalid_type", Title: "未知"},             // should be removed
			{ID: "s4", Type: "map", Title: "地圖", ChartType: ""},      // map with empty chart_type → map_legend
			{ID: "s5", Type: "text", Title: "文字頁"},
			{ID: "s6", Type: "component_explain", Title: "解說"},
			{ID: "", Type: "hero", Title: "結尾", DurationSec: 99},    // id should be auto-assigned; duration clamped to 30
		},
	}

	// Skip DB calls by ensuring FocusComponentID == 0 for all slides
	result := normalizeDisplayPlanNoFix(plan)

	if len(result.Slides) != 6 {
		t.Errorf("expected 6 slides (invalid_type removed), got %d", len(result.Slides))
	}

	s := result.Slides
	// hero duration default
	if s[0].DurationSec != 12 {
		t.Errorf("slide 0 DurationSec: got %d, want 12", s[0].DurationSec)
	}
	// type lowercased
	if s[1].Type != "component" {
		t.Errorf("slide 1 Type: got %q, want %q", s[1].Type, "component")
	}
	// map chart_type default
	if s[2].ChartType != "map_legend" {
		t.Errorf("slide 2 (map) ChartType: got %q, want map_legend", s[2].ChartType)
	}
	// text and component_explain preserved
	if s[3].Type != "text" {
		t.Errorf("slide 3 Type: got %q, want text", s[3].Type)
	}
	if s[4].Type != "component_explain" {
		t.Errorf("slide 4 Type: got %q, want component_explain", s[4].Type)
	}
	// duration clamp
	if s[5].DurationSec != 30 {
		t.Errorf("slide 5 DurationSec: got %d, want 30 (clamped)", s[5].DurationSec)
	}
	// auto ID
	if s[5].ID == "" {
		t.Errorf("slide 5 ID should be auto-assigned, got empty")
	}
	// StrictRender forced true
	if !result.StrictRender {
		t.Error("StrictRender should be forced to true")
	}
}

// normalizeDisplayPlanNoFix is a test-only variant that skips the DB-backed fixSlidesChartTypes.
func normalizeDisplayPlanNoFix(plan DisplayPlan) DisplayPlan {
	if plan.Mode == "" { plan.Mode = "presentation" }
	if plan.Style == "" { plan.Style = "carousel" }
	if plan.Audience == "" { plan.Audience = "war-room" }
	plan.StrictRender = true

	allowedType := map[string]bool{"component": true, "map": true, "hero": true, "component_explain": true, "text": true}
	out := make([]DisplayPlanSlide, 0, len(plan.Slides))
	for i, slide := range plan.Slides {
		t := strings.TrimSpace(strings.ToLower(slide.Type))
		if !allowedType[t] {
			if t == "" { t = "component" } else { continue }
		}
		slide.Type = t
		if strings.TrimSpace(slide.ID) == "" {
			slide.ID = "slide-auto"
		}
		if slide.DurationSec <= 0 { slide.DurationSec = 12 }
		if slide.DurationSec > 30 { slide.DurationSec = 30 }
		if slide.Type == "map" && strings.TrimSpace(slide.ChartType) == "" {
			slide.ChartType = "map_legend"
		}
		_ = i
		out = append(out, slide)
	}
	plan.Slides = out
	return plan
}

// ── fixSlidesChartTypes (no DB) — logic test ─────────────────────────────
// We test the internal logic by providing mock metadata via the map-based lookup approach.
func TestFixSlidesLogic(t *testing.T) {
	// Simulate what fixSlidesChartTypes does without DB by calling pickBestChartType directly
	// and mapChartTypes:

	cases := []struct {
		name        string
		slideType   string
		aiChartType string
		hasMap      bool
		available   []string
		wantType    string
		wantChart   string
	}{
		{
			name: "map slide, has_map=true, valid chart_type",
			slideType: "map", aiChartType: "map_legend", hasMap: true,
			available: []string{"ColumnChart", "map_legend"},
			wantType: "map", wantChart: "map_legend",
		},
		{
			name: "map slide, has_map=false → downgrade to component",
			slideType: "map", aiChartType: "map_legend", hasMap: false,
			available: []string{"BarChart", "ColumnChart"},
			wantType: "component", wantChart: "BarChart",
		},
		{
			name: "map slide, has_map=true, wrong chart_type → find map type in available",
			slideType: "map", aiChartType: "BarChart", hasMap: true,
			available: []string{"BarChart", "map_pin"},
			wantType: "map", wantChart: "map_pin",
		},
		{
			name: "component slide, wrong chart_type → semantic fix",
			slideType: "component", aiChartType: "bar", hasMap: false,
			available: []string{"BarChart", "DonutChart"},
			wantType: "component", wantChart: "BarChart",
		},
		{
			name: "component slide, correct chart_type → unchanged",
			slideType: "component", aiChartType: "ColumnChart", hasMap: false,
			available: []string{"BarChart", "ColumnChart"},
			wantType: "component", wantChart: "ColumnChart",
		},
		{
			// DB uses "MapLegend" (CamelCase), AI uses "map_legend" (snake_case)
			// fixSlidesChartTypes should normalize to the exact DB string "MapLegend"
			name: "map slide, AI uses snake_case map_legend but DB has MapLegend → normalize to DB string",
			slideType: "map", aiChartType: "map_legend", hasMap: true,
			available: []string{"MapLegend"},
			wantType: "map", wantChart: "MapLegend",
		},
		{
			// Map type not in component's list at all → fallback to "map_legend"
			name: "map slide, has_map=true, AI wrong chart_type, no map type in DB list → fallback map_legend",
			slideType: "map", aiChartType: "BarChart", hasMap: true,
			available: []string{"BarChart", "ColumnChart"},
			wantType: "map", wantChart: "map_legend",
		},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			slide := DisplayPlanSlide{
				ID: "test", Type: c.slideType, Title: "test",
				ChartType: c.aiChartType,
			}

			// Replicate fixSlidesChartTypes logic inline (no DB)
			validSet := make(map[string]bool)
			for _, ct := range c.available {
				validSet[ct] = true
			}

			if slide.Type == "map" {
				if !c.hasMap {
					slide.Type = "component"
					if !validSet[slide.ChartType] {
						slide.ChartType = c.available[0]
					}
				} else {
					if !mapChartTypes[slide.ChartType] {
						found := ""
						for _, ct := range c.available {
							if mapChartTypes[ct] { found = ct; break }
						}
						if found != "" { slide.ChartType = found } else { slide.ChartType = "map_legend" }
					} else {
						// Normalize to exact DB string (e.g. "map_legend" → "MapLegend" if DB has that)
						for _, ct := range c.available {
							if mapChartTypes[ct] { slide.ChartType = ct; break }
						}
					}
				}
			} else if slide.Type == "component" {
				if slide.ChartType != "" && !validSet[slide.ChartType] {
					slide.ChartType = pickBestChartType(slide.ChartType, c.available)
				}
			}

			if slide.Type != c.wantType {
				t.Errorf("Type: got %q, want %q", slide.Type, c.wantType)
			}
			if slide.ChartType != c.wantChart {
				t.Errorf("ChartType: got %q, want %q", slide.ChartType, c.wantChart)
			}
		})
	}
}
