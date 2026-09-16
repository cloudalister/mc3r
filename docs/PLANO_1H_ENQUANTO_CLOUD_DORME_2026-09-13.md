# Uma hora de MC3 e desligamento autorizado

Pedido direto de Cloud em13/09/2026: trabalhar por1h daqui em diante, registrar
ao terminar e usar PowerShell para desligar seu PC enquanto ele dorme.
Inicio09:49:30 America/Sao_Paulo (12:49:30 UTC). Encerrar ate10:49:30 local
(13:49:30 UTC). Nao iniciar outro ciclo de testes que ultrapasse esse horario.

Retomada automatica criada nesta mesma tarefa pelo Codex:
id mc3-concluir-1h-e-desligar, PAUSADA durante o bloco apos a retomada confirmada.
Regra limitada, sem tarefa nova. Ao retomar, trabalhar neste prazo absoluto e
pausar a automacao antes do desligamento. Nao confundir com a automacao antiga
mc3-investiga-o-at-6h, que permanece pausada e pertence a outro bloco historico.

## Plano

1.09:49-09:59: localizar emissor visual dos recursos MemCard/MenuOptionScreen.
   Partir de RESULT_MENU_TRANSITIONS_2026-09-13.md e estado atual; nao repetir
   investigacao das flags ja confirmadas abertas. Verificar instrucao/endereco
   antes de aceitar conclusao. Recursos65ACEC e65AE24, nao66....
2.09:59-10:24: investigar e testar uma correcao pequena/reversivel quando houver
   evidencia. Preferir fixture de codigo real/replay. Se nao houver causa
   demonstrada, produzir diagnostico concreto sem inventar patch.
3.10:24-10:39: validacao proporcional. Probe headless so com binario/hash
   preservados e limite que permita encerramento. Nao abrir janela. Nao mudar
   estado guest, forcar flags, pular intro ou editar saves.
4.10:39-10:49: encerrar apenas processos pertencentes a esta investigacao,
   aguardar harness, gravar resultado/fontes/manifesto e atualizar
   PS2_PROJECT_STATE.md. Distinguir sucesso tecnico de menu visual aceito.
   Ao terminar, executar desligamento autorizado via PowerShell.

## Regras operacionais

- Todo terminal via RTK. Saida em <scratch-dir>; E tem pouco espaco.
- Preservar executaveis/objetos anteriores e trabalho dirty. Sem commit/push.
- Nenhum rebuild/relink enquanto houver probe ativo.
- Exatamente um subagente economico de investigacao: reutilizar
  /root/investigar_plano. Resultados precisam de verificacao quando contradizem
  instrucoes MIPS; houve conclusoes incorretas anteriores.
- Nao escrever memorias globais. Registrar no projeto e artefatos.
- Autorizacao explicita de desligar persiste; nao pedir confirmacao de novo.
- Antes do desligamento, salvar tudo desta tarefa. Usar PowerShell para chamar
  shutdown.exe /s /t 0, sem /f. Nao forcar fechamento de outros aplicativos.
  Se aplicativo impedir desligamento, registrar tentativa/erro; nao inventar
  confirmacao de maquina desligada (nao e observavel apos perda de conexao).
- Se usuario corrigir horario/cancelar desligamento, incorporar a nova ordem.

## Ponto inicial confirmado

Ultimo probe menu_transition_20260913_a encerrado:40 amostras,21 depoisD8=40,
filho1725EA0 flags647 aberto; estado37 observado e retorno40 com START periodico.
Menu ainda ilegivel. Nao ha probe ativo. Executavel original e menu-entry
preservados. Ferramentas de observacao funcionam, runtime nao alterado nessa etapa.

## Entrega esperada

docs/RESULT_1H_ENQUANTO_CLOUD_DORME_2026-09-13.md com mudancas, verificacoes,
evidencias, limites, proximo passo exato e horario da tentativa de desligamento.
Atualizar este plano/estado se surgirem novas decisoes.
