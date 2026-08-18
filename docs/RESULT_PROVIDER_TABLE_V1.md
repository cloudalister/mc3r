# Resultado — passo 6: o `a0=7` da tabela de provider (gate `0x5a8908`)

Executa `docs/HANDOFF_FASE1_PROVIDER_TABLE.md` do início ao fim. Data: 2026-08-18. Branch `mc3`
(fork local, sem push), submódulo `PS2Recomp`. Nenhuma linha de código de runtime ou de jogo foi
alterada nesta sessão — achado negativo/corretivo, sem fix seguro disponível ainda.

## Resumo executivo

**O `a0=7` que a sessão anterior (`RESULT_MAINLOOP_DRAW_V1.md`, Bloco C) apontou como a causa —
"`func_399308` recebe `a0=0x00000007` (inteiro pequeno) onde se esperaria ponteiro" — é um
artefato de leitura do trace, não um argumento real.** Uma corrida nova com
`MC3_TRACE_PROVIDER=1` (mesmo binário, mesma instrumentação já existente) reproduz a mesma linha
(`enter=0x399308 a0=0x00000007 a1=0x00672fe8 a2=0x00000003`), mas cruzando com o decomp
(`sub_00399308_0x399308.cpp`) fica provado que essa linha nunca pode vir de uma chamada nova: o
print de `a0/a1/a2` fica **antes** do `switch(ctx->pc)` que decide se a função está entrando do
zero ou retomando (`resume`) num label no meio do corpo — e o print específico do caminho "entrada
nova" (`399308-dispatch table=... fn0=... fn14=...`, logo antes do primeiro `jalr`) **não aparece**
nessa linha, provando que é uma retomada no label `0x399338` (logo depois do `jalr`), não uma
chamada nova. `a0/a1/a2` nesse ponto são o que quer que os registradores `$a0-$a2` estejam
guardando **no momento exato da retomada** — não os argumentos da chamada original, porque MIPS
não garante que registradores caller-saved (`$a0-$a3`) sobrevivam a um ponto de preempção que o
compilador original nunca previu (`shouldPreemptGuestExecution()` é um contador de back-edges
periódico, dispara a cada 64, **sem relação com bloqueio real** — `ps2_runtime.cpp:2029-2044`).

A chamada real e legítima (`4FA398→4FA488→0x399308`, argumento vindo do boot em `0x5a8898`) usa um
ponteiro de caminho válido, não `7`: `enter=0x399308 a0=0x0019fe10 a1=0x00617f88 a2=0x00000001`
(única linha do arquivo com `a2=1`, a constante real de todo caller conhecido). Essa chamada
**chega de verdade** no backend `0x3984c0` ("open" do provider `0x617F88`, `"T:"`) com o caminho
certo, mas o resultado final — depois de toda a cadeia de I/O real (CreateSema/WaitSema/SIF RPC)
rodar — é o sentinela negativo `0xfffefffc`, que `0x399308` interpreta como falha
(`decision=negative`) e devolve `v0=0` para `4FA398`, fechando o gate. **A causa raiz não mudou de
natureza em relação à sessão anterior — continua sendo "provider `T:` (host devkit) sendo usado em
vez do provider de pacote real (`0x619F58`)" — mas a evidência específica que apontava para
`a0=7` como sintoma dessa causa estava errada**, e por isso o próximo passo concreto muda.

## Método

Handoff pedia: decomp dirigido de `func_4FA398`↔alpha nomeado; trace de `sceCdRead`/
`zipFile::zipOpen`; correção na camada certa; 1 corrida = 1 prova. Segui exatamente essa ordem —
decomp primeiro (achei a inconsistência antes de rodar nada), depois trace ao vivo para confirmar
ou refutar.

## O que é o `7` — três `7`s diferentes, nenhum deles o argumento de `399308`

1. **`func_4FA398:0x4fa39c`** (`sub_004FA398_0x4fa398.cpp:38-40`): `addiu $a2, $zero, 0x7` — um
   `7` **real e literal** no MIPS, mas é o terceiro argumento de `func_432968` (uma rotina de
   string/comparação chamada logo no início de `zipFile::Init`), nunca chega perto da tabela de
   provider. Confirmado na corrida: `enter=0x432968 a0=0x0019fe10 a1=0x0066d809 a2=0x00000007`.
2. **`func_4FA398`'s `a1`** (o argumento que a sessão anterior confundiu com "a0=7" da tabela): não
   é um inteiro — é `sp` do chamador (`sub_005A8898_0x5a8898.cpp:171-172`,
   `daddu $a1, $sp, $zero` no delay slot do `jal func_4FA398`), i.e. o endereço de um buffer que
   `func_42F9F0` (um `sprintf`-like: monta `a2..a3,t0-t3,f12-f18` como vararg e chama
   `func_42FA98`) formatou um instante antes. Na corrida real esse ponteiro virou
   `a1=0x0019fe10`/`0x0019fad0` (endereços de pilha válidos), nunca `7`.
3. **O `a0=7` que aparece nos prints de `enter=0x399308`/`enter=0x398830`/`enter=0x3984c0`**: é
   conteúdo de registrador **retido de uma chamada anterior**, capturado no ponto exato em que o
   interpretador retoma a função no meio do corpo depois de uma preempção cooperativa (ver seção
   seguinte). Não achei, em nenhum dos 4 call sites reais de `0x399308` no código do jogo
   decompilado (`sub_004FA488_0x4fa488.cpp`, `sub_004F91E8_0x4f91e8.cpp`,
   `FUN_003c8cf8_0x3c8cf8.cpp`, `FUN_001a0608_0x1a0608.cpp` — os únicos 4 `jal func_399308` em todo
   `work/generated/ghidra/`), nenhum que passe `a2` diferente de `1` — o `a2=0x00000003` observado
   junto do `a0=7` também não corresponde a nenhuma chamada real.

## Por que o `a0=7` nunca é um argumento real — prova por eliminação de estrutura

`sub_00399308_0x399308.cpp:19-24` (chamada real, código gerado):

```cpp
if (std::getenv("MC3_TRACE_PROVIDER")) std::fprintf(stderr,
    "[MC3_TRACE_INIT] enter=0x399308 a0=0x%08x a1=0x%08x a2=0x%08x\n", ...);
switch (ctx->pc) {              // <-- o print acima roda ANTES desta decisão
    case 0x399338u: goto label_399338;   // retomada pós-primeiro-jalr
    ...
}
ctx->pc = 0x399308u;            // caminho "entrada nova" continua daqui
```

O print `[MC3_TRACE_INIT] 399308-dispatch table=... fn0=... fn14=...` só existe no caminho
"entrada nova" (linha `0x39932c`, antes do primeiro `jalr`). A linha real capturada com `a0=7` **não
tem esse print entre `enter=` e `[MC3_PROVIDER_GATE] gate=0x399308 initial-result=...`** — a
segunda linha (`gate=... initial-result=`) é exatamente o print que existe **só** no label
`0x399338` (pós-`jalr`, dentro do `switch`). Logo essa entrada só pode ser uma retomada em
`0x399338`, nunca uma chamada nova — o `a0/a1/a2` impressos são lixo de registrador daquele
instante, não argumento.

Confirmação adicional em `398830`: o print `[MC3_TRACE_PROVIDER] backend-return slot=0x617fc0
pc=0x%08x result=...` (`sub_00398830_0x398830.cpp:67-69`) roda **depois** de chamar o backend
(`jalr`) mas **antes** de checar se `ctx->pc` bateu no label de retorno esperado (`0x398848`). Na
corrida real esse print mostrou `pc=0x00432da8` (primeira tentativa) e `pc=0x00548e70` (segunda
tentativa, caminho real com `0x0019fe10`) — **nenhum dos dois é `0x398848`/`0x398870`** (os únicos
dois labels de retorno válidos de `398830`), provando que a chamada ao backend (`0x3984c0`)
**preemptou no meio** (dentro da cadeia real de I/O — `CreateSema`/`WaitSema`/SIF RPC) e ainda não
tinha retornado de verdade quando o print rodou.

## Causa da preempção — não é bloqueio real

`shouldPreemptGuestExecution()` (`ps2_runtime.cpp:2029-2044`) é um contador `thread_local` de
back-edges: preempta a cada 64 iterações **sempre**, em modo determinístico, **sem relação com
`WaitSema` bloqueando de verdade**. Confirmado na corrida: os únicos dois `WaitSema:block` reais
do log inteiro são de `tid=2`/`tid=3` (não a thread principal, `tid=1`, que faz toda a cadeia do
provider) — toda `WaitSema` de `tid=1` nessa janela é `WaitSema:wake` (não bloqueia). A preempção
que corta `398830`/`399308`/`3984c0` no meio é puramente o contador de 64 back-edges, não um
`WaitSema` real — o que é esperado e correto para o scheduler cooperativo (Fase 2, congelado por
`STATUS.md`); o problema não está no scheduler, está em como o **print de diagnóstico** lê
registradores caller-saved sem saber se está numa entrada nova ou numa retomada.

## O resultado final é real (não é artefato) — e é negativo

Diferente de `a0/a1/a2`, o `v0` (`$2`) **é** confiável nesse ponto: é o registrador de retorno
MIPS, sempre escrito pelo callee bem antes do `jr $ra`, então `initial-result=0xfffefffc` em
`gate=0x399308` é o valor real devolvido pela cadeia `398830→3984c0` depois de toda a I/O rodar —
não um artefato de preempção. A chamada real com o caminho válido (`0x0019fe10`, provider `T:`,
`0x617F88`) **termina em falha determinística**, sentinela `0xfffefffc`. `func_4FA398` devolve
`v0=0` (`[MC3_TRACE_INIT] after-4fa488 v0=0x00000000`, log linha 997), o `beqz $v0` em `0x5a88f0`
salta para o spin `0x5a8908`. Isso é consistente — não contraditório — com a hipótese já registrada
em `RESULT_MAINLOOP_DRAW_V1.md`/`PROVIDER_LIFECYCLE_FLAGS.md`: o provider ativo em `0x618020`
continua sendo `0x617F88` ("T:", redirecionador de sistema de arquivos de devkit host) durante toda
a corrida, nunca `0x619F58` (provider de pacote/textura); `flag619f40` fica `0x00` a corrida
inteira (a assinatura mágica `"DAEV"`/`"Dave"` nunca é reconhecida por `func_4FAA10`, único
mecanismo estático encontrado que trocaria o provider ativo). Um provider `T:` falhando
determinística e imediatamente é o comportamento **esperado** num ambiente sem devkit host
conectado — a pergunta que continua sem resposta é por que o jogo nunca troca para o provider de
pacote real.

## O que o trace descartou

- **Não é corrupção de contexto entre threads.** Cada thread PS2 real (`StartThread`,
  `Kernel/Syscalls/Thread.cpp:362-363`) tem seu próprio `R5900Context` (`threadCtxCopy`); a thread
  principal (`tid=1`) usa `m_cpuContext`, dedicado, dirigido por `dispatchLoop`
  (`ps2_runtime.cpp:1777-1902`) que só chama `lookupFunction(ctx->pc)` e nunca mistura registrador
  de outra thread.
- **Não é bug do scheduler determinístico.** `DeterministicScheduler.cpp` só usa mutex +
  `condition_variable` para arbitrar turno entre threads reais; não copia nem edita
  `R5900Context::r[]` de ninguém.
- **Não é literal `7` gravado errado em lugar nenhum do jogo.** Os três `7`s da seção acima são
  coisas diferentes; nenhuma edição de bytes seria capaz de "consertar" o `a0=7` observado, porque
  ele não é um dado — é uma leitura de registrador feita cedo demais pelo próprio print de
  diagnóstico.

## Reprodução

```bat
set MC3_DETERMINISTIC=1
set MC3_DISPATCH_BUDGET=200000
set MC3_TRACE_PROVIDER=1
set MC3_BOOT_TRACE=1
work\link\partial\mc3_partial.exe extracted_iso\SLUS_213.55 > work\logs\probe_a0_7_stdout.log 2> work\logs\probe_a0_7_stderr.log
```

Evidência bruta desta sessão: `work/logs/probe_a0_7_stderr.log` (1013 linhas),
`work/logs/probe_a0_7_stdout.log`. Linhas citadas: 685-687 (primeira tentativa, `0x19fad0`),
974-997 (tentativa real com o caminho válido `0x19fe10`, `initial-result=0xfffefffc` final).

## Régua de render (inalterada)

`dma=2 vif=3 gif=0 gsw=0 gifPk1/2/3=0 gifPkTotal=0 gsPrims=0 gsPixels=0` — mesmos valores de
`RESULT_MAINLOOP_DRAW_V1.md`. PC estável determinístico continua `0x5a8908`/`0x5a88f0`. Não é M4;
`21_probe_repeat.bat 3 probe m4_confirm` não se aplica (regra do handoff só pede isso na vitória
grande).

## Por que parei aqui (sem corrigir)

O handoff pedia "corrigir na camada certa pelo caminho legítimo" **depois** de entender o `a0=7`.
Entendi o `a0=7` — e a conclusão é que ele não é a causa; a causa continua sendo a seleção de
provider, exatamente como a sessão anterior já tinha mapeado (`PROVIDER_LIFECYCLE_FLAGS.md`,
`BACKEND_TABLE_0x3991F0.md`). Consertar a seleção de provider (por que `func_4FAA10` nunca
reconhece `"DAEV"`/`"Dave"`, ou por que o jogo não usa o provider `0x619F58` desde o início) exige
decodificar o conteúdo real lido do disco/pacote nesse ponto (`func_3993A8`, o parser dos 4 bytes
de assinatura, e o que alimenta ele) — decomp que não fiz nesta sessão porque o objetivo do handoff
era especificamente o `a0=7`, e essa pista se provou um beco sem saída (diagnóstico, não causa).
Mudar a seleção de provider sem essa evidência seria "chute de bytes" — proibido pelo `STATUS.md`.

Corrigir a **instrumentação** (mover os prints de `enter=`/`backend-return`/`backend-call` para
depois do `switch(ctx->pc)`, ou marcar explicitamente quando é retomada vs. entrada nova) é seguro,
puramente diagnóstico (atrás de `MC3_TRACE_PROVIDER`, não muda comportamento do jogo) e evitaria
esse tipo de leitura errada em sessões futuras — não fiz porque não move o gate e o orçamento desta
sessão foi consumido pela investigação; fica como recomendação concreta abaixo.

## Próximos passos sugeridos (não executados nesta sessão)

1. **Instrumentação**: mover os `fprintf` de diagnóstico de `sub_00399308_0x399308.cpp`,
   `sub_00398830_0x398830.cpp`, `sub_003991F0_0x3991f0.cpp` para depois do `switch(ctx->pc)` (ou
   condicioná-los a `ctx->pc == <entry address>`), para não confundir sessões futuras com valores
   de retomada. Diagnóstico-only, sem risco.
2. **Seleção de provider (o gate real)**: decodificar `func_3993A8` (parser dos 4 bytes de
   assinatura que `func_4FAA10` compara contra `"DAEV"`/`"Dave"`) e o que alimenta esses bytes —
   provavelmente o resultado de um `sceCdRead`/RPC ainda incompleto ou uma resposta que o runtime
   está entregando com conteúdo errado/vazio. Objetivo: entender por que a assinatura mágica nunca
   bate, o que mantém `0x619F40=0` a corrida inteira e o provider preso em `0x617F88` ("T:").
3. `docs/BACKEND_TABLE_0x3991F0.md` e `docs/PROVIDER_LIFECYCLE_FLAGS.md` continuam válidos e são o
   ponto de partida — nenhuma correção necessária nesta sessão além desta nota de que o `a0=7` não
   é a pista certa.

## Suíte e commits

Nenhum arquivo de runtime, jogo ou config foi alterado — suíte não fica sujeita a regressão desta
sessão, não rodei `ps2x_tests` de novo (regra do `WORKFLOW.md`: só medir/rodar suíte quando há
mudança de código). Nenhum commit criado (nada para commitar: só leitura + logs de trace em
`work/logs/`, que não fazem parte da árvore de commit do runtime).
