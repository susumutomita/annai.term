import { VERSION } from './version.ts';

// 出力先を注入可能にして、run を副作用のない純関数として単体テストできるようにする。
// bin 側で process.stdout / process.stderr を渡す。
export interface CliIO {
  readonly out: (text: string) => void;
  readonly err: (text: string) => void;
}

export const HELP_TEXT = [
  'annai-term — Ghostty・Herdr のキーバインドを日本語で案内するローカル CLI',
  '',
  'Usage:',
  '  annai-term --version   バージョンを表示する',
  '  annai-term --help      このヘルプを表示する',
  '',
  'Docs: https://github.com/susumutomita/annai.term',
].join('\n');

// V1 足場の入口。実在するフラグ (--version / --help) だけを扱い、未実装コマンドは持たない。
// adapters / catalog / engine / tui は後続 Issue で結線する。
// --version / --help は診断フラグとして先勝ちで短絡させる (git --version foo と同じ慣習)。
// 後続トークンの有無に関わらず表示して 0 を返し、未対応トークンの検査はしない。
export function run(argv: readonly string[], io: CliIO): number {
  if (argv.includes('--version') || argv.includes('-v')) {
    io.out(VERSION);
    return 0;
  }
  if (argv.length === 0 || argv.includes('--help') || argv.includes('-h')) {
    io.out(HELP_TEXT);
    return 0;
  }
  io.err(`annai-term: 未対応の引数です: ${argv.join(' ')}`);
  io.err(HELP_TEXT);
  return 2;
}
