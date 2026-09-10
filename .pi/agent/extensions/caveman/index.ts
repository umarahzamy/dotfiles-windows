/**
 * Caveman Extension
 *
 * Injects compressed communication style into system prompt, adapted from
 * Julius Brussee's caveman-code (buildCaveModePrompt).
 *
 * Default: ON (full)
 * Commands:
 *   /caveman                    — show current state
 *   /caveman on                 — enable
 *   /caveman off                — disable
 *   /caveman mode lite|full|ultra  — set level and enable
 *
 * State persists across session resume.
 *
 * Prompt templates in prompts.md (readable) and prompts.ts (imported).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { CAVE_PROMPTS, LEVELS, type CavemanLevel } from "./prompts.ts";

interface CavemanState {
	enabled: boolean;
	level: CavemanLevel;
}

export default function cavemanExtension(pi: ExtensionAPI) {
	let enabled = true;
	let level: CavemanLevel = "full";

	function persist(): void {
		pi.appendEntry("caveman-state", { enabled, level } satisfies CavemanState);
	}

	function showState(ctx: { ui: { notify: (msg: string, type: string) => void } }): void {
		const msg = enabled ? `Caveman: ON (${LEVELS[level]})` : "Caveman: OFF";
		ctx.ui.notify(msg, "info");
	}

	function setEnabled(val: boolean, ctx: { ui: { notify: (msg: string, type: string) => void } }): void {
		enabled = val;
		ctx.ui.notify(val ? `Caveman ON (${LEVELS[level]})` : "Caveman OFF", "info");
		persist();
	}

	function setLevel(lvl: CavemanLevel, ctx: { ui: { notify: (msg: string, type: string) => void } }): void {
		level = lvl;
		enabled = true;
		ctx.ui.notify(`Caveman: ON (${LEVELS[level]})`, "info");
		persist();
	}

	// --- Command ---

	pi.registerCommand("caveman", {
		description: "Show or change caveman communication style",
		handler: async (args, ctx) => {
			const t = args.trim();

			if (t === "") { showState(ctx); return; }
			if (t === "on") { setEnabled(true, ctx); return; }
			if (t === "off") { setEnabled(false, ctx); return; }

			if (t.startsWith("mode ")) {
				const lvl = t.slice(5).trim().toLowerCase() as CavemanLevel;
				if (lvl === "lite" || lvl === "full" || lvl === "ultra") {
					setLevel(lvl, ctx);
				} else {
					ctx.ui.notify(`Unknown level: "${lvl}". Use lite, full, or ultra`, "error");
				}
				return;
			}

			ctx.ui.notify(`Unknown: "${t}". Try: on, off, mode lite|full|ultra`, "error");
		},
	});

	// --- System prompt injection ---

	pi.on("before_agent_start", async (event) => {
		if (!enabled) return;
		return {
			systemPrompt: event.systemPrompt + CAVE_PROMPTS[level],
		};
	});

	// --- State restore on session start ---

	pi.on("session_start", async (_event, ctx) => {
		const entries = ctx.sessionManager.getEntries();
		const stateEntry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "caveman-state")
			.pop() as { data?: CavemanState } | undefined;

		if (stateEntry?.data) {
			enabled = stateEntry.data.enabled ?? true;
			if (stateEntry.data.level === "lite" || stateEntry.data.level === "full" || stateEntry.data.level === "ultra") {
				level = stateEntry.data.level;
			}
		}
	});
}
