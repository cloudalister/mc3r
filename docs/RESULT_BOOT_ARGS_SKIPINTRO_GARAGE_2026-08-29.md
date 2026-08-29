# Resultado — boot args `-skipintro` / `-garage` pelo crt0 retail

Data: 2026-08-29. Repo externo `mc3recomp`, submodulo `PS2Recomp` branch `mc3`.
Commit do submodulo: `3367091` (`Pass host boot arguments through SN crt0`).
Commits locais somente; sem push.

## Resultado executivo

O aceite binario do handoff foi atingido. Com:

```text
mc3_partial.exe extracted_iso\SLUS_213.55 -skipintro -garage
```

o parser retail em `0x00428AC0` recebeu `argc=3` e as tres strings pelo mecanismo
do crt0. Sem argumentos extras, o crt0 continuou usando o bloco fallback compilado
no ELF (`argc=0`, `argv=0x00677084`). Nao houve escrita direta em `PARAM_*`, injecao
de `SignalSema`, env-gate novo nem mudanca em scheduler, SIF, VIF ou GS.

O detalhe decisivo foi o momento da publicacao: `_start` zera `0x614400` em sua
primeira instrucao. Portanto, montar o bloco antes do entry e publicar o ponteiro
imediatamente nao funciona. O runtime agora conserva o bloco e publica seu ponteiro
durante o syscall retail `SetupThread` (`0x3C`), depois do clear de BSS e antes do
crt0 consumir os argumentos.

## Layout provado do bloco apontado por `0x614400`

Fonte primaria: `work/generated/ghidra/entry_0x1a0008.cpp`.

1. `0x614400` e um **slot de ponteiro**, nao o bloco em si.
   - linhas 398-406 montam `0x614400` e carregam `*(0x614400)` em `v1`;
   - linhas 407-419 escolhem o override quando o ponteiro e nao zero;
   - linhas 431-436 escolhem `0x677080` como fallback quando ele e zero.
2. No bloco apontado, offset `+0x00` e o **ID de semaforo do loader**, `uint32_t`.
   - linhas 473-488 recarregam `*(0x614400)`, fazem `a0 = *(ponteiro + 0)` e
     chamam `0x005469C0`;
   - linhas 490-500 identificam o destino retail como `SignalSema_0x5469c0`.
   - O runtime grava zero, que preserva o comportamento observado do caminho sem
     override e nao injeta nem sinaliza semaforo por conta propria.
3. Offset `+0x04` e **`argc`**, `uint32_t`.
   - linhas 417-419 fazem `v0 = ponteiro + 4` no caminho de override;
   - linhas 438-447 fazem `a0 = *(v0)` e `a1 = v0 + 4`, antes da chamada a
     `FUN_00398370_0x398370`;
   - `FUN_00398370_0x398370.cpp:38-49` persiste esses dois valores como argc/argv;
   - o trace real na entrada de `datArgParser::Init` confirmou `a0=3`.
4. Offset `+0x08` inicia **`argv[0]`**, seguido de `argc` ponteiros guest de 32 bits.
   - como acima, o crt0 calcula `a1 = (ponteiro + 4) + 4`;
   - `sub_00428AC0_0x428ac0.cpp:154-166` calcula `indice * 4` e carrega cada
     entrada com `lw`.
5. As strings sao **referenciadas**, nao campos inline do vetor.
   - `sub_00428AC0_0x428ac0.cpp:164-169` carrega o ponteiro de `argv[i]` com `lw`
     e le o primeiro byte da string com `lb`;
   - o bloco montado guarda as strings depois do vetor, em bytes NUL-terminated.
6. Nao existe campo separado para o ponteiro `argv`: o crt0 o calcula como
   `block + 8`. Tambem nao foi provado nem adicionado `argv[argc] == nullptr`; o
   parser itera por `argc`.

Alinhamento provado/implementado:

- campos e entradas do vetor sao words de 4 bytes (`lw`/`sw`);
- o fallback `0x677080` e alinhado a 16 bytes; o runtime replica esse alinhamento
  para o inicio do bloco;
- strings sao empacotadas byte a byte e cada uma termina em NUL.

Forma final:

```text
+0x00  uint32_t loaderSemaphoreId (= 0)
+0x04  uint32_t argc
+0x08  uint32_t argv[argc]
...    char strings[] (referenciadas por argv, cada uma terminada em NUL)
```

## Implementacao

No submodulo `PS2Recomp`:

- `ps2xRuntime/src/main.cpp:134-152`: quando existem argumentos depois do ELF,
  encaminha `argv[1..]` como argv guest. Sem extras, nao instala override algum.
- `ps2xRuntime/src/lib/games_database.cpp:806-816`: associa o retail normalizado
  `SLUS-21355` ao slot `0x00614400`.
- `ps2xRuntime/src/lib/ps2_runtime.cpp:1260-1382`: valida os argumentos, rejeita
  NUL embutido/overflow, reserva memoria guest alta fora do heap do jogo, monta o
  bloco e conserva a publicacao pendente.
- `ps2xRuntime/src/lib/Kernel/Syscalls/System.cpp:713-719`: publica o ponteiro no
  syscall `SetupThread`, depois que `_start` zerou o slot.
- `ps2xTest/src/ps2_boot_arguments_tests.cpp`: tres testes cobrem layout,
  alinhamento, NUL terminal, publicacao no `SetupThread`, fallback vazio sem
  alocacao e rejeicao de NUL embutido sem estado parcial.

Diff do commit do submodulo: 9 arquivos, 279 insercoes e 2 remocoes.

A instrumentacao passiva e limitada de `datArgParser::Init` ficou no arquivo
gerado/gitignored `work/generated/ghidra/sub_00428AC0_0x428ac0.cpp`; ela foi
compilada apenas para produzir a prova e nao virou mudanca tracked do runtime.

## Validacao

### Suite

Suite completa oficial, CWD `PS2Recomp/out/build`, com
`C:\msys64\ucrt64\bin` no `PATH`:

```text
Total Tests: 303
Passed: 303
Failed: 0
EXIT_CODE=0
```

Os tres casos novos da suite `PS2BootArguments` passaram.

### Build e relink

- `tools/parallel_compile.py`: 1 candidato da instrumentacao, 1 compilado,
  0 falhas.
- `tools/find_stale.py`: `Missing: 0`, `Stale: 0`.
- `10_link_partial_runner.bat fast`: concluido com sucesso.
- `mc3_partial.exe`: `2026-08-29T07:46:04.4795493-03:00`.
- `libps2_runtime.a`: `2026-08-29T07:44:41.3521598-03:00`.
- Executavel mais novo que a biblioteca: **sim**.
- `missing_functions.partial.manifest.csv`: 1 linha, apenas o cabecalho.

### Trace com argumentos

Evidencia preservada em
`work/logs/boot_args_skipintro_garage_20260829_short.stderr.log:28`:

```text
[MC3_BOOT_ARGS] datArgParser::Init argc=3 argv=0x01ffffb8 argv[0]="extracted_iso\SLUS_213.55" argv[1]="-skipintro" argv[2]="-garage"
```

Isso prova que o parser do proprio jogo recebeu as opcoes; nenhuma global
`PARAM_*` foi escrita pelo host/runtime.

### Guarda sem argumentos

Evidencia preservada em
`work/logs/boot_args_no_args_20260829_short.stderr.log:28`:

```text
[MC3_BOOT_ARGS] datArgParser::Init argc=0 argv=0x00677084
```

As duas corridas curtas usaram `MC3_DETERMINISTIC=1` e
`MC3_DISPATCH_BUDGET=25000`, terminaram sem processo residual e produziram stdout
identico, na mesma ordem: 53 linhas contra 53, zero diferencas. Tirando a linha
do parser, o stderr teve apenas duas linhas TTY extras na corrida sem argumentos,
efeito de ordem concorrente de log; a sequencia de encerramento de threads foi a
mesma. O fallback retail permaneceu intacto.

## `mc3-gfx-*` e render

Nenhum trace `mc3-gfx-*` disparou na janela capturada. Um probe diagnostico mais
longo chegou a atividade grafica comum (`gifPk1=1350`, `gifPk2=518`,
`gsPrims=2725` em torno do tick 1800), mas isso esta muito abaixo do plato
conhecido e nao prova modelo 3D novo. O log foi preservado em
`work/logs/boot_args_skipintro_garage_20260829_clean.stderr.log`.

## O que nao foi provado

- Os enderecos/valores finais das globais `PARAM_skipintro` e `PARAM_garage` nao
  foram instrumentados diretamente. O que esta provado e a entrada exata no
  parser retail e sua execucao natural, que e o aceite binario definido pelo
  handoff.
- O decomp prova alinhamento de word para campos/ponteiros; nao prova que 16 bytes
  sejam uma exigencia minima do loader. O runtime usa 16 por paridade conservadora
  com o fallback compilado.
- Nao ha evidencia de que o ABI exige um ponteiro nulo depois de `argv[argc]`; o
  parser observado usa `argc`, por isso nenhum sentinela foi inventado.
- Nao foi provado salto visivel direto para garagem nesta janela curta, nem houve
  evidencia `mc3-gfx-*` de carro/modelo 3D.
