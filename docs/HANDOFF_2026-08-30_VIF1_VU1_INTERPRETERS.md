# Handoff — otimizar os interpretadores VIF1 e VU1

## Contexto mínimo

O runner roda a ~3 fps. A causa foi **medida**, não deduzida. Decomposição por fase
(medianas de 3 corridas de 300 s, normalizadas por primitiva):

| Fase | µs/primitiva | Dispersão entre corridas |
|---|---:|---:|
| **VIF1** (`processVIF1Data`) | **227,5** | 12,6% |
| **VU1** (`VU1Interpreter::execute`) | **186,2** | 12,8% |
| guest — espera de lock | 153,3 | 13,2% |
| guest — execução | 135,1 | 22,8% |
| rasterizador | 24,9 | 3,4% |

**Seu alvo são as duas primeiras linhas.** Somadas, 414 µs/prim — 16× o rasterizador.

Não perca tempo no rasterizador: já foi medido em 3,7% do tempo de parede e já teve o
hoisting óbvio aplicado. E **não** mexa no scheduler (a linha "espera de lock"): é a Fase 2,
congelada por regra, e exige decisão do humano.

## Como medir (inegociável)

O projeto tem histórico de conclusões erradas por medição frouxa. Regras que saíram caras:

1. **Nunca corrida única.** A dispersão entre corridas do mesmo binário é 12-23%. Qualquer
   efeito menor que isso é indetectável com 1 corrida. Use
   `work\scratch\Measure-Phases.ps1 -Runs 3 -Seconds 300 -Label <nome>`, que reporta mediana
   **e dispersão**. Se a dispersão for maior que o efeito, não há resultado — diga isso.
2. **Normalize por trabalho.** Compare `µs/primitiva`, nunca tempo absoluto: as corridas não
   param no mesmo ponto (671k vs 646k primitivas em corridas equivalentes).
3. **Confirme a instrumentação dentro do binário** antes de confiar nela:
   `python -c "d=open(r'work/link/partial/mc3_partial.exe','rb').read(); print(d.count(b'<string>'))"`.
   Já aconteceu de medir 15 min um binário sem a instrumentação, e de instrumentar um bloco
   dentro de `PS2_IF_AGRESSIVE_LOGS` que compila para nada.
4. **Confirme que o exe é mais novo que a lib** antes de medir. O `Measure-Phases.ps1` já
   aborta nesse caso; não contorne.
5. Medição só com a máquina livre: nenhum outro `mc3_partial`, build ou link ativo. Duas
   medições sobrepostas já produziram um "ganho de 7,2%" que era ruído.

## Escopo

### Fazer

1. **Perfilar por dentro** antes de otimizar. O padrão de cronômetro de fase já existe e é
   copiável: veja `RasterScope` em `ps2_gs_rasterizer.cpp` (`drawPrimitive`) e os escopos em
   `ps2_vu1.cpp` / `ps2_vif1_interpreter.cpp`. Todos saem por `MC3_PHASE_TIMING=1` e custam
   zero com a variável ausente. Sub-instrumente por **comando VIF** e por **classe de opcode
   VU1** para descobrir onde o tempo está dentro de cada interpretador.
2. Só então otimizar o que a medição apontar.
3. Procurar **diagnóstico esquecido no caminho quente**. Já foram encontrados dois casos:
   - `ps2TraceGuestWrite` chamado em toda escrita de memória guest;
   - em `processVIF1Data`, uma varredura linear do pacote inteiro (memcpy de 8 bytes a cada
     4 bytes) que existia só para alimentar diagnóstico com teto de 16 logs. Já gateada, mas
     o padrão sugere que há mais.
4. Candidatos clássicos, a confirmar por medição e não por leitura: despacho por `switch`
   grande, recomputação de invariantes dentro de laços, cópias byte a byte onde caberia
   bloco, `std::function`/indireção no laço quente, atômicos por item.

### NÃO fazer

- **NÃO** mexa em scheduler, `GuestExecutionScope`, SIF, dispatcher ou no rasterizador.
- **NÃO** altere semântica para ganhar velocidade. Pular trabalho que o hardware faz não é
  otimização, é bug adiado. Se um caminho parecer removível, prove que é diagnóstico ou
  redundante antes.
- **NÃO** crie env-gate experimental novo. `MC3_PHASE_TIMING` já existe para medição.
- **NÃO** toque em `work/generated/ghidra/sub_0041D0B0_0x41d0b0.cpp`,
  `FUN_0041cfa0_0x41cfa0.cpp` nem `sub_0041CE68_0x41ce68.cpp` (`logf`/`powf`/`expf`) — estão
  sendo investigados em paralelo por outra frente.

## COORDENAÇÃO — leia antes de rodar qualquer coisa

Há investigação paralela em curso na mesma máquina, e ela **também** usa o runner.

- **Antes de qualquer build, relink ou corrida**, verifique que não há processo ativo:
  `Get-Process mc3_partial,cc1plus,'g++',ld,collect2 -ErrorAction SilentlyContinue`.
  Se houver, **espere**. Medir com disputa de CPU invalida o resultado.
- Trabalhe primeiro na leitura e na sub-instrumentação (edição de código), que não conflita.
- Use labels de log próprios (`Measure-Phases.ps1 -Label vif1_<algo>`) para não sobrescrever
  logs da outra frente.

## Ambiente

```
toolchain:   C:\msys64\ucrt64\bin        (prefixar no PATH; a suite TAMBEM precisa em runtime,
                                          senao morre com 0xC0000139, que parece falha de teste
                                          mas e DLL)
cmake:       C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe
build dir:   PS2Recomp\out\build          (RelWithDebInfo: -O2 -g -DNDEBUG)
build runtime: cmake --build PS2Recomp\out\build --target ps2_runtime -j 8
suite:       PS2Recomp\out\build\ps2xTest\ps2x_tests.exe   (CWD = PS2Recomp\out\build)
relink:      10_link_partial_runner.bat fast    (use caminho ABSOLUTO; com caminho relativo
                                                 ja falhou silenciosamente e mediu binario velho)
```

Nota sobre a suíte: 303 testes. Há um flake conhecido de timing (VBlank/preempção) que derruba
1 teste esporadicamente. Se falhar 1, rode de novo antes de investigar; se falhar o mesmo teste
duas vezes, aí é regressão de verdade.

## Regras não-negociáveis

1. Nunca injetar `SignalSema`.
2. Sem chute de bytes — decomp nomeado ou captura; incerto = TODO + neutro.
3. Sem env-gate experimental novo; scheduler congelado.
4. Exe relinkado tem que ser mais novo que a lib.
5. Commits locais, **sem push**.
6. No `work/exports/retail_symbol_port.csv`, use SEMPRE a coluna `retail_addr` (a primeira).
   Já houve incidente grave por usar `alpha_addr`, que pertence a outro build — ver
   `docs/RESULT_ALPHA_GFX_TRACE_REMOVAL_2026-08-29.md`.

## Aceite

Frase binária: **a mediana de `vifUs` ou `vu1Us` (3 corridas) cai de forma maior que a
dispersão medida, com a suíte verde e sem mudança de semântica.**

Resultado negativo é entregável: se a sub-instrumentação mostrar que o tempo está espalhado
sem ponto quente, isso vale tanto quanto um ganho — diga onde está e por que não há alvo
fácil.

## Critérios de parada

- Vitória do passo (o aceite).
- Efeito menor que a dispersão → pare e reporte como não conclusivo, não maquie.
- Suíte vermelha duas vezes no mesmo teste → reverta e documente.
- Qualquer mudança que exija alterar semântica → pare e documente, não implemente.

## Entregáveis

1. `docs/RESULT_VIF1_VU1_PERF_2026-08-30.md` honesto: perfil por dentro, o que foi mudado,
   medianas e dispersões antes/depois, suíte, e o que **não** foi provado.
2. Commits locais pequenos no submódulo (branch `mc3`). Sem push.
3. Bloco appendado em `PS2_PROJECT_STATE.md`.
4. **Não** sobrescrever `STATUS.md`.
