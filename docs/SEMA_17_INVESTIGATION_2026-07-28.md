# Investigação do semáforo 17

## Resultado

No fluxo real observado, o semáforo `17` é usado por `sub_005420C0_0x5420c0` como semáforo de progresso/conclusão da operação de inicialização do subsistema associado ao grupo criado em `0x541510`–`0x541538`.

O consumidor é:

- `sub_005420C0_0x5420c0`, em `0x54210C` → `PollSema(semáforo em 0x61FBB0)`;
- retorno em `0x542114`, comparando o resultado com o mesmo ID.

No trace real do runner, esse slot contém `17`:

```text
CreateSema id=17 ... pc=0x5469a0 ra=0x541528
PollSema sid=17 ... pc=0x5469f0 ra=0x542114
```

## Quem chama `SignalSema(17)`

É a própria `sub_005420C0_0x5420c0`, em dois pontos:

1. `0x54223C` chama `SignalSema(0x61FBB0)` e retorna por `0x542244`.
2. `0x542290` chama `SignalSema(0x61FBB0)` e retorna por `0x542298`.

O trace confirma os dois retornos:

```text
SignalSema sid=17 ... pc=0x5469c0 ra=0x542244
SignalSema sid=17 ... pc=0x5469c0 ra=0x542298
```

## O que dispara cada sinal

- `0x54223C`: ocorre quando a chamada de `func_549488` volta com resultado negativo. É o caminho de falha/encerramento da tentativa atual.
- `0x542290`: ocorre quando a operação cai no caminho alternativo em que o resultado anterior não permite continuar (`v0 <= 0`); o código prepara o valor retornado e sinaliza antes de sair.

Portanto, o sinal esperado não é um “evento externo genérico”: é a conclusão do trabalho que `sub_005420C0` acabou de examinar, inclusive conclusão por erro.

## Conclusão operacional

Não devemos injetar `SignalSema(17)` no runtime, no SIF ou no callback de FMV. O produtor correto já existe no binário recompilado: `sub_005420C0`, nos endereços `0x54223C` e `0x542290`.

Se o semáforo ficar sem sinal no boot, o próximo diagnóstico deve descobrir por que o fluxo não chega a esses branches — principalmente o retorno de `func_549488` e o estado consultado por `func_5414A8`. Sinalizar o ID à força esconderia essa causa.
