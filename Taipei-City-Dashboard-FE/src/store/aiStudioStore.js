import { ref } from "vue";
import { defineStore } from "pinia";

const STORAGE_KEY = "ai_studio_templates_v1";

const buildDefaultScene = () => ({
	version: "1.0",
	title: "AI 形象儀表板",
	objective: "以需求導向展示城市資料",
	layout: {
		type: "split",
		leftPanel: {
			collapsed: false,
			width: 380,
		},
		rightPanel: {
			mode: "presentation",
		},
	},
	presentation: {
		style: "carousel",
		autoplay: {
			enabled: true,
			intervalMs: 10000,
		},
		audience: "public-screen",
		industry: "general",
		slides: [],
	},
	blocks: [],
	meta: {
		city: "taipei",
		theme: "default",
		updatedAt: new Date().toISOString(),
	},
});

const toArray = (value) => (Array.isArray(value) ? value : []);

const sanitizeScene = (scene) => {
	const fallback = buildDefaultScene();
	if (!scene || typeof scene !== "object") return fallback;

	return {
		version: typeof scene.version === "string" ? scene.version : fallback.version,
		title: typeof scene.title === "string" ? scene.title : fallback.title,
		objective:
			typeof scene.objective === "string" ? scene.objective : fallback.objective,
		layout: {
			type: "split",
			leftPanel: {
				collapsed: Boolean(scene?.layout?.leftPanel?.collapsed),
				width:
					typeof scene?.layout?.leftPanel?.width === "number"
						? scene.layout.leftPanel.width
						: fallback.layout.leftPanel.width,
			},
			rightPanel: {
				mode:
					typeof scene?.layout?.rightPanel?.mode === "string"
						? scene.layout.rightPanel.mode
						: fallback.layout.rightPanel.mode,
			},
		},
		presentation: {
			style:
				typeof scene?.presentation?.style === "string"
					? scene.presentation.style
					: fallback.presentation.style,
			autoplay: {
				enabled:
					typeof scene?.presentation?.autoplay?.enabled === "boolean"
						? scene.presentation.autoplay.enabled
						: fallback.presentation.autoplay.enabled,
				intervalMs:
					typeof scene?.presentation?.autoplay?.intervalMs === "number"
						? scene.presentation.autoplay.intervalMs
						: fallback.presentation.autoplay.intervalMs,
			},
			audience:
				typeof scene?.presentation?.audience === "string"
					? scene.presentation.audience
					: fallback.presentation.audience,
			industry:
				typeof scene?.presentation?.industry === "string"
					? scene.presentation.industry
					: fallback.presentation.industry,
			slides: toArray(scene?.presentation?.slides).map((slide, index) => ({
				id: slide?.id || `slide-${index + 1}`,
				type: slide?.type || "component",
				title: slide?.title || "未命名投影片",
				subtitle: slide?.subtitle || "",
				focusComponentId: slide?.focusComponentId,
				durationSec:
					typeof slide?.durationSec === "number" ? slide.durationSec : 10,
			})),
		},
		blocks: toArray(scene.blocks).map((block) => ({
			type: block?.type || "component",
			title: block?.title || "未命名區塊",
			componentId: block?.componentId,
			componentIndex: block?.componentIndex,
			city: block?.city || "taipei",
			mapLayer: block?.mapLayer,
			url: block?.url,
		})),
		meta: {
			city: scene?.meta?.city || fallback.meta.city,
			theme: scene?.meta?.theme || fallback.meta.theme,
			updatedAt: new Date().toISOString(),
		},
	};
};

const loadTemplates = () => {
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		if (!raw) return [];
		const parsed = JSON.parse(raw);
		return Array.isArray(parsed) ? parsed : [];
	} catch (error) {
		console.error("讀取 AI Studio 模板失敗:", error);
		return [];
	}
};

const persistTemplates = (templates) => {
	localStorage.setItem(STORAGE_KEY, JSON.stringify(templates));
};

export const useAIStudioStore = defineStore("aiStudio", () => {
	const scene = ref(buildDefaultScene());
	const templates = ref(loadTemplates());

	const setScene = (nextScene) => {
		scene.value = sanitizeScene(nextScene);
	};

	const setRightMode = (mode) => {
		if (!["components", "map", "web", "presentation"].includes(mode)) return;
		scene.value.layout.rightPanel.mode = mode;
		scene.value.presentation.autoplay.enabled = mode === "presentation";
		scene.value.meta.updatedAt = new Date().toISOString();
	};

	const toggleLeftPanel = () => {
		scene.value.layout.leftPanel.collapsed = !scene.value.layout.leftPanel.collapsed;
		scene.value.meta.updatedAt = new Date().toISOString();
	};

	const saveTemplate = (name) => {
		const safeName = String(name || "未命名模板").trim() || "未命名模板";
		const template = {
			id: `tpl-${Date.now()}`,
			name: safeName,
			scene: scene.value,
			createdAt: new Date().toISOString(),
		};
		templates.value = [template, ...templates.value].slice(0, 30);
		persistTemplates(templates.value);
	};

	const applyTemplate = (id) => {
		const template = templates.value.find((item) => item.id === id);
		if (!template?.scene) return;
		setScene(template.scene);
	};

	const removeTemplate = (id) => {
		templates.value = templates.value.filter((item) => item.id !== id);
		persistTemplates(templates.value);
	};

	const ingestChatResult = (chatItem) => {
		if (!chatItem) return;
		if (chatItem.scene && typeof chatItem.scene === "object") {
			setScene(chatItem.scene);
		}
	};

	return {
		scene,
		templates,
		setScene,
		setRightMode,
		toggleLeftPanel,
		saveTemplate,
		applyTemplate,
		removeTemplate,
		ingestChatResult,
	};
});
