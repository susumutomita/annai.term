#!/usr/bin/env bun
import { run } from '../src/cli.ts';

// process.exit を呼ぶと write の drain 前にプロセスが落ち、pipe buffer を超える出力
// (後続 Issue の keybinding 一覧など) が切り捨てられる。exitCode を設定して自然終了させ、
// ランタイムに stdout / stderr を drain させる。
process.exitCode = run(process.argv.slice(2), {
  out: (text) => {
    process.stdout.write(`${text}\n`);
  },
  err: (text) => {
    process.stderr.write(`${text}\n`);
  },
});
