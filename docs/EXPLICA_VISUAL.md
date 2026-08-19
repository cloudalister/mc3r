# Instruções para uma LLM: transformar este projeto numa explicação visual

Você é uma LLM que vai criar uma explicação VISUAL (infográfico, tirinha, diagrama ou
slides) de um projeto técnico. O público: uma pessoa curiosa, inteligente, com TDAH —
nada de jargão, nada de texto denso. Cada etapa vira UMA cena visual com no máximo
1 frase de legenda. Use metáforas do dia a dia. Pode usar humor.

## O projeto, em uma frase

Estamos pegando um jogo de PlayStation 2 (Midnight Club 3) e fazendo ele rodar no PC
**sem emulador** — traduzindo o jogo inteiro pra "língua" do PC, peça por peça.

## As cenas (desenhe uma por etapa, nesta ordem)

**Cena 1 — O quebra-cabeça virado pra baixo**
Um quebra-cabeça gigante de 15 mil peças, todas viradas pra baixo, cinzas, só com números.
Uma pessoa cavando no escuro há meses. Legenda: "O jogo era código sem nome — meses
travados sem saber onde".

**Cena 2 — O mapa do tesouro**
Chega uma caixa velha (um protótipo do jogo de 2004 vazado na internet) e dentro dela um
MAPA com o nome de cada peça. As peças viram pra cima e ganham cor. Legenda: "Um protótipo
antigo trouxe a 'planta' com 19 mil nomes — agora sabemos o que cada peça faz".

**Cena 3 — O alvo que parava de se mexer**
Antes: um fantasma que trava o jogo num lugar diferente a cada tentativa (impossível
mirar). Depois: o fantasma congelado no mesmo lugar, com um alvo desenhado nele.
Legenda: "Fizemos o jogo travar sempre no MESMO lugar — agora dá pra mirar".

**Cena 4 — As portas trancadas em fila (o corredor)**
Um corredor com portas trancadas em sequência. Cada porta tem uma plaquinha:
"telefone do CD" → "teclado fantasma" → "relógio parado" → "sprintf mudo" → "senha do
disco". Várias já estão ABERTAS com um ✔. Legenda: "Cada trava tinha nome; fomos abrindo
uma por uma, pela fechadura — nunca no pé-de-cabra".

**Cena 5 — A fábrica com defeito de série**
Uma esteira de fábrica (a "máquina de tradução" PS2→PC) cuspindo peças, algumas com o
mesmo defeito repetido. Um inspetor conserta O MOLDE, não as peças — e centenas se
consertam de uma vez. Legenda: "Achamos 5 defeitos no molde da tradução — um conserto
matou 95 bugs, outro matou 450".

**Cena 6 — O medidor no cano errado**
Um encanador olhando um medidor marcando ZERO, ligado num cano... que não é o cano
principal. Ao lado, o cano principal sem medidor. Legenda: "O medidor de 'o jogo desenhou
algo?' media o cano errado há meses — instalamos medidores nos canos certos".

**Cena 7 — Onde estamos agora (o dominó armado)**
Uma fileira de dominós prontos pra cair, com etiquetas: "resposta no formato certo" →
"tranca abre" → "jogo lê o disco pela 1ª vez" → "reconhece os arquivos (carros/pistas)" →
"carrega tudo" → "PRIMEIRA IMAGEM 🎉". Um dedo quase encostando no primeiro dominó.
Legenda: "Falta consertar UMA resposta dada no formato errado — e os dominós caem até a
primeira imagem".

**Cena 8 — A tela rosa (bônus, explica a frustração)**
Uma TV mostrando só rosa. Balãozinho: "o rosa não é erro — é a cor de 'ninguém desenhou
nada ainda'. Quando o primeiro desenho chegar, ela acorda."

## Regras de estilo

- 1 cena = 1 ideia. Nunca duas.
- Legendas de no máximo 20 palavras.
- Zero termos técnicos (proibido: semáforo, RPC, gate, PC, hex, syscall, framebuffer).
- Se precisar de um termo, troca por objeto físico: semáforo→campainha, RPC→telefonema,
  gate→porta trancada, framebuffer→tela, scheduler→maestro.
- Pode formato tirinha, infográfico vertical, ou 8 slides. Escolha um e seja consistente.
