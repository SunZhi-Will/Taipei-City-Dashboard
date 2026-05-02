<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { computed, ref } from "vue";
import VueApexCharts from "vue3-apexcharts";

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

// How many data points to show before summing all remaining points into "other"
const steps = ref(100);

// Donut charts in apexcharts uses a slightly different data format from other chart types
// As such, the following parsing functions are required
const parsedSeries = computed(() => {
	const toParse = [...props.series[0].data];
	if (toParse.length <= steps.value) {
		return toParse.map((item) => toFiniteNumber(item.y));
	}
	let output = [];
	for (let i = 0; i < steps.value; i++) {
		output.push(toFiniteNumber(toParse[i].y));
	}
	const toSum = toParse.splice(steps.value, toParse.length - steps.value);
	let sum = 0;
	toSum.forEach((element) => (sum += toFiniteNumber(element.y)));
	output.push(sum);
	return output;
});
const parsedLabels = computed(() => {
	const toParse = [...props.series[0].data];
	if (toParse.length <= steps.value) {
		return toParse.map((item) => item.x);
	}
	let output = [];
	for (let i = 0; i < steps.value; i++) {
		output.push(toParse[i].x);
	}
	output.push("其他");
	return output;
});
const sum = computed(() => {
	return (
		Math.round(
			parsedSeries.value.reduce((a, b) => toFiniteNumber(a) + toFiniteNumber(b), 0) *
				100
		) / 100
	);
});

const legendColors = computed(() => {
	const baseColors = Array.isArray(props.chart_config?.color)
		? props.chart_config.color
		: [];
	if (parsedLabels.value.length <= baseColors.length) {
		return baseColors.slice(0, parsedLabels.value.length);
	}
	return [...baseColors, "#848c94"];
});

const donutLegendItems = computed(() =>
	parsedLabels.value.map((label, index) => ({
		label,
		value: parsedSeries.value[index],
		color: legendColors.value[index] || "#9ca3af",
	})),
);

// chartOptions needs to be in the bottom since it uses computed data
const chartOptions = ref({
	chart: {
		offsetY: 0,
		width: "100%",
		height: "100%",
		redrawOnParentResize: true,
		redrawOnWindowResize: true,
	},
	colors:
		props.series.length >= steps.value
			? [...props.chart_config.color, "#848c94"]
			: props.chart_config.color,
	dataLabels: {
		formatter: function (
			_val,
			{ seriesIndex, w }
		) {
			let value = w.globals.labels[seriesIndex];
			return value.length > 7 ? value.slice(0, 6) + "..." : value;
		},
	},
	labels: parsedLabels,
	legend: {
		show: false,
	},
	plotOptions: {
		pie: {
			dataLabels: {
				offset: 15,
			},
			donut: {
				size: "77.5%",
			},
		},
	},
	stroke: {
		colors: ["#282a2c"],
		show: true,
		width: 3,
	},
	tooltip: {
		followCursor: false,
		custom: function ({
			series,
			seriesIndex,
			w,
		}) {
			// The class "chart-tooltip" could be edited in /assets/styles/chartStyles.css
			return (
				'<div class="chart-tooltip">' +
				"<h6>" +
				w.globals.labels[seriesIndex] +
				"</h6>" +
				"<span>" +
				series[seriesIndex] +
				` ${props.chart_config.unit}` +
				"</span>" +
				"</div>"
			);
		},
	},
});

const selectedIndex = ref(null);

function handleDataSelection(_e, _chartContext, config) {
	if (!props.map_filter || !props.map_filter_on) {
		return;
	}
	if (
		`${config.dataPointIndex}-${config.seriesIndex}` !== selectedIndex.value
	) {
		// Supports filtering by xAxis
		if (props.map_filter.mode === "byParam") {
			emits(
				"filterByParam",
				props.map_filter,
				props.map_config,
				config.w.globals.labels[config.dataPointIndex],
				null
			);
		}
		// Supports filtering by xAxis
		else if (props.map_filter.mode === "byLayer") {
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
    v-if="activeChart === 'DonutChart'"
    class="donutchart"
  >
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
.donutchart {
	height: 100%;
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
