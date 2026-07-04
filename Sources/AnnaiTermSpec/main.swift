// 各モジュールのスペックを順に実行し、失敗が 1 件でもあれば exit 1。
runCLISpec()
runCatalogSpec()
runGhosttySpec()
runHerdrSpec()
runBackendSpec()
runEngineSpec()
runPrivacySpec()
specSummaryAndExit()
