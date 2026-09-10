import { tmpdir, homedir } from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem, AutocompleteProvider } from "@earendil-works/pi-tui";

const VARS: Record<string, string> = {
	$tmp: tmpdir(),
	$home: homedir(),
	$HOME: homedir(),
};

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.addAutocompleteProvider(
			(current: AutocompleteProvider): AutocompleteProvider => ({
				async getSuggestions(lines, cursorLine, cursorCol, options) {
					const line = lines[cursorLine] ?? "";
					const before = line.slice(0, cursorCol);
					const entry = Object.entries(VARS).find(([key]) => before.endsWith(key));
					if (!entry) {
						return current.getSuggestions(lines, cursorLine, cursorCol, options);
					}
					const [key, value] = entry;
					return {
						items: [{ value, label: key, description: value }],
						prefix: key,
					};
				},
				applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
					return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
				},
				shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
					return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
				},
			}),
		);
	});
}
