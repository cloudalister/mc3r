# HANDOFF — retomada em sessão nova — 2026-08-31

## Onde estamos

Recompilação estática nativa de Midnight Club 3: DUB Edition Remix (PS2, retail
`SLUS_213.55`), em `E:\Games\Emuladores\Sony\mc3recomp`.

O jogo boota, passa da tela legal, renderiza e desenha modelos com esqueleto. **Não chega
ao menu.** A causa disso deixou de ser mistério nesta sessão: em parte das execuções ele
trava na tela de carregamento esperando um recurso que nunca termina de chegar.

## O achado principal: o não-determinismo tem endereço

O projeto convivia desde agosto com "o mesmo binário dá resultados diferentes". Isso agora
está caracterizado e localizado.

**Não é dispersão, são desfechos discretos.** Sete execuções do mesmo binário produzem
contadores idênticos até o último dígito dentro de cada ramo. Em 2026-08-30 o desfecho
ruim saía em 5 de 7; depois das correções COP1, o bom passou a sair em 6 de 7.

**A bifurcação é uma chamada só**, e a cadeia inteira está nomeada:

```
mcFlash::Update(bool, bool, float)                    0x320B38
  └ mcFlash::UpdateLoading(bool)                      0x320C60
      └ datPaging::EndStream(datStreamerInfo&, bool)  0x42E8A0
          └ datRscBuilder::EndStream(...)             0x430C90
              └ datStreamer::Close(unsigned int)      0x4323E8
                  └ ipcSleep(unsigned int)            0x398C60
```

`datStreamer::Close` faz `while (entry->campo_0C != 0) ipcSleep(10);` — o campo fica em
`0x6771fc`. No desfecho ruim ele nunca zera.

Quem deveria zerá-lo é o worker de streaming (`FUN_00431e00`, sem nome no alpha). Ele
desenfileira **duas** requisições nos dois desfechos e conclui só a primeira no ruim:

| marcador | ruim (3 execuções) | bom (2 execuções) |
|---|---:|---:|
| `mc3-datstreamer-read` | 2 | 2 |
| `mc3-streamer-worker-dequeue` | 2 | 2 |
| **`mc3-streamer-worker-done`** | **1** | **2** |
| `mc3-streamer-worker-park` | 2 | 3 |

A entrada que o desfecho bom conclui no `done 2` — `0x006771f0` — é exatamente a que a
outra thread espera. Separação perfeita em 5 execuções.

O que nunca roda do outro lado: `uiMaster::Update` (0x4225D8), `mcMenuShell::AnyListsActive`
(0x33A710), `mcMenuShell::ChangeState` (0x339278), e toda a iluminação
(`mcLight::GetColor`, 0x259D60).

## Critério barato para classificar uma execução

**Se `busy=0x2` aparece no log, o desfecho é bom.** Separação perfeita em 5 de 5. Não
precisa mais rodar 30 minutos e contar primitivas para saber em que ramo caiu.

Cuidado: o número de iterações do laço **não** serve — uma execução ruim girou 15 vezes e
uma boa girou 32.

## O que procurar na próxima sessão, em ordem

1. **Onde o worker de streaming trava entre `dequeue` e `done`.** É a pergunta aberta.
   Sabe-se que ele entra, e que não emite `done` nem `park` depois. As funções que ele
   chama nesse trecho: `ipcTime` (7x), `ipcSleep` (2x), `datStreamer::ValidateHandle`,
   `ipcSignalSema`, e três sem nome (`0x398788`, `0x3986D8`, `0x245680`).

   **Hipótese já descartada, não repetir:** o laço de transferência em `0x431f98`
   (`s1 -= s0; bnez s1`) não é o culpado — sonda ali dispara **zero** vezes nos dois
   desfechos. Aquele caminho não é executado.

   **Hipótese não testada, plausível:** a thread do worker pode simplesmente não estar
   sendo escalonada depois do dequeue. Isso seria problema de scheduler, não de lógica do
   jogo. Distinguir é barato: sonda de entrada/saída em cada uma das chamadas acima.

2. **Referência visual.** Rodar o mesmo ELF no PCSX2, chegar ao mesmo ponto e capturar o
   frame. Hoje não há como saber se o que o recompilador desenha está certo — o dump
   capturado (`work/captures/frame_day20260830_cop1fix.png`) não é cena reconhecível: um
   facho amarelo com estouro magenta sobre bandas diagonais.

3. **Modelo `ps2Float` completo.** Decisão do usuário, ainda em aberto. A FPU do R5900 não
   tem NaN nem infinito; nesta sessão foram fechadas três portas (raiz de negativo,
   `rsqrt`, divisão por zero), mas a classe continua aberta. Custo: muda toda operação de
   ponto flutuante e invalida comparação com tudo já medido.

4. **`DrawSkinned` caiu de 18 para 12** com as correções COP1. Sem explicação.

5. **23,6% do corpus é tradução duplicada** (3.712 de 15.757 funções, 990,6 KB). As duas
   cópias executam. Se contribui para o não-determinismo é hipótese não medida.

## Correções entregues nesta sessão

- **`RSQRT.S`** — 450 dos 451 sítios do binário calculavam `1.0f / sqrt(fs)` em vez de
  `fs / sqrt(ft)`. O gerador estava certo desde `726f311` (29/08); o corpus é de 24/08 e a
  correção nunca tinha sido propagada.
- **Correção estreita da FPU** — `SQRT.S` de negativo devolve `sqrt(|x|)`, `RSQRT.S` idem,
  divisão por zero satura em ±Fmax em vez de infinito.
- **Acumulador do COP1** saiu de `ctx->f[31]` (que é o `$f31` do jogo) para campo próprio.
- **Auditoria COP1 fechada por evidência**: em 303.152 instruções, o `sqrt.s` de 30/08 era
  mesmo o único campo de operando errado.
- **Suíte em 309/309**, com 6 testes novos cobrindo as três semânticas de FPU e o
  acumulador.
- **Dois defeitos de ferramenta de build**, ambos capazes de produzir binário
  silenciosamente inconsistente — ver a seção de armadilhas.

Efeito medido: o desfecho bom passou de 1/7 para 6/7, e o teto dele subiu de 1.004.584
para 1.173.155 primitivas (+16,8%) e de 1,09 para 1,42 bilhão de pixels (+30,7%). **O
efeito não está isolado** — três mudanças entraram no mesmo binário.

## Cinco hipóteses que morreram, para não refazer

1. **O ganho de +43%/+323% da correção do `sqrt.s` (30/08).** Não existiu. A execução
   "antes" caiu no ramo ruim e a "depois" no bom, e os dois binários têm os dois ramos.
2. **Livelock em `FUN_0054cb58`.** Duas threads girando em caminhada de lista encadeada.
   Instrumentado com detecção de ciclo: em quatro execuções do desfecho ruim a sonda não
   disparou uma vez. O laço nem é alcançado. A leitura vinha de uma única execução.
3. **O blend de câmera não converge.** Roda igual nos dois desfechos. A diferença é só que
   no ruim ele é a única coisa acontecendo.
4. **O portão do `mcMenuShell::ChangeState`.** Três condições (`estado==3` ou `campo4==7`,
   depois `campo_E0 != 1`). Nenhuma é avaliada no desfecho ruim — a função nem é entrada.
5. **O laço de transferência do worker em `0x431f98`.** Sonda dispara zero vezes nos dois
   desfechos; o caminho não é executado.

## Armadilhas que custaram caro, todas específicas deste projeto

1. **Os nomes reais estão na coluna 4 do `retail_symbol_port.csv` (`alpha_name`), não na
   2 (`retail_old_name`).** A coluna 2 é só o `FUN_` do Ghidra. Passei a madrugada
   chamando `datStreamer::Close` de `func_4323E8`. Das 8.815 linhas, só 42 têm nome na
   coluna 2 — e todas de kernel.

2. **Instrumentação com teto mente por omissão.** `mcFlash::Update` tinha
   `if (emitCount >= 64) return;`, esgotado antes da chamada que interessava. Os dois
   desfechos produziam 64 amostras idênticas terminando no mesmo estágio, o que lia como
   "a função se comporta igual". Levantado para 4000 e a diferença apareceu na primeira
   execução. **Vale auditar as outras sondas do projeto pelo mesmo critério.**

3. **Instrumentar uma instrução não garante observá-la.** O runtime retoma a thread no
   meio do corpo da função, por PC. Sondas em `0x33acac` ficaram mudas em execuções que
   comprovadamente executam a chamada quatro instruções depois, porque o guest reentrava
   em `label_33accc`, entre as duas. Sonda confiável é em entrada de função ou em ponto de
   junção.

4. **23,6% das funções têm tradução duplicada**, então sondar uma cópia pode não sondar o
   código que roda. Instrumentar as duas, com sufixo distinto.

5. **`find_stale.py` decidia obsolescência como `hash_ok or o_mtime >= cpp_mtime`.** O
   `or` anulava a `COMPILE_KEY`: com dois headers alterados, 14.726 de 15.831 objetos
   passavam como OK. Corrigido em `7904c16`.

6. **O link não conferia falha de compilação.** `parallel_compile.py` deixa o `.o` antigo
   no lugar quando falha, e o link seguia, produzindo exe que mistura objetos de duas
   builds. Corrigido em `73c88d2`.

7. **Modo janela roda 8,6× mais devagar que headless** (207 s de relógio para 24 s de
   jogo). Comparação temporal entre os dois modos é inválida. Os contadores de desfecho
   não mudam — são função do ramo.

## Ferramentas novas em `work/scratch/`

- `Run-DayBattery.ps1` — bateria não supervisionada, N execuções + dump com repetição +
  phase timing, relatório reescrito a cada execução
- `Run-NightPipeline.ps1` — espera bateria, reconstrói lib, recompila corpus, relinka,
  roda segunda bateria. Guardas que abortam alto em cada etapa
- `Catch-GateV2.ps1` — bateria curta que para com N execuções de cada ramo
- `audit_cop1_operands.py`, `audit_cop1_acc_collision.py`, `audit_corpus_vs_generator.py`,
  `audit_overlapping_functions.py`
- `fix_cop1_corpus.py` — propagação ao corpus por codificação de 32 bits, idempotente
- `find_divergence.py` — comparação de eventos entre execuções

## Estado do repositório

13 commits, de `67fab96` a `f9c9425`. Submódulo em `2fe5463`. Árvore limpa. **Nada foi
enviado ao remoto** — regra do projeto.

## Regras do projeto que não se negociam

1. Despacho SIF por (server, fno) — `payloadAddr` nunca é chave.
2. **Nunca injetar `SignalSema`** — conclusão só pelo produtor legítimo. Isto se aplica
   diretamente ao `busy` em `0x6771fc`: zerá-lo na marra destravaria a thread e produziria
   um jogo que parece funcionar escondendo o defeito.
3. Nada de chutar bytes — decomp nomeado ou captura; incerto = TODO + neutro.
4. Sem env-gate experimental novo; scheduler da Fase 2 congelado.
5. Vitória visual = `gifPackets(total) > 0` E `gsPrims > 0` + framebuffer.
6. Exe relinkado tem de ser mais novo que a lib.
7. Executor só faz commit local — **sem push**.
8. Nada do jogo no repo público (ISO, assets, MC.MAP/SYM, código gerado do ELF, decomp).
9. Usar `retail_addr` (primeira coluna) em `retail_symbol_port.csv`, nunca `alpha_addr`.
   **Para nome, usar `alpha_name` (quarta coluna).**

## Preferência de trabalho do usuário

Não pedir sinal verde a cada passo investigativo. Perguntar só sobre duração de bateria e
sobre decisões que mudam escopo. Documentar e commitar sem perguntar.
