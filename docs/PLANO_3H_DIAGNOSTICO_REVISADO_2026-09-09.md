# MC3 — lote de diagnóstico revisado, até 3 horas

Autorizado por Cloud em 09/09/2026: "revise, replaneje, autoaprove e comece".
Início 01:41 Brasília; limite 04:41. Substitui para execução o plano de 08/09.

Objetivo: identificar a instância do alarme que não acorda a thread e localizar a
primeira divergência comprovada. Nem relógio lento nem callback perdido são causas
estabelecidas. Sem promessa de correção, menu ou FPS.

## Agenda e gates

- 00–15: preservar diffs, untracked relevantes, fontes geradas, objetos e binário
  anterior em work/patches; hashes. Não usar stash, reset ou push.
- 15–35: análise offline do log existente, reta now/tMs global/final, latências;
  declarar now ao armar indisponível, sem interpolação apresentada como medição.
- 35–75: sonda de identidade/armamento/seleção escolhida após análise; um único
  subagente econômico read-only para verificar PCs/registradores. Testes focados.
- 75–100: build/suíte/relink e verificação de marcas, hashes e timestamps.
- 100–140: até duas execuções headless de 10 minutos, sequenciais, análise entre
  elas. Interromper se evidência inválida, crash novo ou falta de tempo de registro.
- 140–165: fechar diagnóstico e testes offline. Correção só abre se uma linha
  específica estiver comprovada e restarem pelo menos 40 minutos antes do limite;
  precisa de regressão e validação, não existe terceira rodada reservada.
- 165–180: parar processos próprios e documentar resultado/proveniência/pendências.

As faixas são tetos de organização, não esperas artificiais: concluir antes se
o objetivo delimitado for atingido ou faltar autoridade para expandir o escopo.

## Passo zero já checado, a formalizar em artefato

OLS em 116 timestamps únicos não nulos: 147450,209 ticks/ms; últimos 70s,13
amostras:147462,290; nominal147456. Médias próximas ao esperado, sem prova de
ausência de pausas entre amostras. Quatro callbacks completos:5,6,3,10ms após
armed. Quinto sem callback registrado. Nenhum now explícito no armamento.
O banco de seleção guarda a última comparação, não histórico completo por alarme.
Ausência de seleção na amostra não prova que o alarme não venceu.

## Escopo seguro

Preservar alterações de 06/09. Sonda opcional, limitada, usando escalares já
carregados, sem locks novos ou ponteiros para contextos guest. Identidade inclui
geração/ID real: endereço sozinho não basta. Separar threshold derivado dos campos
do nó do relógio no armamento. Testar entradas reutilizadas e snapshots incompletos.
Código gerado precisa de reprodução/patch explícito, pois é ignorado pelo Git.

Não abrir janela, forçar sinal, alterar velocidade de timer/política de scheduler,
inventar callback/retorno, modificar painel, publicar ou fazer limpeza ampla.
Antes de nova rodada confirmar ausência de processo MC3 e logs de nome único.

## Entrega

docs/RESULT_LOTE_3H_ALARME_BOOT_2026-09-09.md + PS2_PROJECT_STATE.md, evidências
em work/logs. Dizer separadamente: relógio observado, prazo, identidade, callback,
sinal e despertar; cada qual confirmado, inconclusivo ou não medido.
