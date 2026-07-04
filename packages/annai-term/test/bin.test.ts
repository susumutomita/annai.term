import { describe, expect, it } from 'bun:test';
import pkg from '../package.json';

const BIN = new URL('../bin/annai-term.ts', import.meta.url).pathname;

async function runBin(args: string[]) {
  const proc = Bun.spawn(['bun', BIN, ...args], {
    stdout: 'pipe',
    stderr: 'pipe',
  });
  const [stdout, stderr] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);
  const exitCode = await proc.exited;
  return { stdout, stderr, exitCode };
}

describe('annai-term bin（実プロセス）', () => {
  describe('--version を渡して起動したとき', () => {
    it('version を標準出力に出して終了コード 0 で終わる', async () => {
      const r = await runBin(['--version']);
      expect(r.exitCode).toBe(0);
      expect(r.stdout.trim()).toBe(pkg.version);
      // 成功系では標準エラーに何も出さない (out / err の結線取り違えを検出する)。
      expect(r.stderr).toBe('');
    });
  });

  describe('未対応の引数を渡したとき', () => {
    it('終了コード 2 で終わり、標準エラーにヘルプを出す', async () => {
      const r = await runBin(['bogus']);
      expect(r.exitCode).toBe(2);
      expect(r.stderr).toContain('annai-term');
      // エラー系では標準出力に何も出さない (エラーとヘルプは stderr へ)。
      expect(r.stdout).toBe('');
    });
  });
});
