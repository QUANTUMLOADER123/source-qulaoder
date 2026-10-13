#!/usr/bin/env node
/**
 * Static analysis for MidnightUI.
 *
 * Runs the real Luau type checker (strict mode) + linter over every
 * source file through @luau-rs/luau's analysis bindings.
 *
 *   node tools/lint.mjs            # strict, errors only
 *   node tools/lint.mjs --all      # also print lint warnings
 *
 * Exits with a non-zero code when an error is reported.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { Analysis } from '@luau-rs/luau/analysis';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const showAll = process.argv.includes('--all');

/** Roblox classes/appearance types are opaque `any`s for the analyser. */
const TYPE_SHIM = [
	'Instance', 'Frame', 'GuiObject', 'GuiBase2d', 'ScreenGui', 'ScrollingFrame', 'CanvasGroup',
	'TextLabel', 'TextButton', 'TextBox', 'ImageLabel', 'UIStroke', 'UICorner', 'UIPadding',
	'UIListLayout', 'UIGradient', 'UIScale', 'UITextSizeConstraint', 'Enum', 'EnumItem',
	'Color3', 'Vector2', 'Vector3', 'UDim', 'UDim2', 'Rect', 'Tween', 'TweenInfo', 'Font',
	'NumberSequence', 'NumberSequenceKeypoint', 'ColorSequence', 'ColorSequenceKeypoint',
	'InputObject', 'RBXScriptSignal', 'RBXScriptConnection', 'ScreenGui', 'LayerCollector',
].map((name) => `type ${name} = any`).join('; ');

const definitions = [
	{
		name: 'roblox.d.luau',
		source: fs.readFileSync(path.join(here, 'roblox.d.luau'), 'utf8'),
	},
];

function collectFiles() {
	const results = [];

	for (const directory of ['src']) {
		const walk = (current) => {
			for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
				const full = path.join(current, entry.name);

				if (entry.isDirectory()) {
					walk(full);
				} else if (entry.name.endsWith('.luau')) {
					results.push(full);
				}
			}
		};

		walk(path.join(root, directory));
	}

	return results.sort();
}

const files = collectFiles();
const analysis = await Analysis.create({ mode: 'strict', definitions });

let errors = 0;
let warnings = 0;

for (const file of files) {
	const relative = path.relative(root, file).split(path.sep).join('/');
	const source = fs.readFileSync(file, 'utf8');

	// The shim occupies line 1, so reported positions are shifted by one.
	analysis.setModule(relative, `${TYPE_SHIM}\n${source}`);

	const result = await analysis.check(relative);
	const diagnostics = result.diagnostics ?? [];

	const relevant = diagnostics.filter((diagnostic) => diagnostic.severity === 'error' || showAll);

	if (relevant.length === 0) {
		console.log(`clean  ${relative}`);

		continue;
	}

	console.log(`\n${relative}`);

	for (const diagnostic of relevant) {
		const line = Math.max(1, (diagnostic.location?.begin?.line ?? 0));
		const column = (diagnostic.location?.begin?.column ?? 0) + 1;
		const marker = diagnostic.severity === 'error' ? '✗' : '!';

		if (diagnostic.severity === 'error') {
			errors += 1;
		} else {
			warnings += 1;
		}

		console.log(`  ${marker} ${line}:${column} ${diagnostic.message.split('\n')[0]}`);
	}
}

console.log(`\n${files.length} modules · ${errors} errors · ${warnings} warnings`);

process.exit(errors > 0 ? 1 : 0);
