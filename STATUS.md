# STATUS — fonte única de verdade (manter com ≤1 página, sobrescrever sempre)

Atualizado: 2026-08-18 ~00h

## Onde o projeto está, em 3 linhas

- Marco: **M1 quase fechado, entrando em M2/M3** — IOP reboot handshake ✅, cdvd init ✅,
  usbkb ✅, versão de módulo ✅. O gate `0x5a8908` (provider) foi ATRAVESSADO em 17/08.
- **Gate atual: `0x528fa0` = spin em `sceGsSyncV`** (espera de VBlank dentro do init do
  `gfxPipeline`) — e `vif=2`: primeiro tráfego VIF da história do projeto.
- Ainda sem imagem — mas ATENÇÃO: os contadores `gif`/`gsw` são cegos aos paths reais de
  render (só medem PATH3/porta privilegiada — auditoria M4-M5). Régua nova pendente.

## O gate único

`0x528fa0` — `sceGsSyncV`, espera de vsync no init gráfico. Hipótese principal: interação com
o modo determinístico (VBlank avança por idle; spin ocupado pode nunca gerar idle). Handoff
ativo: `docs/HANDOFF_FASE1_GSYNCV_METRICS.md`.

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
