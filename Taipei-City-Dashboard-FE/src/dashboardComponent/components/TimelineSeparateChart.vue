<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { ref, computed, watch, onUnmounted } from "vue";
import VueApexCharts from "vue3-apexcharts";
import { useMapStore } from "../../store/mapStore";
import { useTimeStore } from "../../store/timeStore";

const props = defineProps(["chart_config", "activeChart", "series", "map_config"]);

const mapStore = useMapStore();
const timeStore = useTimeStore();

const localSeries = ref(JSON.parse(JSON.stringify(props.series)));

// GeoJSON index driven by this chart (first map_config entry)
const mapSyncIndex = computed(() => props.map_config?.[0]?.index ?? null);

const availableMonths = computed(() =>
	mapSyncIndex.value ? timeStore.getAvailableMonths(mapSyncIndex.value) : [],
);

const showControls = computed(() => availableMonths.value.length > 0);

// isPlaying tracks animation state
const isPlaying = ref(false);

// Current month from store (reactive)
const currentMonth = computed(() => timeStore.selectedMonth ?? availableMonths.value[0] ?? null);

// KPI stats for current month
const monthStats = computed(() =>
	mapSyncIndex.value && currentMonth.value
		? timeStore.getMonthStats(mapSyncIndex.value, currentMonth.value)
		: null,
);

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
		mapStore.animateMonths(mapSyncIndex.value, 1500);
		isPlaying.value = true;
	}
}

function onMonthSelect(month) {
	if (!mapSyncIndex.value) return;
	isPlaying.value = false;
	mapStore.setMapMonth(mapSyncIndex.value, month);
}

// Stop animation when component unmounts
onUnmounted(() => {
	if (isPlaying.value) mapStore.stopMonthAnimation();
});

const chartOptions = ref({
	chart: {
		toolbar: { show: false, tools: { zoom: false } },
	},
	colors: [...props.chart_config.color],
	dataLabels: { enabled: false },
	grid: { show: false },
	legend: { show: props.series.length > 1 },
	markers: { hover: { size: 5 }, size: 3, strokeWidth: 0 },
	stroke: {
		colors: [...props.chart_config.color],
		curve: "smooth",
		show: true,
		width: 2,
	},
	tooltip: {
		custom({ series, seriesIndex, dataPointIndex, w }) {
			return (
				'<div class="chart-tooltip">' +
				"<h6>" +
				`${parseTime(w.config.series[seriesIndex].data[dataPointIndex].x)}` +
				` - ${w.globals.seriesNames[seriesIndex]}` +
				"</h6>" +
				"<span>" +
				series[seriesIndex][dataPointIndex] +
				` ${props.chart_config.unit}` +
				"</span>" +
				"</div>"
			);
		},
	},
	xaxis: {
		axisBorder: { color: "#555", height: "0.8" },
		axisTicks: { show: false },
		crosshairs: { show: false },
		labels: { datetimeUTC: false },
		tooltip: { enabled: false },
		type: "datetime",
	},
	yaxis: { min: 0 },
});

function parseTime(time) {
	return time.replace("T", " ").replace("+08:00", " ");
}

watch(
	() => props.series,
	(newVal) => {
		if (!newVal || newVal.length === 0) return;
		localSeries.value = JSON.parse(JSON.stringify(newVal));

		const timestamps =
			newVal?.[0]?.data?.map((p) => new Date(p.x).getTime()) || [];
		if (timestamps.length < 2) return;

		const newDiff = Math.max(...timestamps) - Math.min(...timestamps);

		if (newDiff >= 3 * 31536000000) {
			localSeries.value.forEach((item) => {
				item.data = item.data.map((a) => ({ ...a, x: a.x.slice(0, 4) }));
			});
			chartOptions.value = {
				...chartOptions.value,
				xaxis: {
					...chartOptions.value.xaxis,
					type: "category",
					tickAmount: Math.floor(newDiff / 31536000000),
				},
			};
		} else {
			chartOptions.value = {
				...chartOptions.value,
				xaxis: {
					...chartOptions.value.xaxis,
					type: "datetime",
					labels: { datetimeUTC: false },
				},
			};
		}
	},
	{ deep: true, immediate: true },
);
</script>

<template>
  <div v-if="activeChart === 'TimelineSeparateChart' && localSeries.length > 0">
    <!-- 月份動畫控制列 + KPI -->
    <div
      v-if="showControls"
      class="timechart-controls"
    >
      <!-- KPI：合格 / 不合格 即時數字 -->
      <div class="timechart-kpi">
        <span class="timechart-kpi-month">{{ formatMonthLabel(currentMonth) }}</span>
        <span
          v-if="monthStats"
          class="timechart-kpi-pass"
        >合格 {{ monthStats.pass }}</span>
        <span
          v-if="monthStats"
          class="timechart-kpi-fail"
        >不合格 {{ monthStats.fail }}</span>
      </div>
      <!-- 播放列：播放/暫停 + 手動選月 -->
      <div class="timechart-playbar">
        <button
          class="timechart-playbtn"
          :title="isPlaying ? '暫停' : '播放月份動畫'"
          @click="togglePlay"
        >
          <span class="material-icons">{{ isPlaying ? 'pause' : 'play_arrow' }}</span>
        </button>
        <select
          :value="currentMonth"
          class="timechart-monthselect"
          @change="onMonthSelect($event.target.value)"
        >
          <option
            v-for="m in availableMonths"
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
      :height="showControls ? '210px' : '260px'"
      type="line"
      :options="chartOptions"
      :series="localSeries"
    />
  </div>
</template>

<style scoped>
.timechart-controls {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 8px;
	margin-bottom: 4px;
}

.timechart-kpi {
	display: flex;
	align-items: center;
	gap: 8px;
	flex-wrap: wrap;
}

.timechart-kpi-month {
	font-size: 0.8rem;
	color: var(--color-complement-text);
	font-weight: 600;
	white-space: nowrap;
}

.timechart-kpi-pass {
	font-size: 0.8rem;
	color: #27ae60;
	font-weight: 600;
}

.timechart-kpi-fail {
	font-size: 0.8rem;
	color: #e74c3c;
	font-weight: 600;
}

.timechart-playbar {
	display: flex;
	align-items: center;
	gap: 4px;
	flex-shrink: 0;
}

.timechart-playbtn {
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

.timechart-playbtn:hover {
	background: var(--color-highlight);
}

.timechart-playbtn .material-icons {
	font-size: 18px;
}

.timechart-monthselect {
	background: var(--color-component-background);
	color: var(--color-normal-text);
	border: 1px solid var(--color-border);
	border-radius: 4px;
	padding: 2px 6px;
	font-size: 0.8rem;
	cursor: pointer;
}

.timechart-monthselect:focus {
	outline: none;
	border-color: var(--color-highlight);
}
</style>
