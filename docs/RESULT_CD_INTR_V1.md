# Resultado — passo 23: callback de conclusão de RPC e desbloqueio de streaming do CD

Data: 20/08/2026. Repo raiz `mc3recomp` (branch `main`) + submódulo `PS2Recomp` (branch `mc3`).

## Resumo (3 linhas)

- **Causa Resolvida**: O dispatcher SIF síncrono do runtime completava RPCs (`commandId == 0x8000000A`) sem disparar o `end_function` de RPC (`client+0x1C`), fazendo com que o `_sceCd_cd_read_intr` (`0x5413f0`) nunca rodasse.
- **Evidência**: A invocação do end callback via `ps2_syscalls::InvokeRpcEndCallback` fez o contador `0x61FB90` reabastecer, desbloqueou o gateB (`func_541760(4)` retornando 1), e o jogo disparou **9 leituras de CD com LBAs variados**, incluindo os setores iniciais do arquivo **Dave / ASSETS.DAT** (`lsn=0x14e5be`).
- **Próximo Bloqueio**: O streaming do CD/ISO está operacional (M2 alcançado). As 3 corridas de probe estabilizam no missing-function `bad=0x4fa368` (faixa do `zipOpen` / Dave asset manager).

## Detalhes da Execução

1. **Stash Popped & Build**:
   - `git stash pop` aplicado no submódulo `PS2Recomp` (`SIF.cpp`, `RPC.cpp`, `RPC.h`).
   - `python tools/find_stale.py` confirmou `Missing: 0, Stale: 0`.
   - Relink realizado via `10_link_partial_runner.bat fast` com `PATH` incluindo MSYS2 UCRT64.

2. **Prova Determinística (`MC3_DETERMINISTIC=1`, `MC3_DISPATCH_BUDGET=100000`, 90s)**:
   - Log: `work/logs/14_run_boot_trace.log`.
   - `endCallbackInvoked=1` registrado para `callback=0x5413f0` (`_sceCd_cd_read_intr`).
   - `gateB@0x54232c` retornou `v0=1` em todas as verificações subsequentes.
   - LBAs lidos na ISO:
     * `lsn=0x10` (PVD)
     * `lsn=0x105` .. `0x109` (Diretórios do sistema)
     * `lsn=0x14e5be` (Leitura do cabeçalho "Dave" / `ASSETS.DAT`)
     * `lsn=0x14e5bf` (90 setores)
     * `lsn=0x14e64f` (5d setores)

3. **Validação 3x (`21_probe_repeat.bat 3 probe cd_intr_v1`)**:
   - As 3 corridas tentam abrir os arquivos lidos e encontram o missing-function `bad=0x4fa368` (faixa do pipeline de gerador/lote 08/09/10).

## Métricas de Render (M0-M6)
- `gifPkTotal=0`, `gsPrims=0`. Vitória visual não alcançada ainda (esperado até o asset manager carregar as estruturas do M4/M5).
