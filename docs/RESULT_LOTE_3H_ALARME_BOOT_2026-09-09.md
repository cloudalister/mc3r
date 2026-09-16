# Lote de diagnóstico do alarme — 09/09/2026

Estado: CONCLUÍDO como diagnóstico, sem correção de comportamento. Autorização de Cloud e agenda em
`docs/PLANO_3H_DIAGNOSTICO_REVISADO_2026-09-09.md`. Início01:41 Brasília, teto04:41.

## Preservação antes da instrumentação

Baseline completo: `work/patches/timer_route_baseline_20260909_014537/`.
Contém root.patch/runtime.patch, fontes geradas dos cinco owners, objetos,
executável/lib anteriores, header não rastreado e documentos/ferramentas pertinentes;
hashes.csv para conferir. Dois diretórios anteriores têm tentativa de inventário
incompleto; não são o baseline selecionado. Nada foi removido/revertido.

## Passo zero: log antigo, nenhuma nova execução

Ferramenta: tools/Analyze-TimerClock.js. Entrada:
work/logs/probe_timer_route_astra_20260906.log.stderr.

OLS com timestamps de seleção não nulos, únicos. Global116 amostras, linhas384 a
9184:147450,20866ticks/ms (99,99607% de147456). Janela final70s,13 amostras,
linhas9004 a9184:147462,29022ticks/ms (100,00427%). OLS de amostras não exclui
pausas/saltos entre elas, nem comprova identidade contínua dos nós.

| SID | Alarme externo | Armed linha | Callback após armed |
| --- | --- | --- | --- |
| 201 | 0703e1bd | 8915 | 5ms |
| 207 | 0703e0c5 | 8946 | 6ms |
| 209 | 0703e0c9 | 8958 | 3ms |
| 212 | 0703e0cf | 8981 | 10ms |
| 214 | 0703e0d3 | 8990 | Não registrado |

nowAoArmar e threshold-nowAoArmar: NÃO MEDIDOS no log antigo. Não interpolados.
Não há prova de prazo não vencido durante65s, nem de callback perdido. Corrigida
a interpretação forte anterior: interrupções ativas não provam entrega do alarme.

## Sonda implementada: identidade e preparação do prazo

Passiva, sob MC3_TIMER_WAIT_TRACE=1, sem mudança de instrução guest, sinal,
scheduler, timer ou locks. Novo histórico no header ps2_timer_route_probe.h:
duas lanes de produtor único (main e IRQ normal),2048 slots imutáveis cada,
publicação release/acquire, contagem dropped ao saturar. Reporte periódico existente.
Primeiras8 comparações e primeiras8 chamadas por geração; não é histórico ilimitado.

Campos comuns: seq,kind,gen,sid,id(interno),entry,tMs,a,b,c,d,e,f.

| Kind | Captura | Campos específicos |
| --- | --- | --- |
| 1 | antes54d420, configuração pretendida | a=delay,b=target,c=wrapper |
| 2 | após store54d338, base temporal | a=now retornado de54d048,b=flags prévios |
| 3 | antes54cd0c, threshold para inserção | a=threshold,b=base,c=ajuste,d=delay derivado |
| 4 | antes54ce80, comparação do endereço observado | a=now,b=threshold,c=early |
| 5 | após delay slot54ced4, antes chamada | a=ID interno real,b=target,c=a1,d=a2,e=a3,f=ID igual ao configurado |

Kind1 é tentativa anterior à validação, não prova de armamento. Kind2 ocorre no
store da base guest, não exatamente na mensagem armed do wrapper. Kind3 precede
a inserção efetiva. Kind4 casa endereço, não confirma ID; kind5 expõe o ID real.
ID interno da entrada Timer2 NÃO é o alarme externo do wrapper. Correlacionar
wrapper, SID, geração e os registros timer-wait, sem equiparar os dois IDs.

Owners: sub_0054D3F8,sub_0054D2C8,sub_0054CCE8,FUN_0054cda8,sub_0054CD70.
Nos dois últimos a sonda contempla os owners sobrepostos da seleção/chamada.
Hook antigo compared permanece intacto. Nenhuma leitura nova da memória guest.

## Validação antes da primeira rodada

- Teste nativo da sonda: filtro de thread, clock64bits, campos de prazo, slot com
  ID reutilizado, cap por geração, snapshot ímpar, publicação concorrente e saturação:PASS.
- Analisador: precisão64bits, linhas incompletas, dados ausentes e log vazio:PASS.
- Verify-IrqList:60/163/177/43/34 anotações conferem com ELF dos cinco owners.
  Isso não é teste semântico completo do C++.
- Build de runtime e326/326 testes:PASS. Compilação dos cinco owners:PASS.
- Relink e marcas timer-identity/timer-identity-cap/timer-route-select:PASS.
- Teste com gate desligado:PASS, nenhum evento emitido. Overhead ativo não medido.
- Fontes instrumentadas/diffs/hashes:work/patches/timer_identity_sources_20260909_015409.

## Execuções e conclusão

### Rodada1 — concluída

Label timer_identity_r1_20260909. Início01:53:19, fim02:03:21;601,0299012s,
CPU185,125s, sem saída precoce. Executável SHA256:
c4ec432c8ed640c3a112951838c726d3adc509e552f79cf3de74b1cc2aa5e3d9.
Biblioteca:7e85699338f976f23c8722c64dde2d2d8d57f3e70f1eebd8b6390fa9cd978329.

61 eventos novos completos,0 malformados; main33,IRQ28; dropped0 nas duas lanes.
11 gerações configuradas, todas com kind2 e kind3. Em todas,threshold-base=
1474560ticks,ajuste0. Nas primeiras chamadas de cada geração:ID interno igual,
target54d640 e argumento wrapper igual ao configurado.11armed/11callback/11woke
nos registros timer-wait. Configuração->primeira chamada:15,1,6,14,2,11,13,5,1,6,5ms.
Não equiparar isso à latência desde o registro externo armed, que ocorre depois.

Reutilização observada, não apenas risco teórico: gen1,gen5,gen10 apresentam uma
chamada extra com ID DIFERENTE (f0), no mesmo entry e mesmo endereço wrapper,
depois do sinal e antes do woke da thread principal. Por exemplo gen1:
callback36038902,signal-return36038942; chamada com ID0701e40f às36039133;
woke36039149. Não atribuir essa chamada ao alarme0701e40d. Assim, até a igualdade
de wrapper/endereço é insuficiente sem ID real. Isso demonstra uma ambiguidade
dos bancos antigos, NÃO prova que explica o incidente SID214.

A espera inicial SID200/RA398b28 durou270094,6896ms;CV270094,5709ms e token0,1095ms.
É outra espera, anterior à sequência de timer; não somar sua causa aos alarmes.
Última main-wait: none-covered,tokenWait50ms,owner8,dispatch52a080,entry42b150Calls0.
Não houve reprodução da espera longa de timer nesta rodada, nem correção/aceitação
visual. Dados completos nos JSONs Analyze-TimerClock e Analyze-TimerIdentity do label.

### Rodada2 — concluída

Label timer_identity_r2_20260909. Início02:03:59, fim02:14:00;601,1129089s,
CPU193,328125s, sem saída precoce. Mesmo executável/lib e hashes da rodada1.
As duas execuções foram encerradas pelo limite do harness, não por saída natural.

51 eventos completos,0 malformados; main27,IRQ24; dropped0 nas duas lanes.
9 gerações: todas com base/prazo registrados, threshold-base1474560ticks,
primeira chamada com ID interno, target54d640 e wrapper esperados.
9armed/9callback/9woke. Configuração->primeira chamada:
14,2,20,14,1,0,6,9,12ms. Zero significa mesmo milissegundo registrado, não
latência física nula. Mais três chamadas extras de outros IDs, gens1,5,7.

Inclinação global147453,145763ticks/ms; últimos70s147481,672978ticks/ms.
A espera inicial SID79/RA398b28 durou325867,6401ms;CV325867,4819ms,
token0,1471ms. Última main-wait:none-covered,tokenWait329ms,owner8,
dispatch2a9b7c,entry42b150Calls80. Contagem de execução não comprova menu ou FPS.

Análises finais: work/logs/probe_timer_identity_r1_20260909.Analyze-TimerClock.v2.json
e Analyze-TimerIdentity.v2.json; para r2, mesmos sufixos sem .v2. Os JSONs
salvos pelo PowerShell incluem BOM UTF-8; consumidores Node devem removê-lo
antes de JSON.parse. As versões anteriores foram preservadas.

### Conclusão

Nas duas rodadas,20/20 alarmes observados tiveram prazo configurado de1474560ticks
(10ms nominais), primeira chamada com identidade esperada e despertar registrado.
Isso NÃO prova ausência de falha intermitente: a espera longa histórica não
reapareceu. A causa do SID214 segue inconclusiva; não há linha culpada comprovada
nem justificativa para alterar relógio, scheduler, sinalização ou código guest.

Achado confirmado: seis chamadas extras reutilizaram o endereço observado com
outro ID. Portanto o snapshot antigo por endereço pode confundir instâncias.
Essa ambiguidade foi demonstrada, mas não atribuída como causa do incidente antigo.
A sonda nova permite separar as instâncias em uma próxima reprodução.

O lote utilizou aproximadamente40 minutos do teto de3h e encerra após as duas
rodadas previstas. Não foi feita terceira rodada nem correção especulativa.
326/326 testes de runtime passaram, testes isolados de gate ligado/desligado e
analisador passaram. Nenhum teste visual, aceitação de menu ou ganho de FPS.
O executável atual é de diagnóstico instrumentado; overhead ativo não medido.

Próximo lote recomendado: investigar separadamente quem deveria sinalizar a
espera inicial RA398b28, que durou270s e326s nestas execuções. Primeiro mapear
produtor/sinal e condições de chegada, sem forçar despertar. Para a falha rara
de timer, reutilizar a sonda por identidade quando o stall reaparecer; não
repetir conclusões do snapshot antigo como se fossem evidência por instância.

## Proveniência e entrega

HEAD raiz:4c106930b8461bc197dfdcbf1913c83222d95f58.
HEAD runtime:2af51f7037eff0012b0c6a725ce64f33da948ca3.
Sem commit/push/reset/stash, sem alteração de dashboard e sem janela aberta.
Alterações deste lote: header de sonda, hooks passivos nos cinco owners gerados,
lista de compilação, ferramentas de preservação/análise/teste/relink, plano e
este relatório/checkpoint. Alterações anteriores preservadas nos backups acima.
Os diffs dos owners contêm caminhos absolutos; as cópias de fonte e hashes
acompanham para reprodução, não presumir aplicação portátil com git apply.
Após as rodadas, nenhum processo mc3_partial permaneceu em execução.
