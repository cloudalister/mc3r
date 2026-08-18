# Handoff — passo 8: argumentos de boot (o caminho vazio do provider)

## Contexto mínimo

Passo 7 (`docs/RESULT_DAVE_HEADER_V1.md`): a checagem "Dave" nunca roda — o open do provider
recebe caminho **vazio**, `"T:"+""` falha, handle negativo → spin `0x5a8908`. O coordenador
verificou: o runtime **não popula argv em lugar nenhum** (`grep argv` em
`ps2_runtime.cpp`/`Lifecycle.cpp` = zero; `grep cdrom0` no runtime inteiro = zero). Em PS2
real, o kernel entrega ao `_start` os argumentos de boot — `argv[0] = "cdrom0:\SLUS_213.55;1"`
— e o jogo deriva TODO caminho de dados disso. Hipótese principal: sem boot args, o prefixo
de caminho do jogo é `""` e o provider de cdrom nunca é selecionado (o `strncmp` contra
`"cdrom"` no backend `FUN_003984c0` nunca casa).

## Objetivo

O jogo nasce com os boot args corretos pelo mecanismo real do crt0, o caminho do provider vira
`cdrom0:\...`, o open acha o arquivo, a checagem "Dave" roda com os bytes reais, e o gate
`0x5a8908` cai pela causa raiz.

## Método

1. **Decomp do `_start`/crt0** (alpha: `ENTRYPOINT`/`_start` @ `0x1a0008`, `_root`, `main`,
   `Main(void)` — todos nomeados no MC.MAP; o retail equivalente via symbol port ou pelo entry
   do ELF). Descobrir COMO o crt0 espera receber args (área `_args` preenchida pelo kernel?
   registrador? struct `{argc, argv[]}` em endereço fixo?). PS2 crt0 clássico: kernel copia
   `argc + strings` para um bloco e o crt0 monta `argv[]` — confirmar o layout exato no decomp.
2. **Implementar no runtime** (provável: `ps2_runtime.cpp` no setup do entry, ou
   `Lifecycle.cpp`): entregar `argc=1`, `argv[0]="cdrom0:\SLUS_213.55;1"` no formato exato que
   o crt0 espera, antes de saltar para o entry. Sem env-gate — é semântica de hardware/kernel.
3. Conferir também o secundário do passo 7: com caminho correto, quem escreve os slots
   `0x618020/0x618024` deve registrar o provider de cdrom — verificar no trace que o provider
   ativo muda e `func_3993A8`/"Dave" finalmente roda.
4. Se o open por `cdrom0:` cair no fileio/cdvd do runtime: `translatePs2Path` já resolve
   `cdrom0:` para `extracted_iso\`? Se não, mapear (case-insensitive, com/sem `;1`).
5. 1 corrida = 1 prova; seguir o gate. M4 = parar, confirmar 3x, reportar.

## Aceite

Trace mostra caminho não-vazio `cdrom0:\...` no open do provider E (`flag619f40 != 0` OU gate
sai de `0x5a8908`). M4 (`gifPackets>0` E `gsPrims>0`) = prêmio da noite.

## Regras

As do `STATUS.md` + economia do `WORKFLOW.md` (gemini/grep antes de ler arquivos inteiros).
PATH do MSYS2 (`C:\msys64\ucrt64\bin`) SEMPRE no ambiente antes de compilar (achado do passo
7: `cc1plus` falha silenciosamente sem `libmpfr-6.dll`). Recompilar `.o` gerados afetados;
relink timeout ≥6 min; suíte se mudar código tracked; commits locais sem push; resultado em
`docs/RESULT_BOOT_ARGS_V1.md`.
