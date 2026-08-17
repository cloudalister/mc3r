# MASTER PLAN — Do Pink Screen à Tela Inicial (MC3 Recomp)

Atualizado: 2026-07-08 (rev 2 — gate 0x54232c confirmado mas insuficiente; novo blocker = fila de comandos 0x704200 sem consumidor)
Escopo: destravar o boot do runner parcial (`work\link\partial\mc3_partial.exe`) até render real de menu/título.
Público: qualquer LLM (Claude/Codex/Gemini) assumindo o projeto. **Não invente nada fora do que está aqui e no `BRAIN.md` raiz.**

---

## 0. Regras anti-alucinação (LEIA PRIMEIRO)

1. **Fonte de verdade**: `BRAIN.md` (raiz) + este arquivo + `PS2_PROJECT_STATE.md`. Se divergirem, o checkpoint mais recente do `BRAIN.md` vence.
2. **Nunca afirme estado sem rodar**: `15_auto_boot_probe.bat 8 595` e ler `work\boot_probe\latest_status.md` + `work\logs\14_run_boot_trace.log`.
3. **Todo experimento de runtime é env-gated** (`MC3_*=1`). Nada vira permanente sem evidência do PCSX2 real (via PCSX2-MCP) ou do código gerado.
4. **Não sinalize semáforos às cegas** — isso já foi tentado e crashou (ver checkpoint 2026-06-17 do BRAIN.md, exit `-1073741571` por aliases arbitrários; e a regra do sid=9 no checkpoint 2026-06-29).
5. **Não compile batches novos "por via das dúvidas"**: não há mais missing-function no caminho de boot. O bloqueio atual é semântica SIF/IOP, não código faltando.
6. Endereços citados abaixo foram verificados no código gerado em `work\generated\ghidra\` em 2026-07-07. Se editar/regenerar esses arquivos, revalide.

## 1. Estado atual (verificado 2026-07-07)

- Tela rosa = framebuffer fallback. **Esperado.** O jogo ainda não emitiu draw de verdade (`gif=0 gsw=0`).
- Classificação do probe: `render-started`, PC estável `0x245720` em `sub_00245680`, counters `dma=2 gif=0 gsw=0 vif=3`.
- Loop externo: `sub_00245680` repete enquanto `FUN_005422c8` não retornar `1`.

## 2. Anatomia do gate (análise estática do código gerado)

Arquivos: `work\generated\ghidra\FUN_005422c8_0x5422c8.cpp` e `FUN_00541760_0x541760.cpp`.

### FUN_005422c8 retorna 1 somente se:

1. `(fbb8 & 1)` == 0 na entrada, OU `FUN_005418d0()` != 6 (senão retorna 0 cedo em `0x54231c`);
2. `FUN_00541760(a0=4)` (chamada em `0x542324`) retornar **≠ 0** — senão pula pro fail-path `0x542464` e **retorna 0** ← **É AQUI QUE ESTÁ TRAVADO HOJE**;
3. depois monta o request em `0x61FC80`, chama `sub_00548BC8` 4x, e `sub_00549488`; se `sub_00549488` retornar >= 0 e `fb90 (0x61FB90) > 0` → retorna 1.

### FUN_00541760(a0) retorna 1 por dois caminhos:

- **Caminho A (rápido)**: `PollSema(fba8)` com sucesso (retorno comparado ao **sid**, não a 0 — por isso `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID`), grava `fb9c = a0`, `ReferThreadStatus`, `FUN_00541968(1)`; então `sub_00548C78()`; lê `fbbc (0x61FBBC)`: se `>= 0` → **retorna 1**.
- **Caminho B (loop 595)**: se `fbbc < 0` (hoje é `0xFFFFFFFF`), entra no loop:
  - chama `sub_005492B8(a0=0x620D50, a1=0x80000595, a2=0)` (request SIF 595);
  - se retorno >= 0, lê **`mem[0x620D50 + 0x24]` = endereço `0x00620D74`**;
  - se `0x620D74 != 0` → escreve `fbbc = 0` → **retorna 1**;
  - se `0x620D74 == 0` → delay busy-loop e repete.
- **Falha**: se `PollSema(fba8)` falha e `fb90 > 0` → log de erro e retorna 0; se `fb90 <= 0` → retorna 0 silencioso (trace `empty-return`). O trace atual mostra esse retorno 0.

### BUG CONFIRMADO no experimento atual

`MC3_SIF_EXPERIMENT_595_COMPLETE` em `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` (~linha 455-465) escreve:
`*(u32*)(deref(0x620D50) + 0x10) |= 1` — ou seja, trata `0x620D50` como **ponteiro** e escreve em `+0x10`.

O jogo lê `0x620D50 + 0x24` **direto** (o struct do request 595 VIVE em `0x620D50`; `$s0 = 0x620D50`, load `lw $v0, 0x24($s0)` em `0x541860`).

**Correção proposta (Experimento E1)**: no handler do 595, escrever `1` em `0x00620D74` (= `0x620D50 + 0x24`), coerente com o padrão de completion `aux + 0x24` já usado no handler genérico `0x80000009` (mesmo arquivo, ~linha 1019).

## 2b. Atualização 2026-07-08 — Resultado dos experimentos e novo blocker

### O que foi testado (relatório: `work\boot_probe\visual_regression_20260708.md`)

- `pollsid`: PC estável `0x245720`, fail-path de `FUN_005422c8` 32x. Counters inalterados.
- `payload592`: PC estável `0x245734`, fail-path 32x.
- `MC3_EXPERIMENT_5422C8_PASS_541760=1` (novo, env-gated): força `$v0=1` no branch `0x54232c` logo após `FUN_00541760(4)`. Resultado: `FUN_005422c8` retorna 1, fail-path zera, globals mudam (`fbb4=1 fbd8=1 fc80=0x10`).
- **Conclusão: `0x54232c` é gate real mas NÃO suficiente.** Counters continuam `gif=0 gsw=0`. Não gastar mais tempo nele.

### Novo blocker: WaitSema sid=43, pc=0x5469e0, ra=0x5476b0

Análise estática (2026-07-08, `sub_00547608_0x547608.cpp` + `sub_0054D6A0_0x54d6a0.cpp`, ambos batch_0054):

- `ra=0x5476b0` = retorno do `WaitSema` dentro de `sub_00547608` (0x547608–0x5476D0).
- `sub_00547608` é um wrapper síncrono "enfileira comando + espera": `CreateSema` → `sub_0054D570(0)` (aloca nó) → `sub_0054D6A0(nó, callback=0x5476D0, sid)` → `WaitSema(sid)` → `DeleteSema`.
- O **callback `0x5476D0`** (segunda metade do MESMO arquivo `sub_00547608_0x547608.cpp`) faz `iSignalSema(a3)` + `sync` + `ei` — é ele que deveria acordar o sid.
- `sub_0054D6A0` **insere o nó numa fila ligada global em `0x00704200` (guest)**. Quem sinaliza o semáforo é o CONSUMIDOR dessa fila (despachante async de comandos IOP/CDVD), que o runtime atual não executa/emula.
- Portanto: **o problema não é "um semáforo perdido", é a fila de comandos em `0x704200` sem consumidor.** Sinalizar sid=43 na mão só empurra pro próximo comando da mesma fila.

### Próximo trabalho (substitui a Fase 1/2 antigas como prioridade)

1. **Mapear o consumidor da fila `0x704200`**: achar quem lê `0x704200` no código gerado (candidatos: threads criadas no boot, handler registrado via `AddIntcHandler`/DMA callback, ou o dispatcher chamado por `sub_0054C160`). Descobrir em qual evento real (vsync? DMA CDVD? SIF cmd?) o jogo original drena essa fila.
2. **Hipótese de experimento (E2, só depois do item 1)**: emular o drain da fila — quando um nó for enfileirado, o runtime processa o comando (ou marca como completo) e invoca o callback do nó (`0x5476D0`) com a3=sid, respeitando a ordem da fila. Env-gated: `MC3_EXPERIMENT_704200_QUEUE_DRAIN=1` (nome sugerido).
3. **Validação live (PCSX2-MCP)**: no jogo real, breakpoint em `0x547608`/`0x5476b0` e watch em `0x704200` para ver quem consome a fila e em que contexto (thread? handler INTC?).
4. Só promover se bater com o live.

### Gotcha de pipeline (descoberto 2026-07-08 — CUSTOU HORAS)

**`10_link_partial_runner.bat` NÃO recompila .cpp alterado; só relinka objetos existentes.** Editou função gerada ou instrumentou? Precisa recompilar o batch dela antes do relink:

```powershell
# ex.: FUN_005422c8 está em batch_0053 (linha 167 do manifest) — Limit padrão 25 NÃO chega nela
powershell -File tools\Compile-GeneratedBatch.ps1 -Batch batch_0053 -Limit 0 -Mode object
```

Depois `10_link_partial_runner.bat fast` e **validar que o patch entrou no exe** (ex.: `findstr` da string nova de log no binário) antes de rodar probe. Automação recomendada a criar: `16_rebuild_target_and_probe.bat <função> <modo>` — acha o batch em `work\index\functions_index.csv`, recompila o objeto certo, relinka, valida string do experimento no exe, roda `15_auto_boot_probe.bat`. (Atenção: o prefixo `16_` já é usado por `16_pcsx2_mcp_status.bat`; usar `20_` para o novo script.)

## 3. Plano de execução (fases ordenadas)

### Fase 1 — Experimento E1: completar o 595 no offset certo
1. Editar `SIF.cpp`, branch `request-595-complete`: além do que já faz, escrever `1` em `payload/struct 0x620D50 + 0x24` quando o request for o 595 (gatilho real: chamada com `payloadAddr == 0x00620D50` OU manter o gatilho atual e adicionar a escrita em `0x00620D74`). Manter env-gated `MC3_SIF_EXPERIMENT_595_COMPLETE`.
2. `03_build_ps2recomp.bat` → `10_link_partial_runner.bat fast` → `15_auto_boot_probe.bat 8 595`.
3. **Critério de sucesso**: trace mostra `fun_00541760:return v0=0x1` e `fbbc=0x0`; PC estável sai de `0x245720`.

### Fase 2 — Se PollSema(fba8) ainda falhar
- O caminho A exige a semáfora `fba8` disponível. Verificar no trace quem cria/sinaliza `fba8` (buscar `fba8` nos logs; criador provável no init de `sub_005420C0`/`FUN_00541be8`).
- Se ninguém sinaliza: usar PCSX2-MCP (Fase 4) para ver o valor real de `0x61FBA8` e o estado da sema no mesmo ponto do boot. **Não** sinalizar às cegas.

### Fase 3 — Depois que FUN_005422c8 retornar 1
- O loop `0x245718/0x245720` sai; esperar novos bloqueios na cadeia de render (`sub_00549488`, DMA/GIF). Sintoma bom = `gif`/`gsw` > 0 nos counters.
- Repetir o método: probe → identificar PC estável → ler o .cpp gerado → hipótese mínima → experimento env-gated → validar.

### Fase 4 — Validação live com PCSX2-MCP (paralela, read-only)
- Setup já funciona (checkpoint 2026-07-05): DebugServer porta `21512` OK.
- Com MC3 no title screen real: pausar e ler `0x61FB90, 0x61FB9C, 0x61FBA8, 0x61FBB4, 0x61FBB8, 0x61FBBC, 0x61FBD8, 0x620D50..0x620D80, 0x621600`.
- Comparar com o trace do recomp. Qualquer shim só vira permanente se bater com o valor live.
- Wrappers: `16_pcsx2_mcp_status.bat`, `17_live_trace_handoff.bat current`, `18_compare_live_trace.bat`.

### Fase 5 — Promoção e limpeza
- Quando o menu renderizar: promover apenas os experimentos comprovados live de env-gated para default (um por commit), atualizar `BRAIN.md` com checkpoint, manter os demais desligados.

## 4. Comandos canônicos

```bat
:: estado geral
00_status.bat
:: build runtime + relink rápido
03_build_ps2recomp.bat
10_link_partial_runner.bat fast
:: probe padrão atual (com todos os experimentos da linha 595)
15_auto_boot_probe.bat 8 595
:: trace bruto
type work\logs\14_run_boot_trace.log
:: status resumido
type work\boot_probe\latest_status.md
```

## 5. Globals do gate (dicionário)

| Endereço | Apelido | Papel observado |
|---|---|---|
| 0x0061FB90 | fb90 | contador/fila de produção IOP; consumidor exige > 0; produtor: `FUN_00541be8` store em `0x541de4` |
| 0x0061FB9C | fb9c | request kind atual (recebe a0 de FUN_00541760) |
| 0x0061FBA8 | fba8 | sid da semáfora de mutex do canal SIF |
| 0x0061FBB4/B8/D8 | fbb4/fbb8/fbd8 | flags de estado do canal (bit0 de fbb8 = ocupado) |
| 0x0061FBBC | fbbc | flag init do subsistema; `<0` = precisa do request 595; `0` = pronto |
| 0x0061FC80 | fc80 | struct do request montado por FUN_005422c8 |
| 0x00620D50 | d50 | struct do request 595; **completion lida em +0x24 (0x620D74)** |
| 0x00620D80 | d80 | payload do request 592 (slot word +0xC = 0xFE) |
| 0x00621600 | — | resultado do request 59C (escrever 1) |

## 6. O que NÃO fazer

- Não recompilar tudo monolítico (regra do BRAIN.md).
- Não registrar todo `ctx->pc` como alias (crash conhecido).
- Não sinalizar semáforos sem provar o produtor.
- Não promover experimentos sem evidência live.
- Não editar arquivos gerados exceto para adicionar resume labels pontuais (padrão já usado em `0x42eb48/0x42eb90/0x540838`).
