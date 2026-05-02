<script setup>
import { nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";

const props = defineProps({
	tags: {
		type: Array,
		default: () => [],
	},
	refreshKey: {
		type: Number,
		default: 0,
	},
});

const emit = defineEmits(["select"]);

const tagsScrollRef = ref(null);
const showScrollLeft = ref(false);
const showScrollRight = ref(false);

const updateTagScrollButtons = () => {
	const el = tagsScrollRef.value;
	if (!el) return;
	showScrollLeft.value = el.scrollLeft > 10;
	showScrollRight.value = el.scrollLeft < el.scrollWidth - el.clientWidth - 10;
};

const scrollTagsLeft = () => tagsScrollRef.value?.scrollBy({ left: -200, behavior: "smooth" });
const scrollTagsRight = () => tagsScrollRef.value?.scrollBy({ left: 200, behavior: "smooth" });

const refreshButtons = () => {
	nextTick(() => updateTagScrollButtons());
	setTimeout(() => updateTagScrollButtons(), 320);
};

onMounted(() => {
	refreshButtons();
	window.addEventListener("resize", refreshButtons);
});

onBeforeUnmount(() => {
	window.removeEventListener("resize", refreshButtons);
});

watch(
	() => props.tags,
	() => {
		refreshButtons();
	},
	{ deep: true },
);

watch(
	() => props.refreshKey,
	() => {
		refreshButtons();
	},
);
</script>

<template>
  <div
    class="tags-area"
    role="list"
    aria-label="建議查詢主題"
  >
    <button
      class="tag-scroll-btn tag-scroll-left"
      type="button"
      aria-hidden="true"
      :style="{ opacity: showScrollLeft ? '1' : '0', pointerEvents: showScrollLeft ? 'auto' : 'none' }"
      @click="scrollTagsLeft"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="14"
        height="14"
        fill="currentColor"
        viewBox="0 0 16 16"
      >
        <path
          fill-rule="evenodd"
          d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"
        />
      </svg>
    </button>
    <div
      ref="tagsScrollRef"
      class="tags-scroll scrollbar-x-hide"
      @scroll="updateTagScrollButtons"
    >
      <button
        v-for="tag in tags"
        :key="tag"
        class="tag-chip"
        type="button"
        role="listitem"
        @click="emit('select', tag)"
      >
        {{ tag }}
      </button>
    </div>
    <button
      class="tag-scroll-btn tag-scroll-right"
      type="button"
      aria-hidden="true"
      :style="{ opacity: showScrollRight ? '1' : '0', pointerEvents: showScrollRight ? 'auto' : 'none' }"
      @click="scrollTagsRight"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="14"
        height="14"
        fill="currentColor"
        viewBox="0 0 16 16"
      >
        <path
          fill-rule="evenodd"
          d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"
        />
      </svg>
    </button>
  </div>
</template>

<style scoped lang="scss">
$white: #ffffff;
$text-primary: #f4f4f5;
$text-secondary: #d0d0d8;
$transition-fast: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

.scrollbar-x-hide {
	scrollbar-width: none;

	&::-webkit-scrollbar {
		display: none;
	}
}

.tags-area {
	position: absolute;
	left: 0.75rem;
	right: 0.75rem;
	bottom: 4.25rem;
	width: auto;
	animation: fadeIn 0.25s ease-out;
	z-index: 25;
	background: transparent;

	.tags-scroll {
		display: flex;
		gap: 0.5rem;
		overflow-x: auto;
		overflow-y: hidden;
		padding: 0.25rem 1.75rem;
		scroll-behavior: smooth;
	}

	.tag-chip {
		flex-shrink: 0;
		padding: 0.375rem 0.75rem;
		border-radius: 1rem;
		border: 2px solid rgba($white, 0.28);
		background: #2b3037;
		color: $text-secondary;
		font-size: 0.8125rem;
		font-family: inherit;
		white-space: nowrap;
		cursor: pointer;
		transition: $transition-fast;

		&:hover {
			background: #363d47;
			border-color: rgba($white, 0.35);
			color: $text-primary;
		}

		&:active {
			transform: scale(0.98);
		}
	}

	.tag-scroll-btn {
		position: absolute;
		top: 50%;
		transform: translateY(-50%);
		width: 28px;
		height: 28px;
		background: #2a2f36;
		border: 1px solid #4a515a;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		transition: $transition-fast;
		z-index: 10;
		color: #ffffff;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);

		&:hover {
			background: #363d47;
			border-color: #5b6572;
			transform: translateY(-50%) scale(1.05);
		}
	}

	.tag-scroll-left { left: 0; }
	.tag-scroll-right { right: 0; }
}

@media (max-width: 768px) {
	.tags-area {
		left: 0.5rem;
		right: 0.5rem;
		bottom: 4.125rem;
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
</style>
