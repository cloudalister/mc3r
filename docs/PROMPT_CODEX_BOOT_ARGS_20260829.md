# Prompt para colar no Codex — boot args `-skipintro` / `-garage` (2026-08-29)

Copiar o bloco abaixo inteiro.

---

Execute `docs/HANDOFF_2026-08-29_BOOT_ARGS_SKIPINTRO_GARAGE.md` do início ao fim.
Leia o handoff inteiro primeiro, e depois leia `docs/RESULT_BOOT_ARGS_V1.md` antes
de tocar em qualquer código — ele já decodificou metade do mecanismo e evita que
você refaça o trabalho.

Repo raiz: `E:\Games\Emuladores\Sony\mc3recomp`

**COORDENAÇÃO — isto é o mais importante do prompt.** Há uma recompilação completa
de 15512 objetos em `-O2` rodando neste momento, seguida de relink.
**NÃO rode `tools/parallel_compile.py`, `tools/find_stale.py`,
`10_link_partial_runner.bat` nem `mc3_partial.exe` enquanto ela não terminar** —
você corromperia o manifesto de hash e o link em andamento. Até lá, trabalhe só em
leitura, decodificação e edição de código.

Para saber que terminou: nenhum processo `cc1plus`/`g++` ativo E
`work\link\partial\mc3_partial.exe` com timestamp posterior a
`PS2Recomp\out\build\ps2xRuntime\libps2_runtime.a`.

Ambiente de build (não redescobrir):

```
toolchain:  C:\msys64\ucrt64\bin        (prefixar no PATH; a suite TAMBEM precisa disso
                                         em runtime, senao morre com 0xC0000139)
cmake:      C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe
build dir:  PS2Recomp\out\build          (agora RelWithDebInfo: -O2 -g -DNDEBUG)
suite:      PS2Recomp\out\build\ps2xTest\ps2x_tests.exe   (CWD = PS2Recomp\out\build)
relink:     10_link_partial_runner.bat fast    (timeout >= 6 min, sempre)
```

O objetivo: fazer `-skipintro` e `-garage` chegarem ao parser de argumentos do
PRÓPRIO jogo (`datArgParser::Init`, retail `0x00428AC0`, já registrada), pelo
mecanismo real do crt0. **Não escreva nas globais `PARAM_*` diretamente** — isso
seria falsificar estado; o parser do jogo tem que rodar e decidir sozinho.

Regras de execução:

1. **Poll ativo, sempre.** Em toda espera longa rode loop de checagem a cada ~60 s.
   NUNCA pause "esperando notificação" — isso já travou agentes neste projeto.
2. **Não adivinhe o layout do bloco de args.** Se o decomp do crt0 não provar um
   campo, pare e documente a decodificação parcial. Um bloco malformado corrompe o
   boot inteiro de um jeito horrível de diagnosticar. Decodificação parcial honesta
   vale mais que bloco adivinhado.
3. **No symbol port use SEMPRE a coluna `retail_addr`** (a primeira). Já houve
   incidente grave aqui por usar `alpha_addr` — ver
   `docs/RESULT_ALPHA_GFX_TRACE_REMOVAL_2026-08-29.md`.
4. **Guarda de regressão obrigatória:** rode também SEM os argumentos e prove que o
   boot continua alcançando o mesmo estado. O boot atual funciona; quebrá-lo custa
   mais que o atalho vale.
5. Sem push. Commits locais apenas.

Ao final me retorne:

1. O layout do bloco apontado por `0x614400`, campo a campo, com a linha do decomp
   que prova cada campo.
2. O que você implementou, com diff resumido.
3. Saída da suíte (números exatos).
4. Trace de `datArgParser::Init` mostrando `argc` e as strings recebidas.
5. Resultado da corrida SEM argumentos (guarda de regressão).
6. Se algum trace `mc3-gfx-*` disparou.
7. O que você NÃO conseguiu provar.
