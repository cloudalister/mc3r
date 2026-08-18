# STATUS — fonte única de verdade (manter com ≤1 página, sobrescrever sempre)

Atualizado: 2026-08-18 ~01h

## Onde o projeto está, em 3 linhas

- Marco: **M1 quase fechado, entrando em M2/M3** — IOP reboot handshake ✅, cdvd init ✅,
  usbkb ✅, versão de módulo ✅. O gate `0x5a8908` (provider) foi ATRAVESSADO em 17/08; o gate
  seguinte `0x528fa0` (spin eterno em vsync) foi ATRAVESSADO em 18/08.
- **Gate atual: dentro do próprio ciclo de vsync** (`0x545674`/`0x546e70`/`0x528fa8`, mesma
  região — `sceGsSyncV`/`VSync()` do jogo, chamado repetidamente pelo loop principal, não mais
  um freeze). Causa do freeze anterior: `INTC_STAT` (EE, `0x1000F000`) nunca era escrito pelo
  runtime; o jogo faz busy-poll direto nesse registrador (bypassa `AddIntcHandler`). Corrigido
  em `PS2Memory::latchIntcStatBit`. Ver `docs/RESULT_GSYNCV_METRICS_V1.md`.
- Ainda sem imagem — régua nova pronta (`docs/RENDER_METRICS.md`): critério de vitória agora é
  `gifPackets(total)>0` e `gsPrims>0`, ambos ainda `0` nas corridas mais recentes. Os
  contadores antigos `gif`/`gsw` continuam cegos aos paths reais de render (auditoria M4-M5).

## O gate único

Não é mais um freeze fixo — o boot agora executa o ciclo real de vsync (múltiplas chamadas por
segundo). O PC "estável" reportado por `dispatch-budget-reached` cai quase sempre (~80% das
corridas) em `0x545674` (dentro de `sceGsSyncV`), com jitter residual ocasional em `0x528fa8`/
`0x546e70` — mesma região de código, não uma trava nova. Handoff que produziu isso:
`docs/HANDOFF_FASE1_GSYNCV_METRICS.md`. Próximo passo: achar por que `gifPackets`/`gsPrims`
continuam `0` — o jogo ainda não chega a programar path GIF real depois do vsync desbloqueado.

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
