# Handoff — entregar `-skipintro` e `-garage` ao parser de argumentos do próprio jogo

## Contexto mínimo

O objetivo do projeto agora é alcançar o mundo 3D. O jogo **já tem** um atalho legítimo
próprio: um parser de linha de comando que lê globais `PARAM_skipintro`, `PARAM_garage`,
`PARAM_qload`, `PARAM_raceed`, `PARAM_loadrecent`, `PARAM_menuDebug`. Usar esse caminho é
muito melhor que forçar Start ou inventar estado — é a Rockstar que escreveu o atalho.

Provado nesta sessão:

- `datArgParser::Init(int, char**)` — retail `0x00428AC0` — **sobreviveu no binário retail e
  está registrada** (batch_0036). O mecanismo existe.
- `PS2Recomp\ps2xRuntime\src\main.cpp` usa `argv[1]` do host apenas como caminho do ELF. Não
  há nenhum código em `ps2xRuntime\src\lib` que repasse argv extra ao guest (grep por `argv[`
  fora de `main.cpp` = zero ocorrências).

**LEIA `docs/RESULT_BOOT_ARGS_V1.md` ANTES DE QUALQUER COISA.** Ele já decodificou o
mecanismo de boot args e evita que você refaça o trabalho:

1. O `_start`/crt0 **não** usa `$a0`/`$a1` como `argc`/`argv` — esses registradores são
   explicitamente zerados no início do `_start`.
2. O crt0 consulta um **ponteiro global em `0x614400`**, que o kernel real (devkit) popularia
   antes do entry rodar.
3. Se `0x614400` for zero — que é o caso hoje —, o crt0 cai num **bloco de argumentos
   compilado no próprio ELF**, cujo campo que importa mora em `0x617F84`.
4. `0x617F84` já contém `"cdrom0:\"` e **funciona**; o loader de `PT_LOAD` entrega isso
   corretamente e nada o sobrescreve.

Ou seja: o caminho retail já funciona para o caso "sem argumentos". O que falta é o caminho
de **override**, que é exatamente onde `-skipintro` e `-garage` entrariam.

## Objetivo

Fazer com que `mc3_partial.exe <elf> -skipintro -garage` resulte em `datArgParser::Init`
recebendo esses argumentos pelo mecanismo real do crt0, e as globais `PARAM_skipintro` /
`PARAM_garage` ficarem verdadeiras no guest — sem inventar estado de jogo.

## Escopo

### Fazer

1. **Decodificar o layout exato do bloco apontado por `0x614400`**, lendo o decomp do crt0 no
   código gerado. Você precisa saber, com evidência linha-a-linha: quantos campos, onde fica
   `argc`, onde fica o vetor de ponteiros, se as strings são inline ou referenciadas, e o
   alinhamento. `RESULT_BOOT_ARGS_V1.md` diz que o layout além de `argc`/ponteiro-de-string
   **não** foi decodificado — essa é a lacuna a fechar.
2. **Popular esse bloco no runtime**, antes do salto para o entry, com os argumentos extras
   recebidos do host (`argv[2]` em diante de `main.cpp`). Escrever as strings em memória guest
   válida e montar o vetor conforme o layout provado no passo 1.
3. **Repassar argv extra** de `main.cpp` até o ponto de setup do entry.
4. **Provar que chegou**: trace passivo na entrada de `datArgParser::Init` (`0x00428AC0`)
   mostrando `argc` e as strings recebidas. Contador limitado, `fprintf` para stderr.
5. Testes na suíte cobrindo a montagem do bloco (layout, alinhamento, terminação).

### NÃO fazer

- **NÃO adivinhe o layout do bloco.** Se o decomp do crt0 não provar um campo, pare e
  documente. A regra "sem chute de bytes" vale aqui integralmente. Um bloco malformado vai
  corromper o boot inteiro de forma difícil de diagnosticar.
- **NÃO** escreva diretamente nas globais `PARAM_*`. Isso seria falsificar estado. O parser do
  jogo tem que rodar e decidir sozinho.
- **NÃO** mexa em scheduler, dispatcher, SIF, VIF0/VIF1, GS.
- **NÃO** crie env-gate (`MC3_EXPERIMENT_*`). Argumentos vêm por argv do host, que é o
  mecanismo natural.
- **NÃO** ataque as regiões não recompiladas (`0x24A368`, `0x5BB170/78`, `0x5BB220`,
  `0x5BD030`). Outro lote.

## COORDENAÇÃO — leia antes de rodar qualquer coisa

**Há uma recompilação completa de 15512 objetos em `-O2` rodando agora** (iniciada 2026-08-29
~06:06, estimativa ~100 min), seguida de relink. Enquanto ela roda:

- **NÃO** rode `tools/parallel_compile.py`, `tools/find_stale.py`, `10_link_partial_runner.bat`
  nem `mc3_partial.exe`. Você corromperia o manifesto de hash e o link em andamento.
- Trabalhe em leitura, decodificação do layout e edição de código.
- Antes de compilar/linkar/medir, confirme que terminou: nenhum processo `cc1plus`/`g++`
  ativo **e** `work/link/partial/mc3_partial.exe` com timestamp posterior a
  `PS2Recomp/out/build/ps2xRuntime/libps2_runtime.a`.

Contexto de build que mudou hoje (não reverta):

- Código gerado agora compila com `-O2 -fno-strict-aliasing`; `COMPILE_KEY` foi bumpada para
  `g++-cxx20-O2-fnostrictaliasing-msse4.1-wall-generated-ghidra-kernel-v2` em
  `tools/parallel_compile.py` **e** `tools/find_stale.py` (as duas têm que casar).
- CMake em `RelWithDebInfo` (`-O2 -g -DNDEBUG`).
- `PS2Recomp/CMakeLists.txt` ganhou branch x86-64 com `-msse4.1`, sem o qual build otimizado
  não linka (`_mm_extract_epi32` é `always_inline`).
- Suíte passou **300/300** sob `-O2`.
- O `ps2x_tests.exe` só roda com `C:\msys64\ucrt64\bin` no `PATH`; sem isso morre com
  `0xC0000139` (entrypoint not found), que parece falha de teste mas é DLL.

## Fontes de verdade (em ordem)

1. `docs/RESULT_BOOT_ARGS_V1.md` — o que já foi decodificado.
2. Decomp do crt0/`_start` no código gerado (`work/generated/ghidra/`).
3. `work/exports/retail_symbol_port.csv` para nomes.

**ATENÇÃO CRÍTICA sobre o CSV**: as colunas são
`retail_addr,retail_old_name,alpha_addr,alpha_name,...`. Use **sempre** `retail_addr`, a
primeira. Já houve incidente grave neste projeto por instrumentar endereços da coluna
`alpha_addr`, que pertencem a outro build e são funções diferentes no retail — ver
`docs/RESULT_ALPHA_GFX_TRACE_REMOVAL_2026-08-29.md`.

## Regras não-negociáveis

1. Nunca injetar `SignalSema`.
2. Sem chute de bytes — decomp nomeado ou captura; incerto = TODO + neutro.
3. Sem env-gate experimental novo; scheduler congelado.
4. Vitória visual = `gifPackets(total) > 0` **e** `gsPrims > 0` + framebuffer.
5. Exe relinkado tem que ser mais novo que a lib.
6. Commits locais, **sem push**.

## Validação

1. Suíte completa (CWD = `PS2Recomp\out\build`, com o PATH do MSYS2), esperando 300/300 +
   os testes novos.
2. Relink `fast`, exe mais novo que a lib, manifesto de stubs só com cabeçalho.
3. Corrida headless com os argumentos, provando pelo trace que `datArgParser::Init` recebeu
   `argc` e as strings.
4. Corrida headless **sem** os argumentos, provando que o comportamento anterior não mudou.
   Essa é a guarda de regressão mais importante: o boot atual funciona e não pode quebrar.

## Aceite

Frase binária: **com `-skipintro -garage` na linha de comando, o trace na entrada de
`0x00428AC0` mostra esses argumentos, e a corrida sem argumentos continua alcançando o mesmo
estado de antes.**

Resultado negativo é entregável: se o layout do bloco não puder ser provado pelo decomp,
entregue a decodificação parcial com evidência e pare — isso é mais valioso que um bloco
adivinhado.

## Critérios de parada

- Vitória do passo (o aceite).
- **Vitória maior inesperada**: se `mc3-gfx-*` disparar, ou se `gifPk*`/`gsPrims` crescerem
  muito além do platô conhecido (`gifPk1≈348988`, `gsPrims≈704397`) — parar tudo, preservar o
  log, documentar. Seria a primeira evidência de modelo sendo carregado.
- Layout não provável pelo decomp → parar e documentar.
- Regressão na corrida sem argumentos → reverter e documentar.

## Entregáveis

1. `docs/RESULT_BOOT_ARGS_SKIPINTRO_GARAGE_2026-08-29.md` honesto, com o layout decodificado
   campo a campo e a evidência de cada um.
2. Commits locais pequenos no submódulo (branch `mc3`) e no repo externo. Sem push.
3. Bloco appendado em `PS2_PROJECT_STATE.md`.
4. **Não** sobrescrever `STATUS.md`.
