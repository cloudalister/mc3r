# Painel posterior ao titulo: rota de desenho

Atualizacao09:11: flags abertas confirmadas em jogo. Os enderecos66... de recursos
abaixo eram uma interpretacao incorreta do ADDIU; os corretos65... contem nomes
MemCard/MenuOptionScreen. Ver RESULT_MENU_TRANSITIONS_2026-09-13.md.

## Resultado confirmado

O ultimo probe continua sendo menu_entry_20260913_a: titulo inativo, estado atual
panel+D8=40, painel ativo1725D50/vtable62BDE0. Nao houve novo teste visual nesta etapa.
Menu utilizavel continua NAO confirmado. Nenhum novo patch do renderer foi aplicado.

Auditoria direta do ELF e do registro fonte: os nove slots nao nulos de cada
vtable62BDE0 e62BCF8 terminam em funcoes que aceitam o endereco de entrada.
Nao reproduzem, nesses slots, a colisao de registro encontrada em33FEB0.
Isto nao valida todos os descendentes nem todos os calls internos.

## Desenho e teste executavel

- Vtable62BDE0+24: Update37EC18; +28: Render41F980.
- 41F988 le parent+44 e exige bit0; 41F99C passa parent+48 a4262D8.
- 4262E0..4262F4 exige bits0 e9 de child+44.
- 426300 chama child.vtable+28, passando o filho como receptor.
- Fixture usa registro compilado e objetos reais da ultima versao, substituindo
  apenas o metodo final do filho por um contador. Quinze combinacoes de flags:
  parent0/1/975 x child0/1/512/513/975, verificando contagem, receptor e retorno.
- PASS15/15 com MENU_ENTRY_FIX OFF e PASS15/15 ON. Isto prova o encaminhamento
  isolado, nao que os bits do filho estivessem ligados no ultimo jogo.

Artefatos: <scratch-dir>/mc3-menu-draw-20260913.
PASS.json, draw.0.stdout, draw.1.stdout, draw.rsp e vtable-audit-final.json.
O executavel original em E e o executavel menu-entry foram preservados.
Nao houve rebuild da biblioteca; fixture ligada a biblioteca imutavel menu-entry.

## Observacao preparada e limite

Read-MenuGuest.ps1 agora inclui drawChild, drawChildFlags, drawGateOpen,
drawChildVtable e drawChildRender para o candidato exato62BDE0. Leitura continua
read-only e mantem verificacao de identidade do processo/ELF e limites de RAM.
Sintaxe PowerShell passou; novos campos ainda NAO coletados em processo vivo.
O script mantem data/caminho dos probes anteriores: adaptar identidade verificada
ao proximo probe antes de chamar, nunca reutilizar PID antigo.

Update37EC18 consome o estado40, mas nao ha prova suficiente para nomear esse
painel como menu principal. Enderecos66ACFC/66AE24/66AE44 referenciam dados no ELF;
a leitura nao mostrou nomes de assets. Nao tratar esses enderecos como strings.

Proximo diagnostico: coletar parent+48 e flags/render do filho apos D8=40.
Se gate fechado, rastrear seu produtor; se aberto, seguir a funcao de desenho do
filho ate os comandos GS. Nao forcar flags nem alterar estado do jogo.
