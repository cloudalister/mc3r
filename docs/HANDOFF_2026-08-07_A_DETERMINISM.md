# Handoff A — Tornar o boot probe mensurável — 2026-08-07

**Prioridade: bloqueadora.** Enquanto isto não fechar, nenhum experimento das outras frentes produz conclusão confiável. Handoffs B e C dependem deste.

## Por que você está fazendo isto

Cinco corridas do mesmo binário, mesmo modo, mesma duração deram cinco Stable PCs diferentes e quatro classificações diferentes (ver `docs\STATUS_2026-08-07_AUDIT.md`). Uma delas devolveu Stable PC `0x3` e ainda assim foi classificada `render-started`. O instrumento que o projeto usa para decidir se um experimento funcionou não mede nada de forma repetível.

Não é um detalhe de qualidade: é a razão pela qual semanas de lotes produziram documentos detalhados e zero pixels na tela.

## Regras

- Só leitura no código gerado nesta tarefa, exceto onde explicitado. Nada de patch de compatibilidade, handle falso ou `SignalSema` forçado.
- Toda afirmação precisa de comando + saída. `21_probe_repeat.bat` com N≥5 é o mínimo para qualquer alegação sobre comportamento do probe.
- Não abrir PCSX2 em fullscreen.

## Tarefa A1 — Achar a fonte da variação

Hipóteses a testar, em ordem de custo:

1. **Threads do host.** O trace mostra `activeThreads=3..5` variando entre corridas. O runner cria threads reais do SO? Se o escalonamento do host decide qual thread guest avança primeiro, o PC amostrado é loteria. Procurar em `PS2Recomp\ps2xRuntime\src\lib\Kernel` por criação de thread real vs cooperativa.
2. **Amostragem por tempo, não por instrução.** `15_auto_boot_probe.bat 8` roda 8 segundos de wall clock. Máquina mais/menos carregada = número diferente de instruções executadas = PC diferente. Se for isso, a correção é amostrar por contagem de instruções (`total=` já aparece em `[dispatch-window]`), não por segundos.
3. **Estado não inicializado.** Alguma região de RDRAM ou struct de contexto que começa com lixo do heap do host em vez de zero. Sintoma clássico: `Stable PC = 0x3`.
4. **Semente de tempo real.** Alguma leitura de relógio/RTC alimentando o guest.

**Entregável:** `docs\PROBE_NONDETERMINISM_ROOT_CAUSE.md` — qual hipótese é verdadeira, com a evidência que descarta as outras. Se forem várias, ranquear por contribuição.

## Tarefa A2 — Tornar o probe determinístico ou reprodutível

Dependendo do achado de A1, o alvo é um destes, em ordem de preferência:

1. **Determinismo real:** mesmo binário + mesmo modo → mesmo Stable PC, N=10 corridas. Preferível se a causa for (2) ou (3) acima.
2. **Reprodutibilidade sob semente:** aceitar variação mas fixá-la com uma semente/modo single-thread env-gated (`MC3_DETERMINISTIC=1`), para que experimentos comparem maçã com maçã.
3. **Métrica agregada estável:** se nada acima for viável a curto prazo, definir uma métrica que seja estável mesmo com PC variando — ex.: conjunto de PCs visitados, profundidade máxima da call chain, ou contagem de instruções até o primeiro bad PC. Estável = desvio pequeno em N=10.

**Entregável:** o modo/flag implementado + `21_probe_repeat.bat 10 595 <label>` mostrando **1 Stable PC distinto** (opções 1/2) ou variação dentro de tolerância declarada (opção 3).

## Tarefa A3 — Corrigir o classificador

Independente de A1/A2, o classificador aceita `Stable PC = 0x3` como `render-started`. Ele precisa:

- Rejeitar PC que não resolve para nenhuma função conhecida (marcar `invalid-pc`, não `render-started`).
- Não classificar `render-started` sem tráfego real. Hoje `render-started` significa só "algum contador mexeu" — inclusive com `dma=0 gif=0 gsw=0 vif=2`. Separar em `counters-moved` vs `render-started` (este último exigindo `gif>0` ou `gsw>0`).

Arquivo: `tools\Boot-Probe.ps1`.

**Entregável:** classificador corrigido + rerodar `21_probe_repeat.bat 5 595` mostrando as classificações novas, mais honestas.

## Critério de aceite do handoff

```bat
21_probe_repeat.bat 10 595 determinism_final
```

O relatório precisa dizer **"Stable PC estável nas 10 corridas"**, ou declarar explicitamente a tolerância adotada e por quê. Junto: `20_verify_boot_state.bat` rodando sem FAIL espúrio.

## O que NÃO fazer

- Não "consertar" o não-determinismo aumentando o tempo do probe até o resultado parecer estável. Isso esconde a causa.
- Não mexer nas frentes provider/FMV nesta tarefa. Elas estão travadas de propósito.
- Não descartar os experimentos já existentes (`MC3_TRACE_PROVIDER`, `MC3_TRACE_LOGICAL_RESOLVER`) — eles são úteis e reversíveis. Só não confie nas conclusões tiradas com n=1.
