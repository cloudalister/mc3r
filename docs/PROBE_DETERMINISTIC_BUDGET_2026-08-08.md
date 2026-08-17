# VIS-A2 - gate deterministico por budget de dispatch

Data: 2026-08-08. Escopo: wrapper e leitura de evidencia do probe. Nenhum frame visual e' alegado aqui.

## O que muda

`MC3_DETERMINISTIC=1` ativa o gate. Antes de abrir o runner, `14_run_boot_trace.bat` exige que `MC3_DISPATCH_BUDGET` seja inteiro decimal positivo. O runner recebe as duas variaveis e deve encerrar com `[boot-trace:dispatch-budget-reached]`; `timeout reached` invalida a corrida deterministica.

Sem `MC3_DETERMINISTIC=1` (ausente, `0` ou outro valor), o wrapper limpa o budget herdado e preserva o corte antigo por segundos.

O status e o relatorio de repeticao registram: modo deterministico, budget, marcador de budget e timeout. GIF/GSW continua sendo o unico sinal aceito de render; `gif=0 gsw=0` nao e' frame visual.

## Calibracao

Abra `cmd.exe` na raiz do checkout e execute exatamente:

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=100000"
15_auto_boot_probe.bat 8 595
findstr /C:"[boot-trace:dispatch-budget-reached]" work\logs\14_run_boot_trace.log
findstr /C:"[boot-trace-driver] timeout reached" work\logs\14_run_boot_trace.log
```

Aceite o budget somente se o primeiro `findstr` encontrar o marcador e o segundo nao encontrar nada. Se houver timeout, reduza o budget pela metade e repita os cinco comandos; nao aumente os segundos para mascarar o corte.

## Aceite N=10

Depois de calibrar, execute exatamente:

```bat
set "MC3_DETERMINISTIC=1"
set "MC3_DISPATCH_BUDGET=<budget-calibrado>"
21_probe_repeat.bat 10 595 a2_budget
```

PASS A2 requer: dez marcadores de budget, zero timeout, um unico `Stable PC`, zero `invalid-pc` e zero contradicao entre classificacao e GIF/GSW. `gif=0 gsw=0` continua sendo sem render, mesmo com PC estavel.

## Saidas do agregador

- `0`: agregado aceito; nao prova frame visual.
- `2`: PCs variaram sem render real.
- `3`: classificacao e GIF/GSW se contradizem.
- `4`: evidencia deterministica invalida: marcador ausente ou timeout.

## Rollback

No `cmd.exe`, execute:

```bat
set "MC3_DETERMINISTIC="
set "MC3_DISPATCH_BUDGET="
```

Isso volta ao comportamento normal por segundos. Para retirar a implementacao, reverta somente `14_run_boot_trace.bat`, `tools\Boot-Probe.ps1` e `tools\Probe-Repeat.ps1` desta historia.
