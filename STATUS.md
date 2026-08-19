# STATUS — fonte única de verdade (manter com ≤1 página, sobrescrever sempre)

Atualizado: 2026-08-19 ~08h

## Onde o projeto está, em 3 linhas

- Marco: **M1 quase fechado** — todos os serviços IOP do boot respondem (cdvd init+diskready,
  usbkb, fileio handshake, versão de módulo). Kernel determinístico (Fases 2/2c/2d), binário
  100% honesto (19/08 04:43), medição calibrada (budget 100k, janela 90s): 10/10 no mesmo PC.
- **Gate único atual: `0x245720`** — laço de `sub_00245680` (`psxCdCache`). O diskready=2 já
  chega (5x por corrida), o boot toca `0x542230`/`0x5494e0` e volta ao laço: existe uma
  SEGUNDA condição não mapeada (candidato: cadeia `sceCdSeek`/`func_5424A8`==1 + completion).
  `sceCdRead` nunca dispara. Ver `docs/RESULT_FASE2D_RPC_TICK_V1.md`.
- Ainda sem imagem (`gifPk*=0`, `gsPrims=0`) — esperado até o CD ler de fato (M2).

## Conquistas estruturais (não reabrir)

Fase 2/2c/2d: scheduler cooperativo com VBlank inline (N=50) e entrega RPC no turno —
1 PC em 10/10. Contrato de semáforos correto (retorno=sid), permanente. Gerador: resume gaps
(95), jump-tables, 450 colisões de alias — classes fechadas com teste. Binário honesto +
tooling (`parallel_compile.py` ~26min, `find_stale.py`=0 obrigatório pré-relink, relink nunca
concorrente). Leitura por ISO pronta e testada byte-a-byte esperando o boot chegar nela.
Histórico completo: `PS2_PROJECT_STATE.md` e `docs/RESULT_*.md`.

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
