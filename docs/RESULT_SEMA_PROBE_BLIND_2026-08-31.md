# As sondas de semáforo estavam cegas na janela investigada — 2026-08-31

Sessão seguinte ao handoff `HANDOFF_2026-08-31_SESSAO_FRESCA.md`. Fecha os dois itens que
aquele handoff deixou anotados e não feitos, e um deles derruba uma conclusão viva.

## 1. A coluna do CSV: a alegação estava certa

Verificada linha a linha em `work/exports/retail_symbol_port.csv`:

- 8.815 linhas.
- Coluna 2 (`retail_old_name`): **42** têm nome real, todas de kernel (`AddIntcHandler`,
  `RemoveDmacHandler`, `SetAlarm`...). As outras 8.773 são só o rótulo `FUN_` do Ghidra.
- Coluna 4 (`alpha_name`): **100% preenchida**.

Confirmado também o caso concreto: `0x4323E8` é `datStreamer::Close(unsigned int)` na coluna
4 e `FUN_004323e8` na coluna 2.

## 2. `work/scratch/resolve_symbols.py` — o resolvedor

Fecha a armadilha de vez: qualquer script que precise de nome chama isto e não escolhe coluna.
Combina duas fontes, porque nenhuma sozinha basta:

| fonte | dá | cobre |
|---|---|---|
| nomes de arquivo do corpus (`<rótulo>_0x<entrada>.cpp`) | **fronteiras** exatas de função | 15.812 (todas) |
| `retail_symbol_port.csv`, coluna 4 | **nomes** reais | 8.815 (55,7%) |

Só o CSV não delimita função, então endereço dentro de uma função não portada era atribuído à
função nomeada anterior — que pode estar longe. Era assim que `0x431F98` aparecia como "depois
de `datStreamer::ValidateHandle` +0x1F8".

Ligado ao `find_divergence.py`: a linha de `pc` agora sai com o nome embaixo.

## 3. O worker tem nome: `datStreamer::Worker(void *)`

`FUN_00431E00`, a função central de toda a investigação, estava sem nome porque o port a
recusou: alpha `0x3F4080` tem 812 bytes, retail tem 736, e o port exige tamanho compatível.
Nas duas builds ela fica entre `ValidateHandle` e `Read`, na mesma ordem, com os vizinhos de
tamanho idêntico. Está em `OVERRIDES` no resolvedor, com a evidência ao lado.

Duas leituras corrigidas por isso:

- **`0x431F98` é `datStreamer::Worker +0x198`.** A sonda do "laço de transferência" estava
  dentro do worker, não numa função vizinha.
- **`0x432BA8` é `memcpy +0x88`**, não código do streamer. O "PC parado perto de `0x432ba8`"
  do handoff é uma amostra caindo dentro do `memcpy`.

As três "sem nome" do handoff continuam sem nome próprio — o MC.MAP tem um buraco ali — mas
são caracterizáveis por vizinhança: `0x3986D8` e `0x398788` na família `coreRaw*` (entre
`coreFileSignalSema` e `coreRawOpenFile`), `0x245680` na região `psxCdCache::*` (logo antes de
`psxCdCache::RawRead`). O resolvedor marca essas regiões entre colchetes, para não confundir
hipótese com nome.

## 4. O achado: toda sonda de semáforo se esgota antes do segundo pedido

O handoff mandava auditar as outras sondas atrás de tetos como o de 64 do `mcFlash::Update`.
Existem, e um deles invalida uma conclusão viva.

Em `catch_xfer_r2` (ramo ruim, 20.877 linhas), o **segundo dequeue está na linha 20.722**:

| sonda | teto | n | última emissão |
|---|---:|---:|---:|
| `CreateSema` | 128 | 128 | linha 2.726 |
| `WaitSema:wake` | 512 | 512 | linha 3.813 |
| `SignalSema` | 512 | 507 | linha 3.835 |
| `WaitSema:block` | 512 | 512 | linha 13.848 |
| `PollSema` | 512 | 512 | linha 16.202 |

**As cinco estão mudas na janela inteira do segundo pedido de streaming.** A de `SignalSema`
cala 16.887 linhas antes do evento.

Portanto a leitura de que "a sinalização de semáforo é idêntica nos dois ramos" não se sustenta:
ela foi tirada de uma janela em que o instrumento estava desligado. É a mesma armadilha nº 2 do
handoff — teto de amostragem que mente por omissão — em outra sonda.

Os contadores são `static std::atomic<uint32_t>` globais em
`PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Sync.cpp`, não por thread nem por sid.

## 5. Controle que a leitura do handoff ainda passa

O worker travar de verdade não é artefato de log cortado. Em `catch_xfer_r2` o segundo dequeue
é no tick 19.740 e a execução segue até o tick **23.580** — 64 segundos de jogo — sem `done` e
sem `park`. O handoff está certo nesse ponto.

## 6. O que mudou no binário

Os quatro tetos de `boot-trace` de semáforo em `Sync.cpp` subiram de 512 para 20.000
(`sigLog`, `blockLog`, `wakeLog`, `pollLog`), com a razão no comentário. Lib reconstruída, exe
relinkado, exe mais novo que a lib.

Nada mais foi tocado: os tetos de `RUNTIME_LOG` continuam onde estavam, e as outras sondas com
teto (VU1 em 256, GS em 64, MFIFO em 64, `recover` em 4096) seguem intactas — são de
subsistema que não está sob investigação agora, e estão listadas aqui para a próxima auditoria.

## 7. Armadilha nova, minha, para o próximo não repetir

O discriminador barato do handoff é `busy=0x2`. **No log ele sai `busy=0x00000002`**, com
zeros à esquerda. Procurar por `busy=0x2` devolve zero em toda execução e faz um ramo bom
parecer ruim. Classifiquei três execuções ao contrário até conferir o formato bruto.

Padrão correto:

```bash
grep -c 'busy=0x00000002' run.stderr
```

## 8. O que a próxima bateria responde

Com os tetos levantados, uma bateria com o mesmo protocolo mostra, na janela do segundo
pedido, quem sinaliza o quê e quem fica bloqueado em qual sid — que é exatamente o dado que
faltava para separar "worker não é escalonado" de "worker roda e não conclui".
