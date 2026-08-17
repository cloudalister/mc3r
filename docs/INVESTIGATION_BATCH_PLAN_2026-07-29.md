# Plano de investigação em lote — MC3 Recomp

Data: 2026-07-29 00:04 BRT

## Objetivo

Investigar por horas, com pequenas LLMs, por que o provider `0x629F44` não está disponível e quais requests/backend paths levam ao loop `0x5A8908`.

O PRD executável é:

`E:\Emuladores\Sony\mc3recomp\.agents\tasks\prd-mc3-provider-investigation-2026-07-29.json`

## Regras de operação

- Uma história pequena por rodada do Ralph.
- Lanes somente leitura podem rodar em paralelo.
- Código gerado, compilação, relink e probe ficam em lane única e serial.
- Cada LLM recebe `allowedPaths` exclusivos e não pode editar o PRD.
- Toda descoberta precisa de arquivo, endereço, comando e resultado.
- Nenhum handle falso, `SignalSema` forçado, patch amplo ou skip de FMV nesta fase.
- Não abrir PCSX2 em fullscreen.

## Lanes

### Lane A — Provider/package

`US-001 → US-002 → US-003`

Mapear referências globais, tabela de backend e lifecycle das flags.

### Lane B — Trace controlado

`US-004 → US-005 → US-006`

Instrumentar, recompilar uma vez, relinkar e executar a matriz mínima de probes.

### Lane C — Evidência live

`US-007`

Comparar o que o runner mede com a sessão PCSX2 já registrada. Se faltar captura live, registrar como pendência, sem inventar valor.

### Lane D — FMV

`US-009`

Investigar callbacks e requests de vídeo independentemente do provider.

### Fechamento

`US-008 + US-009 → US-010`

Selecionar um único experimento mínimo e deixar o handoff da sessão pronto.

## Ciclo automático sugerido

```text
Ralph build 1 --prd .agents/tasks/prd-mc3-provider-investigation-2026-07-29.json --no-commit
ler .ralph/progress.md e .ralph/runs/
validar o artefato da história
liberar a próxima história sem dependência pendente
```

Para horas de execução, repetir `ralph build 1` em ciclos curtos, preservando a regra de uma história por iteração. Não usar vários agentes na mesma história.

## Gates de parada

Parar e registrar, em vez de continuar automaticamente, se ocorrer:

- falta de evidência para escolher um produtor;
- alteração que exigiria escrever fora de `allowedPaths`;
- compilação ou relink gerar executável sem timestamp novo;
- probe mudar o gate sem explicação;
- necessidade de PCSX2 live sem sessão/autorização disponível;
- qualquer proposta de handle falso, semáforo forçado ou patch permanente.

## Resultado esperado

Ao final do lote, o handoff deve responder:

1. Quem cria `0x629F44`, ou exatamente onde o valor se perde.
2. Qual backend/request deveria completar o provider.
3. Se o FMV está no caminho do bloqueio ou é uma frente separada.
4. Qual é o único próximo experimento env-gated e seu rollback.

## Arquivos de registro

- PRD: `E:\Emuladores\Sony\mc3recomp\.agents\tasks\prd-mc3-provider-investigation-2026-07-29.json`
- Roadmap: `E:\Emuladores\Sony\mc3recomp\docs\INVESTIGATION_BATCH_PLAN_2026-07-29.md`
- Estado Ralph: `E:\Emuladores\Sony\mc3recomp\.ralph\progress.md`
- Logs Ralph: `E:\Emuladores\Sony\mc3recomp\.ralph\runs\`
