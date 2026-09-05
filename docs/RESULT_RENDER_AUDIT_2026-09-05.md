# Auditoria do handoff de performance — 2026-09-05

Pedido: conferir se algo passou despercebido antes de continuar otimizando.
Auditoria local, sem iniciar jogo, build, commit ou push. Um subagente econômico investigou
o caminho VU1/GIF/GS; coordenador conferiu contabilidade, harness e logs.

## Achados confirmados

1. **10,4 s não é tempo total de quadro.** A meta de `probe_isocache_20260905.log.meta`
   registra timeout de 900 s, não 20 minutos. O log contém `vifMs=134876`,
   `guestWaitMs=384141`, `guestExecMs=513684`, `guestMs=897953`.
   Dividir VIF por 13 e multiplicar de volta é identidade aritmética, não prova de
   que o envio do quadro explica toda a demora. Boot também entra nesses totais.
   Não atribuir simplesmente 900-134,9 a outro subsistema: há escopos inclusivos,
   esperas e possíveis sobreposições. O próximo perfil precisa delimitar voltas reais.
2. **`guestExecMs` não é CPU pura.** `ps2_runtime.cpp:2920-2957` cronometra `fn(...)`
   com relógio de parede; bloqueios internos à função entram nesse intervalo.
   `guestWaitMs` mede a entrada no escopo, não toda espera interna do convidado.
3. **VU1 barato em nanossegundos ainda é inferência.** 88 ciclos emulados por chute e
   zero estouros são medidos. O custo assumido de algumas dezenas de ns por ciclo
   não foi medido separadamente. `vu1Ms-rasterMs` também não isola GIF/GS:
   inclui interpretação e subtrai raster global, que pode vir de outros PATHs.
4. **Outra varredura sem gate existe.** `ps2_gs_gpu.cpp:1156-1171`,
   `GS::processGIFPacket`, percorre todo pacote de 8 em 8 bytes para localizar dois
   valores de debug. O limite de 24 mensagens só é consultado depois da varredura.
   É desperdício concreto semelhante ao corrigido no árbitro; magnitude não medida.
5. **Harness descartava evidência válida e aceitava janela parcial.** Timeout fazia
   `continue` antes da análise, embora o modo padrão não imponha orçamento de saída.
   `Get-Borda` usava a última amostra <= marco sem verificar que o marco alto foi
   alcançado. Corrida entre 300k e 600k podia passar por janela completa.

## Entrega nesta auditoria

`tools/Measure-RenderCost.ps1` agora analisa logs após timeout, exige evidência de
cruzamento do marco alto, oferece `-LogPaths` para análise offline, mostra bordas
efetivas/pixels por primitiva, sinaliza menos de três corridas válidas e calcula
mediana também para contagem par. O antigo `gifUsPk1` virou `residuoUsPk1` e tem
ressalva explícita. Quantidade de primitivas não garante identidade de cena.

Teste offline `tools/Test-MeasureRenderCost.ps1`: PASS para janela completa,
rejeição de janela incompleta e rejeição de borda inicial ausente/linha corrompida.
O ramo de encerramento por timeout foi revisado, mas não exercitado com o jogo.

Reanálise dos arquivos existentes (não é A/B novo; não agrupar binários como réplicas):

| log | bordas efetivas | raster ns/pixel | VIF us/prim |
|---|---:|---:|---:|
| probe_isocache_20260905 | 291821..599940 | 71,57 | 42,46 |
| probe_arbgate_20260905 | 299970..597213 | 54,11 | 29,69 |
| probe_vu1cycles_20260905 | 299970..597213 | 54,68 | 30,37 |

**Proveniência a resolver:** o arquivo atual `probe_vu1cycles_20260905.log.stderr`
contém `gsPrims=602667` no tick 20040, enquanto a seção 13 do relatório histórico
registra total 125442. Portanto não tratar o arquivo atual como reprodução daquela
tabela sem esclarecer a origem. Nenhum ganho é validado por esta reanálise.

16% é dispersão observada num conjunto de amostras, não limite universal da máquina
nem prova estatística de que todo delta maior é ganho. O próprio histórico reporta
25,4% para VIF na janela. Comparar réplicas do mesmo binário/cena/configuração.

## Próximo passo concreto

1. Preservar hashes de exe/lib, commits dos dois repositórios, variáveis MC3 e logs
   únicos; capturar baseline com três corridas válidas, sem build concorrente.
2. Medir entrada/saída de voltas reais do frontend e deltas VIF no mesmo intervalo;
   distinguir espera de execução com cuidado para escopos inclusivos. Não alterar
   semáforos, temporizadores ou scheduler com base nesta auditoria.
3. Preparar A/B mínimo para gate da varredura de `GS::processGIFPacket`, mantendo
   diagnóstico opt-in; três corridas por binário, cenas e imagem equivalentes.
   O runtime não foi alterado: a regra de aceitação continua valendo.
4. Se necessário, separar tempo do interpretador VU1 de XGKICK e contar tags/wrap/
   bytes do XGKICK (candidato apontado pelo subagente), antes de decidir prioridade.

Não reabrir hipóteses já testadas sem nova evidência. Também não transformar uma
hipótese específica eliminada em afirmação de que todo subsistema está correto.
