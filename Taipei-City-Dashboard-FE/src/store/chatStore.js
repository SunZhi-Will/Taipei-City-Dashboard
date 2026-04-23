import { ref, watch } from 'vue'
import { defineStore } from 'pinia'
import http from "../router/axios";
import { isOfficialComponent } from "../constants/nonOfficialComponentIndexes";
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
} from "../services/aiChatService";


const USE_TWAI_CHAT = (import.meta.env.VITE_USE_TWAI_CHAT ?? "true") !== "false";
export const useChatStore = defineStore('chat', () => {
  	// 預設訊息
  	const defaultChatData = [
    	{
      		id: 1,
      		role: 'bot',
	  		isDefault: true,
      		content:
		        '您好，我是【臺北城市儀表板】小幫手，很高興為您服務！\n 您可以： \n\n • 直接提問城市數據問題（AI 對話）\n • 輸入主題描述，我會推薦相關組件並可一鍵建立儀表板\n\n 若 AI 服務暫時忙碌，我會自動切換為組件推薦模式，確保不中斷。\n\n 📩 聯絡信箱：tuic@gov.taipei \n 🏢 臺北大數據中心 \n\n',
    	},
  	];

	const recommendComponents = ref(null)
	const isResponding = ref(false)

  	// 從 sessionStorage 讀取
  	const savedChatData = JSON.parse(sessionStorage.getItem('chatData')) || [];

  	// 拼接預設訊息 + sessionStorage 的聊天紀錄
  	const chatData = ref([...defaultChatData, ...savedChatData]);

  	// 監聽 chatData 的變化，自動同步到 sessionStorage
  	watch(
    	chatData,
    	(newVal) => {
      	// 只存使用者與機器人的聊天訊息，不存重複的預設訊息
      	const userBotMessages = newVal.filter((item) => !item.isDefault)
      	sessionStorage.setItem('chatData', JSON.stringify(userBotMessages))
    	},
    	{ deep: true }
  	);

	const pickConfigByCity = (configs, city) => {
		if (!Array.isArray(configs) || configs.length === 0) return null;
		return configs.find((item) => item?.city === city) || configs[0];
	};

	const normalizeText = (text = '') =>
		String(text)
			.toLowerCase()
			.replace(/[\s\u3000，,。.!！?？、;；:\-_/()（）[\]【】]/g, '');

	const isDirectComponentIntent = (query = '') => {
		const q = String(query || '');
		return /組件|元件|顯示|查看|打開|我要看|幫我找|扶養比及老化指數|長照指標/.test(q);
	};

	const computeComponentMatchScore = (component, query) => {
		const qNorm = normalizeText(query);
		const nameNorm = normalizeText(component?.name || '');
		const idxNorm = normalizeText(component?.index || '');
		let score = Number(component?.score || 0) * 10;

		if (!qNorm) return score;
		if (nameNorm && (nameNorm.includes(qNorm) || qNorm.includes(nameNorm))) score += 120;
		if (idxNorm && (idxNorm.includes(qNorm) || qNorm.includes(idxNorm))) score += 90;

		const terms = String(query)
			.split(/[\s,，、;；/]+/)
			.filter((t) => t && !['的', '及', '與', '跟', '請', '幫我', '我要', '資料', '數據'].includes(t));
		for (const term of terms) {
			const tNorm = normalizeText(term);
			if (!tNorm) continue;
			if (nameNorm.includes(tNorm)) score += 25;
			if (idxNorm.includes(tNorm)) score += 15;
		}

		return score;
	};

	const selectFocusedComponents = (components, query) => {
		const list = Array.isArray(components) ? components : [];
		if (list.length <= 1) {
			return list.map((item, idx) => ({ ...item, isPrimary: idx === 0 }));
		}

		const ranked = [...list]
			.map((item) => ({ ...item, __matchScore: computeComponentMatchScore(item, query) }))
			.sort((a, b) => b.__matchScore - a.__matchScore);

		const top = ranked[0];
		const second = ranked[1];
		const directIntent = isDirectComponentIntent(query);
		const dominant = !second || (top.__matchScore - second.__matchScore >= 25);
		const limit = directIntent ? 3 : 4;
		const selected = ranked.slice(0, limit);
		const normalized = selected.map((item, idx) => ({
			...item,
			isPrimary: idx === 0,
		}));

		if (directIntent && dominant) {
			return normalized;
		}

		return normalized;
	};

	const componentsFromAgentResult = (agentResult) => {
		if (!agentResult || !agentResult.primary_component) return [];

		const mapCandidate = (item, isPrimary = false) => ({
			id: item?.id,
			name: item?.name || '未知組件',
			index: item?.index,
			city: item?.city,
			score: item?.score,
			category: 'dashboard_component',
			description: '',
			props: {
				index: item?.index,
				score: item?.score,
			},
			usage_example: '',
			isPrimary,
		});

		const primary = mapCandidate(agentResult.primary_component, true);
		const related = Array.isArray(agentResult.related_components)
			? agentResult.related_components.map((item) => mapCandidate(item, false))
			: [];

		return [primary, ...related].filter((item) => item.id);
	};

	const fetchDashboardComponentsByVector = async (query, limit = 5, score = 0.78) => {
		const vectorResp = await http.post(
			'/vector/component',
			new URLSearchParams({
				query,
				limit,
				score,
			}),
			{ headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
		);

		const vectorResults = Array.isArray(vectorResp?.data?.data) ? vectorResp.data.data : [];
		return hydrateDashboardComponents(vectorResults);
	};

	const buildChartParams = (component) => ({
		city: component?.city,
		...(!['static', 'current', 'demo'].includes(component?.time_from)
			? getComponentDataTimeframe(component?.time_from, component?.time_to, true)
			: {}),
	});

	const fetchCompleteDashboardConfig = async (componentId, city) => {
		if (!componentId) return null;

		try {
			const detailResp = await http.get(`/component/${componentId}/all`);
			const candidates = Array.isArray(detailResp?.data?.data) ? detailResp.data.data : [];
			const dashboardConfig = pickConfigByCity(candidates, city);
			if (!dashboardConfig) return null;

			try {
				const chartResp = await http.get(`/component/${dashboardConfig.id}/chart`, {
					params: buildChartParams(dashboardConfig),
				});
				dashboardConfig.chart_data = chartResp?.data?.data ?? [];
				if (chartResp?.data?.categories) {
					dashboardConfig.chart_config.categories = chartResp.data.categories;
				}
			} catch (err) {
				console.warn('Load dashboard chart data failed:', dashboardConfig?.id, err);
				dashboardConfig.chart_data = [];
			}

			return dashboardConfig;
		} catch (err) {
			console.warn('Load dashboard config failed:', componentId, err);
			return null;
		}
	};

	const hydrateDashboardComponents = async (vectorResults = []) => {
		const normalized = Array.isArray(vectorResults) ? vectorResults : [];
		const enriched = await Promise.all(
			normalized.map(async (item, idx) => {
				const dashboardConfig = item?.id
					? await fetchCompleteDashboardConfig(item.id, item.city)
					: null;

				return {
					id: item.id || `vector-${item.index || idx}`,
					name: item.name || '未知組件',
					index: item.index,
					city: item.city,
					score: item.score,
					category: 'dashboard_component',
					description:
						dashboardConfig?.short_desc ||
						item.description ||
						`城市: ${item.city || 'N/A'}，相關性: ${item.score || 0}`,
					props: {
						index: item.index,
						score: item.score,
					},
					usage_example: '',
					dashboardConfig,
				};
			}),
		);

		return enriched;
	};

	const ensureDashboardConfigs = async (components = []) => {
		const list = Array.isArray(components) ? components : [];
		const enriched = await Promise.all(
			list.map(async (item, idx) => {
				if (item?.dashboardConfig) return item;

				const maybeDashboard = item?.category === 'dashboard_component' || Boolean(item?.id);
				if (!maybeDashboard) return item;

				const dashboardConfig = item?.id
					? await fetchCompleteDashboardConfig(item.id, item.city)
					: null;

				return {
					...item,
					id: item.id || `component-${item.index || idx}`,
					category: item.category || 'dashboard_component',
					dashboardConfig,
				};
			}),
		);

		return enriched;
	};

	const summarizeRelatedComponents = (components = []) => {
		const names = components
			.map((item) => item?.name)
			.filter(Boolean)
			.slice(0, 3);

		if (names.length === 0) return '';
		if (names.length === 1) return `若您要延伸比較，也可以一起看 ${names[0]}。`;
		if (names.length === 2) return `若您要延伸比較，也可以一起看 ${names[0]} 與 ${names[1]}。`;
		return `若您要延伸比較，也可以一起看 ${names.slice(0, -1).join('、')} 與 ${names[names.length - 1]}。`;
	};

	const extractSceneJson = (text = '') => {
		const rawText = String(text || '');
		const fencedBlocks = [...rawText.matchAll(/```(?:json)?\s*([\s\S]*?)```/gi)]
			.map((item) => item[1])
			.filter(Boolean);

		const candidates = [...fencedBlocks, rawText];
		for (const candidate of candidates) {
			const start = candidate.indexOf('{');
			const end = candidate.lastIndexOf('}');
			if (start === -1 || end === -1 || end <= start) continue;

			try {
				const parsed = JSON.parse(candidate.slice(start, end + 1));
				if (!parsed || typeof parsed !== 'object') continue;
				if (!parsed.layout || !parsed.rightPanelMode && !parsed.layout?.rightPanel) continue;
				return parsed;
			} catch {
				continue;
			}
		}

		return null;
	};

	const buildFallbackScene = (question = '', components = [], preferredMode = 'components') => {
		const safeComponents = Array.isArray(components) ? components : [];
		const rightMode = ['components', 'map', 'web'].includes(preferredMode)
			? preferredMode
			: 'components';

		return {
			version: '1.0',
			title: `AI 生成展示：${String(question || '').slice(0, 30) || '城市議題'}`,
			objective: '依需求快速組裝可展示儀表板',
			layout: {
				type: 'split',
				leftPanel: {
					collapsed: false,
					width: 380,
				},
				rightPanel: {
					mode: rightMode,
				},
			},
			blocks: safeComponents.map((item) => ({
				type: 'component',
				title: item?.name || '未命名組件',
				componentId: item?.id,
				componentIndex: item?.index,
				city: item?.city || item?.dashboardConfig?.city || 'taipei',
			})),
			meta: {
				city: safeComponents[0]?.city || safeComponents[0]?.dashboardConfig?.city || 'taipei',
				theme: 'default',
				updatedAt: new Date().toISOString(),
			},
		};
	};

	const resolveSceneFromAI = (question = '', aiRawContent = '', components = [], preferredMode = 'components') => {
		const extracted = extractSceneJson(aiRawContent);
		if (extracted) return extracted;
		return buildFallbackScene(question, components, preferredMode);
	};

	const buildComponentNarrative = (question, components = [], aiContent = '') => {
		const list = Array.isArray(components) ? components : [];
		if (list.length === 0) {
			return String(aiContent || '').trim();
		}

		const primary = list.find((item) => item?.isPrimary) || list[0];
		const related = list.filter((item) => item && item !== primary);
		const shortDesc = primary?.dashboardConfig?.short_desc || primary?.description || '';
		const normalizedAiContent = String(aiContent || '').trim();
		const genericAiReply = !normalizedAiContent || /主結果|相關候選|score|rag|tool|index|id|rephrase|rephrase your question|retrieve/i.test(normalizedAiContent);

		const intro = `我先幫您整理成最值得直接查看的圖表：${primary?.name || '相關指標'}。`;
		const summary = shortDesc ? `這個指標重點在於${shortDesc}。` : `這張圖表最能直接回應您剛剛提到的「${question}」。`;
		const relatedHint = summarizeRelatedComponents(related);

		if (genericAiReply) {
			return [intro, summary, relatedHint].filter(Boolean).join(' ');
		}

		return [normalizedAiContent, relatedHint].filter(Boolean).join(' ');
	};

  	const addChatData = (newChatData) => {
    	chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });
  	};

	const addQueryData = async (newChatData) => {
		if (isResponding.value) return;
		isResponding.value = true;

	    	chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });

		try {

			if (USE_TWAI_CHAT) {
				const twaiResult = await queryByTwai(newChatData.content);
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

			await queryByVector(newChatData.content);
		} finally {
			isResponding.value = false;
		}
	};

	const buildTwaiMessages = (latestUserInput, includeHistory = true) => {
		const systemPrompt =
			'你是臺北城市儀表板小幫手。回覆對象是一般使用者，不是工程師。若使用者在查某個指標、圖表、組件或想看資料，必須先呼叫 retrieve_components_by_query 再回答。取得檢索結果後，請自行整合成自然、完整、可直接理解的繁體中文答案，優先指出最值得先看的圖表與原因，必要時再補充 1 到 3 個延伸指標。不要暴露 RAG、tool、score、index、id、主結果、候選、檢索排序等中繼資訊。若沒有合適結果，直接用白話說明限制並提供下一步建議。';

		if (!includeHistory) {
			return [
				{
					role: 'system',
					content: systemPrompt,
				},
				{ role: 'user', content: latestUserInput },
			];
		}

		const recent = chatData.value
			.filter((item) => !item.isDefault && (item.role === 'user' || item.role === 'bot'))
			.slice(-MAX_CONTEXT_MESSAGES)
			.map((item) => ({
				role: item.role === 'user' ? 'user' : 'assistant',
				content: item.content || '',
			}))
			.filter((item) => item.content.trim().length > 0);

		if (!recent.length || recent[recent.length - 1].role !== 'user') {
			recent.push({ role: 'user', content: latestUserInput });
		}

		return [
			{
				role: 'system',
				content: systemPrompt,
			},
			...recent,
		];
	};

	const queryByTwai = async (question) => {
		const shouldRetry = (error) => {
			const status = error?.response?.status;
			if (!status) return true;
			return [408, 429, 500, 502, 503, 504].includes(status);
		};

		const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

		const createPayload = (includeHistory = true) => ({
			session: (() => {
				const d = new Date();
				return `session_${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
			})(),
			stream: false,
			messages: buildTwaiMessages(question, includeHistory),
			max_new_tokens: includeHistory ? 512 : 256,
			temperature: 0.35,
			tools: [
				{
					type: 'function',
					function: {
						name: 'retrieve_components_by_query',
						description: 'Retrieve relevant Taipei dashboard components by vector similarity search',
						parameters: {
							type: 'object',
							properties: {
								query: { type: 'string' },
								limit: { type: 'integer', minimum: 1, maximum: 10 },
								score: { type: 'number', minimum: 0, maximum: 1 },
							},
							required: ['query'],
						},
					},
				},
				{
					type: 'function',
					function: {
						name: 'get_current_time',
						description: 'Get current Taipei time',
						parameters: {
							type: 'object',
							properties: {},
						},
					},
				},
				{
					type: 'function',
					function: {
						name: 'get_population_summary',
						description: 'Get city population summary for specified year',
						parameters: {
							type: 'object',
							properties: {
								city: { type: 'string', enum: ['taipei', 'new_taipei'] },
								year: { type: 'integer' },
							},
							required: ['year'],
						},
					},
				},
			],
			tool_choice: 'auto',
		});

		try {
			const payload = createPayload(true);
			let response = null;
			let lastError = null;

			for (let attempt = 0; attempt <= TWAI_MAX_RETRY; attempt++) {
				try {
					response = await http.post('/ai/chat/twai', payload);
					break;
				} catch (error) {
					lastError = error;
					if (attempt >= TWAI_MAX_RETRY || !shouldRetry(error)) {
						throw error;
					}
					await wait(300 * (attempt + 1));
				}
			}

			if (!response?.data?.data) {
				if (lastError) throw lastError;
				return { ok: false, reason: 'EMPTY_RESPONSE' };
			}

			const {content} = response.data.data;
			const answerMode = response.data.data.answer_mode || 'agent_chat';
			const tools = Array.isArray(response.data.data.tools) ? response.data.data.tools : [];
			const agentResult = response.data.data.agent_result || null;

			if (!content || !String(content).trim()) {
				return { ok: false, reason: 'EMPTY_CONTENT' };
			}

			return {
				ok: true,
				content: String(content),
				answerMode,
				tools,
				agentResult,
			};
		} catch (error) {
			const status = error?.response?.status;
			const reason = status ? `HTTP_${status}` : 'NETWORK_OR_TIMEOUT';
			console.error('TwaiChatError:', reason, error);

			try {
				const minimalResp = await http.post('/ai/chat/twai', createPayload(false));
				const minimalContent = minimalResp?.data?.data?.content;
				const minimalAnswerMode = minimalResp?.data?.data?.answer_mode || 'agent_chat';
				const minimalTools = Array.isArray(minimalResp?.data?.data?.tools) ? minimalResp.data.data.tools : [];
				const minimalAgentResult = minimalResp?.data?.data?.agent_result || null;
				if (minimalContent && String(minimalContent).trim()) {
					return {
						ok: true,
						content: String(minimalContent),
						answerMode: minimalAnswerMode,
						tools: minimalTools,
						agentResult: minimalAgentResult,
					};
				}
			} catch (minimalError) {
				console.error('TwaiChatMinimalContextError:', minimalError);
			}

			return { ok: false, reason };
		}
	};

	const queryByVector = async (question) => {

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
				recommendComponents.value = response.data.data.filter(
					isOfficialComponent,
				);
			}

			// 去除重複項目存到 result
			const result = Array.from(
  				recommendComponents.value.reduce((map, item) => {
    				const key = item.index
    				const exist = map.get(key)

    				// 如果還沒放過，直接放
    				if (!exist) {
      					map.set(key, item)
      					return map
    				}

    				// 如果已存在，但現在的是 metrotaipei，就覆蓋
    				if (item.city === 'metrotaipei') {
      					map.set(key, item)
    				}

    				return map
  				}, new Map()).values()
			)
			// 把 result 蓋回去 recommendComponents
			recommendComponents.value = result

		} catch (error) { 
			console.error("VectorAnalysisError :", error);
		}

		if (recommendComponents.value && recommendComponents.value?.length > 0) {
			topK = [...recommendComponents.value].sort((a, b) => b.score - a.score);
			chatData.value.push({ id: chatData.value.length + 1, role: 'bot', isDefault: false, button: [{ id:1, text:'建立儀表板' }], content: `您好 😊 \n 以下是根據您的問題，自動為您推薦的「組件清單」。您可以將這些組件整批加入「個人儀表板」，方便日後快速查看與使用。\n`, relations: topK, scene: resolveSceneFromAI(question, '', topK, 'components') });
			chatData.value.push({ id: chatData.value.length + 1, role: 'bot', isDefault: false, content: `若您有任何新的查詢或想深入探索的內容，都可以隨時在對話框告訴我～\n 我很樂意再協助您 💬✨` });
		} else {
			chatData.value.push({ id: chatData.value.length + 1, role: 'bot', isDefault: false, content: `很抱歉，您提供的描述沒有相似組件，請繼續提問 ! `, scene: resolveSceneFromAI(question, '', [], 'web') });
		}

		// 分析結束後紀錄問答log
		saveChatLog(question, recommendComponents.value, {
			answerMode: 'vector_fallback',
			usedTools: ['vector_component_search'],
		});
  	};

	const saveChatLog = async (question, answer, meta = {}) => {
		try {
			const formData = new FormData();
			const d = new Date();
			const todayId =
				d.getFullYear() +
				String(d.getMonth() + 1).padStart(2, "0") +
				String(d.getDate()).padStart(2, "0");

			formData.append("session", "session_" + todayId);
			formData.append("question", question);
			formData.append("answer", JSON.stringify(answer));
			formData.append("answer_mode", meta.answerMode || "unknown");
			formData.append("used_tools", JSON.stringify(Array.isArray(meta.usedTools) ? meta.usedTools : []));

			await http.post("/chatlog/", formData, {
				headers: {
					"Content-Type": "multipart/form-data",
				},
			});
		} catch (error) {
			console.error("saveChatLog error:", error);
		}
	};

	const clearChatHistory = () => {
		chatData.value = [...defaultChatData];
		sessionStorage.removeItem('chatData');
		isResponding.value = false;
	};

	return { chatData, isResponding, addChatData, addQueryData, saveChatLog, clearChatHistory }
})
