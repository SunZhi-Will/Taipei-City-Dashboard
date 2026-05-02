<!-- Developed By Taipei Urban Intelligence Center 2023-2024 -->
<!-- 
Lead Developer:  Igor Ho (Full Stack Engineer)
Data Pipelines:  Iima Yu (Data Scientist)
Design and UX: Roy Lin (Fmr. Consultant), Chu Chen (Researcher)
Systems: Ann Shih (Systems Engineer)
Testing: Jack Huang (Data Scientist), Ian Huang (Data Analysis Intern) 
-->
<!-- Department of Information Technology, Taipei City Government -->

<script setup>
/* global gtag */
import { computed, ref, watch } from "vue";
import DashboardComponent from "../dashboardComponent/DashboardComponent.vue";
import router from "../router";
import { useContentStore } from "../store/contentStore";
import { useDialogStore } from "../store/dialogStore";
import { useAuthStore } from "../store/authStore";

import MoreInfo from "../components/dialogs/MoreInfo.vue";
import ReportIssue from "../components/dialogs/ReportIssue.vue";

const contentStore = useContentStore();
const dialogStore = useDialogStore();
const authStore = useAuthStore();
const expandedComponentId = ref(null);
const componentActiveCharts = ref({});

const expandedComponent = computed(() => {
	return (
		contentStore.currentDashboard.components?.find(
			(item) => item.id === expandedComponentId.value
		) || null
	);
});

function toggleContentFocus(id) {
	expandedComponentId.value = expandedComponentId.value === id ? null : id;
}

function handleDeleteExpanded(id) {
	contentStore.deleteComponent(id);
	expandedComponentId.value = null;
}

function handleChangeCityExpanded(city) {
	if (!expandedComponent.value) {
		return;
	}

	const selectedData = contentStore.cityDashboard.components.find((data) => {
		return (
			data.index === expandedComponent.value.index &&
      data.city === city
		);
	});

	if (!selectedData) {
		return;
	}

	const componentIndex = contentStore.currentDashboard.components.findIndex(
		(item) => item.id === selectedData.id
	);

	if (componentIndex >= 0) {
		contentStore.setComponentData(componentIndex, selectedData);
		expandedComponentId.value = selectedData.id;
	}
}

watch(
	() => contentStore.currentDashboard.index,
	() => {
		expandedComponentId.value = null;
    componentActiveCharts.value = {};
	}
);

const WIDE_CHART_TYPES = new Set([
  "TimelineStackedChart",
  "TimelineSeparateChart",
  "HeatmapChart",
  "MetroChart",
  "TreemapChart",
]);

const TALL_CHART_TYPES = new Set([
  "BarChart",
  "BarPercentChart",
  "BarChartWithGoal",
  "ColumnChart",
  "ColumnLineChart",
  "AnimatedColumnChart",
]);

const DASHBOARD_LAYOUT_PROFILES = {
  food_safety_tpe: {
    taipei_imap_food: "",
    food_poisoning_food: (activeChart) =>
      activeChart === "BarChart" ? "dashboard-tile--x-tall" : "",
    food_poisoning_cause: (activeChart) =>
      activeChart === "BarChart" ? "dashboard-tile--x-tall" : "",
    ntpc_food_factory: "",
    food_poisoning_trend: "dashboard-tile--wide",
    food_poisoning_place: "dashboard-tile--tall",
    wholesale_pesticide_inspection: "",
    school_kitchen_imap: "",
  },
  food_safety_taipei: {
    taipei_imap_food: "",
    food_poisoning_food: (activeChart) =>
      activeChart === "BarChart" ? "dashboard-tile--x-tall" : "",
    food_poisoning_cause: (activeChart) =>
      activeChart === "BarChart" ? "dashboard-tile--x-tall" : "",
    food_poisoning_trend: "dashboard-tile--wide",
    food_poisoning_place: "dashboard-tile--tall",
    wholesale_pesticide_inspection_taipei: "",
    school_kitchen_imap: "",
  },
};

function getTileClass(item, index) {
  const dashboardIndex = contentStore.currentDashboard?.index;
  const activeChart = componentActiveCharts.value[item?.id] || item?.chart_config?.types?.[0] || "";
  const profileClass = DASHBOARD_LAYOUT_PROFILES[dashboardIndex]?.[item?.index];

  if (profileClass !== undefined) {
	return typeof profileClass === "function"
	  ? profileClass(activeChart, item)
	  : profileClass;
  }

  const chartTypes = item?.chart_config?.types || [];
  const hasDenseSeries = Array.isArray(item?.chart_data) && item.chart_data.length >= 12;
  const hasMultiChartTypes = chartTypes.length > 1;
  const hasWideChartType = WIDE_CHART_TYPES.has(activeChart);
	const hasTallActiveChart = TALL_CHART_TYPES.has(activeChart);

  if (hasMultiChartTypes && hasWideChartType) {
    return "dashboard-tile--wide-tall";
  }

  if (hasMultiChartTypes && hasTallActiveChart) {
    return "dashboard-tile--x-tall";
  }

  if (hasWideChartType) {
    return "dashboard-tile--wide";
  }

  if (
    hasDenseSeries ||
    hasTallActiveChart ||
    (index + 1) % 6 === 0
  ) {
    return "dashboard-tile--tall";
  }

  return "";
}

function getTileComponentStyle() {
  return {
    height: "100%",
    maxHeight: "none",
    minHeight: "0",
  };
}

function handleChartTypeChange(componentId, chartType) {
	componentActiveCharts.value = {
		...componentActiveCharts.value,
		[componentId]: chartType,
	};
}

function handleOpenSettings() {
	contentStore.editDashboard = JSON.parse(
		JSON.stringify(contentStore.currentDashboard)
	);
	dialogStore.addEdit = "edit";
	dialogStore.showDialog("addEditDashboards");
}

function toggleFavorite(id,name,city) {
	if (contentStore.favorites.components.includes(id)) {
		contentStore.unfavoriteComponent(id);
	} else {
		contentStore.favoriteComponent(id);
		// 成功收藏組件時觸發GA自訂事件
		if (city && name) {
			gtag('event','popular_component', {
				dashboard_city:city,
				component_name:name,
				city_component:`${city}-${name}`,
				time: Date.now(),
  			})
		}
	}
}
function handleMoreInfo(item) {
	// 檢視更多資訊時觸發GA自訂事件
	if (item.city && item.name){
		gtag('event','popular_component', {
			dashboard_city:item.city,
			component_name:item.name,
			city_component:`${item.city}-${item.name}`,
			time: Date.now(),
  		})
	}

	if (authStore.isMobileDevice && authStore.isNarrowDevice) {
		router.push({
			name: "component-info",
			params: { index: item.index },
		});
	} else {
		dialogStore.showMoreInfo(item);
	}
}
</script>

<template>
  <div
    v-if="expandedComponent"
    class="dashboard dashboard-focus"
  >
    <DashboardComponent
      :config="expandedComponent"
      mode="focus"
      :info-btn="true"
      :expanded-in-content="true"
      :active-city="expandedComponent.city"
      :select-btn="true"
      :select-btn-disabled="contentStore.cityManager.getSelectList(contentStore.currentDashboard?.city).length === 1 || contentStore.currentDashboardExcluded.components.filter((data) => data.index === expandedComponent.index).length === 0"
      :select-btn-list="contentStore.currentDashboard?.city
        ? contentStore.cityManager.getSelectList(contentStore.currentDashboard?.city)
        : contentStore.cityManager.getCities(contentStore.cityManager.activeCities)
      "
      :city-tag="contentStore.currentDashboard?.city
        ? contentStore.cityManager.getTagList(contentStore.currentDashboard?.city)
        : contentStore.cityManager.getTagList(expandedComponent.city)
      "
      :delete-btn="contentStore.personalDashboards.map((item) => item.index).includes(contentStore.currentDashboard.index)"
      :favorite-btn="authStore.token && contentStore.currentDashboard.icon !== 'favorite'"
      :is-favorite="contentStore.favorites?.components.includes(expandedComponent.id)"
      @expand-layout="toggleContentFocus"
      @favorite="(id) => { toggleFavorite(id, expandedComponent.name, expandedComponent.city); }"
      @info="(item) => { handleMoreInfo(item); }"
      @delete="handleDeleteExpanded"
      @change-city="handleChangeCityExpanded"
      @chart-type-change="(id, chartType) => { handleChartTypeChange(id, chartType); }"
    />
    <MoreInfo />
    <ReportIssue />
  </div>
  <!-- 1. If the dashboard is map-layers -->
  <div
    v-else-if="contentStore.currentDashboard.index?.includes('map-layers')"
    class="dashboard"
  >
    <div
      v-for="(item, index) in contentStore.currentDashboard.components"
      :key="`${item.index}-${item.city}`"
      :class="['dashboard-tile', getTileClass(item, index)]"
    >
      <DashboardComponent
        :config="item"
        mode="half"
        :style="getTileComponentStyle()"
        :info-btn="true"
        :active-city="item.city"
        :select-btn="true"
        :select-btn-disabled="contentStore.cityManager.getSelectList(contentStore.currentDashboard?.city).length === 1"
        :select-btn-list="contentStore.cityManager.getSelectList(contentStore.currentDashboard?.city)"
        :city-tag="contentStore.cityManager.getTagList(contentStore.currentDashboard?.city)"
        :favorite-btn="authStore.token ? true : false"
        :is-favorite="contentStore.favorites?.components.includes(item.id)"
        :expanded-in-content="false"
        @expand-layout="toggleContentFocus"
        @favorite="
          (id) => {
            toggleFavorite(id,item.name,item.city);
          }
        "
        @info="
          (item) => {
            handleMoreInfo(item);
          }
        "
        @chart-type-change="(id, chartType) => { handleChartTypeChange(id, chartType); }"
        @change-city="(city)=> {
          const selectedData = contentStore.cityDashboard.components.find((data) => {
            if (data.index === item.index && data.city === city) {
              return data
            }
          });

          const componentIndex = contentStore.currentDashboard.components.findIndex(
            (item) => item.id === selectedData.id
          );

          if (selectedData) {
            contentStore.setComponentData(componentIndex, selectedData);
          }
        }"
      />
    </div>
    <MoreInfo />
    <ReportIssue />
  </div>
  <!-- 2. Dashboards that have components -->
  <div
    v-else-if="contentStore.currentDashboard.components?.length !== 0 || contentStore.cityDashboard.components?.length !== 0"
    class="dashboard"
  >
    <div
      v-for="(item, index) in contentStore.currentDashboard.components"
      :key="`${item.index}-${item.city}`"
      :class="['dashboard-tile', getTileClass(item, index)]"
    >
      <DashboardComponent
        :config="item"
        :style="getTileComponentStyle()"
        :info-btn="true"
        :active-city="item.city"
        :select-btn="true"
        :select-btn-disabled="contentStore.cityManager.getSelectList(contentStore.currentDashboard?.city).length === 1 || contentStore.currentDashboardExcluded.components.filter((data) => data.index === item.index).length === 0"
        :select-btn-list="contentStore.currentDashboard?.city
          ? contentStore.cityManager.getSelectList(contentStore.currentDashboard?.city)
          : contentStore.cityManager.getCities(contentStore.cityManager.activeCities)
        "
        :city-tag="contentStore.currentDashboard?.city
          ? contentStore.cityManager.getTagList(contentStore.currentDashboard?.city)
          : contentStore.cityManager.getTagList(item.city)
        "
        :delete-btn="
          contentStore.personalDashboards
            .map((item) => item.index)
            .includes(contentStore.currentDashboard.index)
        "
        :favorite-btn="
          authStore.token &&
            contentStore.currentDashboard.icon !== 'favorite'
        "
        :is-favorite="contentStore.favorites?.components.includes(item.id)"
        :expanded-in-content="false"
        @expand-layout="toggleContentFocus"
        @favorite="
          (id) => {
            toggleFavorite(id,item.name,item.city);
          }
        "
        @info="
          (item) => {
            handleMoreInfo(item);
          }
        "
        @delete="
          (id) => {
            contentStore.deleteComponent(id);
          }
        "
        @chart-type-change="(id, chartType) => { handleChartTypeChange(id, chartType); }"
        @change-city="(city)=> {
          const selectedData = contentStore.cityDashboard.components.find((data) => {
            if (data.index === item.index && data.city === city) {
              return data
            }
          });

          const componentIndex = contentStore.currentDashboard.components.findIndex(
            (item) => item.id === selectedData.id
          );

          if (selectedData) {
            contentStore.setComponentData(componentIndex, selectedData);
          }
        }
        "
      />
    </div>
    <MoreInfo />
    <ReportIssue />
  </div>
  <!-- 3. If dashboard is still loading -->
  <div
    v-else-if="contentStore.loading"
    class="dashboard dashboard-nodashboard"
  >
    <div class="dashboard-nodashboard-content">
      <div />
    </div>
  </div>
  <!-- 4. If dashboard failed to load -->
  <div
    v-else-if="contentStore.error"
    class="dashboard dashboard-nodashboard"
  >
    <div class="dashboard-nodashboard-content">
      <span>sentiment_very_dissatisfied</span>
      <h2>發生錯誤，無法載入儀表板</h2>
    </div>
  </div>
  <!-- 5. Dashboards that don't have components -->
  <div
    v-else
    class="dashboard dashboard-nodashboard"
  >
    <div class="dashboard-nodashboard-content">
      <span>addchart</span>
      <h2>尚未加入組件</h2>
      <button
        v-if="contentStore.currentDashboard.icon !== 'favorite'"
        class="hide-if-mobile"
        @click="handleOpenSettings"
      >
        加入您的第一個組件
      </button>
      <p v-else>
        點擊其他儀表板組件之愛心以新增至收藏組件
      </p>
    </div>
  </div>
</template>

<style scoped lang="scss">
.dashboard {
	display: grid;
	row-gap: 12px;
	column-gap: 12px;
  grid-auto-flow: dense;
  grid-auto-rows: 180px;
  margin: var(--font-m);

  &-tile {
    min-width: 0;
    grid-column: span 1;
    grid-row: span 2;

    :deep(.dashboardcomponent-fullscreen-container) {
      height: 100%;
    }

    :deep(.dashboardcomponent) {
      height: 100% !important;
      max-height: none !important;
      min-height: 0 !important;
    }

    :deep(.dashboardcomponent-chart),
    :deep(.dashboardcomponent-loading),
    :deep(.dashboardcomponent-error) {
      height: calc(100% - 88px);
        overflow-y: auto;
        overflow-x: hidden;
    }
  }

  &-tile--wide {
    grid-column: span 2;
    grid-row: span 2;
  }

  &-tile--tall {
    grid-column: span 1;
    grid-row: span 3;
  }

  &-tile--x-tall {
    grid-column: span 1;
    grid-row: span 4;
  }

  &-tile--wide-tall {
    grid-column: span 2;
    grid-row: span 3;
  }

	@media (max-width: 768px) {
		margin: 12px;
		row-gap: 16px;
    grid-auto-rows: auto;

    &-tile,
    &-tile--wide,
    &-tile--tall,
    &-tile--x-tall,
    &-tile--wide-tall {
      grid-column: span 1;
      grid-row: span 1;
    }

    &-tile :deep(.dashboardcomponent-chart),
    &-tile :deep(.dashboardcomponent-loading),
    &-tile :deep(.dashboardcomponent-error) {
      height: 75%;
    }
	}

	@media (min-width: 720px) {
		grid-template-columns: 1fr 1fr;
	}

	@media (min-width: 1296px) {
		grid-template-columns: 1fr 1fr 1fr;
	}

	@media (min-width: 1800px) {
		grid-template-columns: 1fr 1fr 1fr 1fr;
	}

	@media (min-width: 2200px) {
		grid-template-columns: 1fr 1fr 1fr 1fr 1fr;
	}

	&-nodashboard {
		grid-template-columns: 1fr;

		&-content {
			width: 100%;
			height: calc(100vh - 127px);
			height: calc(var(--vh) * 100 - 127px);
			display: flex;
			flex-direction: column;
			align-items: center;
			justify-content: center;

			span {
				margin-bottom: var(--font-ms);
				font-family: var(--font-icon);
				font-size: 2rem;
			}

			button {
				color: var(--color-highlight);
			}

			div {
				width: 2rem;
				height: 2rem;
				border-radius: 50%;
				border: solid 4px var(--color-border);
				border-top: solid 4px var(--color-highlight);
				animation: spin 0.7s ease-in-out infinite;
			}
		}
	}

  &-focus {
    display: block;
    grid-template-columns: 1fr;
  }
}

@keyframes spin {
	to {
		transform: rotate(360deg);
	}
}
</style>
