<!-- Developed by Taipei Urban Intelligence Center 2024 -->
<script setup>
import { useRoute, useRouter } from "vue-router";
import { useContentStore } from "../../store/contentStore";

const props = defineProps({
  isOpen: Boolean
});

const emit = defineEmits(['close']);
const route = useRoute();
const router = useRouter();
const contentStore = useContentStore();

const selectDashboard = (index, targetCity) => {
  // Determine city based on dashboard type
  const isPersonal = contentStore.personalDashboards.some(d => d.index === index);
  const city = isPersonal ? undefined : (targetCity || route.query.city || 'taipei');
  
  router.push({ 
    query: { 
      ...route.query, 
      index, 
      city 
    } 
  });
  emit('close');
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
          <div class="mobile-switcher-content">
            <!-- Personal Dashboards -->
            <div v-if="contentStore.personalDashboards.length > 0" class="switcher-group">
              <div class="switcher-header">私人儀表板</div>
              <div 
                v-for="item in contentStore.personalDashboards"
                :key="item.index"
                class="switcher-item"
                :class="{ 'is-active': contentStore.currentDashboard?.index === item.index }"
                @click="selectDashboard(item.index)"
              >
                <span class="material-icons-round">space_dashboard</span>
                {{ item.name }}
              </div>
            </div>
            
            <!-- City Dashboards -->
            <div 
              v-for="city in contentStore.cityManager.activeCities"
              :key="city"
              class="switcher-group"
            >
              <div class="switcher-header">{{ contentStore.cityManager.getExpandedNameName(city) }}</div>
              <div 
                v-for="item in contentStore.getDashboardsByCity(city)"
                :key="item.index"
                class="switcher-item"
                :class="{ 'is-active': contentStore.currentDashboard?.index === item.index && contentStore.currentDashboard?.city === city }"
                @click="selectDashboard(item.index, city)"
              >
                <span class="material-icons-round">map</span>
                {{ item.name }}
              </div>
            </div>
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
  padding: 16px 20px 30px;
}

.switcher-group {
  margin-bottom: 24px;
}

.switcher-header {
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--color-highlight);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 12px;
  padding-left: 2px;
  opacity: 0.8;
}

.switcher-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  margin: 4px 0;
  border-radius: 10px;
  font-size: 1rem;
  color: #fff;
  background: rgba(255, 255, 255, 0.03);
  transition: all 0.2s;
  cursor: pointer;
  
  span {
    font-size: 20px;
    color: var(--color-complement-text);
  }

  &.is-active {
    background: rgba(90, 156, 248, 0.15);
    color: var(--color-highlight);
    font-weight: 600;
    
    span {
      color: var(--color-highlight);
    }
  }

  &:active {
    background: rgba(255, 255, 255, 0.08);
    transform: scale(0.98);
  }
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
