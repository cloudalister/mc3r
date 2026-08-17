# Próxima fase — Provider/Package

## Objetivo

Fazer o provider de pacotes ser criado e disponibilizado antes de `0x4F9760`, sem mascarar o erro com um handle falso.

## Estado confirmado

- O runner estabiliza em `0x5A8908`.
- `0x4FA398` chama `0x4FA488`.
- `0x4F9760` consulta o provider global em `0x629F44`.
- Se ele estiver vazio, usa a cadeia de fallback em `0x629F4C`.
- Sem provider válido, `0x4F9760` retorna `0xFFFFFFFF`.

## Gates

### Gate A — mapear os produtores

Localizar todas as escritas em `0x629F44`, `0x629F4C`, `0x629F40`, `0x629F41` e `0x629F50` no código gerado.

Alvos prioritários: `0x4FA7A8`, `0x4FAED8`, `0x4F9A68`, `0x3991F0`, `0x4F9760`.

Saída: função produtora, ordem de inicialização e valor esperado.

### Gate B — confirmar o caminho real

Comparar os produtores encontrados com o trace do boot e com a evidência PCSX2 já registrada. Não alterar runtime neste gate.

### Gate C — instrumentação mínima

Se o static trace não revelar o valor, adicionar trace env-gated para entrada/saída de `0x4FAED8`, `0x4F9A68`, `0x4FA7A8` e `0x4F9760`.

Recompilar somente o batch afetado, relinkar e rodar o probe. Nenhum `SignalSema` ou handle falso será injetado.

### Gate D — validação

Comparar o valor do provider, o retorno de `0x4F9760` e o Stable PC. Só então decidir se existe um experimento mínimo de compatibilidade.

## Próximo comando lógico

```powershell
rg -n "629F44|629F4C|629F40|629F41|629F50|4FA7A8|4FAED8|4F9A68|3991F0" work\generated\ghidra
```

## Critério de sucesso

O provider global é populado antes da chamada problemática, `0x4F9760` deixa de retornar `0xFFFFFFFF` e o probe avança além de `0x5A8908`.
