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

`0x5a8908` (spin do provider). A escavação dos passos 6-8 (`RESULT_PROVIDER_TABLE_V1`,
`RESULT_DAVE_HEADER_V1`, `RESULT_BOOT_ARGS_V1`) eliminou três hipóteses com evidência
(a0=7 era lixo de print; header "Dave" nunca chega a ser lido; boot args JÁ funcionam) e
cravou a causa atual: **`sub_0042F558` (motor de formatação/sprintf do jogo) retorna 0
caracteres com argumentos válidos**, em 2 call sites independentes, deterministicamente —
o path `cdrom0:\assets.dat` nunca é montado. Suspeita forte (a confirmar no passo 9):
tabela de resume (`switch(ctx->pc)`) incompleta em função gerada — mesma doença do gap
`0x42EB48` documentado em `HANDOFF_2026-08-07_B_DISPATCH_0x42EB48.md` e NUNCA fechado.

## Como medir qualquer coisa

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=25000"
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
