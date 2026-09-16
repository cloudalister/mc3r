# Direção para o lote de 3h (alarme/boot) — revisão do plano de 08/09

Data: 09/09/2026. Revisor: Claude (a pedido de Cloud). Alvo: `docs/PLANO_3_HORAS_ALARME_BOOT_2026-09-08.md`.

**Veredito: aprovado com condições.** A disciplina do plano é boa (sem sinal forçado, sem scheduler, evidência antes de correção). O problema é que ele aponta a sonda para a etapa errada e o orçamento de 180 min só fecha se o lote for declarado diagnóstico desde o início.

## 1. A fronteira escolhida vem DEPOIS de onde o tempo é gasto

Do próprio `RESULT_TIMER_ROUTE_2026-09-06.md`:

- Alarme SID214 armado com `delay 1474560`. 1.474.560 ticks a 147,456 MHz (BUSCLK cheio) = **exatamente 10 ms**. O jogo pediu 10 ms.
- Esse alarme só aparece como `early=0` (prazo atingido) na última linha completa de seleção, `tMs 7895010`, ou seja **~67 s depois de armado** — e o log acaba aí.
- O `cv-wait` de 65 s da thread principal bate com esses 67 s.

Ou seja: durante os 65 s de espera, o alarme **não estava selecionável**, porque o prazo não tinha sido alcançado. A etapa que consumiu o tempo é *antes* da comparação em `0x54ce80`, não depois. Instrumentar `54ce8c → 54cd70 → 54ced0 → 54ced8 → 54d640` (retirada da fila / callback / wrapper) é instrumentar um trecho que o log nunca chegou a exercer para esse alarme. Pode até ser a próxima fronteira, mas não é a que explica os 65 s.

Reforço: nos lotes anteriores as esperas **terminam**, só que tarde (SID220 esperou 272 s e foi sinalizada; 9 esperas de 10 ms levaram 57–739 ms). Isso é assinatura de *relógio/prazo errado*, não de *recado perdido*. A hipótese "o despertador toca e o recado não chega" precisa ser rebaixada a uma entre duas.

## 2. Passo 0 obrigatório (custo: ~20–30 min, zero build)

Antes de qualquer edição no runtime, responder com o log que já existe (`probe_timer_route_astra_20260906.log.stderr`, 119 amostras de seleção com `s1=now`, `s2=threshold`, `tMs`):

1. **Taxa do relógio guest:** ajustar uma reta de `now` (s1) contra `tMs` ao longo do log. Esperado ≈ 147.456 ticks/ms se o `now` está em BUSCLK. Reportar a inclinação global **e** a inclinação só na janela dos últimos 70 s. Se a janela final anda muito abaixo de 147.456 ticks/ms, o relógio guest desacelera/para sob alguma condição — e aí a investigação é Timer2 COUNT/overflow/acúmulo no runtime, não callback.
2. **Sanidade do prazo:** para cada um dos 5 alarmes armados, calcular `threshold − now_no_momento_de_armar`. Deve dar ≈ `delay` (1474560). Se der um número muito maior, o cálculo do prazo (ou a leitura de `now` no momento de armar) está errado.
3. **Latência armar→callback dos 4 que funcionaram:** se 10 ms viraram segundos também neles, é o mesmo bug em versão branda; se foram rápidos, o que difere no quinto?

Detalhe estranho pra checar de passagem: `now 88009113600 / 147456000 ≈ 596,8 s`, quase o wall-clock total da run (601 s). Isso sugere que o `now` acompanha o relógio de parede *na média* — então como o alarme armado ~67 s antes ficou com `threshold` a só 10 ms do `now` final? Ou o `now` deu salto, ou o `threshold` foi calculado a partir de um `now` velho. A pergunta 2 acima resolve isso.

Só depois do passo 0 decidir qual sonda escrever. Se a resposta for "relógio/prazo", a sonda da seção "Fronteira técnica delimitada" fica para outro lote.

## 3. Orçamento de 180 min: realista só como lote de diagnóstico

Histórico de 06/09: cada lote com sonda nova + build + 1 run de 10 min + relatório levou na prática 30–60 min, e nenhum chegou a correção. Este plano quer: baseline, sonda nova com correlação entre threads, subagente de auditoria, build/relink, suíte, 2 runs de 10 min, decisão, correção com teste de regressão, revalidação com 3ª run e relatório. Não cabe.

Ajustes:

- Declarar já no cabeçalho: **lote de diagnóstico**. Correção só entra se sobrar ≥ 40 min após a 2ª run E o passo 0 tiver apontado uma linha específica. Caso contrário a "correção" vira proposta escrita no relatório.
- Cortar a 3ª run do orçamento. Duas runs de 10 min sequenciais já são 20 min + análise; a terceira só se for validação de correção real.
- A "sonda opcional e passiva" da faixa 20–55 só é escrita depois do passo 0. Se o passo 0 apontar relógio, a sonda muda de lugar (Timer2 COUNT/overflow e ponto onde `now` é acumulado).

## 4. Higiene que vale dinheiro

- As alterações de instrumentação de 06/09 continuam **não commitadas**. Antes de editar mais: `git stash`/`git diff` salvo em `work/patches/probe_timer_route_20260906.patch` + hash, ou commit local numa branch `probe/timer-route`. Sem push. O plano fala em "preservar por patch" — fazer isso no minuto 0, não no 165.
- Registrar hash do executável que roda cada run no `.meta` (já é prática; manter).
- Não aceitar a frase "não é diagnóstico de relógio parado" como se fechasse o assunto de *relógio lento/prazo errado*. São coisas diferentes.

## 5. Entrega esperada no fechamento (além do que o plano já lista)

- Tabela: alarme → `now` ao armar, `threshold`, `delay`, `now` na seleção, latência real, callback sim/não.
- Inclinação ticks/ms global e na janela final, com o método (arquivo/linhas usadas).
- Uma frase em português simples para Cloud: *o relógio do jogo anda na velocidade certa? o prazo foi calculado certo? o recado chegou?* — com sim/não/não sei em cada uma.

Aprovação do lote fica com Cloud. Este documento só redireciona o começo.
