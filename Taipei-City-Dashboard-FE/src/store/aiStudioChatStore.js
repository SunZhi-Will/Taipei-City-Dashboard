import { ref, watch } from 'vue';
import { defineStore } from 'pinia';
import {
	queryByTwai,
	queryByVector,
	componentsFromAgentResult,
	ensureDashboardConfigs,
	hydrateDashboardComponents,
	fetchDashboardComponentsByVector,
	buildComponentNarrative,
	resolveSceneFromAI,
	resolveSceneFromDisplayPlan,
	saveChatLog as aiChatServiceSaveChatLog,
	isDirectComponentIntent,
	buildTwaiFallbackNotice,
	selectFocusedComponents,
} from '../services/aiChatService';
import { useAIStudioStore } from './aiStudioStore';

const USE_TWAI_CHAT = (import.meta.env.VITE_USE_TWAI_CHAT ?? 'true') !== 'false';

export const useAiStudioChatStore = defineStore('aiStudioChat', () => {
	const aiStudioStore = useAIStudioStore();
	const defaultChatData = [
		{
			id: 1,
			role: 'bot',
			isDefault: true,
			content:
				'您好，我是【AI Studio 助手】，很高興為您服務！\n 我可以幫助您：\n\n • 深入分析城市議題與數據\n • 推薦相關儀表板組件\n • 生成自訂場景展示\n\n 📩 有任何問題，隨時告訴我吧！\n',
		},
	];

	const recommendComponents = ref([]);
	const isResponding = ref(false);
	const savedChatData = JSON.parse(sessionStorage.getItem('aiStudioChatData')) || [];
	const chatData = ref([...defaultChatData, ...savedChatData]);

	watch(
		chatData,
		(newVal) => {
			sessionStorage.setItem(
				'aiStudioChatData',
				JSON.stringify(newVal.filter((item) => !item.isDefault)),
			);
		},
		{ deep: true },
	);

	const addChatData = (newChatData) => {
		chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });
	};

	const queryByVectorFallback = async (question) => {
		recommendComponents.value = await queryByVector(question);
		const topK = [...recommendComponents.value].sort((a, b) => b.score - a.score);

		if (topK.length > 0) {
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				button: [{ id: 1, text: '建立儀表板' }],
				content: '您好 😊 \n 以下是根據您的問題，自動為您推薦的「組件清單」。您可以將這些組件整批加入「個人儀表板」，方便日後快速查看與使用。\n',
				relations: topK,
				scene: resolveSceneFromAI(question, '', topK, 'presentation'),
			});
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				content: '若您有任何新的查詢或想深入探索的內容，都可以隨時在對話框告訴我～\n 我很樂意再協助您 💬✨',
			});
		} else {
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				content: '很抱歉，您提供的描述沒有相似組件，請繼續提問 ! ',
				scene: resolveSceneFromAI(question, '', [], 'web'),
			});
		}

		saveChatLog(question, recommendComponents.value, {
			answerMode: 'vector_fallback',
			usedTools: ['vector_component_search'],
		});
	};

	const addQueryData = async (newChatData) => {
		if (isResponding.value) return;
		isResponding.value = true;
		chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });

		try {
			if (USE_TWAI_CHAT) {
				const twaiResult = await queryByTwai(newChatData.content, chatData.value, {
					appMode: 'ai_studio',
					// Pass current scene so the AI knows what's already on screen
					// and can intelligently modify/extend it on follow-up queries.
					sceneContext: aiStudioStore.scene,
				});
				if (twaiResult?.ok) {
					let components = componentsFromAgentResult(twaiResult.agentResult);
					if (components.length > 0) {
						components = await ensureDashboardConfigs(components);
					}

					// Supplement with ALL components from the vector search tool result.
					// agentResult caps at primary + 3 related; display_plan may reference more.
					const vectorEntry = Array.isArray(twaiResult.toolTimeline)
						? [...twaiResult.toolTimeline].reverse().find(t => t.name === 'retrieve_components_by_query')
						: null;
					if (vectorEntry?.result) {
						try {
							const parsed = JSON.parse(vectorEntry.result);
							if (Array.isArray(parsed?.results) && parsed.results.length > 0) {
								const existingIds = new Set(components.map(c => String(c.id)));
								const missing = parsed.results.filter(r => r.id && !existingIds.has(String(r.id)));
								if (missing.length > 0) {
									const extra = await hydrateDashboardComponents(missing);
									components = [...components, ...extra.filter(c => c.id)];
								}
							}
						} catch { /* silent */ }
					}

					const shouldRetrieveComponents =
						(Array.isArray(twaiResult.tools) && twaiResult.tools.includes('retrieve_components_by_query')) ||
						isDirectComponentIntent(newChatData.content);

					if (shouldRetrieveComponents && components.length === 0) {
						components = await fetchDashboardComponentsByVector(newChatData.content, 5, 0.78);
					}

					// Preserve full component list for display_plan rendering — no score-based filtering.
					// Mark first as primary for ChatResultComponents display.
					components = components.map((item, idx) => ({ ...item, isPrimary: idx === 0 }));

					// Use AI's director narrative directly.
					// buildComponentNarrative is for the general chat widget; AI Studio AI
					// already produces a proper structured narrative.
					const finalContent = twaiResult.content || '';
					const plannedScene = resolveSceneFromDisplayPlan(
						newChatData.content,
						twaiResult.displayPlan,
						components,
					);

					chatData.value.push({
						id: chatData.value.length + 1,
						role: 'bot',
						isDefault: false,
						content: finalContent,
						answerMode: twaiResult.answerMode,
						selectionReason: twaiResult.agentResult?.selection_reason,
						usedTools: twaiResult.tools,
						toolTimeline: twaiResult.toolTimeline,
						displayPlan: twaiResult.displayPlan || undefined,
						meta: twaiResult.meta,
						scene:
							plannedScene ||
							resolveSceneFromAI(
								newChatData.content,
								twaiResult.content,
								selectFocusedComponents(components, newChatData.content),
								components.length > 0 ? 'presentation' : 'web',
							),
						components: components.length > 0 ? components : undefined,
						suggestedTags: twaiResult.suggestedTags,
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
					content: buildTwaiFallbackNotice(twaiResult?.reason),
				});
			}

			await queryByVectorFallback(newChatData.content);
		} finally {
			isResponding.value = false;
		}
	};

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
