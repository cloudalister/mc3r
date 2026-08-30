# HANDOFF — retomada em sessao nova — 2026-08-30

## Onde estamos

Recompilacao estatica nativa de Midnight Club 3: DUB Edition Remix (PS2, retail
`SLUS_213.55`), em `E:\Games\Emuladores\Sony\mc3recomp`. O jogo ja passa da tela legal,
renderiza (1,0M primitivas / 1,09 bi de pixels por corrida de 900 s) e desenha modelos
com esqueleto. Nao chega ao menu 3D ainda.

## O que acabou de acontecer (resultado principal da sessao)

**Bug de traducao do `sqrt.s`.** O gerador emitia o operando de `SQRT.S` a partir de `fs`,
mas o R5900 poe em `ft`. Toda raiz quadrada do jogo lia `$f0`; quando negativo, NaN, que
se propagava ate um laco infinito de Taylor dentro de `logf` (4.294.967.296 iteracoes).

- Corrigido em `PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp:2074` (`fs` -> `ft`).
- Propagado aos arquivos ja gerados por `work/scratch/fix_sqrt_operand.py`
  (221 arquivos, 323 instrucoes, 0 anomalias) — em vez de re-rodar `04_run_recomp.bat`,
  que apagaria instrumentacao manual acumulada.
- Prova empirica: em 131 codificacoes distintas de `sqrt.s` no corpus, `fs` = 0 em 100%
  delas; `ft` assume 18 valores.
- Postmortem completo: `docs/RESULT_SQRT_OPERAND_BUG_2026-08-30.md`.

Efeito medido (corrida unica de 900 s, sem repeticao):

| | antes | depois |
|---|---:|---:|
| NaN em powf/logf | presente | nenhum |
| `gsPrims` | 704.397 | 1.004.584 |
| `gsPixels` | 257.216.311 | 1.088.137.517 |
| `rmcModel::DrawSkinned` | nunca | 18 chamadas |
| PC estavel | `0x41D188` (dentro de `logf`) | `0x1D3990` |

`0x1D3990` = `mcParticleFogMgr::DrawAllParticles`.

## Estado do repositorio

```
b84c7ef submodule: SQRT.S operand fix
1e8faf9 docs: the sqrt.s operand bug, its proof and its effect
```
Submodulo em `122f780` (`fix(recomp): SQRT.S reads its operand from ft, not fs`).

**Sujo, nao commitado** (instrumentacao de phase timing, decidir se fica ou sai):
`PS2Recomp/ps2xRuntime/src/lib/ps2_gs_rasterizer.cpp`, `.../ps2_runtime.cpp`.

Nada foi enviado ao remoto — regra do projeto: executor so faz commit local.

## Proximos passos sugeridos, em ordem de valor

1. **Auditar as demais instrucoes COP1.** O desmontador imprime `c1 0x......` para
   `sqrt.s`, ou seja o buraco existe tambem no decodificador textual. Se `sqrt` passou
   despercebido, outras provavelmente passaram. Conferir campo a campo contra o manual do
   EE. Maior retorno esperado, e barato.
2. **Refazer o dump de frame com gatilho acima de 1.000.000 primitivas.** O dump anterior
   saiu preto porque o gatilho de 700k caiu no intervalo escuro logo apos o teardown da
   tela legal. Nao e evidencia de cena preta — e captura na hora errada.
   `work/scratch/Run-FrameDump.ps1`, `MC3_FRAME_DUMP_MIN_PRIMS`.
3. **Investigar a parada em `0x1D3990`** (`mcParticleFogMgr::DrawAllParticles`).
4. **Repetir a medicao 3x.** Os numeros acima sao de uma corrida so. Corridas do mesmo
   binario ja mostraram dispersao de 12-25%. O sumico do NaN e a mudanca de PC sao
   qualitativos e nao dependem disso; os contadores dependem.
5. **Performance (~3 fps).** Causa ja medida: interpretadores VIF1/VU1 (ja reduzidos
   59%/68% por Codex em `27faf89`) e contencao de 153 us/prim no `GuestExecutionScope`.
   Mexer no scheduler exige decisao explicita do usuario — Fase 2 esta congelada por regra.

## Regras do projeto que nao se negociam

1. Despacho SIF por (server, fno) — `payloadAddr` nunca e chave.
2. **Nunca injetar `SignalSema`** — conclusao so pelo produtor legitimo.
3. Nada de chutar bytes — decomp nomeado ou captura; incerto = TODO + neutro.
4. Sem env-gate experimental novo; **scheduler da Fase 2 congelado**.
5. Vitoria visual = `gifPackets(total) > 0` E `gsPrims > 0` + framebuffer.
6. Exe relinkado tem de ser mais novo que a lib.
7. Executor so faz commit local — **sem push**.
8. Nada do jogo no repo publico (ISO, assets, MC.MAP/SYM, codigo gerado do ELF, decomp).
9. Usar `retail_addr` (primeira coluna) em `retail_symbol_port.csv`, nunca `alpha_addr`.

## Preferencia de trabalho do usuario

Nao pedir sinal verde a cada passo investigativo. Perguntar so sobre duracao de loop/corrida
e sobre decisoes que mudam escopo. Documentar e commitar sem perguntar.

## Ferramentas uteis

- Build incremental: `tools/find_stale.py` -> `tools/parallel_compile.py` ->
  `Generate-PartialRegister.ps1` -> `10_link_partial_runner.bat`
- Env: `MC3_BOOT_TRACE`, `MC3_HEADLESS`, `MC3_FRAME_DUMP`, `MC3_FRAME_DUMP_MIN_PRIMS`,
  `MC3_PHASE_TIMING`, `MC3_DISPATCH_BUDGET`
- Scripts em `work/scratch/`: `Run-FrameDump.ps1`, `Run-ProbeArgs.ps1`,
  `Measure-Phases.ps1`, `Catch-Stall.ps1`, e os `patch_*.py` de instrumentacao
- Armadilhas conhecidas: arquivos gerados usam CRLF (normalize antes de `str.replace`);
  o trace de frame "vivo" fica em `ps2_runtime.cpp:~328`, o de ~2896 esta dentro de
  `PS2_IF_AGRESSIVE_LOGS` e nao compila; `ps2x_tests.exe` saindo `0xC0000139` e falta de
  `C:\msys64\ucrt64\bin` no PATH, nao teste quebrado
