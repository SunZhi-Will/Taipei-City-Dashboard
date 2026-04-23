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

const emit = defineEmits(["dashboard-click", "component-toggle"]);

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
        <label
          v-for="component in getDashboardComponents(dashboard, city)"
          :key="component.id"
          class="map-component-item"
        >
          <input
            :checked="componentToggles[getComponentKey(dashboard, city, component)] || false"
            type="checkbox"
            @change="handleComponentToggle($event, dashboard, component)"
          >
          <span>{{ component.name }}</span>
          <small v-if="!hasMapConfig(component)">無地圖</small>
        </label>
      </div>
    </div>
  </div>
</template>