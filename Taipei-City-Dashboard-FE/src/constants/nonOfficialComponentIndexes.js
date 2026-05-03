export const NON_OFFICIAL_COMPONENT_INDEXES = new Set([
	"aed_map",
	"aed_district_tpe",
	"indigenous_district_tpe",
	"indigenous_group_tpe",
	"migrant_workers_tpe",
	"long_term_care_abc_map",
	"long_term_care_abc_district_tpe",
]);

// 對應的儀表板 index（黑客松 2025 年新增非官方主題）
// 數據來源：user-added/2025-last-year/my-data/sql/03_dashboardmanager_inserts.sql
export const NON_OFFICIAL_DASHBOARD_INDEXES = new Set([
	"aed_tpe",                              // AED 分布
	"indigenous_social_tpe",                // 原住民族人口
	"migrant_workers_tpe",                  // 受聘僱移工
	"long_term_care_abc_tpe_dashboard",     // 長照ABC據點
]);

export const isOfficialComponent = (component) => {
	if (!component || typeof component !== "object") return true;
	return !NON_OFFICIAL_COMPONENT_INDEXES.has(component.index);
};

export const isOfficialDashboard = (dashboard) => {
	if (!dashboard || typeof dashboard !== "object") return true;
	return !NON_OFFICIAL_DASHBOARD_INDEXES.has(dashboard.index);
};
