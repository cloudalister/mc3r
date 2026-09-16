# Resultado - perfil e otimização VIF1/VU1 (2026-08-30)

## Resultado executivo

Aceite satisfeito. Em três corridas de 300 s por binário, normalizadas por
primitiva:

| Fase inclusiva | Antes (mediana) | Depois (mediana) | Queda | Dispersão antes | Dispersão depois |
|---|---:|---:|---:|---:|---:|
| VIF1 (`processVIF1Data`) | 227,48 us/prim | 92,66 us/prim | 59,3% | 12,6% | 1,7% |
| VU1 (`VU1Interpreter::execute`) | 186,24 us/prim | 60,39 us/prim | 67,6% | 12,8% | 3,1% |

As duas quedas são maiores que a dispersão medida. A suíte terminou em
`303/303`, com `0` falhas.

## Limite importante da régua

Os dois números são inclusivos e se sobrepõem; não podem ser somados como fases
exclusivas:

- o scope VIF1 envolve os callbacks síncronos MSCAL/MSCNT, portanto inclui VU1;
- DIRECT entrega e drena GIF Path2 dentro do scope VIF1, incluindo GS/raster;
- XGKICK entrega e drena GIF Path1 dentro do scope VU1, incluindo GS/raster;
- `vu1Ms` cronometra `execute`, mas não o caminho `resume` usado por MSCNT.

O handoff somava 227,5 + 186,2 us/prim. Essa soma é inválida como decomposição
exclusiva; os valores continuam úteis como réguas inclusivas antes/depois.

## Perfil por dentro antes de otimizar

Foi usado um subperfil temporário sob `MC3_PHASE_TIMING=1`, com buckets RAII por
comando VIF e por classe upper/lower VU. Foram feitas três corridas de 300 s. A
instrumentação temporária foi removida antes da medição final.

### VIF1

Mediana da participação no tempo classificado por comando:

| Bucket VIF | Participação | O que inclui |
|---|---:|---|
| MSCAL/MSCALF/MSCNT | 80,9% | callback VU síncrono |
| DIRECT/DIRECTHL | 16,6% | submit/drain GIF Path2 e downstream |
| UNPACK | 2,4% | decode e escrita VU data |
| controle/setup | 0,1% | NOP, STCYCL, BASE, OFFSET, ITOP, FLUSH etc. |

Conclusão: o parser VIF próprio não era o grande consumidor. O tempo estava
quase todo nos callbacks downstream. Dentro de DIRECT também havia varreduras
de diagnóstico do payload que continuavam depois de esgotado o teto de logs.

### VU1

Mediana da participação no tempo classificado:

| Bucket VU | Participação |
|---|---:|
| helpers de diagnóstico por instrução | 42,0% |
| XGKICK + submit/drain downstream | 41,8% |
| upper Q/I FMAC | 5,1% |
| lower memória | 4,5% |
| lower DIV/SQRT/EFU | 4,1% |
| demais classes upper/lower | 2,5% |

O hotspot próprio provado foi diagnóstico: em todo par VU havia cópia de 16
bytes de `vf20`, chamadas de dois helpers, `getenv`, `memcmp` e atomics, mesmo
depois dos tetos de 256/192 linhas estarem saturados. XGKICK também carregava
scans diagnósticos repetidos no arbiter.

Essas participações são sobre o tempo classificado pelos cronômetros filhos;
fetch/decode, hazards e o overhead do próprio subperfil ficam no residual.

## O que mudou

### `ps2_vu1.cpp`

- cópia de `vf20` e helpers de trace só rodam enquanto os respectivos tetos de
  256/192 registros ainda podem produzir saída;
- branch, Q, MulQ, packet-write e XGKICK deixam de consultar ambiente e/ou fazer
  atomics depois dos tetos 256/128;
- o conteúdo dos primeiros registros foi preservado; apenas trabalho posterior
  incapaz de gerar saída foi removido.

### `ps2_vif1_interpreter.cpp`

- atomics usados apenas por `RUNTIME_LOG` agora compilam somente em `_DEBUG`;
- a busca linear por marcadores em DIRECT para depois dos 16 logs previstos;
- o gate já existente da varredura de pacote foi preservado.

### `ps2_gif_arbiter.cpp`

- as duas buscas de assinatura no submit e as duas no drain param depois dos
  24 logs previstos em cada lado;
- atomics de `RUNTIME_LOG` compilam somente em `_DEBUG`;
- o probe Path1 deixa de consultar ambiente/incrementar contador após 128.

Nenhum opcode, registrador VIF/VU, byte de pacote, fila GIF ou chamada real ao
GS foi removido. Scheduler e rasterizador não foram alterados neste lote. Os
três arquivos proibidos de `logf`/`powf`/`expf` não foram tocados.

## Medições completas

### Antes - `measure_split_r*.log.stderr`

| Run | Primitivas | VU1 us/prim | VIF1 us/prim |
|---:|---:|---:|---:|
| 1 | 398.142 | 186,24 | 227,12 |
| 2 | 381.780 | 184,52 | 227,48 |
| 3 | 361.903 | 208,31 | 255,68 |
| **Mediana** | - | **186,24** | **227,48** |
| **Dispersão** | - | **12,8%** | **12,6%** |

### Depois - `measure_vif1_vu1_diag_gate_after_r*.log.stderr`

| Run | Primitivas | VU1 us/prim | VIF1 us/prim |
|---:|---:|---:|---:|
| 1 | 529.038 | 60,89 | 93,54 |
| 2 | 504.495 | 59,02 | 91,97 |
| 3 | 507.222 | 60,39 | 92,66 |
| **Mediana** | - | **60,39** | **92,66** |
| **Dispersão** | - | **3,1%** | **1,7%** |

O exe final (`2026-08-30 01:59:53`) é posterior à lib
(`2026-08-30 01:59:00`). Dentro do exe final há exatamente uma ocorrência de
`guestWaitMs=`, `vu1Ms=`, `vifMs=` e `MC3_PHASE_TIMING`; as duas strings do
subperfil temporário têm contagem zero.

## Preservação dos diagnósticos

Em cada uma das três corridas finais, os tetos continuaram completos:

- VU: vf20 256, transform 192, branch 256, Q 256, MulQ 256,
  packet-write 256 e XGKICK 128;
- VIF/GIF: COPY_REF_DIRECT 16, ARB_SUBMIT 24, ARB_DRAIN 24,
  VIF_SUMMARY 16 e DRAW_SUMMARY 16.

Isso é evidência de que o gate removeu trabalho somente depois de a saída
diagnóstica possível estar esgotada.

## Validação

Com `C:\msys64\ucrt64\bin` no PATH e CWD `PS2Recomp\out\build`:

```text
Total Tests: 303
Passed: 303
Failed: 0
```

Build oficial `RelWithDebInfo` e fast relink passaram. O relink usou o caminho
absoluto `<project-root>\10_link_partial_runner.bat`.
Commit local do submódulo: `27faf89` (`mc3`), sem push.

## O que não foi provado

- Não foi obtido tempo exclusivo de parser VIF ou ALU VU separado de todo o
  downstream; os scopes de fase atuais são inclusivos.
- Não foi medido o caminho `VU1Interpreter::resume` como fase VU própria.
- Não foi isolada a contribuição individual de cada gate; o lote foi medido
  como uma otimização diagnóstica coesa.
- Não foi feito benchmark com `MC3_BOOT_TRACE=0`; o resultado oficial segue o
  protocolo do handoff, que liga essa variável.
- Não houve aceite visual/manual neste lote. A equivalência foi coberta pela
  suíte e pela preservação exata dos tetos de trace.
- Não foi provado que switch dispatch, `std::function`, UNPACK ou a semântica de
  XGKICK precisem de otimização adicional.
