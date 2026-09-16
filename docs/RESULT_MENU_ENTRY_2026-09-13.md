# Entrada do menu: registro sobrescrito em33FEB0

## Defeito reproduzido

O titulo ativo espera que o componente em title+FC termine sua transicao.
O objeto16ddf40/vtable628878 fica em estado+368=5 com byte+42D=0.
O Update virtual+24 e33FEB0; o Render virtual+28 e3404D0. A tabela do Render
652BF0[5]=34098C testa42D==10 e so entao escreve368=0 em3409A0.
O Update original incrementa42D de0 ate10; a condicao em340060 nao pula isso.

O cadastro de funcoes instala FUN_0033feb0 e depois o sobrescreve por
sub_0033FD80. Esse corpo contem33FEB0 internamente, mas seu switch de entrada
nao aceita esse PC; cai no inicio33FD80. Ter o label interno nao basta.
Nao generalizamos esse defeito para todos os aliases.

menu_registration_tests.cpp foi ligado com o MESMO register_functions.partial.o
e objetos da resposta de link do probe. O fixture inicial tinha uma expectativa
errada sobre Render; os logs de falha foram preservados. Baseline2 corrigiu
somente essa expectativa e mostrou:

- Update: canonical0,overlap1; Render: canonical1,overlap0.
- Estado5/42D0: chamada via registro mantem0; corpo canonico produz1.

O teste isola os helpers posteriores ao incremento. Nao cria janela, nao
executa boot do jogo nem altera saves. A prova cobre a selecao de funcao e o
incremento real; o desbloqueio no jogo ainda depende da execucao abaixo.

## Mudanca isolada, OFF por padrao

MC3_MENU_ENTRY_FIX=1 preserva apenas a primeira entrada registrada em33FEB0.
O registro compilado instala primeiro o corpo canonico. Nao altera3404D0,
outros enderecos, flags de tela, memoria de estado, eventos ou contadores guest.
E um reparo limitado ao registro atual; nao substitui uma politica geral para
aliases/regeneracao. Ausente/0 conserva o comportamento anterior.

Fixture compilado OFF:registryCounter0;ON:registryCounter1,UpdateCanonical1,
RenderCanonical1. Suite331/331 passou OFF/ON. O experimento de relogio e
independente e esta OFF nesta execucao para isolar o efeito desse registro.

## Execucao concluida: saida do titulo destravada

Headless menu_entry_20260913_a,PID7880, iniciado07:20:51 e encerrado
deliberadamente07:33:17 apos746.407s,CPU652.766s. Exit-1 e parada documentada,
nao crash. Tres capturas; nenhum runner permanece ativo.
MC3_MENU_ENTRY_FIX=1; bridge/STQ ON; frame host clock/depth OFF;
START30s pressionado/30s solto apos45s; mesmos traces e capturas do baselineB.
Saida interna do titulo confirmada; menu visual utilizavel ainda NAO aceito.

Evidencia incremental em leituras de memoria do proprio probe:

- 07:23:27: node42D=5 (antes ficava0),node368=5.
- 07:25:09: node42D=10,node368=5. A conclusao do Render nao foi imediata.
- Trace integro tick25200:node368=0; tick26400:6; tick27480:titleFlags974,
  titulo inativo. Houve outros ciclos5/6/0 do componente compartilhado.
- 07:30:22 e07:32:45: estado ATUAL do painel(+D8)=40, titulo inativo,
  node368=0,42D=10. E o estado solicitado pelo handler de entrada do titulo.

Correcao de nomenclatura da sonda: o campo JSON antigo panelState le+E0,
que continuou1; NAO e o estado atual+ D8. panelCurrentD8=40 e o dado correto
para a transicao. frontendScreen617984 permaneceu6 e nao e aceito sozinho
como indicador da tela atual. Nenhum timer foi forcado a30s: title130 para
em0.0251049,canTransitionCalls0 e frame host clock OFF nesta corrida.

Ultimo frame integro tick40560,prims5504328,titleUpdate157,mensagens43,
titleFlags974,node3680,StartPublishes408.140frames integros,443rejeitados
por intercalacao. run/analysis_final.json conserva as transicoes relevantes.

A captura3 conserva faixas brancas e fundo com defeitos. Ela NAO confirma
um menu legivel/navegavel. O componente ativo no slotB0 e1725d50,vtable62BDE0,
Update37EC18; ainda nao rotulamos essa tela como menu principal/perfil.
O ganho confirmado e a passagem do titulo para estado40, sem escrita forcada
de estado nem mudanca do relogio.

Artefatos: <scratch-dir>/mc3-menu-entry-20260913

- Exedfae148e105033eba268e398fe02f3a7ca0572ac4d67e26612c20ef60918a5e5
- Libca699895bee6b3cf6907f4e75e37099a9c55d35aeac187cca87fa2586d1c6dd6
- bin/VERIFIED.json e tests/PASS_entry.json, logs completos das fixtures.
- baseline/ps2_runtime.cpp preserva fonte anterior ao reparo de registro.

Originais E: preservados. Sem janela visivel, skip de intro ou alteracao de save.
Fechamento: CLOSURE.json confere hashes dos tres pares exe/lib de diagnostico,
do executavel original e dos quatro conjuntos de logs/capturas desta investigacao.

## Proxima fronteira

Manter MC3_MENU_ENTRY_FIX=1 ao reproduzir esse avanco, deixando o experimento
MC3_FRAME_HOST_CLOCK e depth OFF. A correcao ainda e opt-in no binario de teste.
Investigar o desenho da tela ativa37EC18/62BDE0 e a origem das faixas, preservando
a animacao/cameras originais. O Render do componente de entrada chegou a
concluir; nao retomar a hipotese de que ele nunca e chamado.
O alias externo34098C tem limitacao de entrada, mas o salto de tabela DENTRO
de3404D0 usa switch interno que aceita esse label; nao atribuir a espera a ele.
