<!-- Admin: AI 問答模式統計頁面 / AI Answer Mode KPI Stats Page -->
<script setup>
import { ref, computed, onMounted, watch } from "vue";
import VueApexCharts from "vue3-apexcharts";
import { useAdminStore } from "../../store/adminStore";

const adminStore = useAdminStore();

const selectedDays = ref(30);
const dayOptions = [7, 14, 30, 60, 90];

const MODES = ["agent_rag", "agent_chat", "vector_fallback", "unknown"];
const MODE_LABELS = {
	agent_rag: "Agent + RAG",
	agent_chat: "Agent",
	vector_fallback: "向量備援",
	unknown: "未知",
};
const MODE_COLORS = {
	agent_rag: "#4ade80",
	agent_chat: "#60a5fa",
	vector_fallback: "#facc15",
	unknown: "#94a3b8",
};

const stats = computed(() => adminStore.aiStats);

// --- Summary cards ---
const summaryCards = computed(() => {
	if (!stats.value) return [];
	const { totals, total } = stats.value;
	return MODES.filter((m) => totals?.[m] != null).map((m) => ({
		mode: m,
		label: MODE_LABELS[m],
		count: totals[m] || 0,
		pct: total ? ((totals[m] / total) * 100).toFixed(1) : "0.0",
		color: MODE_COLORS[m],
	}));
});

// --- Chart data: group daily rows by date ---
const chartOptions = computed(() => {
	if (!stats.value?.daily?.length) return {};
	const dailyMap = {};
	for (const row of stats.value.daily) {
		if (!dailyMap[row.date]) dailyMap[row.date] = {};
		dailyMap[row.date][row.answer_mode] = row.count;
	}
	const sortedDates = Object.keys(dailyMap).sort();

	return {
		chart: { type: "line", toolbar: { show: false }, background: "transparent" },
		theme: { mode: "dark" },
		stroke: { curve: "smooth", width: 2 },
		xaxis: {
			categories: sortedDates,
			labels: { rotate: -45, style: { fontSize: "11px" } },
		},
		yaxis: { labels: { formatter: (v) => Math.round(v) } },
		legend: { position: "top" },
		colors: MODES.map((m) => MODE_COLORS[m]),
		tooltip: { x: { show: true } },
		grid: { borderColor: "#3f3f46" },
	};
});

const chartSeries = computed(() => {
	if (!stats.value?.daily?.length) return [];
	const dailyMap = {};
	for (const row of stats.value.daily) {
		if (!dailyMap[row.date]) dailyMap[row.date] = {};
		dailyMap[row.date][row.answer_mode] = row.count;
	}
	const sortedDates = Object.keys(dailyMap).sort();
	return MODES.map((m) => ({
		name: MODE_LABELS[m],
		data: sortedDates.map((d) => dailyMap[d]?.[m] || 0),
	})).filter((s) => s.data.some((v) => v > 0));
});

// --- Daily table: flattened rows sorted desc by date ---
const tableRows = computed(() => {
	if (!stats.value?.daily) return [];
	return [...stats.value.daily].sort((a, b) => b.date.localeCompare(a.date));
});

function refresh() {
	adminStore.getAiStats(selectedDays.value);
}

watch(selectedDays, refresh);
onMounted(refresh);
</script>

<template>
  <div class="ai-stats">
    <!-- Header -->
    <div class="ai-stats-header">
      <h2>AI 問答模式統計</h2>
      <div class="ai-stats-controls">
        <label>觀察區間</label>
        <select v-model="selectedDays">
          <option
            v-for="d in dayOptions"
            :key="d"
            :value="d"
          >
            最近 {{ d }} 天
          </option>
        </select>
        <button @click="refresh">
          重新整理
        </button>
      </div>
    </div>

    <!-- Summary cards -->
    <div class="ai-stats-cards">
      <div
        v-for="card in summaryCards"
        :key="card.mode"
        class="ai-stats-card"
        :style="{ borderLeftColor: card.color }"
      >
        <p class="ai-stats-card-label">
          {{ card.label }}
        </p>
        <p class="ai-stats-card-count">
          {{ card.count.toLocaleString() }}
        </p>
        <p class="ai-stats-card-pct">
          {{ card.pct }}%
        </p>
      </div>
      <div
        v-if="stats"
        class="ai-stats-card ai-stats-card--total"
      >
        <p class="ai-stats-card-label">
          總計
        </p>
        <p class="ai-stats-card-count">
          {{ (stats.total || 0).toLocaleString() }}
        </p>
        <p class="ai-stats-card-pct">
          {{ selectedDays }} 天
        </p>
      </div>
    </div>

    <!-- Line chart -->
    <div
      v-if="chartSeries.length"
      class="ai-stats-chart"
    >
      <VueApexCharts
        type="line"
        height="280"
        :options="chartOptions"
        :series="chartSeries"
      />
    </div>
    <div
      v-else
      class="ai-stats-empty"
    >
      暫無資料
    </div>

    <!-- Daily detail table -->
    <div
      v-if="tableRows.length"
      class="ai-stats-table-wrap"
    >
      <table class="ai-stats-table">
        <thead>
          <tr>
            <th>日期</th>
            <th>模式</th>
            <th>次數</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="(row, i) in tableRows"
            :key="i"
          >
            <td>{{ row.date }}</td>
            <td>
              <span
                class="ai-stats-badge"
                :style="{ background: MODE_COLORS[row.answer_mode] || '#94a3b8' }"
              >
                {{ MODE_LABELS[row.answer_mode] || row.answer_mode }}
              </span>
            </td>
            <td>{{ row.count }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style scoped lang="scss">
.ai-stats {
  padding: 1.5rem;
  color: var(--color-text);
  width: 100%;
  max-width: 960px;

  &-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 1rem;
    margin-bottom: 1.25rem;

    h2 { margin: 0; font-size: 1.25rem; }
  }

  &-controls {
    display: flex;
    align-items: center;
    gap: 0.75rem;

    label { font-size: 0.85rem; color: var(--color-complement-text); }

    select {
      background: var(--color-component-background);
      color: var(--color-text);
      border: 1px solid var(--color-border);
      border-radius: 6px;
      padding: 0.3rem 0.6rem;
      cursor: pointer;
    }

    button {
      background: var(--color-highlight);
      color: #000;
      border: none;
      border-radius: 6px;
      padding: 0.35rem 0.9rem;
      font-size: 0.85rem;
      cursor: pointer;
      &:hover { filter: brightness(1.1); }
    }
  }

  &-cards {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
  }

  &-card {
    flex: 1 1 140px;
    background: var(--color-component-background);
    border: 1px solid var(--color-border);
    border-left: 4px solid #60a5fa;
    border-radius: 8px;
    padding: 0.85rem 1rem;

    &--total { border-left-color: #e2e8f0; }

    &-label {
      font-size: 0.78rem;
      color: var(--color-complement-text);
      margin: 0 0 0.3rem;
    }

    &-count {
      font-size: 1.5rem;
      font-weight: 700;
      margin: 0;
    }

    &-pct {
      font-size: 0.8rem;
      color: var(--color-complement-text);
      margin: 0.15rem 0 0;
    }
  }

  &-chart {
    background: var(--color-component-background);
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 1.5rem;
  }

  &-empty {
    text-align: center;
    padding: 3rem;
    color: var(--color-complement-text);
    font-size: 0.9rem;
  }

  &-table-wrap {
    overflow-x: auto;
  }

  &-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.88rem;

    th, td {
      padding: 0.55rem 0.9rem;
      text-align: left;
      border-bottom: 1px solid var(--color-border);
    }

    th { color: var(--color-complement-text); font-weight: 600; }

    tbody tr:hover { background: var(--color-component-background); }
  }

  &-badge {
    display: inline-block;
    padding: 2px 10px;
    border-radius: 999px;
    font-size: 11px;
    font-weight: 700;
    color: #000;
  }
}
</style>
