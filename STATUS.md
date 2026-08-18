# STATUS — fonte única de verdade (manter com ≤1 página, sobrescrever sempre)

Atualizado: 2026-08-17 (noite)

## Onde o projeto está, em 3 linhas

- Marco atual: **M1 da escada** (`docs/CAMINHO_ATE_O_FRAME.md`) — fazer os serviços IOP
  responderem. cdvd init ✅, teclado USB ✅, **frente atual: fileio/completion de arquivo**.
- Boot é **determinístico** (Fase 2 aceita): para sempre em `0x5a8908` (spin esperando o
  provider de assets, que espera o sistema de arquivos). Uma corrida = uma prova.
- Nenhuma imagem ainda (`gif=0 gsw=0` desde sempre) — ver a escada para o porquê e a distância.

## O gate único

`0x5a8908` — região `memHeap::Begin`, spin em `func_4FA398` (cadeia `zipFile`/provider).
Destravar = M2. Handoff ativo: `docs/HANDOFF_FASE1_FILEIO_GATE.md`.

## Como medir qualquer coisa

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=25000"
14_run_boot_trace.bat        &rem 1 corrida com trace = prova
21_probe_repeat.bat 3 595 X  &rem 3x só como confirmação final
```

## Regras que não se negociam

1. Dispatch SIF por (servidor, fno) — payloadAddr nunca é chave.
2. Nunca injetar SignalSema — completion só pelo produtor legítimo.
3. Sem chute de bytes — decomp nomeado ou captura PCSX2; incerto = TODO + neutro.
4. Sem env-gate experimental novo; scheduler da Fase 2 congelado.
5. Vitória visual = `gif>0`/`gsw>0` + framebuffer — nada além disso conta como imagem.

## Mapa de referência (o que ler para quê)

| Preciso de... | Doc |
|---|---|
| entender por que não vejo o jogo / distância até o frame | `docs/CAMINHO_ATE_O_FRAME.md` |
| o protocolo SIF e o que já responde | `docs/SIF_PROTOCOL.md` |
| nome de qualquer endereço do retail | `work/exports/retail_symbol_port.csv` + `docs/SYMBOL_PORT_REPORT.md` |
| código decompilado nomeado do SDK | `work/exports/alpha_decomp_sce.txt` |
| como escrever um handoff novo | `docs/TEMPLATE_HANDOFF.md` |
| como operar o loop de trabalho | `docs/WORKFLOW.md` |
| histórico completo (append-only, não é entrada) | `PS2_PROJECT_STATE.md` |

## Ambiente (fixo desta máquina)

JDK: `jdk-21.0.12+8\` (JAVA_HOME p/ Ghidra headless) · CMake: `cmake-3.30.5-windows-x86_64\bin`
· Ninja: VS2022 `Common7\...\CMake\Ninja` · g++: `C:\msys64\ucrt64\bin` · build dir:
`PS2Recomp\out\build` · relink ~3 min (timeout ≥6 min) · suíte roda de `PS2Recomp\out\build`.
Repos: `github.com/cloudalister/mc3r` + fork `github.com/cloudalister/PS2Recomp` branch `mc3`.
