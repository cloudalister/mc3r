# MC3 Recomp — plano de trabalho de 3 horas

**Estado: HISTÓRICO — substituído pelo plano revisado autorizado em 09/09:**
`docs/PLANO_3H_DIAGNOSTICO_REVISADO_2026-09-09.md`.

Data: 08/09/2026. Responsável: Astra/Codex. Duração máxima: 180 minutos a partir do início autorizado, incluindo builds, testes, análise e registro. Este documento não inicia execuções, automações ou alterações no runtime.

## Resultado que buscamos

Descobrir em qual etapa o alarme deixa de acordar o jogo. Se demonstrarmos um erro específico, aplicar uma correção pequena e testar sua consequência. Se não houver prova suficiente, entregar o caminho mais estreito possível e evidência reutilizável — sem inventar uma correção para preencher as três horas.

Em linguagem simples: **o despertador continua tocando; precisamos descobrir por que o recado não chega a quem precisa acordar.** Essa é uma explicação da hipótese de trabalho, não uma causa já demonstrada.

Não prometemos menu, garagem, corrida ou ganho de FPS neste lote. Destravar uma espera é um marco técnico, não prova de que o jogo inteiro funciona.

## Ponto de partida confirmado

- O teste de 06/09, recuperado em 08/09, durou 601,024 segundos.
- O analisador aceitou cinco registros completos de alarme armado, quatro callbacks e quatro despertares. Esses números descrevem o log aceito, não uma cobertura completa da execução.
- A espera final, SID214/alarme `0703e0d3`, chegou a 65,023 segundos sem callback correspondente ou despertar registrados.
- Durante essa espera, as solicitações de interrupção do Timer2 continuaram aumentando; a contagem de solicitações mascaradas permaneceu zero nas amostras.
- Uma amostra final da seleção coincide com o endereço observado e indica prazo atingido. **Isso não confirma que era a mesma instância do alarme:** endereços podem ser reutilizados e os bancos de diagnóstico são independentes.
- Já existem alterações locais da instrumentação anterior. Elas devem ser preservadas e identificadas antes de qualquer nova edição.

Fontes locais principais:

- `<project-root>\PS2_PROJECT_STATE.md`
- `<project-root>\docs\RESULT_TIMER_ROUTE_2026-09-06.md`
- `<project-root>\tools\Analyze-TimerRoute.js`
- `<project-root>\work\logs\probe_timer_route_astra_20260906.log.stderr`
- Arquivos `.meta` e `.result.json` correspondentes ao log acima.

## Agenda fechada: 180 minutos

Os horários abaixo são relativos ao início autorizado. Atrasos consomem a reserva de implementação, não o tempo final de documentação. A partir do minuto 140 não iniciar nova mudança de comportamento.

| Tempo | Trabalho | Entrega / condição para avançar |
| --- | --- | --- |
| 00–20 min | Conferir checkout, processos, alterações pendentes, build, fontes geradas e evidências anteriores. Reexecutar o analisador do log antigo. Identificar todos os owners compilados que contêm o trecho. | Baseline reproduzível: hashes, configuração, estado local e limites conhecidos. Não rodar o jogo com binário de origem incerta. |
| 20–55 min | Instrumentar apenas o trecho entre seleção do alarme, retirada da fila, chamada e retorno. Correlacionar identidade da instância, destino real e argumentos. Usar exatamente um subagente econômico para auditoria estática independente, sem builds ou edições concorrentes. | Sonda limitada, opcional e passiva, mais testes da correlação e dos retornos. Nenhuma alteração deliberada no comportamento guest. |
| 55–80 min | Compilar os arquivos necessários, executar testes focados e a suíte de runtime. Relink explícito, com saída preservada. Verificar presença das novas marcas e hashes do executável. | Build e testes aprovados, binário rastreável. Testes antigos aprovados não substituem esta validação. |
| 80–115 min | Até duas execuções headless de 10 minutos, sequenciais, sob a mesma configuração; analisar entre elas. A segunda confirma a primeira ou repete a coleta, sem mudar vários fatores. | Linha do tempo do mesmo alarme: última etapa confirmada e primeira etapa sem evidência. Se não reproduzir, declarar isso; não aumentar duração indefinidamente. |
| 115–140 min | Decisão por evidência. Se houver erro reproduzível e divergência comprovada do comportamento original, criar teste de regressão e corrigir o menor trecho. Caso contrário, aprofundar análise offline ou uma única sonda focal. | Correção sustentada por teste que falhava antes e passa depois; ou diagnóstico negativo útil. Sem correção especulativa. |
| 140–165 min | Validar a versão final. Se houve correção: reconstruir, suíte e até uma execução headless comparável de 10 minutos, se couber. Se não houve: verificar integridade da instrumentação, testes e evidências. | Separar teste unitário, execução real e aceitação visual. Se faltar tempo, não declarar a correção validada nem promover seu binário como padrão. |
| 165–180 min | Encerrar processos criados pelo lote, organizar evidências e registrar resultado, riscos e próxima tarefa. | Relatório final e checkpoint completos; resumo curto para Cloud. Não deixar teste rodando sem combinar. |

**Orçamento de execução real:** no máximo três rodadas de 10 minutos dentro das três horas. Não executar cópias do jogo em paralelo. Um teste iniciado deve caber no tempo restante com margem para encerramento e registro.

## Perguntas que a sonda precisa responder

1. O alarme observado é realmente o mesmo que a thread principal acabou de armar?
2. Ele foi selecionado com o prazo atingido ou estamos vendo outro nó da fila?
3. A retirada da fila terminou e devolveu o controle ao ponto esperado?
4. Qual função foi realmente carregada como callback? Com quais argumentos e identidade de alarme?
5. Essa função foi encontrada pelo dispatcher, começou e retornou? Se desviou, qual foi o PC de retorno observado?
6. O caminho chegou ao wrapper que sinaliza o semáforo correto?
7. Se o sinal aconteceu, a espera terminou? Se não terminou, onde ficou a thread depois dele?

### Fronteira técnica delimitada

`comparação 0x54ce80 → chamada 0x54ce8c / helper 0x54cd70 → alvo carregado em 0x54cec4 → chamada indireta 0x54ced0 → retorno 0x54ced8`

Correlacionar esse caminho com o wrapper `0x54d640` e os eventos existentes de callback, sinal e despertar. O wrapper fica dentro do caminho chamado; o marcador de retorno serve para provar que esse caminho devolveu o controle.

Examinar tanto `FUN_0054cda8_0x54cda8` quanto o owner sobreposto `sub_0054CD70_0x54cd70`, além dos aliases efetivamente registrados. Comentários de opcode coincidentes com o ELF provam proveniência das instruções, **não** equivalência semântica do C++ gerado.

### Requisitos da instrumentação

- Associar uma geração/sequência de armamento ao identificador do alarme, sem depender apenas do endereço reutilizável da entrada.
- Copiar valores escalares já carregados nos registradores. Não guardar ponteiros para contextos guest nem fazer snapshots de memória guest de outra thread.
- Eventos limitados em memória; contadores explícitos de perda/saturação. Logs periódicos fora de locks sensíveis, sem impressão a cada instrução.
- Não acrescentar locks ao caminho do jogo; manter ordenação e publicação corretas entre threads. Se a identidade não puder ser capturada com segurança, não improvisar: registrar a limitação.
- Testar reutilização de entrada, correlação errada, captura incompleta e retorno normal/desviado. Rejeitar linhas intercaladas ou truncadas na análise.
- Preservar as fontes geradas ignoradas pelo Git por patch/reprodução explícita e hashes. Uma edição apenas local não basta para uma entrega retomável.

## Decisão após a coleta

| Evidência | Próximo alvo permitido |
| --- | --- |
| Não há seleção comprovada da mesma instância | Identidade, fila e cálculo do prazo; não afirmar falha no callback. |
| Há seleção, mas o helper não retorna corretamente | Semântica da retirada da fila e retorno/alias compilado. |
| O alvo foi carregado, mas não se comprova sua entrada | Registro/lookup, entrada sobreposta e chamada indireta. |
| Callback entra, mas não sinaliza o semáforo correspondente | Argumentos, identidade, wrapper e caminho interno comprovado. |
| Sinal confirmado, mas a thread não acorda | Notificação e retomada do token guest. Não alterar política do scheduler automaticamente. |
| Nenhuma espera problemática reproduzida | Registrar não reprodução e limites da janela. Manter hipótese aberta e definir próximo experimento. |

## Critérios de sucesso e de parada

**Sucesso mínimo:** fronteira causal mais precisa, dados íntegros, procedimento reproduzível e checkpoint que permita retomar sem redescobrir o contexto.

**Sucesso com correção:** divergência específica demonstrada, teste de regressão, suíte aprovada e tentativa comparável de boot. Um único boot melhor é evidência inicial; não prova eliminação de falha intermitente nem aceleração geral.

**Parar a coleta ou não avançar para correção quando:**

- Binário sem marcas esperadas, origem/hash incompatível, relink falho ou biblioteca mais nova sem explicação.
- Sonda altera comportamento, causa overhead impeditivo, satura ou não consegue provar identidade do alarme.
- Crash, corrupção nova, falha de teste ou saída precoce inesperada: preservar artefatos e investigar antes de repetir.
- Surge necessidade de mudança ampla, política de scheduler, atualização de toolchain ou reconstrução geral fora do orçamento: entregar o bloqueio e pedir nova aprovação.
- Chega o minuto 165: parar implementação e priorizar encerramento e registro, mesmo sem solução.

Se uma edição deste lote precisar ser retirada, reverter somente essa edição a partir da cópia/patch identificado. Não desfazer alterações anteriores de Cloud ou de outros agentes.

## Escopo da aprovação solicitada

A aprovação deste plano autoriza, **durante o lote**, inspeção local, sondas passivas delimitadas, compilação/relink, testes automatizados, até três execuções headless limitadas, correção pequena condicionada à prova e documentação local.

Não inclui:

- Abrir jogo com janela, editor ou teste visual sem autorização específica.
- Forçar `SignalSema`, inventar callback/retorno, saltar tela, acelerar relógio ou alterar scheduler para mascarar a espera.
- Otimizar rasterizador/VIF/VU1, ampliar frentes de rede/áudio/assets ou corrigir problemas sem relação causal demonstrada.
- Limpeza ampla, reset de Git, apagar objetos existentes ou sobrescrever executável anterior sem preservá-lo.
- Push, publicação, atualização/deploy do painel ou mudança de acesso do projeto.

O painel pode ser atualizado em uma tarefa posterior; ele não deve consumir o orçamento de diagnóstico deste lote.

## Entrega no encerramento

1. Relatório em `<project-root>\docs\RESULT_LOTE_3H_ALARME_BOOT_2026-09-08.md` (nome proposto; se o lote iniciar em outra data, usar essa data).
2. Atualização de `<project-root>\PS2_PROJECT_STATE.md`.
3. Logs/configurações/hashes e resultado por rodada em `<project-root>\work\logs`, com nomes únicos; nunca sobrescrever o lote antigo.
4. Lista exata de arquivos alterados, testes executados, correções mantidas/retiradas e validações que faltam.
5. Resumo para Cloud: **o que descobrimos; o que destravou ou não; próximo passo recomendado**.

## Aprovação

**Pendente. Não executar este plano até a aprovação de Cloud.**
