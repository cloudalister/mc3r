# Execucao manual: proximo bloqueio

Execucao <scratch-dir>/mc3-manual-20260913-153723, iniciada 15:37:23,
logs encerrados 15:41:18. Executavel leaf-5bb268; configuracao em launch.json.
Nenhum mc3_partial ativo na verificacao posterior.

stdout termina com Window closed successfully; stderr termina com PS2 Thread Exit.
Isso indica fechamento limpo, mas nao identifica quem solicitou o fechamento.
Sem mensagem Error: Called unimplemented nessa execucao curta. Nao valida o
trecho que anteriormente falhava apos aproximadamente 15 minutos.

Avisos de lookup ausente, contagem de linhas completas:
- 0x5BB238: 72
- 0x5CD780: 32
- 0x5CD790: 3

getFunction em PS2Recomp/ps2xRuntime/src/lib/ps2_runtime.cpp:2166 emite o aviso
quando a tabela nao contem o endereco. Lookup nao prova que a funcao retornada
foi executada. Portanto ainda nao ha causalidade demonstrada com o menu.

5BB238 consta no corpo amplo sub_005BAEF8_0x5baef8.cpp:1244, sem arquivo proprio:
carrega ponteiro a0+144; copia floats +264 e +268 para a1 e a1+4;
recarrega o ponteiro e retorna com f0 recebido de +270 no delay slot.
Nao substituir por um retorno constante nem registrar o inicio do owner amplo.

Leitura direta dos segmentos PT_LOAD do ELF SLUS_213.55 confirmou:
5CD780: 3C020066 (lui v0,66), 03E00008 (jr ra), C4407384
(lwc1 f0,7384(v0), delay slot): retorna float em 667384 e altera v0.
5CD790: 03E00008 (jr ra), 24020004 (addiu v0,zero,4, delay slot).

Proximo trabalho: extrair entradas exatas, validar opcodes de 5BB238 no ELF,
testar registradores/memoria/delay slots e binding real com registry completo,
relinkar variante isolada em C: preservando os artefatos anteriores.
Depois executar probe comparavel de 20 minutos com capturas e START controlado.
Nenhuma alteracao de runtime ou novo executavel nesta investigacao.
Menu completo e melhora visual continuam sem confirmacao.

## Recuperacao concluida 19:26

tools/Build-MenuMissingEntries.ps1 gera uma variante isolada em
<scratch-dir>/mc3-menu-missing-20260913/bin/mc3_partial.exe.
SHA256: 719502b45720a33d3e1299359d55db4ea439e77aa3c0cb70af25b4102573ec4e.
14 opcodes conferidos diretamente nos segmentos ELF antes de compilar.
As tres entradas novas foram adicionadas ao registro copiado, preservando 5BB268.
48 casos por configuracao OFF/ON passaram: 96 comparacoes com interpretador
restrito aos opcodes verificados, contexto completo e 32MB de RAM.
Cobertura inclui sobreposicao de a1 com a0+144 (primeira ou segunda escrita),
zero negativo, NaN com payload, RA e retorno da antiga 5BB268.
Erro inicial no teste (macro GPR_U32 sem parenteses em &c) corrigido;
copia inicial preservada em source/tests.compile-failed.cpp. Registro e entradas
ja compilados foram reutilizados; somente teste recompilado antes de linkar.
VERIFIED.json recebeu novamente as sequencias apos verificacao ELF repetida,
pois a retomada da compilacao inicialmente deixou esse campo nulo.
Executavel anterior preservado e hash reconfirmado. Nenhum probe longo novo
foi executado: causalidade dos avisos com o menu continua nao demonstrada.
