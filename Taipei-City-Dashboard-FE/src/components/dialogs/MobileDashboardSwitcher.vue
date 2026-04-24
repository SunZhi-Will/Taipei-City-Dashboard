<!-- Developed by Taipei Urban Intelligence Center 2024 -->
<script setup>
import { computed, onMounted, ref, watch } from "vue";
import { useContentStore } from "../../store/contentStore";
import { useAuthStore } from "../../store/authStore";
import SideBarTab from "../utilities/miscellaneous/SideBarTab.vue";

const props = defineProps({
  isOpen: Boolean
});

const emit = defineEmits(['close']);
const contentStore = useContentStore();
const authStore = useAuthStore();

const collapsedStates = ref({
  favorites: false,
  personal: false,
});

function initializeCollapsedStates() {
  contentStore.cityManager.activeCities.forEach((city) => {
    if (!(city in collapsedStates.value)) {
      collapsedStates.value[city] = false;
    }
  });
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
  },
  { immediate: true },
);

onMounted(() => {
  initializeCollapsedStates();
});

const personalDashboards = computed(() =>
  contentStore.personalDashboards.filter((item) => item.icon !== "favorite"),
);

const hasPublicDashboards = computed(() =>
  contentStore.cityManager.activeCities.some(
    (city) => (contentStore.getDashboardsByCity(city) || []).length > 0,
  ),
);

const closeSwitcher = () => {
  emit("close");
};
</script>

<template>
  <teleport to="body">
    <transition name="menu-fade">
      <div 
        v-if="isOpen"
        class="mobile-switcher-overlay"
        @click="$emit('close')"
      >
        <div 
          class="mobile-switcher-container"
          @click.stop
        >
          <div class="mobile-switcher-content mobile-switcher">
            <template v-if="authStore.token">
              <h1 @click="toggleCollapse(['favorites', 'personal'])">
                <span class="mobile-switcher-heading-icon material-icons-round">account_circle</span>
                私人儀表板
                <span
                  class="mobile-switcher-chevron material-icons-round"
                  aria-hidden="true"
                >{{ collapsedStates.favorites && collapsedStates.personal ? "arrow_drop_down" : "arrow_drop_up" }}</span>
              </h1>

              <h2 @click="toggleCollapse('favorites')">
                我的最愛
                <span
                  class="mobile-switcher-chevron material-icons-round"
                  aria-hidden="true"
                >{{ collapsedStates.favorites ? "arrow_drop_down" : "arrow_drop_up" }}</span>
              </h2>

              <transition name="collapse">
                <template v-if="!collapsedStates.favorites && contentStore.favorites?.index">
                  <SideBarTab
                    icon="favorite"
                    title="收藏組件"
                    :expanded="true"
                    :index="contentStore.favorites?.index"
                    :level="3"
                    @click="closeSwitcher"
                  />
                </template>
              </transition>

              <h2 @click="toggleCollapse('personal')">
                個人儀表板
                <span
                  class="mobile-switcher-chevron material-icons-round"
                  aria-hidden="true"
                >{{ collapsedStates.personal ? "arrow_drop_down" : "arrow_drop_up" }}</span>
              </h2>

              <div
                v-if="personalDashboards.length === 0"
                class="switcher-sub-no"
              >
                <p>尚無個人儀表板</p>
              </div>

              <transition name="collapse">
                <div v-if="!collapsedStates.personal">
                  <SideBarTab
                    v-for="item in personalDashboards"
                    :key="item.index"
                    :icon="item.icon"
                    :title="item.name"
                    :index="item.index"
                    :expanded="true"
                    :level="3"
                    @click="closeSwitcher"
                  />
                </div>
              </transition>
            </template>

            <h1 @click="toggleCollapse(contentStore.cityManager.activeCities)">
              <span class="mobile-switcher-heading-icon material-icons-round">public</span>
              公共儀表板
              <span
                class="mobile-switcher-chevron material-icons-round"
                aria-hidden="true"
              >{{ contentStore.cityManager.activeCities.every((city) => collapsedStates[city]) ? "arrow_drop_down" : "arrow_drop_up" }}</span>
            </h1>

            <div
              v-if="!hasPublicDashboards"
              class="switcher-sub-no"
            >
              <p>尚無公共儀表板</p>
            </div>

            <template
              v-for="city in contentStore.cityManager.activeCities"
              :key="city"
            >
              <h2 @click="toggleCollapse(city)">
                {{ contentStore.cityManager.getExpandedNameName(city) }}
                <span
                  class="mobile-switcher-chevron material-icons-round"
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
                    :expanded="true"
                    :level="3"
                    @click="closeSwitcher"
                  />
                </div>
              </transition>
            </template>
          </div>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<style scoped lang="scss">
.mobile-switcher-overlay {
  position: fixed;
  top: 60px; /* Start below NavBar */
  left: 0;
  width: 100vw;
  height: calc(100vh - 60px);
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  z-index: 2000;
  display: flex;
  flex-direction: column;
}

.mobile-switcher-container {
  width: 100%;
  background: rgba(25, 25, 25, 0.95);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5);
  max-height: 80vh;
  overflow-y: auto;
  animation: slideDown 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.mobile-switcher-content {
  padding: 16px 20px 24px;
}

.mobile-switcher {
  width: 100%;
  max-height: 80vh;
  overflow-y: auto;

  h1 {
    display: flex;
    align-items: center;
    cursor: pointer;
    margin: 12px 0;
    min-height: 26px;
    color: var(--color-normal-text);
    font-size: var(--font-l);
  }

  h2 {
    display: flex;
    align-items: center;
    color: var(--color-complement-text);
    font-weight: 400;
    cursor: pointer;
    min-height: 26px;
    margin: 2px 0 2px 1em;
    font-size: var(--font-m);
  }
}

.mobile-switcher-heading-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  margin-right: 8px;
  color: var(--color-complement-text);
  font-size: 18px;
}

.mobile-switcher-chevron {
  font-family: "Material Icons Round", var(--font-icon);
  font-style: normal;
  font-weight: 400;
  font-size: 18px;
  line-height: 1;
  letter-spacing: normal;
  text-transform: none;
  white-space: nowrap;
  direction: ltr;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
  font-feature-settings: "liga";
  margin-left: auto;
  color: var(--color-complement-text);
}

.switcher-sub-no {
  margin: 0.5rem 0 0.5rem 18px;
  font-size: var(--font-s);
  font-style: italic;
  color: var(--color-sidebar-muted-text);
}

/* Reuse sidebar tab visuals for strict consistency with left sidebar. */
:deep(.sidebartab) {
  margin: 2px 0;
  padding-left: 8px;
  padding-right: 8px;

  .sidebartab-label {
    max-width: none;
  }
}

.collapse-enter-active,
.collapse-leave-active {
  transition: max-height 0.22s ease, opacity 0.2s ease;
  overflow: hidden;
}

.collapse-enter-from,
.collapse-leave-to {
  max-height: 0;
  opacity: 0;
}

.collapse-enter-to,
.collapse-leave-from {
  max-height: 600px;
  opacity: 1;
}

@keyframes slideDown {
  from { transform: translateY(-30px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

/* Menu Transitions */
.menu-fade-enter-active,
.menu-fade-leave-active {
  transition: opacity 0.3s ease;
}

.menu-fade-enter-from,
.menu-fade-leave-to {
  opacity: 0;
}
</style>
