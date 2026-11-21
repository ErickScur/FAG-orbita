# ASSETS.md — Registro de assets

> Toda arte, fonte, música e som do jogo tem uma ficha aqui. A ficha é o **contrato**: caminho final, dimensões, frames e grade. O código aponta para o caminho final; até o asset definitivo chegar, o placeholder (gerado por `tools/make_placeholders.gd`) ocupa o **mesmo contrato** em `assets/placeholder/`.
>
> Estilo, paleta, template de prompt e pós-processamento: [`ASSET-PIPELINE.md`](ASSET-PIPELINE.md). Para criar uma ficha nova, use a skill `asset-request`.

## Como o humano usa este arquivo

1. Filtre por `Status = pendente` e **Prioridade = A** (entra na demo).
2. **Opção 0 (padrão para arte por IA, desde 2026-10-27):** o **agente gera sozinho** com a geração de imagem do Codex CLI (`tools/gen_image.sh`, skill `gen-image`), usando o prompt da ficha e uma referência de estilo, fatia até o contrato e integra. O humano só aprova no jogo. As opções 1 e 2 ficam para áudio, pacotes gratuitos e para quando o Codex não estiver disponível.
3. **Opção 1 (grátis):** abra o link, baixe, salve em `~/Downloads/orbita-assets/<ID>/` e avise o agente com o ID.
4. **Opção 2 (IA, manual):** copie o **prompt** para o Gemini (Nano Banana Pro), baixe a melhor imagem para `~/Downloads/orbita-assets/<ID>/` e avise o agente.
5. O agente pós-processa (recorte, redimensionamento nearest, redução de paleta, fatiamento), coloca no caminho final, atualiza a cena, registra licença/créditos e muda o status.

**Legenda de status:** `placeholder` (só o gerado) · `pendente` (aguardando humano) · `recebido` (arquivo bruto chegou) · `integrado` (no jogo) · `final` (revisado).

**Como o código acha o arquivo** ([F05](features/F05-pipeline-assets-placeholders.md)): cenas e scripts pedem sempre o **caminho final** a `AssetResolver.texture()` / `AssetResolver.audio()` (`scripts/core/asset_resolver.gd`); se o definitivo não existe, ele cai no espelho `assets/placeholder/<mesmo caminho>`. Colocar o arquivo definitivo no caminho final e rodar `--import` é o único passo da troca. Os placeholders são regenerados por `"$GODOT" --headless --path . -s res://tools/make_placeholders.gd` a partir de `tools/placeholders.json` (dimensões, grade e paleta por setor). O arquivo bruto do humano é pós-processado por `tools/process_image.gd` (remove `#FF00FF`, recorta, redimensiona por nearest, reduz paleta, fatia o sheet).

---

## Índice

| ID | Tipo | Uso | Prioridade | Fonte preferida | Status | Feature |
|---|---|---|:--:|---|:--:|---|
| [SPR-MU7](#spr-mu7) | Sprite sheet | Protagonista | A | IA | **integrado** | F12 |
| [SPR-SR3](#spr-sr3) | Sprite sheet | Inimigo SR-3 | A | IA | **integrado** | F22 |
| [SPR-SPORE](#spr-spore) | Sprite/partícula | Enxame de esporos | B | Grátis/gerado | **integrado** | F23 |
| [SPR-TERMINAL](#spr-terminal) | Sprite | Terminal de Distribuição + terminal comum | A | IA | **integrado** | F16, F17 |
| [SPR-DOCK](#spr-dock) | Sprite | Doca de recarga / Ponto de Backup | A | IA | **integrado** | F11, F13 |
| [SPR-DOOR](#spr-door) | Sprite sheet | Porta de energia | A | IA ou Grátis | **integrado (IA)** | F17 |
| [SPR-PICKUPS](#spr-pickups) | Sprite sheet | Célula, Kit de Solda, Log, Dado, Capacitor | A | IA | **integrado** | F20, F27 |
| [SPR-PLATFORM](#spr-platform) | Sprite | Plataforma móvel | B | Grátis | **integrado** | F25 |
| [SPR-PLANT](#spr-plant) | Sprite sheet | Planta que cresce | B | IA | **integrado** | F25 |
| [SPR-PROPS](#spr-props) | Sprite sheet | Objetos do cotidiano (caneca, cadeira, foto, traje/corpo) | B | IA | **integrado** | F19, F28, F29 |
| [SPR-BOTANICO](#spr-botanico) | Sprite sheet | Drone BOTÂNICO 04 | C | IA | **integrado** | F34 |
| [SPR-CX2](#spr-cx2) | Sprite sheet | Torre Calibradora CX-2 (inimigo do Laboratório) | A | IA | **integrado (IA)** | F60 |
| [SPR-STEAM](#spr-steam) | Sprite | Bocal do jato de vapor | B | IA | **integrado (IA)** | F60 |
| [SPR-V9](#spr-v9) | Sprite sheet | Sentinela Voadora V-9 (inimigo da Enfermaria) | A | IA | **integrado (IA)** | F61 |
| [SPR-ICE](#spr-ice) | Sprite sheet | Gelo fino e parede de gelo | A | IA | **integrado (IA)** | F61 |
| [SPR-PROPS-DOCKS](#spr-props-docks) | Sprite sheet | Objetos das Docas (caixa, traje, poltronas…) | B | IA | **integrado (IA)** | F62 |
| [SPR-CRADLE](#spr-cradle) | Sprite | Berço vazio da nave de escape SELENE | A | IA | **integrado (IA)** | F62 |
| [SPR-COUPLER](#spr-coupler) | Sprite sheet | Acoplador de energia (4 estados; F63 reaproveita) | A | IA | **integrado (IA)** | F62, F63 |
| [FX-THRUSTER](#fx-thruster) | Sprite sheet | Jato do Propulsor | B | IA | **integrado (IA)** | F62 |
| [SPR-PROPS-INF](#spr-props-inf) | Sprite sheet | Objetos da Enfermaria (leitos, maca, soro, cápsula…) | B | IA | **integrado (IA)** | F61 |
| [SPR-CMD](#spr-cmd) | Sprite sheet | Sala de comando: baia da cápsula, transmissor e os dois consoles de alavanca | A | IA | **integrado (IA)** | F66 |
| [SPR-ENDING](#spr-ending) | Sprite sheet | Cutscene final: ARTEMIS por fora, cápsula em voo, planeta-alvo, Terra, clarão e onda do sinal | A | IA | **integrado (IA)** | F66 |
| [TIL-CORE](#til-core) | Tileset | Núcleo Central | A | Grátis + IA | **integrado** | F21, F28 |
| [TIL-GREENHOUSE](#til-greenhouse) | Tileset | Estufa | A | Grátis + IA | **integrado** | F21, F29 |
| [TIL-LAB](#til-lab) | Tileset | Laboratório (Verão) | A | IA | **integrado (IA)** | F60 |
| [TIL-INFIRMARY](#til-infirmary) | Tileset | Enfermaria (Inverno) | A | IA | **integrado (IA)** | F61 |
| [TIL-DOCKS](#til-docks) | Tileset | Docas (Vácuo) | A | IA | **integrado (IA)** | F62 |
| [BG-SPACE](#bg-space) | Camadas parallax | Espaço pelas janelas + menu | A | Grátis ou IA | **integrado** | F26, F07 |
| [UI-LOGO](#ui-logo) | Imagem | Logo ÓRBITA (splash + menu) | A | IA | **integrado** | F03, F07 |
| [UI-FONT](#ui-font) | Fonte | Fonte pixel de toda a UI | A | Grátis | integrado | F05, F07 |
| [UI-HUD](#ui-hud) | Sprite sheet | Molduras, células de Integridade, ícones de status | A | IA ou Grátis | **integrado** | F15, F23 |
| [FX-LIGHT](#fx-light) | Textura | Gradiente radial da lanterna/luzes | A | Gerado | final | F18 |
| [MUS-MENU](#mus-menu) | Música | Trilha do menu | A | IA | **integrado** | F04, F07 |
| [MUS-CORE](#mus-core) | Música | Trilha do Núcleo Central | A | Grátis | **integrado** | F28 |
| [MUS-GREENHOUSE](#mus-greenhouse) | Música | Trilha da Estufa | A | Grátis | **integrado** | F29 |
| [MUS-LAB](#mus-lab) | Música | Trilha do Laboratório | A | IA ou Grátis | pendente | F60 |
| [MUS-INFIRMARY](#mus-infirmary) | Música | Trilha da Enfermaria | A | IA ou Grátis | pendente | F61 |
| [MUS-DOCKS](#mus-docks) | Música | Trilha das Docas | A | IA ou Grátis | pendente | F62 |
| [MUS-CHASSIS](#mus-chassis) | Música | Momento CHASSI PERDIDO (one-shot) | B | Grátis | pendente | F46 |
| [MUS-GAMEOVER](#mus-gameover) | Música | Momento PERDA DE ÓRBITA (one-shot) | B | Grátis | pendente | F46 |
| [MUS-SECTOR](#mus-sector) | Música | Momento do religamento do setor (one-shot) | B | Grátis | pendente | F46 |
| [MUS-CRITICAL](#mus-critical) | Música | Camada de tensão do reator crítico (loop) | B | Grátis | pendente | F46 |
| [SFX-PACK](#sfx-pack) | SFX (lista) | Todos os efeitos da demo | A | Grátis | **integrado (23 de 29)** | F04 e várias |

---

## Fichas

<a id="spr-mu7"></a>
### SPR-MU7 — Chassi MU-7 (protagonista)

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/mu7/mu7_sheet.png` |
| Contrato | Frames **32×32**, sprite sheet em grade de **6 colunas**, fundo transparente. Linhas: `idle` 4f · `walk` 6f · `jump` 2f · `fall` 2f · `land` 2f · `hurt` 2f · `interact` 4f · `climb` 4f (garras) · `death` 4f · `dash` 3f (F31). Frames não usados na linha ficam vazios |
| Placeholder | Retângulo cinza-azulado 20×26 com "olho" ciano, uma cor por animação |
| Fonte preferida | IA (Nano Banana Pro) |
| Placeholder gerado | `assets/placeholder/sprites/mu7/mu7_sheet.png` (192×320 = 6×10 frames de 32×32) — `tools/make_placeholders.gd` |
| Pós-processamento | **(F31, 2026-10-27)** a linha `dash` vinha com rastro roxo-magenta pintado (375 px, vários semitransparentes, sobra do fundo de recorte). Removidos os pixels de violeta saturado e os pontos soltos só nessa linha; o rastro do dash agora é a partícula ciano do código. Original guardado no scratchpad da sessão |
| Status | **integrado** |

**Prompt (Nano Banana Pro):**
```
Pixel art sprite sheet of a small, old, bipedal maintenance robot called MU-7, side view facing right, 2D platformer game. The robot has a boxy rusty metal torso, two thick hydraulic legs, no arms, and a single round cyan optical sensor as its "eye" glowing softly. It looks heavy, worn and patched, with scratches, a faded yellow maintenance stripe and small antenna.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the robot. Never draw walls, floors, ground, ladders, platforms, pipes, scenery, props, shadows or any other object, not even when the animation implies one. If a pose suggests the robot is touching something, draw the pose alone, floating on the flat background.

Style: 16-bit era pixel art, crisp hard pixels, no anti-aliasing, limited palette of 16 colors (cold steel greys, desaturated blue, rust orange accents, cyan glow).

Layout: a clean grid of 32x32 pixel frames, 6 columns and 10 rows, each row one animation:
row 1 idle breathing (4 frames)
row 2 heavy walk cycle (6 frames)
row 3 jump, legs tucked (2 frames)
row 4 fall, legs extended downward (2 frames)
row 5 landing squash, knees bent (2 frames)
row 6 hurt, body recoiling, eye flashing (2 frames)
row 7 interacting, leaning forward with sensor brighter (4 frames)
row 8 climbing pose: the robot upright and vertical, body pressed forward, magnetic feet flat and gripping, arms-less torso tilted into the climb, legs alternating up and down as if scaling a vertical surface — NO WALL, NO SURFACE, NO BACKGROUND OBJECT, only the robot floating on the flat background (4 frames)
row 9 shutting down and collapsing, the eye going dark (4 frames)
row 10 dashing forward with a magnetic motion blur trail behind the robot (3 frames)

Every frame the same size, character centered, feet on the same baseline. Solid flat magenta background (#FF00FF) behind everything, no shadows on the background, no text, no labels, no grid lines, no watermark.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 768x1280 pixels in total, which is four times the size it will have in the game (192x320, frames of 32x32). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="spr-sr3"></a>
### SPR-SR3 — Aranha de Reparo SR-3

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/enemies/sr3_sheet.png` |
| Contrato | Frames **32×16**; `walk` 4f · `shutdown` 3f (desligando) · `off` 1f |
| Placeholder | Oval laranja 24×12 com 6 "pernas" |
| Placeholder gerado | `assets/placeholder/sprites/enemies/sr3_sheet.png` (128×48 = 4×3 frames de 32×16) — `tools/make_placeholders.gd` |
| Status | **integrado** — 2ª geração (2026-09-20), fatiada de `aranha2.png` (2048×768) com `tools/autoslice_sheet.gd --frame-width=32 --frame-height=16 --columns=4 --fit=contain` |

**Prompt:**
```
Pixel art sprite sheet of a small six-legged repair spider robot called SR-3, side view facing right, for a 2D sci-fi platformer. Flat oval metal body the size of a toolbox, six thin articulated legs, a single small amber warning light on top, welding tool tip in front. Not evil, just an old machine following orders.

Style: 16-bit pixel art, crisp hard pixels, no anti-aliasing, no gradients, no soft shading, 12-color palette (dark steel, amber, rust, a little teal). Chunky readable shapes only: no fine rust speckles, no tiny panel lines, no thin 1-pixel details — everything must still read when the frame is only 32x16 pixels.

Layout: a grid of 32x16 pixel frames, 4 columns and 3 rows: row 1 scuttling walk cycle (4 frames), row 2 shutting down with light fading and legs folding (3 frames), row 3 fully off, folded, light dark (1 frame).

CRITICAL SIZE: draw the whole sheet SMALL. The entire image must be at most 512x192 pixels, so each frame is close to its native 32x16 and the pixels stay hard. Do NOT deliver a large upscaled image.

CRITICAL PROPORTION: every frame is exactly TWICE as wide as it is tall (2:1). The complete robot — including the front welding tip with its spark AND the rearmost leg — must fit INSIDE that 2:1 box with one pixel of margin on the left and on the right. Nothing may touch or cross the left or right edge of a frame.

Same baseline in every frame. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.
```

<a id="spr-spore"></a>
### SPR-SPORE — Enxame de Esporos

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/fx/spore.png` |
| Contrato | Partícula **8×8** (4 variações lado a lado, 32×8) usada em `GPUParticles2D` + área de colisão invisível |
| Placeholder | Círculos verde-rosados semitransparentes |
| Fonte | **Kenney Particle Pack 1.1 (CC0)** — https://kenney.nl/assets/particle-pack. Quadros `dirt_02` · `dirt_01` · `smoke_01` · `circle_05`. **O quadro 3 não é esporo**: é a mota pálida do ambiente, deixada quase branca de propósito para receber o tint da fase. Os outros três são tingidos em `#B7D35A` com pico de alfa 185, porque 24 partículas sobrepostas em alfa cheio viram mancha sólida |
| Placeholder gerado | `assets/placeholder/sprites/fx/spore.png` (32×8 = 4 frames de 8×8) — `tools/make_placeholders.gd` |
| Status | placeholder |

<a id="spr-terminal"></a>
### SPR-TERMINAL — Terminais

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/terminal_sheet.png` |
| Contrato | Frames **32×32**: terminal de distribuição `off`, `on`, `active` (3f) + terminal de log `off`, `on` (2f) |
| Placeholder | Caixa 24×28 cinza com tela verde |
| Placeholder gerado | `assets/placeholder/sprites/world/terminal_sheet.png` (160×32 = 5 frames de 32×32) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art sprite sheet of two sci-fi wall-mounted terminals for a 2D side-view space station platformer, each drawn as a standalone unit with no wall around it. Terminal A: "power distribution terminal", a chunky console with a screen showing bars and a big breaker lever, three states: unpowered (dark screen), powered (cyan screen glow), active (screen bright with yellow bars). Terminal B: small log terminal with a tiny screen, two states: off and on (soft green text lines). Style: 16-bit pixel art, hard pixels, no anti-aliasing, cold blue-grey metal with cyan and green light accents. Layout: one row of 32x32 pixel frames, 5 frames total in this order: A-unpowered, A-powered, A-active, B-off, B-on. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 640x128 pixels in total, which is four times the size it will have in the game (160x32, frames of 32x32). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="spr-dock"></a>
### SPR-DOCK — Doca de recarga (Ponto de Backup)

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/dock_sheet.png` |
| Contrato | Frames **32×48**: `idle` 1f · `charging` 4f (luz pulsando) |
| Placeholder | Moldura 28×44 com faixa ciana |
| Placeholder gerado | `assets/placeholder/sprites/world/dock_sheet.png` (160×48 = 5 frames de 32×48) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art sprite sheet of a robot recharging dock for a 2D side-view space station platformer: a tall standalone alcove unit with a metal floor plate, two clamps on the sides and a power cable, where a small maintenance robot parks to recharge and back up its memory. Style: 16-bit pixel art, hard pixels, no anti-aliasing, cold steel with cyan energy light. Layout: one row of 32x48 pixel frames, 5 frames: frame 1 idle with dim light, frames 2-5 charging with a cyan light pulse travelling up the alcove. Solid flat magenta background (#FF00FF), no robot inside, no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 640x192 pixels in total, which is four times the size it will have in the game (160x48, frames of 32x48). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="spr-door"></a>
### SPR-DOOR — Porta de energia

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/door_sheet.png` |
| Contrato | Folha **192×48 = 6 quadros de 32×48**: `closed` 1f · `opening` 3f · `open` 1f · **`portal` 1f** (o quadro 5, usado pela saída de fase). `sealed` reusa o quadro 0 tingido de vermelho. **A colisão continua 16×48**; a porta mede o vão até o teto e completa com antepara sólida |
| Placeholder | Barra 16×48 cinza com faixa amarela |
| Fonte grátis alternativa | Kenney "Pixel Platformer Industrial Expansion" (CC0) — https://kenney.nl/assets/pixel-platformer-industrial-expansion |
| Placeholder gerado | `assets/placeholder/sprites/world/door_sheet.png` (112×48 = 7 frames de 16×48) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art sprite sheet of a vertical two-leaf bulkhead door for a 2D side-view space station platformer, seen flat from the side.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the station tileset and the MU-7 robot): same worn, lived-in 16-bit look — cold teal-blue steel (#1B2B34 shadow, #2F4F5A body) with a lighter bevel catching light on every top edge, visible bolt heads, rust-orange streaks bleeding down from the bolts, grime settled in the recesses, scratched paint. Cyan (#5FD4C8) only for status light and glass, amber (#E0B43C) only for hazard stripes. Hard pixels, no anti-aliasing, no soft gradients, no airbrush. MEDIUM brightness overall: the game darkens the scene and lights it at runtime, so do NOT bake strong shadows or a dark vignette into the sprite.

It must read as a DOOR, not as a machine: a heavy FIXED steel frame — two side jambs, a header beam and a floor threshold — that never moves, and two sliding leaves inside it that meet in the middle, each leaf carrying a round porthole with dark navy glass. Amber and black hazard stripes on the leading edge of each leaf, under the header and on the threshold. A small status light on the header and a small control panel on the right jamb.

Layout: ONE ROW of 6 frames, each 32 wide by 48 tall.
Frame 1 — closed, red status light, both portholes visible.
Frames 2, 3, 4 — opening: the upper leaf retracting UP into the header, the lower leaf retracting DOWN into the threshold, the portholes disappearing into the frame, amber status light.
Frame 5 — fully open: ONLY the empty frame remains. The doorway opening must be FLAT MAGENTA (#FF00FF), because that becomes transparent in the game and the room behind shows through. Thin amber hazard lip under the header and above the threshold, green status light.
Frame 6 — A DIFFERENT OBJECT, a SECTOR PORTAL: the same doorway but with a heavier frame and corner brackets, a small lit identification plate on the header, NO hazard stripes at all, and the opening filled with a receding lit tunnel in green glowing from deep inside, light spilling down onto the threshold.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the door. Never draw walls, floors, ground, ceilings, rooms, scenery, characters or cast shadows, not even when the description implies one. The door floats on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 768x192 pixels in total, which is four times its size in the game (192x48, frames of 32x48). Art drawn large and shrunk down turns to mush; art drawn small stays sharp. Do NOT deliver a big image.

FRAME MARGIN: leave one empty pixel inside every frame on the left, the right and the top. The threshold sits on the bottom edge. Nothing may cross into a neighbouring frame.

No text, no letters, no labels, no grid lines, no watermark.
```

> **Anexe duas imagens de referência ao gerar:** o tileset do Núcleo (`tileset.png`) e a folha do MU-7 (`robo novo.png`). É o que faz a porta compartilhar desgaste, paleta e peso com o resto — sem anexo, a IA devolve metal limpo de catálogo.

<a id="spr-pickups"></a>
### SPR-PICKUPS — Coletáveis

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/pickups/pickups_sheet.png` |
| Contrato | Frames **16×16**, 1 linha por item, 4f de brilho cada: Célula de Energia · Kit de Solda · Fragmento de Log · Dado de Pesquisa · Núcleo de Capacitor |
| Placeholder | Silhuetas distintas (F37): pilha azul · maleta vermelha com cruz · documento verde com linhas · gema hexagonal dourada · anel/bobina roxo |
| **Regra de silhueta** | A arte definitiva **tem de manter uma silhueta diferente por tipo**, legível em 16×16 sob luz escura. Cor sozinha não basta: os losangos coloridos antigos fizeram o jogador perguntar "oq são essas coisas azuis no chao e as laranjas". O ícone do contador no HUD repete a mesma silhueta do item — se a silhueta mudar aqui, `UI-HUD` muda junto |
| **Par frágil** | Célula de Energia e Núcleo de Capacitor dividem o mesmo retângulo externo (8×14, cilindro vertical com tampas) e se separam por textura interna e cor. Se o jogador voltar a confundir, o capacitor deve virar **bobina horizontal deitada, mais larga que alta**, para não dividir a silhueta |
| Placeholder gerado | `assets/placeholder/sprites/pickups/pickups_sheet.png` (64×80 = 4×5 frames de 16×16) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art sprite sheet of five small collectible items for a 2D sci-fi platformer, each 16x16 pixels, with a 4-frame idle glow/bob animation: row 1 "energy cell" (small blue battery canister with glowing core), row 2 "welding repair kit" (compact red and grey tool case with a cross), row 3 "log fragment" (tiny green data chip with a blinking light), row 4 "research data" (golden hexagonal data crystal), row 5 "capacitor core" (purple glowing cylinder with coils, looks rare and valuable). Style: 16-bit pixel art, hard pixels, no anti-aliasing, readable silhouettes, dark outline. Layout: grid of 16x16 frames, 4 columns and 5 rows. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 256x320 pixels in total, which is four times the size it will have in the game (64x80, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="spr-platform"></a>
### SPR-PLATFORM — Plataforma móvel

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/moving_platform.png` |
| Contrato | **48×8**, 1 frame. Montado sem reamostragem a partir de três tiles de 18×18 da Kenney: cap esquerdo + miolo + cap direito, mantendo só as 4 linhas de cima e as 4 de baixo |
| Fonte | **Kenney — "Pixel Platformer: Industrial Expansion" v1.0 (29-10-2022), CC0.** Peças `Tiles/tile_0100.png`, `tile_0101.png` e `tile_0102.png` (tiles de 18×18 nesse pacote, não 16×16) |
| Placeholder gerado | `assets/placeholder/sprites/world/moving_platform.png` (48×8) — `tools/make_placeholders.gd` |
| Status | placeholder |

<a id="spr-plant"></a>
### SPR-PLANT — Planta que cresce

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/grow_plant_sheet.png` |
| Contrato | Frames **64×64**, 6 quadros: `seedling` 1f · `growing` 4f · `grown` 1f. A copa adulta é mais larga que o vaso, por isso o quadro dobrou de largura; o **topo pisável continua com 32 px** no meio da copa |
| Placeholder | Retângulo verde que cresce de 8 para 64 px |
| Placeholder gerado | `assets/placeholder/sprites/world/grow_plant_sheet.png` (192×64 = 6 frames de 32×64) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art sprite sheet of an alien crop plant in a hydroponic planter, for a 2D side-view space greenhouse platformer. The plant grows fast under a grow lamp: from a small sprout to a tall sturdy stalk whose wide flat top leaves form a platform a small robot can stand on. Moss green leaves with pink flowers, slightly bioluminescent. Style: 16-bit pixel art, hard pixels, no anti-aliasing. Layout: one row of 32x64 pixel frames, 6 frames: sprout, 4 growth stages, fully grown with flat leafy top. Planter pot at the bottom in every frame at the same position. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 768x256 pixels in total, which is four times the size it will have in the game (192x64, frames of 32x64). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="spr-props"></a>
### SPR-PROPS — Objetos do cotidiano interrompido

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/props/props_sheet.png` |
| Contrato | Frames **32×32**: caneca flutuando · cadeira virada · foto no armário · traje espacial caído (o "primeiro corpo" — sem sangue, só o traje vazio/de costas) · vaso quebrado · tablet apagado |
| Placeholder | Quadrados com inicial |
| Placeholder gerado | `assets/placeholder/sprites/props/props_sheet.png` (192×32 = 6 frames de 32×32) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art sprite sheet of six abandoned everyday objects for a melancholic 2D side-view space station game, "a beautiful station nobody is using": 1 a coffee mug floating slightly tilted, 2 an overturned office chair, 3 a family photo taped to a metal locker, 4 a crew member's empty spacesuit slumped as if leaning back, seen from behind, helmet down, no gore, no body visible, and no wall drawn, 5 a cracked plant pot with dry soil, 6 a turned-off tablet lying flat, with no floor drawn. Style: 16-bit pixel art, hard pixels, no anti-aliasing, muted cold palette with small warm accents. Layout: one row of 32x32 pixel frames, 6 frames. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 768x128 pixels in total, which is four times the size it will have in the game (192x32, frames of 32x32). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="spr-botanico"></a>
### SPR-BOTANICO — Drone BOTÂNICO 04

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/npc/botanico_sheet.png` |
| Contrato | Frames **16×16**: `hover` 4f · `spray` 2f |
| Placeholder gerado | `assets/placeholder/sprites/npc/botanico_sheet.png` (96×16 = 6 frames de 16×16) — `tools/make_placeholders.gd` |
| Uso no jogo | `scenes/npc/botanico.gd` (F34): `hover` = colunas 0–3 a 8 fps, `spray` = colunas 4–5 a 6 fps; o sprite olha para a direita e vira com `flip_h`. Luz própria `#ffd98a` (`Balance.DRONE_LIGHT_RADIUS`) com a textura de FX-LIGHT |
| Status | **integrado** (folha definitiva da leva F51/F52, em jogo desde a F34 em 2026-11-21) |

**Prompt:**
```
Pixel art sprite sheet of a tiny cute irrigation drone called BOTANICO 04 for a 2D space greenhouse game: round white-green body with a small propeller on top, a watering nozzle underneath and a warm yellow lamp in front. Style: 16-bit pixel art, hard pixels, no anti-aliasing. Layout: one row of 16x16 pixel frames, 6 frames: 4 frames hovering bob, 2 frames spraying water mist. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 384x64 pixels in total, which is four times the size it will have in the game (96x16, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="spr-cx2"></a>
### SPR-CX2 — Torre Calibradora CX-2

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/enemies/cx2_sheet.png` |
| Contrato | Folha **128×64 = 4 col × 2 lin de 32×32**, fundo transparente. Linha 0: `scan` 4f (cabeça varre da esquerda para a direita, lente **ciano**). Linha 1: `lock` 2f (lente vermelha, a 2ª mais clara), `fire` 1f (lente branca e clarão vermelho que sai pelo pé do quadro), `off` 1f (braço caído, lente apagada). **Montada no teto**: a placa de fixação encosta no topo do quadro (y = 0) e o centro da placa fica em x = 16 em todos os quadros (pivô do código). Em parede o código gira o nó 90° |
| Silhueta | Placa larga no teto + braço curto com um cotovelo + cabeça de scanner creme com **lente redonda grande**. Não se confunde com SR-3 (aranha de chão), doca, terminal nem lâmpada |
| Placeholder | Placa cinza com marcas laranja, haste, cabeça creme com lente ciano/vermelha/apagada; `fire` com clarão em losango |
| Placeholder gerado | `assets/placeholder/sprites/enemies/cx2_sheet.png` (128×64) — `tools/make_placeholders.gd`, forma `ceiling_turret` |
| Fonte | **IA — geração de imagem do Codex CLI** (`tools/gen_image.sh`), 2026-10-27, 2 variações, escolhida a **1ª**: lente maior e silhueta mais limpa a 32 px; a 2ª tinha braço e cabeça mais embolados e virava mancha creme. Referências de estilo: `assets/sprites/mu7/mu7_sheet.png` e `assets/sprites/world/door_sheet.png`. Bruto 1774×887, grade 4×2 detectada exata; fatiada com alinhamento **pelo topo** (o `autoslice_sheet.gd` alinha pelo pé, o que soltaria a torre do teto), escala única tirada dos quadros sem o clarão (o feixe do `fire` é cortado no pé do quadro). Chave por magentice + *unmix*: 0 px semitransparentes, 0 px de franja magenta |
| Status | **integrado (IA)** em 2026-10-27 |

**Prompt (Codex, com as duas referências anexadas):**
```
Pixel art sprite sheet of a CEILING-MOUNTED CALIBRATION TURRET called CX-2, for a 2D side-view sci-fi platformer set in an abandoned space station laboratory. Side view.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the MU-7 robot and the station door): same worn, lived-in 16-bit look, hard pixels, dark 1-pixel outline, visible bolts, scratched paint, grime in the recesses. MEDIUM brightness overall: the game darkens the scene and lights it at runtime, so do NOT bake strong shadows or glow halos into the sprite.

THE MACHINE (same design in every frame): it HANGS FROM THE CEILING, upside down like a security camera.
- At the TOP: a wide flat mounting plate bolted to the ceiling (dark cold steel #4A5058), with two small orange heat-warning marks (#E07A3A).
- Below the plate: a SHORT, THICK articulated arm with ONE visible elbow joint (cold steel), pointing downward.
- At the BOTTOM of the arm: a chunky boxy SCANNER HEAD in off-white lab casing (#C9C4B5 body, #8C8778 shading) with ONE BIG ROUND LENS on its underside/front that takes up almost half of the head. The lens is the most visible part of the machine.
It must NOT look like a spider, a walking robot, a lamp, a terminal or a door: it is a hanging arm with a camera-like head and a huge lens.

Layout: a grid of SQUARE frames, 4 columns and 2 rows, the same size each, every frame showing the WHOLE turret with the mounting plate touching the TOP of its frame.
Row 1 — "scan", 4 frames: the head slowly sweeps from pointing down-left to pointing down-right; the lens is BRIGHT CYAN (#7FD6E8) with a small white highlight.
Row 2 — frame 1 "lock A": head aimed straight down, lens RED (#E0383A). Frame 2 "lock B": same pose, lens BRIGHTER RED-ORANGE (#FF6A5A), charging. Frame 3 "fire": same pose, lens WHITE-HOT with a short thick red beam flash right under the lens. Frame 4 "off": the arm sags, the head droops lower and tilted, the lens DARK GREY and dead, no light at all.

Chunky readable shapes only: no thin 1-pixel antennas, no tiny panel lines, no speckle — everything must still read when each frame is shrunk to 32x32 pixels. The turret should fill about 60% of the frame width and 75% of the frame height.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the turret. Never draw the ceiling, walls, floors, rooms, scenery, characters, targets or cast shadows, not even though the turret is mounted on a ceiling. The mounting plate floats on the flat magenta background.

Solid flat magenta background (#FF00FF) everywhere else, with clear magenta gaps between frames. No text, no letters, no labels, no numbers, no grid lines, no frame borders, no watermark.
```

<a id="spr-steam"></a>
### SPR-STEAM — Bocal do jato de vapor

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/steam_vent.png` |
| Contrato | **16×16, 1 quadro**, fundo transparente. Bocal de chão atarracado (16×8) apoiado na borda de baixo do quadro: grade de 4 fendas escuras no topo, aro **laranja-calor**, corpo de aço. O jato é partícula, não sprite |
| Placeholder | Caixa cinza 14×7 com faixa laranja e fendas |
| Placeholder gerado | `assets/placeholder/sprites/world/steam_vent.png` (16×16) — `tools/make_placeholders.gd`, forma `steam_vent` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-10-27, 2 imagens com 2 desenhos cada (4 candidatos), escolhido o **1º desenho da 2ª imagem**: 4 fendas grossas continuam separadas a 16 px; os de 6 fendas viravam uma faixa cinza. Referências: `door_sheet.png` e `core_tiles.png`. Reduzido para 16×8 e encostado no pé do quadro; 0 px semitransparentes, 0 px de franja |
| Status | **integrado (IA)** em 2026-10-27 |

**Prompt (Codex):**
```
Pixel art game object for a 2D side-view space station platformer: a FLOOR STEAM VENT nozzle, seen from the side, sitting on the ground.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES: same worn 16-bit station look, hard pixels, dark 1-pixel outline, bolts, scratched paint, no anti-aliasing. MEDIUM brightness, no baked glow.

The object: a short, wide, squat metal nozzle housing (cold steel #5E646B, #3A3F45 shading), wider than tall, with a heavy GRATE of thick dark slots on its top where the steam comes out, bolted feet on both sides, and an ORANGE heat-warning rim (#E07A3A) around the top edge. Chunky readable shapes only: it must still read when shrunk to 16x16 pixels, so no thin details. Do NOT draw any steam, smoke, jet or particles: only the dry metal nozzle.

Layout: TWO different design variations of this nozzle, side by side, in two SQUARE frames of the same size (2 columns x 1 row), each nozzle sitting on the bottom edge of its frame and occupying the full frame width and about half of its height.

IMPORTANT RULE: draw ONLY the nozzle. Never draw the floor, walls, pipes, scenery or shadows. The nozzle floats on the flat magenta background.

Solid flat magenta background (#FF00FF) everywhere else. No text, no letters, no labels, no grid lines, no watermark.
```

<a id="spr-v9"></a>
### SPR-V9 — Sentinela Voadora V-9

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/enemies/v9_sheet.png` |
| Contrato | Folha **128×64 = 4 col × 2 lin de 32×32**, fundo transparente. Linha 0: `patrol` 4f (paira; os jatos dos propulsores alternam curto/longo; lente **ciano**). Linha 1: `alert` 1f (lente **âmbar**), `chase` 1f (inclinada para a frente, lente vermelha, jatos para trás), `latch` 1f (garras abertas para baixo e para a frente), `off` 1f (tombada de lado, lente apagada, sem jato). **Voadora**: centrada pelo **corpo**, não pelo pé — o centro do corpo oval fica em (16, ~15) em todos os quadros, e jatos e garras sobram para baixo. Olha para a **direita** (o código espelha) |
| Silhueta | Ovo deitado branco-sujo com **faixa âmbar de quarentena** listrada, **uma lente grande** na frente, dois propulsores com jato ciano embaixo e um par de garras no meio. Sem hélice, sem antena, sem pernas, **sem cruz vermelha** (emblema protegido). Não se confunde com SR-3 (aranha laranja de chão), CX-2 (torre creme pendurada no teto) nem BOTÂNICO 04 (bolinha verde de 16 px com hélice) |
| Placeholder | Oval claro com faixa âmbar, lente ciano/âmbar/vermelha/apagada, propulsores e garras |
| Placeholder gerado | `assets/placeholder/sprites/enemies/v9_sheet.png` (128×64) — `tools/make_placeholders.gd`, forma `flying_sentinel` |
| Fonte | **IA — geração de imagem do Codex CLI** (`tools/gen_image.sh`), 2026-10-27, 2 variações (as duas em grade 4×2 exata), escolhida a **2ª**: corpo maior e de sombreado limpo a 32 px (escala 0,080 contra 0,071), lente e garras abertas legíveis. A 1ª tinha o balanço de pairar desenhado, mas o corpo cheio de rebites e sujeira virava chuvisco branco a 32 px; o balanço fica com o código. Referências de estilo: `mu7_sheet.png` e `cx2_sheet.png` (ampliadas ×6 sobre magenta). Bruto 1774×887 |
| Montagem | Fatiada por **células da grade** (1774/4 × 887/2), não pelo `autoslice_sheet.gd` (que alinha pelo pé): centro do corpo = linhas em que a largura opaca passa de 50 % da máxima (o oval; jatos e garras são estreitos), média dos 4 quadros de patrulha; a linha 2 desce 31 px brutos para o `alert` casar com a patrulha; janela quadrada única que cabe todos os quadros com 1 px de folga. Chave por magentice + *unmix*: 0 px semitransparentes, 0 px de franja magenta |
| Status | **integrado (IA)** em 2026-10-27 |

**Prompt (Codex, com as duas referências anexadas):**
```
Pixel art sprite sheet of a FLYING MEDICAL SENTINEL DRONE called V-9, for a 2D side-view sci-fi platformer set in the frozen, abandoned infirmary of a space station. Side view, the drone faces RIGHT.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the MU-7 robot and the CX-2 turret): same worn, lived-in 16-bit look, hard pixels, dark 1-pixel outline, visible bolts, scratched paint, a little frost on the top edges. MEDIUM brightness overall: the game darkens the scene and lights it at runtime, so do NOT bake strong shadows or glow halos into the sprite.

THE MACHINE (same design in every frame): it FLOATS IN THE AIR, it has no legs and never touches the ground.
- A chunky HORIZONTAL OVAL body like an egg lying on its side, in cold white medical casing (#D8E6EC body, #9FB4C0 shading, #4A5A66 cold steel seams), with ONE thick AMBER QUARANTINE STRIPE (#E8B04A with dark #3A2A10 diagonal hatching) wrapped vertically around the middle of the body.
- On the FRONT (right side) of the body: ONE BIG ROUND LENS that takes up almost half of the body height. The lens is the most visible part of the machine.
- Under each end of the body: a short stubby THRUSTER POD pointing DOWN, with a small pale cyan jet flame (#9FE3F0) under it.
- Under the middle of the body: a pair of short folded GRABBER CLAWS (cold steel).
NO propeller on top, NO rotor blades, NO antenna, NO legs. NO red cross and NO cross symbol of any kind anywhere. It must NOT look like a spider, a ceiling turret, a walking robot, a lamp or a small round garden drone: it is a white flying egg with a huge lens, an amber stripe and two thrusters.

Layout: a grid of SQUARE frames, 4 columns and 2 rows, the same size each, every frame showing the WHOLE drone centered in its frame.
Row 1 — "patrol", 4 frames: the drone hovers, bobbing gently up and down by a few pixels; the thruster jets flicker (short, long, short, long); the lens is BRIGHT PALE CYAN (#7FD6E8) with a small white highlight.
Row 2 — frame 1 "alert": level pose, lens AMBER (#E8B04A), the claws still folded. Frame 2 "chase": the whole body TILTED FORWARD (nose down toward the right) about 20 degrees, lens RED (#E0383A), thruster jets long and angled backward. Frame 3 "latch": level pose, lens RED, the two grabber claws OPEN WIDE and reaching DOWN and FORWARD, big and clearly visible. Frame 4 "off": the drone is DEAD, tipped over on its side about 70 degrees, lens DARK GREY with no light, claws limp, NO thruster flame at all.

Chunky readable shapes only: no thin 1-pixel details, no tiny panel lines, no speckle — everything must still read when each frame is shrunk to 32x32 pixels. The drone (without its jets) should fill about 70% of the frame width and 50% of the frame height.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the drone. Never draw floors, walls, ceilings, rooms, scenery, characters, targets or cast shadows. The drone floats on the flat magenta background.

Solid flat magenta background (#FF00FF) everywhere else, with clear magenta gaps between frames. No text, no letters, no labels, no numbers, no grid lines, no frame borders, no watermark.
```

<a id="spr-ice"></a>
### SPR-ICE — Gelo fino e parede de gelo

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/ice_sheet.png` |
| Contrato | Folha **64×32 = 4 col × 2 lin de 16×16**, fundo transparente, **todo pixel opaco ou vazio** (nada de alfa parcial). Linha 0, **gelo fino** (plataforma de 1 tile, pontes são sequências): `intact`, `cracked`, `breaking`, (vazio) — laje de ~6 px **colada no topo do quadro e de borda a borda**, com pingentes embaixo até ~y 11. Linha 1, **parede de gelo** (bloco de 1 tile que empilha): `solid` (16×16 cheio), `melting_a` (menor, cantos de cima abertos, escorrendo), `melting_b` (montinho de ~1/3 da altura no pé do quadro), (vazio) |
| Silhueta | Gelo fino = laje branco-azulada com **pingentes**: não se confunde com a passarela one-way do tileset (faixa de aço lisa de 5 px, sem pingente). Parede de gelo = bloco azul-escuro cheio com fraturas claras |
| Placeholder | Laje azul com pingentes / bloco azul com brilho, nas mesmas posições |
| Placeholder gerado | `assets/placeholder/sprites/world/ice_sheet.png` (64×32) — `tools/make_placeholders.gd`, forma `ice` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-10-27, 2 variações (as duas 4×2 com as células vazias certas), escolhida a **1ª**: laje grossa e reta que lê como chão, 3 pingentes curtos; a 2ª tinha pingentes compridos que, a 16 px, viravam franja e escondiam a laje, e uma poça ciano saturada no `melting_b`. Referência: `lab_tiles.png` ×6 |
| Montagem | Células tiradas da grade (passo entre caixas detectadas): linha 0 ancorada no topo da laje, linha 1 no pé do bloco. Linha 0 esticada **×1,6 na vertical** (laje de 3 px viraria uma risca; ficou com ~6) e com as rachaduras finas preservadas (pixel bruto quase branco que cobre ≥10 % da célula reduzida vira `#EEF8FC`), senão `cracked` saía igual a `intact`. 0 px semitransparentes, 0 px de franja |
| Status | **integrado (IA)** em 2026-10-27 |

**Prompt (Codex):**
```
Pixel art sprite sheet of ICE pieces for a 2D side-view space station platformer set in a frozen infirmary. Side view.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the existing station tiles): same 16-bit look, hard pixels, dark 1-pixel outline, no anti-aliasing, no soft gradients, NO transparency and NO glow: every pixel fully opaque. Ice is drawn with solid opaque colors: deep blue (#3E6E95), mid blue (#6FA8CF), pale cyan (#A9DCEC), white highlights (#EEF8FC), dark outline (#0C1E2C).

Layout: a grid of SQUARE frames, 4 columns and 2 rows, all the same size, separated by flat magenta gaps.
Row 1 — "THIN ICE" platform, a slab of ice that the player can stand on for a moment before it breaks:
 Frame 1 "intact": a flat horizontal slab of pale blue ice spanning the FULL WIDTH of the frame, edge to edge, only about one third of the frame tall, sitting at the TOP of the frame, with white highlights on its top surface and 3 short chunky ICICLES hanging under it. The rest of the frame below is magenta.
 Frame 2 "cracked": the same slab with bold white zig-zag cracks across it.
 Frame 3 "breaking": the same slab split into 3 separate chunks with magenta gaps between them, the chunks starting to drop and tilt.
 Frame 4: EMPTY, only magenta.
Row 2 — "ICE WALL", a solid block of thick ice that blocks a corridor and stacks vertically:
 Frame 1 "solid": a block of thick deep-blue ice filling the WHOLE square edge to edge, with a few pale internal fracture lines and white highlight streaks; the top and bottom must line up seamlessly when blocks are stacked.
 Frame 2 "melting A": the same block slightly smaller, edges rounded and wet, drips running down, a few magenta gaps at the top corners.
 Frame 3 "melting B": only a low lump of ice at the bottom of the frame, about one third of its height, with a small puddle.
 Frame 4: EMPTY, only magenta.

Chunky readable shapes only: everything must still read when each frame is shrunk to 16x16 pixels. Thin ice must look clearly different from a steel catwalk: blue, glassy, with icicles.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the ice. Never draw walls, floors, scenery, characters or cast shadows.

Solid flat magenta background (#FF00FF) everywhere else. No text, no letters, no labels, no numbers, no grid lines, no frame borders, no watermark.
```

<a id="spr-props-inf"></a>
### SPR-PROPS-INF — Objetos da Enfermaria

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/props/infirmary_props_sheet.png` (carregado pelo `o` com `"sheet"` + `"frame"`) |
| Contrato | Folha **128×64 = 4 col × 2 lin de 32×32**, fundo transparente, cada objeto **apoiado no pé do quadro** (última linha) e centrado. Quadros: 0 leito arrumado · 1 leito vazio com lençol dobrado · 2 maca · 3 suporte de soro · 4 cápsula criogênica · 5 carrinho de medicação · 6 cadeira de rodas · 7 armário de prontuários. Leitos 0 e 1 diferem pelo lençol (ciano esticado × colchão cinza com o lençol dobrado nos pés): é o que conta a ordem em que a tripulação adoeceu |
| Placeholder | Silhuetas retangulares de cada objeto, apoiadas no pé |
| Placeholder gerado | `assets/placeholder/sprites/props/infirmary_props_sheet.png` (128×64) — `tools/make_placeholders.gd`, forma `infirmary_props` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-10-27, 2 variações (as duas com os 8 objetos na ordem), escolhida a **1ª**: lençol ciano × colchão cinza bem separados a 32 px e gaveta aberta com pastas legível; na 2ª o lençol dobrado era quase branco e sumia no colchão. Referências: `mu7_sheet.png` e `props_sheet.png` ×6. **Sem cruz vermelha** |
| Montagem | Escala comum tirada da altura (o objeto mais alto ocupa 31 px), limitada pela largura de 31 px nos compridos (leitos e maca quase na mesma escala; a cápsula fica menor, 31×13). Alinhados pelo pé, centrados. 0 px semitransparentes, 0 px de franja |
| Status | **integrado (IA)** em 2026-10-27 |

**Prompt (Codex):**
```
Pixel art sprite sheet of EIGHT abandoned infirmary objects for a melancholic 2D side-view space station game, "a beautiful station nobody is using", in the frozen infirmary where the crew fell ill one by one. Side view.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the MU-7 robot and the station objects): same worn 16-bit look, hard pixels, dark 1-pixel outline, scratched paint, a thin layer of white frost on top surfaces. MEDIUM brightness, no baked glow, no cast shadows.

Palette: cold white medical casing (#D8E6EC, #9FB4C0 shading), cold blue steel (#5B6E7C, #34434F), pale cyan sheets and glass (#9FE3F0, #6FA8CF), white frost (#EEF6F8), a few amber quarantine marks (#E8B04A), dark blue outline (#0C141B). NO red cross and NO cross symbol of any kind on any object.

Layout: a grid of SQUARE frames, 4 columns and 2 rows, the same size each, every object STANDING ON THE BOTTOM EDGE of its own frame, centered horizontally.
Row 1:
 1. a hospital BED, made: low steel frame on short legs, mattress with a smooth pale cyan sheet tucked in and a white pillow at the left end, the bed is long and low.
 2. the same hospital BED, EMPTY: bare grey mattress, the sheet FOLDED in a neat square stack at the foot, pillow gone.
 3. a wheeled STRETCHER (gurney): thin flat padded top on an X-shaped steel scissor frame with four small wheels.
 4. an IV STAND: a tall steel pole on a wheeled star base, with a hanging pale cyan fluid bag at the top; make the pole thick enough to read.
Row 2:
 5. a CRYOGENIC POD: a long horizontal capsule on a short pedestal, white casing, a big frosted pale cyan glass window on top, an amber warning stripe, heavily frosted.
 6. a MEDICATION CART: a squat steel cart on four wheels with three drawers and amber handles, a few small bottles on top.
 7. a WHEELCHAIR seen from the side: one big wheel, one small front wheel, seat and backrest, empty.
 8. a tall FILE CABINET for medical records: steel cabinet with three drawers, the top drawer half open with paper folders sticking out.

Chunky readable shapes only: no thin 1-pixel details — everything must still read when each frame is shrunk to 32x32 pixels. Keep the relative sizes realistic: the beds, stretcher and pod are wide and low, the IV stand and file cabinet are tall and narrow.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, bodies, cast shadows or any other object. Each object floats on the flat magenta background, resting on the bottom edge of its frame.

Solid flat magenta background (#FF00FF) everywhere else, with clear magenta gaps between frames. No text, no letters, no labels, no numbers, no grid lines, no frame borders, no watermark.
```

<a id="spr-cmd"></a>
### SPR-CMD — Sala de comando (máquinas e consoles da escolha)

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/command_machines_sheet.png` (lido por `EndingMachine` e `EndingConsole`, F66) |
| Contrato | Folha **256×128 = 4 col × 2 lin de 64×64**, fundo transparente, cada máquina **apoiada no pé do quadro** e centrada. Linha 0: (0) baia da cápsula parada · (1) baia armada (luzes verdes) · (2) transmissor parado · (3) transmissor carregando (anéis e ponta ciano). Linha 1: (0) console SEMEADURA com a alavanca em cima · (1) alavanca puxada, tela verde · (2) console TRANSMISSÃO com a alavanca em cima · (3) alavanca puxada, tela ciano. As duas máquinas têm silhuetas opostas (cápsula bojuda entre garras × mastro fino com prato); os consoles têm a mesma forma e se distinguem pela cor do pomo e da faixa |
| Placeholder gerado | `assets/placeholder/sprites/world/command_machines_sheet.png` (256×128) — `tools/make_placeholders.gd`, forma `rect_index` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-11-21, 2 variações (as duas 4×2 exatas), escolhida a **1ª**: garras da baia e pomos das alavancas mais grossos e legíveis a 64 px; na 2ª o pomo das duas alavancas era cinza e os consoles ficavam iguais. Referências: `mu7_sheet.png`, `door_sheet.png`, `terminal_sheet.png` |
| Montagem | `tools/autoslice_sheet.gd --frame-width=64 --frame-height=64 --columns=4 --fit=contain` (escala 0,13, alinhado pelo pé), depois alfa binarizado (≥ 128 opaco, abaixo transparente): 0 px semitransparentes, 0 px de franja magenta |
| Status | **integrado (IA)** em 2026-11-21 |

**Prompt (Codex):**
```
Pixel art sprite sheet of EIGHT machines for the final room of a melancholic 2D side-view space station game: the station COMMAND ROOM, where the last decision of the game is made. Side view, "a beautiful station nobody is using", silent, dark, almost sacred.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the MU-7 robot, the station door, dock and terminals): same worn 16-bit look, hard pixels, dark 1-pixel outline, scratched paint, grime in recesses. MEDIUM brightness, no baked glow halos, no cast shadows.

Palette: cold blue-grey steel (#5E6E7A, #3A4650, #8CA3B0 highlight), dark outline (#0B1216), off-white casing (#C9D3D8). SEEDING machines use a living GREEN accent (#7BD88F, #3E8E57). TRANSMISSION machines use a signal CYAN accent (#7FE3F0, #3A9FB0). A few amber warning marks (#E0B43C).

Layout: a grid of SQUARE frames, 4 columns and 2 rows, the same size each, every machine STANDING ON THE BOTTOM EDGE of its own frame, centered horizontally, filling most of the frame height.
Row 1:
 1. SEED CAPSULE LAUNCH CRADLE, dormant: a tall rounded seed capsule (like a bullet-shaped pod, white casing with a green band and a small round porthole) standing upright inside an open steel launch cradle with two curved clamp arms and a heavy base with pipes. Accent lights dark.
 2. the SAME seed capsule cradle, ARMED: identical shape, but the green band, the porthole and small lights on the base are lit bright green.
 3. TRANSMITTER ANTENNA, dormant: a tall steel mast on a heavy base with cables, topped by a big round parabolic DISH facing up and to the right, with a pointed feed horn in the center of the dish. Accent lights dark.
 4. the SAME transmitter antenna, CHARGING: identical shape, but the feed horn and rings along the mast are lit bright cyan.
Row 2:
 5. a LEVER CONSOLE for seeding: a waist-high slanted control pedestal with a big heavy lever with a round knob sticking UP out of the top, a green stripe on the front panel, screen dark.
 6. the SAME seeding lever console with the lever PULLED DOWN to the front, the green stripe and a small screen lit green.
 7. a LEVER CONSOLE for transmission: the same pedestal shape and lever UP, but with a cyan stripe on the front panel, screen dark.
 8. the SAME transmission lever console with the lever PULLED DOWN, the cyan stripe and a small screen lit cyan.

Keep the two big machines very different in silhouette: the capsule cradle is a bulky rounded pod held by clamps, the transmitter is a thin mast with a wide dish on top. The consoles are about half the height of the big machines.

Chunky readable shapes only: no thin 1-pixel details. Everything must still read when the sheet is shrunk so each frame is 64x64 pixels.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the machine described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object. Each machine floats on the flat magenta background, resting on the bottom edge of its frame.

Solid flat magenta background (#FF00FF) everywhere else, with clear magenta gaps between frames. No text, no letters, no labels, no numbers, no grid lines, no frame borders, no watermark.
```

<a id="spr-ending"></a>
### SPR-ENDING — Cutscene final (espaço)

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/fx/ending_space_sheet.png` (lido por `EndingCutscene`, F66) |
| Contrato | Folha **256×128 = 4 col × 2 lin de 64×64**, fundo transparente. Linha 0: (0) ARTEMIS por fora, janelas acesas · (1) a mesma, apagada · (2) cápsula de sementes em voo para a direita, com chama · (3) a mesma sem chama. Linha 1: (0) planeta-alvo habitável (oceanos e continentes verdes) · (1) Terra pequena e cansada (continentes marrons) · (2) clarão do transmissor com feixe para a direita · (3) onda do sinal (três arcos ciano). Na cutscene a estação vai a ×2, o planeta-alvo a ×1,5–2 e a Terra a ×0,5 |
| Placeholder gerado | `assets/placeholder/sprites/fx/ending_space_sheet.png` (256×128) — `tools/make_placeholders.gd`, forma `rect_index` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-11-21, 2 variações (as duas 4×2 exatas), escolhida a **2ª**: a diferença entre a ARTEMIS acesa (janelas âmbar) e apagada se lê de longe; na 1ª as duas eram quase iguais. Referências: `mu7_sheet.png` e `space_mid.png` |
| Montagem | `tools/autoslice_sheet.gd` 64×64, 4 colunas, `--fit=contain`; alfa binarizado; 4 pixels magenta do miolo do anel da estação escurecidos. 0 px semitransparentes, 0 px de franja |
| Status | **integrado (IA)** em 2026-11-21 |

**Prompt (Codex):**
```
Pixel art sprite sheet of EIGHT objects seen in deep space, for the final cutscene of a melancholic 2D side-view space station game. Quiet, lonely, beautiful.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the station robot and the space background with the planet): same 16-bit look, hard pixels, dark 1-pixel outline on objects, no anti-aliasing, no soft gradients.

Palette: station steel blue-grey (#5E6E7A, #3A4650, #8CA3B0), off-white panels (#C9D3D8), warm window light (#F0D58A), dark outline (#0B1216), seed capsule green band (#7BD88F), thruster flame (#FFE9A8, #F0A040), habitable planet ocean teal and green land (#2E8C9A, #5FB06A, #E8F0E0 clouds), Earth pale blue with brown dry land and grey clouds (#6F9FC8, #9C7A55, #B8C2C8), transmission signal cyan (#7FE3F0, #E8FBFF).

Layout: a grid of SQUARE frames, 4 columns and 2 rows, the same size each, every object CENTERED in its own frame.
Row 1:
 1. the ARTEMIS SPACE STATION seen from outside, small and far: a central ring hub with four short modules (one with a big glass dome greenhouse, one with a tall mast and a round dish antenna), two solar panel wings, MANY small warm lit windows. Fill most of the frame.
 2. the SAME station with every window DARK and the panels unlit, identical shape and position.
 3. a SEED CAPSULE in flight seen from the side: a white bullet-shaped pod with a green band and a small porthole, pointing RIGHT, with a bright yellow-orange thruster FLAME coming out of its LEFT end. The capsule occupies about half of the frame width.
 4. the SAME seed capsule pointing RIGHT, no flame, a faint cold glint on the porthole.
Row 2:
 5. a HABITABLE PLANET: a round planet filling the frame, teal oceans, green continents, thin white clouds, a soft cyan atmosphere rim on the right side, the left side in shadow.
 6. the EARTH, far away and tired: a smaller round planet (about half the frame), pale blue ocean, large brown dry continents, grey clouds, the left half in shadow.
 7. a TRANSMISSION SIGNAL FLASH: a bright cyan starburst flare with a short straight beam going to the RIGHT, white core.
 8. a SIGNAL WAVE RING: three thin concentric cyan arcs opening to the RIGHT like a radio wave, made of thick pixels.

Chunky readable shapes only: no thin 1-pixel details. Everything must still read when the sheet is shrunk so each frame is 64x64 pixels.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. No stars, no nebula, no background scenery inside the frames.

Solid flat magenta background (#FF00FF) everywhere else, with clear magenta gaps between frames. No text, no letters, no labels, no numbers, no grid lines, no frame borders, no watermark.
```

<a id="til-core"></a>
### TIL-CORE — Tileset Núcleo Central

| Campo | Valor |
|---|---|
| Caminho final | `assets/tiles/core_tiles.png` |
| Contrato | Tiles **16×16**, atlas 8 colunas. Mínimo: chão/parede sólido com 16 variações de borda (bitmask 4-dir), plataforma one-way, fundo de parede (background), janela para o espaço, grade de ventilação, cano, luz de teto, faixa de perigo |
| Fonte grátis | Kenney "Pixel Platformer Industrial Expansion" (CC0) ou "Sci-fi platformer tileset" no itch.io filtrado por CC0 — https://itch.io/game-assets/free/tag-sci-fi/tag-tileset |
| Placeholder | Quadrados azul-esverdeados com borda clara |
| Placeholder gerado | `assets/placeholder/tiles/core_tiles.png` (128×64 = atlas 8×4 de 16×16) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt (se optar por IA):**
```
Pixel art tileset for a 2D side-view platformer set inside a space station control hub, 16x16 pixel tiles arranged on a grid of 8 columns. Include: solid metal floor/wall blocks with all edge and corner variations (top, bottom, left, right, inner and outer corners), a thin one-way metal grating platform, dark background wall panels with rivets and cables, a round window frame with a fully transparent (magenta) center so the parallax background shows through, ventilation grille, horizontal and vertical pipes, a ceiling light, yellow-black hazard stripe. Palette: cold teal-blue and blue-green steel, calm and almost cozy, soft cyan light accents. Style: 16-bit pixel art, hard pixels, no anti-aliasing, tiles must line up seamlessly. Solid flat magenta background (#FF00FF) between tiles, no text, no grid lines.

IMPORTANT RULE: deliver a GRID OF SEPARATE TILES, not a finished picture. Do not draw a room, a level or a composed scene; do not draw characters, creatures or props resting on the tiles; do not bake lighting, glow or cast shadows into the tiles, because the game lights the scene at runtime. Keep the base tiles at MEDIUM brightness — the engine darkens them — and leave flat magenta (#FF00FF) between every tile.

CRITICAL DELIVERY SIZE: draw the whole atlas SMALL — at most 512x256 pixels in total, which is four times the size it will have in the game (128x64, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

NO EMPTY BORDER INSIDE A TILE: the magenta gaps are separators that go BETWEEN tiles, never inside one. Within its own cell each tile must be filled edge to edge with artwork, because the game lays tiles side by side: a tile with empty or magenta pixels along its own border will show a visible seam in the level.
```

<a id="til-greenhouse"></a>
### TIL-GREENHOUSE — Tileset Estufa

| Campo | Valor |
|---|---|
| Caminho final | `assets/tiles/greenhouse_tiles.png` |
| Contrato | Mesmo layout do TIL-CORE (troca estética): terra/metal com musgo, trepadeiras, canteiros hidropônicos, vidro, parede metálica **marcada para garras** (placa com listras magnéticas) |
| Placeholder | Verde-musgo com pontos rosa; parede magnética com listras amarelas |
| Placeholder gerado | `assets/placeholder/tiles/greenhouse_tiles.png` (128×64 = atlas 8×4 de 16×16) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art tileset for a 2D side-view platformer set inside an overgrown space station greenhouse, 16x16 pixel tiles on a grid of 8 columns. Include: solid blocks of metal covered with soil and moss with all edge and corner variations, thin one-way wooden-metal planter platforms, hanging vines, hydroponic trays with alien crops, glass panel frames with fully transparent (magenta) centers so the parallax background shows through, dark background walls with leaves, and a special climbable magnetic wall panel with clear diagonal yellow-grey stripes. Palette: moss green, deep green, pink flowers, rusty metal, the only "alive" and almost beautiful area of the station. Style: 16-bit pixel art, hard pixels, no anti-aliasing, seamless tiles. Solid flat magenta background (#FF00FF) between tiles, no text, no grid lines.

IMPORTANT RULE: deliver a GRID OF SEPARATE TILES, not a finished picture. Do not draw a room, a level or a composed scene; do not draw characters, creatures or props resting on the tiles; do not bake lighting, glow or cast shadows into the tiles, because the game lights the scene at runtime. Keep the base tiles at MEDIUM brightness — the engine darkens them — and leave flat magenta (#FF00FF) between every tile.

CRITICAL DELIVERY SIZE: draw the whole atlas SMALL — at most 512x256 pixels in total, which is four times the size it will have in the game (128x64, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

NO EMPTY BORDER INSIDE A TILE: the magenta gaps are separators that go BETWEEN tiles, never inside one. Within its own cell each tile must be filled edge to edge with artwork, because the game lays tiles side by side: a tile with empty or magenta pixels along its own border will show a visible seam in the level.
```

<a id="til-lab"></a>
### TIL-LAB — Tileset Laboratório

| Campo | Valor |
|---|---|
| Caminho final | `assets/tiles/lab_tiles.png` + `assets/tiles/lab_tileset.tres` |
| Contrato | **Mesmo atlas do TIL-CORE/TIL-GREENHOUSE**: 128×64, 8×4 de 16×16. Linhas 0–1: as 16 máscaras 4-dir (`LevelParser.atlas_coords_for_mask`, bit 1 cima · 2 direita · 4 baixo · 8 esquerda), todas opacas. Linha 2: (0,2) passarela one-way só no topo · (1,2) parede de fundo opaca · (2,2) janela com miolo transparente · (3,2) grade de ventilação · (4,2) cano horizontal · (5,2) cano vertical · (6,2) luminária acesa (quadro 22) · (7,2) faixa de perigo laranja/preta. Linha 3: (0,3) **parede magnética amarela** (`MagneticWall.TILE_COLUMN/ROW`) · (1,3) luminária apagada (quadro 25) · (2..7,3) armário de amostras, monitor, serpentina de refrigeração quebrada, feixe de cabos, manômetro, painel chamuscado. O `.tres` copia o da Estufa (colisão de mundo nas 16 máscaras, one-way em (0,2) na camada 64) |
| Placeholder | Creme `#C9C4B5` com bordas, paleta `lab` do `tools/placeholders.json` |
| Placeholder gerado | `assets/placeholder/tiles/lab_tiles.png` (128×64) — `tools/make_placeholders.gd` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-10-27, 2 variações (as duas em grade 8×4 exata). Base: **1ª variação** (painéis mais limpos, janela de moldura grossa). Da 2ª veio só a passarela one-way (a da 1ª sumia, fina e escura, contra o fundo). Referências: `core_tiles.png` e `greenhouse_tiles.png` |
| Montagem | Igual à Estufa: as 16 máscaras são a célula "interior" com as faixas de borda coladas por cima (cima 28 % da célula "piso", baixo 22 % da "teto", lados 13 % das células de borda), então as bordas casam por construção. Fundo = variação de painel da linha 4 escurecida (×0,60, quase neutra), porque o fundo de aço com fenda da IA, repetido na fase inteira, virava uma grade de fendas. Ganho final 0,9 com joelho nos claros: luma dos sólidos 0,555 (Núcleo 0,53, Estufa 0,55). 0 px semitransparentes, 0 px de franja |
| Status | **integrado (IA)** em 2026-10-27; `tests/test_level_tileset.gd` confere o Lab papel por papel (inclui a parede magnética) |

**Prompt (Codex, com os dois tilesets anexados):**
```
Pixel art TILE SET for a 2D side-view space station platformer: the station's research LABORATORY, where the cooling system broke and the white corridors bake in the heat.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the existing station tilesets): same 16-bit worn look, panel seams, rivets, scratched paint, grime in recesses, hard pixels, no anti-aliasing, no soft gradients.

Palette (16 colors max): dirty off-white and cream lab casing (#C9C4B5 body, #DCD7C9 highlight, #8C8778 shading), cold steel underneath (#5E646B, #3A3F45), dark outline (#141310), heat-warning orange stripes (#E07A3A), a little pale cyan (#7FD6E8) only on lamp glass. Keep the base tiles MEDIUM-BRIGHT: the engine darkens the scene with lighting, so do NOT bake shadows, glow or vignettes into tiles.

Layout: a strict grid of SQUARE tiles, 8 columns and 4 rows, all the same size, separated by flat magenta (#FF00FF) gaps. Each tile filled EDGE TO EDGE with artwork inside its own square (except where a tile is told to have magenta).
Row 1:
 1. wall block INTERIOR: off-white lab wall panel that tiles seamlessly on all four sides, no border, a few rivets and a seam.
 2. the same block seen as a FLOOR TOP: a cold steel floor trim with a thin orange heat stripe along the TOP edge, the off-white panel below.
 3. the same block as a CEILING UNDERSIDE: darker steel lip along the BOTTOM edge.
 4. the same block with a steel edge trim along the LEFT side only.
 5. the same block with a steel edge trim along the RIGHT side only.
 6. a single isolated block with trim on all four sides.
 7. a THIN ONE-WAY steel grating catwalk filling only the TOP QUARTER of the square, the rest flat magenta.
 8. a dark recessed BACKGROUND wall panel (greyer and darker than the blocks, cream-grey #8C8778 and steel), seamless, with a vent slot.
Row 2:
 1. a square WINDOW FRAME: thick off-white frame, the center fully flat magenta (#FF00FF).
 2. a ventilation grille with horizontal slats.
 3. a horizontal coolant pipe, cracked, with frost-free dry metal.
 4. a vertical coolant pipe.
 5. a ceiling lamp fixture, cold lab light, glass lit pale cyan.
 6. the same ceiling lamp, OFF, glass dark grey.
 7. an orange-and-black diagonal heat hazard stripe panel.
 8. a climbable MAGNETIC wall panel with bold diagonal YELLOW (#E8C15A) and dark grey stripes, steel frame.
Row 3: lab details, each a full square tile: a sample cabinet with small glass doors, a wall monitor screen (dark, no text), a broken cooling coil panel, a cable bundle, a pressure gauge panel (no numbers), an off-white wall panel with a scorch mark, a riveted steel plate, a floor drain grate.
Row 4: eight more variations of the row-1 interior wall block (different seams, rivets, a small dent, a stain), each seamless.

IMPORTANT RULE: deliver a GRID OF SEPARATE TILES, not a finished picture. Do not draw a room, a level or a composed scene; do not draw characters, creatures or props resting on the tiles.
No text, no letters, no numbers, no labels, no grid lines, no watermark.
```

<a id="til-infirmary"></a>
### TIL-INFIRMARY — Tileset Enfermaria

| Campo | Valor |
|---|---|
| Caminho final | `assets/tiles/infirmary_tiles.png` + `assets/tiles/infirmary_tileset.tres` |
| Contrato | **Mesmo atlas do TIL-LAB**: 128×64, 8×4 de 16×16, mesmas coordenadas. Linhas 0–1: as 16 máscaras 4-dir, opacas. Linha 2: (0,2) passarela one-way só no topo (5 px) · (1,2) parede de fundo opaca · (2,2) janela com miolo transparente · (3,2) grade de ventilação com geada · (4,2) cano horizontal congelado · (5,2) cano vertical · (6,2) luminária acesa (quadro 22) · (7,2) faixa de perigo. Linha 3: (0,3) **parede magnética amarela** · (1,3) luminária apagada (quadro 25) · (2..7,3) armário de remédios, monitor, painel com placa de gelo e pingentes, cabos congelados, painel de sinais vitais, azulejo com rachadura de gelo. O `.tres` é cópia do `lab_tileset.tres` com a textura trocada (colisão de mundo nas 16 máscaras, one-way em (0,2) na camada 64) |
| Paleta | GDD-2.9: azulejo hospitalar ciano-pálido (`#B9CFD9`), geada branca nas bordas e juntas, aço azul-frio por baixo, contorno azul-escuro, faixa âmbar de quarentena; paleta `infirmary` no `tools/placeholders.json` |
| Placeholder gerado | `assets/placeholder/tiles/infirmary_tiles.png` (128×64) — `tools/make_placeholders.gd` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-10-27, 2 variações (as duas 8×4 exatas), escolhida a **1ª**: azulejos mais limpos e geada só nas bordas. A 2ª tinha mais ruído e, na linha 4, geada em forma de **"+"** nas juntas — descartada pela regra de não ter cruz. Referências: `lab_tiles.png` e `core_tiles.png` ×6 |
| Montagem | Receita do TIL-LAB (`compose`): as 16 máscaras são o azulejo "interior" com faixas de borda coladas (cima 28 % da célula "piso" com crosta de geada, baixo 22 % do "teto", lados 13 %). **Passarela one-way montada da faixa de piso** (4 px de aço com geada + 1 px de sombra): as duas passarelas da IA (grade escura na 1ª, tela ciano vazada na 2ª) sumiam contra o fundo escuro. Fundo = o próprio azulejo escuro da IA (0,7), sem escurecer. Ganho 0,87 com joelho nos claros: luma dos sólidos **0,552** (Núcleo 0,53, Lab 0,555). 0 px semitransparentes, 0 px de franja |
| Status | **integrado (IA)** em 2026-10-27; `tests/test_level_tileset.gd` confere a Enfermaria papel por papel (inclui a parede magnética) |

**Prompt (Codex, com os dois tilesets anexados):**
```
Pixel art TILE SET for a 2D side-view space station platformer: the station's INFIRMARY, frozen solid after the heating failed. Dark, narrow, cold hospital corridors with pale cyan wall tiles and frost creeping along the seams.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the existing station tilesets): same 16-bit worn look, panel seams, rivets, scratched paint, grime in recesses, hard pixels, no anti-aliasing, no soft gradients.

Palette (16 colors max): pale icy cyan-white hospital wall tiles (#B9CFD9 body, #DDEBF0 highlight, #7D97A6 shading), white frost (#EEF6F8) only along edges and seams, cold blue steel underneath (#5B6E7C, #34434F), dark blue outline (#0C141B), amber quarantine stripes (#E8B04A), a little pale cyan (#9FE3F0) only on lamp glass. Keep the base tiles MEDIUM-BRIGHT: the engine darkens the scene with lighting, so do NOT bake shadows, glow or vignettes into tiles.

Layout: a strict grid of SQUARE tiles, 8 columns and 4 rows, all the same size, separated by flat magenta (#FF00FF) gaps. Each tile filled EDGE TO EDGE with artwork inside its own square (except where a tile is told to have magenta).
Row 1:
 1. wall block INTERIOR: pale cyan hospital wall made of square ceramic tiles, seamless on all four sides, no border, a few grout lines, a hairline crack.
 2. the same block seen as a FLOOR TOP: a cold steel floor trim with a thick white FROST crust along the TOP edge, the tile wall below.
 3. the same block as a CEILING UNDERSIDE: darker blue steel lip along the BOTTOM edge with tiny frost.
 4. the same block with a steel edge trim along the LEFT side only.
 5. the same block with a steel edge trim along the RIGHT side only.
 6. a single isolated block with trim on all four sides.
 7. a THIN ONE-WAY steel grating catwalk filling only the TOP QUARTER of the square, the rest flat magenta.
 8. a dark recessed BACKGROUND wall (deep cold blue-grey #4A5E6C and #34434F, clearly darker than the blocks), seamless, plain ceramic tiles.
Row 2:
 1. a square WINDOW FRAME: thick pale steel frame with frost in the corners, the center fully flat magenta (#FF00FF).
 2. a ventilation grille with horizontal slats, frost on the slats.
 3. a horizontal pipe covered in frost, with a short icicle under it.
 4. a vertical frosted pipe.
 5. a ceiling lamp fixture, cold hospital light, glass lit pale cyan.
 6. the same ceiling lamp, OFF, glass dark grey.
 7. an amber-and-black diagonal QUARANTINE hazard stripe panel.
 8. a climbable MAGNETIC wall panel with bold diagonal YELLOW (#E8C15A) and dark grey stripes, steel frame.
Row 3: infirmary details, each a full square tile: a medicine cabinet with small frosted glass doors, a wall monitor screen (dark, no text, no numbers), a wall panel with a thick sheet of ice and icicles, a frozen cable bundle, a vital-signs wall panel with a dark screen (no numbers, no text), a wall tile panel with a deep ice crack, a riveted blue steel plate, a frozen floor drain grate.
Row 4: eight more variations of the row-1 interior wall block (different grout, a missing ceramic tile, a frost patch, a small stain), each seamless.

NO red cross and NO cross symbol of any kind on any tile.

IMPORTANT RULE: deliver a GRID OF SEPARATE TILES, not a finished picture. Do not draw a room, a level or a composed scene; do not draw characters, creatures, beds or props resting on the tiles.
No text, no letters, no numbers, no labels, no grid lines, no watermark.
```

<a id="til-docks"></a>
### TIL-DOCKS — Tileset Docas

| Campo | Valor |
|---|---|
| Caminho final | `assets/tiles/docks_tiles.png` + `assets/tiles/docks_tileset.tres` |
| Contrato | **Mesmo atlas do TIL-INFIRMARY**: 128×64, 8×4 de 16×16, mesmas coordenadas. Linhas 0–1: as 16 máscaras 4-dir, opacas. Linha 2: (0,2) passarela one-way só no topo (4 px + 1 px de sombra) · (1,2) parede de fundo opaca · (2,2) janela com miolo transparente · (3,2) grade de ventilação · (4,2) cano de combustível com válvula · (5,2) cano vertical · (6,2) sinalizador âmbar aceso (quadro 22) · (7,2) faixa de perigo. Linha 3: (0,3) **parede magnética amarela** · (1,3) sinalizador apagado (quadro 25) · (2..7,3) lateral de contêiner, painel de volante de eclusa, junção com manômetros, remendo de casco, placa de trava de atracação, grelha de piso com argolas. O `.tres` é cópia do `infirmary_tileset.tres` com a textura trocada |
| Paleta | GDD-2.9 (preto do espaço + amarelo de perigo): casco aço médio `#8C96A0`, moldura `#454E58`, contorno `#0E1218`, amarelo `#F2C230` com preto; paleta `docks` no `tools/placeholders.json` |
| Placeholder gerado | `assets/placeholder/tiles/docks_tiles.png` (128×64) |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-11-20, 2 variações (as duas 8×4 exatas), escolhida a **1ª**: piso com a faixa de perigo fina no topo e menos marcas soltas. Referências: `infirmary_tiles.png` e `lab_tiles.png` |
| Montagem | Receita da Enfermaria (script do agente, PIL): redução por média com alfa pré-multiplicado; as 16 máscaras são a célula "interior" com faixas coladas (topo 5 px da célula "piso", baixo 4 px do "teto", lados 2 px das bordas). Passarela one-way montada da faixa de piso. Ganho ×1,12 com joelho nos claros: luma dos sólidos **0,550** (Enfermaria 0,552). 0 px semitransparentes |
| Status | **integrado (IA)** em 2026-11-20; `tests/test_level_tileset.gd` confere as Docas papel por papel |

**Prompt (Codex, com os dois tilesets anexados):**
```
Pixel art TILE SET for a 2D side-view space station platformer: the station's DOCKS, a huge cargo and launch bay whose hull is breached to open space. Heavy riveted gunmetal hull plates, yellow-and-black hazard markings, cold and industrial.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the existing station tilesets): same 16-bit worn look, panel seams, rivets, scratched paint, grime in recesses, hard pixels, no anti-aliasing, no soft gradients.

Palette (16 colors max): medium steel-grey hull plates (#8C96A0 body, #B4BEC8 highlight, #5E6873 shading), darker gunmetal frame (#454E58, #2C333B), dark navy outline (#0E1218), bold hazard yellow (#F2C230) with black (#1A1D21) diagonal stripes only on trims and markings, a little warning red-orange (#E0663A) only on small lamps. Keep the base tiles MEDIUM-BRIGHT: the engine darkens the scene with lighting, so do NOT bake shadows, glow or vignettes into tiles.

Layout: a strict grid of SQUARE tiles, 8 columns and 4 rows, all the same size, separated by flat magenta (#FF00FF) gaps. Each tile filled EDGE TO EDGE with artwork inside its own square (except where a tile is told to have magenta).
Row 1:
 1. wall block INTERIOR: riveted steel-grey hull plates, seamless on all four sides, no border, plate seams and a few rivets.
 2. the same block seen as a FLOOR TOP: a thick gunmetal deck plate along the TOP edge with a thin yellow-and-black hazard stripe, the hull plates below.
 3. the same block as a CEILING UNDERSIDE: darker gunmetal lip along the BOTTOM edge with bolts.
 4. the same block with a gunmetal edge trim along the LEFT side only.
 5. the same block with a gunmetal edge trim along the RIGHT side only.
 6. a single isolated block with trim on all four sides.
 7. a THIN ONE-WAY steel grating catwalk filling only the TOP QUARTER of the square, the rest flat magenta.
 8. a dark recessed BACKGROUND wall (deep gunmetal #3A424C and #2A3038, clearly darker than the blocks), seamless, large plain panels.
Row 2:
 1. a square WINDOW FRAME: thick gunmetal frame with hazard-yellow corner brackets, the center fully flat magenta (#FF00FF).
 2. a ventilation grille with horizontal slats.
 3. a horizontal fuel pipe with a valve.
 4. a vertical fuel pipe.
 5. a caged hazard beacon lamp, ON, glass lit warm amber.
 6. the same caged beacon lamp, OFF, glass dark grey.
 7. a yellow-and-black diagonal HAZARD stripe panel.
 8. a climbable MAGNETIC wall panel with bold diagonal YELLOW (#E8C15A) and dark grey stripes, steel frame.
Row 3: docks details, each a full square tile: the corrugated side of a cargo container, an airlock wheel-valve panel, a pipe junction with gauges (no numbers), a hull patch plate welded over a crack, a docking clamp plate, a cargo net strapped over panels, a floor grate with tie-down rings, a stencil-less warning panel with a big chevron arrow.
Row 4: eight more variations of the row-1 interior hull block (different plate layout, a dent, scorch marks, a missing rivet), each seamless.

IMPORTANT RULE: deliver a GRID OF SEPARATE TILES, not a finished picture. Do not draw a room, a level or a composed scene; do not draw characters, creatures, ships or props resting on the tiles.
No text, no letters, no numbers, no labels, no grid lines, no watermark.
```

<a id="spr-props-docks"></a>
### SPR-PROPS-DOCKS — Objetos das Docas

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/props/docks_props_sheet.png` (carregado pelo `o` com `"sheet"` + `"frame"`) |
| Contrato | Folha **128×64 = 4 col × 2 lin de 32×32**, fundo transparente, objeto apoiado no pé do quadro e centrado. Quadros: 0 caixas de carga · 1 suporte de cilindros de combustível · 2 traje EVA vazio pendurado · 3 carrinho de ferramentas · 4 empilhadeira · 5 duas poltronas da nave de escape · 6 cabeço de amarração com cabo cortado · 7 painel de partidas |
| Placeholder gerado | `assets/placeholder/sprites/props/docks_props_sheet.png` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-11-20, 2 variações (as duas com os 8 objetos na ordem), escolhida a **1ª** (quadros de tamanho mais parecido). Referências: `mu7_sheet.png` e `infirmary_props_sheet.png` |
| Montagem | Escala comum tirada do objeto mais alto (31 px), limitada a 31 px de largura nos compridos; alinhados pelo pé |
| Status | **integrado (IA)** em 2026-11-20 |

**Prompt (Codex):**
```
Pixel art sprite sheet of EIGHT abandoned objects from the DOCKS of a melancholic 2D side-view space station game, "a beautiful station nobody is using": the cargo and launch bay where the escape ship left almost empty. Side view.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the MU-7 robot and the station objects): same worn 16-bit look, hard pixels, dark 1-pixel outline, scratched paint. MEDIUM brightness, no baked glow, no cast shadows.

Palette: steel grey (#8C96A0, #B4BEC8 highlight, #5E6873 shading), gunmetal (#454E58, #2C333B), hazard yellow (#F2C230) with black (#1A1D21) stripes, a little orange (#E0663A), pale cyan glass (#9FE3F0), dark navy outline (#0E1218).

Layout: a grid of SQUARE frames, 4 columns and 2 rows, the same size each, every object STANDING ON THE BOTTOM EDGE of its own frame, centered horizontally.
Row 1:
 1. a CARGO CRATE: a chunky square metal crate with reinforced corners and a hazard-yellow stripe, a smaller crate stacked on top slightly offset.
 2. a FUEL CANISTER rack: three tall cylindrical canisters strapped in a low steel rack, orange caps.
 3. an empty SPACESUIT hanging on a wall-less standing rack: bulky white-grey EVA suit with a dark visor, empty and limp, NO person inside.
 4. a TOOL CART: low wheeled cart with a toolbox and a coiled cable on top.
Row 2:
 5. a small CARGO LOADER: a squat wheeled loader with a short lifting fork, hazard stripes.
 6. a row of two empty PASSENGER SEATS from an escape ship, bolted to a short floor rail, harness straps hanging loose.
 7. a TIE-DOWN BOLLARD: a short thick mooring post with a cut steel cable coiled at its base.
 8. a tall DEPARTURE PANEL on a pole: a dark screen (no text, no numbers) with one amber light, slightly tilted.

Chunky readable shapes only: no thin 1-pixel details, everything must still read when each frame is shrunk to 32x32 pixels. Keep relative sizes realistic: the crate and loader are wide, the canister rack, spacesuit and departure panel are tall and narrow.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, bodies, cast shadows or any other object. Each object floats on the flat magenta background, resting on the bottom edge of its frame.

Solid flat magenta background (#FF00FF) everywhere else, with clear magenta gaps between frames. No text, no letters, no labels, no numbers, no grid lines, no frame borders, no watermark.
```

<a id="spr-cradle"></a>
### SPR-CRADLE — Berço vazio da SELENE

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/escape_cradle.png` (cena `scenes/world/escape_cradle.tscn`, usada pelo `o` com `"scene"`) |
| Contrato | **128×64**, um quadro, apoiado no pé, sem colisão (cenário); marco visual do hangar |
| Placeholder gerado | `assets/placeholder/sprites/world/escape_cradle.png` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-11-20, 2 variações, escolhida a **1ª**: garras curvas abertas leem "algo grande estava aqui"; a 2ª parecia uma prensa. Referências: `infirmary_props_sheet.png` e `lab_tiles.png` |
| Status | **integrado (IA)** em 2026-11-20 |

**Prompt (Codex):**
```
Pixel art of ONE large object for a melancholic 2D side-view space station platformer: the EMPTY LAUNCH CRADLE of an escape ship that already left. Side view, the object is about twice as wide as it is tall.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the station objects and tiles): same worn 16-bit look, hard pixels, dark 1-pixel outline, scratched paint, rivets. MEDIUM brightness, no baked glow, no cast shadows.

The cradle: a massive low steel cradle base resting on the ground, with two big curved CLAMP ARMS rising from each end and OPEN outward, holding nothing — the ship is gone, the space between the arms is empty. Thick hydraulic pistons under each arm, hazard yellow-and-black stripes along the base, a few severed umbilical hoses and cables hanging loose from the arms, an unlit amber beacon on one arm. It must read clearly as "something big used to sit here".

Palette: steel grey (#8C96A0, #B4BEC8 highlight, #5E6873 shading), gunmetal (#454E58, #2C333B), hazard yellow (#F2C230) with black (#1A1D21) stripes, orange (#E0663A) hoses, dark navy outline (#0E1218).

Chunky readable shapes: it will be shown at 128x64 pixels in game, so no thin 1-pixel details. The cradle stands on the bottom edge of the image and fills the width.

IMPORTANT: draw ONLY the cradle. No ship, no person, no robot, no walls, no floor, no ground line, no room, no stars, no cast shadow. Solid flat magenta background (#FF00FF) everywhere else. No text, no letters, no numbers, no labels, no watermark.
```

<a id="spr-coupler"></a>
### SPR-COUPLER — Acoplador de energia

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/world/coupler_sheet.png` (cena `scenes/world/coupler.tscn`, `A` no ASCII) |
| Contrato | **128×32 = 4 quadros de 32×32**, apoiados no pé: 0 desligado · 1 carregando (núcleo meio ciano) · 2 alimentado (núcleo branco-ciano) · 3 trancado pelo Serralheiro (barra e luz laranja). A F63 usa os quatro |
| Placeholder gerado | `assets/placeholder/sprites/world/coupler_sheet.png` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-11-20, 2 variações da folha "máquinas das Docas" (linha 1 acoplador, linha 2 jato); acopladores da **2ª** (estados mais distintos, barra de trava legível). Referências: `mu7_sheet.png` e `cx2_sheet.png` |
| Status | **integrado (IA)** em 2026-11-20 |

**Prompt (Codex, mesma folha do FX-THRUSTER):**
```
Pixel art sprite sheet for a melancholic 2D side-view space station platformer, the DOCKS sector. Side view.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the MU-7 robot and station machines): same worn 16-bit look, hard pixels, dark 1-pixel outline, scratched paint. No cast shadows.

Layout: a grid of SQUARE frames, 4 columns and 2 rows, all the same size.
Row 1: four states of the same ENERGY COUPLER, a squat floor-mounted machine: a heavy steel base with a vertical power socket in the middle holding a round glass energy core, hazard-yellow stripes on the base, cables going out of both sides at the bottom. Every frame STANDS ON THE BOTTOM EDGE of its own frame, same size and same position in each frame.
 1. OFF: core dark grey, no light.
 2. CHARGING: core half lit cyan (#5FE8FF) at the bottom, a few cyan sparks.
 3. POWERED: core fully lit bright cyan-white, glowing ring around the socket.
 4. SEALED: the same coupler locked shut by a big clamp bar across the core, red-orange (#E0663A) lock light, core dark.
Row 2: four animation frames of a small THRUSTER JET flame seen from the side, pointing STRAIGHT DOWN from the top center of each frame: a short bright cyan-white core (#E8FFFF) with a blue (#5FE8FF, #2E7BD6) outer flame, each frame slightly different length and flicker; the flame occupies only the top half of its frame and is centered horizontally.

Palette: steel grey (#8C96A0, #B4BEC8, #5E6873), gunmetal (#454E58, #2C333B), hazard yellow (#F2C230) with black (#1A1D21), cyan energy (#5FE8FF, #E8FFFF), dark navy outline (#0E1218).

Chunky readable shapes only: no thin 1-pixel details. The coupler must still read at 32x32 pixels and the flame at 16x16 pixels.

IMPORTANT: draw ONLY the objects described. Never draw walls, floors, ground, rooms, characters or any other object. Solid flat magenta background (#FF00FF) everywhere else, with clear magenta gaps between frames. No text, no letters, no numbers, no labels, no grid lines, no frame borders, no watermark.
```

<a id="fx-thruster"></a>
### FX-THRUSTER — Jato do Propulsor

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/fx/thruster_jet.png` (filho `ThrusterJet` do MU-7, girado no sentido oposto ao empuxo) |
| Contrato | **64×16 = 4 quadros de 16×16**, chama apontando para baixo a partir do topo do quadro, centrada; desenhada sem luz de cena |
| Placeholder gerado | `assets/placeholder/sprites/fx/thruster_jet.png` |
| Fonte | **IA — geração de imagem do Codex CLI**, 2026-11-20: linha 2 da **1ª** variação da folha do SPR-COUPLER (chamas mais grossas, legíveis a 16 px). Prompt na ficha SPR-COUPLER |
| Status | **integrado (IA)** em 2026-11-20 |

<a id="bg-space"></a>
### BG-SPACE — Espaço (parallax)

| Campo | Valor |
|---|---|
| Caminho final | `assets/backgrounds/space_far.png`, `space_mid.png`, `space_near.png` |
| Contrato | Cada camada **1152×216** (três larguras de tela), repetível horizontalmente. `far` = estrelas, opaca. `mid` = nebulosa com o **planeta-alvo e a lua**, com alfa por luminância para as estrelas aparecerem pelos vazios — **o disco do planeta e a lua levam alfa 1 por máscara**, senão o planeta fica translúcido. `near` = treliças e detritos da estação, com o magenta chaveado e **sem** esmaecimento de emenda (borda dura esmaecida vira fantasma) |
| Fonte grátis | "Space Background" packs CC0 no itch.io (ex.: https://screamingbrainstudios.itch.io/ — verificar licença) ou OpenGameArt "space backgrounds" CC0 |
| Placeholder | Gradiente escuro + pontos brancos gerados |
| Placeholder gerado | `assets/placeholder/backgrounds/space_far.png`, `space_mid.png`, `space_near.png` (384×216 cada) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Three separate pixel art parallax background layers for a 2D side-view space game, each exactly 384x216 pixels and seamlessly tileable horizontally. Layer 1 "far": deep black-blue space with tiny scattered stars. Layer 2 "mid": a faint teal and purple nebula and, far away, a small blue-green habitable planet. Layer 3 "near": dark silhouettes of space station trusses, antennas and floating debris on a fully transparent background. Style: 16-bit pixel art, hard pixels, no anti-aliasing, calm and lonely mood. Deliver each layer as its own image. For layer 3 use a solid flat magenta background (#FF00FF) instead of transparency. No text.

IMPORTANT RULE: these are distant background layers only. Do not draw station interiors, floors, platforms, doors, characters, HUD or any foreground object.

CRITICAL DELIVERY SIZE: each layer at most 768x432 pixels, which is twice its size in the game (384x216). Do NOT deliver a big image: upscaled art loses its hard pixel edges when reduced. The artwork must reach the left and right edges exactly so the layer repeats seamlessly.
```

<a id="bg-menu"></a>
### BG-MENU — Fundo do menu principal

| Campo | Valor |
|---|---|
| Caminho final | `assets/backgrounds/menu_backdrop.png` |
| Contrato | **384×216 exatos**, uma imagem só, sem transparência. É desenhada no tamanho final e ampliada por número inteiro (5× em 1920×1080) — **não** é a tira de parallax da fase |
| Por que separada do BG-SPACE | Na fase o espaço é visto por vigias de 2 ou 3 tiles: detalhe fino some e não faz falta. No menu ele ocupa a tela inteira, ampliado 5×, e qualquer moleza vira borrão do tamanho de um punho |
| Composição | Estrutura da estação em silhueta na esquerda (primeiro plano), o planeta habitável e a lua à direita, nebulosa ao fundo. O logo entra no terço superior e os botões no centro — **a faixa central precisa ser escura e calma**, senão o texto some |
| Status | **integrado** em 2026-09-20 (entrega `bg menu.png` 1672×941, reduzida para 384×216 por Lanczos) |

**Prompt (Nano Banana Pro):**
```
Pixel art title screen background for a 2D sci-fi game about an abandoned space station, seen from outside the station looking into deep space.

Composition, left to right: on the LEFT, the dark silhouette of a space station truss — beams, antennas, a docking arm — in near-black blue, cropped by the edge of the frame, occupying about one quarter of the width. On the RIGHT, a blue-green habitable planet with visible continents and cloud bands, plus a small grey moon beside it. BEHIND everything, a teal and purple nebula and a field of stars. The CENTER of the image must stay dark, calm and uncluttered, because the game title and the menu buttons are drawn over it.

Style: 16-bit era pixel art, CHUNKY HARD PIXELS, no anti-aliasing, no soft gradients, no airbrush. Limited palette of about 24 colors: near-black blue, deep teal, muted purple, pale cyan, and a warm ochre only on the planet. Dithering is allowed and encouraged for the nebula gradients — use visible dither patterns instead of smooth blends. Lonely, melancholic, quiet. Not neon, not cyberpunk.

CRITICAL DELIVERY SIZE: the image must be EXACTLY 384x216 pixels, or at most 768x432 (exactly twice that). Do NOT deliver a large painted image: this artwork is magnified five times in the game, so every pixel of it is a visible block on screen. Art drawn large and shrunk down turns to mush; art drawn small stays sharp. Every star must be one or two pixels, not a soft glow.

No text, no logo, no letters, no watermark, no user interface, no characters, no grid lines.
```

<a id="spr-helena"></a>
### SPR-HELENA — Retrato da Dra. Helena Vasquez (logs)

| Campo | Valor |
|---|---|
| Caminho final | `assets/sprites/portraits/helena_sheet.png` |
| Contrato | Quadros **48×48**, grade de **2 colunas × 6 linhas** (folha 96×288). Coluna 1 = boca fechada, coluna 2 = boca aberta: alternar as duas enquanto o texto é digitado dá a ilusão de fala. Uma linha por expressão |
| Expressões | 1 neutra/profissional · 2 cansada · 3 preocupada · 4 sorriso leve · 5 emocionada, olhos marejados · 6 determinada |
| Por que essas | Cada uma casa com um momento dos quatro logs: o relatório técnico (neutra), "ela é educada demais para dizer que eu estou cansada" (cansada), o oxigênio caindo no setor B (preocupada), a Samira e as mudas (sorriso), "Dá certo, Marcos. Dá certo." (emocionada), "Não deixe a estação cair" (determinada) |
| Uso no jogo | Na caixa de log, à esquerda do texto. Cada linha do log ganha um campo de expressão no JSON — **feature ainda não implementada** |
| Status | pendente |

**Prompt (Nano Banana Pro):**
```
Pixel art character portrait sprite sheet for the dialogue box of a melancholic 2D sci-fi game. The character is DR. HELENA VASQUEZ, chief engineer of a space station: an attractive Latina woman in her late thirties, warm brown skin, dark brown eyes, rectangular black-framed glasses, thick dark wavy hair in a half-up style with loose strands framing her face, confident and intelligent. Curvy figure. She wears a worn teal engineering jumpsuit unzipped to the chest over a fitted top with a low neckline, a small station ID badge clipped to the collar. Head-and-shoulders bust framing, facing three-quarters toward the right.

STYLE MUST MATCH THE ATTACHED REFERENCE IMAGES (the MU-7 robot and the station tileset): same 16-bit pixel art, CHUNKY HARD PIXELS, no anti-aliasing, no soft gradients, no airbrush. Limited palette of about 20 colors. Cool teal and navy tones on the clothes to match the station, warm tones only on skin and hair. Soft cyan rim light on one side, as if lit by a monitor.

Layout: a grid of 2 columns and 6 rows, every frame exactly 48x48 pixels. Column 1 = mouth closed. Column 2 = SAME frame with the mouth slightly open, as if mid-word — nothing else changes between the two columns. One expression per row:
row 1 neutral, professional, calm
row 2 tired, heavy eyelids, slight frown
row 3 worried, eyebrows raised together, lips pressed
row 4 faint warm smile, softened eyes
row 5 emotional, eyes glistening with held-back tears, trembling smile
row 6 determined, serious, jaw set, looking straight ahead

CONSISTENCY IS CRITICAL: the same woman in all 12 frames — same face shape, same glasses, same hair, same clothes, same head position and same framing. Only the facial expression changes.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the character's head and shoulders. No background, no room, no screen, no border, no frame around the portrait, no text, no speech bubble.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 384x1152 pixels in total, which is four times its size in the game (96x288, frames of 48x48). Art drawn large and shrunk down turns to mush; art drawn small stays sharp. Do NOT deliver a big image.

FRAME MARGIN: leave one empty pixel inside every frame on the left, the right and the top. The shoulders are cut by the bottom edge of the frame.

Solid flat magenta background (#FF00FF). No text, no letters, no labels, no grid lines, no watermark.
```

> **Anexe o `robo novo.png` e o `tileset.png` como referência.** Consistência de rosto entre 12 quadros é o ponto fraco das IAs de imagem: se vier uma Helena diferente em alguma linha, peça de novo só aquela linha anexando a folha boa.

<a id="ui-logo"></a>
### UI-LOGO — Logo ÓRBITA

| Campo | Valor |
|---|---|
| Caminho final | `assets/ui/logo.png` |
| Contrato | **192×48** (cabe na tela 384×216), fundo transparente |
| Placeholder | Texto "ÓRBITA" na fonte pixel |
| Placeholder gerado | `assets/placeholder/ui/logo.png` (192×48) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art game title logo reading exactly "ÓRBITA" (with the acute accent on the O), for a melancholic sci-fi 2D game about an AI alone on a space station. Clean bold pixel letters in pale cyan with a subtle thin orbit ring passing behind the O like a planet ring, slight glow, cold and elegant, not cartoonish. Size ratio 4:1, designed to be downscaled to 192x48 pixels, hard pixels, no anti-aliasing. Solid flat magenta background (#FF00FF). No other text.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 768x192 pixels in total, which is four times the size it will have in the game (192x48, frames of 192x48). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

<a id="ui-font"></a>
### UI-FONT — Fonte pixel

| Campo | Valor |
|---|---|
| Caminho final | `assets/fonts/ui_font.ttf` (+ `ui_font_mono.ttf` para telas de terminal) |
| Contrato | Fonte bitmap/pixel com **acentos pt-BR** (á, ã, ç, é, ê, í, ó, ô, õ, ú), legível em 8 px |
| Fonte grátis | **m5x7** e **m6x11** por Daniel Linssen (livre, crédito pedido) — https://managore.itch.io/m5x7 · alternativa CC0: Kenney Fonts — https://kenney.nl/assets/kenney-fonts |
| Arquivo integrado | **m5x7** (Daniel Linssen) em `assets/fonts/ui_font.ttf`, `.import` com `antialiasing=0`, `hinting=0`, `subpixel_positioning=0`, `generate_mipmaps=false`, `multichannel_signed_distance_field=false`, `oversampling=1.0` |
| Tema | `assets/ui/theme.tres` com `default_font` = a fonte e `default_font_size = 16`; todos os `*/font_sizes/*` do tema passaram de 10/8 para **16** (tamanho nativo da m5x7; altura de linha 13 px em 384×216) |
| Verificado em | QA visual da F07/F08/F09 (2026-09-19): borda dura sem antialias, acentos Ó/Ç/Õ/Í/Á/Ã corretos, texto cabe nos botões |
| Pendente | `ui_font_mono.ttf` (telas de terminal) continua pendente |
| Status | integrado |

<a id="ui-hud"></a>
### UI-HUD — Elementos de HUD

> **Ligação com SPR-PICKUPS:** os ícones dos contadores de Log e Dado no rodapé repetem a **silhueta** do coletável correspondente. Se a arte definitiva dos coletáveis mudar de silhueta, estes ícones mudam junto — é o que liga "coisa no chão" a "número no canto da tela" ([AJ-023](design/GDD.md#gdd-ajustes)).

| Campo | Valor |
|---|---|
| Caminho final | `assets/ui/hud_sheet.png` |
| Contrato | Tiles **16×16**: célula de Integridade cheia/vazia/piscando · moldura da barra de Carga (9-slice 16×16) · moldura da barra do Reator (9-slice) · ícones de status (Corrosão, Superaquecimento, Congelamento, Descarga, Sobrecarga) · ícone Log · ícone Dado · ícone tecla [E] |
| Fonte grátis alternativa | Kenney "UI Pack Pixel Adventure" (CC0) — https://kenney.nl/assets/ui-pack-pixel-adventure |
| Placeholder gerado | `assets/placeholder/ui/hud_sheet.png` (128×32 = atlas 8×2 de 16×16) — `tools/make_placeholders.gd` |
| Status | placeholder |

**Prompt:**
```
Pixel art HUD sprite sheet for a sci-fi 2D game where the HUD looks like sensor readouts of an old maintenance robot, 16x16 pixel icons on a grid of 8 columns: health cell full (cyan), health cell empty (dark red), health cell blinking (bright red), a 9-slice frame for a horizontal energy bar (blue), a 9-slice frame for a reactor stability bar (white), status icons: corrosion (green spores), overheating (orange flame), freezing (blue snowflake), discharge (yellow lightning), overload (white arrow up), a green data-chip log icon, a gold hexagon data icon, a keyboard key "E" icon. Style: 16-bit pixel art, hard pixels, no anti-aliasing, minimal and diegetic, thin monochrome outlines. Solid flat magenta background (#FF00FF), no other text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole atlas SMALL — at most 512x128 pixels in total, which is four times the size it will have in the game (128x32, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

EDGES: the two 9-slice bar frames must reach the edges of their cell, because the game stretches them. Every icon, on the contrary, must leave one empty pixel of margin inside its cell and must not touch the border.
```

<a id="fx-light"></a>
### FX-LIGHT — Textura de luz

| Campo | Valor |
|---|---|
| Caminho final | `assets/fx/light_radial.png` (+ `light_cone.png` para lanterna direcional) |
| Contrato | **256×256** gradiente radial branco→transparente; cone 256×128 |
| Fonte | Gerado por `tools/make_placeholders.gd` (definitivo = gerado) |
| Arquivo gerado | `assets/fx/light_radial.png` (256×256, gradiente branco→transparente, alcança zero no raio 128 px = `Balance.VISION_RADIUS_ON`) e `assets/fx/light_cone.png` (256×128, ápice à esquerda, abertura de 28°) — vão direto ao caminho final (`"final": true` no manifesto) |
| Status | final |

<a id="mus-menu"></a>
### MUS-MENU — Menu

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/menu.ogg` (loop) |
| Direção | **Música de verdade.** A decisão anterior de "sem música, só ruído de rádio" foi **revogada pelo humano** em 2026-09-20 ("vou reverter a adr e colocar uma musica mesmo"). Loop ambiente de 60–90 s: estação morta ouvida de dentro, drone grave desafinado, pad lento, estática distante, um ping a cada oito compassos. Sem bateria, sem voz, sem melodia cantável |
| Fonte grátis | Freesound "radio static loop" CC0 — https://freesound.org/search/?q=radio+static+loop&f=license:%22Creative+Commons+0%22 |
| Status | **pendente** — o arquivo entregue em 2026-09-20 chegou com **0 byte** (download falhou); precisa ser reenviado |

<a id="mus-core"></a>
### MUS-CORE — Núcleo Central

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/core.mp3` (loop) — a resolução aceita `.ogg`, `.mp3` ou `.wav` |
| Direção | Ambiente eletrônico minimalista, drones longos, poucos instrumentos, frio mas acolhedor ([GDD-2.9](design/GDD.md#gdd-2-9-musica)) |
| Fonte | **Gerada por IA e entregue pelo humano** em 2026-09-20 (`nucleo.mp3`, 1,5 MB, **48 s**). Alternativa grátis registrada: Pixabay Music "ambient space drone" — https://pixabay.com/music/search/ambient%20space%20drone/ · alternativa CC-BY: Kevin MacLeod (incompetech) |
| Status | **integrado** em 2026-09-20 |

<a id="mus-greenhouse"></a>
### MUS-GREENHOUSE — Estufa

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/greenhouse.mp3` (loop) — a resolução aceita `.ogg`, `.mp3` ou `.wav` |
| Direção | Mesmo universo do MUS-CORE com um elemento orgânico (pads quentes, sinos suaves); quase bonito, levemente triste |
| Fonte | **Gerada por IA e entregue pelo humano** em 2026-09-20 (`estufa.mp3`, 3,4 MB, **1 min 52 s**). Alternativa grátis registrada: Pixabay Music "ambient calm space" / "ethereal ambient" |
| Status | **integrado** em 2026-09-20 |

<a id="mus-lab"></a>
### MUS-LAB — Laboratório

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/lab.ogg` (**loop** sem fade nas pontas, 2–3 min) — a resolução aceita `.ogg`, `.mp3` ou `.wav` |
| Direção | Mesmo universo do MUS-CORE, mas **abafado e parado**: calor que não se mexe, refrigeração quebrada. Drone grave e morno, zumbido elétrico de compressor que tenta partir e engasga, pulsos espaçados como um ventilador falhando, um pad que "derrete" (leve detune). Modo menor, ~60 BPM sem pulso marcado. **Sem bateria e sem voz** ([GDD-2.9](design/GDD.md#gdd-2-9-musica)) |
| Fonte grátis | Pixabay Music (licença Pixabay, sem crédito obrigatório) — https://pixabay.com/music/search/dark%20ambient%20drone/ · Free Music Archive filtrado CC0/CC-BY · incompetech (CC-BY, crédito no README) |
| Termos de busca | `industrial ambient drone` · `humming machine ambient loop` · `heat haze ambient` · `broken machinery ambient` · `dark lab ambient` · `sci-fi laboratory loop` |
| Placeholder | nenhum: até o arquivo chegar a fase toca `core` |
| Status | **pendente** — o humano gera ou baixa e entrega; o agente normaliza por RMS, confere a emenda do loop e integra |

**Prompt (Stable Audio — preferido para loop; Suno com "instrumental" marcado):**
```
Instrumental seamless loop, 2 minutes 30 seconds, dark ambient for a 2D sci-fi game level: an abandoned space station laboratory where the cooling system broke and the white corridors bake in still, heavy heat. Low warm drone in a minor key, muffled and stifling, around 60 BPM with no clear beat. A faint electric hum of a failing compressor that tries to start and chokes, sparse soft metallic ticks of expanding metal, a slow detuned pad that feels like it is melting. Mixed quiet, lots of low-mid warmth, no bright highs. No drums, no percussion groove, no vocals, no choir, no melody that can be sung. Start and end at the same intensity, no fade-in, no fade-out, so it loops seamlessly.
```

<a id="mus-infirmary"></a>
### MUS-INFIRMARY — Enfermaria

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/infirmary.ogg` (**loop** sem fade nas pontas, 2–3 min) — a resolução aceita `.ogg`, `.mp3` ou `.wav` |
| Direção | Mesmo universo do MUS-CORE, mas **frio e vazio**: Inverno numa enfermaria onde a tripulação adoeceu um a um. Pad gelado e alto, quase sem graves, com muito espaço entre as notas; a **respiração de máquina** de um ventilador hospitalar desligado que ainda sopra de vez em quando (ar entrando e saindo, lento); um bipe distante de monitor, raro e sem ritmo; estalos de gelo no metal. Modo menor, ~50 BPM sem pulso marcado, reverb longo de sala de azulejo. **Sem bateria e sem voz** ([GDD-2.9](design/GDD.md#gdd-2-9-musica)) |
| Fonte grátis | Pixabay Music (licença Pixabay, sem crédito obrigatório) — https://pixabay.com/music/search/cold%20ambient/ · Free Music Archive filtrado CC0/CC-BY · incompetech (CC-BY, crédito no README) |
| Termos de busca | `cold ambient drone` · `frozen ambient loop` · `winter dark ambient` · `hospital ambient eerie` · `abandoned hospital ambience` · `sci-fi ice cave ambient` · `breathing machine ambient` |
| Placeholder | nenhum: até o arquivo chegar a fase toca `core` |
| Status | **pendente** — o humano gera ou baixa e entrega; o agente normaliza por RMS, confere a emenda do loop e integra |

**Prompt (Stable Audio — preferido para loop; Suno com "instrumental" marcado):**
```
Instrumental seamless loop, 2 minutes 30 seconds, dark ambient for a 2D sci-fi game level: the frozen, abandoned infirmary of a space station, where the crew fell ill one by one and the heating died. Cold, empty and still. A high, glassy, icy pad in a minor key with long silences between notes, very little bass, around 50 BPM with no clear beat. The slow mechanical breathing of a hospital ventilator that is still running in an empty room, air in, air out, every few seconds. A distant, rare monitor beep with no rhythm, faint creaks of ice on metal, long reverb of a tiled room. Mixed quiet. No drums, no percussion groove, no vocals, no choir, no melody that can be sung. Start and end at the same intensity, no fade-in, no fade-out, so it loops seamlessly.
```

<a id="mus-docks"></a>
### MUS-DOCKS — Docas

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/docks.ogg` (**loop** sem fade nas pontas, 2–3 min) |
| Direção | Mesmo universo do MUS-CORE, mas **aberto e sem ar**: o hangar vazio de onde a nave de escape partiu. Pad grave e largo, quase parado, com um pulso lento de baixo como respiração de máquina de atracação; sinos metálicos distantes e espaçados; um alarme de doca abafado, raro, que nunca completa a frase. Modo menor, ~60 BPM sem bateria, muito reverb e silêncio. **Sem voz** ([GDD-2.9](design/GDD.md#gdd-2-9-musica)) |
| Termos de busca | `space ambient drone` · `empty hangar ambient` · `dark sci-fi ambient loop` · `zero gravity ambient` |
| Placeholder | nenhum: até o arquivo chegar a fase toca `core` |
| Status | **pendente** — o humano gera ou baixa e entrega |

**Prompt (Stable Audio — preferido para loop; Suno com "instrumental" marcado):**
```
Instrumental seamless loop, 2 minutes 30 seconds, dark ambient for a 2D sci-fi game level: the empty docking bay of a space station, its hull open to space, the escape ship already gone. Wide, slow, airless. A deep sustained pad in a minor key, a slow sub-bass pulse like distant docking machinery breathing, sparse far-away metallic chimes, a muffled dock alarm that starts and never finishes, long reverb, lots of silence. Around 60 BPM with no drums. Mixed quiet. No vocals, no choir, no melody that can be sung. Start and end at the same intensity, no fade-in, no fade-out, so it loops seamlessly.
```

<a id="mus-chassis"></a>
### MUS-CHASSIS — Chassi perdido

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/chassis_lost.ogg` (**sem loop**, 6–10 s) |
| Direção | Sino grave de desligamento e um sopro de estática que some; a IA perde um corpo, não a vida |
| Fonte grátis | Freesound CC0 "power down drone" / Pixabay Music "dark ambient sting" |
| Status | placeholder (WAV sintetizado em `assets/placeholder/audio/music/chassis_lost.wav`) — definitivo pendente |

<a id="mus-gameover"></a>
### MUS-GAMEOVER — Perda de órbita

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/game_over.ogg` (**sem loop**, 10–15 s) |
| Direção | Queda lenta e definitiva: drone grave que desafina e morre, sem resolução |
| Fonte grátis | Pixabay Music "dark ambient ending" / Freesound CC0 "deep space rumble" |
| Status | placeholder (WAV sintetizado em `assets/placeholder/audio/music/game_over.wav`) — definitivo pendente |

<a id="mus-sector"></a>
### MUS-SECTOR — Setor religado

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/sector_restored.ogg` (**sem loop**, 15–20 s) |
| Direção | A única recompensa alegre do jogo: pad que abre, sinos claros, energia voltando corredor a corredor |
| Fonte grátis | Pixabay Music "uplifting ambient swell" / Freesound CC0 "power up ambient" |
| Status | placeholder (WAV sintetizado em `assets/placeholder/audio/music/sector_restored.wav`) — definitivo pendente |

<a id="mus-critical"></a>
### MUS-CRITICAL — Camada de reator crítico

| Campo | Valor |
|---|---|
| Caminho final | `assets/audio/music/reactor_critical.ogg` (**loop**, 20–30 s) |
| Direção | Camada de tensão que toca **por cima** da trilha da fase: pulso grave de ~1 Hz, ruído metálico, sem melodia — precisa somar sem competir |
| Fonte grátis | Pixabay Music "tension pulse loop" / Freesound CC0 "alarm drone loop" |
| Status | placeholder (WAV sintetizado em `assets/placeholder/audio/music/reactor_critical.wav`) — definitivo pendente |

<a id="sfx-pack"></a>
### SFX-PACK — Efeitos sonoros da demo

Caminho final: `assets/audio/sfx/<nome>.ogg` (ou `.wav`). Fontes CC0 sugeridas: **Kenney** "Sci-fi Sounds", "Interface Sounds", "Impact Sounds" (https://kenney.nl/assets?q=audio) e **Freesound** filtrado por CC0.

| Nome do arquivo | Evento ([GDD-2.9](design/GDD.md#gdd-2-9-sfx)) | Sugestão |
|---|---|---|
| `step_metal_1`, `step_metal_2`, `step_metal_3` | Passo metálico pesado (3 variações; `AudioManager.play_sfx("step_metal")` sorteia) | Kenney Impact Sounds — footstep_concrete/metal |
| `step_soil` | Passo na terra da Estufa | Kenney Impact Sounds |
| `jump` | Servo hidráulico | Kenney Sci-fi Sounds |
| `land` | Impacto pesado | Kenney Impact Sounds |
| `interact` | Bip de interação | Kenney Interface Sounds |
| `terminal_breaker` | Clique de disjuntor | Freesound "breaker switch" CC0 |
| `power_on` | Sala ligando (hum crescente) | Kenney Sci-fi Sounds |
| `power_off` | Sistema desligando | Kenney Sci-fi Sounds |
| `log_pickup` | Beep suave de arquivo | Kenney Interface Sounds |
| `pickup` | Coleta de item | Kenney Interface Sounds |
| `damage` | Alarme curto + estática | Kenney Sci-fi Sounds |
| `low_integrity` | Batimento eletrônico (loop) | Freesound "heartbeat electronic" CC0 |
| `flashlight` | Clique da lanterna | Kenney Interface Sounds |
| `door_open` | Porta deslizando | Kenney Sci-fi Sounds |
| `reactor_alarm` | Alarme do reator < 25% (loop) | Freesound "alarm loop" CC0 |
| `ui_move` / `ui_confirm` / `ui_back` | Navegação de menu | Kenney Interface Sounds |
| `sr3_shutdown` | "Gemido" descendente de máquina dormindo | Kenney Sci-fi Sounds |
| `chassis_lost` | Perda do chassi (estática + queda de tom) | Kenney Sci-fi Sounds |
| `respawn` | Backup restaurado (religar suave) | Kenney Sci-fi Sounds |
| `door_close` | Porta fechando | Kenney Sci-fi Sounds |
| `ui_error` | Ação inválida no terminal/menu | Kenney Interface Sounds |
| `dialogue_blip` | Blip por caractere da fala da ÓRBITA | Kenney Interface Sounds |
| `tape_hiss` | Chiado de fita dos logs da Helena (loop) | Freesound "tape hiss" CC0 |
| `sector_restored` | Setor religado (acorde/hum ascendente) | Kenney Sci-fi Sounds |
| `secret_found` | Área secreta revelada | Kenney Interface Sounds |
| `claw_grab` | Garras magnéticas agarrando a parede | Kenney Sci-fi Sounds |
| `dash` | Pulso magnético do dash (F31) | Kenney Sci-fi Sounds |
| `beam` | Feixe de Manutenção (F31) | Kenney Sci-fi Sounds |
| `steam_hiss` | Jato de vapor (F32) | Freesound "steam hiss" CC0 |
| `electric_buzz` | Piso eletrificado (F32, loop) | Freesound "electric buzz" CC0 |
| `spores` | Chiado orgânico (loop) | Freesound CC0 |
| `plant_grow` | Crescimento rápido | Freesound CC0 |
| `v9_alert` | Alerta da V-9 antes de perseguir (F61; hoje toca `ui_error`) | Kenney Sci-fi Sounds |
| `ice_crack` | Gelo fino rachando (F61; hoje toca `land`) | Freesound CC0 "ice crack" |
| `ice_break` | Gelo fino quebrando (F61; hoje toca `door_close`) | Freesound CC0 "ice break" |
| `ice_melt` | Parede de gelo derretendo (F61; hoje toca `spores`) | Freesound CC0 "melting ice drip" |
| Fonte | **Kenney — Sci-Fi Sounds 1.0 (11-10-2020), CC0 1.0 Universal.** Linha do `License.txt`: *"License: (Creative Commons Zero, CC0)"* — http://creativecommons.org/publicdomain/zero/1.0/. Crédito não é obrigatório; creditado mesmo assim no `README.md` |
| Formato | `.wav` 44,1 kHz mono 16 bits. Não há codificador Vorbis nesta máquina, e o `.wav` é **necessário** para o enxame de esporos, que exige `AudioStreamWAV` para forçar o loop |
| Normalização | Por **RMS**, não por pico. O pacote chega todo com pico ≈ −1 dBFS mas com 21 dB de diferença de volume percebido entre os arquivos, então normalizar por pico não resolveria nada |
| Pendentes (6) | `reactor_alarm` · `low_integrity` · `tape_hiss` · `dialogue_blip` · `flashlight` · `step_soil`. O pacote não tem equivalente adequado; procurar em Kenney *Interface/Impact Sounds* ou Freesound CC0 |

Status do pacote: **placeholder** — 39 WAVs sintetizados por `tools/make_audio_placeholders.gd` em `assets/placeholder/audio/sfx/` e `.../music/`; o `AudioManager` cai neles quando o definitivo não existe. Definitivos **pendentes**.

---

<a id="creditos"></a>
## Créditos e licenças (espelhar no `README.md`)

| Asset | Autor | Licença | Link |
|---|---|---|---|
| m5x7 (`assets/fonts/ui_font.ttf`) | Daniel Linssen | livre, crédito solicitado | https://managore.itch.io/m5x7 |

---

<a id="fila-de-geracao"></a>
## Fila de geração — ordem de impacto visual (2026-09-20)

> Depois da demo ficar jogável de ponta a ponta e da passada de polimento (F35), esta é a ordem em que **gerar arte muda mais o jogo**. Todos os prompts já trazem a lição aprendida com o SPR-MU7: **só o objeto pedido, nunca cenário dentro do quadro**, fundo magenta `#FF00FF`, e o agente fatia com `tools/autoslice_sheet.gd`.

| # | Asset | Por que é o próximo | Estado |
|:-:|---|---|---|
| 1 | **TIL-CORE** (tileset do Núcleo) | É o que o jogador olha 100% do tempo na Fase 0. O placeholder é escuro demais e obriga o ambiente a ficar claro, matando o contraste que o GDD pede | placeholder |
| 2 | **TIL-GREENHOUSE** (tileset da Estufa) | Mesma coisa na Fase 1, e é a única área "viva" do jogo | placeholder |
| 3 | **BG-SPACE** (3 camadas de parallax) | O parallax já funciona, mas o espaço visto pela janela está quase preto. Camadas com estrelas e nebulosa visíveis dão profundidade em todas as janelas e no menu | placeholder |
| ~~4~~ | ~~**SPR-SR3** (inimigo)~~ | **fechado — 2ª geração integrada em 2026-09-20.** A 1ª folha virava mancha ao reduzir; a regeração com formas grossas (mesmo 2048×768, mas desenhada em grade larga) resolveu na leitura: silhueta, seis pernas, painéis vermelho/teal, luz âmbar e ponta de solda agora separáveis a 32×16. Números: semitransparentes (α<250) 804/1671 → 795/1748, franja magenta 0 → 0 — o índice mal muda porque ele mede a borda da redução, não o borrão; o ganho está no contraste interno. Fatiada com `--fit=contain` (a aranha é 2,26:1 num quadro 2:1). **Não vale uma 3ª rodada** | **integrado** |
| 5 | **UI-HUD** (ícones e molduras) | O HUD está em tela o tempo todo; ícones legíveis de Integridade/Carga/status elevam a percepção de acabamento | placeholder |
| 6 | **SPR-PROPS** (traje/corpo, caneca, cadeira) | O "primeiro corpo" é hoje uma caixa cinza e a cena depende só da fala — é o momento narrativo mais forte da Fase 0 | placeholder |
| 7 | **FX-SHEET** (nova) | Poeira, faísca e anel de energia hoje são o mesmo quadrado recolorido; e o esporo de ambiente parece o esporo que machuca — risco de confundir o jogador | não existe |
| 8 | **MUS-CORE / MUS-GREENHOUSE / MUS-MENU** | O jogo tem som, mas as trilhas são bipes sintetizados | placeholder |

### Prompt — TIL-CORE (1º)
```
Pixel art tileset for a 2D side-view space station platformer, 16x16 pixel tiles on a strict grid of 8 columns and 4 rows, each tile exactly 16x16 with no gaps.
Row 1 and 2: solid metal floor/wall blocks with every edge and corner variation of a 4-direction bitmask (16 tiles total), light-to-medium cold blue-grey steel with visible panel seams and rivets — IMPORTANT: the base tone must be MID-BRIGHT, not dark, because the game darkens the scene with lighting.
Row 3: a thin one-way metal grating platform, a dark background wall panel, a round window FRAME with a fully transparent (magenta) center, a ventilation grille, a horizontal pipe, a vertical pipe, a ceiling lamp fixture, a yellow-black hazard stripe.
Row 4, first tile: a climbable magnetic wall panel with clear diagonal yellow-grey stripes.
Palette: cold teal-blue and blue-green steel with soft cyan light accents, 16 colors max.
Style: 16-bit pixel art, crisp hard pixels, no anti-aliasing, tiles must line up seamlessly.
Solid flat magenta background (#FF00FF) for empty space and for the window center. No text, no grid lines, no drop shadows, no characters.

IMPORTANT RULE: deliver a GRID OF SEPARATE TILES, not a finished picture. Do not draw a room, a level or a composed scene; do not draw characters, creatures or props resting on the tiles; do not bake lighting, glow or cast shadows into the tiles, because the game lights the scene at runtime. Keep the base tiles at MEDIUM brightness — the engine darkens them — and leave flat magenta (#FF00FF) between every tile.

CRITICAL DELIVERY SIZE: draw the whole atlas SMALL — at most 512x256 pixels in total, which is four times the size it will have in the game (128x64, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

NO EMPTY BORDER INSIDE A TILE: the magenta gaps are separators that go BETWEEN tiles, never inside one. Within its own cell each tile must be filled edge to edge with artwork, because the game lays tiles side by side: a tile with empty or magenta pixels along its own border will show a visible seam in the level.
```

### Prompt — TIL-GREENHOUSE (2º)
```
Pixel art tileset for a 2D side-view overgrown space greenhouse, 16x16 pixel tiles on a strict grid of 8 columns and 4 rows.
Row 1 and 2: solid blocks of metal covered with soil and moss, every edge and corner variation of a 4-direction bitmask (16 tiles) — base tone MID-BRIGHT (the engine darkens it), moss green over rusty metal.
Row 3: thin one-way planter platform, dark background wall with leaves, a glass panel FRAME with fully transparent (magenta) center, a ventilation grille, a horizontal pipe, a vertical pipe, a grow-lamp fixture, a yellow-black hazard stripe.
Row 4, first tile: climbable magnetic wall panel with diagonal yellow-grey stripes.
Palette: moss green, deep green, pink flower accents, rusty metal, 16 colors max.
Style: 16-bit pixel art, hard pixels, no anti-aliasing, seamless tiles.
Solid flat magenta background (#FF00FF). No text, no grid lines, no characters.

IMPORTANT RULE: deliver a GRID OF SEPARATE TILES, not a finished picture. Do not draw a room, a level or a composed scene; do not draw characters, creatures or props resting on the tiles; do not bake lighting, glow or cast shadows into the tiles, because the game lights the scene at runtime. Keep the base tiles at MEDIUM brightness — the engine darkens them — and leave flat magenta (#FF00FF) between every tile.

CRITICAL DELIVERY SIZE: draw the whole atlas SMALL — at most 512x256 pixels in total, which is four times the size it will have in the game (128x64, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

NO EMPTY BORDER INSIDE A TILE: the magenta gaps are separators that go BETWEEN tiles, never inside one. Within its own cell each tile must be filled edge to edge with artwork, because the game lays tiles side by side: a tile with empty or magenta pixels along its own border will show a visible seam in the level.
```

### Prompt — BG-SPACE (3º, gere as três separadas)
```
(1 de 3) Pixel art parallax layer "far": deep space, seamless horizontally, 384x216 proportion. Many small stars of varying brightness on near-black blue, a few brighter. Nothing else. 16-bit pixel art, hard pixels, no anti-aliasing, no text.

(2 de 3) Pixel art parallax layer "mid": a teal and purple nebula, soft and diffuse, plus one small blue-green habitable planet far away in the right third. Transparent (magenta #FF00FF) where there is no nebula. Seamless horizontally, 384x216 proportion, 16-bit pixel art, no text.

(3 de 3) Pixel art parallax layer "near": dark silhouettes of space station trusses, antennas and floating debris along the bottom edge, everything else fully magenta (#FF00FF). Seamless horizontally, 384x216 proportion, 16-bit pixel art, no text.

IMPORTANT RULE: these are distant background layers only. Do not draw station interiors, floors, platforms, doors, characters, HUD or any foreground object.

CRITICAL DELIVERY SIZE: each layer at most 768x432 pixels, which is twice its size in the game (384x216). Do NOT deliver a big image: upscaled art loses its hard pixel edges when reduced. The artwork must reach the left and right edges exactly so the layer repeats seamlessly.
```

### Prompt — FX-SHEET (7º, asset novo)
```
Pixel art effects sprite sheet for a 2D sci-fi game, grid of 8x8 pixel frames, 8 columns and 4 rows, each row one effect animation read left to right:
row 1: a small dust puff expanding and fading (landing dust, pale grey-blue);
row 2: a bright cyan spark burst (item pickup);
row 3: an expanding energy ring (a system powering on, warm amber);
row 4: a floating organic mote, soft and harmless looking, pale green with a white core (ambient greenhouse particle — it must look CLEARLY different from a dangerous spore).
Style: 16-bit pixel art, hard pixels, no anti-aliasing, high contrast so it reads at small size.
Solid flat magenta background (#FF00FF). No text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 512x256 pixels in total, which is four times the size it will have in the game (64x32, frames of 8x8). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
```

> **Como entregar:** salve cada arquivo em `~/Downloads/orbita-assets/<ID>/` e avise o agente com o ID. Ele fatia, remove o fundo, ajusta ao contrato, integra no jogo e registra a licença.

---

<a id="gratis-vs-ia"></a>
## Grátis × IA — prompts e termos de busca para os assets sem prompt

> Para cada asset que estava marcado como **Grátis**, há agora as duas rotas: um prompt de IA
> pronto e onde procurar a versão gratuita, com os termos de busca exatos. Gere os dois e compare.

### Onde cada rota ganha (recomendação, não regra)

| Tipo de asset | Rota recomendada | Por quê |
|---|---|---|
| Personagens e inimigos | **IA** | Casam com um estilo único que já definimos; volume pequeno; o MU-7 e o SR-3 saíram ótimos |
| Props, terminais, portas, coletáveis | **IA** | Poucas peças, estilo específico, e a IA acerta objeto isolado |
| **Tilesets** | **Grátis** (IA só para peças decorativas) | É o calcanhar da IA: ela não mantém **encaixe sem costura** entre dezenas de peças. Um tileset coerente vale mais que um bonito |
| Fundos de parallax | Qualquer uma | Ambas funcionam; grátis é mais rápido |
| Partículas | **Grátis** | Kenney tem pack CC0 pronto; gerar 8×8 na IA é desperdício |
| Ícones de HUD | Empate | IA se você quiser o estilo exato; Kenney se quiser rápido |
| Música e SFX | **Grátis** | A IA de imagem não faz som. Música grátis boa é abundante e licenciada |

### Sites e filtros

| Site | Filtro obrigatório | Link |
|---|---|---|
| Kenney | tudo é **CC0**, sem crédito obrigatório | https://kenney.nl/assets |
| itch.io | marque **Free** e a tag **CC0** | https://itch.io/game-assets/free/tag-tileset |
| OpenGameArt | evite **GPL** para arte | https://opengameart.org |
| Freesound | filtre `license:"Creative Commons 0"` | https://freesound.org |
| Pixabay Music | licença Pixabay, uso livre | https://pixabay.com/music/ |
| incompetech | **CC-BY**: crédito obrigatório no README | https://incompetech.com |

### Termos de busca por asset

| Asset | Termos de busca |
|---|---|
| SPR-SPORE | `particle pack` (Kenney) · `spore`, `pollen particle`, `bioluminescent particle` |
| SPR-PLATFORM | `industrial platformer tileset` · `sci-fi metal platform 16x16` · `moving platform sprite` |
| SPR-DOOR | `sci-fi door sprite sheet` · `bulkhead door pixel art` · `blast door animation` |
| TIL-CORE | `sci-fi space station tileset 16x16` · `metroidvania sci-fi tileset` · `spaceship interior tileset pixel` |
| TIL-GREENHOUSE | `overgrown sci-fi tileset` · `greenhouse tileset pixel art` · `plants lab tileset` · `jungle ruins tileset 16x16` |
| BG-SPACE | `parallax space background pixel` · `seamless starfield parallax` · `nebula parallax layers` |
| UI-HUD | `ui pack` / `1-bit pack` (Kenney) · `pixel ui icons` · `status effect icons pixel` |
| MUS-* | `ambient space drone` · `dark ambient loop` · `sci-fi ambient` · `ethereal ambient loop` |
| SFX-PACK | `servo motor` · `relay switch click` · `metal footstep` · `electrical hum` · `airlock door` · `computer beep` · `tape hiss` |

### Prompts de IA que faltavam

**SPR-SPORE** — tira de 4 partículas de 8×8 (32×8 no total):
```
Pixel art sprite strip of four tiny alien spore particles for a 2D sci-fi game, each exactly 8x8 pixels, in one horizontal row of 4 frames. Each spore is a small irregular floating seed-pod: a soft round body with two or three short bristles, faintly bioluminescent, sickly yellow-green (#B7D35A) with a darker green core and a thin dark outline. The four frames are four slightly different shapes and rotations of the same species, not an animation. Must stay readable at actual size.
IMPORTANT RULE FOR EVERY FRAME: draw ONLY the spore. No walls, floors, ground, plants, scenery, characters, no glow halo bleeding outside the 8x8 cell, no cast shadows.
Style: 16-bit pixel art, hard pixels, no anti-aliasing, 4 colors per spore.
Solid flat magenta background (#FF00FF), no text, no grid lines, no watermark.

CRITICAL DELIVERY SIZE: draw the whole strip SMALL — at most 256x64 pixels in total, which is eight times the size it will have in the game (32x8, frames of 8x8). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no bristle, no clamp, no glow — may touch or cross the edge of its own frame.
```

**SPR-PLATFORM** — plataforma móvel, 48×8, um quadro:
```
Pixel art sprite of a single industrial moving platform for a 2D side-view space station platformer, exactly 48x8 pixels, seen from the side. A narrow metal cargo slab: grated top surface, a thick reinforced edge, two small magnetic clamps underneath at the ends, and a thin cyan indicator strip along the front face so it reads as "powered". Worn steel, cold blue-grey, rust flecks, 1px dark outline.
IMPORTANT RULE: draw ONLY the platform. No wall, no floor, no cables, no rails, no scenery, no characters, no cast shadow.
Style: 16-bit pixel art, hard pixels, no anti-aliasing, limited palette.
Solid flat magenta background (#FF00FF), one single frame, no text, no grid lines.

CRITICAL DELIVERY SIZE: draw it SMALL — at most 384x64 pixels, which is eight times the size it will have in the game (48x8). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no bristle, no clamp, no glow — may touch or cross the edge of its own frame.
```

**MUS-MENU** — para Suno, Udio ou equivalente (a Nano Banana Pro não faz som):
```
Ambient sci-fi menu loop, 60-90 seconds, seamless. A dead space station heard from the inside: low detuned synth drone, slow swelling pad, distant radio static crackle, a faint sonar ping every eight bars, occasional metallic creak. No drums, no vocals, no hummable melody. Melancholic, patient, lonely but not frightening. Very low energy, around 60 BPM, minor key.
```

**MUS-CORE**:
```
Ambient sci-fi exploration loop, 2-3 minutes, seamless. Cold and cavernous: sustained low synth pad, sparse single piano or bell notes far apart, soft machinery hum, and a slow pulse like a dying reactor breathing. No percussion, no vocals, no hummable melody. Restrained, curious, slightly tense. 55-65 BPM, minor key.
```

**MUS-GREENHOUSE**:
```
Ambient loop for an overgrown greenhouse inside an abandoned space station, 2-3 minutes, seamless. The one place still alive: warm analog pad, soft mallet or kalimba notes, gentle water drips, distant wind through leaves, a faint sci-fi shimmer underneath. Slightly hopeful and green, but still lonely. No drums, no vocals. 60-70 BPM.
```

**MUS-CHASSIS** — one-shot, 6 to 10 seconds, must NOT loop:
```
Short ambient sting for a robot chassis shutting down, 6-10 seconds, one-shot with a clean start and a natural decay. A single low bell struck once, a descending detuned synth tail, a brief burst of radio static that fades out. No drums, no vocals, no loop point. Cold, resigned, not tragic.
```

**MUS-GAMEOVER** — one-shot, 10 to 15 seconds, must NOT loop:
```
Ambient game over sting for a space station falling out of orbit, 10-15 seconds, one-shot. A deep sub drone that slowly detunes downward, distant metal groans, one fading alarm tone, then silence. No drums, no vocals, no resolution, no loop point. Final and lonely.
```

**MUS-SECTOR** — one-shot, 15 to 20 seconds, must NOT loop:
```
Uplifting ambient swell for power returning to a dead space station sector, 15-20 seconds, one-shot. Warm pad opening from nothing, clear bell notes arriving one by one, soft electrical hum rising, a gentle shimmer at the end. Hopeful but restrained, still lonely. No drums, no vocals, no loop point.
```

**MUS-CRITICAL** — loop de tensão, 20 to 30 seconds, seamless:
```
Seamless tension layer loop for a failing reactor, 20-30 seconds, designed to play ON TOP of an ambient track. Low pulsing sub around one pulse per second, metallic rattle, faint high whine, no melody and no chords that would clash with another key. No drums, no vocals. Start and end must match exactly for a gapless loop.
```

**UI-FONT** — sem prompt de IA de propósito. Fonte gerada por IA não tem métrica de pixel confiável
nem cobertura de acentos. Rota única: grátis. Já verificamos por script que a **m5x7** tem todos os
acentos do português e que a **m3x6 não tem nenhum** — ver [lição no CLAUDE.md §9].

---

<a id="trilha"></a>
## Trilha sonora — o que precisamos, onde achar, como gerar

> Sete faixas fecham a demo. Três já têm encaixe no jogo; quatro estão sendo criadas na
> [F46](features/F46-trilha-por-momento.md). Todas em `assets/audio/music/<id>.ogg`.

### As sete faixas da demo

| id | Onde toca | Tipo | Duração | Sensação |
|---|---|---|---|---|
| `menu` | splash, menu, opções, FIM DA DEMO | loop | 60–90 s | estação morta ouvida de dentro; paciente, solitária, **não** assustadora |
| `core` | Núcleo Central | loop | 2–3 min | frio e cavernoso; curiosidade com um fio de tensão |
| `greenhouse` | Estufa | loop | 2–3 min | o único lugar vivo; morno e verde, ainda assim sozinho |
| `chassis_lost` | tela CHASSI PERDIDO | **one-shot** | 6–10 s | um desligamento, não uma tragédia — a ÓRBITA trata morte como manutenção |
| `game_over` | PERDA DE ÓRBITA (reator em 0%) | **one-shot** | 10–15 s | aí sim é o fim: queda, silêncio, algo se apagando de vez |
| `sector_restored` | cutscene de religamento | **one-shot** | 15–20 s | **o pico emocional do jogo**; alívio que quase vira esperança |
| `reactor_critical` | estabilidade abaixo de 25% | loop | 20–30 s | camada de tensão por cima da fase; pulso que aperta |

Para a entrega final entram uma por fase nova (Laboratório, Enfermaria, Docas, Núcleo de
Memória, Reator), tema de mini-boss e de boss, e o epílogo.

### Regras técnicas que evitam retrabalho

- **`.ogg`** é o formato preferido; `.wav` e `.mp3` também importam no Godot 4. Não há ffmpeg
  nesta máquina, então **baixe já no formato final**.
- Faixa de **loop** precisa de começo e fim que casem: peça "seamless loop" e **não** aceite
  arquivo com fade in/out embutido — o fade é o que estraga a emenda.
- Faixa **one-shot** (morte, game over, religamento) não leva loop.
- **Sem bateria marcada e sem voz** nas faixas de fase: elas tocam por 10 minutos seguidos e
  qualquer coisa "cantável" vira tortura.
- Mixe **baixo**. O jogo tem bus de música separado e o jogador ajusta nas Opções, mas faixa
  que chega estourada não tem conserto.

### Gerar com IA

A Nano Banana Pro **não faz som** — é imagem. Para música:

| Ferramenta | Melhor para | Nota |
|---|---|---|
| **Suno** (suno.com) | faixas com estrutura, temas de menu e de fim | marque **instrumental**; tem créditos diários grátis |
| **Udio** (udio.com) | ambiente, texturas longas | controle de estilo mais fino |
| **Stable Audio** (stableaudio.com) | **loops e stingers** | feito para áudio curto e emendável; a melhor opção para as quatro faixas novas |
| **ElevenLabs Sound Effects** | stingers e ambiências curtas | não serve para música longa |

Dicas que valem para qualquer uma: escreva **instrumental**, diga o **BPM** e o **modo**
(menor), peça **seamless loop** nas faixas de fase, proíba bateria e voz explicitamente, e gere
**quatro variações** antes de escolher. Os prompts prontos das três faixas de fase estão na
seção [Grátis × IA](#gratis-vs-ia); os das quatro novas ficam na ficha da
[F46](features/F46-trilha-por-momento.md).

### Achar pronto, de graça

| Site | Licença | Por que usar |
|---|---|---|
| **Pixabay Music** — pixabay.com/music | licença Pixabay, uso livre, sem crédito obrigatório | primeira parada; acervo grande de ambiente sci-fi |
| **Free Music Archive** — freemusicarchive.org | filtre **CC0** ou **CC-BY** | bom para temas de menu |
| **incompetech** (Kevin MacLeod) | **CC-BY** — crédito obrigatório no README | acervo enorme, qualidade consistente |
| **OpenGameArt** | evite **GPL** | música pensada para jogo, já em loop |
| **itch.io** — itch.io/game-assets/free | marque Free + CC0 | packs inteiros com coerência entre faixas |
| **Freesound** | filtre `license:"Creative Commons 0"` | camadas e ambiências, não música estruturada |

### Termos de busca por faixa

| Faixa | O que digitar |
|---|---|
| `menu` | `space ambient drone` · `sci-fi menu loop` · `dark ambient pad` · `lonely ambient` |
| `core` | `abandoned station ambient` · `cold sci-fi ambient loop` · `minimal dark ambient` |
| `greenhouse` | `ethereal ambient loop` · `calm space ambient` · `kalimba ambient` · `hopeful ambient` |
| `chassis_lost` | `power down sound` · `shutdown stinger` · `sci-fi failure` |
| `game_over` | `game over ambient` · `sad sci-fi stinger` · `descending drone` |
| `sector_restored` | `power up ambient` · `uplifting sci-fi stinger` · `hopeful swell` |
| `reactor_critical` | `tension loop` · `alarm ambient` · `pulsing dark loop` |

**Em qualquer rota, registre a licença aqui e nos créditos do `README.md`.** Asset sem licença
compatível não entra no repositório — é regra dura do projeto.
