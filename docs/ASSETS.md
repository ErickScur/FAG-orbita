# ASSETS.md — Registro de assets

> Toda arte, fonte, música e som do jogo tem uma ficha aqui. A ficha é o **contrato**: caminho final, dimensões, frames e grade. O código aponta para o caminho final; até o asset definitivo chegar, o placeholder (gerado por `tools/make_placeholders.gd`) ocupa o **mesmo contrato** em `assets/placeholder/`.
>
> Estilo, paleta, template de prompt e pós-processamento: [`ASSET-PIPELINE.md`](ASSET-PIPELINE.md). Para criar uma ficha nova, use a skill `asset-request`.

## Como o humano usa este arquivo

1. Filtre por `Status = pendente` e **Prioridade = A** (entra na demo).
2. **Opção 1 (grátis):** abra o link, baixe, salve em `~/Downloads/orbita-assets/<ID>/` e avise o agente com o ID.
3. **Opção 2 (IA):** copie o **prompt** para o Gemini (Nano Banana Pro), baixe a melhor imagem para `~/Downloads/orbita-assets/<ID>/` e avise o agente.
4. O agente pós-processa (recorte, redimensionamento nearest, redução de paleta, fatiamento), coloca no caminho final, atualiza a cena, registra licença/créditos e muda o status.

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
| [TIL-CORE](#til-core) | Tileset | Núcleo Central | A | Grátis + IA | **integrado** | F21, F28 |
| [TIL-GREENHOUSE](#til-greenhouse) | Tileset | Estufa | A | Grátis + IA | **integrado** | F21, F29 |
| [BG-SPACE](#bg-space) | Camadas parallax | Espaço pelas janelas + menu | A | Grátis ou IA | **integrado** | F26, F07 |
| [UI-LOGO](#ui-logo) | Imagem | Logo ÓRBITA (splash + menu) | A | IA | **integrado** | F03, F07 |
| [UI-FONT](#ui-font) | Fonte | Fonte pixel de toda a UI | A | Grátis | integrado | F05, F07 |
| [UI-HUD](#ui-hud) | Sprite sheet | Molduras, células de Integridade, ícones de status | A | IA ou Grátis | **integrado** | F15, F23 |
| [FX-LIGHT](#fx-light) | Textura | Gradiente radial da lanterna/luzes | A | Gerado | final | F18 |
| [MUS-MENU](#mus-menu) | Música | Trilha do menu | A | IA | **integrado** | F04, F07 |
| [MUS-CORE](#mus-core) | Música | Trilha do Núcleo Central | A | Grátis | **integrado** | F28 |
| [MUS-GREENHOUSE](#mus-greenhouse) | Música | Trilha da Estufa | A | Grátis | **integrado** | F29 |
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
| Status | placeholder |

**Prompt:**
```
Pixel art sprite sheet of a tiny cute irrigation drone called BOTANICO 04 for a 2D space greenhouse game: round white-green body with a small propeller on top, a watering nozzle underneath and a warm yellow lamp in front. Style: 16-bit pixel art, hard pixels, no anti-aliasing. Layout: one row of 16x16 pixel frames, 6 frames: 4 frames hovering bob, 2 frames spraying water mist. Solid flat magenta background (#FF00FF), no text, no grid lines.

IMPORTANT RULE FOR EVERY FRAME: draw ONLY the object described. Never draw walls, floors, ground, ceilings, rooms, scenery, characters, cast shadows or any other object, not even when the description implies one. If a pose or a placement suggests a surface, draw the object alone, floating on the flat magenta background.

CRITICAL DELIVERY SIZE: draw the whole sheet SMALL — at most 384x64 pixels in total, which is four times the size it will have in the game (96x16, frames of 16x16). A large upscaled image loses its hard pixel edges when it is reduced and comes out blurry instead of pixel art. Do NOT deliver a big image.

FRAME MARGIN: leave at least one empty pixel inside every frame on all four sides. Nothing — no antenna, no tool tip, no motion trail, no glow, no leaf — may touch or cross the edge of its own frame.
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
