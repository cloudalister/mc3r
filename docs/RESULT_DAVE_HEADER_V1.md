# Resultado — passo 7: header "Dave" do ASSETS.DAT (gate `0x5a8908`)

Executa `docs/HANDOFF_FASE1_DAVE_HEADER.md` do início ao fim. Data: 2026-08-18. Branch `mc3`
(fork local, sem push), submódulo `PS2Recomp`. **Aceite NÃO alcançado** — achado
negativo/corretivo com causa-raiz mais precisa que a do passo 6, evidenciado por trace real.
Nenhum código de runtime tracked foi alterado; a única mudança é uma instrumentação de
diagnóstico num arquivo gerado (gitignored, ver seção "O que foi mudado").

## Resumo executivo

**O boot nunca chega a ler os 4 bytes de assinatura.** `func_3993A8` (o parser "DAEV"/"Dave"
identificado no passo 6) **nunca é chamado** nesta corrida — confirmado por
`grep -c "3993a8" <log> = 0`. A cadeia trava um passo antes: `func_4FAA10` (que chamaria
`0x3993A8`) depende de um `open()` bem-sucedido em `0x3984c0` para obter um handle; esse
`open()` recebe **um caminho vazio (`""`)** como argumento de entrada, porque o provider
ativo no momento (`0x617F88`, "T:") não reconhece nenhum dos três prefixos que trata
explicitamente (`"cdrom"`, `"host0:"`, `"pfs0:"`) e cai no ramo padrão, que monta
`prefixoPadrão + caminhoVazio = prefixoPadrão` — e o `prefixoPadrão` embutido no objeto
provider em `0x617FB0` é a string `"T:"`. `sceOpen("T:", ...)` (via `ps2_syscalls::fioOpen` →
`translatePs2Path` → `fopen` no host) falha (não existe unidade `T:` válida com esse nome),
devolve handle negativo, `sub_00399308_0x399308` interpreta `bltz` como `decision=negative`,
devolve `v0=0` até `func_4FA398`, e o `beqz $v0` em `0x5a88f0` entra no spin `0x5a8908` — que é
literalmente `nop×5` + `b` incondicional para si mesmo (não é uma espera condicional; é um
`while(1){}` puro no MIPS original).

Ou seja: a pista do passo 6 ("a leitura da assinatura devolve vazio") estava certa na
direção, mas **um nível abaixo do suposto** — não é a leitura dos 4 bytes que falha, é a
etapa de `open()` anterior a qualquer leitura. `flag619f40` continua `0x00` a corrida
inteira; o gate não sai de `0x5a8908`; o critério de aceite não foi atingido.

## Método

1. **Trace primeiro** (`MC3_BOOT_TRACE=1 MC3_TRACE_PROVIDER=1`, determinístico, budget
   200000): reproduzido 3x, mesma cadeia de eventos até o gate. Confirma o mesmo padrão já
   visto no passo 6 (`enter=0x3984c0 a0=0x00000008 a1=0x00672fe8` na leitura pré-`switch`) —
   valor de registrador retido de uma retomada, não argumento real (mesmo bug de
   instrumentação documentado em `RESULT_PROVIDER_TABLE_V1.md`).
2. Em vez de aceitar esse artefato, adicionei uma segunda instrumentação **depois** do
   `switch(ctx->pc)` de resumo em `FUN_003984c0_0x3984c0.cpp` (só dispara em entrada nova de
   verdade, nunca em retomada) que lê e imprime a string apontada por `a0` byte a byte via
   `READ8`. Recompilei o `.o` afetado (`work/compile/ghidra/batch_0027/obj/FUN_003984c0_0x3984c0.o`)
   e relinkei (`10_link_partial_runner.bat fast`) antes de medir de novo — nenhuma suíte
   rodou porque a mudança é só um `fprintf` diagnóstico atrás do mesmo env var já existente
   (`MC3_TRACE_PROVIDER`), sem novo env-gate e sem alterar comportamento do jogo.
3. Com a instrumentação nova, a chamada real do gate mostrou `path=""` (string vazia) —
   virada a partir daí para decomp dirigido: li `FUN_003984c0_0x3984c0.cpp` inteiro (as três
   comparações de prefixo + os quatro ramos de resposta) e `sub_00399308_0x399308.cpp`
   inteiro (a lógica de decisão `bltz`/`decision=negative`/spin) para confirmar a cadeia
   completa sem adivinhar nada — todo endereço de função citado abaixo foi confirmado contra
   `work/exports/retail_symbol_port.csv`.
4. Não usei `gemini -p` nesta sessão: grep dirigido + leitura pontual de decomp por função +
   extração de strings do ELF (`extracted_iso/SLUS_213.55`, seção `.rodata`, via um script
   Python de ~15 linhas para resolver VA→offset de arquivo) e a corrida real de trace foram
   suficientes para chegar a evidência de primeira mão, mais barato que uma rodada de Gemini
   sobre decomp bruto. **0 consultas Gemini usadas.**

## A cadeia completa, com evidência

```
sub_005A8898_0x5a8898  (boot, zipFile::Init)
  0x5a88dc: jal func_42F9F0(a0=sp, a1="%s%s", a2=*(0x617F84), a3=fallbackNode)
            -> sprintf-like; buffer(sp) fica vazio nesta corrida
  0x5a88e8: jal func_4FA398(a0=providerTablePtr, a1=sp)      a1 = 0x0019fe10 ("")
    0x432968 strncmp(a1, "...", 7)          [comparação não relacionada, a2=7]
    jal func_4FA488(a0=providerTablePtr, a1=sp, a2=0)
      -> sub_003991F0_0x3991f0 (backend table, US-002/BACKEND_TABLE_0x3991F0.md)
         slot0=*0x618020=0x617F88  slot1=*0x618024=0x617F88   <- AMBOS "T:" nesta corrida
         jal *(0x617F88+0)  =  sub_00398830_0x398830(a0=0x0019fe10, a1=1)
           raw617fc0=0x3984C0(open) raw617fc4=0x398610(close) raw617fd4=0x3987E0
           jal *0x617fc0 = FUN_003984c0_0x3984c0(a0=0x0019fe10, a1=1)
             strncmp(a0,"cdrom",5)  -> mismatch (a0="")
             strncmp(a0,"host0:",6) -> mismatch
             strncmp(a0,"pfs0:",5)  -> mismatch
             -> ramo padrão (0x3985c0): strcpy(sp2, *(0x617FB0)) ; strcat(sp2, a0="")
                jal func_398408 (coreFileWaitCreateSema)
                jal func_54A350 (sceOpen, host stub -> ps2_syscalls::fioOpen)
                    fioOpen(path=sp2) -> translatePs2Path(sp2) -> fopen(host) -> FALHA
                jal func_398450 (coreFileSignalSema)
             <- retorna v0 = handle negativo (sentinela observado 0xfffefffc)
         sub_00399308_0x399308: bltz($s0=handle) -> decision=negative -> v0=0
  <- func_4FA398 devolve v0=0
0x5a88f0: beqz $v0 -> 0x5A8908  (spin: nop x5 + b incondicional para si mesmo)
```

`func_4FAA10`/`func_3993A8` (o parser "Dave"/"DAEV" mapeado no passo 6) estão **downstream**
dessa cadeia e nunca são alcançados nesta corrida.

## Evidência bruta (trace desta sessão)

```
[MC3_TRACE_DAVE] fresh-entry=0x3984c0 a0=0x0019fad0 path="T:/mc3/assets/userdata/options.cfg" a1=0x00000001
[MC3_TRACE_DAVE] fresh-entry=0x3984c0 a0=0x0019fad0 path="T:/mc3/assets/userdata/default.cfg" a1=0x00000001
[MC3_TRACE_DAVE] fresh-entry=0x3984c0 a0=0x0019fe10 path="" a1=0x00000001
...
[MC3_PROVIDER_GATE] gate=0x399308 initial-result=0xfffefffc handle=0xfffefffc callback711d40=0x00000000
[MC3_PROVIDER_GATE] gate=0x399308 decision=negative handle=0xfffefffc callback711d40=0x00000000
[MC3_TRACE_PROVIDER] after-399308 result=0x00000000 table619f54=0x00617f88 flag619f40=0x00
[MC3_TRACE_INIT] after-4fa488 v0=0x00000000 flag619f40=0x00
[boot-trace:frame] tick=4 activeThreads=3 pc=0x5a8908 ra=0x5a88f0 ... gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0
```

Arquivos: `work/scratch/dave_trace3_stdout.log`, `work/scratch/dave_trace3_stderr.log`
(a corrida de referência desta sessão; `dave_trace_*`/`dave_trace2_*` são corridas
intermediárias do mesmo experimento, mantidas para auditoria).

As duas primeiras linhas (`options.cfg`, `default.cfg`) mostram que **outros subsistemas
também usam o provider `"T:"` e também falham** neste host (sem unidade `T:` real) — mas
essas chamadas toleram a falha (o boot continua). É específico do gate `0x399308`/`5a8908`
tratar qualquer handle negativo como fatal e girar para sempre, sem tentar nenhum provider
alternativo nem continuar sem esse recurso opcional.

## Por que isso é uma pista nova, não uma repetição do passo 6

O passo 6 (`RESULT_PROVIDER_TABLE_V1.md`) já sabia que o provider ativo era `0x617F88` ("T:")
e que a chamada terminava em `0xfffefffc`, mas não sabia **com que caminho** o `open()` era
chamado — a suspeita registrada era que o problema estava em `func_3993A8`/`func_4FAA10` (o
parser da assinatura, chamado depois de um open bem-sucedido). Esta sessão prova que:

1. O `open()` em si já falha, antes de qualquer leitura de assinatura.
2. Falha porque recebe um **caminho relativo vazio**, não porque o provider "T:" en si seja
   inválido como conceito — "T:" + caminho vazio = "T:" sozinho, que não é um path válido em
   lugar nenhum.
3. Os dois slots de provider (`0x618020` e `0x618024`, mapeados em
   `docs/BACKEND_TABLE_0x3991F0.md`) **já estão ambos apontando para `0x617F88`** neste
   ponto do boot — não há alternância entre slot "T:" e slot "pacote" (`0x619F58`) em jogo
   aqui; os dois já são "T:" simultaneamente.

## Por que não corrigi nesta sessão (sem fix seguro disponível)

A única forma de fazer o gate sair de `0x5a8908` sem "chutar bytes" seria uma destas:

- **Preencher o buffer vazio com um caminho real de `ASSETS.DAT`** — mas não há decomp que
  mostre qual deveria ser esse caminho aqui; `func_42F9F0("%s%s", *0x617F84, fallbackNode)`
  produzir string vazia pode ser o comportamento *correto* deste probe específico (uma
  tentativa opcional de override de devkit que é normal falhar em retail), e forçar um
  caminho fabricado seria dado inventado, proibido pelo `STATUS.md`.
- **Fazer o provider `0x618020`/`0x618024` apontar para `0x619F58` (pacote) neste ponto** —
  exigiria achar quem deveria ter escrito esse global antes deste ponto do boot e por que não
  escreveu (não localizado nesta sessão; busca por escritas literais a `0x618020` no corpus
  de decomp não encontrou nenhuma — só a leitura em `sub_003991F0_0x3991f0.cpp`; a escrita
  real provavelmente usa endereço calculado em registrador que não aparece como o literal
  hex `0x618020` no C++ gerado, exigindo rastreamento adicional não feito aqui).
- **Tratar handle negativo como não-fatal em `sub_00399308_0x399308`** — mudaria o
  comportamento do dispatcher genérico (código compartilhado, usado por outros call sites),
  fora do escopo de "servir a assinatura pelo caminho legítimo" e um risco de regressão em
  outros gates já fechados.

Qualquer uma dessas é uma decisão de próximo passo, não uma "consequência direta do trace" —
por isso parei aqui, em vez de arriscar uma correção não evidenciada.

## O que foi mudado (só diagnóstico, sem efeito em jogo)

`work/generated/ghidra/FUN_003984c0_0x3984c0.cpp` — arquivo gerado, **gitignored**
(`work/` está em `.gitignore`; não entra em nenhum commit). Adicionei um bloco atrás do
`switch(ctx->pc)` de resumo (ou seja, só roda em entrada nova de verdade, nunca em retomada
por preempção — o mesmo tipo de correção de instrumentação que `RESULT_PROVIDER_TABLE_V1.md`
recomendou e não chegou a fazer) que imprime a string apontada por `a0` quando
`MC3_TRACE_PROVIDER=1` está setado. Reusa o env var já existente; não introduz gate novo.
Recompilado (`g++ -std=c++20 -msse4.1 ... -c ... -o work/compile/ghidra/batch_0027/obj/FUN_003984c0_0x3984c0.o`)
e relinkado via `10_link_partial_runner.bat fast`. Efeito em jogo: nenhum (só `fprintf` em
`stderr`).

**Nota de ambiente descoberta nesta sessão**: `g++`/`cc1plus.exe` (MSYS2 ucrt64) falha
silenciosamente (sem stdout/stderr, exit code 1) quando `C:\msys64\ucrt64\bin` não está no
`PATH` do processo que o invoca — `cc1plus.exe` não acha `libmpfr-6.dll` e morre sem
mensagem. Isso derrubou as duas primeiras tentativas de recompilar nesta sessão (o `.o`
antigo, de 01/08, não tinha sido de fato substituído apesar de um `exit=0` aparente — bug de
verificação minha, não do compilador: eu tinha capturado o exit code de um `tail` no pipe, não
do `g++`). Corrigido prefixando `PATH="/c/msys64/ucrt64/bin:$PATH"` antes de invocar `g++`
diretamente. Vale registrar em `docs/WORKFLOW.md`/`STATUS.md` para não repetir.

## Régua de render (inalterada)

`dma=2 vif=3 gif=0 gsw=0 gifPk1/2/3=0 gifPkTotal=0 gsPrims=0 gsPixels=0` — mesmos valores dos
passos anteriores. PC estável determinístico continua `0x5a8908`/`0x5a88f0`. Não é M4;
`21_probe_repeat.bat 3 probe m4_confirm` não se aplica.

## Aceite

**Não alcançado.** `flag619f40` permanece `0x00` durante toda a corrida (3 corridas,
determinístico); o gate não sai de `0x5a8908`; os bytes `44 61 76 65` ("Dave") nunca chegam
a ser lidos porque `func_3993A8` nunca é chamado.

## Próximos passos sugeridos (não executados nesta sessão)

1. **Achar quem deveria escrever `0x618020`/`0x618024` com `0x619F58`** (ou por que ambos já
   valem `0x617F88` neste ponto do boot) — provavelmente exige rastrear a construção do
   endereço via registrador (não o literal hex) nas funções de inicialização do asset
   manager/`zipFile`, ou capturar mais cedo no boot (antes de `sub_005A8898_0x5a8898`) se
   algum init de pacote roda e é sobrescrito depois.
2. **Decodificar `func_42F9F0`/o vararg `"%s%s"`** em `0x5a88dc` — entender se um buffer
   vazio ali é esperado (probe de override opcional, deveria falhar graciosamente) ou é sinal
   de um global (`0x617F84`, endereço adjacente ao provider `0x617F88`) que também deveria
   ter sido inicializado antes.
3. Mover as instrumentações de diagnóstico "roda antes do switch de resumo" identificadas no
   passo 6 (`sub_00399308`, `sub_00398830`, `sub_003991F0`) para depois do switch, como já
   feito aqui para `0x3984c0` — evita mais leituras erradas de `a0`/`a1` em sessões futuras.
4. Registrar a descoberta do bug de `PATH`/`libmpfr-6.dll` em `docs/WORKFLOW.md` (seção de
   ambiente) para acelerar recompilações futuras.

## Suíte e commits

Nenhum arquivo de runtime tracked foi alterado (só o gerado/gitignored citado acima) —
suíte não rodou (regra do `WORKFLOW.md`: só medir/rodar suíte quando há mudança de código
tracked). `git status` no repo raiz e no submódulo `PS2Recomp` não mostram nada para
commitar além do próprio handoff (`docs/HANDOFF_FASE1_DAVE_HEADER.md`, já presente antes
desta sessão) e deste RESULT doc — nenhum commit de código foi necessário.
