import { version } from '../package.json' with { type: 'json' };

// バージョンの単一の出所は package.json。version だけを named import で読み、CLI から参照する。
export const VERSION: string = version;
