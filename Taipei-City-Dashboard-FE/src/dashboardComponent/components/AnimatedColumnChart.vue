<!-- 每月不合格/合格變化動畫柱狀圖 -->
<script setup>
import { ref, computed, watch, onUnmounted } from "vue";
import VueApexCharts from "vue3-apexcharts";
import { useMapStore } from "../../store/mapStore";
import { useTimeStore } from "../../store/timeStore";

const props = defineProps(["chart_config", "activeChart", "series", "map_config"]);

const mapStore = useMapStore();
const timeStore = useTimeStore();

const mapSyncIndex = computed(() => props.map_config?.[0]?.index ?? null);

// Extract sorted months + per-month series from the time series data
// series format: [{name: "市場A", data: [{x: "2026-04-01T...", y: 8}, ...]}]
const monthlyData = computed(() => {
	if (!props.series?.length) return { months: [], byMonth: {} };
	const byMonth = {};
	for (const s of props.series) {
		for (const pt of s.data || []) {
			const month = pt.x?.slice(0, 7); // "YYYY-MM"
			if (!month) continue;
			if (!byMonth[month]) byMonth[month] = {};
			byMonth[month][s.name] = pt.y ?? 0;
		}
	}
	const months = Object.keys(byMonth).sort();
	return { months, byMonth };
});

const seriesNames = computed(() => props.series?.map((s) => s.name) ?? []);

const isPlaying  = ref(false);
const currentIdx = ref(0);
let playTimer    = null;

const currentMonth = computed(() => monthlyData.value.months[currentIdx.value] ?? null);

function formatMonthLabel(ym) {
	if (!ym) return "";
	const [y, m] = ym.split("-");
	return `${y} 年 ${parseInt(m, 10)} 月`;
}

// Build ApexCharts series for the current month
const currentSeries = computed(() => {
	const { byMonth } = monthlyData.value;
	const m = currentMonth.value;
	if (!m) return [];
	return [{
		name: "不合格",
		data: seriesNames.value.map((name) => byMonth[m]?.[name] ?? 0),
	}];
});

const chartOptions = computed(() => ({
	chart: {
		toolbar: { show: false },
		animations: {
			enabled: true,
			easing: "easeinout",
			speed: 600,
			dynamicAnimation: { enabled: true, speed: 500 },
		},
	},
	colors: props.chart_config?.color ?? ["#E74C3C"],
	dataLabels: { enabled: true, style: { fontSize: "11px" } },
	grid: { show: false },
	plotOptions: {
		bar: { borderRadius: 4, columnWidth: "55%" },
	},
	tooltip: { enabled: true },
	xaxis: {
		categories: seriesNames.value,
		axisBorder: { color: "#555" },
		axisTicks:  { show: false },
	},
	yaxis: { min: 0, title: { text: props.chart_config?.unit ?? "件" } },
}));

function applyMonth(idx) {
	currentIdx.value = idx;
	// Sync map if connected
	if (mapSyncIndex.value) {
		const m = monthlyData.value.months[idx];
		if (m) mapStore.setMapMonth(mapSyncIndex.value, m);
	}
}

function togglePlay() {
	if (isPlaying.value) {
		clearInterval(playTimer);
		playTimer = null;
		isPlaying.value = false;
	} else {
		isPlaying.value = true;
		playTimer = setInterval(() => {
			const next = (currentIdx.value + 1) % monthlyData.value.months.length;
			applyMonth(next);
		}, 1500);
	}
}

function onMonthSelect(ym) {
	isPlaying.value = false;
	clearInterval(playTimer);
	playTimer = null;
	const idx = monthlyData.value.months.indexOf(ym);
	if (idx >= 0) applyMonth(idx);
}

watch(
	() => monthlyData.value.months,
	(months) => {
		if (months.length > 0) currentIdx.value = months.length - 1;
	},
	{ immediate: true },
);

onUnmounted(() => {
	clearInterval(playTimer);
	if (isPlaying.value && mapSyncIndex.value) mapStore.stopMonthAnimation();
});
</script>

<template>
  <div v-if="activeChart === 'AnimatedColumnChart' && monthlyData.months.length > 0">
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
        :max="monthlyData.months.length - 1"
        :value="currentIdx"
        @input="onMonthSelect(monthlyData.months[$event.target.value])"
      >
      <span class="animcol-month">{{ formatMonthLabel(currentMonth) }}</span>
    </div>

    <VueApexCharts
      width="100%"
      height="210px"
      type="bar"
      :options="chartOptions"
      :series="currentSeries"
    />
  </div>
</template>

<style scoped lang="scss">
.animcol-controls {
	display: flex;
	flex-direction: row;
	align-items: center;
	gap: 12px;
	padding: 4px 0;
	margin-bottom: 6px;
	border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.animcol-month {
	font-size: 0.8rem;
	font-weight: 700;
	color: var(--color-highlight);
	white-space: nowrap;
	line-height: 1;
	letter-spacing: 0.02em;
	min-width: 90px;
	text-align: right;
}


.animcol-playbtn {
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
</style>
