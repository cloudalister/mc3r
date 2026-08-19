# STATUS — fonte única de verdade (manter com ≤1 página, sobrescrever sempre)

Atualizado: 2026-08-18 ~01h

## Onde o projeto está, em 3 linhas

- Marco: **M1 quase fechado, entrando em M2/M3** — IOP reboot handshake ✅, cdvd init ✅,
  usbkb ✅, versão de módulo ✅. O gate `0x5a8908` (provider) foi ATRAVESSADO em 17/08; o gate
  seguinte `0x528fa0` (spin eterno em vsync) foi ATRAVESSADO em 18/08.
- **Gate atual: `0x5a8908`/`0x5a88f0` de novo — mas agora com causa mapeada.** Correção do
  passo 5: o "ciclo de vsync" do passo 4 era um init único (`FUN_00528ca0` esperando CSR.FIELD,
  corrigido com toggle real do bit 13 por VBlank) + callback de conclusão do loader promovido
  de experimento morto a permanente (decomp prova que o callback registrado `0x5407C0` É
  `iSignalSema` — produtor legítimo). Depois disso o boot chega em `zipFile::Init` e para na
  lookup da tabela do provider recebendo `a0=7` (inteiro) onde deveria chegar ponteiro de path.
  Ver `docs/RESULT_MAINLOOP_DRAW_V1.md`.
- Ainda sem imagem — régua nova (`docs/RENDER_METRICS.md`) toda zerada: `gifPk1/2/3=0`,
  `gsPrims=0`. Determinístico 3/3 no gate atual.

## O gate único

**`0x5a8908` CAIU (18/08, passo 9)** — causa raiz: `jalr` computado cross-função apontando
para `0x42EB48` (o first-bad-pc fantasma de 07/08) sem tabela de resume na função dona; o
sprintf do jogo restartava do topo com args errados e retornava 0. Fix no **gerador**
(`code_generator.cpp`: idiom `lui+addiu` cross-função vira entry target) — 95 gaps em 80
funções fechados no repo inteiro, `resume_gaps.csv` = 0, teste novo na suíte. O path
`cdrom0:\assets.dat` agora monta e chega ao open do provider.
`docs/RESULT_FORMATTER_RESUME_V1.md`.

**FASE 2c ACEITA (19/08, passo 15)**: VBlank roda inline no tick do scheduler (sem thread
paralela no modo determinístico, N=50 handoffs), contrato de semáforos permanente (flag
removida). **1 Stable PC em 10/10 e 7x mais rápido** (3.9s vs 26.7s até o marcador).
`docs/RESULT_FASE2C_V1.md`. Medições padrão agora: janela 90s.

**BINÁRIO 100% HONESTO desde 19/08 04:43** — 13.555 `.o` recompilados (conteúdo divergia de
verdade pós-regeneração de 18/08; o "bad value" do linker era corrida com compile concorrente,
não objeto podre). Baseline 5/5 determinístico no mesmo PC. Ferramentas novas:
`tools/parallel_compile.py` (13,5k arquivos em ~26 min, 20 workers — o caminho antigo levaria
8h), `tools/find_stale.py` (auditoria fonte-vs-objeto — RODAR ANTES DE QUALQUER RELINK),
`tools/validate_objs.py`. Regra nova: relink NUNCA concorrente com compilação.

Gate atual: **`0x245720`** — o gate histórico de julho dentro de `sub_00245680`
(`psxCdCache`): o loop onde `sceCdRead` retorna 0. O degrau anterior a ele: o servidor
"disco pronto" (sid `0x8000059c`, `sub_005420C0` — o "precisa retornar 2"/SCECdComplete de
julho) nunca responde. A leitura por ISO está pronta e testada byte-a-byte
(`RESULT_CDREAD_REAL_V1.md`) esperando o boot chegar nela. Handoff ativo:
`docs/HANDOFF_FASE1_DISKREADY_059C.md`.

## Como medir qualquer coisa

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=100000"
14_run_boot_trace.bat          &rem 1 corrida com trace = prova
21_probe_repeat.bat 3 probe X  &rem 3x confirmação; modo "probe" LIMPO
```

**Modo `595` está APOSENTADO para medição** — ele liga 11 env-vars de experimentos rejeitados
que agora colidem com os handlers reais (achado do passo 3, `docs/RESULT_FILEIO_GATE_V1.md`).

## Regras que não se negociam

1. Dispatch SIF por (servidor, fno) — payloadAddr nunca é chave.
2. Nunca injetar SignalSema — completion só pelo produtor legítimo.
3. Sem chute de bytes — decomp nomeado ou captura PCSX2; incerto = TODO + neutro.
4. Sem env-gate experimental novo; scheduler da Fase 2 congelado.
5. Vitória visual = `gifPackets(total)>0` E `gsPrims>0` + framebuffer — nada além disso conta
   como imagem (atualizado 18/08: `gif>0`/`gsw>0`, o critério antigo, é cego a paths reais de
   render — auditoria M4-M5, `docs/RENDER_METRICS.md`).

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
