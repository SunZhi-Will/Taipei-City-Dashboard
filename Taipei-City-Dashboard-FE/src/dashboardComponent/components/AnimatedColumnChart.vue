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
    <!-- 控制列 -->
    <div class="animcol-controls">
      <span class="animcol-month">{{ formatMonthLabel(currentMonth) }}</span>
      <div class="animcol-playbar">
        <button
          class="animcol-playbtn"
          :title="isPlaying ? '暫停' : '播放月份動畫'"
          @click="togglePlay"
        >
          <span class="material-icons">{{ isPlaying ? 'pause' : 'play_arrow' }}</span>
        </button>
        <select
          :value="currentMonth"
          class="animcol-select"
          @change="onMonthSelect($event.target.value)"
        >
          <option
            v-for="m in [...monthlyData.months].reverse()"
            :key="m"
            :value="m"
          >
            {{ formatMonthLabel(m) }}
          </option>
        </select>
      </div>
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

<style scoped>
.animcol-controls {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 4px;
}

.animcol-month {
	font-size: 0.85rem;
	font-weight: 600;
	color: var(--color-complement-text);
}

.animcol-playbar {
	display: flex;
	align-items: center;
	gap: 4px;
}

.animcol-playbtn {
	background: transparent;
	border: 1px solid var(--color-border);
	border-radius: 4px;
	padding: 1px 4px;
	cursor: pointer;
	display: flex;
	align-items: center;
	color: var(--color-normal-text);
	transition: background 0.15s;
}
.animcol-playbtn:hover { background: var(--color-highlight); }
.animcol-playbtn .material-icons { font-size: 18px; }

.animcol-select {
	background: var(--color-component-background);
	color: var(--color-normal-text);
	border: 1px solid var(--color-border);
	border-radius: 4px;
	padding: 2px 6px;
	font-size: 0.8rem;
	cursor: pointer;
}
.animcol-select:focus { outline: none; border-color: var(--color-highlight); }
</style>
