<script setup>
import { ref, watch, nextTick, onMounted } from "vue";
import { useRouter } from "vue-router";
import { storeToRefs } from "pinia";
import BotLogo from "../icons/BotLogo.vue";
import ChatResultComponents from "./ChatResultComponents.vue";
import ChatComposer from "./chat/ChatComposer.vue";
import ChatHeader from "./chat/ChatHeader.vue";
import ChatStickyNotice from "./chat/ChatStickyNotice.vue";
import SuggestedTagsBar from "./chat/SuggestedTagsBar.vue";

import { useChatStore } from "../../store/chatStore";
import { useContentStore } from "../../store/contentStore";
import { useAuthStore } from "../../store/authStore";
import http from "../../router/axios";

const props = defineProps({
	showCloseButton: {
		type: Boolean,
		default: false,
	},
});

const emit = defineEmits(["close", "expand"]);

const chatStore = useChatStore();
const contentStore = useContentStore();
const authStore = useAuthStore();
const router = useRouter();
const { addChatData, addQueryData, saveChatLog, clearChatHistory } = chatStore;
const { createDashboard } = contentStore;
const { chatData, isResponding } = storeToRefs(chatStore);
const { editDashboard } = storeToRefs(contentStore);
const { user } = storeToRefs(authStore);

const userMessage = ref("");
const chatAreaRef = ref(null);
const isStickyOpen = ref(false);
const isExpanded = ref(false);
const dashboardCreationLoading = ref(false);
const tagsRefreshKey = ref(0);

// === 建議 Tags ===
// 初始：從現有儀表板名稱取前 6 個；AI 回覆後換成模型生成的 Tag
const suggestedTags = ref([]);

function buildInitialTags() {
	const names = [];
	for (const dashboards of contentStore.dashboards.values()) {
		for (const d of dashboards) {
			if (d.name && !d.index?.includes('map-layers')) {
				names.push(d.name);
			}
			if (names.length >= 6) break;
		}
		if (names.length >= 6) break;
	}
	return names;
}

// 點擊 tag 直接送出
const clickTag = async (tag) => {
	if (isResponding.value) return;
	await addQueryData({ role: "user", content: tag });
};

onMounted(() => {
	suggestedTags.value = buildInitialTags();
});

watch(
	() => contentStore.dashboards.size,
	() => {
		if (suggestedTags.value.length === 0) {
			suggestedTags.value = buildInitialTags();
		}
	},
);

watch(
	chatData,
	(newVal) => {
		const lastBot = [...newVal].reverse().find((m) => m.role === "bot" && !m.isDefault);
		if (!lastBot) {
			suggestedTags.value = buildInitialTags();
			return;
		}
		if (Array.isArray(lastBot.suggestedTags) && lastBot.suggestedTags.length > 0) {
			suggestedTags.value = lastBot.suggestedTags;
			return;
		}
		suggestedTags.value = buildInitialTags();
	},
	{ deep: true },
);
const qaBtnHandler = async (text, relations) => {
	if (text === "建立儀表板") {
		if (dashboardCreationLoading.value === true) return;
		dashboardCreationLoading.value = true;
		const response = await http.get(`/dashboard/`);
		if (response.data?.data?.personal?.length > 20) {
			addChatData({
				role: "bot",
				content:
					"您的個人儀表板已超出限制 20 個，請先移除既有儀表板後，重新執行本功能！",
			});
			dashboardCreationLoading.value = false;
			return;
		}
		const safeRelations = Array.isArray(relations) ? relations : [];
		const components = Array.from(new Set(safeRelations.map((r) => r.id))).map(
			(id) => ({ id }),
		);

		if (user.value.user_id) {
			editDashboard.value = {
				index: "",
				name: "推薦儀表板",
				icon: "star",
				components,
			};
			await createDashboard();
			saveChatLog("建立儀表板", "使用者成功建立儀表板!");
		} else {
			addChatData({
				role: "bot",
				content: "請先登入會員以使用此功能喔！",
			});
		}
		dashboardCreationLoading.value = false;
	}
};

const sendBtnHandler = async () => {
	if (isResponding.value) return;
	const normalizedText = userMessage.value.trim();
	if (!normalizedText) return;
	userMessage.value = "";
	await addQueryData({
		role: "user",
		content: normalizedText,
	});
};

const closeWidget = () => {
	emit("close");
};

const toggleExpand = () => {
	isExpanded.value = !isExpanded.value;
	emit("expand", isExpanded.value);
	tagsRefreshKey.value += 1;
};

const clearChat = () => {
	if (confirm("確定要清除所有聊天紀錄並開新的 Chat 嗎？")) {
		clearChatHistory();
	}
};

const copyToClipboard = async (text) => {
	if (!text) return;
	try {
		await navigator.clipboard.writeText(text);
	} catch (err) {
		console.error("複製失敗:", err);
	}
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
	const chat = chatAreaRef.value;
	if (!chat) return;
	chat.scrollTop = chat.scrollHeight - chat.clientHeight;
};

const renderContent = (content) => {
	if (!content) return "";
	
	const lines = content.split('\n');
	let inTable = false;
	let result = [];
	let tableRows = [];

	const generateTableHtml = (rows) => {
		if (rows.length === 0) return "";
		let html = '<div class="ai-table-wrapper"><table class="ai-table">';
		rows.forEach((row, index) => {
			if (index === 0) html += '<thead>';
			if (index === 1) html += '<tbody>';
			
			// 恢復所有列，並進行必要的顯示名稱轉換
			html += '<tr>';
			row.forEach((cell, cellIdx) => {
				const tag = index === 0 ? 'th' : 'td';
				let displayCell = cell;
				// 轉換城市名（僅限城市名稱欄位）
				if (cellIdx === 1) {
					if (cell === 'metrotaipei') displayCell = '雙北';
					if (cell === 'taipei') displayCell = '臺北';
				}
				html += `<${tag}>${displayCell}</${tag}>`;
			});
			html += '</tr>';
			
			if (index === 0) html += '</thead>';
		});
		if (rows.length > 1) html += '</tbody>';
		html += '</table></div>';
		return html;
	};

	for (let line of lines) {
		const trimmed = line.trim();
		if (trimmed.startsWith('|') && (trimmed.includes('|') || trimmed.endsWith('|'))) {
			if (!inTable) {
				inTable = true;
				tableRows = [];
			}
			const cells = trimmed.split('|').map(c => c.trim()).filter((c, i, arr) => i > 0 && i < arr.length - 1);
			if (trimmed.includes('---')) continue;
			if (cells.length > 0) {
				tableRows.push(cells);
			}
		} else {
			if (inTable) {
				result.push(generateTableHtml(tableRows));
				inTable = false;
			}
			if (trimmed) {
				result.push(`<p>${line}</p>`);
			}
		}
	}
	if (inTable) result.push(generateTableHtml(tableRows));
	
	return result.join('');
};

onMounted(() => {
	scrollToBottom();
});

watch(
	() => chatData.value.length,
	async () => {
		scrollToBottom();
	},
	{ deep: true },
);
</script>

<template>
  <div
    id="chat-widget-panel"
    class="chat-widget"
    role="dialog"
    aria-label="臺北城市儀表板小幫手"
    tabindex="-1"
  >
    <ChatHeader
      :show-close-button="props.showCloseButton"
      @clear="clearChat"
      @expand="toggleExpand"
      @close="closeWidget"
    />

    <!-- 聊天區 -->
    <div
      ref="chatAreaRef"
      class="chat-area scrollbar-custom"
      role="log"
      aria-live="polite"
      aria-label="對話紀錄"
    >
      <ChatStickyNotice v-model="isStickyOpen" />
      <div
        v-if="chatData.length === 0 && !isResponding"
        class="empty-state"
      >
        <div
          class="empty-icon"
          aria-hidden="true"
        >
          <svg viewBox="0 0 16 16">
            <path d="M5 8a1 1 0 1 1-2 0 1 1 0 0 1 2 0m4 0a1 1 0 1 1-2 0 1 1 0 0 1 2 0m3 1a1 1 0 1 0 0-2 1 1 0 0 0 0 2" />
          </svg>
        </div>
        <p class="empty-text">
          您好！請輸入想查詢的城市議題，我會協助推薦相關組件與說明。
        </p>
      </div>
      <div
        v-for="chat in chatData"
        :key="chat.id"
        class="message"
      >
        <!-- 機器人訊息 -->
        <div
          v-if="chat.role === 'bot'"
          class="bot"
        >
          <div class="content">
            <div
              v-if="chat.content"
              class="message--plain message--markdown"
              v-html="renderContent(chat.content)"
            >
            </div>
            <ChatResultComponents
              v-if="chat.components && chat.components.length > 0"
              :components="chat.components"
              @copy="copyToClipboard"
              @explore="handleExploreIndicator"
              @open-map="handleOpenMap"
            />
            <div
              v-if="chat.button"
              v-horizontal-wheel
              class="message--button scrollbar-x-hide"
            >
              <button
                v-for="btn in chat.button"
                :key="btn.id"
                @click="qaBtnHandler(btn.text, chat.relations)"
              >
                {{ btn.text }}
              </button>
            </div>
          </div>
        </div>
        <!-- 使用者訊息 -->
        <div
          v-else
          class="user"
        >
          <div
            v-if="chat.content"
            class="content"
          >
            <div class="message--bubble">
              <p>{{ chat.content }}</p>
            </div>
          </div>
        </div>
      </div>
      <div
        v-if="isResponding"
        class="responding-state"
      >
        <div class="avatar">
          <BotLogo />
        </div>
        <div
          class="typing-dots"
          aria-label="小幫手回應中"
        >
          <span class="typing-dot" />
          <span class="typing-dot" />
          <span class="typing-dot" />
        </div>
      </div>
    </div>

    <SuggestedTagsBar
      v-if="!isResponding && suggestedTags.length > 0"
      :tags="suggestedTags"
      :refresh-key="tagsRefreshKey"
      @select="clickTag"
    />
    <ChatComposer
      v-model="userMessage"
      :is-responding="isResponding"
      @send="sendBtnHandler"
    />
  </div>
</template>

<style lang="scss" scoped>
/* === 色彩系統（對齊 AIChatHub Widget） === */
$bg-dark: #18191d;
$card-bg: #252a2f;
$border-color: #353a41;
$border-hover: rgba(255, 255, 255, 0.2);
$white: #ffffff;
$text-primary: #f4f4f5;
$text-secondary: #d0d0d8;
$text-muted: #a1a1aa;
$scroll-thumb-hover: #505560;

/* === 圓角系統 === */
$radius-8: 8px;
$radius-10: 10px;

/* === 動畫標準 === */
$transition-fast: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

/* === 尺寸標準 === */

/* === Scrollbar === */
.scrollbar-x-hide {
	scrollbar-width: none;

	&::-webkit-scrollbar {
		display: none;
	}
}

.scrollbar-custom {
	&::-webkit-scrollbar {
		width: 2px;
		background: transparent;
	}

	&::-webkit-scrollbar-thumb {
		background: $white;
		border-radius: 8px;
	}

	&::-webkit-scrollbar-thumb:hover {
		background: $scroll-thumb-hover;
	}
}

/* === 主要樣式 === */
.chat-widget {
	width: 420px;
	max-width: 100%;
	height: 100%;
	border-radius: 16px;
	overflow: hidden;
	position: relative;
	background: $bg-dark;
	border: 1px solid $border-color;
	display: flex;
	flex-direction: column;
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif;
	color: #18181b;
	box-shadow: 0 20px 60px rgba(0, 0, 0, 0.16);

	&, * {
		box-sizing: border-box;
	}

	:where(div, p, span, button, table, thead, tbody, tr, th, td, svg, path) {
		overflow: visible;
	}

	.chat-area {
		flex: 1;
		min-height: 0;
		padding: 0 0 8.75rem;
		overflow-y: auto;
		overflow-x: hidden;
		background: $bg-dark;
		color: $white;

		.empty-state {
			display: flex;
			flex-direction: column;
			align-items: center;
			justify-content: center;
			text-align: center;
			padding: 1.5rem 1.25rem;
			margin: 0 1rem;
			min-height: 180px;
			animation: fadeIn 0.3s ease-out;
		}

		.empty-icon {
			width: 48px;
			height: 48px;
			color: #909099;
			margin-bottom: 1rem;
			animation: scaleIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);

			svg {
				width: 100%;
				height: 100%;
				fill: currentColor;
			}
		}

		.empty-text {
			font-size: 14px;
			line-height: 1.5;
			color: $text-muted;
			margin: 0;
		}

		.message {
			padding: 0.75rem 1rem;
			animation: slideIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
			margin-bottom: 0.25rem;
			transition: $transition-fast;

			.bot,
			.user {
				display: flex;
				gap: 0.25rem;
				align-items: flex-start;
				width: 100%;

				&.user {
					justify-content: flex-end;
				}

				.content {
					display: flex;
					flex-direction: column;
					gap: 0.5rem;
					max-width: 100%;
					flex: 1;
					width: 100%;
					min-width: 0;

					.message--plain {
						width: 100%;
						&.message--markdown {
							display: block;
							width: 100%;
							:deep(p) { margin: 0 0 0.5rem 0; width: 100%; }
							:deep(.ai-table-wrapper) {
								margin: 12px 0;
								inline-size: 100% !important;
								max-inline-size: 100% !important;
								width: 100% !important;
								display: block;
								overflow-x: auto;
								border-radius: 8px;
								border: 1px solid rgba(255,255,255,0.1);
								background: rgba(255,255,255,0.03);
								box-sizing: border-box;
							}
							:deep(.ai-table) {
								display: table;
								width: 100% !important;
								min-width: 100% !important;
								max-width: 100%;
								border-collapse: collapse;
								border: 1px solid rgba(255,255,255,0.28);
								font-size: 13px;
								text-align: left;
								table-layout: fixed;
								box-sizing: border-box;
								th, td {
									padding: 10px 12px;
									border: 1px solid rgba(255,255,255,0.22);
									word-break: break-word;
									text-align: left;
								}
								th:nth-child(1), td:nth-child(1) {
									width: 56px;
									white-space: nowrap;
									text-align: left;
								} /* 排名欄最小寬 */
								th:nth-child(2), td:nth-child(2) {
									width: 84px;
									white-space: nowrap;
								} /* 城市欄維持緊湊 */
								th:last-child, td:last-child { width: calc(100% - 140px); } /* 主要內容欄吃滿剩餘寬度 */
								th {
									background: rgba(255,255,255,0.09);
									font-weight: 600;
									color: $white;
								}
								tr:nth-child(even) td { background: rgba(255,255,255,0.03); }
							}
						}
						p {
							color: $text-secondary;
							white-space: pre-line;
							margin: 0;
							padding: 0;
							font-size: 14px;
							line-height: 1.7;
						}
					}

					.message--bubble {
						display: inline-block;
						max-width: 100%;
						border: none;
						border-radius: 1rem;
						background: #6b7280;
						box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);

						p {
							color: $white;
							white-space: pre-line;
							margin: 0;
							padding: 0.75rem 1rem;
							font-size: 14px;
							line-height: 1.55;
						}
					}

					.message--button {
						display: flex;
						gap: 0.5rem;
						overflow-x: auto;

						button {
							padding: 0.5rem 0.875rem;
							border-radius: $radius-10;
							border: 1px solid $border-color;
							background: $card-bg;
							color: $text-primary;
							font-size: 13px;
							font-weight: 500;
							white-space: nowrap;
							cursor: pointer;
							transition: $transition-fast;

							&:hover {
								background: rgba($white, 0.08);
								border-color: $border-hover;
								filter: brightness(1.12);
								transform: scale(1.02);
							}

							&:active {
								transform: scale(0.98);
							}
						}
					}
				}
			}

			.user {
				.content {
					max-width: 32rem;
					width: auto;
					flex: 0 1 auto;
					align-items: flex-end;
				}
			}
		}

		.responding-state {
			display: flex;
			align-items: center;
			gap: 0.5rem;
			padding: 0.75rem 1rem;
			font-size: 13px;
			color: #909099;
			opacity: 0.85;

			.avatar {
				width: 28px;
				height: 28px;
				display: flex;
				align-items: center;
				justify-content: center;
				flex-shrink: 0;

				svg {
					width: 100%;
					height: auto;
				}
			}

			.typing-dots {
				display: flex;
				align-items: center;
				gap: 6px;
				padding: 8px 0;
			}

			.typing-dot {
				width: 8px;
				height: 8px;
				border-radius: 50%;
				background: #7a7a88;
				animation: chat-typing-bounce 1.4s infinite ease-in-out;
			}

			.typing-dot:nth-child(1) {
				animation-delay: 0s;
			}

			.typing-dot:nth-child(2) {
				animation-delay: 0.2s;
			}

			.typing-dot:nth-child(3) {
				animation-delay: 0.4s;
			}
		}
	}

}

@media (max-width: 768px) {
  .chat-widget {
    border-radius: 12px;

		.chat-area {
			padding-bottom: 9.75rem;
		}
  }
}

@keyframes chat-msg-in {
	from {
		opacity: 0;
		transform: translateY(10px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
	}
}

@keyframes fadeIn {
	from {
		opacity: 0;
	}
	to {
		opacity: 1;
	}
}

@keyframes scaleIn {
	from {
		opacity: 0;
		transform: scale(0.8);
	}
	to {
		opacity: 1;
		transform: scale(1);
	}
}

@keyframes chat-typing-bounce {
	0%,
	60%,
	100% {
		transform: translateY(0);
		opacity: 0.7;
	}
	30% {
		transform: translateY(-10px);
		opacity: 1;
	}
}

</style>
