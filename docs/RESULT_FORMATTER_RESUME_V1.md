# Resultado — passo 9: o sprintf mudo, a classe de gaps de resume, e o gate seguinte

Executa `docs/HANDOFF_FASE1_FORMATTER_RESUME.md` do início ao fim. Data: 2026-08-18. Branch
`mc3` (fork local, sem push), submódulo `PS2Recomp`. **Aceite alcançado**: `sub_0042F558`
formata corretamente, o path `cdrom0:\cdrom0:\assets.dat` fica visível no `open()` do
provider, o gate `0x5a8908` foi atravessado, e a classe (não só uma função) foi fechada na
geração — `work/exports/resume_gaps.csv` confirma **0 gaps** no corpus inteiro (15774
funções) depois do fix. O boot avança e para num gate **novo**, adiante: `0x245718`
(`bad=0x540838`, função não implementada), reproduzido determinístico 3/3.

## Mecanismo confirmado (PC exato)

A suspeita do handoff (tabela de resume incompleta no `switch(ctx->pc)`, mesma doença do
precedente `0x42EB48`) estava certa na *família* do bug, mas não na causa específica que o
handoff descrevia. Não é gap de retomada pós-preempção cooperativa (essa sub-classe está
**vazia** — auditoria: 0 ocorrências em todo o corpus, ver seção "Diagnóstico da classe").
É uma sub-classe irmã, nunca antes fechada:

1. `FUN_0042fa98_0x42fa98` (trampolim de vararg) monta `$a2 = 0x42EB48` via
   `lui $v0,0x43` (`0x42fa9c`) seguido, **9 instruções depois** (dentro do delay slot do
   próprio `jal func_42F558`), de `addiu $a2,$v0,-0x14B8` (`0x42fac4`) — o idioma clássico
   de `la $a2, 0x42EB48` que o compilador original expressa como `lui`+`addiu` quando o
   registrador de destino (`$a2`) é diferente do registrador que carrega a metade alta
   (`$v0`).
2. Esse `$a2` vira `$s5` dentro de `sub_0042F558_0x42f558` (`0x42f564`:
   `daddu $s2,$t1,$zero`... na verdade `$s5 = $a2+0` em `0x42f57c`) e é usado como alvo de
   **`jalr $s5`** em 4 call sites (`0x42f730`, `0x42f964`, `0x42f9a0`, `0x42f9b0`) — o motor
   de formatação despachando para um "handler de especificador" por endereço computado.
3. Como `0x42EB48` não é alvo de nenhum `jalr` resolvido como jump table (não há `lw` de
   tabela antes do `jalr`; o valor vem de um argumento cross-função), a análise estática
   por função nunca vê esse alvo — cai no fallback `runtime->lookupFunction(jumpTarget)`.
4. `0x42EB48` cai dentro do intervalo de `sub_0042EB08_0x42eb08` (`0x42eb08`-`0x42ebd8`,
   intervalo já estendido por uma pass anterior do recompiler para cobrir o "buraco órfão"
   que o Ghidra não atribuiu a nenhuma função — `work/exports/SLUS_213.55.ghidra.csv` mostra
   `FUN_0042eb08` terminando em `0x42EB48` cru). `lookupFunction` encontra a função
   corretamente (sem `[dispatch:first-bad-pc]` — por isso o bug nunca apareceu nos logs
   anteriores), mas **`sub_0042EB08_0x42eb08.cpp` não tinha `switch (ctx->pc)` nenhum** —
   toda entrada, não importa o PC, caía direto em `ctx->pc = 0x42eb08u;` e executava a
   função **do zero**, com `a0`/`a1` sendo o que quer que o call site tenha deixado ali
   (não os argumentos que o label `0x42EB48` esperava).

Confirmado por trace ao vivo (instrumentação `MC3_TRACE_PROVIDER`, atrás do env var já
existente, em dois arquivos gerados/gitignored) antes do fix:

```
[MC3_TRACE_RESUME_GAP] sub_0042F558 external-jalr jumpTarget=0x0042eb48 ra=0x0042f9b8 a0=0x00000053 a1=0x0019fc30
[MC3_TRACE_RESUME_GAP] sub_0042EB08 entered-with pc=0x0042eb48 a0=0x00000053 a1=0x0019fc30 ra=0x0042f9b8 (no switch(ctx->pc) in this function -> always restarts at 0x42eb08)
```

Mais de 100 ocorrências na mesma corrida (uma por caractere de `"SYSTEM\"`,
`"cdrom0:\assets.dat"` etc. sendo processado pelo motor de formatação) — cada uma reiniciando
`sub_0042EB08` do zero com o `a0` errado (código de caractere ASCII, não o que a função
esperava), explicando por que o motor devolvia `v0=0` (chars escritos) sistematicamente.

## Diagnóstico da classe — `tools/Find-ResumeGaps.py` / `work/exports/resume_gaps.csv`

Script novo (`tools/Find-ResumeGaps.py`), varre **todo** `work/generated/ghidra/*.cpp`
(15774 funções) e cobre duas sub-classes distintas do mesmo sintoma ("switch(ctx->pc) sem
case pro PC de entrada → reinício silencioso do zero"):

- **Mecanismo A** (hipótese original do handoff — gap pós-preempção cooperativa, mesma
  família do precedente `0x42EB48`/`0x42EB90` de 07/08): compara todo
  `if (runtime->shouldPreemptGuestExecution()) { return; } goto label_X;` contra os `case`
  do `switch(ctx->pc)` da mesma função. **0 gaps reais no corpus inteiro** — essa sub-classe
  já estava fechada (o gerador atual já popula `resumeEntryPoints` corretamente para todo
  back-edge preemptível; confirmado lendo `collectInternalBranchTargets` em
  `code_generator.cpp` e validando com o scan). A hipótese "bug de preempção" do handoff foi
  **refutada** por essa varredura — mas apontou na direção certa (função irmã, mesmo
  sintoma).
- **Mecanismo B** (a causa raiz real, seção acima): compara todo par `lui`+`addiu`/`ori`
  (idioma `la`, com busca até 64 instruções à frente e detecção de "registrador
  sobrescrito antes de ser consumido") que constrói uma constante caindo **dentro do corpo**
  de outra função (validado contra o conjunto real de endereços de instrução dessa função —
  não só o intervalo `[start,end)`, para não confundir constante-que-coincide-numericamente
  com endereço-de-instrução-de-verdade) contra os `case` do dono. **95 gaps reais**
  encontrados antes do fix, cobrindo **80 funções-dono** distintas em todo o binário — a
  classe inteira, não só `sub_0042EB08`.

Validação do script: rodado contra o arquivo `sub_0042EB08_0x42eb08.cpp` **pré-fix**
(backup) + `FUN_0042fa98_0x42fa98.cpp`, acusa corretamente o gap `0x42eb48`; rodado contra o
corpus **pós-fix** completo, **0 linhas** (só cabeçalho) — a classe está fechada.
`work/exports/resume_gaps.csv` no repo reflete o estado pós-fix (vazio = classe fechada).

## O fix — na geração, não patch manual

Local: `PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp`,
`CodeGenerator::collectInternalBranchTargets` (função já existente, que roda tanto por
função — `generateFunction` — quanto no passo whole-program —
`PS2Recompiler::discoverAdditionalEntryPoints`). Novo bloco: para todo `lui $r,hi` seguido
(não necessariamente adjacente — até 64 instruções depois, respeitando se o registrador foi
sobrescrito antes) de `addiu`/`ori $r2,$r,lo` no MESMO registrador fonte, calcula a
constante resultante e chama `queueExternalEntryTarget(constant)` — o mesmo lambda já usado
para `J`/`JAL` estáticos cross-função e para jump tables resolvidas, então a validação
downstream (`PS2Recompiler::discoverAdditionalEntryPoints`, que exige o alvo bater um
endereço de instrução real da função candidata, não só cair no intervalo) já filtra qualquer
falso positivo — over-matching aqui é seguro (pior caso: um `case` extra nunca alcançado).

Não é chute: o padrão (`lui`+`addiu`/`ori` cross-registrador construindo endereço de código
tomado por outra função, consumido via `jalr` em uma TERCEIRA função) é exatamente o
mecanismo que o precedente de 07/08 já tinha documentado sem nomear a causa
(`docs/HANDOFF_2026-08-07_B_DISPATCH_0x42EB48.md`, opção B2 "corrigir o gerador" nunca
implementada até agora).

Teste novo em `PS2Recomp/ps2xTest/src/code_generator_tests.cpp`
("lui/addiu address-taken constant into another function's body is an external entry
candidate") — reproduz o padrão real (`lui`/`addiu` não-adjacentes, ~9 instruções de
distância, igual ao caso de produção) e prova que `collectInternalBranchTargets` marca o
alvo como `externalEntryPoints`.

## Funções regeneradas/recompiladas

Fix aplicado no recompiler → `04_run_recomp.bat` (TOML `work/exports/SLUS_213.55.ghidra.toml`
tinha paths absolutos obsoletos de outra máquina, `D:/TARS/...`; corrigidos localmente para
`E:/...` — arquivo gitignorado, não é mudança tracked) regenerou o corpus inteiro
(15811 arquivos, ~36s, só geração de texto). Diff estrutural (pares `registerFunction`
antes/depois, ignorando reordenação de `unordered_map`) isolou exatamente **80 funções-dono**
com conteúdo realmente alterado (95 registros de entry point novos + 11 realocados para o
dono correto). Essas 80 (lista completa: `sub_0042EB08_0x42eb08` e mais 79, ver
`work/scratch/changed_owner_symbols.txt` desta sessão — não versionado, é `work/`) foram
recompiladas (`g++ -std=c++20 -msse4.1 ...`, mesmas flags de
`tools/Compile-GeneratedBatch.ps1`) e os `.o` colocados no batch correto de cada uma
(conferido via `work/batches/ghidra/*.csv`, lição do incidente de 09/08 registrada em
`docs/RESULT_BOOT_ARGS_V1.md`) — sem duplicata (`find work/compile/ghidra -iname
"<sym>.o"` = 1 ocorrência cada). Mais um arquivo, `FUN_004fa2b8_0x4fa2b8.cpp`, recebeu só
instrumentação diagnóstica (print do path no `open()` do provider, atrás de
`MC3_TRACE_PROVIDER`) — sem mudança de comportamento.

Relink: `10_link_partial_runner.bat` (sem `fast`, para regenerar
`register_functions.partial.cpp`/`.aliases.csv` a partir do corpus atual — o alias CSV
anterior estava **stale**, com uma entrada pré-existente para `0x42eb48`→`sub_0042EB08`
rotulada `"switch-case"` que já não batia com o `.cpp` real, achado incidental que explica
por que `lookupFunction` nunca reportava "not found" para esse PC apesar do `.cpp` não ter
switch). `168173` aliases internos gerados, `15811` funções registradas.

## Trajetória do gate

Antes (todas as sessões desde 17/08): `flag619f40=0x00` a corrida inteira, PC estável
determinístico `0x5a8908`/`0x5a88f0`, `vsnprintf-return v0(len)=0`.

Depois do fix, mesma corrida (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000
MC3_TRACE_PROVIDER=1`):

```
[MC3_TRACE_ARGS] at=0x42fac8 vsnprintf-return v0(len)=26 destBase(s0)=0x0019fe10 preview="cdrom0:\cdrom0:\assets."
[MC3_TRACE_ARGS] provider-open fn=0x4fa2b8 a0(request)=0x0019fe10 path="cdrom0:\cdrom0:\assets.dat"
```

`v0=26` (não mais `0`), path completo e não-vazio chega no `open()` do provider (função
`FUN_004fa2b8_0x4fa2b8`, backend de uma tabela de provider **diferente** da anterior:
`table=0x00619fc8`, não mais `0x617f88` "T:" — o boot passou a consultar um provider
diferente do redirecionador de devkit host). O prefixo duplicado (`cdrom0:\cdrom0:\`) não é
bug desta sessão: `RESULT_BOOT_ARGS_V1.md` já tinha provado que o nó default em
`0x637e03` (o segundo argumento do `%s%s`) **já vem com `"cdrom0:\assets.dat"` embutido**
na tabela estática do jogo — o formato concatena os dois como o código original manda.

`21_probe_repeat.bat 3 probe formatter_resume_fix` (determinístico, budget 25000):

| Corrida | Stable PC | First bad PC | Classificação |
|---|---|---|---|
| 1/2/3 | `0x245718` (idêntico nas 3) | `0x540838` | `missing-function` |

3/3 idêntico — **o gate `0x5a8908` foi atravessado**; o boot avança e para num ponto novo,
adiante na cadeia: função não implementada em `0x540838` (`ra=0x540814`,
`sub_00245680_0x245680` é a função que contém o PC estável `0x245718`). Isso é o padrão
esperado do projeto ("fechar um gap revela o próximo, não regressão nova") — fora do escopo
deste handoff, registrado aqui como achado para a próxima sessão. O probe script acusa
`DETERMINISTIC-FAIL` (marcador de budget ausente, timeout=yes) — a corrida real termina
mais cedo que os 8s do modo `probe` porque o processo agora fecha a janela raylib e sai
sozinho (`stdout`: `Window closed successfully`) em vez de ficar preso no spin antigo;
recomendo a próxima sessão usar um budget/timeout maior ou investigar esse encerramento
antecipado antes de medir o próximo gate.

## Régua de render (M4)

`gifPk1=0 gifPk2=0 gifPk3=0 gifPkTotal=0 gsPrims=0 gsPixels=0 dma=2 vif=3 gif=0 gsw=0` —
inalterada. **M4 não alcançado** (precisa `gifPackets>0` E `gsPrims>0`) —
`21_probe_repeat.bat 3 probe m4_confirm` não se aplica.

## Suíte e commits

`ps2x_tests.exe` (`PS2Recomp/out/build`, rebuild completo após o fix):
**268/270** — as 2 falhas são as mesmas conhecidas e documentadas, não tocadas por este
trabalho: `VU0 macro mappings cover all S1/S2 enums` (falha única pré-existente, ver
`RESULT_FASE2_SCHED_V1.md`) e `sceGsSyncV waits on VBlank and reports interlaced field
parity` (flaky histórica de timing, ver `RESULT_GSYNCV_METRICS_V1.md`). 270 é 269+1 porque
este handoff acrescentou 1 teste novo. **268 ≥ 266, dentro da regra do `STATUS.md`.**

Nenhum env-gate novo, nenhum `SignalSema`, scheduler intocado (Fase 2 congelada), nenhum
chute de bytes (todo endereço veio de decomp/trace, nunca inventado).

Commits locais (sem push):
- Submódulo `PS2Recomp`: `ps2xRecomp/src/lib/code_generator.cpp` (fix),
  `ps2xTest/src/code_generator_tests.cpp` (teste novo).
- Repo raiz: `tools/Find-ResumeGaps.py` (script novo), `work/exports/resume_gaps.csv`
  (gitignorado — **não** commitado, é artefato de `work/`), este RESULT doc,
  `docs/BOOT_PROBE_STATUS.md` (atualizado automaticamente pelo `15_auto_boot_probe`/probe
  tooling ao rodar a medição oficial — reflete a corrida real, não editado à mão).

## Aceite

**Alcançado**: path `cdrom0:\cdrom0:\assets.dat` visível no `open()` do provider (trace) +
`work/exports/resume_gaps.csv` gerado com a classe mapeada (0 gaps restantes — a classe
inteira foi fechada nesta sessão, 80 funções, não só o caminho crítico). Gate `0x5a8908`
atravessado; boot avança até um novo bloqueio determinístico em `0x245718`/`0x540838`,
achado e registrado para a próxima sessão.
