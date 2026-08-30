# RESULT — bug de tradução do `sqrt.s`: operando lido de `fs` em vez de `ft` — 2026-08-30

## Resultado

**Uma palavra errada no gerador de código quebrava todas as raízes quadradas do jogo.**
Corrigido. O congelamento desapareceu e o render saltou de 704.397 para 1.004.584
primitivas (+43%) e de 257 milhões para 1,09 bilhão de pixels (4,2×).

Este é provavelmente o bug mais consequente encontrado no projeto até aqui, e explica de
uma vez o congelamento do frontend **e** o não-determinismo que atormentava as medições
desde agosto.

## O bug

`PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp:2074`

```cpp
case COP1_S_SQRT:
    return fmt::format("ctx->f[{}] = FPU_SQRT_S(ctx->f[{}]);", fd, fs);
                                                            //  ^^ deveria ser ft
```

O R5900 do PS2 põe o operando de `SQRT.S` em **`ft`** (bits 20-16), não em `fs` como o
MIPS padrão. A `COP1_S_RSQRT`, na linha imediatamente abaixo, já usava `ft` corretamente —
a `SQRT` ficou inconsistente com sua vizinha.

### Prova empírica

Extraídas todas as codificações distintas de `sqrt.s` do corpus gerado:

```
encodings distintos: 131
valores de fs vistos: [0]
valores de ft vistos: [0,1,2,3,4,5,6,8,9,10,11,12,13,16,20,21,22,23]
```

**`fs` é zero em 100% das 131 codificações**, enquanto `ft` assume 18 valores distintos.
Se o operando estivesse em `fs`, o jogo tiraria a raiz do mesmo registrador (`$f0`) nas 585
ocorrências — o que é absurdo para um jogo 3D.

### Caso rastreado ponta a ponta

`mcLight::GetColor(const Vector3&, Vector3&)`, retail `0x00259D60`, cálculo de atenuação:

```
0x259da4:  mula.s  $f0, $f0        ; ACC  = dx²
0x259da8:  madda.s $f5, $f5        ; ACC += dy²
0x259dac:  madd.s  $f6, $f1, $f1   ; f6   = ACC + dz²      <- soma dos quadrados
0x259dd0:  sqrt.s  $f12, $f6       ; f12  = distancia
0x259df0:  div.s   $f12, $f12, $f7 ; f12  = distancia / alcance
0x259e08:  sub.s   $f12, $f20, $f12; base = 1.0 - (dist/alcance)
0x259e04:  jal     powf            ; powf(base, expoente)
```

Traduzido como `sqrt(f[0])` — ou seja **`sqrt(dx)`** em vez de `sqrt(dx²+dy²+dz²)`. Quando
`dx` é negativo, o resultado é NaN.

Cadeia completa do congelamento, cada elo confirmado por trace:

```
sqrt(dx) com dx<0        -> NaN
NaN / 20.0               -> NaN
1.0 - NaN                -> NaN
powf(NaN, 1.0)           -> NaN            [boot-trace:mc3-nan-powf] ra=0x00259e0c
logf(NaN)                -> laco infinito  [boot-trace:mc3-nan-logf] ra=0x0041d000
```

O laço de `logf` é a série de Taylor com saída em `c.eq.s $f3,$f1` (soma == soma anterior).
Pelo IEEE 754 NaN nunca é igual a nada, nem a si mesmo, então a comparação jamais fecha:
**4.294.967.296 iterações registradas** antes do contador `n` estourar para negativo.

Evidência: `work/logs/stall_logf_r3.log.stderr`, `work/logs/probe_20260830_lightnan.log.stderr`.

### Por que explica o não-determinismo

`dx = pos.x - luz.x` depende de onde a câmera está quando aquela luz é avaliada. Às vezes
positivo (funciona), às vezes negativo (NaN). Daí o mesmo binário, com a mesma
configuração, congelar em endereços diferentes a cada execução — comportamento documentado
desde `docs/STATUS_2026-08-07_AUDIT.md` e atribuído na época a ruído de medição.

Não era ruído de medição. Era a raiz quadrada.

## O conserto

1. **Gerador** (`code_generator.cpp:2074`): `fs` → `ft`, com comentário explicando a
   diferença do R5900 e a prova empírica.
2. **Arquivos já gerados**: propagado por `work/scratch/fix_sqrt_operand.py`, que lê a
   codificação da instrução no comentário e reescreve o operando a partir dela — não confia
   no registrador que já estava escrito.

```
arquivos corrigidos:   221
instrucoes corrigidas: 323
anomalias:             0
```

Das 585 ocorrências, 262 já apontavam para `f[0]` porque `ft` também era 0 — coincidência,
e permanecem corretas.

Optou-se por propagar em vez de re-rodar `04_run_recomp.bat` porque a regeneração completa
apagaria a instrumentação manual acumulada em várias sessões, boa parte sem script de
reaplicação.

## Efeito medido

Corrida headless de 900 s, binário de 2026-08-30 05:49.

| | antes | depois |
|---|---:|---:|
| NaN em powf/logf | presente | **nenhum** |
| Iterações travadas em `logf` | 4.294.967.296 | **nenhuma** |
| `gsPrims` | 704.397 | **1.004.584** |
| `gsPixels` | 257.216.311 | **1.088.137.517** |
| `rmcModel::DrawSkinned` | nunca disparou | **18 chamadas** |
| PC estável | `0x41D188` (dentro de `logf`) | `0x1D3990` |

`0x1D3990` está em `mcParticleFogMgr::DrawAllParticles` — renderização de partículas e
névoa, muito mais adiante no fluxo. `DrawSkinned` (modelos com esqueleto) nunca havia sido
alcançado em nenhuma corrida anterior.

## Limitações e o que NÃO foi provado

- **O dump de frame saiu preto** (9 KB contra 70 KB da tela legal). O gatilho estava em
  700.000 primitivas, que é logo após o teardown da tela legal e antes da cena nova
  aparecer — capturou o intervalo escuro entre as duas. **Não é evidência de que a cena 3D
  esteja preta**; é captura em momento errado. Refazer com gatilho acima de 1.000.000.
- **Não foi provado que o jogo alcança o menu.** O PC estável mudou para outro ponto de
  parada; destravar um bloqueio não garante ausência do próximo.
- **Não foi medido o efeito em performance.** Os ~3 fps têm outra causa, já medida:
  interpretadores VIF1/VU1 e contenção entre threads guest.
- **Não foi verificado se outras instruções COP1 têm o mesmo problema de campo.** O
  desmontador imprime `c1 0x......` para `sqrt.s`, indicando buraco também no decodificador
  textual; vale auditar as demais.
- Uma corrida única. Sem repetição, o efeito nos contadores não tem estimativa de variância
  — mas o desaparecimento do NaN e a mudança do PC estável são qualitativos, não estatísticos.

## Nota de processo

O bug foi encontrado **instrumentando pelo sintoma, não pela cadeia suposta**. Foram gastas
horas seguindo `FUN_001FADC0` → `powf` (a cadeia de câmera), que estava saudável: 2.203
chamadas com argumentos válidos. Um detector que disparava em "qualquer NaN, venha de onde
vier" achou o culpado — `mcLight::GetColor`, iluminação — em uma corrida.

Também custou caro perseguir a corrida certa por sorte: o runner é não-determinístico e 8
tentativas falharam em reproduzir o estado. A instrumentação por sintoma tornou a
reprodução desnecessária.

Sem SignalSema injetado, sem env-gate novo, sem mudança de scheduler/dispatcher/SIF, sem
mascaramento de NaN e sem push.
