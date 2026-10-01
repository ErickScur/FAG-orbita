---
id: F54
title: Porta, doca e portal — três papéis, três leituras
status: done
scope: demo
block: 8
priority: P1
rubric: ["Arte coerente", "Cenário e ambientação", "Legibilidade"]
depends_on: ["F17", "F13", "F28", "F48"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F54 — Porta, doca e portal

## 1. Contexto e objetivo

O humano jogou e reclamou: *"a sprite do negócio de salvar checkpoint está muito igual a da
porta. o da porta tá muito sci-fi, não dá pra entender que realmente é uma porta. inclusive ela
deveria ser até mais alta eu acho, com mais cara de porta ou escotilha. dá a sensação de que é
uma máquina ou algo que pode pular por cima."*

A captura confirmou pior do que ele descreveu: **três objetos com papéis diferentes usavam o
mesmo vocabulário** — cápsula vertical de vidro com moldura metálica e cabo à direita:

| Objeto | Papel | Como era |
|---|---|---|
| `door.gd` (porta de energia) | barreira que o puzzle abre | cápsula cinza-ciano, 3 tiles, flutuando no meio do corredor |
| `backup_dock.gd` (Ponto de Backup) | checkpoint / recarga | cápsula ciana com cabo |
| `level_exit.gd` (saída de fase) | leva ao próximo setor | **o quadro 4 do mesmo sheet da porta** + luz verde |

E havia um erro de semântica mais grave que a semelhança: no sheet antigo a porta **acendia**
ao abrir. O estado `open` era a coluna mais brilhante e mais "sólida" da folha — uma barreira de
energia ligada. O jogador lia "passagem bloqueada" exatamente quando podia passar.

## 2. Diagnóstico — o que dava para resolver sem arte nova

Medi antes de aceitar as hipóteses do enunciado.

### 2.1 Altura: a porta **não pode** crescer

Varri as duas fases medindo o vão livre em cada coluna com porta:

| Fase | Tile | Vão livre | Conclusão |
|---|---|---|---|
| Estufa | `12,11` | **3 tiles (48 px)** | a porta **já** vai do chão ao teto |
| Núcleo | `60,11` | 5 tiles (80 px) | a porta flutua com 2 tiles de ar em cima |

Ou seja: aumentar o sprite para 64 px enfiaria a porta da Estufa dentro da parede. A altura
não é um problema do sprite, é um problema **do corredor do Núcleo**. Com `JUMP_HEIGHT = 40`
um pulo simples não passa por cima de 48 px, mas o pulo duplo (~80 px) passa — o convite visual
que o humano sentiu **era real**, não só impressão.

**Solução escolhida:** a porta mede sozinha o vão até o teto (raycast na camada `world`) e
desenha, por código, uma **antepara** (bulkhead) preenchendo o que sobra, com colisão de 16 px.
No Núcleo isso dá 32 px de parede acima da porta; na Estufa dá zero e nada é desenhado. A porta
passou a ser sempre chão-a-teto sem tocar em `data/levels/*`, e o buraco de pulo duplo fechou.

### 2.2 Moldura, cor e luz: resolvidos com um sheet novo, sem IA

O sheet definitivo da porta era inaproveitável (estado aberto mais sólido que o fechado), então
reescrevi os 6 quadros **proceduralmente**, em `tools/make_door_sheet.gd`. Porta é geometria
reta — é o caso em que desenho por código compete com arte gerada.

- **Batente:** jambas de 7 px, verga e soleira fixas, que **não se movem** quando a porta abre.
  É a moldura que faz o objeto ler como porta mesmo aberto.
- **Duas folhas** que recolhem para a verga e para a soleira (comporta / escotilha), com
  **vigia redonda** em cada folha — as duas janelas somem para dentro do batente conforme abrem.
- **Faixa de perigo âmbar/preto** no bordo de ataque de cada folha, na verga e na soleira. Âmbar
  é o "amarelo de sinalização de perigo" das Docas no [GDD-2.9](../design/GDD.md#gdd-2-9-paleta),
  e afasta a porta do ciano da doca em uma olhada.
- **Painel de comando** de 4×8 na jamba direita, com LED verde.
- **LED de estado** na verga: vermelho fechada, âmbar abrindo, verde aberta.
- **Aberta = vazio.** O vão fica transparente: vê-se o corredor do outro lado. O oposto do que
  o sheet antigo fazia.
- Figura/fundo: batente escuro (`#1e2a34`), folhas claras (`#3f5465`). Aberto o batente escuro
  fica, e o buraco lê como buraco.

### 2.3 Portal de saída: sexto quadro

O agente do `level_exit` confirmou que porta aberta e portal são o **mesmo pixel**. Acrescentei
um **quadro 5** ao sheet, com vocabulário próprio: batente mais pesado (sem parafusos, com
mísulas nos cantos), **placa de identificação de setor** na verga, e um **túnel verde em
perspectiva** (5 retângulos aninhados) com a luz vindo de dentro e escorrendo na soleira. Sem
faixa de perigo — perigo é peça que se move, e portal não se move.

### 2.4 Doca: nada a fazer

Com a porta fora do vocabulário de cápsula, a doca voltou a ser o único objeto de vidro
vertical do corredor e seu papel ficou claro. A arte dela é boa; o problema era o vizinho.
Não mexi. O prompt de regeneração está na seção 7 caso o humano queira separá-la ainda mais.

## 3. Escopo

### Inclui
- `assets/sprites/world/door_sheet.png` regerado: **192×48, 6 quadros de 32×48**.
- `tools/make_door_sheet.gd` — gerador reproduzível do sheet.
- `scenes/world/door.gd` / `.tscn` — antepara medida por raycast, desenhada em `_draw()`,
  com `BulkheadShape` de colisão.
- Sondas e roteiros de QA `f54_*` em `tests/qa/`.

### Não inclui
- `scenes/world/level_exit.*` (outro agente) — só a recomendação da seção 6.
- `docs/ASSETS.md` (do humano) — as fichas a atualizar estão na seção 7.
- `scripts/core/balance.gd` (outro agente) — constantes pedidas na seção 8.
- `data/levels/*` — a geometria das fases não mudou.
- Arte nova da doca.

## 4. Critérios de aceite

- [x] Porta, doca e portal legíveis como três objetos diferentes no mesmo enquadramento.
- [x] Porta chão-a-teto no Núcleo e na Estufa, sem mexer nas fases.
- [x] Estado aberto lê como passagem livre (vão transparente), não como barreira acesa.
- [x] Travessia do Núcleo e demo da Estufa (`f29_greenhouse`) fecham sem regressão.
- [x] Portões §6 verdes: `--import`, 681 testes, 77 cenas no smoke, varreduras limpas.
- [x] Sem comentários no código; nada 3D.

## 5. Definição técnica

### Contrato do sheet (mudou)

```
assets/sprites/world/door_sheet.png   192x48   6 quadros de 32x48
  0  fechada        duas folhas, duas vigias, LED vermelho
  1  abrindo 1/3    folhas recolhendo, vigias entrando no batente, LED âmbar
  2  abrindo 2/3    LED âmbar
  3  abrindo 3/3    LED âmbar
  4  aberta         vão transparente, lábios de perigo na verga e na soleira, LED verde
  5  PORTAL         túnel verde em perspectiva, placa de setor, soleira iluminada
```

`door.gd` usa 0–4. `level_exit.gd` deve passar a usar **5**. A colisão da porta continua
**16×48**, independente do sprite de 32 px.

### Antepara (`door.gd`)

```
BULKHEAD_MAX          48.0   teto do preenchimento (3 tiles)
BULKHEAD_DELAY_FRAMES 2      frames de física antes de medir
```

A medição espera 2 frames de física: na primeira física após o `_ready` a colisão do
`TileMapLayer` ainda não está registrada e o raycast atravessa o teto — foi exatamente o bug
que fez a porta da Estufa nascer com 48 px de antepara dentro da parede.

O raio sai 1 px abaixo do topo da porta e sobe `BULKHEAD_MAX + 1`; desconta o recuo. Sem acerto,
usa o máximo. A antepara é desenhada em `_draw()` (colunas do batente continuadas + parafusos a
cada 8 px) e ganha uma `RectangleShape2D` de 16 px de largura — a largura do tile, não a do
sprite, para o jogador poder encostar nos dois lados da porta como antes.

## 6. Recomendação para o `level_exit` (agente vizinho)

1. Trocar `const FRAME_OPEN: int = 4` por **`const FRAME_PORTAL: int = 5`** em
   `scenes/world/level_exit.gd` — uma linha, o quadro já existe no sheet.
2. A `PointLight2D` verde (`LIGHT_COLOR = #8fe3b0`, `LIGHT_ENERGY = 1.1`) pode **baixar para
   ~0.7**: o quadro 5 já emite luz própria pela soleira e pelo túnel, e a luz de cima competia
   com ele. A cor casa de propósito com o `PORTAL_TICK` do sheet.
3. O portal fica com o mesmo problema de altura que a porta tinha: no Núcleo ele mora no tile
   `76,11`, com 5 tiles de vão. Se quiser a mesma leitura chão-a-teto, o bloco
   `_draw()` + `_ceiling_gap()` de `door.gd` é copiável — mas o portal **não** deve ganhar
   colisão de antepara, porque é uma `Area2D` e virar corpo sólido mudaria o gatilho.

## 7. Prompts de regeneração (prontos para colar no `ASSETS.md`)

### SPR-DOOR — ficha a atualizar

| Campo | Valor novo |
|---|---|
| Contrato | Frames **32×48**, **6 quadros**: `closed` 1f · `opening` 3f · `open` 1f · `portal` 1f. Folha **192×48**. `sealed` reusa o quadro 0 tingido de vermelho. Sprite de 32 px transborda 8 px para cada lado da coluna de tile. **Colisão continua 16×48** |
| Status | **integrado (desenho procedural, `tools/make_door_sheet.gd`)** |

**Prompt (se o humano quiser trocar o desenho procedural por arte de IA):**

```
Pixel art sprite sheet of a vertical two-leaf bulkhead door for a 2D side-view space station platformer, seen flat from the side. It must read as a DOOR, not as a machine: a heavy fixed steel frame (two side jambs, a header beam and a floor threshold) that never moves, and two sliding leaves inside it that meet in the middle, each leaf carrying a round porthole window with dark blue glass. Amber and black hazard stripes on the leading edge of each leaf, on the underside of the header and on the threshold. A small status light on the header and a small control panel on the right jamb. Style: 16-bit pixel art, hard pixels, no anti-aliasing, cold grey-blue steel, amber hazard accents, dark navy glass. Layout: one row of 32x48 pixel frames, 6 frames: frame 1 closed with a red status light and both portholes visible, frames 2 to 4 opening (the upper leaf retracting up into the header and the lower leaf retracting down into the threshold, the portholes disappearing into the frame, amber status light), frame 5 fully open — only the empty frame remains, the whole doorway opening is TRANSPARENT so the room behind shows through, with a thin amber hazard lip under the header and above the threshold and a green status light, frame 6 is a different object: a SECTOR PORTAL, the same doorway but with a heavier frame, corner brackets, a small lit identification plate on the header, no hazard stripes at all, and the opening filled with a receding lit tunnel in green that glows from deep inside, with light spilling onto the threshold. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 768x192 pixels in total, which is four times the size it will have in the game (192x48, frames of 32x48). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

### SPR-DOCK — prompt de regeneração

A doca não precisa mais se afastar da porta (a porta saiu do vocabulário de cápsula). Este
prompt existe para o caso de o humano querer reforçar o papel dela: **o MU-7 entra e recarrega**.
O contrato (`160×48`, 5 quadros de 32×48) **não muda**.

```
Pixel art sprite sheet of a robot recharging and memory-backup dock for a 2D side-view space station platformer. It must NOT read as a door or as a doorway: it is an open-fronted alcove the robot walks into and parks in, wider at the base than at the top. Key shapes: a thick metal floor plate with two magnetic clamps that close around the robot's feet, a curved back shell, a hinged articulated mechanical arm folded down from the top right that would plug into a robot, and a thick ribbed power cable that leaves the right side and hangs in a loop. A cyan energy light lives INSIDE the shell. Style: 16-bit pixel art, hard pixels, no anti-aliasing, cold steel with cyan energy light, no yellow, no hazard stripes. Layout: one row of 32x48 pixel frames, 5 frames: frame 1 idle with the arm folded and the light dim, frames 2 to 5 charging, with a bright cyan pulse travelling up the cable and along the arm and the floor plate glowing brighter each frame. Solid flat magenta background (#FF00FF), no robot inside, no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 640x192 pixels in total, which is four times the size it will have in the game (160x48, frames of 32x48). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

## 8. Constantes pedidas ao `balance.gd` (outro agente)

Hoje moram em `door.gd` como constantes de arte/geometria. Se o dono do `balance.gd` quiser
centralizar, as duas que têm efeito de jogo são:

| Nome | Valor | Por quê |
|---|---|---|
| `DOOR_BULKHEAD_MAX` | `48.0` | altura máxima da antepara sólida acima da porta — define até onde a porta veda o corredor |
| `DOOR_BULKHEAD_DELAY` | `2` | frames de física esperados antes de medir o teto (menos que isso e o raycast fura o `TileMapLayer`) |

As cores (`BULKHEAD_OUTLINE`, `BULKHEAD_BODY`, `BULKHEAD_EDGE`) são arte e devem ficar no script.

## 9. QA

| Roteiro | Cena | O que prova |
|---|---|---|
| `f54_vitrine.json` | `f54_probe_vitrine.tscn` | porta, portal e doca no mesmo enquadramento |
| `f54_trio.json` | `f54_probe_trio.tscn` | fechada → abrindo → aberta |
| `f54_perto.json` | `f54_probe_selada.tscn` | porta selada (quadro 0 + tinta vermelha) |
| `f54_estufa.json` | `f54_probe_estufa.tscn` | Estufa: vão de 3 tiles, antepara zero |
| `f54_doca.json` | `f54_probe_doca.tscn` | doca ociosa e com o MU-7 encaixado |
| `f54_travessia.json` | `f54_probe_travessia.tscn` | travessia do Núcleo do tile 56 ao 78 |
| `f29_greenhouse.json` | `greenhouse.tscn` | demo fecha em FIM DA DEMO |

## 10. Log de evolução

- **2026-09-20** — Diagnóstico com captura: porta, doca e saída eram três cápsulas iguais e o
  estado aberto da porta era o quadro mais brilhante da folha.
- **2026-09-20** — Sheet regerado proceduralmente (5 quadros) e antepara medida por raycast.
  Primeira versão do raycast media errado: mediu na primeira física, antes de o `TileMapLayer`
  registrar colisão, e a porta da Estufa nasceu com 48 px de antepara enfiada na parede.
  Corrigido com `BULKHEAD_DELAY_FRAMES = 2`.
- **2026-09-20** — Vigias saíram como blocos escuros na primeira tentativa (anel de contorno
  grosso demais comendo o vidro em 9 px). Refeitas com gradiente vertical claro→escuro e
  contorno de 1 px.
- **2026-09-20** — Antepara com emendas horizontais a cada 8 px lia como **escada de poço de
  elevador**. Emendas trocadas por parafusos nas duas bordas.
- **2026-09-20** — Sexto quadro (portal) a pedido do agente do `level_exit`.
- **2026-09-20** — `f28_core_hub.json` trava o jogador no tile 59 (porta fechada) **desde antes
  desta feature**: rodei o mesmo roteiro com o `door.gd` do `HEAD` e o log de posições é byte a
  byte idêntico. É dívida do roteiro, não regressão. Registrado na seção 11.

## 11. Pendências

- `tests/qa/f28_core_hub.json` está desatualizado: o roteiro esperava a porta aberta a partir do
  frame ~1900 e o jogador para no tile 59 até o fim, perdendo as seis últimas fotos. Precisa de
  uma passada de quem cuida do roteiro do Núcleo.
- `docs/ASSETS.md`: aplicar a seção 7 (contrato SPR-DOOR de 160×48/5 para 192×48/6 e status).
