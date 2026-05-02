import { defineStore } from "pinia";

export const useTimeStore = defineStore("time", {
	state: () => ({
		// Currently selected month "YYYY-MM", or null = latest
		selectedMonth: null,
		// Cached GeoJSON metadata keyed by index
		geojsonData: {},
		// Pre-computed per-month result counts: { [index]: { [month]: { 合格, 正在複查, 不合格 } } }
		monthResultCounts: {},
	}),
	actions: {
		setMonth(month) {
			this.selectedMonth = month;
		},
		cacheGeojson(index, data) {
			this.geojsonData[index] = data;
			this._buildMonthResultCounts(index, data);
		},
		// Return available months newest→oldest (reads from metadata.available_months)
		getAvailableMonths(index) {
			const base = this.geojsonData[index];
			if (!base) return [];
			if (base.metadata?.available_months?.length) {
				return base.metadata.available_months;
			}
			// Fallback: scan features for month property
			const monthSet = new Set();
			for (const f of base.features) {
				if (f.properties?.month) monthSet.add(f.properties.month);
			}
			return [...monthSet].sort().reverse();
		},
		// Build per-month result category counts from embedded metadata or feature scan
		_buildMonthResultCounts(index, data) {
			// Prefer pre-computed stats embedded in GeoJSON metadata
			if (data?.metadata?.month_stats) {
				this.monthResultCounts[index] = data.metadata.month_stats;
				return;
			}
			// Fallback: scan flat features (monthly_flat format)
			const counts = {};
			for (const f of data?.features ?? []) {
				const month  = f.properties?.month;
				const result = f.properties?.result ?? "";
				if (!month) continue;
				if (!counts[month]) counts[month] = { 合格: 0, 正在複查: 0, 不合格: 0 };
				if (result.startsWith("A") || result === "合格") counts[month]["合格"]++;
				else if (result === "B1")      counts[month]["正在複查"]++;
				else if (result)               counts[month]["不合格"]++;
			}
			this.monthResultCounts[index] = counts;
		},
	},
});
