# Causa estrutural — a camada de resposta IOP não é um protocolo, é uma lista de endereços fixos

Data: 2026-08-13. Autor: Claude (Opus 5). Método: leitura do runtime + trace de boot com binário limpo.

## Resumo

O runtime não implementa o protocolo de resposta IOP. O que existe é uma cadeia de `else if`
com **endereço de payload fixo em código**, a maioria atrás de env-gate de experimento. Toda
resposta que não casa exatamente é descartada.

Num único boot, **14 respostas IOP são descartadas**, em 7 combinações distintas.

Isso explica o padrão que dominou as últimas semanas: cada experimento novo fixa o endereço
visto em *um* trace, o Stable PC anda, e a chamada seguinte usa outro buffer e trava de novo.
Semanas de PC mudando e zero frame.

## A estrutura, em `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp`

```
if (!rdram || !isMc3SifIopQueueExperimentEnabled() || payloadAddr == 0 || payloadSize < 4)  -> sai
bool wrote = false;                                                          // linha ~824
if      (requestId == 0x1  && payloadAddr == 0x007019C0)                     // linha 834
else if (requestId == 0xFF && payloadAddr == 0x00701B40)                     // linha 841
else if (requestId == 0x0  && payloadAddr == 0x00620D80 && size>=0x10 && <experimento>)
else if (requestId == 0x0  && payloadAddr == 0x00621600 && ...  && <experimento>)
else if (requestId == 0xE  && payloadAddr == 0x0061FC00 && ...  && <experimento>)
else if (requestId == 0x4  && payloadAddr == 0x00620D80 && ...  && <experimento>)
// nada mais casa -> [boot-trace:mc3-iop-response-unhandled]   // linha 932
```

Cada braço exige **`payloadAddr` exato**. O `payloadAddr` é, por natureza, o buffer do
chamador — muda conforme quem pede. Chavear o handler por endereço fixo faz ele funcionar
exatamente para o buffer que apareceu em uma sessão de trace, e falhar para todos os outros.

## A prova

Respostas descartadas num boot (`work\logs\14_run_boot_trace.log`):

| request | payload | size | vezes |
|---|---|---:|---:|
| `0x0` | `0x700dc0` | `0x4` | 1 |
| `0x0` | `0x701b40` | `0x8` | 3 |
| `0x1` | `0x6f9000` | `0x90` | 2 |
| `0x1` | `0x6fc780` | `0x80` | 3 |
| `0x9` | `0x701b40` | `0x4` | 2 |
| `0x22` | `0x620d80` | `0x4` | 1 |
| `0xff` | `0x700dc0` | `0x8` | 2 |

Cruzando com os handlers:

- **`request=0x1` tem handler**, fixo em `payloadAddr == 0x007019C0`. O guest usa `0x6f9000`
  e `0x6fc780`. Descartados. São **três buffers distintos para o mesmo request**.
- **`request=0xFF` tem handler**, fixo em `payloadAddr == 0x00701B40`. O guest usa `0x700dc0`.
  Descartado.
- `request=0x9` e `request=0x22` não têm handler nenhum.

Pior: `request=0x1` chega com `size=0x90` e `size=0x80` (144 e 128 bytes). O handler escreve
**um único `u32`**. Mesmo se o endereço casasse, ele preencheria 4 de 144 bytes. A estrutura
da resposta não é modelada em lugar nenhum.

## Como isso conecta ao bloqueio observado

Com binário limpo e budget 25k, 10/10 corridas param em `semaphore` e 9/10 na região
`0x54a0xx`. O bloqueio direto é `WaitSema tid=3 sid=5`, e `sid=5` nunca recebe sinal
(19 `SignalSema` no trace, para sids 7, 8, 10, 16, 29, 37, 40 — nenhum é 5).

No trace, quatro linhas antes do bloqueio aparece
`[boot-trace:mc3-iop-response-unhandled] request=0xff payload=0x700dc0 size=0x8`.

Correção de uma leitura anterior: `sub_00398A60` (cria) e `sub_00398B18` (espera) **não são
específicas de arquivo** — são wrappers genéricos de semáforo num módulo utilitário. Deduzir
"módulo de I/O" por proximidade de endereço com o ABI `0x3984C0/0x3986D8` foi fraco. A prova
de que são genéricas: o mesmo `ra=0x398b28` espera tanto `sid=5` (nunca sinalizado) quanto
`sid=7` (sinalizado normalmente de `ra=0x398b50`, par saudável de mutex).

## O que está provado e o que não está

**Provado:**
- A camada de resposta IOP é chaveada por `(requestId, payloadAddr fixo)`, a maioria atrás de env-gate.
- 14 respostas descartadas num boot, em 7 combinações.
- Dois requests (`0x1`, `0xFF`) têm handler, mas só para um endereço, e o guest usa outros.
- Handlers escrevem 4 bytes onde a resposta tem até 144.

**Inferência razoável, não provada:**
- Que este é o motivo de cada experimento mover o PC e travar em seguida.
- Que o `sid=5` sem sinal é sintoma disso.

**Não provado:**
- Que corrigir isso produz frame. Continua `gif=0 gsw=0` em 20/20 corridas de hoje.

## Consequência estratégica

Adicionar mais um `else if` com mais um endereço fixo atrás de mais um env-gate é continuar o
padrão que já não funcionou. A pergunta que vale investigar antes de qualquer novo experimento:

**o que é, de verdade, o protocolo de resposta IOP para esses requests?** Ou seja: dada uma
requisição `(requestId, payload, size)`, qual estrutura o IOP real devolve? Isso é o que
permitiria um handler genérico, indiferente ao endereço do buffer.

Fontes para responder: o snapshot PCSX2 real (o IOP verdadeiro responde — capturar a resposta
para `request=0x1 size=0x90` é o dado mais valioso disponível), e os módulos IRX em
`extracted_iso\SYSTEM\` que implementam o lado IOP.

## Próximo passo sugerido

Capturar, no PCSX2 real, o conteúdo do buffer de resposta para `request=0x1` (`size=0x90`) e
`request=0xFF` (`size=0x8`) no mesmo ponto do boot. Fluxo em
`docs\PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md`. Sem isso, qualquer valor escrito é chute.
