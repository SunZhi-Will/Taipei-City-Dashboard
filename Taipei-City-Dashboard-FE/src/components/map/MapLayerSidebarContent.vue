<script setup>
import MapDashboardListSection from "./MapDashboardListSection.vue";
import { useMapLayerSidebarContent } from "./composables/useMapLayerSidebarContent";

const emit = defineEmits(["switch-dashboard"]);

const {
authStore,
contentStore,
privateCollapsed,
publicCollapsed,
favoriteCollapsed,
personalCollapsed,
selectedPublicCity,
expandedDashboardMap,
loadingDashboardKey,
componentToggles,
favoriteDashboards,
personalDashboards,
publicCityOptions,
publicDashboards,
buildDashboardKey,
componentKey,
hasMapConfig,
getDashboardComponents,
handleDashboardRowClick,
handleComponentSyncToggle,
} = useMapLayerSidebarContent(emit);
</script>

<template>
  <div class="map-island-content">
    <section
      v-if="authStore.token"
      class="map-group"
    >
      <button
        class="map-group-title"
        @click="privateCollapsed = !privateCollapsed"
      >
        私人儀表板
        <span>{{ privateCollapsed ? 'expand_more' : 'expand_less' }}</span>
      </button>

      <div v-if="!privateCollapsed">
        <button
          class="map-sub-title"
          @click="favoriteCollapsed = !favoriteCollapsed"
        >
          我的最愛
          <span>{{ favoriteCollapsed ? 'expand_more' : 'expand_less' }}</span>
        </button>
        <MapDashboardListSection
          v-if="!favoriteCollapsed && favoriteDashboards.length > 0"
          :dashboards="favoriteDashboards"
          scope="private"
          :expanded-dashboard-map="expandedDashboardMap"
          :loading-dashboard-key="loadingDashboardKey"
          :component-toggles="componentToggles"
          :get-dashboard-key="buildDashboardKey"
          :get-dashboard-components="getDashboardComponents"
          :get-component-key="componentKey"
          :has-map-config="hasMapConfig"
          @dashboard-click="handleDashboardRowClick"
          @component-toggle="handleComponentSyncToggle"
        />

        <button
          class="map-sub-title"
          @click="personalCollapsed = !personalCollapsed"
        >
          個人儀表板
          <span>{{ personalCollapsed ? 'expand_more' : 'expand_less' }}</span>
        </button>
        <MapDashboardListSection
          v-if="!personalCollapsed"
          :dashboards="personalDashboards"
          scope="private"
          :expanded-dashboard-map="expandedDashboardMap"
          :loading-dashboard-key="loadingDashboardKey"
          :component-toggles="componentToggles"
          :get-dashboard-key="buildDashboardKey"
          :get-dashboard-components="getDashboardComponents"
          :get-component-key="componentKey"
          :has-map-config="hasMapConfig"
          @dashboard-click="handleDashboardRowClick"
          @component-toggle="handleComponentSyncToggle"
        />
      </div>
    </section>

    <section class="map-group">
      <button
        class="map-group-title"
        @click="publicCollapsed = !publicCollapsed"
      >
        公共儀表板
        <span>{{ publicCollapsed ? 'expand_more' : 'expand_less' }}</span>
      </button>

      <div v-if="!publicCollapsed">
        <div
          v-if="publicCityOptions.length > 1"
          class="map-city-toggle"
        >
          <button
            v-for="city in publicCityOptions"
            :key="city"
            :class="['map-city-toggle-btn', { active: selectedPublicCity === city }]"
            @click="selectedPublicCity = city"
          >
            {{ contentStore.cityManager.getExpandedNameName(city) }}
          </button>
        </div>

        <MapDashboardListSection
          :dashboards="publicDashboards"
          scope="public"
          :city="selectedPublicCity"
          :expanded-dashboard-map="expandedDashboardMap"
          :loading-dashboard-key="loadingDashboardKey"
          :component-toggles="componentToggles"
          :get-dashboard-key="buildDashboardKey"
          :get-dashboard-components="getDashboardComponents"
          :get-component-key="componentKey"
          :has-map-config="hasMapConfig"
          @dashboard-click="handleDashboardRowClick"
          @component-toggle="handleComponentSyncToggle"
        />
      </div>
    </section>
  </div>
</template>

<style scoped lang="scss">
.map-island-content {
max-height: calc(100vh - 80px);
overflow-y: auto;
padding: 12px 10px 10px;
}

.map-group {
margin-bottom: 12px;

&-title {
width: 100%;
padding: 8px;
background: rgba(255, 255, 255, 0.06);
border: none;
border-radius: 8px;
color: #e8eaed;
font-weight: 600;
font-size: 0.85rem;
cursor: pointer;
display: flex;
justify-content: space-between;
align-items: center;

span {
font-family: var(--font-icon);
font-size: 0.8rem;
}

&:hover {
background: rgba(255, 255, 255, 0.1);
}
}
}

.map-sub-title {
width: 100%;
padding: 6px;
margin-top: 6px;
background: transparent;
border: none;
border-radius: 6px;
color: #b7bcc3;
font-size: 0.8rem;
font-weight: 500;
cursor: pointer;
display: flex;
justify-content: space-between;
align-items: center;
text-align: left;

span {
font-family: var(--font-icon);
font-size: 0.75rem;
}

&:hover {
background: rgba(255, 255, 255, 0.06);
}
}

.map-city-toggle {
display: flex;
margin-top: 6px;
margin-bottom: 8px;
background: rgba(255, 255, 255, 0.06);
border: 1px solid rgba(255, 255, 255, 0.12);
border-radius: 6px;
overflow: hidden;
}

.map-city-toggle-btn {
flex: 1;
padding: 5px 6px;
background: transparent;
border: none;
color: rgba(255, 255, 255, 0.5);
font-size: 0.78rem;
cursor: pointer;
transition: background 0.15s, color 0.15s;

&.active {
background: rgba(255, 255, 255, 0.15);
color: #e8eaed;
font-weight: 600;
}

&:hover:not(.active) {
background: rgba(255, 255, 255, 0.08);
color: rgba(255, 255, 255, 0.8);
}
}

:deep(.map-dashboard-list) {
padding: 0 4px;
}

:deep(.map-dashboard-item) {
margin-bottom: 6px;
}

:deep(.map-dashboard-row) {
display: flex;
width: 100%;
align-items: center;
justify-content: space-between;
padding: 6px;
background: rgba(255, 255, 255, 0.08);
border: none;
border-radius: 6px;
color: #e8eaed;
font-size: 0.8rem;
cursor: pointer;
text-align: left;

&:hover {
background: rgba(255, 255, 255, 0.12);
}

&:focus-visible {
outline: 1px solid rgba(255, 255, 255, 0.45);
outline-offset: 1px;
}
}

:deep(.map-dashboard-name) {
flex: 1;
padding-right: 8px;
white-space: nowrap;
overflow: hidden;
text-overflow: ellipsis;
}

:deep(.map-dashboard-arrow) {
flex: 0 0 24px;
display: flex;
align-items: center;
justify-content: center;
font-family: var(--font-icon);
font-size: 0.75rem;
}

:deep(.map-component-list) {
margin-top: 6px;
margin-left: 8px;
border-left: 2px solid rgba(255, 255, 255, 0.1);
padding-left: 8px;

p {
margin: 0;
font-size: 0.75rem;
color: #8b92a8;
padding: 4px;
}
}

:deep(.map-component-item) {
display: flex;
align-items: center;
padding: 4px;
margin-bottom: 4px;
border-radius: 4px;
cursor: pointer;
font-size: 0.8rem;
color: #b7bcc3;

input {
width: 16px;
height: 16px;
margin-right: 6px;
cursor: pointer;
flex-shrink: 0;
}

span {
flex: 1;
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

&:hover {
background: rgba(255, 255, 255, 0.06);
}
}
</style>
