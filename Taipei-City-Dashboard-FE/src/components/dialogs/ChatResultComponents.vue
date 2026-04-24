<script setup>
import { computed } from "vue";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";
import { useContentStore } from "../../store/contentStore";

const props = defineProps({
	components: {
		type: Array,
		default: () => [],
	},
	selectionReason: {
		type: String,
		default: '',
	},
});
const emit = defineEmits(["copy", "explore", "open-map"]);
const contentStore = useContentStore();

const normalizedComponents = computed(() =>
	Array.isArray(props.components) ? props.components : [],
);

const primaryComponent = computed(() =>
	normalizedComponents.value.find((item) => item?.isPrimary) || normalizedComponents.value[0] || null,
);

const secondaryComponents = computed(() =>
	normalizedComponents.value.filter((item) => item && item !== primaryComponent.value),
);

const hasMapConfig = (config) =>
	Array.isArray(config?.map_config) && config.map_config.length > 0 && Boolean(config.map_config[0]);

const isDashboardPreview = (comp) =>
	comp?.category === "dashboard_component" && comp?.dashboardConfig && !hasMapConfig(comp.dashboardConfig);

const isMapComponent = (comp) =>
	comp?.category === "dashboard_component" && comp?.dashboardConfig && hasMapConfig(comp.dashboardConfig);

const cityTags = (config) => {
	if (!config?.city) return [];
	return contentStore.cityManager.getTagList(config.city);
};

const onExplore = (comp) => {
	if (!comp?.name) return;
	emit("explore", comp.name);
};

const onOpenMap = (comp) => {
	if (!isMapComponent(comp)) return;
	emit("open-map", comp);
};
</script>

<template>
  <div class="component-cards-area">
    <div
      v-if="primaryComponent"
      :key="`${primaryComponent.id}-${primaryComponent.index || primaryComponent.name}`"
      class="component-card"
    >
      <div
        v-if="isMapComponent(primaryComponent)"
        class="map-focus-card"
      >
        <div class="map-focus-head">
          <h4 class="component-name">
            {{ primaryComponent.name }}
          </h4>
          <p class="map-focus-text">
            此組件為地圖圖資，請使用地圖檢視查看完整圖層內容。
          </p>
        </div>
        <button
          type="button"
          class="map-open-btn"
          @click="onOpenMap(primaryComponent)"
        >
          開啟地圖
        </button>
      </div>

      <DashboardComponent
        v-else-if="isDashboardPreview(primaryComponent)"
        :config="primaryComponent.dashboardConfig"
        mode="default"
        :show-index="false"
        :city-tag="cityTags(primaryComponent.dashboardConfig)"
        :info-btn="false"
        :add-btn="false"
        :favorite-btn="false"
        :footer="false"
        :fullscreen-btn="false"
      />

      <div
        v-else
        class="generic-card generic-card-primary"
      >
        <div class="component-header">
          <h4 class="component-name">
            {{ primaryComponent.name }}
          </h4>
        </div>
        <div class="component-body">
          <p class="component-description">
            {{ primaryComponent.description }}
          </p>
        </div>
      </div>
    </div>

    <div
      v-if="secondaryComponents.length > 0"
      class="secondary-section"
    >
      <p class="secondary-title">
        也可以延伸查看這些相關指標：
      </p>
      <div class="secondary-links">
        <button
          v-for="comp in secondaryComponents"
          :key="`${comp.id}-${comp.index || comp.name}`"
          type="button"
          class="secondary-link"
          :title="`查看 ${comp.name}`"
          @click="onExplore(comp)"
        >
          <span class="secondary-link-name">{{ comp.name }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.component-cards-area {
	margin: 12px 0;
	display: flex;
	flex-direction: column;
	gap: 14px;
}

.component-card {
	border-radius: 10px;
	overflow: hidden;
}

/* Chat-only override: allow embedded DashboardComponent charts to grow naturally. */
.component-card :deep(.dashboardcomponent) {
	height: auto !important;
	max-height: none !important;
	min-height: 0;
}

.component-card :deep(.dashboardcomponent-chart),
.component-card :deep(.dashboardcomponent-loading),
.component-card :deep(.dashboardcomponent-error) {
	height: auto !important;
	max-height: none !important;
	overflow-y: hidden !important;
	overflow-x: auto !important;
}

.component-card :deep(.vue-apexcharts) {
	width: 100% !important;
	min-height: 0 !important;
	overflow: visible !important;
}

.component-card :deep(.apexcharts-canvas),
.component-card :deep(.apexcharts-svg) {
	max-width: 100% !important;
}

.component-card :deep(.apexcharts-legend) {
	overflow: visible !important;
	max-height: none !important;
}


.map-focus-card {
	background: rgba(16, 185, 129, 0.08);
	border: 1px solid rgba(52, 211, 153, 0.35);
	border-radius: 10px;
	padding: 14px;
	display: flex;
	flex-direction: column;
	gap: 10px;
}

.map-focus-head {
	display: flex;
	flex-direction: column;
	gap: 6px;
}

.map-focus-text {
	margin: 0;
	font-size: 13px;
	line-height: 1.5;
	color: #bfe7d5;
}

.map-open-btn {
	align-self: flex-start;
	padding: 6px 12px;
	border: 1px solid rgba(74, 222, 128, 0.5);
	border-radius: 8px;
	background: rgba(22, 163, 74, 0.25);
	color: #e7ffe9;
	font-size: 13px;
	font-weight: 600;
	cursor: pointer;
}

.map-open-btn:hover {
	background: rgba(22, 163, 74, 0.35);
}

.generic-card {
	border: 1px solid rgba(255, 255, 255, 0.14);
	border-radius: 10px;
	padding: 14px;
	background: rgba(255, 255, 255, 0.04);
}

.generic-card-primary {
	background: rgba(255, 255, 255, 0.06);
	border-color: rgba(255, 255, 255, 0.18);
}

.component-header {
	display: flex;
	align-items: center;
	margin-bottom: 8px;
	padding-bottom: 6px;
}

.component-name {
	font-size: 16px;
	font-weight: 600;
	color: #f0f3f8;
	margin: 0;
}

.component-body {
	display: flex;
	flex-direction: column;
	gap: 8px;
}

.component-description {
	font-size: 14px;
	color: #c8d0db;
	line-height: 1.5;
	margin: 0;
}

.secondary-section {
	display: flex;
	flex-direction: column;
	gap: 10px;
}

.secondary-title {
	margin: 0;
	font-size: 13px;
	line-height: 1.5;
	color: #d7dde6;
}

.secondary-links {
	display: flex;
	flex-direction: column;
	gap: 10px;
	align-items: flex-start;
}

.secondary-link {
	padding: 0;
	border: none;
	background: transparent;
	display: inline-flex;
	flex-direction: column;
	align-items: flex-start;
	gap: 4px;
	cursor: pointer;
	text-align: left;
	width: fit-content;
}


.secondary-link-name {
	margin: 0;
	font-size: 14px;
	line-height: 1.4;
	font-weight: 600;
	color: #cfe4ff;
	text-decoration: underline;
	text-underline-offset: 3px;
	text-decoration-thickness: 1px;
	transition: color 0.2s ease;
}

.secondary-link:hover .secondary-link-name {
	color: #ffffff;
}
</style>
