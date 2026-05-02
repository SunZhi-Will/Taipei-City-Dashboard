<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { computed, ref, onUnmounted } from "vue";
import VueApexCharts from "vue3-apexcharts";
import { useTimeStore } from "../../store/timeStore";
import { useMapStore } from "../../store/mapStore";

const props = defineProps([
	"chart_config",
	"activeChart",
	"series",
	"map_config",
	"map_filter",
	"map_filter_on",
	"showColorLegend",
]);

const emits = defineEmits([
	"filterByParam",
	"filterByLayer",
	"clearByParamFilter",
	"clearByLayerFilter",
	"fly"
]);

function toFiniteNumber(value) {
	const parsed = typeof value === "number" ? value : Number(value);
	return Number.isFinite(parsed) ? parsed : 0;
}
const timeStore = useTimeStore();
const mapStore  = useMapStore();

// How many data points to show before summing all remaining points into "other"
const steps = ref(100);

const getY = (item) => (typeof item === "object" && item !== null ? item.y : item);
const getX = (item, idx) =>
	typeof item === "object" && item !== null
		? item.x
		: props.chart_config?.categories?.[idx] ?? "";

// --- GeoJSON-based live counts via pre-computed monthResultCounts ---
const mapSyncIndex = computed(() => props.map_config?.[0]?.index ?? null);

const GEO_LABELS = ["合格", "正在複查", "不合格"];

const geoRawData = computed(() => {
	const idx = mapSyncIndex.value;
	if (!idx) return null;
	const allCounts = timeStore.monthResultCounts[idx];
	if (!allCounts) return null;

	const month = timeStore.selectedMonth;
	if (month) {
		const mc = allCounts[month];
		if (!mc) return [0, 0, 0];
		return [mc["合格"] ?? 0, mc["正在複查"] ?? 0, mc["不合格"] ?? 0];
	}
	// No month selected: aggregate all months
	const total = [0, 0, 0];
	for (const mc of Object.values(allCounts)) {
		total[0] += mc["合格"] ?? 0;
		total[1] += mc["正在複查"] ?? 0;
		total[2] += mc["不合格"] ?? 0;
	}
	return total;
});

// Filter out zero-value categories (e.g. 正在複查 not present in wholesale)
const geoFiltered = computed(() => {
	if (geoRawData.value === null) return null;
	const vals = geoRawData.value;
	const baseColors = props.chart_config.color;
	const pairs = GEO_LABELS
		.map((l, i) => ({ label: l, value: vals[i], color: baseColors[i] }))
		.filter((p) => p.value > 0);
	if (!pairs.length) return { series: [], labels: [], colors: baseColors };
	return {
		series: pairs.map((p) => p.value),
		labels: pairs.map((p) => p.label),
		colors: pairs.map((p) => p.color),
	};
});

// --- Animation controls (shown when GeoJSON has monthly snapshots) ---
// availableMonths: newest→oldest (from store); sliderMonths: oldest→newest (left→right)
const availableMonths = computed(() =>
	mapSyncIndex.value ? timeStore.getAvailableMonths(mapSyncIndex.value) : []
);
const sliderMonths = computed(() => [...availableMonths.value].reverse());
const showAnimControls = computed(() => availableMonths.value.length > 1);
const isPlaying    = ref(false);
const currentMonth = computed(() => timeStore.selectedMonth ?? availableMonths.value[0] ?? null);

// Slider position (0 = oldest, max = newest) — reactive to selectedMonth so it moves during playback
const sliderIdx = computed(() => {
	const m = currentMonth.value;
	if (!m) return sliderMonths.value.length - 1;
	const idx = sliderMonths.value.indexOf(m);
	return idx >= 0 ? idx : sliderMonths.value.length - 1;
});

function formatMonthLabel(ym) {
	if (!ym) return "最新";
	const [y, m] = ym.split("-");
	return `${y} 年 ${parseInt(m, 10)} 月`;
}

function togglePlay() {
	if (!mapSyncIndex.value) return;
	if (isPlaying.value) {
		mapStore.stopMonthAnimation();
		isPlaying.value = false;
	} else {
		mapStore.animateMonths(mapSyncIndex.value, animIntervalMs.value);
		isPlaying.value = true;
	}
}

function onSliderInput(e) {
	const idx   = parseInt(e.target.value);
	const month = sliderMonths.value[idx];
	if (!month || !mapSyncIndex.value) return;
	// Stop playback when user manually drags
	if (isPlaying.value) {
		mapStore.stopMonthAnimation();
		isPlaying.value = false;
	}
	mapStore.setMapMonth(mapSyncIndex.value, month);
}

onUnmounted(() => {
	if (isPlaying.value) mapStore.stopMonthAnimation();
});

// --- Parse series from API (fallback when no map link) ---
const parsedSeries = computed(() => {
	// Priority 1: live GeoJSON counts when map is linked
	if (geoFiltered.value !== null) return geoFiltered.value.series;

	if (!props.series?.length) return [];

	// map_legend format: [{name, type, icon, value}]
	if (props.series[0]?.value !== undefined) {
		return props.series.slice(0, steps.value).map((s) => s.value ?? 0);
	}

	// two_d format: [{data: [{x, y}]}]
	if (!props.series[0]?.data) return [];
	const toParse = [...props.series[0].data];
	if (toParse.length <= steps.value) {
		return toParse.map((item) => getY(item));
	}
	let output = [];
	for (let i = 0; i < steps.value; i++) output.push(getY(toParse[i]));
	const toSum = toParse.slice(steps.value);
	let sum = 0;
	toSum.forEach((el) => (sum += getY(el)));
	output.push(sum);
	return output;
});

const parsedLabels = computed(() => {
	if (geoFiltered.value !== null) return geoFiltered.value.labels;

	if (!props.series?.length) return [];

	if (props.series[0]?.value !== undefined) {
		return props.series.slice(0, steps.value).map((s) => s.name ?? "");
	}

	if (!props.series[0]?.data) return [];
	const toParse = [...props.series[0].data];
	if (toParse.length <= steps.value) {
		return toParse.map((item, idx) => getX(item, idx));
	}
	let output = [];
	for (let i = 0; i < steps.value; i++) output.push(getX(toParse[i], i));
	output.push("其他");
	return output;
});

const sum = computed(() => {
	if (!parsedSeries.value.length) return 0;
	return Math.round(parsedSeries.value.reduce((a, b) => a + b) * 100) / 100;
});

// Interval for animation (read from map property config, default 1500ms)
const animIntervalMs = computed(() => {
	const prop = props.map_config?.[0]?.property;
	if (Array.isArray(prop)) {
		const a = prop.find((p) => p._animate);
		if (a?.interval_ms) return a.interval_ms;
	}
	return 1500;
});

// Reactive chartOptions so labels update when month changes
const chartOptions = computed(() => ({
	chart: {
		offsetY: 10,
		animations: {
			enabled: true,
			easing: "easeinout",
			dynamicAnimation: {
				enabled: true,
				speed: Math.round(animIntervalMs.value * 0.8),
			},
		},
	},
	colors: geoFiltered.value
		? geoFiltered.value.colors
		: parsedSeries.value.length >= steps.value
			? [...props.chart_config.color, "#848c94"]
			: props.chart_config.color,
	dataLabels: {
		formatter: function (_val, { seriesIndex, w }) {
			let value = w.globals.labels[seriesIndex];
			return value.length > 7 ? value.slice(0, 6) + "..." : value;
		},
	},
	labels: parsedLabels.value,
	legend: { show: false },
	plotOptions: {
		pie: {
			dataLabels: { offset: 15 },
			donut: { size: "77.5%" },
		},
	},
	stroke: { colors: ["#282a2c"], show: true, width: 3 },
	tooltip: {
		followCursor: false,
		custom: function ({ series, seriesIndex, w }) {
			return (
				'<div class="chart-tooltip">' +
				"<h6>" +
				w.globals.labels[seriesIndex] +
				"</h6>" +
				"<span>" +
				series[seriesIndex] +
				` ${props.chart_config.unit ?? ''}` +
				"</span>" +
				"</div>"
			);
		},
	},
}));

const selectedIndex = ref(null);

function handleDataSelection(_e, _chartContext, config) {
	if (!props.map_filter || !props.map_filter_on) {
		return;
	}
	if (
		`${config.dataPointIndex}-${config.seriesIndex}` !== selectedIndex.value
	) {
		if (props.map_filter.mode === "byParam") {
			emits(
				"filterByParam",
				props.map_filter,
				props.map_config,
				config.w.globals.labels[config.dataPointIndex],
				null
			);
		} else if (props.map_filter.mode === "byLayer") {
			emits(
				"filterByLayer",
				props.map_config,
				config.w.globals.labels[config.dataPointIndex]
			);
		}
		selectedIndex.value = `${config.dataPointIndex}-${config.seriesIndex}`;
	} else {
		if (props.map_filter.mode === "byParam") {
			emits("clearByParamFilter", props.map_config);
		} else if (props.map_filter.mode === "byLayer") {
			emits("clearByLayerFilter", props.map_config);
		}
		selectedIndex.value = null;
	}
}
</script>

<template>
  <div
    v-if="activeChart === 'DonutChart' && parsedSeries.length > 0"
    class="donutchart-wrapper"
  >
    <div
      v-if="showAnimControls"
      class="donutchart-anim"
    >
      <button
        class="donutchart-anim-btn"
        :title="isPlaying ? '暫停' : '播放'"
        @click="togglePlay"
      >
        <span class="material-icons-round">{{ isPlaying ? 'pause' : 'play_arrow' }}</span>
      </button>
      <input
        type="range"
        class="donutchart-anim-slider"
        :min="0"
        :max="sliderMonths.length - 1"
        :value="sliderIdx"
        @input="onSliderInput"
      >
      <span class="donutchart-anim-month">{{ formatMonthLabel(currentMonth) }}</span>
    </div>

    <div class="donutchart">
      <VueApexCharts
        width="100%"
        height="100%"
        type="donut"
        :options="chartOptions"
        :series="parsedSeries"
        @data-point-selection="handleDataSelection"
      />
      <div class="donutchart-title">
        <h5>總合</h5>
        <h6>{{ sum }}</h6>
      </div>
    </div>
		<div
			v-if="showColorLegend"
			class="donutchart-legend"
		>
			<div
				v-for="item in donutLegendItems"
				:key="`legend-${item.label}`"
				class="donutchart-legend-item"
			>
				<span
					class="donutchart-legend-swatch"
					:style="{ backgroundColor: item.color }"
				/>
				<span class="donutchart-legend-label">{{ item.label }}</span>
			</div>
		</div>
  </div>
</template>

<style scoped lang="scss">
.donutchart-wrapper {
	display: flex;
	flex-direction: column;
	width: 100%;
	height: 100%;
	min-height: 0;  /* allow flex shrink */
	gap: 2px;
	overflow: hidden;
}

/* 時間控制：單排緊湊版 */
.donutchart-anim {
	flex-shrink: 0;
	display: flex;
	flex-direction: row;
	align-items: center;
	gap: 12px;
	padding: 4px 0;
	margin-bottom: 6px;
	border-bottom: 1px solid rgba(var(--color-border-rgb, 255, 255, 255), 0.1);

	&-month {
		font-size: 0.8rem;
		font-weight: 700;
		color: var(--color-highlight);
		white-space: nowrap;
		line-height: 1;
		letter-spacing: 0.02em;
		min-width: 90px;
		text-align: right;
	}


	&-btn {
		width: 28px;
		height: 28px;
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
			font-size: 18px;
			line-height: 1;
		}
	}

	&-slider {
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
}

.donutchart {
	flex: 1;
	min-height: 0;  /* allow flex shrink below content size */
	width: 100%;
	display: flex;
	justify-content: center;
	align-items: center;
	position: relative;
	overflow: hidden;

	:deep(.vue-apexcharts),
	:deep(.apexcharts-canvas),
	:deep(.apexcharts-svg) {
		width: 100% !important;
		height: 100% !important;
	}

	&-title {
		display: flex;
		align-items: center;
		justify-content: center;
		flex-direction: column;
		position: absolute;
		pointer-events: none;

		h5 {
			margin: 0;
			color: var(--color-complement-text);
		}

		h6 {
			margin: 0;
			color: var(--color-complement-text);
			font-size: var(--font-m);
			font-weight: 400;
		}
	}

	&-legend {
		position: absolute;
		left: 12px;
		right: 12px;
		bottom: 8px;
		display: flex;
		flex-wrap: wrap;
		gap: 8px 12px;
		align-items: center;
		justify-content: center;
		padding: 6px 10px;
		border-radius: 10px;
		background: rgba(2, 6, 23, 0.45);
		backdrop-filter: blur(4px);
		pointer-events: none;

		&-item {
			display: inline-flex;
			align-items: center;
			gap: 6px;
		}

		&-swatch {
			width: 10px;
			height: 10px;
			border-radius: 999px;
			flex-shrink: 0;
			border: 1px solid rgba(255, 255, 255, 0.3);
		}

		&-label {
			color: rgba(226, 232, 240, 0.95);
			font-size: 12px;
			line-height: 1.2;
		}
	}
}
</style>
