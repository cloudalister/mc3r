# Handoff — semáforo 17 — 2026-07-28 05:59 BRT

## Confirmado

- `sid=17` é criado no grupo de semáforos iniciado pelo fluxo em `0x541510`–`0x541538`.
- `sub_005420C0_0x5420c0` consome esse semáforo em `PollSema`, no retorno `0x542114`.
- A própria `sub_005420C0_0x5420c0` chama `SignalSema` nos pontos `0x54223C` e `0x542290`.
- Esses sinais correspondem a encerramento da operação, inclusive caminho de erro; não são sinais genéricos de SIF/FMV.
- Nenhum patch de runtime foi feito.

## Pendente

Descobrir por que o fluxo atual não chega aos branches que sinalizam o semáforo 17.

## Próximo passo

Instrumentar, de forma env-gated, as chamadas/retornos de:

1. `func_5414A8`;
2. `func_549488`;
3. leitura do estado em `0x61FB90`;
4. branch tomado dentro de `sub_005420C0`.

### Próximo comando sugerido

```bat
15_auto_boot_probe.bat 8 595
```

Antes de qualquer compatibilidade, usar o trace para decidir se falta resposta SIF/IOP, estado inicializado ou retorno incorreto.
