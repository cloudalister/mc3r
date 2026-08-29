# RESULT — build otimizado (-O2) — 2026-08-29

## Resultado

**O build otimizado funciona e não muda semântica, mas o ganho é de ~20%, não de ordem de
magnitude. O `-O0` NÃO era o gargalo dominante.**

Esta é uma correção explícita de um diagnóstico que eu (Claude) afirmei antes de ter medição.
Ver seção "Correção de diagnóstico".

## O que foi mudado

Quatro lugares construíam sem otimização; três foram corrigidos.

| Lugar | Antes | Depois |
|---|---|---|
| `tools/parallel_compile.py` (15.811 funções geradas) | sem flag `-O` | `-O2 -fno-strict-aliasing` |
| `COMPILE_KEY` em `parallel_compile.py` **e** `find_stale.py` | `...-v1` | `...-O2-...-v2` |
| CMake (runtime + testes) | `Debug` (`-g`) | `RelWithDebInfo` (`-O2 -g -DNDEBUG`) |
| `tools/Link-PartialRunner.ps1` (`main.cpp`, register, stubs) | sem `-O` | **mantido de propósito** |

O último foi deixado como está: é código de startup (registro de ~168 mil funções, executado
uma vez). Otimizar não traz ganho e `-O2` num arquivo desse tamanho tem risco real de
compilação patológica.

### Bug latente que o `-O0` escondia

O primeiro build otimizado falhou:

```
smmintrin.h:448:1: error: inlining failed in call to 'always_inline'
'int _mm_extract_epi32(__m128i, int)': target specific option mismatch
```

O arquivo de registradores guest é `__m128i` e o runtime o lê com intrínsecos SSE4.1
(`_mm_extract_epi32`, `ps2_runtime.h:185`), que são `always_inline`. O `PS2Recomp/CMakeLists.txt`
tinha branch de flags só para ARM64/NEON — **nenhum branch x86-64 habilitando SSE4.1**. Em
`-O0` o GCC nunca tentava inlinar, então passava batido.

Conclusão: **o projeto nunca havia sido compilado com otimização**. Não é que alguém a
desligou — ela nunca funcionou, e o erro só aparece quando se liga.

Corrigido com um branch x86-64 (`add_compile_options(-msse4.1)`), espelhando a flag que
`parallel_compile.py` já usava para o código gerado.

## Build e corretude

- Recompilação completa: **15.512 objetos, `failures=0`, 2378 s** (~40 min).
- Manifesto de hash de volta a 15.811 entradas; `find_stale` limpo (`Missing 0 / Stale 0`).
- Suíte: **300/300** sob `-O2` (mesmo número do `-O0`).
- Relink `fast` OK; zero stubs ausentes.

Tamanho dos artefatos:

| Artefato | `-O0` | `-O2` |
|---|---:|---:|
| `libps2_runtime.a` | 115 MB | 67 MB |
| `mc3_partial.exe` | 521 MB | 284 MB |

Nota de ambiente: `ps2x_tests.exe` só roda com `C:\msys64\ucrt64\bin` no `PATH`; sem isso
morre com `0xC0000139` (entrypoint not found), que parece falha de teste mas é DLL.

## Medição

Métrica válida: **tick em que `EndOfTransitionOut=1` é publicado** (fim da tela legal).

`ticks/s` foi descartado como métrica de velocidade do guest: o loop tem `SetTargetFPS(60)`
(`ps2_runtime.cpp:1009`), então o tick é frame do host travado no vsync. Medido: `-O0` =
55,8 ticks/s, `-O2` = 54,0 ticks/s. Ambos no teto; não medem o guest.

| Corrida | Build | Tick do `End=1` | Relógio aprox. |
|---|---|---:|---:|
| `gfx_probe_20260828_gfx1` | `-O0` | 35.040 | ~10,5 min |
| `gfx_probe_20260829_postvif0` | `-O0` | 30.180 | ~9,3 min |
| `gfx_probe_20260829_O2` | **`-O2`** | **25.680** | **~8,4 min** |

Ganho: **~20%** contra a média `-O0` (~32.600 ticks).

## Equivalência semântica

O estado final do `-O2` é idêntico ao do `-O0`, o que é forte evidência de que a otimização
não alterou comportamento:

- PC estável: `0x41D188` (`ra=0x41D000`) — igual.
- `gifPk1=348988`, `gifPk2=138800`, `gsPrims=704397`, `gsPixels=257216311` — **idênticos**.
- Mesmos PCs ausentes, mesmas contagens: `0x24A368` (27), `0x5BB178` (20), `0x5BB170` (16),
  `0x5BB220` (5), `0x5BD030` (4).
- Mesmas transferências VIF0 (normal + duas chain, `completed=1`).
- `mc3-gfx-*`: zero, como antes.

## Correção de diagnóstico

Eu afirmei, antes de medir, que "a lentidão é, em primeira ordem, `-O0`" e que "não é o
rasterizador, não é o scheduler — é uma flag de compilação". **Isso estava errado.**

O subagente provou que o `-O0` existia. Nem ele nem eu provamos que ele dominava o tempo do
guest — o próprio relatório do agente marcava o ganho como estimativa não medida. Eu tratei
"achei uma causa" como "achei a causa" e comuniquei com confiança que o dado não sustentava.

O `-O2` continua sendo mudança correta e válida (binário 45% menor, suíte verde, bug de
SSE4.1 destravado), mas é ganho estrutural, não a solução do problema de velocidade.

## Onde o gargalo está de verdade

A conta que deveria ter sido feita antes de qualquer diagnóstico:

- A tela legal precisa de **490 iterações** do script AVM1.
- No PS2 real isso é 490 frames, ~**8 segundos**.
- Aqui consome **25.680 frames de host**.

São **~52 frames de host por frame de guest**, com o host mantendo 54-60 fps o tempo inteiro.
O host nunca esteve lento. O problema é **quanto trabalho de guest ocorre por frame**.

Fatos verificados que delimitam a próxima investigação:

- `SetTargetFPS(60)` em `ps2_runtime.cpp:1009`; `BeginDrawing`/`EndDrawing` a cada volta do
  loop (`ps2_runtime.cpp:2716` / `2732`).
- `MC3_DISPATCH_BUDGET` (`ps2_runtime.cpp:115`, `2156-2175`) é apenas condição de parada por
  variável de ambiente, **não** um throttle por frame.
- Hipótese a testar (**não provada**): o guest cede controle ao host cedo demais a cada frame,
  provavelmente em espera de VBlank/semáforo no scheduler cooperativo.

## Pendências

1. Investigar quanto trabalho de guest roda por frame do host — a causa real da lentidão.
2. Auditoria de hash completa do `compile_manifest.json` (risco herdado: objetos compilados
   fora do `parallel_compile.py` podem deixar o manifesto mentindo).
3. Regiões não recompiladas: `0x24A368` (falta resume case, dentro de
   `mcCullable::SetClippingAndSphereTest`), `0x5BB170/78`, `0x5BB220`, `0x5BD030` (vãos).
4. `-O3` só depois de a causa real da lentidão ser entendida; hoje não se justifica.

Sem SignalSema injetado, sem env-gate novo, sem mudança de scheduler/dispatcher/SIF, sem
PCSX2, sem janela visível e sem push.
