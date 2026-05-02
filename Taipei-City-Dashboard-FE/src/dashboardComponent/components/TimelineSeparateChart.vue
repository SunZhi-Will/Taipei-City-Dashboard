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
					` ${props.chart_config.unit ?? ''}` +
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
    <!-- 月份動畫控制列 + KPI (優化版) -->
    <div
      v-if="showControls"
      class="timechart-controls"
    >
      <button
        class="timechart-playbtn"
        :title="isPlaying ? '暫停' : '播放月份動畫'"
        @click="togglePlay"
      >
        <span class="material-icons-round">{{ isPlaying ? 'pause' : 'play_arrow' }}</span>
      </button>
      
      <input
        type="range"
        class="timechart-slider"
        :min="0"
        :max="availableMonths.length - 1"
        :value="availableMonths.indexOf(currentMonth)"
        @input="onMonthSelect(availableMonths[$event.target.value])"
      >

      <div class="timechart-info">
        <span class="timechart-info-month">{{ formatMonthLabel(currentMonth) }}</span>
        <div class="timechart-kpi" v-if="monthStats">
          <span class="timechart-kpi-pass">合 {{ monthStats.pass }}</span>
          <span class="timechart-kpi-fail">不合 {{ monthStats.fail }}</span>
        </div>
      </div>
    </div>

    <VueApexCharts
      width="100%"
      :height="showControls ? '260px' : '310px'"
      type="line"
      :options="chartOptions"
      :series="localSeries"
    />
  </div>
</template>

<style scoped lang="scss">
.timechart-controls {
	display: flex;
	flex-direction: row;
	align-items: center;
	gap: 12px;
	padding: 4px 0;
	margin-bottom: 6px;
	border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.timechart-info {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  min-width: 80px;
  flex-shrink: 0;

  &-month {
    font-size: 0.75rem;
    color: var(--color-highlight);
    font-weight: 700;
    white-space: nowrap;
  }
}

.timechart-kpi {
	display: flex;
	align-items: center;
	gap: 6px;
}

.timechart-kpi-pass {
	font-size: 0.7rem;
	color: #2ecc71;
	font-weight: 600;
}

.timechart-kpi-fail {
	font-size: 0.7rem;
	color: #e74c3c;
	font-weight: 600;
}


.timechart-playbtn {
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
		font-family: var(--font-icon);
		font-size: 18px;
		line-height: 1;
	}
}

.timechart-slider {
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
