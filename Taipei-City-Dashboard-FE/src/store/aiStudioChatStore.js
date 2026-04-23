/**
 * AI Studio Chat Store
 * 獨立的聊天狀態管理，與右下角 ChatBot 分開
 * - 獨立的聊天記錄（sessionStorage key: aiStudioChatData）
 * - 獨立的會話邏輯
 * - 引用共用的 aiChatService
 */

import { ref, watch } from 'vue'
import { defineStore } from 'pinia'
import http from "../router/axios";
import {
	queryByTwai,
	queryByVector,
	componentsFromAgentResult,
	ensureDashboardConfigs,
	selectFocusedComponents,
	fetchDashboardComponentsByVector,
	buildComponentNarrative,
	resolveSceneFromAI,
	saveChatLog as aiChatServiceSaveChatLog,
	isDirectComponentIntent,
} from "../services/aiChatService";

const USE_TWAI_CHAT = (import.meta.env.VITE_USE_TWAI_CHAT ?? "true") !== "false";

export const useAiStudioChatStore = defineStore('aiStudioChat', () => {
	// ═══════════════════════════════════════════════════════════════════
	// 預設訊息 - AI Studio 專用
	// ═══════════════════════════════════════════════════════════════════
	const defaultChatData = [
		{
			id: 1,
			role: 'bot',
			isDefault: true,
			content:
				'您好，我是【AI Studio 助手】，很高興為您服務！\n 我可以幫助您：\n\n • 深入分析城市議題與數據\n • 推薦相關儀表板組件\n • 生成自訂場景展示\n\n 📩 有任何問題，隨時告訴我吧！\n',
		},
	];

	const recommendComponents = ref(null);
	const isResponding = ref(false);

	// ═══════════════════════════════════════════════════════════════════
	// 聊天記錄管理 - 獨立的 sessionStorage key
	// ═══════════════════════════════════════════════════════════════════
	const savedChatData = JSON.parse(sessionStorage.getItem('aiStudioChatData')) || [];

	// 拼接預設訊息 + sessionStorage 的聊天紀錄
	const chatData = ref([...defaultChatData, ...savedChatData]);

	// 監聽 chatData 的變化，自動同步到 sessionStorage
	watch(
		chatData,
		(newVal) => {
			// 只存使用者與機器人的聊天訊息，不存重複的預設訊息
			const userBotMessages = newVal.filter((item) => !item.isDefault);
			sessionStorage.setItem('aiStudioChatData', JSON.stringify(userBotMessages));
		},
		{ deep: true }
	);

	// ═══════════════════════════════════════════════════════════════════
	// 核心聊天方法
	// ═══════════════════════════════════════════════════════════════════

	const addChatData = (newChatData) => {
		chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });
	};

	const addQueryData = async (newChatData) => {
		if (isResponding.value) return;
		isResponding.value = true;

		chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });

		try {
			if (USE_TWAI_CHAT) {
				const twaiResult = await queryByTwai(newChatData.content, chatData.value);
				if (twaiResult?.ok) {
					let components = componentsFromAgentResult(twaiResult.agentResult);
					if (components.length > 0) {
						components = await ensureDashboardConfigs(components);
					}
					const shouldRetrieveComponents =
						(Array.isArray(twaiResult.tools) && twaiResult.tools.includes('retrieve_components_by_query')) ||
						isDirectComponentIntent(newChatData.content);
					if (shouldRetrieveComponents && components.length === 0) {
						try {
							components = await fetchDashboardComponentsByVector(newChatData.content, 5, 0.78);
							components = selectFocusedComponents(components, newChatData.content);
						} catch (err) {
							console.warn('Component detail fetch failed:', err);
						}
					} else if (components.length > 0) {
						components = selectFocusedComponents(components, newChatData.content);
					}

					const finalContent = buildComponentNarrative(
						newChatData.content,
						components,
						twaiResult.content,
					);

					chatData.value.push({
						id: chatData.value.length + 1,
						role: 'bot',
						isDefault: false,
						content: finalContent,
						answerMode: twaiResult.answerMode,
						selectionReason: twaiResult.agentResult?.selection_reason,
						usedTools: twaiResult.tools,
						scene: resolveSceneFromAI(
							newChatData.content,
							twaiResult.content,
							components,
							components.length > 0 ? 'components' : 'web',
						),
						components: components.length > 0 ? components : undefined,
					});
					saveChatLog(newChatData.content, finalContent, {
						answerMode: twaiResult.answerMode,
						usedTools: twaiResult.tools,
					});
					return;
				}

				chatData.value.push({
					id: chatData.value.length + 1,
					role: 'bot',
					isDefault: false,
					content: 'AI 對話服務暫時忙碌，已自動切換為組件推薦模式。',
				});
			}

			await queryByVectorFallback(newChatData.content);
		} finally {
			isResponding.value = false;
		}
	};

	// ═══════════════════════════════════════════════════════════════════
	// 向量檢索 Fallback 邏輯
	// ═══════════════════════════════════════════════════════════════════

	const queryByVectorFallback = async (question) => {
		recommendComponents.value = [];
		let topK = null;

		try {
			const response = await http.post(
				"/vector/component",
				new URLSearchParams({
					query: question,
					limit: 10,
					score: 0.8,
				}),
				{
					headers: {
						"Content-Type": "application/x-www-form-urlencoded",
					},
				}
			);
			if (response.data?.data?.length > 0) {
				const { isOfficialComponent } = await import("../constants/nonOfficialComponentIndexes");
				recommendComponents.value = response.data.data.filter(isOfficialComponent);
			}

			// 去除重複項目存到 result
			const result = Array.from(
				recommendComponents.value.reduce((map, item) => {
					const key = item.index;
					const exist = map.get(key);

					// 如果還沒放過，直接放
					if (!exist) {
						map.set(key, item);
						return map;
					}

					// 如果已存在，但現在的是 metrotaipei，就覆蓋
					if (item.city === 'metrotaipei') {
						map.set(key, item);
					}

					return map;
				}, new Map()).values()
			);
			// 把 result 蓋回去 recommendComponents
			recommendComponents.value = result;

		} catch (error) {
			console.error("VectorAnalysisError :", error);
		}

		if (recommendComponents.value && recommendComponents.value?.length > 0) {
			topK = [...recommendComponents.value].sort((a, b) => b.score - a.score);
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				button: [{ id: 1, text: '建立儀表板' }],
				content: `您好 😊 \n 以下是根據您的問題，自動為您推薦的「組件清單」。您可以將這些組件整批加入「個人儀表板」，方便日後快速查看與使用。\n`,
				relations: topK,
				scene: resolveSceneFromAI(question, '', topK, 'components'),
			});
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				content: `若您有任何新的查詢或想深入探索的內容，都可以隨時在對話框告訴我～\n 我很樂意再協助您 💬✨`,
			});
		} else {
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				content: `很抱歉，您提供的描述沒有相似組件，請繼續提問 ! `,
				scene: resolveSceneFromAI(question, '', [], 'web'),
			});
		}

		// 分析結束後紀錄問答log
		saveChatLog(question, recommendComponents.value, {
			answerMode: 'vector_fallback',
			usedTools: ['vector_component_search'],
		});
	};

	// ═══════════════════════════════════════════════════════════════════
	// 日誌記錄 & 清除歷史
	// ═══════════════════════════════════════════════════════════════════

	const saveChatLog = async (question, answer, meta = {}) => {
		await aiChatServiceSaveChatLog(question, answer, meta);
	};

	const clearChatHistory = () => {
		chatData.value = [...defaultChatData];
		sessionStorage.removeItem('aiStudioChatData');
		isResponding.value = false;
	};

	return {
		chatData,
		isResponding,
		addChatData,
		addQueryData,
		saveChatLog,
		clearChatHistory,
	};
});
