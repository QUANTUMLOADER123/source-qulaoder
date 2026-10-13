#!/usr/bin/env node
/**
 * Runs the MidnightUI selftest bundle inside a real Luau VM (WASM),
 * with the MockRoblox environment installed by the bundle itself.
 *
 *   python3 tools/build.py --tests && node tools/run_tests.mjs
 *
 * Requires @luau-rs/luau (devDependency of this folder).
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { Lua } from '@luau-rs/luau';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const bundlePath = path.join(root, 'tests', '.build', 'bundle.luau');

if (!fs.existsSync(bundlePath)) {
	console.error(`missing ${path.relative(root, bundlePath)} — run: python3 tools/build.py --tests`);
	process.exit(2);
}

const source = fs.readFileSync(bundlePath, 'utf8');

const lines = [];
const warnings = [];

const lua = await Lua.create();

lua.globals.set(
	'print',
	lua.createFunction((...args) => {
		lines.push(args.map((value) => String(value)).join(' '));
	})
);

// `warn` is a Roblox global; the mock defines its own, but any warning
// raised before the mock installs should still be visible.
lua.globals.set(
	'warn',
	lua.createFunction((...args) => {
		warnings.push(args.map((value) => String(value)).join(' '));
	})
);

lua.globals.set(
	'__warnHook',
	lua.createFunction((text) => {
		process.stdout.write('| ' + String(text) + '\n');
	})
);

let report = null;
let crashed = null;

try {
	const values = lua.execute(source);

	report = values.length > 0 ? values[0] : null;
} catch (error) {
	crashed = error;
}

if (crashed === null && (!report || typeof report.get !== 'function')) {
	// not the selftest bundle (e.g. tests/Debug.luau) — just show the output
	for (const line of lines) {
		console.log(line);
	}

	for (const warning of warnings) {
		console.log('warn: ' + warning);
	}

	process.exit(0);
}

const passed = report ? Number(report.get('Passed') ?? 0) : 0;
const failed = report ? Number(report.get('Failed') ?? 0) : 0;

const failures = [];

if (report) {
	const list = report.get('Failures');

	if (list && typeof list.toArray === 'function') {
		for (const item of list.toArray()) {
			failures.push(String(item));
		}
	}
}

const notes = lines.filter((line) => line.startsWith('TEST:NOTE '));

if (process.argv.includes('--all')) {
	console.log('\nvm output:');

	for (const line of lines) {
		console.log(' | ' + line);
	}
}

if (crashed) {
	for (const line of lines) {
		console.log(' | ' + line);
	}

	console.error('\n💥 the bundle crashed before finishing\n');
	console.error(crashed.stack ?? crashed.message ?? String(crashed));
	console.error('\n--- luau output ---');
	console.error(lines.join('\n') || '(none)');
	process.exit(1);
}

console.log('\nMidnightUI selftest');
console.log('-------------------');
console.log(`passed : ${passed}`);
console.log(`failed : ${failed}`);

if (notes.length > 0) {
	console.log('\nnotes:');

	for (const note of notes) {
		console.log(' • ' + note.replace('TEST:NOTE ', ''));
	}
}

if (failures.length > 0) {
	console.log('\nfailures:');

	for (const failure of failures) {
		console.log(' ✗ ' + failure);
	}
}

if (warnings.length > 0) {
	console.log('\nwarnings from the vm:');

	for (const warning of warnings) {
		console.log(' ! ' + warning);
	}
}

if (failed > 0 || failures.length > 0) {
	process.exit(1);
}

console.log('\nall good ✅');
