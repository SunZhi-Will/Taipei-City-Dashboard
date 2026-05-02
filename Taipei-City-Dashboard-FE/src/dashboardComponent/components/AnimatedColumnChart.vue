<!-- 每月不合格/合格變化動畫柱狀圖 -->
<script setup>
import { ref, computed, watch, onUnmounted } from "vue";
import VueApexCharts from "vue3-apexcharts";
import { useMapStore } from "../../store/mapStore";
import { useTimeStore } from "../../store/timeStore";

const props = defineProps([
	"chart_config",
	"activeChart",
	"series",
	"map_config",
	"map_filter_on",
]);

const mapStore = useMapStore();
const timeStore = useTimeStore();
const RESULT_ORDER = ["合格", "正在複查", "不合格"];

const mapSyncIndex = computed(() => props.map_config?.[0]?.index ?? null);
const canSyncMapMonth = computed(() => Boolean(props.map_filter_on && mapSyncIndex.value));

function isYearMonth(value) {
	return typeof value === "string" && /^\d{4}-\d{2}/.test(value);
}

// Extract year-frames from time series data.
// Each frame key is a 4-digit year ("YYYY"); within each frame, byMonth[year][seriesName] = value.
// series format: [{name: "01月", data: [{x: "2016-01-01T...", y: 38}, ...]}]
// All rows in the same year share the same year prefix, so slice(0,4) groups them into year frames.
const monthlyData = computed(() => {
	if (!props.series?.length) return { months: [], byMonth: {} };
	const byMonth = {};
	for (const s of props.series) {
		for (const pt of s.data || []) {
			if (!isYearMonth(pt.x)) continue;
			const year = pt.x.slice(0, 4); // "YYYY" — one frame per year
			if (!year) continue;
			if (!byMonth[year]) byMonth[year] = {};
			// Use addition to handle multiple data points for the same year+series
			byMonth[year][s.name] = (byMonth[year][s.name] ?? 0) + (pt.y ?? 0);
		}
	}
	const months = Object.keys(byMonth).sort();
	return { months, byMonth };
});

const mapMonthlyData = computed(() => {
	const idx = mapSyncIndex.value;
	if (!idx) return { months: [], byMonth: {} };
	const counts = timeStore.monthResultCounts[idx];
	if (!counts) return { months: [], byMonth: {} };
	const months = Object.keys(counts).sort();
	const byMonth = {};
	for (const month of months) {
		const monthCounts = counts[month] ?? {};
		byMonth[month] = {
			"合格": monthCounts["合格"] ?? 0,
			"正在複查": monthCounts["正在複查"] ?? 0,
			"不合格": monthCounts["不合格"] ?? 0,
		};
	}
	return { months, byMonth };
});

const hasSeriesMonthData = computed(() => monthlyData.value.months.length > 0);
const effectiveMonthlyData = computed(() =>
	hasSeriesMonthData.value ? monthlyData.value : mapMonthlyData.value,
);

const seriesNames = computed(() => {
	if (hasSeriesMonthData.value) {
		return props.series?.map((s) => s.name) ?? [];
	}
	return RESULT_ORDER.filter((name) =>
		effectiveMonthlyData.value.months.some(
			(month) => (effectiveMonthlyData.value.byMonth[month]?.[name] ?? 0) > 0,
		),
	);
});

const isPlaying  = ref(false);
const currentIdx = ref(0);
let playTimer    = null;

const currentMonth = computed(() =>
	effectiveMonthlyData.value.months[currentIdx.value] ?? null,
);

const animIntervalMs = computed(() => {
	const prop = props.map_config?.[0]?.property;
	if (Array.isArray(prop)) {
		const animateConfig = prop.find((p) => p._animate);
		if (animateConfig?.interval_ms) {
			return Math.max(900, Number(animateConfig.interval_ms));
		}
	}
	return 1500;
});

function formatMonthLabel(key) {
	if (!key) return "";
	// Pure year key (e.g. "2016") — used when series data drives year-frame animation
	if (/^\d{4}$/.test(key)) return `${key} 年`;
	// YYYY-MM key (e.g. "2025-03") — used for map-synced month animation
	if (!isYearMonth(key)) return "";
	const [y, m] = key.split("-");
	return `${y} 年 ${parseInt(m, 10)} 月`;
}

// Build ApexCharts series for the current month
const currentSeries = computed(() => {
	const { byMonth } = effectiveMonthlyData.value;
	const m = currentMonth.value;
	if (!m) return [];
	return [{
		name: "件數",
		data: seriesNames.value.map((name) => byMonth[m]?.[name] ?? 0),
	}];
});

// ✅ FIX: Use ref instead of computed to avoid recreating options object on each month change
// This prevents VueApexCharts from re-initializing the chart unnecessarily
const chartOptions = ref({
	chart: {
		toolbar: { show: false },
		animations: {
			enabled: true,
			easing: "easeout",
			speed: 900,  // 60% of default 1500ms; leaves 600ms buffer before next interval
			animateGradually: {
				// Disabled: stagger delay extends total animation past the setInterval window,
				// causing bars to be snapped mid-animation (appearing to "suddenly complete").
				// NOTE: delay must NOT be 0 — ApexCharts computes animationDelay = barIndex / delay
				// which gives Infinity, and Infinity * 0 (c=0 when disabled) = NaN in SVG.js.
				enabled: false,
				// delay MUST NOT be 0: ApexCharts computes animationDelay = barIndex / delay
				// With delay=0 → Infinity, then Infinity * 0 (c=0 when disabled) = NaN in SVG.js
				delay: 150,
			},
			dynamicAnimation: {
				enabled: true,
				speed: 900,
			},
		},
	},
	colors: ["#E74C3C"],
	dataLabels: { enabled: true, style: { fontSize: "11px" } },
	grid: { show: false },
	plotOptions: {
		bar: { borderRadius: 4, columnWidth: "55%" },
	},
	tooltip: {
		custom: function ({ series, seriesIndex, dataPointIndex, w }) {
			return (
				'<div class="chart-tooltip">' +
				"<h6>" +
				w.globals.labels[dataPointIndex] +
				"</h6>" +
				"<span>" +
				series[seriesIndex][dataPointIndex] +
				` ${props.chart_config?.unit ?? "件"}` +
				"</span>" +
				"</div>"
			);
		},
	},
	xaxis: {
		categories: [],
		axisBorder: { color: "#555" },
		axisTicks:  { show: false },
	},
	yaxis: { min: 0, title: { text: "件" } },
});

// Update chart configuration when series or animation interval changes
watch(
	[seriesNames, () => props.chart_config?.color, () => props.chart_config?.unit],
	([names, colors, unit]) => {
		chartOptions.value.xaxis.categories = names ?? [];
		chartOptions.value.colors = colors ?? ["#E74C3C"];
		chartOptions.value.yaxis.title.text = unit ?? "件";
	},
	{ immediate: true },
);

// Update animation speed when interval changes
watch(
	animIntervalMs,
	(ms) => {
		const speed = Math.round(ms * 0.6);
		chartOptions.value.chart.animations.speed = speed;
		chartOptions.value.chart.animations.dynamicAnimation.speed = speed;
	},
	{ immediate: true },
);

function applyMonth(idx) {
	currentIdx.value = idx;
	// Sync map if connected
	if (canSyncMapMonth.value) {
		const m = effectiveMonthlyData.value.months[idx];
		if (m) mapStore.setMapMonth(mapSyncIndex.value, m);
	}
}

function togglePlay() {
	if (isPlaying.value) {
		clearInterval(playTimer);
		playTimer = null;
		isPlaying.value = false;
	} else {
		if (!effectiveMonthlyData.value.months.length) return;
		isPlaying.value = true;
		playTimer = setInterval(() => {
			const next = (currentIdx.value + 1) % effectiveMonthlyData.value.months.length;
			applyMonth(next);
		}, animIntervalMs.value);
	}
}

function onMonthSelect(ym) {
	isPlaying.value = false;
	clearInterval(playTimer);
	playTimer = null;
	const idx = effectiveMonthlyData.value.months.indexOf(ym);
	if (idx >= 0) applyMonth(idx);
}

watch(
	() => effectiveMonthlyData.value.months,
	(months) => {
		if (months.length > 0) currentIdx.value = months.length - 1;
	},
	{ immediate: true },
);

onUnmounted(() => {
	clearInterval(playTimer);
	if (isPlaying.value && canSyncMapMonth.value) mapStore.stopMonthAnimation();
});
</script>

<template>
	<div
		 v-if="activeChart === 'AnimatedColumnChart' && effectiveMonthlyData.months.length > 0"
		class="animcol-wrapper"
	>
    <div class="animcol-controls">
      <button
        class="animcol-playbtn"
        :title="isPlaying ? '暫停' : '播放月份動畫'"
        @click="togglePlay"
      >
        <span class="material-icons-round">{{ isPlaying ? 'pause' : 'play_arrow' }}</span>
      </button>
      <input
        type="range"
        class="animcol-slider"
        :min="0"
				:max="effectiveMonthlyData.months.length - 1"
        :value="currentIdx"
				@input="onMonthSelect(effectiveMonthlyData.months[$event.target.value])"
      >
      <span class="animcol-month">{{ formatMonthLabel(currentMonth) }}</span>
    </div>

		<div class="animcol-chart">
			<VueApexCharts
				width="100%"
				height="100%"
				type="bar"
				:options="chartOptions"
				:series="currentSeries"
			/>
		</div>
  </div>
	<div
		v-else-if="activeChart === 'AnimatedColumnChart'"
		class="animcol-empty"
	>
		暫無可播放的月份資料
	</div>
</template>

<style scoped lang="scss">
.animcol-wrapper {
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
}

.animcol-chart {
	flex: 1;
	min-height: 310px;
}

.animcol-empty {
	display: flex;
	align-items: center;
	justify-content: center;
	height: 100%;
	min-height: 310px;
	color: rgba(255, 255, 255, 0.7);
	font-size: 0.95rem;
	letter-spacing: 0.02em;
}

.animcol-controls {
	display: flex;
	flex-direction: row;
	align-items: center;
	gap: 10px;
	padding: 6px 0;
	margin-bottom: 8px;
	border-bottom: 1px solid rgba(255, 255, 255, 0.1);
	min-height: 40px;
}

.animcol-month {
	font-size: 0.8rem;
	font-weight: 700;
	color: var(--color-highlight);
	white-space: nowrap;
	line-height: 1;
	letter-spacing: 0.02em;
	min-width: 92px;
	text-align: right;
}


.animcol-playbtn {
	width: 30px;
	height: 30px;
	background: rgba(var(--color-highlight-rgb, 90, 156, 248), 0.1);
	border: 1px solid rgba(var(--color-highlight-rgb, 90, 156, 248), 0.2) !important;
	border-radius: 50%;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	color: var(--color-highlight);
	transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
	flex-shrink: 0;

	&:hover {
		background: var(--color-highlight);
		color: #fff;
		transform: scale(1.1);
		box-shadow: 0 0 10px rgba(90, 156, 248, 0.4);
	}

	.material-icons-round {
		font-family: var(--font-icon);
		font-size: 18px;
		line-height: 1;
	}
}


.animcol-slider {
	flex: 1;
	min-width: 0;
	height: 6px;
	-webkit-appearance: none;
	appearance: none;
	background: rgba(255, 255, 255, 0.1);
	border-radius: 3px;
	outline: none;
	cursor: pointer;
	position: relative;
	overflow: visible;

	&::-webkit-slider-thumb {
		-webkit-appearance: none;
		appearance: none;
		width: 14px;
		height: 14px;
		border-radius: 50%;
		background: var(--color-highlight);
		border: 2px solid #fff;
		cursor: pointer;
		box-shadow: 0 0 8px rgba(0, 0, 0, 0.5), 0 0 4px var(--color-highlight);
		transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);

		&:hover {
			transform: scale(1.25);
			background: #fff;
			border-color: var(--color-highlight);
		}
	}

	&::-moz-range-thumb {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		background: var(--color-highlight);
		border: 2px solid #fff;
		cursor: pointer;
		box-shadow: 0 0 8px rgba(0, 0, 0, 0.5);
		transition: all 0.2s;
	}
}


@media (max-width: 760px) {
	.animcol-controls {
		flex-wrap: wrap;
		gap: 10px;
		align-items: flex-start;
	}

	.animcol-slider {
		order: 3;
		width: 100%;
		flex-basis: 100%;
	}

	.animcol-month {
		text-align: left;
		min-width: 0;
	}
}
</style>
