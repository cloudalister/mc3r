# STATUS ATUAL — 2026-08-23 — PASSO 30 CONCLUÍDO PARCIALMENTE

O handshake real do MCMAN foi implementado no dispatcher SIF por (sid,fno):

- sid=0x80000400, fno=0xfe, resposta de 0x0c bytes;
- resultado 0, versões 0x20a e 0x20e, conforme os limiares lidos no decomp de sceMcInit;
- trace: mc3-memcard-rpc kind=mcman-init.

O PC saiu do loop 0x1b15xx e terminou em 0x1a2408 por game-thread-return. Ainda não há imagem: gifPk*=0, gsPrims=0, gsPixels=0 na corrida determinística de validação.

Validação: runtime ps2_runtime OK; find_stale Missing=0/Stale=0; relink fast sequencial OK; suíte retry 278/278; corrida MC3_DETERMINISTIC=1, MC3_DISPATCH_BUDGET=500000, MC3_BOOT_TRACE=1; probe 3x em PCs 0x42e738, 0x433254 e 0x4f97b8, render 0/3.

Próximo gate: após mcman-init, MCMAN fno=0x14, 0x1 e 0xd ainda caem no fallback neutro. Casar esses fnos com sceMc* no decomp e preencher somente os campos lidos pelo cliente.

Regras preservadas: sem SignalSema injetado, sem env-gate, sem chute, scheduler intacto.

Artefatos: docs/RESULT_MEMCARD_30_V1.md; work/exports/longrun_timeline.md; tools/analyze_longrun.py.

Commits: runtime 4d64045; projeto 23f6b73. Sem push.

# STATUS — fonte única de verdade (manter com ≤1 página, sobrescrever sempre)

Atualizado: 2026-08-20 ~02h — PASSO 23 CONCLUÍDO (STREAMING DE CD LIBERADO)

## 📌 Ponto de parada (retomar daqui)

Passo 23 (callback de conclusão de RPC para `sceCdRead`) **CONCLUÍDO e VALIDADO**.
- O fix em `ps2xRuntime` (`SIF.cpp`, `RPC.cpp`, `RPC.h`) aciona `InvokeRpcEndCallback` para completar RPCs síncronas com end callback (`_sceCd_cd_read_intr` `0x5413f0`).
- O contador `0x61FB90` reabastece e desbloqueou o gateB (`func_541760(4)` = 1).
- **Leitura do CD/ISO disparada**: O boot leu PVD (`lsn=0x10`), diretórios (`0x105`–`0x109`) e os setores do gerenciador de assets **Dave / ASSETS.DAT** (`lsn=0x14e5be`, `0x14e5bf`, `0x14e64f`).
- **Próximo Gate**: missing-function `bad=0x4fa368` (faixa do pipeline de lote dos passos 08/09/10).
- Ver detalhes completos em `docs/RESULT_CD_INTR_V1.md`.

## Onde o projeto está, em 3 linhas

- Marco: **M2 (Streaming de CD/ISO) ALCANÇADO!** — `sceCdRead` lê a ISO byte-a-byte, o asset manager ("Dave") começou o carregamento dos arquivos do jogo.
- **Gate atual**: missing-function `bad=0x4fa368` acessado após o término da sequência inicial de leitura do CDVD.
- Ainda sem imagem (`gifPk*=0`, `gsPrims=0`) — o motor gráfico ainda não iniciou os registros de exibição (esperado até o carregamento das estruturas de assets).

## Conquistas estruturais (não reabrir)

Fase 2/2c/2d + Passo 23: scheduler cooperativo com VBlank inline, entrega RPC no turno e invocação de end-callbacks RPC de SIF. Leitura por ISO 100% operacional byte-a-byte. Gerador e tooling (`find_stale.py`, `parallel_compile.py`, relink sequencial) validados.
Histórico completo: `PS2_PROJECT_STATE.md` e `docs/RESULT_*.md`.

## Como medir qualquer coisa

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=100000"
14_run_boot_trace.bat          &rem 1 corrida com trace = prova
21_probe_repeat.bat 3 probe X  &rem 3x confirmação; modo "probe" LIMPO
```

**Modo `595` está APOSENTADO para medição** — ele liga 11 env-vars de experimentos rejeitados que agora colidem com os handlers reais (`docs/RESULT_FILEIO_GATE_V1.md`).

## Regras que não se negociam

1. Dispatch SIF por (servidor, fno) — payloadAddr nunca é chave.
2. Nunca injetar SignalSema — completion só pelo produtor legítimo.
3. Sem chute de bytes — decomp nomeado ou captura PCSX2; incerto = TODO + neutro.
4. Sem env-gate experimental novo; scheduler da Fase 2 congelado.
5. Vitória visual = `gifPackets(total)>0` E `gsPrims>0` + framebuffer — nada além disso conta como imagem (`docs/RENDER_METRICS.md`).

## Mapa de referência (o que ler para quê)

| Preciso de... | Doc |
|---|---|
| entender por que não vejo o jogo / distância até o frame | `docs/CAMINHO_ATE_O_FRAME.md` |
| o protocolo SIF e o que já responde | `docs/SIF_PROTOCOL.md` |
| nome de qualquer endereço do retail | `work/exports/retail_symbol_port.csv` + `docs/SYMBOL_PORT_REPORT.md` |
| código decompilado nomeado do SDK | `work/exports/alpha_decomp_sce.txt` |
| o que cada contador de render mede (`gifPk1/2/3`, `gsPrims`, `gsPixels`) | `docs/RENDER_METRICS.md` |
| como escrever um handoff novo | `docs/TEMPLATE_HANDOFF.md` |
| como operar o loop de trabalho | `docs/WORKFLOW.md` |
| histórico completo (append-only, não é entrada) | `PS2_PROJECT_STATE.md` |

## Ambiente (fixo desta máquina)

JDK: `jdk-21.0.12+8\` (JAVA_HOME p/ Ghidra headless) · CMake: `cmake-3.30.5-windows-x86_64\bin`
· Ninja: VS2022 `Common7\...\CMake\Ninja` · g++: `C:\msys64\ucrt64\bin` · build dir:
`PS2Recomp\out\build` · relink ~3 min (timeout ≥6 min) · suíte roda de `PS2Recomp\out\build`.
Repos: `github.com/cloudalister/mc3r` + fork `github.com/cloudalister/PS2Recomp` branch `mc3`.
