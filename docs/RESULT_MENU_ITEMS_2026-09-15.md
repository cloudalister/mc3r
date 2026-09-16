# Itens do menu ausentes no painel pos-START — 2026-09-15

## Metodo

Sem novo probe (sem lock, sem exe novo). Reanalisado o snapshot final ja
capturado do probe menu_last2_20260915_a:
`<scratch-dir>/mc3-menu-last2-20260915/run/snapshots/sample_0177.json`
(D8=40, painel 0x1725D50 ativo, child 0x1725EA0 flags 647 gate aberto, membro
0x17788B0 vtable 0x631BA8 flags 591). Campos `uiDisplayRoot`/`uiDisplayTree` do
proprio Read-MenuGuest.ps1 (leitura ja embutida no snapshot, sem escrita).

## Achado principal

A arvore viva `instance=0x1e98f20` e a MESMA arvore do estado anterior (title
ativo, "Press START"). Apos START ela nao e reconstruida: 73 nos no total
(limite 128 nao atingido, `pending:0`, entao a coleta esta completa):

| drawSlotC | rotina | contagem |
|---|---|---|
| 0x20ebf8 | container/branch | 46 |
| 0x20f208 | folha decorativa (sem texto) | 20 |
| 0x210dd0 | folha de texto | 7 |

Os 7 textos das folhas 0x210dd0 sao **só** `OK, OK, Back, OK, Back, OK, Back`
(chunks 0x17b55c0/17b55e0/17b55d0/17b5600/... — mesmo padrao de chunk de 12
bytes documentado em RESULT_1H). Nenhuma folha contem rotulo de item de menu
(ex.: "Single Race", "License", etc.). Comparado ao snapshot descrito em
RESULT_1H_ENQUANTO_CLOUD_DORME (arvore antes do START: 48 containers 20EBF8,
20 folhas 20F208, 8 folhas 210DD0 = "Press START"+7×OK/Back), a UNICA mudanca
apos START e a folha "Press START button" ter sumido (8→7 em 210DD0; containers
48→46). Nao apareceu nenhuma folha nova.

## O que isso prova

O bloqueio nao e o render (5CC940 = `jr ra;nop`, legitimo, ja confirmado) nem
gate/flags do painel (591/647, abertos). **A etapa que deveria popular a
arvore com os itens do proximo painel nunca roda**: o motor continua
desenhando a arvore antiga (titulo), so escondendo o "Press START" e deixando
OK/Back — que sao botoes de dialogo generico dessa mesma arvore, nao itens do
painel seguinte. Isso aponta diretamente para a hipotese ja registrada em
RESULT_1H nao fechada: `Owner*(617980)+6B4` -> wrapper -> `3212D0`/`321208`
grava byte `+9`; `322FD8` chama `320B38` com `f12=-1`; **se byte+9 ativo usa
`618E54`, senao usa zero** — ou seja, ha um caminho condicional de populacao
de lista cujo gate provavelmente nao esta sendo satisfeito. Isso continua como
HIPOTESE (nao instrumentado neste lote); o que foi PROVADO por medicao direta
e que a arvore nunca recebe novas folhas de item.

## Nao foi corrigido

Nenhum codigo alterado, nenhum exe novo, nenhum probe novo rodado. Achado
apenas por releitura de dado ja coletado.

## Proximo passo (concluido nesta sessao — ver apendice abaixo)

Instrumentar `320B38`/byte `+9` de `Owner*(617980)+6B4` (e `618E54`) num probe
curto (<20 min) com runner lock, comparando byte+9 e o ponteiro `618E54`
sample a sample contra a ausencia de folhas novas em `uiDisplayTree`. Se
`618E54` for nulo/nao inicializado quando byte+9 deveria ativar, esse e o
ponto de bloqueio da lista de itens.

---

## Apendice — instrumentacao do proximo passo, mesma sessao

### Metodo

Copia read-only `tools/Read-MenuGuest-ItemProbe.ps1` (baseada em
Read-MenuGuest.ps1) adiciona, sem escrita nenhuma no processo:

- `textureCallback70F1BC` = leitura direta de `0x70f1bc` (ponteiro de callback).
- Para cada membro do grupo do painel (mesma lista que ja existia,
  `groupMembers`), um novo campo `ownChildCount`/`ownChildren`: percorre
  `member+0x74` (child) / `+0x78` (sibling), exatamente o mesmo layout usado
  pelo walker da arvore do titulo (`uiDisplayRoot`), ate 32 nos, com guarda de
  ciclo/limite identica.

Runner: mesmo exe ja aprovado (`.../mc3-menu-last2-20260915/bin/mc3_partial.exe`,
SHA `dc0375b7...`), mesmos env vars do probe anterior (`MC3_PAD_AUTOSTART=60000`,
delay 45000ms, hold 30000ms, `MC3_MENU_ENTRY_FIX=1`, `MC3_FRAME_HOST_CLOCK=1`,
`MC3_GS_STQ_INTERPOLATION=1`, `MC3_GS_IRQ_BRIDGE=1`, `MC3_HEADLESS=1`). RUNNER_LOCK
criado/usado/removido; nenhum outro runner ativo durante o probe. Duracao total
do probe (excluindo boot): 420 s (7 min), dentro do limite de 20 min. Saida em
`<scratch-dir>\mc3-menuitems-20260915-probe1\run\` (31 amostras).
Nenhum arquivo em `work\generated`, `work\compile`, `work\link` ou
`PS2Recomp\ps2xRuntime` foi tocado; nenhum exe existente foi alterado.

### Resultado — PROVADO, nao mais hipotese

1. **`textureCallback70F1BC` = `0x3203b8` em 31/31 amostras.** A instalacao do
   callback de pacotes de textura descrita em RESULT_1H passo 4 esta ativa e
   estavel a corrida inteira. Isso NAO e o ponto de bloqueio.
2. **O byte em `wrapper+9` (`Owner*(617980)+6B4 +9`) oscila entre 0 e 1** ao
   longo da corrida (nao e sempre 1 como uma leitura pontual sugeriu antes).
   Isso e o gate de delta de animacao (RESULT_1H passo 2); correlacionado com
   titulo ativo/inativo, nao com o painel D8=40.
3. **Achado decisivo: o membro do grupo do painel (objeto na familia
   `0x177xxxx`, vtable `0x631ba8`, render `0x5cc940` = `jr ra;nop`) tem
   `ownChildCount=0` em TODAS as 31 amostras**, inclusive nas 13 amostras em
   que `gateOpen=true` (flags=591, portao aberto) — amostras 8-17 (objeto
   `0x177abd0`) e 24-26 (objeto `0x17788b0`, o mesmo endereco documentado em
   STATUS.md/RESULT_1H). O ponteiro em `member+0x74` (mesmo offset "child"
   usado pela arvore do titulo) nunca aponta para RDRAM valido nesse membro,
   com o portao aberto ou fechado.

### Conclusao

Isso fecha a cadeia de causalidade por medicao direta, nao mais inferencia:
o renderer desse membro e literalmente `jr ra;nop` (ja confirmado identico ao
ELF) E o membro nunca recebe filhos em `+0x74`. Um renderer no-op sem filhos
**nao pode**, por construcao dos dados, desenhar itens — nem quando o portao
591 abre. O bloqueio nao esta em codigo ausente, callback, ou no gate de
animacao (todos vivos e corretos): esta em uma escrita que deveria popular
`member+0x74` (endereco RDRAM `0x17788b0+0x74` / `0x177abd0+0x74` conforme a
instancia) e que nunca acontece nesta execucao. Candidato a correcao (ainda
NAO aplicado, precisa de confirmacao adicional no ELF antes de qualquer
mudanca): localizar, no ELF, o site de escrita que deveria gravar em
`instance+0x74` para objetos de vtable `0x631ba8` — provavelmente parte da
cadeia `MenuOptionScreen 65AE24 -> 320848 -> 20B198 -> 20AFB0` ja mapeada em
RESULT_1H passo 1, que hoje so consulta propriedade tipada mas cujo efeito de
popular a lista (escrever o primeiro filho) nao foi confirmado como executado.
Nenhum codigo foi alterado; nenhuma flag foi forcada; achado por leitura pura.

### Apendice 2 — busca estatica no ELF do escritor de `+0x74` (mesma sessao, sem lock)

Metodo: `capstone` (MIPS64/LE) sobre os PT_LOAD do proprio
`extracted_iso\SLUS_213.55`, sem tocar `work\generated`/corpus. Passos:

1. Localizados os DOIS unicos sites no ELF inteiro que montam o literal
   `0x631ba8` via `lui`+`addiu` (par imediato): `0x420a0c/0x420a18` e
   `0x420948/0x420950`(este ultimo e outro vtable proximo, nao usado). O
   construtor real e:
   ```
   420a08: addiu sp,sp,-0x10
   420a0c: lui v0,0x63
   420a14: move v1,a0
   420a18: addiu v0,v0,0x1ba8      ; v0 = 0x631ba8
   420a1c: jal 0x426000
   420a20: sw v0,(v1)              ; *objeto = 0x631ba8 (grava o vtable)
   ```
   Ou seja, `0x420a08` e o unico construtor de objetos vtable `0x631ba8` no
   binario, e ele encadeia para `0x426000` (super-construtor, que grava OUTRO
   vtable, `0x632118`, no mesmo objeto — heranca). Dump de ~150 instrucoes de
   `0x426000` **nao contem nenhuma escrita em offset 0x74** do objeto.
2. Extraida a vtable completa `0x631ba8` (dados, 39 entradas, `+0x00..+0x9c`).
   Confirma `+0x28=0x5cc940` (render, ja sabido). Testadas as ~17 entradas de
   metodo seguintes (`+0x40..+0x80`, enderecos `420c90..428830`) por ate ~260
   instrucoes cada: **nenhuma contem `sw reg, 0x74(reg_objeto)`.**
3. Busca geral no ELF inteiro por `sw reg, 0x74(base)` deu 168 ocorrencias;
   filtrando as que tem um `lw ..,0x74(mesma_base)` proximo (padrao classico
   de insercao "ler cabeca antiga, gravar novo no.": 30 pares. O unico no
   intervalo `0x320000-0x330000` (`0x323880/0x3238b0`) usa `base=$sp`
   (variavel de pilha, nao campo de objeto) — falso positivo. O candidato mais
   promissor fora da faixa de vtable, `0x200b18` (`sw s0, 0x74(s3)`), foi
   verificado e e de OUTRO tipo de objeto: `s3` recebe vtable `0x624700` (nao
   `0x631ba8`) e o valor gravado em `+0x74` e um contador de sequencia lido de
   `0x614da8`, nao um ponteiro de arvore — coincidencia de offset entre
   classes diferentes, descartado.

### Conclusao do apendice 2

**Nao encontrado, por analise estatica, o site que escreve `instance+0x74`
para objetos de vtable `0x631BA8`.** Isso NAO prova ausencia (poderia estar
em codigo nao coberto pela minha janela de disassembly, ex.: alem de 260
instrucoes nos metodos virtuais, ou via ponteiro de funcao no meio de uma
tabela maior nao decodificada como controle de fluxo estatico). Portanto:
nem (a) "condicao falsa identificada" nem (b) "divergencia ELF vs corpus
provada" foram alcancados com evidencia solida — near este ponto o resultado
e **inconclusivo**, nao um achado positivo. Regra do projeto (`Sem chute de
bytes`) impede propor um fix sem essa prova; nenhum exe novo foi construido,
nenhum probe rodado nesta etapa (analise 100% estatica, sem lock).

### Proximo passo real

Confirmar no ELF (nao no corpus gerado, para evitar viés de divergencia) o
corpo de `320848`/`20B198`/`20AFB0` procurando por uma instrucao `sw` que
grave em `+0x74` de um objeto vtable `0x631ba8`/definicao correspondente, e
comparar reg-a-reg contra o binario recompilado. Se essa escrita existir no
ELF mas nunca disparar no runtime (condicao de entrada falsa), esse e o bug;
se nao existir nenhuma escrita assim nesse caminho, o site correto fica a
localizar em outra função ainda não mapeada.

### Apendice 3 — oraculo PCSX2 e viabilidade do write-trace (mesma sessao)

**Oraculo PCSX2:** `tools\PCSX2-MCP-Status.ps1` confirma binario/servidor MCP
presentes (`external\PCSX2-MCP\...\pcsx2-qt.exe`, `pcsx2-mcp-server\dist`),
mas `[PENDING]` em DebugServer(21512), PINE(28011) e processo — PCSX2 nao
esta rodando. Nao existe nenhum savestate (`.p2s*`) no repo ou em
`external\PCSX2-MCP` no estado do painel D8=40 (busca por nome em `.`/
`external\PCSX2-MCP`, sem grep no corpus). `pcsx2-qt.exe -help` confirma
`-statefile`, mas sem savestate pronto seria necessario bootar do zero e
automatizar START no timing certo via MCP, sem tooling ja validado para
pad-input nesta sessao. **Julgado inviavel dentro de ~15 min com confianca**;
nao iniciado, para nao gastar o orcamento em uma tentativa as cegas. Isso e
uma limitacao de tempo desta sessao, nao uma prova de que o oraculo nao serve
— fica como TODO para uma sessao com esse orcamento reservado.

**Write-trace isolado (fallback):** o binario ja tem um mecanismo generico de
watch-de-escrita, `PS2_PATH_WATCH_ADDR`/`ps2TraceGuestWrite` em
`PS2Recomp/ps2xRuntime/include/ps2_runtime.h` (usado no probe de escritas do
frontend em 05/09, RESULT_FRONTEND_WRITES). **Mas o endereco e uma constante
`inline constexpr` fixa em tempo de compilacao** (`0x01EFFFA0`), nao
configuravel por env var — repoint-la para `0x17788b0+0x74`/`0x177abd0+0x74`
exigiria editar `PS2Recomp\ps2xRuntime\include\ps2_runtime.h`, que e
EXATAMENTE o arquivo protegido pela regra dura ("Não altere ...
PS2Recomp\ps2xRuntime (fontes ou lib)"). O padrao usado em
`mc3-menu-vertex-20260913` (`menu_vertex_observer.h`) contorna isso copiando
o CORPO de uma unica funcao geradora ja conhecida para um `.cpp` isolado e
injetando um observer RAII nela — mas esse padrao exige saber DE ANTEMAO qual
funcao escreve, que e exatamente o dado que falta aqui (apendice 2 nao achou
o site). Sem endereco-alvo configuravel no watch generico e sem uma funcao
candidata confirmada para copiar, um write-trace novo hoje ou (a) violaria a
regra de nao mexer no runtime compartilhado, ou (b) seria um chute de qual
funcao copiar — ambos proibidos pelas regras do projeto. **Nao construido.**

### Apendice 4 — verificacao do "armadilha de header obsoleto" (mesma sessao, sem lock)

Cumprindo a instrucao do coordenador de checar, antes de rodar qualquer
probe, se `ps2TraceGuestWrite`/o endereco de watch estao "inlineados" nos
`.o` gerados a ponto de um relink de biblioteca nao ter efeito:

1. **`nm` no exe ja aprovado** (`mc3-menu-last2-20260915/bin/mc3_partial.exe`
   e `libps2_runtime.a`, toolchain `C:\msys64\ucrt64\bin`) mostra que
   `ps2TraceGuestWrite` (`_Z18ps2TraceGuestWritePhjjyyPKcPK12R5900Context`) e
   uma funcao `inline` de "vague linkage" (grupo COMDAT
   `.text$_Z18ps2TraceGuestWrite...`): existem milhares de referencias `U`
   (uma por `.o` gerado que usa `WRITE8/16/32/64/128`) e **exatamente UMA**
   definicao sobrevive no binario final apos a fusao COMDAT. Ou seja, cada um
   dos ~15.800 `.o` gerados carregava sua PROPRIA copia da funcao (compilada
   com o endereco fixo antigo `0x01EFFFA0`), e o linker descartou todas menos
   uma.
2. **`mc3_partial.link.rsp` confirma a ordem de link**: `libps2_runtime.a`
   aparece na linha 15837, **depois de ~15.833 arquivos `.o` gerados** (e
   antes so dos ultimos `leaf.o`/`entries.o` das entradas de menu). Selecao
   COMDAT "any" do linker GNU/MinGW mantem a PRIMEIRA definicao encontrada na
   ordem de processamento; como a biblioteca vem quase no fim, sua copia de
   `ps2TraceGuestWrite` perde para qualquer uma das ~15.833 copias ja
   presentes nos `.o` gerados, processadas antes.
3. **Copia isolada criada e corrigida** em
   `<scratch-dir>\mc3-menuitems-20260915-watch\` (`include/`,
   `src/` copiados de `PS2Recomp\ps2xRuntime`, fonte original intocada):
   `ps2PathWatchPhysAddr`/`ps2PathWatchIntersects` deixaram de ser `inline`
   no header e passaram a ser funcoes reais definidas uma unica vez em
   `src/lib/ps2_runtime.cpp`, lendo `MC3_WRITE_WATCH_ADDR`/`MC3_WRITE_WATCH_LEN`
   (hex) em runtime, default OFF. Isso e correto para codigo **recompilado**
   contra essa copia.

**Conclusao, provada e nao apenas prevista pelo coordenador:** dado (1)+(2),
um relink usando os `.o` gerados existentes (sem recompila-los) **nao pode**
mudar o endereco observado, porque a definicao vencedora do COMDAT continua
sendo uma das ~15.833 copias antigas processadas antes da biblioteca no link.
Rodar o probe nessas condicoes produziria zero linhas de watch por construcao
do link, nao por ausencia real de escritas — um resultado que pareceria
"negativo" mas seria uma medicao invalida. Por isso **o probe NAO foi
executado** e nenhum RUNNER_LOCK foi tomado nesta etapa: rodar um probe cujo
resultado ja se sabe ser estruturalmente nao-informativo desperdicaria a
janela de 15 min sem produzir evidencia, o que a regra do projeto trata como
pior que nao medir. A copia com a correcao de header fica pronta em
`<scratch-dir>\mc3-menuitems-20260915-watch\` para quando houver
orcamento para recompilar os `.o` candidatos (nao so relinkar a lib).

### Apendice 5 — tentativa de leitura via PINE no oraculo PCSX2 (mesma sessao, so leitura)

Implementado cliente PINE minimo em Python (TCP 127.0.0.1:28011, framing
`[u32 size incl. si mesmo][payload]` / resposta `[u32 size][u8 result: 0=OK,
0xFF=FAIL][dados]`), conferido byte a byte contra
`external\PCSX2-MCP\...\pcsx2-mcp-server\dist\pine-client.js` (`PineCmd`
enum, `MsgRead8/16/32/64=0..3`, `MsgStatus=15`) para garantir compatibilidade
exata antes de tentar qualquer endereco de jogo. Nenhuma escrita, nenhum
`MsgSaveState`/`MsgLoadState` foi enviado.

**Handshake OK** (`MsgStatus` retornou `result=0`), mas o valor retornado e
**`status=2` (`EmuStatus.Shutdown`)** — nao `Running` nem `Paused`. Confirmado
por `MsgTitle`/`MsgID`/`MsgVersion`, que retornaram `result=0xFF` (FAIL),
padrao de "nenhum jogo carregado" nessas implementacoes de PINE. Ou seja, a
porta 28011 esta aberta e aceitando o protocolo, mas **nao ha VM ativa** no
processo PCSX2 (PID 4728) neste momento — diverge do que foi relatado
(pausado no Slot 2). Nao tentei nenhuma leitura de endereco de jogo (`617980`
etc.) porque, sem VM ativa, retornariam FAIL/lixo e eu poderia mal-interpretar
isso como "campo ausente no retail", uma conclusao falsa por medicao invalida
— o mesmo cuidado usado nos apendices anteriores.

**Bloqueio:** nao devo carregar o Slot 2 nem religar/retomar a VM sem
autorizacao explicita (regra "nao mudar estado do emulador sem perguntar").
Preciso de confirmacao para: (a) retomar/despausar a VM no PCSX2 ja aberto,
ou (b) carregar o Slot 2 salvo, o que quer que restaure o estado esperado.
Nenhuma comparacao de campo foi feita ainda; nada no doc dos apendices 1-4
foi contradito ou confirmado por este apendice — ele so estabelece que o
cliente PINE funciona e identifica exatamente o que falta para prosseguir.

### Apendice 5 (continuacao) — leitura real do retail via PINE e comparacao com `sample_0177`

VM confirmada `Running` (`MsgStatus` result=0, status=0) apos o usuario
carregar o Slot 2 (menu com opcoes visiveis, PCSX2 PID 4728). `MsgTitle`
confirma `"Midnight Club 3 - DUB Edition Remix"`. Cliente PINE em Python
(mesmo do topo do apendice 5) percorreu, **so leitura**, exatamente a mesma
cadeia de ponteiros do nosso `Read-MenuGuest-ItemProbe.ps1`, partindo dos
GLOBAIS fixos do ELF (`0x617980`, `0x617adc` — identicos no retail, pois sao
`.data`/`.bss`; nao usei nenhum endereco de heap hardcoded da nossa build,
conforme instruido) e seguindo os ponteiros ate onde eles levam no heap real
do retail (que sao outros enderecos, como esperado).

**Resultado retail** (script e JSON completo em
`<scratch-dir>\mc3-menuitems-20260915-watch\pine_read.py` /
`retail_pine_read.json`):

| Campo | Nosso `sample_0177` | Retail (PINE, agora) |
|---|---|---|
| painel seguinte vtable | `0x62bde0` | `0x62bde0` (identico) |
| `drawChild` vtable (grupo) | `0x631c40` | `0x631c40` (identico) |
| `drawGateOpen` | true | true |
| membro do grupo, vtable | `0x631ba8` | `0x631ba8` (identico) |
| membro do grupo, render | `0x5cc940` (`jr ra;nop`) | `0x5cc940` (identico) |
| **membro do grupo, `ownChildCount` (`+0x74`)** | **0** (31/31 amostras, gate aberto ou fechado) | **0** |
| arvore do titulo, total de nos | 73 | 65 |
| arvore, folhas por `drawSlotC` | `20ebf8`=46, `20f208`=20, `210dd0`=7 | `20ebf8`=40, `20f208`=22, `210dd0`=3 |
| textos das folhas `210dd0` | `OK,OK,Back,OK,Back,OK,Back` | `OK,OK,Back` |
| **rotulo de item de menu em qualquer folha** | **nenhum** | **nenhum** |

### Achado principal do apendice 5

**Nao ha divergencia no campo que a hipotese apontava.** O retail real, no
mesmo estado de menu (Slot 2, opcoes visiveis), tem o **mesmo** membro de
grupo vtable `0x631ba8` com `+0x74` (child) **vazio**, e a **mesma** arvore
do titulo sem nenhuma folha de texto de item — so `OK`/`Back`, exatamente
como no nosso recomp. A contagem de nos (73 vs 65) e de folhas `OK`/`Back`
(7 vs 3) difere, mas isso e compativel com amostrar um instante diferente da
mesma tela viva (numero de dialogos/paineis `OK`/`Back` empilhados varia com
o tempo, ja visto oscilar nas nossas 31 amostras) — nao e evidencia de codigo
diferente, e por isso **nao ha endereco de ELF para citar como "escritor
divergente"**: nao existe divergencia comprovada para atribuir.

**Isso invalida a hipotese de trabalho dos apendices 1-4.** A cadeia
`instance+0x74` do membro vtable `0x631ba8` e a arvore de folhas de texto do
titulo NAO sao o mecanismo que desenha os itens do menu — nem no retail. A
procura por um "escritor de `+0x74` que falha" (apendices 2-4) buscava algo
que o proprio jogo original tambem nao faz nesse ponto. O bloqueio visual
real precisa estar em outro lugar: candidatos que sobram, ainda nao
descartados, sao os **20 a 22 nos decorativos sem texto** (`drawSlotC=0x20f208`,
provavelmente icones/quads texturizados sem rotulo nesta estrutura) — se
esses icones SAO os itens do menu visualmente (like PS2 games that show
icon-only options), o defeito seria de textura/posicionamento/render desses
nos especificos, nao de populacao de lista. Combina com os itens ja abertos
e nao resolvidos no STATUS.md (placa cortada na diagonal, faixas brancas).

### Proximo passo real (substitui as recomendacoes dos apendices 2-4)

Comparar, no MESMO PINE, os 20-22 nos `drawSlotC=0x20f208` (posicao/matriz,
textura referenciada) entre retail e nosso recomp, em vez de perseguir
`+0x74`. Esse caminho foi aberto mas nao lido em detalhe nesta sessao (so
contado). Ver tambem `menu_vertex_observer` (RESULT_1H) para o pipeline real
de vertices/textura, que pode ser o local correto do defeito.

### Apendice 6 — comparacao dos nos decorativos (0x20F208) e busca por tela/arvore ausente (mesma sessao, so leitura PINE)

Pedido do coordenador: comparar nos `drawSlotC=0x20F208` campo a campo e
checar se o retail tem uma tela/arvore INTEIRA que falta no nosso recomp,
em vez de so um campo errado. Metodo: mesmo cliente PINE, ainda so leitura,
sem savestate/pause/resume.

**Achado decisivo, antes mesmo de chegar aos nos 0x20F208:** comparando a
lista completa de candidatos ativos em `front+0x40..0x130` (a MESMA sondagem
que ja fazia parte do nosso `Read-MenuGuest-ItemProbe.ps1`, sem inventar
campo novo):

| Slot em `front` | Nosso `sample_0177` (recomp) | Retail (agora, PINE) |
|---|---|---|
| `0x58` | *(ausente da lista ativa)* | **objeto `0x16a68f0`, vtable `0x629b88`, flags=975 (bit0=1, ATIVO)** |
| `0xb0` | **objeto `0x1725d50`, vtable `0x62bde0`, flags=975 (bit0=1, ATIVO)** | objeto `0x16c6210`, vtable `0x62bde0`, **flags=974 (bit0=0, INATIVO)** |
| `0xf0` | vtable `0x628878`, flags=975 | vtable `0x628878`, flags=975 (igual) |
| `0x11c` | vtable `0x62bcf8`, flags=975 | vtable `0x62bcf8`, flags=975 (igual) |
| `0x124` | vtable `0x6355b8`, flags=719 | vtable `0x6355b8`, flags=719 (igual) |

Os tres ultimos casam exatamente (mesmo vtable, mesmas flags). A diferenca
esta so nos dois primeiros: **no recomp, o painel `0x62BDE0` (o que
investigamos nos apendices 1-5, com o membro vazio) e que esta ATIVO
(bit0 de `+0x44` ligado). No retail, ESSE MESMO painel esta INATIVO
(bit0 desligado) e, em vez dele, um painel DIFERENTE (`0x629B88`, no slot
`0x58`) esta ativo.**

Segui o painel retail `0x629B88` (mesmo padrao de estrutura: `render=0x41F980`
identico ao nosso, filho em `+0x48` com vtable `0x631C40` igual, `flags=647`
igual): seu grupo tem um unico membro (`0x17060F0`, vtable `0x631BA8`,
`flags=591`, gate aberto, render `0x5CC940`, `ownChildCount=0` -- mesma
"folha vazia" dos apendices 1-5). Ou seja, esse painel alternativo TAMBEM nao
tem itens de texto por esse mecanismo -- mas **e uma tela logicamente
diferente da que estamos travados mostrando**, confirmando a hipotese do
coordenador: **falta uma transicao de tela inteira, nao um campo dentro da
mesma tela.**

### Conclusao do apendice 6

O recomp fica preso mostrando o painel `0x62BDE0` (slot `0xb0` de `front`)
como o painel ativo. No retail, no mesmo momento de jogo (menu com opcoes
visiveis), esse painel **ja foi desativado** (`flags` bit0 `1->0`) e outro
painel (`0x629B88`, slot `0x58`) foi ativado no lugar. Isso desloca todo o
diagnostico anterior: o problema nao e "itens nao populam dentro do painel
62BDE0" -- e **"o jogo deveria ter trocado de painel ativo (62BDE0 -> outro,
possivelmente 629B88 ou uma cadeia que passa por ele) e essa troca nao
acontece no recomp"**. O bit relevante e `object+0x44` bit `0x1` (o mesmo
"flags&1" ja usado pelo nosso proprio filtro de `activePanelCandidates`).

**Nao identificado nesta sessao (falta de tempo/orcamento), e registrado como
TODO, sem chute:** qual funcao do ELF escreve/limpa esse bit em `+0x44` para
apagar `62BDE0` e acender `629B88` (ou o painel equivalente). E o proximo
alvo concreto e MUITO mais promissor que continuar em `+0x74`: provavelmente
um dispatcher de transicao de estado do frontend (candidato natural: perto de
`320748`/`322FD8` ja mapeados nos apendices 2, que chamam `320848` com um
`f12`/modo -- ainda nao confirmado como o escritor deste bit especifico).

Nos `0x20F208` ainda NAO foram comparados campo a campo (posicao/textura)
nesta sessao -- o achado acima e mais forte e foi priorizado. Fica como
proximo passo se a hipotese da troca de painel nao fechar sozinha o defeito
visual.

### Apendice 7 — rastreando o ativador do painel 0x629B88 (parcial, mesma sessao)

**Log de acao do frontend (nosso probe):** `grep` em
`<scratch-dir>\mc3-menu-last2-20260915\run\logs\probe_menu_last2_20260915_a.log.stderr`
por `mc3-frontend-action-edge` retorna 16 linhas, **todas identicas**:
`frontend=0x008183d0 state=0x008183dc index=6 source=0x007d6710 current=255
previous=0 queue=10 next=11 ra=0x0020bb00`. Isso vem de um hook de log
manual JA EXISTENTE (nao inserido por mim) dentro do corpus gerado, em
`work/generated/ghidra/sub_0020BA88_0x20ba88.cpp` (funcao ELF `0x20BA88`,
achada por `state_address == frontend+12` no codigo). **A funcao roda e e
executada repetidamente durante todo o probe** (16 vezes em 20 min) — nao e
funcao ausente/nao-chamada.

**O que a funcao faz (lido do corpo decompilado, nao verificado byte-a-byte
contra o ELF por falta de tempo nesta sessao):** varre uma tabela de
registros de 0x1C0 bytes em `frontend+0x6C..` procurando campo `+0`==4
(filtro de tipo), chama `func_234D58` (RA `0x20BB00`, e o valor de `$ra`
capturado no log — nao um segundo endereco de chamada, e sobra do `jal`
anterior) para avaliar a condicao de cada candidato, depois varre um array
apontado por `frontend+0x100` comparando um hash de 2 bytes por entrada
contra um valor de entrada, e quando bate, escreve `1` no byte "casado" da
entrada correspondente. **O slot `index=6` (offset `+0xC` de `frontend`) e
exatamente o que nosso hook loga, e seus dois campos lidos (`current` em
`source_address`, `previous` em `source_address+3`) ficam parados em
`255`/`0` nas 16 amostras ao longo de 20 minutos inteiros** — ou seja, os
bytes de entrada que decidiriam esse "edge" nunca mudam durante toda a
corrida no nosso recomp.

**Tentativa de comparar com o retail via PINE, sem sucesso nesta sessao:**
`frontend=0x008183d0` e um ponteiro de HEAP do NOSSO processo, nao um global
fixo do ELF — tentei o mesmo endereco literal no retail via PINE e os
valores lidos (`actionCount=2303998983`, `arrayPtr=0x48f0`) sao lixo
claramente incompativel com a estrutura esperada, confirmando que o heap do
retail aloca esse objeto em outro endereco. **Nao encontrei, no tempo
disponivel, a cadeia de ponteiros de um global fixo (`617980`/`617adc`/etc.)
ate esse objeto `frontend`** para localiza-lo no retail e ler o campo
equivalente — a funcao `sub_0020BA88` recebe `frontend` como argumento (`a0`),
entao o ponteiro vem de algum outro codigo/estrutura ainda nao mapeado nesta
sessao.

### Conclusao do apendice 7 e status real do "ativador"

**Nao provado (a) nem (b)** dentro do orcamento desta etapa:
- (a) nao identifiquei a condicao exata (quais bytes deveriam ficar
  diferentes de `255`/`0` e o que os escreveria) nem o endereco ELF que
  falha a condicao — sei ONDE o "edge" e verificado (`sub_0020BA88`/`0x20BA88`,
  slot `index=6`), mas nao QUEM deveria alimentar `source_address=0x7D6710`
  com valores novos.
- (b) nao comparei o corpo gerado contra os opcodes do ELF byte-a-byte para
  essa funcao (feito so uma leitura de alto nivel do C++ decompilado).
- Nao encontrei, ainda, o ponteiro de `frontend` no retail para confirmar se
  o MESMO slot `index=6` tambem fica parado em `255/0` la (o que provaria
  isso como comportamento NORMAL, nao bug) ou se no retail ele avanca (o que
  confirmaria esse ser o ponto exato do defeito).

**Isso e diferente, e mais fraco, do que a comparacao de paineis do apendice
6** (essa sim comprovada: painel `62BDE0` ativo no nosso recomp vs `629B88`
ativo no retail, mesmo momento de jogo). O log `action-edge` e um candidato
PLAUSIVEL para o mecanismo por tras dessa nao-transicao, mas **nao esta
conectado por evidencia** ao achado do apendice 6 nesta sessao — sao duas
pistas paralelas, nao uma cadeia causal provada.

### Proximo passo real (atualizado)

1. Achar quem chama `sub_0020BA88` com `frontend=front` (ou confirmar que sao
   objetos diferentes) e re-ler `frontend+0x100`/`+0x104`/a tabela de
   `0x1C0` bytes via PINE no retail, usando a MESMA cadeia de ponteiros
   fixos (nao o endereco de heap `0x8183d0`).
2. Comparar opcode a opcode `sub_0020BA88_0x20ba88.cpp` vs ELF (igual ao
   apendice 2, mas para este arquivo), focando no branch de `0x20bb54`
   (`bnez $v1`, decide se a entrada "bate") e `0x20bbb4`/`0x20bbe0`-`0x20bbe8`
   (os testes de hash/xor que decidem avancar `queue`->`next`).
3. So depois, se (1)+(2) confirmarem uma condicao concreta, buscar no ELF
   quem deveria escrever em `source_address`/`source_address+3` para
   satisfazer essa condicao — aí sim citar o endereco do "ativador" com
   confianca.

### Apendice 8 — global fixo de `frontend`, leitura retail e diff ELF vs corpus (mesma sessao)

**Achado o ponteiro fixo real.** `0x8183D0` (apendice 7) e um endereco de
HEAP do nosso processo, nao um global. Busquei no ELF inteiro quem chama
`sub_0020BA88` (`jal 0x20BA88` = palavra `0x0C082EA2`): **dois sites,
`0x20AD30` e `0x20AE38`**, ambos com o mesmo padrao `lui s1,0x71` seguido de
`lw a0,-0xE2C(s1)` -- ou seja, **`frontend = *(0x70F1D4)`**, um global fixo
(mesma faixa `0x70Fxxx` de `0x70F1B0/B4` (viewport) e `0x70F1BC` (callback de
textura) ja usados nos apendices 1 e 3).

**Leitura PINE no retail usando esse global** (`pine_read5.py`): `frontend`
real no retail = `0x81C0B0` (mesma ordem de grandeza de heap que o nosso
`0x8183D0` -- confirma ser o mesmo tipo de objeto, endereco diferente por
alocacao). Byte em `+0xC` (o "state" do slot index=6) = **0**. `arrayPtr`
em `+0x100` = `0x63F410` (faixa `.rodata`, plausivel — bem diferente do lixo
obtido antes com o endereco de heap errado, o que confirma que agora estou
lendo o objeto certo). `count` em `+0x104` = **1** (valor pequeno plausivel,
nao lixo). Bytes `frontend+0x00..0x20` (area de fila) = todos zero.

**Nao completei, no orcamento restante,** o calculo exato de `source_address`
(a formula usa uma cadeia `a1 = index derivado do PRIMEIRO BYTE em *arrayPtr`,
depois `a2 = tabela_base(0x6BB400) + a1*0x1C0 + 0x174`, e soh dai chega no
endereco comparado com `+4`) — precisa de mais um nivel de leitura (o byte em
`*arrayPtr`) que nao segui a tempo. Portanto **nao consegui comparar
`current`/`previous` do slot index=6 contra o retail** como pedido.

### Diff opcode-a-opcode: `sub_0020BA88` vs ELF nos ramos de decisao

Desassemblei `0x20BB48-0x20BBA0` e `0x20BBB0-0x20BBF8` (os dois ramos
pedidos: `0x20BB54` `bnez $v1` e a sequencia `0x20BBB4-0x20BBE8` de
`xori`/`beql`/`xor`/`srl`/`beql`) diretamente do ELF e comparei palavra a
palavra com os comentarios `// 0xPC: 0xWORD` do corpo gerado
(`sub_0020BA88_0x20ba88.cpp`, linhas ~251-450 ja lidas no apendice 7).
**Resultado: identico, instrucao por instrucao, sem nenhuma divergencia** —
`1460002c` (`bnez v1,0x20bc08`), `38420004`/`5440000f` (`xori`/`bnel`),
`5060000c` (`beql`), `641826`/`319c2`/`50600003` (`xor`/`srl`/`beql`) batem
exatamente com o C++ decompilado.

### Conclusao do apendice 8

**`sub_0020BA88` esta corretamente recompilado — nao ha bug de recompilacao
nessa funcao.** Isso muda a conclusao provisoria do apendice 7: o mecanismo
"action-edge" nao pode ser descartado nem confirmado como causa da troca
`62BDE0`->`629B88` do apendice 6 **com a evidencia desta sessao**, mas
**o codigo em si esta exonerado** -- se o slot index=6 realmente fica preso,
a causa estaria a MONTANTE (dados/entrada que alimentam a tabela em
`arrayPtr`/`frontend+0x100`, ou timing), nao num erro de traducao MIPS->C++
nesta funcao especifica. **Nao ha, portanto, uma ligacao causal provada
entre o apendice 7 e o apendice 6** nesta sessao; permanecem pistas
paralelas, sendo que o apendice 6 (troca de painel `62BDE0`/`629B88`) e a
descoberta mais solida ate agora, com evidencia direta e comparavel via
PINE, enquanto o apendice 7/8 (action-edge) fica sem prova de causalidade e
sem bug de recompilacao para justificar continuar essa trilha sem novos
dados.

### Proximo passo real (substitui o do apendice 7)

Dado que `sub_0020BA88` esta correto, abandonar essa funcao como suspeita
direta. Focar em achar, no ELF, QUEM escreve o bit `object+0x44 & 0x1` para
`62BDE0` (limpar) e para `629B88`/o painel real seguinte (setar) — greppar
por `andi $vX, $vX, 0xfffe`/`ori $vX,$vX,1` seguidos de `sw ...,0x44($sN)`
em funcoes que referenciam os enderecos `0x62BDE0`/`0x629B88` (mesmo metodo
dos apendices 2/4), e so entao rastrear se essa escrita e alcancada no
runtime (grep nos logs do probe, como feito para `mc3-frontend-action-edge`).

### Apendice 9 — busca do ativador de `+0x44` bit0 (parcial, mesma sessao) e handoff

**Vtables completas extraidas do ELF** (`0x62BDE0` e `0x629B88`, 40 entradas
cada, `+0x00..0x9C`): sao **classes irmãs quase identicas** — todos os slots
de `+0x0C` a `+0x9C` tem o MESMO endereco de metodo nas duas (inclusive
`+0x28=0x41F980`, o render generico ja visto), exceto `+0x08` (construtor,
`0x37E150` vs `0x353C38`) e os slots proprios `+0x1C, +0x24, +0x88, +0x8C,
+0x90, +0x98`, onde cada classe tem sua propria funcao. Isso confirma que sao
duas variantes da mesma familia de "painel", so com construtor e uns poucos
metodos proprios diferentes — reforça que a troca `62BDE0`->`629B88` e uma
troca de OBJETO (outra instancia dessa familia), nao um comportamento
exotico.

**Busca por `lw $v,0x44(base)` -> `ori $v,$v,1`/`andi $v,$v,0xFFFE` ->
`sw $v,0x44(base)` no ELF inteiro: so 1 ocorrencia** (`lw@0x467DA4
mod@0x467DBC sw@0x467DC4`, kind=`ori1`). Inspecionado: esse trecho calcula
`v0 = (*(a1+0x44) & ~4) | 1` antes de manipular varios `lwc1`/`swc1` (campos
de float, padrao de setup de camera/interpolacao, sem nenhuma referencia
proxima a `0x62BDE0`/`0x629B88`). **Nao aparece nenhuma vez** nos logs do
probe (`grep` por `467d`/`467da4`/`467dc4` em
`probe_menu_last2_20260915_a.log.stderr` = 0 ocorrencias, contra 454
ocorrencias de `62bde0`/`629b88` no mesmo log vindas de outro lugar -- os
nossos proprios prints de diagnostico, nao evidencia de execucao desse
codigo). **Descartado como candidato**: endereco nao relacionado, sem
evidencia de execucao no nosso runtime.

**Conclusao honesta:** a busca de padrao estreito (`lw`/`ori-or-andi`/`sw`
consecutivos, ate 6+3 instrucoes de distancia) **nao achou o ativador real**.
O bit provavelmente e setado por um caminho diferente do procurado -- por
exemplo, como parte de uma constante maior (`ori $v,$zero,0x3CF` /
`addiu $v,$zero,0x3CF`, já que os valores observados 975=0x3CF e 974=0x3CE
diferem so no bit0, mas podem ser escritos como PALAVRA INTEIRA nova, nao
como read-modify-write), ou via uma funcao generica de "SetActive"/"PushScreen"
que recebe o objeto por ponteiro e escreve a constante certa, chamada
indiretamente (via vtable ou tabela de despacho) — nao capturavel pelo grep
de padrao fixo usado.

### Handoff para a proxima sessao (exato, sem chute)

1. **Buscar `ori $v,$zero,0x3cf` / `addiu $v,$zero,0x3cf` e o par `0x3ce`**
   no ELF inteiro (word patterns: opcode `0x0d`/`0x09`, `rs=0`, `imm=0x3cf`
   ou `0x3ce`), depois checar quais tem um `sw` para `+0x44(base)` nas
   proximas ~6 instrucoes. Script pronto para adaptar:
   `/tmp/scan_flag44.py` (nesta sessao, nao commitado; recriar rapido).
2. **Ler, via PINE, no retail (VM ainda em `Running`, front=`0x167e320` na
   ultima leitura, mas RE-LER pois o estado avança), o campo `+0x108` da
   TABELA (nao confundir com o `frontend` de `0x70F1D4`) que a arvore
   `0x20D420` usa — ver se ha um contador de "screen index" perto de
   `front+0x40..0x130` que muda quando o slot ativo muda de `0xB0` para
   `0x58`.**
3. **Rastrear callers de `320748`/`322FD8` no ELF** (`jal` word scan, mesmo
   metodo do item 1 do apendice 2) e verificar se algum deles escreve em
   `front+0x58` ou `front+0xb0` diretamente (nao so em `+0x44` de outro
   objeto) -- pode ser que a ativacao seja: escrever o PONTEIRO do painel
   novo no slot do array `front`, e so ENTAO o `flags` de cada objeto e
   consultado (nao setado) por quem itera esse array. Ou seja, **reconsiderar
   a hipotese**: talvez `+0x44` bit0 nao seja "ligado/desligado" por
   nenhuma funcao -- talvez os OBJETOS sejam CRIADOS ja com um valor fixo
   (`0x3CF` para o ativo do momento, `0x3CE` para outros), e a "troca" real
   e sobre QUAL objeto esta no slot do array `front`, nao sobre um bit
   dentro do mesmo objeto. Verificar isso ANTES de continuar procurando o
   "escritor do bit".
4. Enderecos fixos uteis ja confirmados nesta sessao (todos globais, iguais
   em qualquer build/retail): `0x617980` (uiOwner), `0x617ADC` (root),
   `0x70F1D4` (ponteiro `frontend` do action-edge), `0x70F1B0/B4` (viewport),
   `0x70F1BC` (callback textura). `front = *(*(0x617ADC)+0xC)`.

### Conclusao dos apendices 2, 3 e 4 e proximo passo real (HISTORICO — ver apendices 5, 6, 7, 8 e 9 acima para a conclusao atualizada)

Nem o oraculo PCSX2 nem o write-trace foram executados nesta sessao — o
primeiro por orcamento de tempo, o segundo por bloqueio estrutural genuino
(watch de escrita fixo em compile-time no runtime protegido; nenhuma funcao
candidata confirmada para copiar isoladamente). Isso NAO e um "nao funcionou";
e um chute evitado deliberadamente. Caminho real para a proxima sessao, em
ordem de custo/risco:
1. **Preferencial:** rodar o oraculo PCSX2 do zero com orcamento >15 min:
   bootar o ISO real, chegar ao mesmo D8=40 (ou equivalente no retail) via
   input manual/MCP, e comparar `+0x74`/contagem de filhos/rotulos da arvore
   contra `sample_0177.json`. Sem savestate pronto; precisa ser criado e
   preservado para reuso.
2. **Alternativa:** propor (nao aplicar sem aprovacao) um parametro de
   endereco de watch configuravel por env var em `ps2_runtime.h`, revisado
   por quem tem permissao de tocar `PS2Recomp\ps2xRuntime`, e so entao
   compilar um observer generico apontado para `0x17788b0+0x74`.

**Atualizado apos apendice 2:** a busca estatica direta no construtor/vtable
de `0x631ba8` nao achou o escritor (ver apendice 2). O proximo passo real e
tracejar em runtime (nao estatico) — instrumentar com um build isolado que
loga toda escrita em `instance+0x74` para objetos com vtable `0x631ba8`
durante um probe curto, em vez de continuar a busca estatica as cegas pelo
ELF inteiro.

## Apendice 10 - Watchpoint real no retail (Claude, PCSX2 DebugServer 21512)

Estado: Save Slot 1 (antes do START). front=*(*(0x617ADC)+0xC)=0x167E320.
Antes do START: slot0xB0 obj0x16C6210 vt62BDE0 flags975 (ATIVO), slot0x58
obj0x16A68F0 vt629B88 flags462 (inativo) - igual ao nosso recomp antes do START.
Memcheck write/break em obj+0x44 dos dois. Usuario apertou START.

Hit 1: pc 0x4262A0 `sw v0,0x44(a0)`, a0=0x16C6210 (62BDE0), v0=0x3CF (975) -
regrava o MESMO valor (ativo). Backtrace (entry/pc):
426288/4262A0 <- 41F938/41F94C <- 5810F0/581100 <- 380738/380A64 <-
37EC18/37F320 <- 4225D8/422668 <- 41E3D0/41E424 <- 346970/346A0C <-
1A32B0/1A33B0 <- 1A23A8/1A2728 <- 1A0DB4/1A102C <- ... 1A0000.
426288 e o setter de flags do painel (candidato SetActive). Proximo: watch
"onchange" para pegar a troca real 975->974 / 462->975.

Hit 2 (write/break so no obj 629B88+0x44, apos START) - ATIVADOR ENCONTRADO:
pc 0x427C14 `sw v1,0x44(s0)`, s0=a0=0x16A68F0 (629B88), v1=0x1CF (bit0 ligado),
a1=1. Cadeia retail (entry/pc):
427BD0/427C14 <- 41F550/41F578 <- 380068/380210 <- 353CA0/353CE8 <-
339278/3395E4 <- 320B38/320C2C <- 322FD8/32302C <- 1A32B0/1A32DC (loop) ...
Ou seja: 322FD8 -> 320B38 -> 339278 -> 353CA0 -> 380068 -> 41F550 -> 427BD0(SetActive,a1=1).
Proximo: descobrir em qual elo o recomp para (log/corpus) e a condicao.

## Apendice 11 - Condicao que falha no recomp (Claude)

Ramo decisivo em 320B38 (conferido ELF = corpus FUN_00320b38, opcodes iguais):
320BF8 jal 20B290(a0=*(s0+4), a1="readyformenu" @0x64C9CF, a2=s0)
320C00 lbu v1,0(s0) ; 320C04 beqz v1 -> 320C2C (pula)
320C0C..320C24: le *(*(*(0x617ADC)+C)+C)+0xE0; se !=1 -> jal 339278 (caminho
que no retail chega a 41F550 -> 427BD0 SetActive(629B88)).
20B290 = "le variavel de script por nome": 20AF60 lookup; se achou, *a2 = 20E628(var).
No nosso probe last2 o trace mc3-320b38-progress em stage 320C2C tem ra=0x320C00
(beqz tomado): **readyformenu = 0 no recomp**, por isso 339278 nunca roda e o
painel 629B88 nunca e ativado.
Unicos acessos de codigo ao nome (lui 0x65 + addiu -0x3631): 320BF0 (leitura),
320E64 e 320F8C (via 20B258 com a2=0: ZERAM a variavel apos uso). O valor 1 vem
de fora do codigo com o nome literal (provavel script/dados do disco).
Retail: entrada da variavel na tabela em 0x1754750 (nomePtr), valor/tipo em
0x1754754/0x1754758. Watch de escrita armado para capturar quem grava 1 apos
recarregar Slot 1 + START.

## Apendice 12 - Instrumentacao do PROPRIO recomp (Claude, 2026-09-16)

Depois de tres quedas do PCSX2 com watchpoints, troquei a abordagem: instrumentar
o nosso build, onde temos controle.

Builds isolados (tools/Build-VarTraceEntries.ps1, Build-VarTrace2Entries.ps1,
Build-VarLookupTrace.ps1; fontes tools/mc3_var_trace_entries.cpp e
tools/mc3_var_lookup_trace.cpp):
- 0x20B290 (le variavel) e 0x20B258 (grava bool) reimplementados conforme ELF,
  64 casos de fixture OFF/ON PASS.
- Melhor: wrappers em 0x20AF60 (find) e 0x20AFB0 (find/create), que TODOS os
  acessores tipados usam; o wrapper so loga e chama o corpo gerado original.
  24 casos de equivalencia (contexto + 4MB de RAM identicos) PASS.
Gate por env: MC3_VAR_TRACE / MC3_VAR_LOOKUP_TRACE, default desligado.

Resultados (probe headless 15min, START automatico aos 45s):
1. `readyformenu` EXISTE no recomp, e lida (found=1) e vale SEMPRE 0; e gravada
   dezenas de vezes, sempre 0, por 320C40 e 320F9C - os dois sitios do ELF que
   a zeram. Ninguem grava 1. No retail e a mesma coisa nesses sitios (37.850
   gravacoes com 0 na captura noturna via PINE), logo o valor 1 vem de outro
   caminho, guiado por dados/script.
2. Lista completa de variaveis que o recomp cria/procura: 41 nomes, incluindo
   MenuOptionScreen, PressStart, TitleHeader, savegamescreen, showbar,
   ChatPanelHeight, KeyboardShown. Comparando com a lista capturada no retail,
   faltam SEIS: offSetX, offSetY, lineheight, scrollable, currentselection,
   actualselection.
3. Essas seis sao propriedades da classe de view do frontend: as strings ficam
   no bloco de nomes em 0x652A80..0x652CC0 (junto de mc3FeView, colorBase,
   menuLineHeight, showArrows...) e sao referenciadas por codigo em
   0x33F814/0x33F854/0x33F8AC/0x33FAC4 (corpo sub_0033F728) e
   0x3417A0/0x3417BC/0x34180C/0x341828 (corpo sub_0033FD80 / FUN_00340ac8).
   offSetX/offSetY/lineheight = layout da lista; scrollable/currentselection/
   actualselection = estado de lista rolavel, isto e, exatamente os itens do menu.
4. 0x33FEB0 (mesma familia, vtable 0x628878) e chamado no nosso: 637 vtcalls no
   log. Nao ha prova de que 0x33F728 ou a regiao 0x3417A0 executem.

Interpretacao: o recomp chega a criar o MenuOptionScreen e as variaveis de
titulo, mas nao chega ao trecho que registra as propriedades da LISTA. Ainda nao
esta provado qual condicao/caminho falta.

Proximo: achar os chamadores de 0x33F728 e do trecho em 0x3417A0 (ELF), e
instrumentar esses callers no recomp (wrapper que so loga, como em
mc3_var_lookup_trace.cpp) para ver ate onde o caminho vai. Lembrar do remendo
existente do runtime para 0x33FEB0 vs sub33FD80 (MC3_MENU_ENTRY_FIX) - a area e
a mesma e pode estar relacionada.
