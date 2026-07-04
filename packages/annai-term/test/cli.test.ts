import { describe, expect, it } from 'bun:test';
import pkg from '../package.json';
import { HELP_TEXT, run } from '../src/cli.ts';
import { VERSION } from '../src/version.ts';

function capture() {
  const out: string[] = [];
  const err: string[] = [];
  return {
    io: {
      out: (text: string) => {
        out.push(text);
      },
      err: (text: string) => {
        err.push(text);
      },
    },
    out,
    err,
  };
}

describe('run', () => {
  describe('--version / -v が渡されたとき', () => {
    it('version を標準出力に 1 行出して 0 を返す', () => {
      const c = capture();
      const code = run(['--version'], c.io);
      expect(code).toBe(0);
      expect(c.out).toEqual([pkg.version]);
      expect(c.err).toEqual([]);
    });

    it('短縮形 -v でも version を出す', () => {
      const c = capture();
      const code = run(['-v'], c.io);
      expect(code).toBe(0);
      expect(c.out).toEqual([pkg.version]);
    });

    it('後続トークンが続いても診断フラグを先勝ちで short-circuit する', () => {
      const c = capture();
      const code = run(['--version', 'bogus'], c.io);
      expect(code).toBe(0);
      expect(c.out).toEqual([pkg.version]);
      expect(c.err).toEqual([]);
    });
  });

  describe('引数が無いとき', () => {
    it('ヘルプを標準出力に出して 0 を返す', () => {
      const c = capture();
      const code = run([], c.io);
      expect(code).toBe(0);
      expect(c.out).toEqual([HELP_TEXT]);
      expect(c.err).toEqual([]);
    });
  });

  describe('--help / -h が渡されたとき', () => {
    it('どちらでもヘルプを標準出力に出して 0 を返す', () => {
      for (const flag of ['--help', '-h']) {
        const c = capture();
        const code = run([flag], c.io);
        expect(code).toBe(0);
        expect(c.out).toEqual([HELP_TEXT]);
        expect(c.err).toEqual([]);
      }
    });
  });

  describe('未対応の引数が渡されたとき', () => {
    it('入力を含むエラーとヘルプを標準エラーに出して 2 を返す', () => {
      const c = capture();
      const code = run(['no-such-command'], c.io);
      expect(code).toBe(2);
      expect(c.out).toEqual([]);
      expect(c.err).toHaveLength(2);
      expect(c.err[0]).toContain('no-such-command');
      expect(c.err[1]).toBe(HELP_TEXT);
    });
  });
});

describe('VERSION', () => {
  it('package.json の version と一致する', () => {
    expect(VERSION).toBe(pkg.version);
  });
});

describe('HELP_TEXT', () => {
  it('プロダクト名と実在する 2 つのフラグだけを案内する', () => {
    expect(HELP_TEXT).toContain('annai-term');
    expect(HELP_TEXT).toContain('--version');
    expect(HELP_TEXT).toContain('--help');
  });
});
