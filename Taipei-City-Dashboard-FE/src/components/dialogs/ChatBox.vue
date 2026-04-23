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
const DEFAULT_TAGS = [
	"空氣品質", "交通壅塞", "捷運人流", "垃圾清運", "醫療資源", "老年人口",
];

const suggestedTags = ref([...DEFAULT_TAGS]);

// 點擊 tag 直接送出
const clickTag = async (tag) => {
	if (isResponding.value) return;
	await addQueryData({ role: "user", content: tag });
};

// bot 回覆後，根據內容動態更新相關 tags
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
	await addQueryData({
		role: "user",
		content: normalizedText,
	});
	userMessage.value = "";
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
              class="message--plain"
            >
              <p>{{ chat.content }}</p>
            </div>
            <ChatResultComponents
              v-if="chat.components && chat.components.length > 0"
              :components="chat.components"
              @copy="copyToClipboard"
              @explore="handleExploreIndicator"
              @open-map="handleOpenMap"
            />

            <!-- 儀表板卡片區 -->
            <div
              v-if="chat.relations && chat.relations.length > 0"
              class="dashboard-cards-area"
            >
              <div
                v-for="(item, index) in chat.relations"
                :key="index"
                class="dashboard-card"
              >
                <div class="card-content">
                  <h4 class="card-title">
                    {{ item.name }}
                  </h4>
                  <div class="card-meta">
                    <span class="card-city">
                      {{ item.city === "taipei" ? "🏙️ 臺北" : "🌆 雙北" }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
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

					.dashboard-cards-area {
						display: grid;
						grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
						gap: 12px;
						margin-top: 12px;
						margin-bottom: 12px;

						.dashboard-card {
							position: relative;
							background: linear-gradient(135deg, #1f2a33 0%, #252a2f 100%);
							border: 1px solid $border-color;
							border-radius: $radius-10;
							padding: 12px;
							cursor: pointer;
							transition: $transition-fast;
							overflow: hidden;

							&::before {
								content: '';
								position: absolute;
								top: 0;
								left: 0;
								right: 0;
								height: 3px;
								background: linear-gradient(90deg, #00b4d8, #00d4ff);
								opacity: 0;
								transition: opacity 0.3s ease;
							}

							&:hover {
								border-color: $border-hover;
								transform: translateY(-2px);
								box-shadow: 0 4px 12px rgba(0, 180, 216, 0.15);

								&::before {
									opacity: 1;
								}

								.card-title {
									color: #00d4ff;
								}
							}

							.card-rank {
									display: none;
							}

							.card-title {
								margin: 0;
								font-size: 14px;
								font-weight: 600;
								color: $text-primary;
								transition: color 0.2s;
								word-break: break-word;
								max-height: 2.8em;
								overflow: hidden;
								text-overflow: ellipsis;
								display: -webkit-box;
								line-clamp: 2;
								-webkit-line-clamp: 2;
								-webkit-box-orient: vertical;
							}

							.card-meta {
								display: flex;
								gap: 8px;
								margin-top: 8px;
								flex-wrap: wrap;
								font-size: 12px;

								.card-city {
									background: rgba(0, 180, 216, 0.1);
									color: #00d4ff;
									padding: 2px 6px;
									border-radius: 3px;
									border: 1px solid rgba(0, 180, 216, 0.2);
									white-space: nowrap;
								}
							}
						}
					}

					.message--plain {
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
						border: none;
						border-radius: 1rem;
						background: #2a3f52;
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
