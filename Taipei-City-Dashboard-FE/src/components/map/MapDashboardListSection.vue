<script setup>
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";
import { useContentStore } from "../../store/contentStore";

const contentStore = useContentStore();

const props = defineProps({
	dashboards: {
		type: Array,
		default: () => [],
	},
	scope: {
		type: String,
		required: true,
	},
	city: {
		type: String,
		default: undefined,
	},
	expandedDashboardMap: {
		type: Object,
		required: true,
	},
	loadingDashboardKey: {
		type: String,
		default: "",
	},
	componentToggles: {
		type: Object,
		required: true,
	},
	getDashboardKey: {
		type: Function,
		required: true,
	},
	getDashboardComponents: {
		type: Function,
		required: true,
	},
	getComponentKey: {
		type: Function,
		required: true,
	},
	hasMapConfig: {
		type: Function,
		required: true,
	},
});

const emit = defineEmits([
	"dashboard-click",
	"component-toggle",
	"component-analyze",
	"component-city-change",
]);

const handleDashboardClick = (dashboard) => {
	emit("dashboard-click", { scope: props.scope, dashboard, city: props.city });
};

const handleToggle = ({ checked, dashboard, city, component }) => {
	emit("component-toggle", {
		checked,
		dashboard,
		city,
		component,
	});
};

const handleComponentCityChange = ({ dashboard, city, component, nextCity }) => {
	emit("component-city-change", {
		dashboard,
		city,
		component,
		nextCity,
	});
};

const handleAnalyzeClick = (dashboard, component) => {
	emit("component-analyze", {
		dashboard,
		city: props.city,
		component,
	});
};
</script>

<template>
  <div class="map-dashboard-list">
    <div
      v-for="dashboard in dashboards"
      :key="dashboard.index"
      class="map-dashboard-item"
    >
      <button
        class="map-dashboard-row"
        @click="handleDashboardClick(dashboard)"
      >
        <span class="map-dashboard-name">{{ dashboard.name }}</span>
        <span class="map-dashboard-arrow">{{ expandedDashboardMap[getDashboardKey(scope, dashboard.index, city)] ? 'expand_less' : 'expand_more' }}</span>
      </button>
      <div
        v-if="expandedDashboardMap[getDashboardKey(scope, dashboard.index, city)]"
        class="map-component-list"
      >
        <p v-if="loadingDashboardKey === dashboard.index">
          載入組件中...
        </p>
        <div
          v-for="component in getDashboardComponents(dashboard, city)"
          :key="component.id"
          class="map-component-item"
        >
					<DashboardComponent
						:config="component"
						mode="map"
						:show-index="false"
						:select-btn="true"
						:select-btn-disabled="contentStore.cityManager.getSelectList(component.city).length === 1"
						:select-btn-list="contentStore.cityManager.getSelectList(component.city)"
						:city-tag="contentStore.cityManager.getTagList(component.city)"
						:active-city="component.city"
						:toggle-on="componentToggles[getComponentKey(dashboard, city, component)] || false"
						:favorite-btn="false"
						:delete-btn="false"
						:fullscreen-btn="false"
						@toggle="(checked) => handleToggle({ checked, dashboard, city, component })"
						@change-city="(nextCity) => handleComponentCityChange({ dashboard, city, component, nextCity })"
					/>
					<div class="map-component-item-actions">
						<small v-if="!hasMapConfig(component)">無地圖</small>
						<button
							class="map-component-analyze"
							type="button"
							:disabled="!hasMapConfig(component)"
							@click="handleAnalyzeClick(dashboard, component)"
						>
							分析
						</button>
					</div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.map-component-item {
	display: flex;
	flex-direction: column;
	align-items: stretch;
	gap: 6px;
	padding: 4px;
	margin-bottom: 4px;
	border-radius: 4px;

	&:hover {
		background: rgba(255, 255, 255, 0.06);
	}
}

.map-component-list :deep(.dashboardcomponent.mapclosed),
.map-component-list :deep(.dashboardcomponent.mapopen) {
	width: 100%;
	margin: 4px 0;
	box-sizing: border-box;
}

.map-component-list :deep(.dashboardcomponent-header) {
	gap: 8px;
}

.map-component-item-actions {
	display: flex;
	align-items: center;
	justify-content: space-between;
	min-height: 22px;

	small {
		font-size: 0.7rem;
		color: #8b92a8;
		flex-shrink: 0;
	}
}

.map-component-analyze {
	height: 22px;
	padding: 0 8px;
	border: 1px solid rgba(255, 255, 255, 0.2);
	border-radius: 999px;
	background: rgba(255, 255, 255, 0.08);
	color: #e8eaed;
	font-size: 0.7rem;
	line-height: 1;
	cursor: pointer;
	white-space: nowrap;

	&:hover:not(:disabled) {
		background: rgba(255, 255, 255, 0.16);
	}

	&:disabled {
		opacity: 0.45;
		cursor: not-allowed;
	}
}
</style>