# Plano atualizado — 2026-08-17 — o alpha 102404 muda o jogo

Autor: Claude (Fable 5). Contexto de entrada: `PS2_PROJECT_STATE.md` (checkpoint 13/08),
`docs\ROOT_CAUSE_IOP_RESPONSE_LAYER_2026-08-13.md`, `docs\HANDOFF_2026-08-13_IO_COMPLETION_SID5.md`.

## Veredito sobre "recomeçar do zero"

**Não recomece do zero.** O código EE gerado pelo PS2Recomp não é o gargalo — os três bloqueios
provados são todos do *runtime e do processo*, e um recomeço reproduziria exatamente as mesmas paredes:

1. **Camada de resposta SIF/IOP é uma lista de endereços fixos, não um protocolo** (causa-raiz 13/08).
   Foi isso que transformou os últimos 2 meses em whack-a-mole: cada experimento fixa um buffer visto
   num trace, o PC anda, o próximo buffer trava.
2. **Scheduler não-determinístico** (threads guest = `std::thread` reais). Medição vira ruído; o
   Handoff A continua aberto.
3. **Nenhum caminho fechado até um frame** (`gif=0 gsw=0` em 100% de todas as corridas da história
   do projeto).

O que *muda* é a estratégia: parar de escavar o retail às cegas. O alpha extraído hoje resolve isso.

## O achado — símbolos completos no alpha 102404

O ISO do alpha (`MIDNIGHT CLUB 3 DUB PS2 ALPHA BUILD 102404.ISO`) contém, na raiz:

| Arquivo | Tamanho | O que é |
|---|---|---|
| `MC.MAP` | 3,0 MB | **Linker map completo**: endereço + tamanho + nome C++ demanglado + objeto de origem, ~19.250 símbolos de função |
| `MC.SYM` | 1,4 MB | Tabela de símbolos complementar |
| `SLUS_123.45` | 4,9 MB | ELF do alpha |
| `SYSTEM\*.IRX` | — | Módulos IOP nomeados (SCREAM.IRX = áudio, MCMAN, PADMAN, SIO2MAN…) |

Já extraídos para a pasta do alpha. Amostras que batem direto nos bloqueios atuais:

- `coreFileWaitCreateSema(void)` @ 0x3689f8 e `coreFileSignalSema(int)` @ 0x368a40 — **o par
  criador/produtor de semáforo de completion de arquivo que o handoff sid=5 procura às cegas está
  nomeado**. O engine é o AGE (Angel Game Engine, `c:\soft\age\src\...`), com `coreFileMethods`
  (a vtable de open/close/read/seek — o "ABI físico" 0x3984C0/0x3986D8 do retail), `Stream`,
  `zipFile` (explica as menções a `texture.zip`) e `datAssetManager*` (a "frente provider" inteira).
- `mcAudioRpcMgr` / `sndRpcManager` / `sndRpcData` — o lado cliente do RPC de áudio (servidor:
  `SCREAM.IRX`). Os structs de request/response dos requests misteriosos (0x1 com 0x90 bytes, 0xFF,
  0x9, 0x22) são legíveis no código cliente nomeado.
- `mcGame::Execute`, `mcGame::PreDraw`, `ipcCreateSema/WaitSema/SignalSema` — o boot path inteiro
  com nome.

Retail (abr/2005) vs alpha (out/2004) = ~6 meses. A esmagadora maioria das funções de
engine/infra (AGE, coreFile, ipc, snd, dat) será casável por diffing binário.

## Fase 0 — Portar os símbolos (1–2 semanas; desbloqueia tudo)

1. **Importar `MC.MAP` no Ghidra sobre o ELF do alpha.** O formato é fixo
   (`addr size 0 nome`), um script Python/Java de import resolve. Aplicar também `MC.SYM` se
   agregar algo além do map.
2. **Diffar alpha → retail** (`SLUS_213.55`) com Ghidra Version Tracking (já temos Ghidra 11.4/12.1
   no repo) ou Diaphora/BinDiff. Propagar nomes para o retail. Meta: ≥60% das funções do boot path
   nomeadas.
3. **Responder as perguntas abertas com os nomes:**
   - `sub_00398B18`/`sub_00398A60` (retail) = qual wrapper `coreFile*`/`ipc*`? Quem chama
     `coreFileSignalSema` no alpha → onde está esse chamador no retail? **Isso fecha a Tarefa 1 do
     handoff sid=5 sem chute.**
   - `sub_004F9A68`/`sub_004FAED8`/flag `0x619F40` = quais métodos de `datAssetManager*`?
   - Requests SIF 0x1/0xFF/0x9/0x22 = quais chamadas cliente nomeadas, com quais structs?
4. Entregável: `docs\SYMBOL_PORT_REPORT.md` — tabela retail-addr → nome, cobertura por região, e a
   resposta do sid=5.

**Decisão condicionada ao resultado:** se o casamento alpha→retail vier bom (≥60% no boot path),
o alvo do recomp continua o retail. Se vier ruim, **trocar o alvo do recomp para o ELF do alpha**
é o "recomeço" que faz sentido: 19k funções com nome e boundaries perfeitos (endereço+tamanho no
map) tornam recomp, stubs e debugging incomparavelmente mais tratáveis; prova-se o pipeline até o
frame no alpha e porta-se para o retail depois. Custos conhecidos do alpha: proteção de dongle
(patch conhecido da cena) e instabilidade própria do build.

## Fase 1 — Protocolo SIF de verdade (mata a classe de bug)

Regra nova, sem exceção: **nenhum novo `else if` com `payloadAddr` fixo, nenhum novo env-gate
experimental de SIF.** A causa-raiz de 13/08 provou que esse padrão não converge.

1. Com os nomes da Fase 0, especificar por servidor RPC o protocolo real (requestId → struct de
   request → struct de response), começando pelo servidor que bloqueia o boot (cdvd/fileio →
   completion do `coreFile`), depois SCREAM (áudio), pad, mc.
2. Usar o PCSX2 como oráculo: capturar o buffer de resposta real para `request=0x1 size=0x90` e
   `request=0xFF size=0x8` (fluxo em `docs\PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md`) e validar
   o spec contra a captura.
3. Reescrever a camada em `SIF.cpp`: handler genérico por `(servidor, requestId)` que escreve a
   struct de resposta completa **no endereço que veio no request** — o payload nunca mais é chave.
4. Apagar os env-gates experimentais atuais; o caminho novo vira o padrão.
5. Plano B permanente: se um servidor se provar intratável em HLE, avaliar LLE do IOP (interpretador
   R3000 rodando os `.IRX` reais da ISO). É a solução definitiva da classe, mas é um projeto de
   runtime grande — só entrar nele com evidência de que o HLE não fecha.

Aceite: boot com binário limpo não descarta **nenhuma** resposta IOP
(`mc3-iop-response-unhandled` = 0 no trace), e `sid=5` é sinalizado pelo produtor identificado.

## Fase 2 — Determinismo (Handoff A, agora com solução definida)

Serializar as threads guest num scheduler cooperativo (uma thread host + troca de contexto em
`WaitSema`/syscalls bloqueantes, ou fibers). É mudança arquitetural no `ps2xRuntime`, já
diagnosticada em 13/08 como a única saída real. Aceite: `21_probe_repeat.bat 10` → **1** Stable PC
distinto, 10/10.

Ordem deliberada: Fase 2 depois da Fase 1 porque o protocolo SIF correto muda o comportamento das
threads; serializar antes seria calibrar determinismo sobre um boot ainda quebrado. Se a Fase 1
empacar por medição, adiantar a Fase 2.

## Fase 3 — Primeiro frame

O runtime já tem peças (`ps2_vu1.cpp`, `ps2_vif1_interpreter.cpp`, `ps2_gs_rasterizer.cpp`,
`ps2_gif_arbiter.cpp`). Auditar o que existe vs. o que o MC3 usa no caminho
VIF1→VU1→GIF→GS do primeiro frame (com `mcGame::PreDraw` nomeado, dá para ler o que o jogo faz).
Vitória continua sendo a mesma e única: `gif>0`/`gsw>0` **e** dump de framebuffer visível.

## Higiene (fazer já, custa uma hora)

1. **O repo não existe**: `.git\` está vazio. `git init`, `.gitignore` para ISOs/7z/zips/`work\`
   pesado, commit de `docs\`, scripts `.bat`, `tools\`, e do fork do PS2Recomp (submodule ou
   subtree). Meses de trabalho estão sem nenhum backup versionado.
2. `cmake` fora do PATH (pendência de 13/08) — resolver antes da Fase 1, que exige rebuild do runtime.
3. Regras que continuam valendo: N≥10 probes por medição (`MC3_DETERMINISTIC=1`,
   `MC3_DISPATCH_BUDGET=25000`), nunca injetar `SignalSema`, evidência antes de patch, sem valor
   plausível inventado.

## Por que este plano destrava o que os últimos meses não destravaram

Os meses de trava tiveram um padrão: engenharia reversa às cegas do retail, um endereço por vez,
com medição ruidosa. As três frentes deste plano atacam exatamente isso: a Fase 0 troca "adivinhar
o que `sub_005422c8` faz" por "ler o nome e o código cliente"; a Fase 1 troca o whack-a-mole de
buffers por protocolo; a Fase 2 troca ruído por medição. Nenhuma delas exige jogar fora o que existe.
