# Probe de 20 minutos — concluido

2026-09-13 21:39:13–21:59:15 local. PID25204 encerrado pelo harness no limite;
nenhum runner permaneceu ativo. Reader terminou normalmente, exit0.
1202.0500839 segundos de parede;1193.75 segundos CPU. exitedBeforeLimit=false,
exitCode=null: o processo foi parado pelo limite, nao houve saida espontanea.

Executavel <scratch-dir>/mc3-menu-missing-20260913/bin/mc3_partial.exe
SHA719502b45720a33d3e1299359d55db4ea439e77aa3c0cb70af25b4102573ec4e.
Artefatos <scratch-dir>/mc3-menu-missing-20260913/run.
Entry-fix/host-clock/bridge/STQ ON; depth OFF; headless; START30s ON/30s OFF
apos45s. Metadados, receipt PID/path/start/hash e resultados preservados.

## Resultado

- 4 capturas apresentadas, inspecionadas. Primeira: avisos/logo; segunda: cena
  quase escura; terceira/quarta: logo e PRESS START legiveis, faixas brancas.
- 252 snapshots validos;218 pos-ativacao. Sequencia1/41/40/37/40, final40.
  Titulo inativo, painel ativo, gates do child e membro abertos no final.
- Animacao wrapper16D6710 usa frame delta; movie177F230, fps2563840.
- Sem texto Called unimplemented ou avisos dos tres enderecos recuperados.
  Isso nao prova que todos os mesmos caminhos do probe anterior foram executados.
- Sobreviveu alem dos896.5s da rodada anterior e produziu quarta captura.
  Nao e prova de menu utilizavel, ganho de FPS ou melhoria visual.

audit-final.json tem frames=0 porque QuietBootTrace estava ativo: NAO usar
essa contagem como ausencia de renderizacao. Capturas e snapshots sao as
evidencias de progresso.16 action-edge records intactos. Alguns logs sofrem
intercalacao entre threads; contagens abaixo sao linhas completas reconhecidas.

## Lookups ausentes restantes

| Endereco | Avisos | Semantica observada no ELF |
| --- | ---: | --- |
| 5CD768 | 781 | carrega float667384 em f1, copia para a1+4/a1, move para f0 |
| 5BB260 | 3284 | retorna a0+30 em v0 no delay slot |
| 5BB228 | 9 | le ponteiro a0+144 e retorna floatobj+270 |
| 5CC940 | 238 | jr ra; nop |
| 5BA338 | 7 | OR2 em wordthis+6C e grava no delay slot |
| 5BA440 | 5 | wrapper com stack/RA e chamada virtual: requer corpo completo |
| 5BA3D8 | 11 | jr ra; nop |
| 37E4D0 | 1 | cadeia de ponteiros desde617ADC e zera byteultimo+21B |

4336 avisos completos. Aviso de lookup nao prova chamada do fallback:
nao atribuir causalidade visual sem caller/RA ou teste controlado.
Bytes diretamente lidos dos segmentos PT_LOAD do ELF, nao deduzidos de nomes
dos owners gerados. Agrupamento em owner amplo nao prova continuacao interna.

Proximo trabalho: priorizar recuperacao exata de5BB260/5CD768 e metodos que
alteram flags, ou instrumentar callers dos lookups para confirmar uso; fixture
com registry completo antes de novo probe. Nao mudar flags da arvore por palpite.
Nenhum fonte/runtime foi alterado durante esta execucao.
