# Escritas do frontend — 2026-09-05

## Correção do diagnóstico anterior

O STATUS anterior tratava `fe6AC` como ciclo `39 → 0`, citando a seção 19 de
`RESULT_M3_TITLE_EXIT_2026-09-04.md`. A releitura ordenada do arquivo original
`work/logs/probe_longcook_20260905.log.stderr` encontrou **887 blocos completos,
zero regressões, máximo 40, último 40**. A expressão exigiu o bloco contíguo
`feView/fe49/fe6AC/fe6B0/feAnim`; linhas misturadas foram descartadas.

Isso não prova ausência de qualquer escrita entre amostras, mas o arquivo não sustenta
o reinício alegado. O histograma de frequências não estabelece a ordem temporal.
Um investigador econômico conferiu a ordem e o caminho de escrita de forma independente.

## Instrumentação executada

Oito stores de quatro owners recompilados receberam observação imediatamente antes da
escrita original. O helper não altera RAM ou registradores, tem gate `MC3_FE_WRITE_TRACE=1`
e teto de 512 eventos. Inventário completo: `tools/diagnostics/FRONTEND_WRITE_PROBE.md`.
O código gerado continua local/ignorado; o helper neutro e o executor são versionáveis.

Compilação dos quatro owners com os flags atuais `-O2 -fno-strict-aliasing -msse4.1`:
sucesso. Manifesto SHA dos quatro fontes atualizado somente após compilação. Relink
absoluto: sucesso; string `[mc3-fe-write]` presente no executável. O exe passou a incluir
também a biblioteca já preparada `9b9846b` (gate GS). **Não é um A/B de performance.**

Proveniência da corrida principal:

- root anterior: `a292d20`; submódulo: `9b9846b`;
- exe SHA-256: `52d61679337cfc83c25eeb6f499e0aa941eed70ed83299ff2b2611d37775e78c`;
- lib SHA-256: `ac11092a866b63bc2e3daa0c065576bd5772eda2931f087e65b20903e4921fbe`;
- log: `work/logs/probe_fe_writes_astra_20260905.log.stderr`;
- configuração e hora de início: `.log.meta`, scheduler padrão, headless, input automático.

## Evidência direta inicial

- Objeto `0x16d5ec0`: construtor `0x321390` inicializa +0x6AC em zero.
- Inicializador `0x322428`: `0 → 0`, slot 10, clipe `0x17e5850`, comprimento **119**.
- Update `0x322dd0`: posição calculada com `f20`; depois `0x322e94` incrementa.
- Primeiras saídas de Update: `1, 2, 4, 5, 6`; timer `0,033; 0,066; 0,099; 0,132; 0,165`.
- Duração configurada **3**, mesmo objeto/clipe e nenhum reinício nesses eventos.

O código divide o timer por 3, multiplica por 119, converte para inteiro e incrementa.
Com 31 atualizações, isso é compatível com posição final 40, a observada no log antigo.
Três segundos de tempo do guest exigem aproximadamente 91 atualizações; não equivalem
a três segundos de parede nesta implementação lenta. Ainda não foi observada a saída
final nem demonstrado o motivo de todo o tempo de parede.

A captura ao cruzar 700.000 primitivas saiu preta, inclusive no contexto GS 0 inspecionado.
Ela não prova avanço visual ou menu jogável. Captura pontual não descreve toda a corrida.

## Fechamento do lote

Corrida principal encerrada pelo limite em **901 s**. Foram **34 eventos de escrita**:
um construtor, um inicializador, 16 escritas de posição calculada e 16 incrementos.
Valor final **21/119**, timer **0,527999938**, mesmo objeto e clipe, nenhuma regressão.
606 amostras de estado completas corroboram esse progresso. Última linha útil de render:
924.703 primitivas, 828.853.729 pixels. Não há confirmação de menu jogável.

Uma leitura do processo aos 796 s mostrou 375,8 s de CPU agregado; outra leitura pouco
depois mostrou 387,45 s (216,95 em usuário, 170,5 em kernel). Não confundir CPU somada de
todas as threads com uma fase exclusiva, nem atribuir o intervalo restante a um lock específico.

## Achado novo: limites VU1 eram zero somente na cena anterior

O parser exige o bloco contíguo `vu1Cycles / vu1CapHits / delayThreadCalls /
setTimerAlarmCalls`. Isso descarta falsos números produzidos por linhas misturadas.

| log | blocos completos | blocos com caps não zero | ciclos VU finais | cap hits finais |
|---|---:|---:|---:|---:|
| fe_writes_astra_20260905 (901 s) | 603 | 271 | 1.102.197.458 | 15.852 |
| longcook_20260905 (histórico 1800 s) | 902 | 577 | 2.042.115.837 | 30.169 |

Os callbacks MSCAL/MSCNT em `ps2_runtime.cpp` passam explicitamente orçamento 65.536.
`CycleTally` em `ps2_vu1.cpp` soma um cap hit quando `executed >= budget`.
Assim, chamadas que chegaram ao orçamento contabilizam **1.038.876.672 / 1.102.197.458 =
94,3% dos ciclos VU** no lote novo e **96,8%** no log antigo. Isso mede ciclos emulados,
nunca percentual de parede ou prova de loop infinito. A saída normal no último ciclo
também incrementaria esse contador; só uma captura do E-bit/PC pode separar os casos.

A conclusão histórica de 88 ciclos/chute e zero caps era de um trecho anterior e não
pode eliminar esta hipótese na cena do frontend. Este é o próximo alvo concreto:
registrar, com teto pequeno, PC de entrada/saída, E-bit, registradores VI e os pares de
instruções das primeiras chamadas que atingem o orçamento. Não reduzir o orçamento para
simular ganho; isso alteraria a execução sem corrigir a causa.

Reprodução da análise somente leitura:

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Analyze-FrontendBoot.ps1 -LogPath work/logs/probe_longcook_20260905.log.stderr
```

## Controle curto sem trace geral

`probe_fe_writes_quiet_astra_20260905`: **300,52 s**, mesmo exe/lib e input, alterando
apenas `MC3_BOOT_TRACE=0`. A sonda independente permaneceu ativa: um evento de construtor,
nenhum Update até o corte. CPU agregado **129,17 s** (usuário 95,66; kernel 33,52), stderr
505.940 bytes. Não demonstrou solução imediata ou ganho; a janela curta não é comparável
ao trecho de frontend da corrida principal. Campos de frame/caps ausentes com trace
desligado são **não medidos**, não zero. O dump depende do trace geral e não dispara nesse modo.

Validação final: análise offline reproduziu 887/0/40 e 606/0/21; ambos os runners encerraram
no limite e não restou MC3 rodando. Sintaxe PowerShell e `git diff --check` passaram.
Não houve mudança de instrução guest, semáforo ou scheduler. A suíte C++ não foi repetida:
as mudanças C++ deste lote são a sonda passiva nos quatro owners, compilados com sucesso e
exercitados pelos 34 eventos; não se deve reapresentar os 309 testes antigos como execução nova.
