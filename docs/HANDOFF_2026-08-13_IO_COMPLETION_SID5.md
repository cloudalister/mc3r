# Handoff — completion de I/O de arquivo nunca sinalizada (`sid=5`) — 2026-08-13

**Prioridade: alta.** É o bloqueio determinístico mais próximo do boot com binário limpo, e o primeiro em muito tempo que é reprodutível em 9/10 corridas.

## Contexto que você precisa saber antes

Duas correções de higiene aconteceram hoje e mudam a interpretação de tudo que veio antes:

1. **O binário estava contaminado.** O exe usado de 09/08 até hoje continha o experimento rejeitado `MC3_EXPERIMENT_OPCODE2B_HOST0_RESPONSE`. Foi purgado (exe limpo: `13/08 03:01`). **Não confie em nenhuma medição feita entre 09/08 e 13/08.**
2. **O checkout mudou de pasta:** agora é `<project-root>`. Docs e logs antigos citam o caminho velho.

## Ambiente — pendências antes da Tarefa 2

- **`cmake` não está no PATH nem em `Program Files`/`msys64`.** Hoje isso não bloqueou nada porque a lib já estava limpa (só leitura, sem rebuild). Mas a Tarefa 2 provavelmente vai exigir recompilar o runtime (`PS2Recomp\ps2xRuntime`) para instrumentar ou corrigir o wrapper de I/O — resolver o PATH/instalação do cmake **antes** de começar essa tarefa, não durante.
- **Checkout confirmado em `<project-root>`** (ver item acima) — qualquer script ou doc antigo apontando para o caminho velho precisa ser atualizado ao usar.

Configuração de medição a usar sempre (calibrada hoje, 10/10 corridas válidas):

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=25000"
```

Budget `100000` **não** serve: 5/10 corridas dão timeout sem atingir o marcador.

## O bloqueio, com a evidência

Com binário limpo e budget 25k, **todas** as 10 corridas classificam `semaphore`, e 9/10 param na mesma região:

| Stable PC | Ocorrências | Função |
|---|---:|---|
| `0x54a0ac` | 5 | `sub_0054A080_0x54a080` |
| `0x54a188` | 2 | — |
| `0x54a3c4` | 2 | — |
| `0x3985d8` | 1 | — |

Cadeia do bloqueio:

- Espera: `[boot-trace:WaitSema:block] tid=3 sid=5 count=0 waiters=0 pc=0x5469e0 ra=0x398b28`
- `ra=0x398b28` → `work\generated\ghidra\sub_00398B18_0x398b18.cpp`
- Criação: `[boot-trace:CreateSema] tid=1 id=5 init=0 max=16 attr=0x0 ... ra=0x398a98`
- **Sinal: nunca.** O trace tem 19 `SignalSema`, para sids `7, 8, 10, 16, 29, 37, 40`. Nenhum é `5`.

`init=0` + espera imediata = semáforo de **completion**. Ele é criado dentro do módulo de I/O físico de arquivo — a mesma vizinhança do ABI já documentado no lote 20: open `0x3984C0`, close `0x398610`, read `0x3986D8`, seek `0x398730`, stat `0x398788`.

**Leitura:** o módulo de arquivo emite uma operação e dorme esperando a conclusão. A conclusão nunca é produzida. Isso reposiciona a frente provider: o problema imediato não é "o global `0x619F44` está vazio", é que **o caminho de completion de I/O não existe no runtime**.

## Regra que não se negocia

**Não injetar `SignalSema(5)`.** A investigação do sema 17 (`docs\SEMA_17_INVESTIGATION_2026-08-28.md` e o handoff correspondente) estabeleceu que sinalizar à força esconde a causa, e naquele caso o produtor legítimo já existia no próprio binário. Repita o método: ache o produtor antes de mexer.

## Tarefa 1 — Mapear o produtor legítimo (só leitura)

1. Ler `sub_00398B18_0x398b18.cpp` inteiro e a função que contém `0x398a98` (a criadora do semáforo). Determinar: qual operação é emitida entre criar o semáforo e esperar nele.
2. Achar quem, no binário, deveria sinalizar esse semáforo. Candidatos por ordem: callback de conclusão registrado junto com a operação; handler SIF/IOP de resposta; drain de fila de comandos; thread de I/O dedicada.
3. Verificar se o `sid` é passado adiante (guardado em struct, passado como argumento) — o sinalizador legítimo precisa recebê-lo de algum lugar. Rastrear esse caminho é o que identifica o produtor.

**Entregável:** `docs\IO_COMPLETION_SID5_PRODUCER.md` — função produtora com endereço, ou a afirmação explícita de que nenhum produtor existe no código gerado (isso também é um achado: significa que a conclusão vinha do IOP e o runtime precisa emulá-la).

## Tarefa 2 — Confirmar o que o runtime implementa

O módulo de arquivo do runtime (`PS2Recomp\ps2xRuntime\src\lib`) implementa as operações de arquivo de forma síncrona no host? Se sim, a operação já terminou quando o guest vai esperar — e o semáforo deveria ser sinalizado imediatamente pelo próprio wrapper de I/O. Se o wrapper cumpre a operação mas não sinaliza a conclusão que o guest registrou, esse é o bug, e ele é do runtime, não do jogo.

**Entregável:** qual chamada de host atende `0x3986D8`/`0x3984C0` hoje, e se ela tem qualquer noção do semáforo de conclusão.

## Tarefa 3 — Comparar com PCSX2 real (se houver sessão)

No jogo real, no mesmo ponto: quem sinaliza esse semáforo e em que contexto (thread? handler de interrupção?). Fluxo de abertura/captura em `docs\PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md`. Sem sessão disponível, registrar como pendência — **não preencher com valor plausível**.

## Aceite

Um experimento só é aceitável depois das Tarefas 1 e 2. Quando houver, o formato é env-gated com rollback por desligar a variável, e a medição é:

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=25000"
21_probe_repeat.bat 10 595 <label>
```

Critério: `sid=5` passa a receber sinal de um produtor identificado, e a distribuição de Stable PC sai da região `0x54a0xx`. **`gif>0` ou `gsw>0` continua sendo o único sinal de vitória visual** — e nada disso prova frame sem o Cloud ver na tela.

## Estado de hoje, sem maquiagem

`gif=0 gsw=0` em **20/20** corridas de hoje. Nenhum frame. O trabalho acima é sobre destravar o bloqueio determinístico mais próximo do boot — não há, ainda, nenhuma evidência de progresso visual.

## Contexto: por que o Handoff A (determinismo) segue aberto

O gate por budget foi calibrado hoje mas **não** entrega determinismo: 4 Stable PCs distintos em 10 corridas com budget 25k (7 com 100k). O budget corrige a fronteira de amostragem; a variação restante vem do racing entre threads guest, que são `std::thread` reais do host. Determinismo pleno exige serializar a execução dessas threads — mudança arquitetural, não ajuste de script.

Isso **não** bloqueia esta tarefa: 9/10 corridas convergem para a mesma região e o `sid=5` sem sinal é 10/10. A evidência é forte o suficiente para trabalhar.
