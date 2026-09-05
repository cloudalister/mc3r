# VU1 budget capture - 2026-09-05

## Objetivo

Identificar as execucoes de 65.536 ciclos observadas na cena posterior ao boot.
O contador antigo registra `executed >= budget`: sozinho nao distingue parada
normal no ultimo ciclo de esgotamento sem E-bit. Nao e porcentagem de tempo real.

## Instrumentacao passiva

`PS2Recomp/ps2xRuntime/src/lib/ps2_vu1.cpp`, opt-in
`MC3_VU1_BUDGET_TRACE=1`. Limite global de oito ocorrencias por processo.

- Entrada/saida PC, VI de entrada/saida, ITOP, E-bit e branch pendente.
- Motivo real de saida: `budget`, `end-bit`, `pc-out-of-range`.
- Ultimas 32 posicoes do orcamento: instrucao dupla e VI antes de executar.
- FNV-1a de toda a memoria de codigo, apenas nas ocorrencias capturadas.
- `MC3_VU1_BUDGET_DUMP=<prefixo>` salva codigo e dados **finais**, sem sobrescrever.
  Nao e snapshot de entrada e nao permite prometer replay deterministico.

Nenhuma mudanca no orcamento, nas instrucoes, nos locks ou no scheduler.
O contador historico continua incluindo a tentativa com PC invalido; `reason`
permite identificar isso. `ebit=1 reason=budget` significa que a sinalizacao
foi vista mas o delay slot pode ainda nao ter terminado.

## Build e testes

- Runtime compilado em RelWithDebInfo (-O2), apesar do nome Debug no batch antigo.
- Relink absoluto `10_link_partial_runner.bat fast` concluido com exit 0.
- Exe 19:55:00, lib 19:53:50; tres strings novas confirmadas no executavel.
- Dois novos testes: E-bit com limites 1/2/8 preserva um delay slot; branch infinito
  para PC zero executa exatamente 65.536 ciclos sem inventar E-bit.
- Suite executada com PATH UCRT64 e cwd `PS2Recomp`: **311/311 passaram**.
- Suite repetida com a captura ligada: **311/311 passaram**. Log real confirmou
  oito eventos (limite respeitado), `ebit=1 reason=budget` com um ciclo,
  `reason=end-bit` com dois, e loop sem E-bit com tail de 32 passos.
  Os 16 arquivos de codigo/dados tiveram tamanho correto (`ok=1`).
- Parser `tools/Analyze-VuBudget.ps1` validado com fixture sintetica e com esse
  log real. `tools/Test-AnalyzeVuBudget.ps1` passou.
- Primeiras tentativas de teste nao contam como aprovacao: sem PATH nao gerou
  resultado; com PATH e cwd errado foram 310/311 (arquivo de fixture nao localizado).
  Logs preservados. Resultado valido: `work/logs/vu_budget_tests_correct_cwd_20260905.log`.

## Corrida

`tools/Probe-FrontendWrites.ps1 -Seconds 900 -Label vu_budget_astra_20260905 -TraceVuBudget`

Headless, serial, scheduler padrao, mesmos parametros de START/tempo de fase do
probe anterior. Metadados com hashes: `work/logs/probe_vu_budget_astra_20260905.log.meta`.
Os testes (~3 segundos cada) rodaram no inicio desta captura; a corrida e para
diagnostico funcional, nao para comparacao de velocidade.

Baseline encerrado deliberadamente apos obter as oito capturas, para liberar o
executavel para relink. Processo 28564, identidade/caminho/inicio conferidos antes
de encerrar: 19:56:14.494 a 20:08:07.316. O harness terminou em **716 s** e marcou
`exitedBeforeLimit`; isso foi encerramento do experimento, nao crash espontaneo.
CPU imediatamente antes de encerrar: 382.75 s (195.484375 usuario, 187.265625 kernel).
O JSON final do harness tem CPU nula apos encerramento externo; esses valores foram
lidos do processo vivo imediatamente antes de parar, nao extraidos daquele JSON.
465 blocos completos: ultimo `vu1Cycles=577504739`, `vu1CapHits=7858`.
453 amostras de animacao, zero regressao, maximo/final 8.

## Causa capturada

Todas as oito chamadas: entrada **PC 0x0030**, mesmo codigo FNV **0a669b31**, ITOP
alternando 152/453. Todas sairam por `reason=budget ebit=0`. Cada tail de 32 passos
repete o bloco **0x2820..0x2868**, dez instrucoes duplas.

Em **0x2838**, palavra inferior **0x2c070002**, o programa manda `FSAND VI7, 2`.
O interpretador escrevia sempre em **VI1**, zerando o contador/endereco do loop.
Em 0x2840, `IADDI VI1, VI1, 3` elevava esse zero a tres. Em 0x2860, `IBNE`
comparava VI1=3 com VI5=0x1ad e voltava para 0x2820. O contador era apagado na
proxima volta. Os valores antes/depois estao no tail, nao foram inferidos apenas
pela leitura de codigo.

Referencia de semantica, consultada em 2026-09-05:
[PCSX2 VUops.cpp, FSAND](https://github.com/PCSX2/pcsx2/blob/master/pcsx2/VUops.cpp#L1248-L1257).
O destino e o campo It e o imediato de 12 bits usa os bits 10:0 e 21 da instrucao.
Implementacao local alterada somente nesse opcode; sem importar codigo do PCSX2.

## Correcao e prova reduzida

FSAND agora escreve no VI codificado, descarta VI0 e decodifica corretamente o bit
alto do imediato. **Nao alteramos branch, E-bit, scheduler nem os 65.536 ciclos.**

Dois testes novos falharam antes: **311/313**, log `vu_budget_fsand_red_20260905.log`.
Depois da correcao: **313/313**, log `vu_budget_fsand_green_20260905.log`.
Cobertura: VI7 preserva VI1, imediato alto, VI0, e cadeia FSAND/incremento/branch
derivada da captura. O loop reduzido agora chega ao fim em dez ciclos.

O investigador economico fez revisao somente leitura e nao encontrou erro concreto.
Ha defeitos analogos em FSEQ/FSOR e suspeita em FSSET, **nao alterados neste lote**:
ficam como investigacao separada para nao misturar a causalidade do experimento.

## Validacao no jogo

Corrida `vu_fsand_fixed_astra_20260905`, iniciada 20:10:32, planejada para 900 s.
Exe relinkado 20:09:21, lib 20:07:34. Hashes no `.meta`:

- exe: `38f379d929822b0d5db21952e2ed1b33b7c68e0025452f1ca6af9b0675bf3e52`
- lib: `b631cb135b80ee767367f6088b120278e440e5d2c39cd817a8ed9e45d9fc60f2`

Concluida em **901.417 s**, parada pelo proprio harness no limite, sem crash antecipado.
Nenhum processo `mc3_partial` permaneceu rodando. CPU450.40625s (271.515625 usuario,
178.890625 kernel). **624 blocos completos**, ultimo89.339.312 ciclos VU e **82 caps**.
596 amostras de animacao, zero regressao, maximo/final18; 30 eventos de escrita,
14 Updates, timer0.461999923. Ultimo bloco GS completo:1.099.186 primitivas e
851.848.298 pixels.

Comparacao descritiva, nao benchmark de FPS:

| Corrida | Parede | Caps | Posicao final da animacao |
|---|---:|---:|---:|
| Sonda de escritas anterior (sem correcao) | ~901s | 15.852 | 21 |
| Baseline deste lote (encerrada apos captura) | 716s | 7.858 | 8 |
| FSAND corrigido | 901s | 82 | 18 |

O padrao FSAND sumiu dos primeiros oito casos capturados e o total de caps caiu
fortemente, mas **nao demonstramos ganho de FPS nem avancamos mais a animacao que
na corrida anterior de igual duracao**. Trabalho renderizado/caminhos mudam com a
correcao. A sonda confirma uma correcao de semantica, nao uma vitoria de performance.
Boot/menu continuam nao aceitos. Commit runtime: **721a97b**.

### Segundo alvo capturado (nao corrigido)

Na corrida corrigida, os primeiros oito caps sao de OUTRO codigo: entrada
**0x0060**, FNV **a57d6e03**, ITOP338. `reason=budget ebit=0`, PCs finais entre
0x0308 e 0x0400. Isso nao prova que surgiu com a correcao: o limite de oito
amostras da baseline foi consumido pelo primeiro padrao.

Fluxo: 0x01c8 XTOP VI4; 0x01d0 ILWx VI5,0(VI4); 0x01f0 soma VI4 a VI5;
0x0218 decrementa VI5; 0x0400 compara VI5 com VI4 e volta a 0x01f8.
Tail do caso0: VI4=0x152, VI5=0xfffffd76. Os 16 bytes do header em **0x1520**
estao zerados no dump FINAL. Contagem inicial zero e uma hipotese compativel,
mas precisa ser confirmada na entrada: nao e snapshot inicial nem prova de
loop infinito (registrador de 16 bits pode eventualmente dar a volta).

**Pista prioritaria para a proxima rodada:** em `ps2_vu1.cpp`, XTOP e XITOP leem
ambos `m_state.itop`. O callback MSCAL/MSCNT recebe somente ITOP. Em
`ps2_vif1_interpreter.cpp`, MSCAL alterna DBF/recalcula TOPS, mas nao salva TOP
antes de chamar o VU1. Verificar o contrato TOP/TOPS/ITOP/ITOPS e capturar os
quatro valores + header antes do MSCAL de entrada0x60. Nao tratar TOP como ITOP
por mera conveniencia, nem pular o programa porque o header observado e zero.
Referencia primaria confirma que sao fontes diferentes:
[PCSX2 XTOP e XITOP](https://github.com/PCSX2/pcsx2/blob/master/pcsx2/VUops.cpp#L1798-L1806)
(XITOP em linhas1683-1692). A divergencia de implementacao esta confirmada;
a sua responsabilidade por este header zero ainda exige captura de entrada.

Proximo lote: teste discriminante TOP diferente de ITOP; teste de latch TOP/TOPS
antes da troca DBF em MSCAL/MSCNT; sonda limitada ao codigo a57d6e03/entrada0x60;
so depois alterar a passagem desses valores entre VIF1 e VU1 e repetir o boot.

Dump pontual ao ultrapassar700k primitivas: apresentacao e contexto0 inspecionados,
**ambos pretos**. Portanto a imagem/menu nao foram destravados por esta correcao.
