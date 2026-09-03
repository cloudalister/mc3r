# Resultado — passo 8: argumentos de boot (o caminho vazio do provider)

Executa `docs/HANDOFF_FASE1_BOOT_ARGS.md` do início ao fim. Data: 2026-08-18. Branch `mc3`
(fork local, sem push), submódulo `PS2Recomp`. **Aceite NÃO alcançado** — mas a hipótese
principal do handoff ("kernel nunca entrega argv, prefixo de path fica vazio") foi **refutada
por evidência de trace ao vivo**, e a causa raiz real foi isolada um passo adiante, em camada
compartilhada (motor de `sprintf`/`vsnprintf` recompilado), fora do escopo seguro deste
handoff. Nenhum arquivo de runtime tracked foi alterado — só instrumentação diagnóstica em
três arquivos gerados (gitignored).

## Resumo executivo

1. **O layout de boot args do crt0 foi decodificado por completo** (seção "Layout de args do
   crt0" abaixo, com evidência linha-a-linha do decomp). Ele não usa `$a0`/`$a1` como
   `argc`/`argv` (esses registradores são explicitamente zerados no início do `_start`, antes
   de qualquer `syscall`) — usa um ponteiro global (`0x614400`) que o kernel real popularia
   antes do entry rodar; se esse ponteiro for zero (caso não-devkit, sem override), o crt0 cai
   num bloco de argumentos **compilado no próprio ELF** (`0x677080`, mas o campo que
   efetivamente importa mora em `0x617F84`).
2. **Esse bloco compilado já contém `"cdrom0:\"` por padrão** — confirmado tanto no ELF cru
   (extração de bytes) quanto **ao vivo, por trace**: `*(0x617F84) = 0x0065c50d`, que aponta
   para a string literal `"cdrom0:\"` em `.rodata`. Nenhum código no boot escreve nesse global
   (busca em todo o corpus `work/generated/ghidra/*.cpp` por `WRITE32` no offset `0x7F84` a
   partir de `0x610000`: zero ocorrências) — o loader de segmentos do runtime
   (`ps2_runtime.cpp`, cópia do `PT_LOAD` para `rdram`) entrega esse valor corretamente e nada
   o sobrescreve depois. **Conclusão: a entrega de boot args já funciona para o caso retail
   (sem override de devkit) — não há nada faltando para implementar aqui.** Implementar o
   mecanismo alternativo do ponteiro `0x614400` seria código morto (o caminho realmente
   percorrido nunca o consulta com valor não-nulo) e exigiria adivinhar o layout exato dos
   campos além de `argc`/ponteiro-de-string — o que a regra "sem chute de bytes" proíbe sem
   evidência de que essa é de fato a causa do bloqueio (não é, ver item 3).
3. **A causa raiz real está uma camada abaixo**: em `zipFile::Init`
   (`sub_005A8898_0x5a8898`, `0x5a88dc`), o prefixo `"cdrom0:\"` (de `0x617F84`) e um caminho
   candidato `"cdrom0:\assets.dat"` (de uma tabela estática de nós default, endereço
   `0x637e03`) são passados **ambos válidos e não-nulos** para uma chamada estilo `sprintf`:
   `func_42F9F0(dest, "%s%s", "cdrom0:\", "cdrom0:\assets.dat")`. Essa chamada desce por
   `FUN_0042fa98_0x42fa98` (trampolim de vararg) até `sub_0042F558_0x42f558` (motor de
   formatação genérico, ~1996 linhas, `0x42f558`-`0x42f9ec`, usado em todo o jogo — vi-o sendo
   chamado também com `"%d"` e `"%sSYSTEM\%s"` durante o mesmo boot). **Comprovado por trace ao
   vivo: os dois argumentos `%s` chegam corretos e não-nulos, mas o motor devolve
   `v0 (chars escritos) = 0`**, deixando o buffer de destino vazio (`""`) — exatamente o
   sintoma que `RESULT_DAVE_HEADER_V1.md` já tinha observado, mas a causa não é "provider
   errado" nem "kernel sem argv": é o motor de formatação compartilhado falhando
   silenciosamente com entradas válidas. Uma segunda chamada independente (`"%sSYSTEM\%s"`,
   também no boot) reproduziu o mesmo `v0=0`, o que sugere bug sistêmico no motor, não
   específico deste call site.
4. Esse motor (`func_42F558`) é infraestrutura compartilhada usada por todo o jogo, não algo
   específico de boot args — corrigi-lo está fora do escopo e do orçamento seguro deste
   handoff (regra do `STATUS.md`: bug suspeito fora do escopo do handoff atual → reportar, não
   remendar). Fica como achado prioritário para a próxima sessão.

## Layout de args do crt0 (com evidência do decomp)

Fonte: `work/generated/ghidra/entry_0x1a0008.cpp` (retail, `0x1a0008`-`0x1a04c8`, mesmo
endereço do `ENTRYPOINT`/`_start` nomeado no MC.MAP alpha — mesma base de link do crt0 SN
Systems em ambos os builds). ELF confirmado via `e_entry` do cabeçalho:
`extracted_iso/SLUS_213.55` → `0x1a0008`. Único `PT_LOAD`: `vaddr=0x1a0000 filesz=0x4d7074
memsz=0x575d3c` (offset de arquivo `0x80`).

```
0x1a0008-0x1a0084  zera TODOS os registradores (inclui $a0-$a3 via padduw $zero,$zero) —
                    qualquer argc/argv que o kernel real tivesse passado por registrador
                    morre aqui. Confirma que o mecanismo de args NÃO é por registrador.
0x1a0138-0x1a0154  zera bloco de BSS via sq $zero em loop (0x614400..0x677080, o range que
                    contém os globais de boot-args).
0x1a0154-0x1a0184  monta gp=0x67F070, stack=0x180000, stackSize=0x20000,
                    a3(argsBlockPtr)=0x677080, t0=0x1A01F8; syscall 0x3C (60 = InitMainThread).
0x1a0188           sp = v0 (retorno de InitMainThread)
0x1a018c-0x1a01a0  syscall 0x3D (61 = InitHeap)
0x1a01a4           jal func_54C3C0 (init adicional, não decodificado — fora do caminho de args)
0x1a01ac           jal func_546C20 = FlushCache_0x546c20 (nomeado)
0x1a01b4           ei (habilita interrupções)
0x1a01b8-0x1a01e0  v1 = *(0x614400)              // ponteiro de override, setado pelo "kernel"
                    real antes do entry (0 = sem override, caso padrão retail)
                    if (v1 != 0) { v0 = v1 + 4; }         // bloco fornecido em runtime
                    else          { v0 = 0x677080; }      // bloco compilado default (fallback)
                    a0 = *(v0);  a1 = v0 + 4;
0x1a01e4  jal FUN_00398370_0x398370(a0, a1)
```

`FUN_00398370_0x398370.cpp:44-55` (decomp):
```cpp
WRITE32(ADD32(GPR_U32(ctx, 2), 32636), GPR_U32(ctx, 4));  // *(0x617F7C) = a0
WRITE32(ADD32(GPR_U32(ctx, 3), 32640), GPR_U32(ctx, 5));  // *(0x617F80) = a1
```
Ou seja: `a0` (primeiro campo do bloco de args) é salvo em `0x617F7C`; `a1` (ponteiro pro
resto do bloco) em `0x617F80`. Essa função depois zera um trecho de scratchpad (não
relacionado a args) e chama `sub_001A0CF0_0x1a0cf0` (que passa `a0`/`a1` adiante para uma
cadeia de init de heap/TLS: `func_54E158`, `func_398338`, `func_3AFBF0`, `func_3AFD78`,
`func_3AFAD8`, `func_1A0CE8`, `func_42EB08`, `func_428AC0`, `func_398318`, `func_4292C0`,
`func_3AFD08`). **Busquei em todo o corpus `work/generated/ghidra/*.cpp` (grep pelos offsets
`0x7F7C`/`0x7F80`/`0x7F84`/`0x7F88`/`0x7FB0` a partir do padrão `lui $reg,0x61` = `0x610000`)
por qualquer `WRITE32` no offset `0x7F84` (32644 decimal): zero ocorrências.** Ou seja,
`0x617F84` nunca é escrito por nenhum código do boot — mantém o valor com que o ELF o
inicializou.

### O valor compilado de `0x617F84`

Extração direta dos bytes do ELF (`extracted_iso/SLUS_213.55`, `PT_LOAD` `vaddr=0x1a0000
offset=0x80`):
```
VA 0x617F84 (file offset 0x478004): bytes 0D C5 65 00  ->  word = 0x0065C50D
VA 0x0065C50D (file offset 0x4bc58d): b'cdrom0:\\\x00cdrom\x00host0:\x00pfs0:\x00...'
```
`0x617F84` é inicializado, em tempo de compilação/link, para apontar para a string literal
`"cdrom0:\"` em `.rodata`. **O loader de `PT_LOAD` do runtime** (`ps2_runtime.cpp`, laço em
`~linhas 803-919`: lê `ph.filesz` bytes do arquivo direto para `rdram + physAddr`, depois
`memset` do restante até `ph.memsz`) **copia esse valor corretamente** — verificado ao vivo
(trace abaixo). O bloco default em `0x677080` (o outro ramo, quando `v1==0`) está tecnicamente
além do `filesz` do segmento (`0x677074`), então é BSS puro (zerado); isso é irrelevante
porque o campo que realmente importa (`0x617F84`, lido bem mais adiante em `zipFile::Init`,
não diretamente do bloco `0x677080`/`0x677084`) já vem populado desde o `.data` do ELF.

## Evidência ao vivo (trace desta sessão)

Instrumentação nova (atrás do já existente `MC3_TRACE_PROVIDER`, sem gate novo), aplicada só
em código gerado/gitignored, posicionada **depois** do `switch(ctx->pc)` de resumo de cada
função (mesmo cuidado que `RESULT_DAVE_HEADER_V1.md` recomendou, para não ler registrador de
retomada por engano):

```
[MC3_TRACE_ARGS] at=0x5a88cc *(0x617F84)=0x0065c50d str="cdrom0:\" fallbackNode(a3/s0)=0x00637e03
[MC3_TRACE_ARGS] enter=0x42f558 a0(fmt)=0x00676fec "%s%s" a1(vaPtr)=0x0019fde0 a3(dest)=0x0019fe10 va[0]=0x0065c50d
va[+8]=0x00637e03
[MC3_TRACE_ARGS] at=0x42fac8 vsnprintf-return v0(len)=0 destBase(s0)=0x0019fe10 preview=""
```

Segunda amostra independente, mais cedo no mesmo boot (call site diferente, mesmo motor):
```
[MC3_TRACE_ARGS] enter=0x42f558 a0(fmt)=0x00640dcc "%sSYSTEM\%s" a1(vaPtr)=0x0019fcb0 a3(dest)=0x0019fce0
[MC3_TRACE_ARGS] at=0x42fac8 vsnprintf-return v0(len)=0 destBase(s0)=0x0019fce0 preview=""
```

Ambas chamadas: formato válido, ambos ponteiros `%s` válidos e não-nulos (confirmados também
por leitura de string, não só endereço), retorno `v0=0`. O buffer de destino (que vira `a1` da
chamada em `func_4FA398`, e por fim `a0`/path de `FUN_003984c0`) fica `""` — reproduz
exatamente a linha já vista em `RESULT_DAVE_HEADER_V1.md`:
`[MC3_TRACE_DAVE] fresh-entry=0x3984c0 a0=0x0019fe10 path=""`.

Arquivos: `work/scratch/bootargs_probe1_stderr.log` (confirma `*(0x617F84)` correto antes de
qualquer instrumentação no motor de format), `work/scratch/bootargs_probe3_stderr.log` (com
todas as três instrumentações, corrida de referência desta sessão — linhas 1176-1179).

## `translatePs2Path` — conferido, já correto

`PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Helpers/Runtime.h:466-516` e
`Helpers/Path.h:38-81`: `translatePs2Path` já resolve `cdrom0:`/`cdrom:` (case-insensitive,
via `toLowerAscii`) para `getConfiguredCdRoot()`, que cai em `paths.elfDirectory`
(`extracted_iso\`) quando `cdRoot` não foi configurado explicitamente; `normalizePs2PathSuffix`
já troca `\` por `/` e remove sufixo `;N` de versão ISO. **Nada a mapear aqui — já funciona.**
Não é a camada bloqueando o gate.

## Por que não implementei o mecanismo `0x614400` no runtime

O handoff pedia para entregar `argc=1, argv[0]="cdrom0:\SLUS_213.55;1"` no formato que o crt0
espera, antes do salto pro entry. Decodifiquei o formato (seção acima) — mas a evidência ao
vivo mostra que:

1. O caminho que o jogo **de fato** percorre no boot retail (sem override de devkit) é o
   `v1==0` → bloco compilado default, e esse bloco **já resulta** em `0x617F84 = "cdrom0:\"`
   sem qualquer intervenção do runtime.
2. Implementar o ponteiro `0x614400` faria o crt0 tomar o **outro** ramo (`v1 != 0`), cujo
   layout exato além de `{header; argc; argvPtr}` não tenho como confirmar sem decomp
   adicional de como o kernel real preencheria esse bloco (quantos campos, se `argv` é um
   array de ponteiros ou uma string concatenada, como o terminador funciona) — implementá-lo
   por analogia seria "chute de bytes" proibido pelo `STATUS.md`, especialmente porque **não
   moveria o gate**: o bloqueio real (item 3 do resumo) está downstream de onde quer que
   `0x617F84` venha, e afeta os dois ramos igualmente.
3. Forçar esse ramo também trocaria comportamento de um mecanismo que, pelas evidências, é
   **opcional/devkit-only** em hardware real — mexer nele sem necessidade violaria a regra de
   não introduzir comportamento não evidenciado.

Ou seja: a "entrega de boot args" pedida pelo handoff **já está correta e não precisa de
mudança de runtime** — o handoff partiu de uma hipótese (passo 7) que a evidência desta sessão
refuta. Documentar isso e apontar a causa real (item 3) é o resultado certo, por
`WORKFLOW.md`: "resultado negativo é entregável" + "bug suspeito fora do escopo → reportar, não
remendar".

## Trajetória do gate / `flag619f40`

Sem mudança: `flag619f40` permanece `0x00` a corrida inteira; PC estável determinístico
continua `0x5a8908`/`0x5a88f0` (3 corridas desta sessão, mesmo padrão). Nenhuma mudança de
comportamento do jogo foi feita — só instrumentação `fprintf` atrás de `MC3_TRACE_PROVIDER`.

## Régua de render

`gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0 dma=2 vif=3 gif=0 gsw=0` — inalterada. Não é
M4; `21_probe_repeat.bat 3 probe m4_confirm` não se aplica.

## Aceite

**Não alcançado.** Caminho não-vazio no `open()` não foi obtido; `flag619f40` continua `0x00`;
gate continua em `0x5a8908`. Mas a causa raiz avançou uma camada real: de "kernel não entrega
argv" (hipótese do passo 7, refutada) para "motor de `sprintf`/`vsnprintf` compartilhado
(`sub_0042F558_0x42f558`) devolve 0 caracteres escritos para formatos `%s` válidos com
argumentos não-nulos" (achado novo, evidenciado por trace, reproduzido em 2 call sites
independentes).

## O que foi mudado

Só instrumentação diagnóstica, em três arquivos **gerados/gitignored**
(`work/` está no `.gitignore`; nada entra em commit):

- `work/generated/ghidra/sub_005A8898_0x5a8898.cpp` — print de `*(0x617F84)` (string) e do
  "fallbackNode" (`a3`/`s0`) logo após a leitura em `0x5a88cc`, antes da chamada a
  `func_42F9F0`.
- `work/generated/ghidra/FUN_0042fa98_0x42fa98.cpp` — print de `v0` (chars escritos) e preview
  do buffer de destino no label de retomada pós-`jal func_42F558` (`0x42fac8`).
- `work/generated/ghidra/sub_0042F558_0x42f558.cpp` — print de entrada (formato, ponteiro de
  vararg, os dois primeiros slots de vararg) em entrada nova (após o `switch(ctx->pc)` de
  resumo, mesmo cuidado do passo 7).

Todos atrás do env var já existente `MC3_TRACE_PROVIDER` (sem gate novo); todos só `fprintf`
em `stderr`; zero efeito em comportamento de jogo. Recompilados com
`PATH=/c/msys64/ucrt64/bin:$PATH` + `g++ -std=c++20 -msse4.1 ...` e relinkados via
`10_link_partial_runner.bat fast`.

**Nota de correção de build incidental**: ao recompilar `FUN_0042fa98_0x42fa98.cpp` pela
primeira vez usei por engano o diretório de batch errado
(`work/compile/ghidra/batch_0027/obj/`, copiando o padrão de outro arquivo do passo 7) — o
CSV de batches (`work/batches/ghidra/batch_0036.csv:220`) mostra que o batch correto para essa
função é `batch_0036`. Como `Link-PartialRunner.ps1` faz `Get-ChildItem -Recurse -Filter *.o`
em toda a árvore `work/compile/ghidra`, os dois `.o` (um recém-criado por engano em
`batch_0027`, outro o legítimo em `batch_0036`) colidiram como "multiple definition" no link.
Removi o `.o` incorreto que eu mesmo criei em `batch_0027` (`rm
work/compile/ghidra/batch_0027/obj/FUN_0042fa98_0x42fa98.o`) e mantive só o de `batch_0036`
(consistente com o CSV). Confirmei que os outros dois arquivos tocados (`sub_005A8898_0x5a8898`
→ `batch_0059`, `sub_0042F558_0x42f558` → `batch_0036`) não têm duplicata. Vale registrar em
`docs/WORKFLOW.md`: sempre conferir o batch correto no CSV (`grep <NomeDaFuncao>
work/batches/ghidra/*.csv`) antes de recompilar um objeto manualmente, em vez de assumir o
batch de outro arquivo.

## Próximos passos sugeridos (não executados nesta sessão)

1. **Prioridade alta, fora do escopo deste handoff**: investigar `sub_0042F558_0x42f558`
   (`0x42f558`-`0x42f9ec`, ~294 instruções, motor de formatação compartilhado por todo o jogo)
   — por que devolve `v0=0` para `%s%s`/`%sSYSTEM\%s` com argumentos válidos. Candidatos a
   olhar primeiro: o parâmetro `a2` fixo (`0x42EB48`, uma constante/tabela passada por
   `FUN_0042fa98` antes de chamar o motor — não decodificado nesta sessão) e o laço principal
   de despacho de especificador em `label_42f9b8`/`label_42f598`. Esse bug provavelmente afeta
   MUITO mais do que boot args (qualquer `sprintf`/`vsnprintf` do jogo recompilado) — merece
   handoff próprio dedicado, com suíte completa rodando depois (é código super compartilhado,
   risco de regressão alto).
2. Se/quando esse motor for corrigido, revisitar este handoff: o resto da cadeia (prefixo
   `"cdrom0:\"`, `translatePs2Path`) já está pronto — só falta o `sprintf` produzir
   `"cdrom0:\assets.dat"` de verdade para o `open()` finalmente receber um path não-vazio.
3. Mover a instrumentação `MC3_TRACE_ARGS` (ou uma versão reduzida dela) para o handoff que for
   atacar `func_42F558`, já que ela já prova exatamente onde o motor falha.

## Suíte e commits

Nenhum arquivo de runtime tracked foi alterado (só os três arquivos gerados/gitignored citados
acima) — suíte não rodou (regra do `WORKFLOW.md`: só medir/rodar suíte quando há mudança de
código tracked). `git status` no repo raiz e no submódulo `PS2Recomp` não mostram nada a
commitar além deste RESULT doc; commit local deste arquivo será feito a seguir, sem push
(regra do `WORKFLOW.md`).


## Adendo 2026-09-03: `-skipintro` nao existe neste retail

Varredura direta dos 5.264.872 bytes de `extracted_iso/SLUS_213.55` (busca literal, sem
depender de simbolo):

| termo | ocorrencias |
|---|---|
| `skipintro` | **0** |
| `qload` | **0** |
| `menuDebug` | **0** |
| `garage` | 5+, mas todas dentro da tabela de nomes de estado |
| `loadrecent` | 2, ambas em nomes de UI (`PM_AreYouSureLoadRecent`, `RE_LOADRECENTSLOT`) |

As ocorrencias de `garage` estao todas na mesma tabela de `.rodata` (a partir de `0x497dfa`):

```
tune/city.loadTransition.city.conditions.ambients.frontend.garage.mc3frontend.movie.race.
race editor.mix.tuneudio.vehInput...
```

Isso e a **tabela de nomes de estado** do `mcGameState`, nao uma lista de parametros de linha
de comando. O `datArgParser::Init@0x428AC0` sobreviveu no binario, mas as palavras que o
handoff esperava passar para ele nao estao em lugar nenhum do retail — elas vieram dos
simbolos do build alpha (MC.MAP), nao deste ELF.

**Consequencia pratica:** implementar o override do bloco em `0x614400` para entregar
`-skipintro -garage` seria construir a maquinaria inteira para argumentos que nenhum codigo
deste binario procura. O atalho da Rockstar existe no alpha; nao existe aqui.

O layout do override, ja decodificado, fica registrado caso um dia sirva para outro argumento
que exista de fato:

```
v1 = *(0x614400)
v0 = (v1 != 0) ? (v1 + 4) : 0x677080
a0 = *(v0)      // argc
a1 = v0 + 4     // vetor de ponteiros para as strings
```

Ganho colateral da varredura: a tabela de nomes de estado esta localizada e legivel a partir de
`0x497dfa`. Ela nomeia `frontend`, `garage`, `mc3frontend`, `movie`, `race`, `race editor` — o
vocabulario da maquina de estados que hoje nao avanca da tela legal
(`docs/RESULT_PAD_AUTOSTART_2026-09-03.md`).
