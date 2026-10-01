---
id: F47
title: Tilesets definitivos (Núcleo e Estufa)
status: done
scope: demo
block: 6
priority: P0
rubric: ["Desenvolvimento de fases", "Luz/Sombra", "Efeitos naturais"]
depends_on: ["F21", "F18", "F24", "F41"]
unblocks: []
estimate: 4h
last_updated: 2026-09-20
---

# F47 — Tilesets definitivos (Núcleo e Estufa)

## 1. Contexto e objetivo

Até aqui as duas fases da demo rodavam com os tiles placeholder gerados por `tools/make_placeholders.gd`: quadrados chapados de uma cor só, com um filete claro na borda. Funcionavam para provar o autotile e a colisão, mas a estação não tinha material nenhum — nem chapa metálica, nem musgo, nem vigia para o espaço. É o item de arte mais visível do jogo, porque cada tela é feita de ~1700 tiles.

Esta feature troca os dois placeholders pelos atlas definitivos ([TIL-CORE](../ASSETS.md#til-core) e [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse)), gerados por IA em folhas grandes e **fatiadas por ferramenta** para a grade de 16 px do jogo, mantendo exatamente o contrato de atlas de 8 colunas que o `LevelParser`/`LevelBuilder` já usa ([F21 §6.4](F21-construtor-fases-ascii.md)).

Ela também fecha um defeito conhecido da F18/F41: **nenhuma lâmpada tinha sprite**. Eram `PointLight2D` no vácuo e o jogador via "luz sem fonte". Agora a `powered_lamp.tscn` carrega um `Sprite2D` com o tile de luminária de teto, com quadro **aceso** e quadro **apagado** — e onde tem luminária apagada, o jogador sabe que existe energia para religar ali.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 Paleta](../design/GDD.md#gdd-2-9-paleta) · [GDD-2.7 Level design](../design/GDD.md#gdd-2-7) · [GDD-2.2](../design/GDD.md#gdd-2-2)
- **Parâmetros:** `Balance.TILE_SIZE` (16) · `Balance.LAMP_*` · `Balance.MAGNETIC_*` ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa 4](../design/JORNADA-DO-HEROI.md#jh-4) (o Núcleo é frio e morto; a Estufa é o único lugar vivo)
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (16 px, filtro nearest) · [ADR-004](../DECISIONS.md#adr-004) (fases em ASCII) · [ADR-005](../DECISIONS.md#adr-005) (placeholder-first) · [ADR-F18-003](F18-luz-lanterna.md) (oclusão só em máscara ≠ 15)
- **Features:** [F21 §6.4](F21-construtor-fases-ascii.md) (contrato do atlas) · [F41](F41-escuridao.md) (calibragem de luz) · [F24](F24-garras-magneticas.md) (parede magnética)

## 3. Critério de avaliação atendido

"Desenvolvimento de fases", "Luz/Sombra" e "Efeitos naturais": é a diferença entre um protótipo de caixas coloridas e um jogo com cara de jogo. Na apresentação, a primeira tela do Núcleo e a chegada na Estufa passam a vender sozinhas a troca de bioma (aço azul frio → musgo e flores).

## 4. Escopo

### Inclui
- `tools/build_tileset_atlas.gd`: ferramenta headless que lê uma folha grande com separadores magenta, detecta a grade, **reempacota no atlas 8×4 de 16 px** do jogo e aplica ganho de brilho com joelho nos altos-luzes.
- `assets/tiles/core_tiles.png` e `assets/tiles/greenhouse_tiles.png` definitivos (128×64 cada).
- Regeneração dos `.tres` por `tools/make_tileset.gd` (passam a apontar para o caminho final, não para o placeholder).
- `Sprite2D` de luminária em `scenes/world/powered_lamp.tscn` com quadro aceso/apagado configurável pelo JSON da fase.
- `tests/test_light_darkness.gd` passa a medir o **tileset definitivo** (antes media o placeholder e não provava nada).
- `tests/test_level_tileset.gd` (novo): trava o **contrato de papéis do atlas** — cada máscara existe, é sólida e **sem buraco**; `(0,2)` tem colisão one-way e desenho só no topo; `(2,2)` tem miolo vazado e moldura; `(1,2)` não tem colisão; o quadro da parede magnética é amarelo; a luminária apagada é mais escura que a acesa.
- Roteiro `tests/qa/f47_tilesets.json` e quatro cenas-sonda em `tests/qa/scenes/`.

### Não inclui
- Trocar a geometria das fases (`data/levels/*.txt`) — continua sendo F28/F29/F43.
- Tiles animados, transição suave entre dois materiais, terrenos do editor.
- Registro de licença no `ASSETS.md` (fica com o humano).
- Sprites de personagens, props e UI (F48 e outras).

## 5. Critérios de aceite

- [x] As 16 variações de borda (bitmask 4-direções) existem nos dois atlas e encaixam **sem costura** entre si (screenshot `f47_04`).
- [x] Plataforma fina (`=`) desenhada no **topo** do tile, com o resto transparente — o jogador vê a grade em que pisa (screenshot `f47_04`).
- [x] Parede de fundo, grade de ventilação, canos e faixa de perigo nos slots da linha 2 do atlas ([F21 §6.4](F21-construtor-fases-ascii.md)).
- [x] Janela (`W`) com miolo **transparente**: o parallax do espaço aparece por trás (screenshot `f47_03`).
- [x] Parede magnética continua listrada de amarelo e brilha, no mesmo índice de atlas `(0,3)` que `magnetic_wall.gd` já usava (screenshot `f47_05`).
- [x] Luminária com sprite: acesa é um tubo branco-ciano que emite luz; apagada é o mesmo corpo cinza, sem brilho (screenshots `f47_01`/`f47_02`).
- [x] `test_light_darkness.gd` mede o tileset **final** e passa (luma dos sólidos ≥ 0,45).
- [x] `test_level_tileset.gd` verde: papéis do atlas no lugar e nenhum tile de máscara com pixel transparente.
- [x] Travessia completa `tests/qa/f29_greenhouse.json` fecha na tela **FIM DA DEMO** (`TEMPO 01:30 · LOGS 1/4 · DADOS 1/4 · MORTES 0 · SEGREDOS 0/4`).
- [x] Portões do `/CLAUDE.md` §6 verdes (658 testes, 76 cenas de smoke, varreduras vazias).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
tools/build_tileset_atlas.gd      fatiador/reempacotador headless (novo)
tools/make_tileset.gd             gerador dos .tres (inalterado)
assets/tiles/core_tiles.png       atlas definitivo do Núcleo (128×64)
assets/tiles/greenhouse_tiles.png atlas definitivo da Estufa (128×64)
scenes/world/powered_lamp.tscn    + nó Fixture (Sprite2D)
scenes/world/powered_lamp.gd      quadro aceso/apagado
tests/qa/f47_tilesets.json
tests/qa/scenes/f47_probe_lamp_off.tscn / _lamp_on / _window / _edges
```

### Comando de geração (reprodutível)
```bash
"$GODOT" --headless --path . -s res://tools/build_tileset_atlas.gd -- \
  --in=<folha do Núcleo>.png --out=res://assets/tiles/core_tiles.png \
  --kind=core --gain=2.00 --magenta=0.14

"$GODOT" --headless --path . -s res://tools/build_tileset_atlas.gd -- \
  --in=<folha da Estufa>.png --out=res://assets/tiles/greenhouse_tiles.png \
  --kind=greenhouse --gain=1.55

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s res://tools/make_tileset.gd
```

### Como a ferramenta funciona
1. Lê a folha, chaveia o magenta (tolerância + família magenta com piso configurável) e **espalha a cor das bordas para dentro do vazio** (12 passes de dilatação) — sem isso o redimensionamento mistura magenta e sobra franja roxa.
2. Detecta a grade por faixas totalmente vazias (linhas e colunas), produzindo a caixa apertada de cada peça.
3. Para cada slot do atlas de destino aplica um descritor: `cell` (linha:coluna da folha), `sub` (recorte normalizado), `mode` (`fill` estica a caixa para 16×16; `top` preserva a proporção e encosta no topo), `rotate`/`flip_*`, `cut_background` (preenchimento por inundação a partir da borda, em resolução cheia) e `unlit`.
4. Aplica ganho linear com **joelho** em 0,72 (os altos-luzes comprimem em vez de estourar) e grava o PNG 128×64.

### Dados (`data/`)
Nada obrigatório. A luminária aceita, por entidade, em `data/levels/<fase>.json`:
`"sheet"` (caminho da folha), `"frame_on"` e `"frame_off"` (índice no atlas de 8 colunas). Padrão: folha do Núcleo, `22` = `(6,2)` acesa e `25` = `(1,3)` apagada.

### Input actions / camadas de colisão
Nenhuma mudança.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [TIL-CORE](../ASSETS.md#til-core) | Todos os tiles do Núcleo Central + luminária | substituído pelo definitivo |
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Todos os tiles da Estufa + parede magnética | substituído pelo definitivo |

O placeholder continua em `assets/placeholder/tiles/` e o `AssetResolver` só cai nele se o definitivo sumir.

## 8. 🧑 Ação humana

Nenhuma para o jogo rodar. **Pendente do humano:** registrar a licença/origem das duas folhas em [`ASSETS.md`](../ASSETS.md) (TIL-CORE e TIL-GREENHOUSE: trocar status `placeholder` → `integrado` e anotar o prompt/gerador usado).

## 9. Plano de execução

- [x] **Passo 1** — Medir as folhas e mapear peça a peça (§13).
- [x] **Passo 2** — Escrever `tools/build_tileset_atlas.gd` e reempacotar as duas para 8×4.
- [x] **Passo 3** — Medir a luma dos sólidos e calibrar o ganho contra o placeholder.
- [x] **Passo 4** — `--import` + `make_tileset.gd`; apontar `test_light_darkness.gd` para o caminho final.
- [x] **Passo 5** — Sprite de luminária (aceso/apagado) na `powered_lamp`.
- [x] **Passo 6** — Portões §6 + QA por screenshot.

## 10. Verificação

- **Testes:** `test_level_tileset.gd` (contrato de papéis do atlas) · `test_light_darkness.gd` (luma do tileset final ≥ 0,45; ambiente ≤ 0,10; produto ≤ 0,06) · `test_light_crowding.gd` (nenhuma luz nova foi criada — o sprite não é `Light2D`) · `test_level_*` e `test_world_scenes.gd` inalterados.
- **Smoke:** as cenas-sonda da F47 seguem o precedente das `dark_probe_*` e **não** entram em `tests/scenes.txt`; `core_hub.tscn` e `greenhouse.tscn` já cobrem os dois tilesets.
- **Roteiro godot-qa:** `tests/qa/f47_tilesets.json`, começando em `res://tests/qa/scenes/f47_probe_lamp_off.tscn`, com `--fixed-fps 60`.
  - `f47_01_nucleo_luminaria_apagada` — luminária cinza, sem brilho, revelada só pela lanterna.
  - `f47_02_nucleo_luminaria_acesa` — mesmo corpo com tubo branco-ciano e halo de luz.
  - `f47_03_nucleo_vigia_parallax` — duas vigias redondas com miolo transparente mostrando o espaço.
  - `f47_04_nucleo_plataforma_e_bordas` — plataforma fina no topo do tile, bordas de bloco encaixando.
  - `f47_05_estufa_parede_magnetica` — coluna listrada de amarelo, brilhando.
  - `tests/qa/f41_escuridao.json` (sonda `dark_probe_core.tscn`) — as quatro combinações escuro/iluminado × Núcleo/Estufa.
  - `tests/qa/f29_greenhouse.json` — a demo inteira até `44_fim_da_demo_estatisticas`.

## 11. ADRs locais

### ADR-F47-001 — A Estufa é reempacotada para 8 colunas, não o código para 10
- **Contexto:** a folha do Núcleo veio com 8 colunas × 4 linhas e a da Estufa com 10 × 5. O `LevelParser.atlas_coords_for_mask` (`mask % 8`, `mask / 8`), o `make_tileset.gd` e o `magnetic_wall.gd` assumem 8 colunas.
- **Decisão:** manter **um único formato de atlas** (8×4 de 16 px) para toda fase e reempacotar a folha da Estufa nele com `tools/build_tileset_atlas.gd`. O número de colunas continua constante no código.
- **Alternativa recusada:** tornar as colunas um dado do tileset (ler de `data/levels/<fase>.json` ou do `.tres`). Isso espalharia um parâmetro por `LevelParser`, `LevelBuilder`, `make_tileset` e `magnetic_wall`, e passaria a permitir um formato por fase — exatamente o que o enunciado da tarefa pede para evitar. A grade da folha bruta é um detalhe de quem desenhou, não do jogo.
- **Consequências:** a folha bruta pode vir em qualquer grade; o mapeamento peça→papel vive numa tabela de constantes da ferramenta (§13), revisável em diff. As peças que sobram (48 na Estufa, 32 no Núcleo) entram nos slots decorativos ou ficam de fora.
- **Data:** 2026-09-20

### ADR-F47-002 — Máscaras faltantes são sintetizadas, não desenhadas de novo
- **Contexto:** nenhuma das duas folhas entrega as 16 variações do bitmask 4-direções. O Núcleo traz 7 bordas limpas (máscaras 0, 1, 3, 5, 9, 11, 14) mais peças de canto interno de um conjunto tipo *blob* que a máscara de 4 bits não sabe usar. A Estufa traz blocos cheios com musgo em posições variadas, sem correspondência 1:1 com máscara nenhuma.
- **Decisão:** duas estratégias, uma por folha.
  - **Núcleo:** usar as 7 peças do artista e derivar as outras 9 por **espelho e rotação** (o bisel metálico é geométrico e aguenta rotação sem parecer errado). Máscara 15 usa a chapa com emenda horizontal.
  - **Estufa:** **compor** cada máscara sobre uma base de chapa lisa, colando a faixa de musgo do topo (46% do tile), a de grama do rodapé (44%), a da esquerda (34%) e a da direita (34%). Como a faixa sai sempre da mesma peça e na mesma posição, tiles vizinhos casam por construção.
- **Consequências:** as 16 máscaras existem e encaixam. O custo é que a Estufa perde as peças de canto diagonal desenhadas à mão (viraram slots decorativos).
- **Data:** 2026-09-20

### ADR-F47-003 — Ganho de brilho com joelho, calibrado contra o placeholder
- **Contexto:** o modelo de luz da F41 foi calibrado contra o placeholder, cuja luma média nos tiles sólidos é **0,62**; `test_light_darkness.gd::test_solid_tiles_are_mid_bright` exige ≥ 0,45. As folhas definitivas chegaram escuras: **0,276** (Núcleo) e **0,363** (Estufa) — 2,2× e 1,7× mais escuras que a calibragem. Como o resultado final é `tile × (ambiente + luz)`, a fase inteira viraria um borrão preto.
- **Decisão:** aplicar ganho linear na geração do atlas (**2,00** no Núcleo, **1,55** na Estufa), com joelho exponencial em 0,72 para os altos-luzes não estourarem em branco chapado. Luma final: **0,529** e **0,552**. Não mexer em `ambient_color` nem nas energias das lâmpadas: com o tileset recalibrado, a iluminação da F41 volta ao ponto em que foi ajustada.
- **Alternativas recusadas:** (a) baixar o limiar do teste — esconderia o problema em vez de resolvê-lo; (b) clarear o `ambient_color` — brilharia o cenário **sem lâmpada**, que é justamente o que a F41 quer ilegível; (c) correção gama — comprime o contraste das sombras, que é o que dá relevo ao metal.
- **Consequências:** o ganho é parâmetro de linha de comando, então a calibragem é refeita em um comando se a arte for trocada. O teste passou a medir o caminho final (`res://assets/tiles/...`), não mais o placeholder.
- **Data:** 2026-09-20

### ADR-F47-004 — A luminária é sprite de tile, e o quadro apagado é gerado
- **Contexto:** a F18 criou `powered_lamp.tscn` só com `PointLight2D`. Sem corpo, a luz não tem fonte; e no escuro o jogador não tem como saber onde existe luminária para religar.
- **Decisão:** `Fixture` (`Sprite2D`) no `powered_lamp.tscn`, com `AtlasTexture` recortada do próprio atlas de tiles (`AssetResolver.atlas`). O quadro aceso é a peça `(6,2)` do contrato ([F21 §6.4](F21-construtor-fases-ascii.md)), com o fundo da chapa removido por inundação para a luminária ficar pendurada. Como a folha não trouxe variante apagada, o quadro `(1,3)` é **gerado** a partir do aceso: dessatura completa e escurece a 0,32 — um tubo cinza dentro do mesmo corpo. A luminária é sempre a do Núcleo (é uma peça da estação, igual nos dois setores); `sheet`/`frame_on`/`frame_off` ficam configuráveis por entidade no JSON.
- **Consequências:** nenhuma `Light2D` nova (o `test_light_crowding` continua válido — o limite de 16 luzes por item de canvas do renderer Compatibility não foi tocado). No escuro a luminária apagada só aparece sob a lanterna, o que é coerente com a F41.
- **Data:** 2026-09-20

### ADR-F47-005 — O contrato do atlas vira teste, não convenção
- **Contexto:** `LevelBuilder.ONE_WAY_TILE/BACKGROUND_TILE/WINDOW_TILE`, `MagneticWall.TILE_COLUMN/ROW` e `SecretWall.tile_column/row` são **coordenadas cruas de atlas**. Regerar a arte com o mapeamento errado transforma silenciosamente a plataforma fina em parede — e nenhum teste pegava isso, porque o único teste que olhava o tileset (`test_light_darkness`) media o **placeholder**.
- **Decisão:** `tests/test_level_tileset.gd` verifica, nos dois tilesets, que cada papel está na coordenada que o código espera **e** que o desenho cumpre o papel (one-way fina no topo, janela vazada, máscara sem buraco, parede magnética amarela, luminária com dois estados).
- **Consequências:** o teste já pagou o preço de existir: pegou que a faixa de musgo do topo da Estufa carregava pixels transparentes da silhueta e abria **buraco em toda superfície de piso** (8 das 16 máscaras). Corrigido trocando `blit_rect` por `blend_rect` na composição das faixas.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Tilesets definitivos integrados
- **Quem**: agente TILES · **O que**: `tools/build_tileset_atlas.gd`, os dois atlas 128×64, `.tres` regenerados, sprite de luminária acesa/apagada, `test_light_darkness.gd` apontando para o caminho final, `test_level_tileset.gd` novo, roteiro e sondas de QA. · **Portões**: 658 testes verdes, 76 cenas de smoke, varreduras vazias, QA lido por screenshot, travessia completa fechando em FIM DA DEMO. · **Próximo passo**: humano registra licença/origem em `ASSETS.md`.

### 2026-09-20 — Buraco no topo das máscaras da Estufa
- **Quem**: agente TILES · **O que**: a faixa de musgo do topo era colada com `blit_rect`, que copia o alfa: onde a silhueta do musgo era transparente na folha, o tile ficava **vazado**, e as 8 máscaras com topo exposto (toda superfície de piso e patamar) abriam buraco. Trocado por `blend_rect`, que preserva a chapa de base por baixo. Pego por `test_level_tileset.gd::test_every_mask_tile_is_solid_and_opaque`, não pelo olho.

## 13. Tabela de mapeamento peça → papel

> Coordenadas `linha:coluna` da **folha bruta**; destino é a coordenada do atlas 8×4 do jogo.

### TIL-CORE — folha 8 colunas × 4 linhas

| Destino | Papel | Peça da folha | Transformação |
|:--:|---|:--:|---|
| máscara 0 `(0,0)` | bloco isolado (4 bordas) | `0:0` | — |
| máscara 1 `(1,0)` | bordas esq+dir+baixo | `0:6` | — |
| máscara 2 `(2,0)` | bordas cima+baixo+esq | `0:6` | rotação 90° |
| máscara 3 `(3,0)` | bordas esq+baixo | `0:4` | — |
| máscara 4 `(4,0)` | bordas cima+dir+esq | `0:6` | espelho vertical |
| máscara 5 `(5,0)` | bordas esq+dir | `0:3` | — |
| máscara 6 `(6,0)` | bordas cima+esq | `0:4` | espelho vertical |
| máscara 7 `(7,0)` | borda esquerda | `0:1` | rotação 270° |
| máscara 8 `(0,1)` | bordas cima+dir+baixo | `0:6` | rotação 270° |
| máscara 9 `(1,1)` | bordas dir+baixo | `0:5` | — |
| máscara 10 `(2,1)` | bordas cima+baixo | `0:3` | rotação 90° |
| máscara 11 `(3,1)` | borda de baixo | `0:2` | — |
| máscara 12 `(4,1)` | bordas cima+dir | `0:5` | espelho vertical |
| máscara 13 `(5,1)` | borda direita | `0:1` | rotação 90° |
| máscara 14 `(6,1)` | borda de cima (piso) | `0:1` | — |
| máscara 15 `(7,1)` | miolo maciço | `1:4` | — |
| `(0,2)` | plataforma fina (one-way) | `1:6` | topo do tile |
| `(1,2)` | parede de fundo | `2:0` | — |
| `(2,2)` | vigia (miolo transparente) | `2:7` | — |
| `(3,2)` | grelha de ventilação | `2:6` | — |
| `(4,2)` | cano horizontal | `3:0` | — |
| `(5,2)` | cano vertical | `3:1` | — |
| `(6,2)` | **luminária acesa** | `3:5` | fundo removido |
| `(7,2)` | faixa de perigo | `1:7` | — |
| `(0,3)` | painel de malha | `3:6` | — |
| `(1,3)` | **luminária apagada** | `3:5` | fundo removido + dessaturada |
| `(2,3)` | cabos | `2:4` | — |
| `(3,3)` | caixa de junção | `2:5` | — |
| `(4,3)` | cotovelo de cano | `3:2` | — |
| `(5,3)` | T de cano | `3:3` | — |
| `(6,3)` | cruzeta de cano | `3:4` | — |
| `(7,3)` | cruz de reforço | `3:7` | — |

**Peças da folha que sobraram:** `0:7`, `1:0`, `1:1`, `1:2`, `1:3`, `1:5` — todas cantos internos de conjunto *blob* (a emenda entre dois blocos vizinhos), que a máscara de 4 bits não distingue.

### TIL-GREENHOUSE — folha 10 colunas × 5 linhas

| Destino | Papel | Peça da folha | Transformação |
|:--:|---|:--:|---|
| máscaras 0–15 `(0,0)`–`(7,1)` | as 16 bordas | base `0:1` (recorte `y 52%–90%`) + faixas `0:1` topo 46%, `0:2` rodapé 44%, `0:3` esquerda 34%, `0:4` direita 34% | composição por lado exposto |
| `(0,2)` | plataforma fina (canteiro) | `1:0` | topo do tile |
| `(1,2)` | parede de fundo | `4:1` | — |
| `(2,2)` | janela de vidro (miolo transparente) | `3:1` | — |
| `(3,2)` | grelha de ventilação | `4:0` | — |
| `(4,2)` | cano vertical | `4:7` | — |
| `(5,2)` | bandeja hidropônica | `2:1` | — |
| `(6,2)` | trepadeira pendurada | `1:6` | topo do tile |
| `(7,2)` | faixa de perigo | `4:8` | — |
| `(0,3)` | **parede magnética** (listras amarelas) | `4:8` | — |
| `(1,3)` | trepadeira | `1:7` | topo do tile |
| `(2,3)` | bandeja com flores | `2:0` | — |
| `(3,3)` | bandeja com mudas | `2:3` | — |
| `(4,3)` | exaustor redondo | `4:3` | — |
| `(5,3)` | painel com trepadeiras | `4:5` | — |
| `(6,3)` | canteiro de madeira | `1:2` | topo do tile |
| `(7,3)` | trepadeira | `1:9` | topo do tile |

**Peças da folha que sobraram:** os cantos diagonais de musgo `0:0`, `0:5`–`0:9`; as bandejas `2:2`, `2:4`, `2:5`, `2:7`, `2:8`; as molduras de vidro `3:0`, `3:2`–`3:9` (só uma é usada); os canteiros `1:1`, `1:3`, `1:4`; as trepadeiras `1:5`, `1:8`; os painéis `4:2`, `4:4`, `4:6`.

**O que a folha não trouxe:** nenhuma das duas tem variante **apagada** de luminária (gerada por código) e a Estufa não tem luminária nenhuma (usa a do Núcleo). Nenhuma das duas trouxe as 16 bordas do bitmask.
