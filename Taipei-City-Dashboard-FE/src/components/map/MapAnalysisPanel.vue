<script setup>
import { computed, ref, watch } from "vue";
import { useMapStore } from "../../store/mapStore";
import http from "../../router/axios";
import { getComponentDataTimeframe } from "../../assets/utilityFunctions/dataTimeframe";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";

const mapStore = useMapStore();

const props = defineProps({
	component: {
		type: Object,
		required: true,
	},
});

const emit = defineEmits(["close"]);
const resolvedComponent = ref(null);
const panelLoading = ref(false);
const panelError = ref("");
const panelTitle = computed(() => resolvedComponent.value?.name || props.component?.name || "未命名組件");

function cloneComponent(component) {
	try {
		return JSON.parse(JSON.stringify(component));
	} catch (error) {
		console.error("Failed to clone analysis component", error);
		return {
			...component,
			chart_data: Array.isArray(component?.chart_data)
				? component.chart_data
				: [],
		};
	}
}

function getChartParams(component) {
	if (!component) return {};
	const fallbackCity = component?.map_config?.[0]?.city || "taipei";
	const params = {
		city: component.city || fallbackCity,
	};

	if (!["static", "current", "demo"].includes(component.time_from)) {
		Object.assign(
			params,
			getComponentDataTimeframe(component.time_from, component.time_to, true),
		);
	}

	return params;
}

async function hydrateAnalysisComponent(component) {
	if (!component) {
		resolvedComponent.value = null;
		return;
	}

	panelLoading.value = true;
	panelError.value = "";
	const nextComponent = cloneComponent(component);

	try {
		const hasChartData = Array.isArray(nextComponent.chart_data);
		if (!hasChartData) {
			let payload = null;
			const params = getChartParams(nextComponent);

			try {
				const response = await http.get(`/component/${nextComponent.id}/chart`, {
					params,
					timeout: 12000,
				});
				payload = response.data;
			} catch (error) {
				console.warn("Primary chart API failed, trying fallback route", error);
			}

			if (!payload || typeof payload !== "object") {
				const query = new URLSearchParams(params).toString();
				const fallbackRoutes = [
					`/api/dev/component/${nextComponent.id}/chart?${query}`,
					`/api/component/${nextComponent.id}/chart?${query}`,
					`/api/v1/component/${nextComponent.id}/chart?${query}`,
				];

				for (const route of fallbackRoutes) {
					try {
						const resp = await fetch(route, {
							method: "GET",
							headers: { Accept: "application/json" },
						});
						if (!resp.ok) continue;
						const json = await resp.json();
						if (json && typeof json === "object") {
							payload = json;
							break;
						}
					} catch (_e) {
						// Try next fallback route
					}
				}
			}

			if (!payload || typeof payload !== "object") {
				nextComponent.chart_data = [];
				panelError.value = "圖表資料格式異常，已以空資料呈現";
			} else {
				nextComponent.chart_data = Array.isArray(payload.data)
					? payload.data
					: [];
				if (payload.categories) {
					nextComponent.chart_config = nextComponent.chart_config || {};
					nextComponent.chart_config.categories = payload.categories;
				}
				if (!Array.isArray(payload.data)) {
					panelError.value = "圖表資料結構不完整，已以空資料呈現";
				}
			}
		}
	} catch (error) {
		console.error("Failed to load chart data for analysis panel", error);
		nextComponent.chart_data = [];
		panelError.value = "圖表資料暫時讀取失敗，請稍後再試";
	} finally {
		resolvedComponent.value = nextComponent;
		panelLoading.value = false;
	}
}

watch(
	() => props.component,
	(component) => {
		hydrateAnalysisComponent(component);
	},
	{ immediate: true },
);

function handleFilterByParam(map_filter, map_config, x, y) {
	mapStore.filterByParam(map_filter, map_config, x, y);
}

function handleFilterByLayer(map_config, x) {
	mapStore.filterByLayer(map_config, x);
}

function handleClearByParamFilter(map_config) {
	mapStore.clearByParamFilter(map_config);
}

function handleClearByLayerFilter(map_config) {
	mapStore.clearByLayerFilter(map_config);
}

function handleFly(location) {
	if (!Array.isArray(location)) return;
	mapStore.flyToLocation(location);
}

function clearFiltersAndClose() {
	if (resolvedComponent.value?.map_config?.length) {
		mapStore.clearByParamFilter(resolvedComponent.value.map_config);
		mapStore.clearByLayerFilter(resolvedComponent.value.map_config);
	}
	emit("close");
}
</script>

<template>
  <section class="map-analysis-panel hide-if-mobile">
		<p class="map-analysis-panel-tag">
			互動分析｜{{ panelTitle }}
		</p>

		<button
			type="button"
			title="關閉分析"
			class="map-analysis-panel-close"
			@click="clearFiltersAndClose"
		>
			<span>close</span>
		</button>

    <DashboardComponent
			v-if="resolvedComponent"
			:config="resolvedComponent"
			:no-outer-container="true"
      mode="map"
      :toggle-on="true"
      :toggle-disable="true"
      :footer="false"
      :fullscreen-btn="false"
      :select-btn="false"
      :info-btn="false"
      :city-tag="[]"
			:active-city="resolvedComponent.city"
      @filter-by-param="handleFilterByParam"
      @filter-by-layer="handleFilterByLayer"
      @clear-by-param-filter="handleClearByParamFilter"
      @clear-by-layer-filter="handleClearByLayerFilter"
      @fly="handleFly"
    />

		<div
			v-if="panelLoading"
			class="map-analysis-panel-loading"
		>
			<div />
			<p>分析資料載入中...</p>
		</div>

		<p
			v-if="panelError"
			class="map-analysis-panel-error"
		>
			{{ panelError }}
		</p>
  </section>
</template>

<style scoped lang="scss">
.map-analysis-panel {
	position: absolute;
	left: 12px;
	bottom: 12px;
	width: min(340px, 30vw);
	height: min(360px, 42vh);
	z-index: 21;
	display: block;

	:deep(.dashboardcomponent) {
		height: 100%;
		max-height: none;
		min-height: 0;
		padding-top: 34px;
		border-radius: 16px;
	}

	:deep(.dashboardcomponent-control-group) {
		transform: none;
	}

	:deep(.dashboardcomponent-header-toggle .toggleswitch) {
		opacity: 0.55;
	}

	:deep(.dashboardcomponent-fullscreen-container) {
		display: contents;
	}

	&-tag {
		position: absolute;
		left: 10px;
		top: 8px;
		z-index: 2;
		margin: 0;
		padding: 3px 8px;
		max-width: calc(100% - 60px);
		font-size: 0.72rem;
		line-height: 1.3;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		color: rgba(248, 250, 252, 0.92);
		background: rgba(2, 6, 23, 0.58);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 999px;
	}

	&-close {
		position: absolute;
		top: 7px;
		right: 8px;
		z-index: 2;
		width: 28px;
		height: 28px;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		border: 1px solid rgba(255, 255, 255, 0.22);
		border-radius: 50%;
		background: rgba(2, 6, 23, 0.62);
		cursor: pointer;

		span {
			font-family: var(--font-icon);
			font-size: 0.95rem;
			color: #e8eaed;
		}

		&:hover {
			background: rgba(15, 23, 42, 0.85);
		}
	}

	&-loading {
		position: absolute;
		inset: 0;
		height: 100%;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 10px;
		border-radius: 16px;
		background: rgba(2, 6, 23, 0.48);

		div {
			width: 24px;
			height: 24px;
			border-radius: 50%;
			border: 3px solid rgba(148, 163, 184, 0.45);
			border-top-color: rgba(255, 255, 255, 0.92);
			animation: spin 0.7s linear infinite;
		}

		p {
			margin: 0;
			font-size: 0.78rem;
			color: rgba(226, 232, 240, 0.88);
		}
	}

	&-error {
		position: absolute;
		left: 8px;
		right: 8px;
		bottom: 10px;
		margin: 0;
		padding: 6px 8px;
		border-radius: 8px;
		font-size: 0.72rem;
		line-height: 1.35;
		color: #fde68a;
		background: rgba(113, 63, 18, 0.52);
		border: 1px solid rgba(217, 119, 6, 0.38);
	}
}

@keyframes spin {
	to {
		transform: rotate(360deg);
	}
}
</style>