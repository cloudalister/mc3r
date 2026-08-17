# Plano do modo automático — MC3 Recomp

Data: 2026-07-29

## Objetivo

Automatizar o trabalho repetitivo sem deixar o sistema inventar patches:

```text
auditar estado -> executar 1 etapa -> validar -> registrar -> decidir continuar ou parar
```

O modo automático não abre PCSX2, não promove experimento e não altera o jogo original.

## Decisão

Usar dois ciclos separados:

1. **Investigação:** executar uma história do PRD por vez.
2. **Experimento:** compilar, relinkar, verificar o exe, rodar probes e comparar resultados.

Nunca executar duas etapas que escrevem código ao mesmo tempo.

## Arquivos propostos

- `21_auto_provider_cycle.bat`: entrada simples para o usuário.
- `tools/Invoke-ProviderAutoCycle.ps1`: controlador principal.
- `tools/Verify-BootState.ps1`: gate de estado, depois das correções abaixo.
- `work/auto_provider/state.json`: estado retomável da execução.
- `work/auto_provider/runs/<data-hora>/`: logs e cópias dos resultados.
- `work/auto_provider/latest_status.md`: resumo humano.

## Comandos previstos

```bat
21_auto_provider_cycle.bat inspect
21_auto_provider_cycle.bat build
21_auto_provider_cycle.bat probe
21_auto_provider_cycle.bat resume
21_auto_provider_cycle.bat status
```

- `inspect`: roda somente histórias de leitura permitidas.
- `build`: executa uma etapa de edição já aprovada e seus testes.
- `probe`: roda a matriz `595` + `payload1m3skip5a`.
- `resume`: continua do último gate concluído.
- `status`: apenas mostra estado; não altera nada.

## Máquina de estados

```text
PREFLIGHT
  -> STATIC_STORY
  -> REVIEW_REQUIRED
  -> COMPILE_TARGETS
  -> RELINK
  -> VERIFY_EXE
  -> PROBE_595
  -> PROBE_PAYLOAD
  -> COMPARE
  -> CHECKPOINT
  -> DONE ou STOPPED
```

Cada estado só começa se o anterior gravou `PASS` no `state.json`.

## Preflight obrigatório

Antes de qualquer trabalho:

1. Confirmar os arquivos permitidos da história.
2. Confirmar que não há outro ciclo automático ativo.
3. Salvar hash e data do exe atual.
4. Rodar a guarda do baseline:

```bat
20_verify_boot_state.bat 0x5a8908
```

5. Confirmar que `missing_functions.partial.manifest.csv` tem zero linhas.
6. Registrar o último Stable PC, modo, log e counters.

Se o diretório tiver mudanças fora dos caminhos permitidos, parar e registrar; não limpar arquivos.

## Ciclo de investigação

Reusar:

```text
.agents/tasks/prd-mc3-provider-investigation-2026-07-29.json
```

Regras:

- executar uma história por rodada;
- validar o artefato e os critérios de aceite;
- marcar a história concluída somente depois da validação;
- permitir paralelo apenas nas histórias de leitura com caminhos sem conflito;
- parar antes da primeira história que edita código, aguardando revisão.

Ordem segura inicial:

```text
US-001 -> US-002 + US-003 -> US-009
```

`US-002` e `US-003` podem ser analisadas em paralelo depois de `US-001`. `US-004` em diante usa lane serial.

## Ciclo de experimento

Depois que uma instrumentação ou experimento tiver sido aprovado:

1. Descobrir os batches das funções alteradas pelo índice.
2. Compilar cada batch com `Limit 0`, evitando pular a função alvo.
3. Exigir exit code zero em todas as linhas do summary CSV.
4. Rodar `10_link_partial_runner.bat fast`.
5. Exigir exe com data nova.
6. Procurar a string única do experimento no exe.
7. Rodar probe `595`.
8. Copiar `latest_status.md` e o log antes do segundo probe.
9. Rodar probe `payload1m3skip5a`.
10. Comparar PC, classificação, counters e trace provider.
11. Gravar checkpoint.

Fluxo:

```text
compile alvo
  -> relink fast
  -> Verify-BootState -ExpectExeString
  -> probe 595
  -> salvar resultado
  -> probe payload1m3skip5a
  -> salvar resultado
  -> comparar
```

## Correções necessárias no verificador

O verificador atual é útil como começo, mas ainda não deve comandar o modo automático.

Antes disso:

1. Aceitar o caminho de um status específico, não apenas `latest_status.md`.
2. Validar que o status foi criado depois do início do probe.
3. Validar modo, exit code, duração e caminho do log esperado.
4. Considerar exe stale contra todos os objetos usados no link, não apenas `register_functions.partial.cpp`.
5. Tratar manifest ausente, vazio e inválido separadamente.
6. Trocar a busca binária da string por uma função simples e determinística.
7. Produzir saída JSON além do texto.
8. Separar `PASS`, `FAIL` e `GOAL_PENDING`; hoje `real-render-traffic` aparece como `TODO`, mas o processo termina com sucesso.
9. Validar formato do PC antes de comparar.
10. No wrapper `.bat`, passar argumentos diretamente ao PowerShell, sem montar uma linha de comando em texto.

## Gates de parada

Parar automaticamente quando:

- build ou relink falhar;
- exe não receber data nova após edição;
- string do experimento não estiver no exe;
- status do probe estiver velho ou incompleto;
- Stable PC regredir para `0x2b4488`;
- o gate mudar sem trace que explique a mudança;
- os dois modos derem resultados incompatíveis;
- a próxima ação exigir PCSX2 ao vivo;
- aparecer proposta de handle falso, `SignalSema` forçado ou patch permanente;
- arquivos fora dos caminhos permitidos precisarem ser alterados.

## O que pode rodar sem Cloud

- buscas e mapas estáticos;
- criação de documentos de evidência;
- compilação de batches já aprovados;
- fast relink;
- validação da string no exe;
- probes headless;
- comparação e checkpoint.

## O que exige Cloud

- abrir ou controlar PCSX2;
- aceitar um experimento que muda comportamento;
- promover env-gate para comportamento padrão;
- escolher entre hipóteses com evidência insuficiente;
- continuar depois de regressão inexplicada.

## Critério de sucesso

O primeiro modo automático está pronto quando:

1. Pode ser interrompido e retomado sem repetir uma etapa concluída.
2. Preserva separadamente os dois resultados de probe.
3. Nunca informa sucesso usando um status antigo.
4. Para sozinho em todos os gates acima.
5. Gera um `latest_status.md` com resultado verificado, pendência e próximo comando.
6. Só declara vitória visual quando `gif > 0` ou `gsw > 0`.

## Ordem de implementação

1. Corrigir e testar `Verify-BootState.ps1`.
2. Criar o estado JSON e o lock de execução.
3. Implementar `status`, `inspect` e `resume`.
4. Implementar compile/relink/verify.
5. Implementar a matriz de probes com cópia imediata dos resultados.
6. Adicionar comparação, checkpoint e gates de parada.
7. Fazer um teste seco sem editar nem abrir executáveis visuais.

## Próximo passo recomendado

Implementar primeiro somente o núcleo seguro:

```text
preflight -> verify baseline -> executar uma história read-only -> validar documento -> checkpoint -> parar
```

Depois adicionar build e probes, já apoiados num verificador corrigido.
