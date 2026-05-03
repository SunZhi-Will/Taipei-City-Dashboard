<script setup>
import { ref, watch, nextTick, onMounted, onUnmounted } from "vue";
import { useRouter } from "vue-router";
import { storeToRefs } from "pinia";
import ChatResultComponents from "../dialogs/ChatResultComponents.vue";
import ChatComposer from "../dialogs/chat/ChatComposer.vue";
import SuggestedTagsBar from "../dialogs/chat/SuggestedTagsBar.vue";

const renderMarkdown = (text) => {
	const raw = String(text || "").trim();
	if (!raw) return "";

	// HTML entity escaping (XSS prevention, no external sanitizer needed)
	const esc = (str) =>
		String(str)
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;");

	// Inline Markdown: bold, italic, inline code
	const inline = (str) =>
		esc(str)
			.replace(/\*\*\*(.+?)\*\*\*/g, "<strong><em>$1</em></strong>")
			.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
			.replace(/\*(.+?)\*/g, "<em>$1</em>")
			.replace(/__(.+?)__/g, "<strong>$1</strong>")
			.replace(/_(.+?)_/g, "<em>$1</em>")
			.replace(/`([^`]+)`/g, "<code>$1</code>");

	// Table block parser — replicates same paragraph-extraction & empty-table logic
	const parseTable = (tableLines) => {
		const rows = [];
		for (const line of tableLines) {
			const t = line.trim();
			if (!t.startsWith("|")) continue;
			if (/^\|[\s|:-]+\|$/.test(t)) continue; // separator row
			const cells = t.split("|").slice(1, -1).map((c) => c.trim());
			if (cells.length > 0) rows.push(cells);
		}
		if (rows.length === 0) return "";

		const headerRow = rows[0];
		const bodyRows = rows.slice(1);
		const extractedParagraphs = [];
		const dataRows = [];

		for (const row of bodyRows) {
			const firstCellText = row[0] || "";
			const hasOnlyFirstCell = row.slice(1).every((c) => !c.trim());
			const looksLikeParagraph = /[，。！？；：]/.test(firstCellText) && firstCellText.length >= 18;
			if (hasOnlyFirstCell && looksLikeParagraph) {
				extractedParagraphs.push(firstCellText);
			} else {
				dataRows.push(row);
			}
		}

		let html = "";
		if (dataRows.length > 0) {
			html += '<div class="ai-table-wrapper"><table class="ai-table"><thead><tr>';
			for (const cell of headerRow) html += `<th>${inline(cell)}</th>`;
			html += "</tr></thead><tbody>";
			for (const row of dataRows) {
				html += "<tr>";
				for (const cell of row) html += `<td>${inline(cell)}</td>`;
				html += "</tr>";
			}
			html += "</tbody></table></div>";
		}
		for (const p of extractedParagraphs) {
			html += `<p class="acp__table-followup">${inline(p)}</p>`;
		}
		return html;
	};

	const lines = raw.split("\n");
	const result = [];
	let i = 0;

	while (i < lines.length) {
		const line = lines[i];
		const trimmed = line.trim();

		if (!trimmed) { i++; continue; }

		// Heading
		const headingMatch = trimmed.match(/^(#{1,6}) (.+)/);
		if (headingMatch) {
			const level = headingMatch[1].length;
			result.push(`<h${level}>${inline(headingMatch[2])}</h${level}>`);
			i++;
			continue;
		}

		// Table
		if (trimmed.startsWith("|")) {
			const tableLines = [];
			while (i < lines.length && lines[i].trim().startsWith("|")) tableLines.push(lines[i++]);
			const tableHtml = parseTable(tableLines);
			if (tableHtml) result.push(tableHtml);
			continue;
		}

		// Unordered list
		if (/^[-*+] /.test(trimmed)) {
			const items = [];
			while (i < lines.length && /^[-*+] /.test(lines[i].trim()))
				items.push(`<li>${inline(lines[i++].trim().replace(/^[-*+] /, ""))}</li>`);
			result.push(`<ul>${items.join("")}</ul>`);
			continue;
		}

		// Ordered list
		if (/^\d+\. /.test(trimmed)) {
			const items = [];
			while (i < lines.length && /^\d+\. /.test(lines[i].trim()))
				items.push(`<li>${inline(lines[i++].trim().replace(/^\d+\. /, ""))}</li>`);
			result.push(`<ol>${items.join("")}</ol>`);
			continue;
		}

		// Paragraph (collect until blank line or block element)
		const paraLines = [];
		while (
			i < lines.length &&
			lines[i].trim() &&
			!lines[i].trim().startsWith("|") &&
			!/^[-*+] /.test(lines[i].trim()) &&
			!/^\d+\. /.test(lines[i].trim()) &&
			!/^#{1,6} /.test(lines[i].trim())
		) {
			paraLines.push(lines[i]);
			i++;
			if (i < lines.length && !lines[i].trim()) break;
		}
		if (paraLines.length > 0) {
			result.push(`<p>${paraLines.map((l) => inline(l)).join("<br>")}</p>`);
		}
	}

	return result.join("");
};

import { useAiStudioChatStore } from "../../store/aiStudioChatStore";
import { useContentStore } from "../../store/contentStore";
import { useAuthStore } from "../../store/authStore";
import http from "../../router/axios";

const chatStore = useAiStudioChatStore();
const contentStore = useContentStore();
const authStore = useAuthStore();
const router = useRouter();

const { addChatData, addQueryData, saveChatLog } = chatStore;
const { createDashboard } = contentStore;
const { chatData, isResponding } = storeToRefs(chatStore);
const { editDashboard } = storeToRefs(contentStore);
const { user } = storeToRefs(authStore);

const userMessage = ref("");
const chatAreaRef = ref(null);
const dashboardCreationLoading = ref(false);

// === 建議 Tags ===
const DEFAULT_TAGS = [
	"空氣品質", "交通壅塞", "捷運人流", "垃圾清運", "醫療資源", "老年人口",
];
const suggestedTags = ref([...DEFAULT_TAGS]);

const clickTag = async (tag) => {
	if (isResponding.value) return;
	await addQueryData({ role: "user", content: tag });
};

// 根據 bot 回覆動態更新 tags
watch(
	chatData,
	(newVal) => {
		const lastBot = [...newVal].reverse().find((m) => m.role === "bot" && !m.isDefault);
		if (!lastBot) return;
		const content = (lastBot.content || "") + (lastBot.components?.map((c) => c.name).join(" ") || "");
		const contextMap = [
			{ keywords: ["空氣", "PM2.5", "AQI", "污染"], tags: ["PM2.5 即時", "空氣品質指標", "各站空品"] },
			{ keywords: ["交通", "車流", "速率", "壅塞"], tags: ["路口車流量", "公車即時", "停車場資訊"] },
			{ keywords: ["捷運", "MRT", "地鐵"], tags: ["捷運進出站", "各線人流", "延誤查詢"] },
			{ keywords: ["垃圾", "清運", "廢棄物", "回收"], tags: ["垃圾清運量", "資源回收率", "廚餘處理"] },
			{ keywords: ["老年", "老化", "長照", "扶養"], tags: ["老化指數", "長照資源", "社福補助"] },
			{ keywords: ["醫療", "醫院", "診所", "救護"], tags: ["醫院分布", "AED 位置", "119 統計"] },
			{ keywords: ["水", "用水", "降雨", "水庫"], tags: ["水庫蓄水率", "降雨量統計", "淹水警戒"] },
			{ keywords: ["電", "用電", "能源", "再生"], tags: ["用電量統計", "太陽能發電", "碳排放量"] },
		];
		for (const rule of contextMap) {
			if (rule.keywords.some((k) => content.includes(k))) {
				suggestedTags.value = [...rule.tags, ...DEFAULT_TAGS.filter((t) => !rule.tags.includes(t)).slice(0, 3)];
				return;
			}
		}
		suggestedTags.value = [...DEFAULT_TAGS];
	},
	{ deep: true },
);

const qaBtnHandler = async (text, relations) => {
	if (text === "建立儀表板") {
		if (dashboardCreationLoading.value) return;
		dashboardCreationLoading.value = true;
		const response = await http.get("/dashboard/");
		if (response.data?.data?.personal?.length > 20) {
			addChatData({ role: "bot", content: "您的個人儀表板已超出限制 20 個，請先移除既有儀表板後，重新執行本功能！" });
			dashboardCreationLoading.value = false;
			return;
		}
		const safeRelations = Array.isArray(relations) ? relations : [];
		const components = Array.from(new Set(safeRelations.map((r) => r.id))).map((id) => ({ id }));
		if (user.value.user_id) {
			editDashboard.value = { index: "", name: "推薦儀表板", icon: "star", components };
			await createDashboard();
			saveChatLog("建立儀表板", "使用者成功建立儀表板!");
		} else {
			addChatData({ role: "bot", content: "請先登入會員以使用此功能喔！" });
		}
		dashboardCreationLoading.value = false;
	}
};

const sendBtnHandler = async () => {
	if (isResponding.value) return;
	const text = userMessage.value.trim();
	if (!text) return;
	userMessage.value = "";
	await addQueryData({ role: "user", content: text });
};

const copyToClipboard = async (text) => {
	if (!text) return;
	try { await navigator.clipboard.writeText(text); } catch { /* silent */ }
};

const handleExploreIndicator = async (indicatorName) => {
	if (isResponding.value || !indicatorName) return;
	await addQueryData({ role: "user", content: indicatorName });
};

const handleOpenMap = async (component) => {
	const mapConfig = component?.dashboardConfig?.map_config;
	if (!Array.isArray(mapConfig) || mapConfig.length === 0 || !mapConfig[0]) return;
	const city = component?.dashboardConfig?.city || contentStore.currentDashboard?.city || "taipei";
	const index = `map-layers-${city}`;
	const openComponentId = component?.dashboardConfig?.id;
	await router.push({
		name: "mapview",
		query: {
			index,
			city,
			openTrigger: String(Date.now()),
			...(openComponentId ? { openComponentId: String(openComponentId) } : {}),
		},
	});
};

const scrollToBottom = async () => {
	await nextTick();
	const el = chatAreaRef.value;
	if (el) el.scrollTop = el.scrollHeight;
};

// ResizeObserver: 圖表非同步撐高後補捲到底
let _ro = null;
onMounted(() => {
	scrollToBottom();
	_ro = new ResizeObserver(() => {
		const el = chatAreaRef.value;
		if (!el) return;
		const fromBottom = el.scrollHeight - el.scrollTop - el.clientHeight;
		if (fromBottom < 400) el.scrollTop = el.scrollHeight;
	});
	if (chatAreaRef.value) _ro.observe(chatAreaRef.value);
});
onUnmounted(() => { if (_ro) _ro.disconnect(); });

const showScrollBtn = ref(false);
const onScroll = () => {
	const el = chatAreaRef.value;
	if (!el) return;
	showScrollBtn.value = el.scrollHeight - el.scrollTop - el.clientHeight > 120;
};
</script>

<template>
  <div class="acp">
    <!-- Messages area -->
    <div
      ref="chatAreaRef"
      class="acp__messages"
      role="log"
      aria-live="polite"
      @scroll.passive="onScroll"
    >
      <!-- Empty -->
      <div
        v-if="chatData.length === 0 && !isResponding"
        class="acp__empty"
      >
        <span class="material-icons-round acp__empty-icon">smart_toy</span>
        <p>輸入城市議題，AI 將推薦相關組件並生成場景</p>
      </div>

      <!-- Messages -->
      <template
        v-for="chat in chatData"
        :key="chat.id"
      >
        <!-- Bot -->
        <div
          v-if="chat.role === 'bot'"
          class="acp__row acp__row--bot"
        >
          <div class="acp__bot-block">
            <!-- eslint-disable-next-line vue/no-v-html -->
            <div
              v-if="chat.content"
              class="acp__bot-text acp__bot-markdown"
              v-html="renderMarkdown(chat.content)"
            />
            <ChatResultComponents
              v-if="chat.components && chat.components.length > 0"
              :components="chat.components"
              @copy="copyToClipboard"
              @explore="handleExploreIndicator"
              @open-map="handleOpenMap"
            />
            <div
              v-if="chat.relations && chat.relations.length > 0"
              class="acp__relations"
            >
              <div
                v-for="(item, idx) in chat.relations"
                :key="idx"
                class="acp__relation-item"
              >
                <span>{{ item.city === 'taipei' ? '🏙️' : '🌆' }}</span>
                <span class="acp__relation-name">{{ item.name }}</span>
              </div>
            </div>
            <div
              v-if="chat.button"
              class="acp__actions"
            >
              <button
                v-for="btn in chat.button"
                :key="btn.id"
                class="acp__action-btn"
                @click="qaBtnHandler(btn.text, chat.relations)"
              >
                {{ btn.text }}
              </button>
            </div>
          </div>
        </div>

        <!-- User -->
        <div
          v-else
          class="acp__row acp__row--user"
        >
          <div class="acp__user-bubble">
            <p class="acp__user-text">
              {{ chat.content }}
            </p>
          </div>
        </div>
      </template>

      <!-- Typing -->
      <div
        v-if="isResponding"
        class="acp__row acp__row--bot"
      >
        <div class="acp__typing">
          <span class="acp__dot" />
          <span class="acp__dot" />
          <span class="acp__dot" />
          <span class="acp__typing-label">AI 分析中…</span>
        </div>
      </div>
    </div>

    <!-- Scroll FAB -->
    <Transition name="acp-fade">
      <button
        v-if="showScrollBtn"
        class="acp__scroll-fab"
        aria-label="捲到最新訊息"
        @click="scrollToBottom"
      >
        <span class="material-icons-round">expand_more</span>
      </button>
    </Transition>

    <!-- Tags row -->
    <SuggestedTagsBar
      v-if="!isResponding && suggestedTags.length > 0"
      :tags="suggestedTags"
      @select="clickTag"
    />

    <!-- Composer -->
    <ChatComposer
      v-model="userMessage"
      :is-responding="isResponding"
      :compact="true"
      @send="sendBtnHandler"
    />
  </div>
</template>

<style scoped lang="scss">
$bg:     var(--color-background);
$panel:  var(--color-component-background);
$border: var(--color-border);
$text:   var(--color-normal-text);
$muted:  var(--color-complement-text);
$accent: var(--color-highlight);
$side:   var(--color-sidebar-bg-start);
$t: 0.18s cubic-bezier(0.4, 0, 0.2, 1);

/* ── Root ────────────────────────────────────── */
.acp {
	position: relative;
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
	background: $side;
	overflow: hidden;

	/* ── Messages ─────────────────────────────── */
	&__messages {
		flex: 1;
		min-height: 0;
		overflow-y: scroll;
		padding: 12px 14px 154px;
		display: flex;
		flex-direction: column;
		gap: 10px;
		scrollbar-width: thin;
		scrollbar-color: rgba(255,255,255,0.15) transparent;

		&::-webkit-scrollbar { width: 3px; }
		&::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.15); border-radius: 3px; }
	}

	/* ── Empty ────────────────────────────────── */
	&__empty {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 10px;
		padding: 32px 16px;
		text-align: center;
		color: $muted;
		margin: auto;

		p { font-size: var(--font-s); color: $muted; line-height: 1.6; }
	}

	&__empty-icon {
		font-size: 2.4rem;
		color: rgba(90, 156, 248, 0.5);
		animation: acp-pulse 2.8s ease-in-out infinite;
	}

	/* ── Message rows ─────────────────────────── */
	&__row {
		display: flex;
		width: 100%;

		&--user { justify-content: flex-end; }
		&--bot  { justify-content: flex-start; }
	}

	/* ── Bot block ────────────────────────────── */
	&__bot-block {
		width: 100%;
		max-width: 100%;
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	&__bot-text {
		font-size: var(--font-s);
		line-height: 1.7;
		color: $text;
		white-space: pre-wrap;
		word-break: break-word;
		margin: 0;
	}

	&__bot-markdown {
		display: block;
		width: 100%;
		white-space: normal;

		// Markdown 基本排版
		p { margin: 0 0 0.4em; line-height: 1.7; }
		strong { font-weight: 600; color: $text; }
		em { font-style: italic; }
		ul, ol { margin: 0.3em 0 0.3em 1.2em; padding: 0; }
		li { margin-bottom: 2px; }

		// 表格樣式（對齊 ChatBox 結構）
		:deep(.ai-table-wrapper) {
			display: block;
			width: 100%;
			min-width: 100%;
			margin: 0.5em 0 0.35em;
			inline-size: 100%;
			max-inline-size: 100%;
			overflow-x: auto;
			overflow-y: hidden;
			border-radius: 6px;
			border: 1px solid rgba(255, 255, 255, 0.12);
			box-sizing: border-box;
		}

		:deep(.ai-table) {
			display: table;
			width: 100%;
			min-width: 100%;
			max-width: 100%;
			border-collapse: collapse;
			table-layout: fixed;
			font-size: 0.8rem;
			border: 1px solid rgba(255, 255, 255, 0.28);
			box-sizing: border-box;

			th, td {
				padding: 6px 10px;
				border: 1px solid rgba(255, 255, 255, 0.22);
				text-align: left;
				white-space: normal;
				overflow-wrap: anywhere;
				word-break: break-word;
				vertical-align: top;
			}

			th:nth-child(1), td:nth-child(1) {
				width: 56px;
				white-space: nowrap;
			}

			th:nth-child(2), td:nth-child(2) {
				width: 84px;
				white-space: nowrap;
			}

			th:last-child, td:last-child { width: calc(100% - 140px); }

			th {
				background: rgba(255, 255, 255, 0.09);
				color: $text;
				font-weight: 600;
				letter-spacing: 0.02em;
			}

			tr:nth-child(even) td { background: rgba(255, 255, 255, 0.04); }
			tr:hover td { background: rgba(90, 156, 248, 0.08); transition: background 0.15s; }
		}

		:deep(.acp__table-followup) {
			margin: 0.25em 0 0;
			line-height: 1.65;
			color: $text;
		}

		// 行內程式碼
		code {
			background: rgba(255, 255, 255, 0.1);
			border-radius: 3px;
			padding: 1px 5px;
			font-family: monospace;
			font-size: 0.85em;
		}
	}

	/* ── Bot avatar ───────────────────────────── */
	&__bot-avatar {
		flex-shrink: 0;
		font-size: 1rem;
		color: rgba(90, 156, 248, 0.55);
		margin-top: 2px;
		line-height: 1;
	}

	/* ── User bubble ──────────────────────────── */
	&__user-bubble {
		display: inline-block;
		max-width: 80%;
		min-width: 0;
		background: #6b7280;
		border: 1px solid rgba(255, 255, 255, 0.22);
		border-radius: 16px 6px 16px 16px;
		padding: 9px 13px;
		word-break: break-word;
		box-shadow: 0 8px 18px rgba(0, 0, 0, 0.24);
	}

	&__user-text {
		font-size: var(--font-s);
		color: $text;
		line-height: 1.6;
		white-space: pre-wrap;
		word-break: break-word;
		margin: 0;
	}

	/* ── Relations ────────────────────────────── */
	&__relations {
		display: flex;
		flex-direction: column;
		gap: 3px;
	}

	&__relation-item {
		display: flex;
		align-items: center;
		gap: 6px;
		padding: 4px 8px;
		border-radius: 5px;
		background: $panel;
		border: 1px solid $border;
		font-size: var(--font-s);
	}

	&__relation-name { color: $text; }

	/* ── Action buttons ───────────────────────── */
	&__actions {
		display: flex;
		flex-wrap: wrap;
		gap: 6px;
	}

	&__action-btn {
		padding: 4px 10px;
		border: 1px solid $accent;
		background: rgba($accent, 0.1);
		color: $accent;
		border-radius: 5px;
		font-size: var(--font-s);
		cursor: pointer;
		transition: background $t;
		&:hover { background: rgba($accent, 0.22); }
	}

	/* ── Typing ───────────────────────────────── */
	&__typing {
		display: flex;
		align-items: center;
		gap: 5px;
		padding: 8px 14px;
		border-radius: 4px 12px 12px 12px;
		background: $panel;
		border: 1px solid $border;
	}

	&__typing-label {
		font-size: 0.7rem;
		color: $muted;
		margin-left: 4px;
		letter-spacing: 0.02em;
	}

	&__dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: $muted;
		animation: acp-blink 1.3s infinite ease-in-out;
		&:nth-child(2) { animation-delay: 0.18s; }
		&:nth-child(3) { animation-delay: 0.36s; }
	}

	/* ── Scroll FAB ──────────────────────────── */
	&__scroll-fab {
		position: absolute;
		bottom: 112px;
		right: 14px;
		width: 32px;
		height: 32px;
		border: 1px solid rgba(255,255,255,0.2);
		border-radius: 50%;
		background: $panel;
		color: $muted;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		z-index: 10;
		box-shadow: 0 2px 8px rgba(0,0,0,0.35);
		transition: color $t, border-color $t;

		.material-icons-round { font-size: 1.1rem; }
		&:hover { color: $text; border-color: rgba(255,255,255,0.4); }
	}

}

.acp-fade-enter-active,
.acp-fade-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.acp-fade-enter-from,
.acp-fade-leave-to   { opacity: 0; transform: translateY(6px); }

@keyframes acp-blink {
	0%, 80%, 100% { opacity: 0.2; transform: scale(0.8); }
	40% { opacity: 1; transform: scale(1); }
}

@keyframes acp-pulse {
	0%, 100% { opacity: 0.5; transform: scale(1); }
	50% { opacity: 0.9; transform: scale(1.1); }
}
</style>
