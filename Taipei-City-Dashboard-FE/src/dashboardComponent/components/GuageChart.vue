<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { ref, computed } from "vue";
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

// Guage charts in apexcharts uses a slightly different data format from other chart types
// As such, the following parsing function are required
const parseSeries = computed(() => {
	let output = {
		series: [],
		tooltipText: [],
	};
	let parsedSeries = [];
	let parsedTooltip = [];
	for (let i = 0; i < props.series[0].data.length; i++) {
		let total = props.series[0].data[i] + props.series[1].data[i];
		parsedSeries.push(Math.round((props.series[0].data[i] / total) * 100));
		parsedTooltip.push(`${props.series[0].data[i]} / ${total}`);
	}
	output.series = parsedSeries;
	output.tooltipText = parsedTooltip;
	return output;
});

const guageLegendItems = computed(() => {
	const colors = Array.isArray(props.chart_config?.color) ? props.chart_config.color : [];
	const labels = Array.isArray(props.chart_config?.categories) ? props.chart_config.categories : [];

	if (labels.length > 1) {
		return labels.map((label, index) => ({
			label,
			color: colors[index] || "#9ca3af",
		}));
	}

	const primaryLabel = props.series?.[0]?.name || "主要指標";
	return [
		{ label: primaryLabel, color: colors[0] || "#9dc56e" },
		{ label: "其餘", color: "#777777" },
	];
});

// chartOptions needs to be in the bottom since it uses computed data
const chartOptions = ref({
	chart: {
		toolbar: {
			show: false,
		},
		width: "100%",
		height: "100%",
		redrawOnParentResize: true,
		redrawOnWindowResize: true,
	},
	colors: [...props.chart_config.color],
	labels: props.chart_config.categories ? props.chart_config.categories : [],
	legend: {
		offsetY: -10,
		onItemClick: {
			toggleDataSeries: false,
		},
		position: "bottom",
		show: parseSeries.value.series.length > 1 ? true : false,
	},
	plotOptions: {
		radialBar: {
			dataLabels: {
				name: {
					color: "#888787",
					fontSize: "0.8rem",
				},
				// total: {
				// 	color: "#888787",
				// 	fontSize: "0.8rem",
				// 	label: "平均",
				// 	show: true,
				// },
				value: {
					color: "#888787",
					fontSize: "16px",
					offsetY: 5,
				},
			},
			track: {
				background: "#777",
			},
		},
	},
	tooltip: {
		custom: function ({ seriesIndex, w }) {
			// The class "chart-tooltip" could be edited in /assets/styles/chartStyles.css
			return (
				'<div class="chart-tooltip">' +
				"<h6>" +
				w.globals.seriesNames[seriesIndex] +
				"</h6>" +
				"<span>" +
				`${parseSeries.value.tooltipText[seriesIndex]}` +
				"</span>" +
				"</div>"
			);
		},
		enabled: true,
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
		// Supports filtering by xAxis and yAxis
		if (props.map_filter.mode === "byParam") {
			emits(
				"filterByParam",
				props.map_filter,
				props.map_config,
				config.w.globals.labels[config.dataPointIndex],
				props.series[0].name // You can only click on the first series in ApexCharts
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
    v-if="activeChart === 'GuageChart'"
    class="guagechart"
    :class="{ 'guagechart--with-custom-legend': showColorLegend }"
  >
    <VueApexCharts
      width="100%"
      height="100%"
      type="radialBar"
      :options="chartOptions"
      :series="parseSeries.series"
      @data-point-selection="handleDataSelection"
    />

    <div
      v-if="showColorLegend"
      class="guagechart-legend"
    >
      <div
        v-for="item in guageLegendItems"
        :key="`guage-legend-${item.label}`"
        class="guagechart-legend-item"
      >
        <span
          class="guagechart-legend-swatch"
          :style="{ backgroundColor: item.color }"
        />
        <span class="guagechart-legend-label">{{ item.label }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.guagechart {
	position: relative;
	width: 100%;
	height: 100%;
	min-height: 0;
	overflow: hidden;

	:deep(.vue-apexcharts),
	:deep(.apexcharts-canvas),
	:deep(.apexcharts-svg) {
		width: 100% !important;
		height: 100% !important;
	}

	&--with-custom-legend {
		:deep(.apexcharts-legend) {
			display: none !important;
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
