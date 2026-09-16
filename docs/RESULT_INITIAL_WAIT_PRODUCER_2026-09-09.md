# Espera inicial: produtor identificado — 09/09/2026

Lote offline autorizado por Cloud com `go`. Nenhuma execução/build novo,
nenhuma mudança de runtime, fontes geradas, relógio ou scheduler neste lote.
Análise sobre as duas execuções fechadas timer_identity_r1/r2_20260909.

## Resultado confirmado nos logs

| Rodada | SID | Espera total | Aviso aceito até retorno da CV | Recuperar token |
| --- | --- | --- | --- | --- |
| R1 | 200 | 270094,6896 ms | 0,0079 ms | 0,1095 ms |
| R2 | 79 | 325867,6401 ms | 0,0464 ms | 0,1471 ms |

R1 stderr: sinal legal-worker linha8938, conclusão da espera8939,
retorno worker0 linha8941. R2:9029,9030,9032 respectivamente.
Mesmo state01ea1ff0 nos sinais e retornos; worker0=c8/4f corresponde ao SID
da própria execução. Essa correlação dinâmica acrescenta o elo que faltava
ao relatório de06/09; RA398b28 sozinho é wrapper genérico e não identifica dono.
Os timestamps de notificação vêm do semáforo sob seu mutex; linha de sinal
é anterior à chamada. Não usar proximidade de linhas como duração causal.

R1 tem53 snapshots dessa espera (idades3282..265313ms), owners7 em23 e-1 em30.
R2 tem64 snapshots (3915..324296ms), owners7 em33 e-1 em31. Esses snapshots
não provam ocupação contínua nem CPU consumida por thread7.

O primeiro endRaw1 registrado nos snapshots de transição está na linha8933
em R1 e9016 em R2, antes do sinal. Os valores endRaw/nScroll são leituras de
endereços globais fixos no hook de sub00211770, não identidade autônoma de
cada script. Correlação consistente com conclusão da transição, não prova
de que todo o atraso está no interpretador nem de frames por segundo.

## Caminho estático e próximo ponto exato

Fontes em work/generated/ghidra:

- FUN_001aae80_0x1aae80.cpp: worker0 vem de state+4000 e chama398b18.
- sub_00398B18_0x398b18.cpp: chama WaitSema5469e0, RA398b28.
- FUN_001aab90_0x1aab90.cpp: em1aac54 carrega state+4000 no delay slot,
  emite legal-worker-signal e chama398b40 -> SignalSema5469c0.
- O laço em1aabe0 chama1aac70, preserva seu retorno ems0, chama1aad28 e
  em1aabf4 repete enquanto s0==0. É candidato concreto para delimitar o custo.
- FUN_001aac70_0x1aac70.cpp consulta state+4010, objeto emstate+4008 e
  flags do objeto+14/+15; pode atualizar via1ac3f8 e sinalizar worker1(+400c).
- sub_001AAD28_0x1aad28.cpp usa state+4014 e chama processamento adicional
  a partir de5295f0/238980. Não atribuir a esta função tempo ainda não medido.

Importante: o teste em1aac44 de(v0+41f8) NÃO é uma barreira repetitiva
comprovada para sinalizar. Se zero, salta diretamente para1aac54 (sinal);
se não zero, chama1f8468 e depois converge para o sinal. Não chamá-lo de
state+41f8 sem provar a identidade do v0 retornado pela chamada virtual.

Próxima medição recomendada: delimitar entrada/saída de1aac70 e1aad28 por
instância do worker, contar voltas e registrar retorno que encerra o laço;
separar tempo de parede inclusivo de espera/token/CPU. Isso distingue custo
de uma volta de excesso de voltas. Só então avançar para scripts/render/esperas
internas que dominarem, sem pular tela ou forçar semáforo.

## Higiene de medição

O hook antigo sub00211770 faz busca de strings em até16KiB por chamada
enquanto o contador de emissões é menor que256; filtro de milestone acontece
depois da busca. QuietBootTrace não é garantia de desativar esse bloco.
Custo não medido: possível interferência da instrumentação, NÃO causa confirmada.
Qualquer futura comparação deve controlar essa configuração/proveniência.

## Entrega e limites

Criados tools/Analyze-InitialWait.js e tools/Test-AnalyzeInitialWait.js.
Analisador offline correlaciona semáforo, sinal, state e retorno worker0;
calcula diferenças de timestamps com BigInt antes de converter para ms.
Testes: vazio, correspondência, state divergente, retries, ausência de aviso,
delta acima de2^53:PASS. Aplicação aos dois logs confirma tabela acima.
Não acompanha Create/DeleteSema, portanto reuso de SID ainda requer cuidado.
Nenhum novo teste de runtime: binário não foi modificado neste lote.

Reprodução a partir da raiz do projeto:

```powershell
rtk proxy node tools/Test-AnalyzeInitialWait.js
rtk proxy node tools/Analyze-InitialWait.js work/logs/probe_timer_identity_r1_20260909.log.stderr
rtk proxy node tools/Analyze-InitialWait.js work/logs/probe_timer_identity_r2_20260909.log.stderr
```

Conclusão: remetente e destinatário confirmados nas duas esperas; atraso
anterior ao aviso, não recuperação lenta após o aviso. Custo interno do
produtor segue aberto. Sem ganho de desempenho ou desbloqueio visual alegado.
