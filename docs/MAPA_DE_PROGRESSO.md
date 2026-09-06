# MC3 — mapa do que conhecemos e do que já funciona

Atualizado em 06/09/2026. Base: código e evidências locais; nenhuma nova execução
do jogo nesta auditoria. Este é um mapa de cobertura, não uma porcentagem de jogo pronto.

Adendo02:20, lote posterior: [sonda da espera](RESULT_MAIN_WAIT_2026-09-06.md)
passou319 testes e observou a espera inicial terminar após pelo menos361,9s.
Animação avançou até11, mas surgiram recoveries de entradas sem registro, também
presentes no controle anterior. Integridade dessas chamadas é gate de aceite;
não considerar boot/menu resolvidos nem transformar contagem de fontes em cobertura.

## Resumo sem linguagem técnica

Temos boa parte das peças identificadas. Já vimos a abertura desenhar, arquivos
serem lidos e comandos de controle chegarem ao jogo. Ainda não comprovamos o
caminho completo até escolher um carro e correr. A lentidão e as esperas da
abertura continuam sendo a primeira barreira.

## A porcentagem que podemos calcular

Conferência direta dos CSVs locais nesta auditoria:

| Medida | Resultado | O que significa |
|---|---:|---|
| Entradas no catálogo de funções/labels retail | 15.812 | Denominador do catálogo, não tamanho do jogo em trabalho |
| Entradas com nome associado do alpha | 8.815 — **55,7%** | Há uma identificação automática associada |
| Entradas sem essa associação | 6.997 — **44,3%** | Não têm nome por esse método; podem ter investigação manual |
| Associações por hash de instruções normalizadas | 6.695 | Evidência estrutural mais forte; não valida comportamento |
| Associações por relações entre chamadas | 2.120 | Evidência mais fraca, requer confirmação quando usada |
| Porcentagem entendida ou jogável | **Não medida** | Não temos cobertura de comportamento nem aceite por sistema |

Fontes: `work/exports/SLUS_213.55.ghidra.csv`,
`work/exports/retail_symbol_port.csv` e [relatório do método](SYMBOL_PORT_REPORT.md).
O CSV contém 8.815 endereços distintos. Os nomes vêm de outra versão do jogo.
Um nome associado não significa função entendida, correta ou executada.

O [índice histórico](FUNCTION_INDEX.md) lista 15.811 fontes geradas para 15.812
entradas. Hoje a pasta contém 15.832 arquivos `.cpp`; arquivos adicionais não
equivalem a novas funções cobertas. Não usamos essa contagem como porcentagem
de recompilação, linkagem ou funcionamento. Tampouco 318 testes equivalem a
318 funções do jogo validadas.

## Mapa por sistema

“Parcial” sempre se refere aos caminhos examinados, nunca ao sistema inteiro.
“Sem prova” significa ausência de evidência suficiente nesta auditoria, não
que a funcionalidade esteja ausente do código. Testes abaixo são evidências
existentes, não uma suíte reexecutada nesta tarefa.

| Sistema | Identificado? | Entendido? | Já vimos funcionar? | O que foi testado / o que falta |
|---|---|---|---|---|
| Código recompilado e execução básica | Catálogo e despacho | Parcial | Executa a abertura por vários minutos | Decodificador/runtime têm testes; não há validação de todas as funções [1] |
| Organização das tarefas e esperas | Threads e algumas travas | Parcial | Há avanço e correções de travas verificadas | Espera atual da principal ainda sem causa exata; não está “resolvido” [2] |
| Leitura do disco e arquivos | CD, SIF e arquivos | Parcial | Caminhos de leitura e carregamento observados | Há testes de bytes/arquivos; não prova carregar toda cidade [3] |
| Conteúdo do jogo (assets) | Arquivos e alguns caminhos de carga | Parcial | Conteúdo da abertura aparece | Arquivos compactados e handles têm testes; coleção completa não validada [3] |
| Preparação dos gráficos (VIF/VU) | Caminho conhecido | Parcial, com erros específicos corrigidos | Processa trabalho real da abertura | Replays e testes das correções passaram; não certifica todas as cenas [4] |
| Desenho e apresentação da imagem | GIF/GS/framebuffer | Parcial | Logo/tela legal legíveis no histórico | Capturas recentes quase pretas; não há aceite visual atual do menu [5] |
| Abertura e menus | Estado frontend e animação | Parcial | Animação avançou em rodadas anteriores | Última sonda não avançou; menu navegável não comprovado [2][6] |
| Controle | Teclado, PADMAN e START | Parcial | START entregue em headless | Testes do pacote/input; não prova dirigir nem navegar todo menu [7] |
| Gerenciador de rede | Thread, callback e parte da cadeia | Parcial | Callback real medido | 468 retornos, média411ms inclusiva na última sonda; não prova rede/multiplayer funcional [2] |
| Áudio | Backend e chamadas | Parcial no backend | Sem prova de áudio correto em jogo nesta auditoria | Código play/stop/VAG/RPC existe; falta escuta de música, efeitos e sincronização [8] |
| Save / cartão de memória | API e backend | Parcial no backend | Handshake observado historicamente | Testes básicos de leitura/escrita; falta salvar carreira, fechar e carregar [9] |
| Garagem e escolha do carro | Estado e símbolos encontrados | Só pontos isolados | Garagem não alcançada no ensaio consultado | Falta entrar, exibir carro e selecionar; argumentos antigos não são atalho validado [10] |
| Corrida, física e colisões | Símbolos de corrida/veículo/física | Sem cobertura suficiente | Sem prova de corrida jogável nas evidências consultadas | Falta dirigir, colidir, completar corrida e comparar comportamento [11] |
| Missões e progressão de carreira | Sem inventário específico nesta auditoria | Não avaliado | Sem prova consultada | Falta mapear fluxo, objetivos, recompensas e persistência; não inferir ausência de código |

## Evidências e limites

1. [Índice](FUNCTION_INDEX.md); `PS2Recomp/ps2xTest/src/` contém testes de
   decoder, gerador e runtime. Último resultado documentado:318/318, não repetido aqui.
2. [Espera por dono](RESULT_WAIT_OWNERS_2026-09-05.md) e
   [controle quiet/callback](RESULT_WAIT_QUIET_2026-09-06.md). As janelas diferem:
   422/429s de espera no controle não podem ser atribuídos à rodada seguinte.
3. `PS2Recomp/ps2xTest/src/ps2_runtime_io_tests.cpp` e
   `mc3_asset_archive_tests.cpp`; [leitura real](RESULT_CDREAD_REAL_V1.md),
   [escritas do frontend](RESULT_FRONTEND_WRITES_2026-09-05.md).
   Testes opcionais com ISO/DAT dependem dos arquivos disponíveis; existir um
   teste não comprova que seu ramo opcional foi executado na última suíte.
4. [FSAND](RESULT_VU1_BUDGET_2026-09-05.md) e
   [TOP/XTOP](RESULT_VIF_INPUTS_2026-09-05.md): erros concretos corrigidos,
   oito entradas reais reproduzidas; não houve ganho de FPS demonstrado.
5. [Imagem nativa histórica](RESULT_NATIVE_FRAME_2026-08-26.md) e [captura
   recente](RESULT_WAIT_OWNERS_2026-09-05.md). Uma captura preta não prova que
   todos os quadros sejam pretos; imagem antiga correta não certifica o binário atual.
6. [Escritas da animação](RESULT_FRONTEND_WRITES_2026-09-05.md) e última rodada [2].
7. [START automático](RESULT_PAD_AUTOSTART_2026-09-03.md);
   `PS2Recomp/ps2xTest/src/pad_input_tests.cpp`.
8. `PS2Recomp/ps2xRuntime/src/lib/ps2_audio.cpp`; [protocolo SIF](SIF_PROTOCOL.md).
9. [Handshake de cartão](RESULT_MEMCARD_30_V1.md);
   `PS2Recomp/ps2xTest/src/ps2_runtime_io_tests.cpp`, testes `sceMc` e `mc0`.
10. [Ensaio de garagem, resultado negativo](RESULT_GARAGE_RUN_2026-08-29.md);
    CSV de símbolos: `0x001A7150` = `mcGameState::SetFrameModeGarage` (hash).
    O STATUS posterior rejeita `skipintro` como opção comprovada deste retail.
11. CSV: `0x001A9C60` = `mcLayerRace` (callgraph), `0x0025D968` =
    `vehChassis::SetBound` (hash), `0x00267178` = `vehTransmission::Upshift` (hash).
    Esses exemplos corrigem a ideia de que corrida/física não estão identificadas
    em parte; não constituem prova de que rodem corretamente.

## Próximos marcos de progresso real

1. **Abertura termina e menu responde**, repetidamente, no binário identificado.
   Agora: localizar a espera da principal e separar as chamadas internas do callback.
2. **Garagem abre e permite escolher um carro.** Exigir imagem e input reais.
3. **Uma corrida pode ser iniciada, dirigida e concluída.** Só então validar os
   caminhos de física, áudio, objetivos e desempenho usados nessa corrida.
4. **Carreira salva e carrega após reiniciar.** Teste isolado de arquivo não basta.

Manutenção: ao mudar uma linha, anexar data, binário/configuração, evidência e
critério de aceite. Não calcular média das linhas: elas têm tamanhos diferentes
e este inventário não pretende listar cada sistema do jogo.
