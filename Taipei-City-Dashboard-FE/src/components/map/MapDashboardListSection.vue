<script setup>
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
]);

const handleDashboardClick = (dashboard) => {
	emit("dashboard-click", { scope: props.scope, dashboard, city: props.city });
};

const handleComponentToggle = (event, dashboard, component) => {
	emit("component-toggle", {
		checked: event.target.checked,
		dashboard,
		city: props.city,
		component,
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
          <label class="map-component-item-main">
            <input
              :checked="componentToggles[getComponentKey(dashboard, city, component)] || false"
              type="checkbox"
              @change="handleComponentToggle($event, dashboard, component)"
            >
            <span>{{ component.name }}</span>
            <small v-if="!hasMapConfig(component)">無地圖</small>
          </label>
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
</template>

<style scoped lang="scss">
.map-component-item {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 6px;
	padding: 4px;
	margin-bottom: 4px;
	border-radius: 4px;

	&:hover {
		background: rgba(255, 255, 255, 0.06);
	}
}

.map-component-item-main {
	display: flex;
	align-items: center;
	flex: 1;
	min-width: 0;
	color: #b7bcc3;
	font-size: 0.8rem;
	cursor: pointer;

	input {
		width: 16px;
		height: 16px;
		margin-right: 6px;
		cursor: pointer;
		flex-shrink: 0;
	}

	span {
		flex: 1;
		min-width: 0;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	small {
		font-size: 0.7rem;
		color: #8b92a8;
		margin-left: 4px;
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