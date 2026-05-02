<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { onMounted, ref, watch, computed } from "vue";
import { useContentStore } from "../../../store/contentStore";
import { useDialogStore } from "../../../store/dialogStore";
import { useMapStore } from "../../../store/mapStore";
import { useAuthStore } from "../../../store/authStore";
import SideBarTab from "../miscellaneous/SideBarTab.vue";

const contentStore = useContentStore();
const dialogStore = useDialogStore();
const mapStore = useMapStore();
const authStore = useAuthStore();
const SIDEBAR_EXPANDED_KEY = "dashboard.sidebar.expanded";
const SIDEBAR_COLLAPSED_GROUPS_KEY = "dashboard.sidebar.collapsedGroups";

const formattedTimeToUpdate = computed(() => {
	const t = contentStore.timeToUpdate;
	const minutes = Math.floor(t / 60);
	const seconds = t % 60;
	return `${minutes}:${seconds < 10 ? "0" : ""}${seconds}`;
});

const isExpanded = ref(true);
const collapsedStates = ref({
	private: false,
	public: false,
	favorites: false,
	personal: false,
});

function initializeCollapsedStates() {
	const normalized = {
		private: Boolean(collapsedStates.value.private),
		public: Boolean(collapsedStates.value.public),
		favorites: Boolean(collapsedStates.value.favorites),
		personal: Boolean(collapsedStates.value.personal),
	};

	contentStore.cityManager.activeCities.forEach((city) => {
		normalized[city] = Boolean(collapsedStates.value[city]);
	});

	collapsedStates.value = normalized;
}

function restoreCollapsedStates() {
	const storedCollapsedGroups = localStorage.getItem(SIDEBAR_COLLAPSED_GROUPS_KEY);
	if (!storedCollapsedGroups) {
		return;
	}

	try {
		const parsed = JSON.parse(storedCollapsedGroups);
		if (parsed && typeof parsed === "object") {
			collapsedStates.value = {
				...collapsedStates.value,
				...parsed,
			};
		}
	} catch {
		localStorage.removeItem(SIDEBAR_COLLAPSED_GROUPS_KEY);
	}
}

function handleOpenAddDashboard() {
	dialogStore.addEdit = "add";
	dialogStore.showDialog("addEditDashboards");
}

function toggleExpand() {
	isExpanded.value = isExpanded.value ? false : true;
	localStorage.setItem(SIDEBAR_EXPANDED_KEY, String(isExpanded.value));
	if (!isExpanded.value) {
		mapStore.resizeMap();
	}
}

function toggleCollapse(cities) {
	cities = [cities].flat();
	const allCollapsed = cities.every((city) => collapsedStates.value[city]);

	cities.forEach((city) => {
		collapsedStates.value[city] = !allCollapsed;
	});
}

watch(
	() => contentStore.cityManager.activeCities,
	() => {
		initializeCollapsedStates();
		localStorage.setItem(
			SIDEBAR_COLLAPSED_GROUPS_KEY,
			JSON.stringify(collapsedStates.value)
		);
	},
	{ immediate: true }
);

watch(
	collapsedStates,
	(state) => {
		localStorage.setItem(SIDEBAR_COLLAPSED_GROUPS_KEY, JSON.stringify(state));
	},
	{ deep: true }
);

onMounted(() => {
	restoreCollapsedStates();
	initializeCollapsedStates();
	const storedExpandedState = localStorage.getItem(SIDEBAR_EXPANDED_KEY);
	if (storedExpandedState === "false") {
		isExpanded.value = false;
	} else {
		isExpanded.value = true;
	}
});
</script>

<template>
  <div
    :class="{
      sidebar: true,
      'sidebar-collapse': !isExpanded,
      'hide-if-mobile': true,
    }"
  >
    <div
      class="sidebar-collapse-btnContainer"
      :class="{ notExpanded: !isExpanded }"
    >
      <button
        class="sidebar-collapse-btnContainer-button"
        :aria-label="isExpanded ? '收合側欄' : '展開側欄'"
        @click="toggleExpand"
      >
        <span>{{
          isExpanded
            ? "keyboard_double_arrow_left"
            : "keyboard_double_arrow_right"
        }}</span>
      </button>
    </div>

    <div class="sidebar-content">
      <template v-if="authStore.token">
        <h1 @click="toggleCollapse('private')">
          <span class="sidebar-icon material-icons-round">account_circle</span>
          <span
            class="sidebar-label"
            :class="{ 'is-hidden': !isExpanded }"
          >私人儀表板</span>
          <span
            class="sidebar-chevron material-icons-round"
            aria-hidden="true"
          >{{ collapsedStates.private ? "arrow_drop_down" : "arrow_drop_up" }}</span>
        </h1>
        <transition name="collapse">
          <div v-if="!collapsedStates.private">
            <h2 @click="toggleCollapse('favorites')">
              <span class="sidebar-icon material-icons-round">star_border</span>
              <span
                class="sidebar-label"
                :class="{ 'is-hidden': !isExpanded }"
              >我的最愛</span>
              <span
                class="sidebar-chevron material-icons-round"
                aria-hidden="true"
              >{{ collapsedStates.favorites ? "arrow_drop_down" : "arrow_drop_up" }}</span>
            </h2>
            <transition name="collapse">
              <template v-if="!collapsedStates.favorites">
                <SideBarTab
                  icon="favorite"
                  title="收藏組件"
                  :expanded="isExpanded"
                  :index="contentStore.favorites?.index"
                  :level="3"
                />
              </template>
            </transition>
            <h2 @click="toggleCollapse('personal')">
              <span class="sidebar-icon material-icons-round">person</span>
              <span
                class="sidebar-label"
                :class="{ 'is-hidden': !isExpanded }"
              >個人儀表板</span>
              <span
                class="sidebar-chevron material-icons-round"
                aria-hidden="true"
              >{{ collapsedStates.personal ? "arrow_drop_down" : "arrow_drop_up" }}</span>
            </h2>
            <div
              v-if="
                !collapsedStates.personal &&
                  contentStore.personalDashboards.filter(
                    (item) => item.icon !== 'favorite'
                  ).length === 0
              "
              class="sidebar-sub-no"
            >
              <p>{{ isExpanded ? `尚無個人儀表板 ` : `尚無` }}</p>
            </div>
            <transition name="collapse">
              <div v-if="!collapsedStates.personal">
                <SideBarTab
                  v-for="item in contentStore.personalDashboards.filter(
                    (item) => item.icon !== 'favorite'
                  )"
                  :key="item.index"
                  :icon="item.icon"
                  :title="item.name"
                  :index="item.index"
                  :expanded="isExpanded"
                  :level="3"
                />
                <button
                  v-if="isExpanded"
                  class="sidebar-add-item"
                  aria-label="新增個人儀表板"
                  @click="handleOpenAddDashboard"
                >
                  <span>add_circle_outline</span>新增
                </button>
              </div>
            </transition>
          </div>
        </transition>
      </template>
      <h1 @click="toggleCollapse('public')">
        <span class="sidebar-icon material-icons-round">public</span>
        <span
          class="sidebar-label"
          :class="{ 'is-hidden': !isExpanded }"
        >公共儀表板</span>
        <span
          class="sidebar-chevron material-icons-round"
          aria-hidden="true"
        >{{ collapsedStates.public ? "arrow_drop_down" : "arrow_drop_up" }}</span>
      </h1>
      <transition name="collapse">
        <div v-if="!collapsedStates.public">
          <template
            v-for="city in contentStore.cityManager.activeCities"
            :key="city"
          >
            <h2 @click="toggleCollapse(city)">
              {{ isExpanded ? `${contentStore.cityManager.getExpandedNameName(city)} ` : contentStore.cityManager.getCollapsedName(city) }}
              <span
                class="sidebar-chevron material-icons-round"
                aria-hidden="true"
              >{{ collapsedStates[city] ? "arrow_drop_down" : "arrow_drop_up" }}</span>
            </h2>
            <transition name="collapse">
              <div
                v-if="
                  !collapsedStates[city] &&
                    contentStore.getDashboardsByCity(city)?.length > 0
                "
              >
                <SideBarTab
                  v-for="item in contentStore.getDashboardsByCity(city)"
                  :key="item.index"
                  :icon="item.icon"
                  :title="item.name"
                  :index="item.index"
                  :city="city"
                  :expanded="isExpanded"
                  :level="3"
                />
              </div>
            </transition>
          </template>
        </div>
      </transition>
    </div>
    <div class="sidebar-update">
      <p>{{ isExpanded ? '下次更新：' : '' }}{{ formattedTimeToUpdate }}</p>
    </div>
  </div>
</template>

<style scoped lang="scss">
.sidebar {
width: 12.5rem;
min-width: 12.5rem;
height: calc(100vh - 60px);
height: calc(var(--vh) * 100 - 60px);
max-height: calc(100vh - 60px);
max-height: calc(var(--vh) * 100 - 60px);
position: relative;
z-index: 15;
padding: 0;
border: 1px solid var(--color-sidebar-border);
border-right: 1px solid var(--color-sidebar-border);
background: linear-gradient(
  180deg,
  var(--color-sidebar-bg-start) 0%,
  var(--color-sidebar-bg-end) 100%
);
box-shadow: 8px 0 24px var(--color-sidebar-shadow);
transition: width 0.32s cubic-bezier(0.4, 0, 0.2, 1),
min-width 0.32s cubic-bezier(0.4, 0, 0.2, 1);
overflow: visible;
user-select: none;
display: flex;
flex-direction: column;

&-content {
flex: 1;
overflow-y: auto;
overflow-x: hidden;

&::-webkit-scrollbar {
width: 5px;
}
&::-webkit-scrollbar-thumb {
background: var(--color-sidebar-scrollbar-thumb);
border-radius: 999px;
}
}

.sidebar-label {
display: inline-block;
max-width: 11.5rem;
opacity: 1;
overflow: hidden;
text-overflow: ellipsis;
white-space: nowrap;
clip-path: inset(0 0 0 0);
transition: max-width 0.32s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.2s ease, clip-path 0.32s cubic-bezier(0.4, 0, 0.2, 1);

&.is-hidden {
  max-width: 0;
  opacity: 0.35;
  margin: 0;
  clip-path: inset(0 100% 0 0);
}
}

.sidebar-chevron {
font-family: "Material Icons Round", var(--font-icon);
font-style: normal;
font-weight: 400;
line-height: 1;
letter-spacing: normal;
text-transform: none;
white-space: nowrap;
direction: ltr;
-webkit-font-smoothing: antialiased;
-moz-osx-font-smoothing: grayscale;
text-rendering: optimizeLegibility;
font-feature-settings: "liga";
font-size: 16px;
min-width: 16px;
margin-left: auto;
margin-right: 0;
display: inline-flex;
align-items: center;
justify-content: center;
flex-shrink: 0;
transition: max-width 0.2s ease, opacity 0.2s ease, margin 0.2s ease;
}

// Section header - VS Code style
h1 {
display: flex;
align-items: center;
height: 2.25rem;
margin: 10px 8px 6px;
padding: 0 10px;
font-size: var(--font-m);
font-weight: 600;
text-transform: uppercase;
letter-spacing: 0.08em;
color: var(--color-normal-text);
cursor: pointer;
white-space: nowrap;
overflow: hidden;
border-radius: 999px;
transition: background-color 0.2s ease, padding 0.32s cubic-bezier(0.4, 0, 0.2, 1), margin 0.24s ease;

&:first-of-type {
margin-top: 4px;
}

.sidebar-icon {
font-family: "Material Icons Round", var(--font-icon);
font-style: normal;
font-weight: 400;
line-height: 1;
letter-spacing: normal;
text-transform: none;
white-space: nowrap;
direction: ltr;
-webkit-font-smoothing: antialiased;
-moz-osx-font-smoothing: grayscale;
text-rendering: optimizeLegibility;
font-feature-settings: "liga";
font-size: 16px;
margin-right: 6px;
margin-left: 0;
flex-shrink: 0;
transition: margin-left 0.32s cubic-bezier(0.4, 0, 0.2, 1), margin-right 0.32s cubic-bezier(0.4, 0, 0.2, 1);
}

&:hover {
background-color: var(--color-sidebar-item-hover-bg);
}
}

// Folder row - VS Code style
h2 {
display: flex;
align-items: center;
height: 2.25rem;
margin: 2px 8px;
padding: 0 10px 0 8px;
font-size: var(--font-m);
font-weight: 400;
color: var(--color-normal-text);
cursor: pointer;
white-space: nowrap;
overflow: hidden;
border-radius: 999px;
transition: background-color 0.2s ease, padding 0.32s cubic-bezier(0.4, 0, 0.2, 1), margin 0.24s ease;

.sidebar-icon {
font-family: "Material Icons Round", var(--font-icon);
font-style: normal;
font-weight: 400;
line-height: 1;
letter-spacing: normal;
text-transform: none;
white-space: nowrap;
direction: ltr;
-webkit-font-smoothing: antialiased;
-moz-osx-font-smoothing: grayscale;
text-rendering: optimizeLegibility;
font-feature-settings: "liga";
font-size: 16px;
margin-right: 6px;
margin-left: 0;
flex-shrink: 0;
transition: margin-left 0.32s cubic-bezier(0.4, 0, 0.2, 1), margin-right 0.32s cubic-bezier(0.4, 0, 0.2, 1);
}

&:hover {
background-color: var(--color-sidebar-item-hover-bg);
}
}

&-add-item {
display: flex;
align-items: center;
width: calc(100% - 16px);
box-sizing: border-box;
height: 2.25rem;
margin: 2px 8px;
padding: 0 10px 0 14px;
border-radius: 999px;
background: transparent;
color: var(--color-normal-text);
font-size: var(--font-m);
font-weight: 400;
cursor: pointer;
white-space: nowrap;
border: none;
transition: background-color 0.2s ease, color 0.2s ease;
text-decoration: none;

&:hover {
background-color: var(--color-sidebar-item-hover-bg);
}

span {
font-family: var(--font-icon);
font-size: 17px;
margin-right: 8px;
width: 17px;
height: 17px;
flex-shrink: 0;
display: inline-flex;
align-items: center;
justify-content: center;
}
}

&-sub {
&-no p {
padding: 0 8px 0 28px;
height: 2.25rem;
line-height: 2.25rem;
margin: 0;
font-size: var(--font-s);
color: var(--color-sidebar-muted-text);
font-style: italic;
white-space: nowrap;
}
}

&-update {
flex-shrink: 0;
display: flex;
align-items: center;
justify-content: center;
padding: 8px 0;
border-top: 1px solid var(--color-sidebar-border);
opacity: 0.45;
transition: opacity 0.3s;
user-select: none;
overflow: hidden;

&:hover {
opacity: 1;
}

p {
font-size: var(--font-s);
color: var(--color-complement-text);
white-space: nowrap;
}

span {
font-size: 16px;
color: var(--color-complement-text);
}
}

&-collapse {
width: 3.5rem;
min-width: 3.5rem;

h1 {
justify-content: flex-start;
padding: 0;
margin-left: 0;
margin-right: 0;
letter-spacing: 0;
border-radius: 12px;

.sidebar-chevron {
display: none;
}

.sidebar-icon {
margin-left: calc((3.5rem - 16px) / 2);
margin-right: 0;
}
}

h2 {
justify-content: flex-start;
padding: 0;
margin-left: 0;
margin-right: 0;
border-radius: 12px;

.sidebar-chevron {
display: none;
}

.sidebar-icon {
margin-left: calc((3.5rem - 16px) / 2);
margin-right: 0;
}
}

:deep(.sidebartab) {
padding: 0;
margin: 2px 6px;
justify-content: flex-start;
border-radius: 12px;
}

&-btnContainer {
position: absolute;
top: 14px;
right: -18px;
display: flex;
align-items: center;
justify-content: center;
width: 28px;
height: 28px;
padding: 0;
z-index: 20;

&-button {
display: flex;
align-items: center;
justify-content: center;
width: 28px;
height: 28px;
background-color: #2c2e31;
border: 2px solid var(--color-background);
border-radius: 50%;
box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
transition: transform 0.2s ease, box-shadow 0.2s ease;

&:hover {
transform: scale(1.08);
box-shadow: 0 4px 10px rgba(0, 0, 0, 0.24);
}

span {
font-family: var(--font-icon);
font-size: var(--font-m);
color: #fff;
}
}
}
}

.collapse-enter-from,
.collapse-leave-to {
opacity: 0;
transform: translateY(-4px);
}

.collapse-enter-active,
.collapse-leave-active {
transition: opacity 0.15s cubic-bezier(0.4, 0, 0.2, 1),
transform 0.15s cubic-bezier(0.4, 0, 0.2, 1);
}
}
</style>





