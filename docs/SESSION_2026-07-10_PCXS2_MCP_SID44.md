# Sessao 2026-07-10: PCSX2-MCP e blocker sid=44

## Resultado

O PCSX2-MCP confirmou o jogo real e forneceu um snapshot util do caminho de arquivo/pacote. A evidencia atual aponta para estado de package/list provider ausente ou incompleto no runner parcial, antes de tratar `sid=44` como um simples problema de semaforo.

## Evidencia confirmada

- Jogo: `Midnight Club 3 - DUB Edition Remix`, `SLUS-21355`, versao `1.00`.
- PC pausado em `0x004f9760`, funcao `FUN_004f9760_0x4f9760`, chamada por `sub_003991F0_0x3991f0`.
- Argumento observado: `fonts/mcloadstrings.strtbl`.
- Globals live de package/list: `0x629f44=0x5c0c40`, `0x629f48=0x5c0c50`, `0x629f4c=0x41f9b0`.
- Flag live `0x6218fc=1`.
- Tabela live de backend em `0x617fc0`: open `0x3984c0`, close `0x398610`, read `0x3986d8`, seek `0x398730`, stat `0x398788`, extra `0x3987e0`.

## Correcao de nomenclatura

`0x4f9760` e o dispatcher/provider de pacote. O backend low-level e selecionado pela tabela em `0x617fc0`, cujo primeiro entry e `0x3984c0`. Portanto, os erros anteriores de abertura no runner devem ser lidos como falha no estado/provider ou na camada de arquivo, nao como prova isolada de que `0x4f9760` e o backend.

## Relacao com sid=44

O worker `FUN_001f70e0_0x1f70e0` inicia com `arg=0x2c` e bloqueia em `WaitSema` usando `sid=44`, com retorno `ra=0x1f7150`. A sequencia parcial anterior coloca imediatamente antes dele `request=0x4`, payload `0x620d80`, tamanho `0x4`; tambem aparecem o request nao tratado em `0x6f9000` e requests do file-driver em `0x701b40`.

A leitura atual nao autoriza sinalizar `sid=44` diretamente. O proximo alvo e descobrir qual resposta de SIF/I/O deveria completar o estado do provider/package e permitir que o worker receba a notificacao correta.

## Limitacao da captura

O DebugServer caiu com `ECONNRESET` ao tentar adicionar/usar breakpoints e avancar instrucoes. O snapshot de memoria foi lido antes da queda; nao houve escrita live nem trace completo de retorno.

## Tasks pendentes

1. Implementar trace env-gated `MC3_TRACE_54A350_FILEOPEN` em `sub_0054A350_0x54a350.cpp`.
2. Rodar `10_link_partial_runner.bat`.
3. Rodar `15_auto_boot_probe.bat 6 payload1m3skip5a` com o trace ativo.
4. Comparar provider globals e requests com o snapshot PCSX2.
5. Escolher um unico experimento env-gated minimo: inicializacao/resposta do provider ou stub do file-driver.

## Atualizacao posterior: alvo oficial mudou para 0x2B4488

O texto acima registra corretamente o contexto que levou ate `sid=44` e `0x54BCB0`, mas esse nao e mais o blocker vivo. O baseline atual ja foi reproduzido depois disso com:

- `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a`

Resultado atual:

- stable PC: `0x2b4488`
- funcao: `sub_002B4438_0x2b4438`
- classificacao: `render-started`
- frame estavel: `ra=0x2b4478 sp=0x19fd00 gp=0x67f070 dma=2 gif=0 gsw=0 vif=3`

Interpretacao:

- `sub_002B4438` chama um metodo virtual do objeto global `0x006d557c` usando a entrada de vtable `+0x24`.
- Se o retorno vier `0`, a funcao cai num spin local explicito em `0x2b4488`.
- Portanto, o blocker atual nao e um `WaitSema` local: ele e uma espera ocupada por um valor/objeto ainda nao produzido.

Caller e cadeia viva:

- `FUN_003b34c0_0x3b34c0` chama `sub_002B4438` em sequencia para indices `0..8`, usando strings em torno de `0x0066d330`.
- O `ra=0x2b4478` do frame estavel e o retorno imediato do `jalr` virtual dentro da propria `sub_002B4438`.

Relacao com `sid=44`, `0x620d80` e `0x701b40`:

- `sid=44` ainda aparece bloqueando `tid=4` em `pc=0x5469e0 ra=0x1f7150`, mas isso nao explica sozinho o PC atual.
- Os requests de file-driver continuam aparecendo antes do spin:
  - `request=0x0 payload=0x701b40 size=0x8`
  - `request=0x9 payload=0x701b40 size=0x4`
- `request=0x4 payload=0x620d80 size=0x4` ainda existe na baseline atual, mas ja nao define o blocker principal.

Conclusao operacional:

- `0x54BCB0`, `sid=44` e `0x701b40` continuam relevantes como contexto causal possivel, mas hoje sao hipoteses upstream.
- A pergunta principal virou: qual valor `sub_002B4438` espera em `0x2B4488`, quem deveria produzir isso, e se essa producao depende mesmo dos requests `0x701b40`.

Pendencia correta a partir daqui:

1. Mapear quem inicializa/escreve o global `0x006d557c`.
2. Identificar a funcao concreta na vtable `+0x24`.
3. Confirmar se o produtor desse estado depende dos requests `0x701b40`.
4. So entao decidir por um experimento env-gated de file-driver.

## Reancoragem apos corrigir o wrapper do Boot-Probe

Correcao aplicada:

- `tools/Boot-Probe.ps1` tinha um bug real no wrapper: `Invoke-ProbeRun` fazia `Invoke-BatStep ... | Out-Host`, e isso fazia `Write-Step` tentar gravar um objeto/stream nao legivel com `Add-Content`. O ajuste foi minimo: remover esse pipe.

Baseline apos a correcao:

- `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a`
- Resultado do parser atual:
  - `Classification=render-started`
  - `Stable PC=0x5469c0`
  - funcao: `SignalSema_0x5469c0`

Nuance importante:

- O trace cru ainda mostra o frame `pc=0x2b4488 ra=0x2b4478`.
- Entao `0x5469c0` e o loop mais frequente observado pelo sumarizador, nao uma substituicao completa do caminho `0x2B4488`.

Open path confirmado no runner atual:

- Rodando com `MC3_TRACE_3991F0_OPEN=1`, `sub_003991F0_0x3991f0` usa:
  - provider slot `0x618020`
  - provider `0x619f58`
  - metodo `0x4f9760`
  - backend table valida em `0x617fc0` (`open=0x3984c0`, `close=0x398610`, `read=0x3986d8`, `seek=0x398730`, `stat=0x398788`, `extra=0x3987e0`)
- O retorno repetido e `handle=0xffffffff` para:
  - `texture.zip`
  - `texture/fx_rider_detailmap_0.tex`
  - variantes `.xtex`, `.tga`, `.ipu`

Leitura causal atual:

- O backend low-level nao esta nulo; ele esta registrado.
- O miss agora parece estar no provider/package state ou na disponibilidade do conteudo dentro do provider.
- `0x701b40` continua aparecendo nao tratado no mesmo trace:
  - `request=0x0 payload=0x701b40 size=0x8`
  - `request=0x9 payload=0x701b40 size=0x4`
- Mesmo assim, ainda nao existe prova causal suficiente para implementar resposta em `0x701b40` antes de entender quem deveria fazer `0x4f9760` parar de devolver `-1`.

Estrutura nova mapeada:

- `sub_004F9AA0_0x4f9aa0` escreve/atualiza `0x00629f4c`.
- `sub_004F9B38_0x4f9b38` fica em loop enquanto `0x00629f4c != 0`, reentrando em `sub_004F9AA0`.
- `sub_004FB0D8_0x4fb0d8` aloca/gerencia slots de package-open na area `0x006f3b00` antes do dispatcher `0x4f9760`.

Pergunta certa daqui pra frente:

- Quem produz o estado valido de package/provider para `0x4f9760`, e se esse produtor depende mesmo dos requests `0x701b40`.

## Atualizacao: cadeia local do package provider

Mapeamento fechado nesta sessao:

- `sub_003991F0_0x3991f0` escolhe o slot de provider `0x618020`.
- Esse slot aponta para `0x619f58`, cujo metodo de open e `FUN_004f9760_0x4f9760`.
- `FUN_004f9760` tenta primeiro o provider global `0x629f44`; se falhar, anda pela cadeia fallback em `0x629f4c`.

Produtor local desse estado:

- `sub_004F9A68_0x4f9a68` constrói um novo node fallback:
  - encadeia o `0x629f4c` antigo no campo `0`
  - zera campos de estado
  - grava `0x629f4c = novoNode`
- `FUN_004faa10_0x4faa10` roda logo depois em fluxos de setup de pacote/lista e pode marcar:
  - `0x629f40 = 1`
  - `0x629f41 = 1`
- `sub_004FAED8_0x4faed8`, chamado por `sub_004FB0D8_0x4fb0d8`, consome exatamente essas flags `0x629f40/41` para escolher o layout/local builder do package-open.

Leitura das subfuncoes:

- `sub_004FA5B8_0x4fa5b8` e um canonicalizador/filtro de path.
- `sub_004FAED8_0x4faed8` monta o request/objeto local de package-open e chama `FUN_00431b80_0x431b80`.
- `sub_004FB0D8_0x4fb0d8` so gerencia/aloca slot de open na area `0x006f3b00` antes do dispatcher `0x4f9760`.

Conclusao causal atual:

- O estado `0x629f4c` e as flags `0x629f40/41` nascem de uma cadeia local de package/list setup.
- Ate aqui nao apareceu evidencia estrutural de que `request=0x0/0x9 payload=0x701b40` seja o produtor direto desse estado.
- Portanto, ainda nao ha base para implementar `0x701B40` como proximo passo imediato.

Proximo passo correto:

- Encontrar quem deveria popular `0x629f44` no runner parcial, ou por que o setup que ja cria `0x629f4c` nao consegue produzir um provider capaz de abrir `texture.zip`.
