# GeoShot

## Conceito do Jogo

**GeoShot** é um top-down shooter 2D para iOS com estética geométrica retro. O jogador controla uma Kite — um losango — que atravessa uma dungeon de salas, enfrenta ondas de inimigos e fica progressivamente mais poderoso através de upgrades.

O objetivo é sobreviver pelos 3 andares da dungeon e derrotar o boss final. Cada run é única graças aos upgrades aleatórios, e o timer integrado incentiva o jogador a melhorar o seu tempo a cada tentativa.

## Elevator Pitch

GeoShot é um dungeon-crawler top-down para iOS onde formas geométricas combatem formas geométricas — rápido, minimalista e viciante. Sobrevive aos 3 andares, derrota o boss final e bate o teu recorde.

## Porque é Divertido

O loop de satisfação vem de três fontes: a tensão de uma sala fechada com inimigos a fechar espaço, a recompensa imediata de escolher um upgrade após cada vitória, e o incentivo de speedrun que motiva o jogador a melhorar a cada run. O auto-aim permite focar a atenção no movimento e posicionamento estratégico, não na pontaria — tornando o jogo acessível mas com profundidade.

## Como se Joga

O jogador usa um joystick e um botão:

- Joystick esquerdo: mover o jogador livremente pelo ecrã.
- Botão direito: disparar. Segurar = disparo automático contínuo; largar = para.
- Auto-aim: a Kite aponta automaticamente para o inimigo mais próximo e dispara nessa direção.

O mapa é uma dungeon com salas ligadas por corredores. Quando o jogador entra numa sala de combate, as portas fecham. Só abrem depois de todos os inimigos serem derrotados. No fim de cada sala, o jogador escolhe 1 upgrade.

## As Formas

**Jogador**

- Kite (Losango) — forma do jogador. Estatísticas equilibradas. Dispara automaticamente para o inimigo mais próximo.

**Inimigos**

- Squared (Quadrado) — inimigo base. Lento, alta vida, dispara uma bala pesada em direção ao jogador.
- Triangle (Triângulo) — inimigo base. Muito rápido, pouca vida. Persegue o jogador diretamente.

**Miniboss**

- Plus (+) — forma em cruz. Stats moderados, move-se lentamente, dispara nas 4 direções cardeais em simultâneo.
  
**Bosses**

- Pentagon — muita vida, move-se lentamente, dispara em padrão rotativo fixo. Encontrado no fim do Andar 2.

## Estrutura da Dungeon

- Andar 1 — 3 salas de combate + miniboss Plus (+).
- Andar 2 — 3 salas de combate + boss final Pentagon.
  
A dificuldade aumenta a cada andar: mais inimigos por sala, maior velocidade, maior dano.

## Upgrades

Após limpar cada sala, o jogador vê **2 cartas de upgrade** geradas aleatoriamente do pool. Escolhe 1.

**Upgrades Base**

- +Vida — aumenta a vida máxima do jogador.
- +Balas — dispara mais projéteis por tiro.
- +Dano — cada bala causa mais dano.
- +Velocidade — o jogador move-se mais depressa.
- +Velocidade de Disparo — dispara mais vezes por segundo.

**Upgrades Especiais**

- Perfurante — as balas atravessam inimigos em vez de parar no primeiro.
- Regeneração — recupera 1 HP a cada 8 segundos sem receber dano.

## Pontuação & Timer

**Pontuação**

- O jogador ganha pontos por cada inimigo morto, acumulados ao longo da run.
- Mostrada no HUD e no ecrã final.

**Timer (Speedrun)**

- Regista o tempo total de duração da run.
- Apresentado no HUD (centro do topo) e no ecrã final.

## Gameplay Loop

Explorar corredor → Entrar na sala → Portas fecham → Derrotar todos os inimigos → Escolher 1 de 2 upgrades aleatórios → Avançar para a próxima sala → Boss do andar → Próximo andar → Boss final → Vitória ou Game Over.

## Interface

- Menu Principal — botão para começar.
- HUD — vida, timer, pontuação, indicador de andar, slots de upgrades ativos, joystick e botão de disparo.
- Ecrã de escolha de upgrade — 2 cartas com nome e descrição.
- Ecrã de Game Over — pontuação final, tempo total, recomeçar ou menu.
- Ecrã de Vitória — pontuação final, tempo total.

## Abordagem Técnica (SpriteKit)

- `SKScene` para gerir as cenas (menu, jogo, game over, vitória).
- `SKShapeNode` para desenhar todas as formas geométricas.
- `SKPhysicsBody` para detetar colisões entre jogador, balas e inimigos.
- Joystick virtual com `SKShapeNode` e tracking de toque (`touchesBegan / touchesMoved / touchesEnded`).
- Auto-aim: distância euclidiana a todos os inimigos vivos, `atan2` para calcular ângulo.
- Portas: `SKSpriteNode` com `physicsBody`, `closeDoors()` / `openDoors()`; contador de inimigos vivos — quando = 0: `openDoors()` + `showUpgradeUI()`.
- Sistema de estados por inimigo: idle → chase → attack → dead.
- Timer: `startTime: Date` atualizado em `update()`.

## MVP

- Kite com movimento e disparo automático.
- Joystick virtual + botão de disparo funcionais.
- 2 tipos de inimigos: Triangle e Squared.
- 1 sala funcional com portas que fecham e abrem.
- 3 upgrades base (+Dano, +Velocidade, +Vida) escolhidos aleatoriamente após cada sala.
- HUD básico: corações e pontuação.
- Ecrã de Game Over.

## Ideias Futuras (Stretch Goals)

- Andar 1 completo: 3 salas + boss Pentagon.
- Andares 2 e 3 completos com boss Hexagon.
- Timer de speedrun no HUD e ecrã de Vitória.
- Upgrades Especiais (Escudo, Perfurante, Regeneração, Overdrive).
- Leaderboard local com Firebase.
- Geração semi-aleatória da ordem das salas.
- Feedback audiovisual (sons, partículas, screen shake).
- Salas especiais (tesouro, secretas) e minimapa.
- Sistema de raridade nos upgrades (comum, raro, épico).

## Maior Risco + Mitigação

**Risco:** Gerir múltiplos `SKPhysicsBody` ativos em simultâneo (jogador + balas + vários inimigos por sala) pode causar quebras de performance em iPhones mais antigos.

**Mitigação:**

- Limitar o número de inimigos por sala a 5–6 no máximo
- Remover balas fora do ecrã imediatamente com `removeFromParent()`
- Desativar física de nós em salas não ativas
- Testar em dispositivo físico desde a Semana 1, não só no simulador

## Cronograma de 6 Semanas (4h / semana)

### Semana 1 — Base do Jogo

- **Hora 1–2:** Criar a `SKScene` principal, desenhar a Kite com `SKShapeNode`, implementar joystick virtual com `touchesBegan / touchesMoved / touchesEnded`
- **Hora 3–4:** Movimento fluido da Kite pelo ecrã, limitar aos bounds da sala, testar em dispositivo físico

### Semana 2 — Combate

- **Hora 1–2:** Botão de disparo, disparo automático com `SKAction` repeat, `removeAction(forKey: "autoFire")` ao soltar
- **Hora 3–4:** Auto-aim com `atan2`; criar Triangle e Squared com movimento básico

### Semana 3 — Dungeon e Salas

- **Hora 1–2:** Sala com paredes, portas com `physicsBody`, `closeDoors()` / `openDoors()`
- **Hora 3–4:** Contador de inimigos; quando = 0: `openDoors()` + `showUpgradeUI()`; corredor de transição

### Semana 4 — Upgrades e Boss

- **Hora 1–2:** Pool de upgrades, geração aleatória de 2 opções, ecrã de escolha, aplicar efeito ao jogador
- **Hora 3–4:** Boss Pentagon; HUD completo (corações, timer, pontuação, indicador de andar)

### Semana 5 — Ecrãs e Leaderboard

- **Hora 1–2:** Ecrã de Game Over e Vitória; Menu Principal
- **Hora 3–4:** Firebase: configurar projeto, gravar e ler top runs

### Semana 6 — Testes e Polishing

- **Hora 1–2:** Testes completos do início ao fim; corrigir bugs de colisão e física
- **Hora 3–4:** Balanceamento (vida, dano, velocidade); MVP estável antes de avançar

## Notas

- Toda a arte é geométrica e desenhada por código. Não são necessários assets externos.
- O foco do MVP é ter 1 sala completa e jogável do início ao fim.
- Só avançar para salas adicionais e boss depois da 1ª sala estar estável e testada.

## Design Visual

Estilo retro arcade escuro. Sem texturas elaboradas. Tudo é geométrico e limpo.

### Fundo e Mapa

- Fundo muito escuro (quase preto) com grid subtil de pontos
- Paredes e limites das salas: retângulos sólidos brancos/cinzentos
- Corredores simples entre salas

### Inimigos — Cores por Forma

- Squared: branco. Triangle: laranja.
- Pentagon (Boss 1): azul. Hexagon (Boss 2): dourado.
- Ao morrer: explosão simples de partículas na cor do inimigo.

### HUD

- Vida em meios corações (topo esquerdo) — ex: 6 HP = 3 corações cheios
- Timer em tempo real (centro do topo)
- Pontuação com ícone dourado (ao lado do timer)
- Indicador de andar (ex: ANDAR 1)
- Slots de upgrades ativos (topo direito)

### Efeitos Visuais

- Partículas ao destruir inimigos — Stretch Goal.
- Flash de cor ao receber dano — Stretch Goal.
- Screen shake ao receber dano — Stretch Goal.
