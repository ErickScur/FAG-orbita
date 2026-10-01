---
id: F41
title: Escuridão de verdade
status: done
scope: demo
block: 6
priority: P0
rubric: ["Luz/Sombra", "Efeitos naturais (campo de visão, clima)"]
depends_on: ["F05", "F18", "F21", "F26", "F35"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F41 — Escuridão de verdade

## 1. Contexto e objetivo

O humano jogou a demo e disse: *"Quando fica escuro, nao fica escura realmente, nao precisa
da lanterna, da pra ver tudo tranquilamente, nao fica nem um pouco escuro."*

Ele está certo, e a causa estava documentada na própria [fila de geração do
`ASSETS.md`](../ASSETS.md#fila-de-geracao): *"o placeholder é escuro demais e obriga o
ambiente a ficar claro, matando o contraste que o GDD pede"*. A compensação tinha sido feita
no lugar errado — em vez de clarear o tileset, tinha-se clareado o `ambient_color` das fases
(`#5a757f` no Núcleo, `#5f7f55` na Estufa: luminância 0,44). Com o ambiente quase cinza-médio,
`Light2D` nenhuma consegue criar contraste e a lanterna vira um botão decorativo — o oposto do
pilar visual do [GDD-2.9](../design/GDD.md#gdd-2-9-visual): *a estação é escura por padrão; a
luz não é decoração, é informação*.

Esta feature **inverte a compensação**: o tileset placeholder passa a ter base de brilho médio
(a regra que o próprio `ASSETS.md` já manda: *"the base tone must be MID-BRIGHT, not dark,
because the game darkens the scene with lighting"*), o ambiente das fases fica realmente
escuro, e as lâmpadas e a lanterna passam a ser a única fonte de informação. O trecho escuro do
Núcleo — que existe para **ensinar** a lanterna ([GDD-2.6.2-E](../design/GDD.md#gdd-2-6-2-e)) —
também escurece de verdade; lá o jogo continua avisando, aqui o assunto é só a luz.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 Estilo visual](../design/GDD.md#gdd-2-9-visual) (regra de iluminação) ·
  [GDD-2.9 Paleta por setor](../design/GDD.md#gdd-2-9-paleta) (azul frio no Núcleo, verde
  musgo + rosa na Estufa) · [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (lanterna: visão
  3 m → 8 m, 1 Carga/s) · [GDD-2.6.2-E](../design/GDD.md#gdd-2-6-2-e) (escuridão total)
- **Parâmetros:** `Balance.VISION_RADIUS_OFF` (48), `Balance.VISION_RADIUS_ON` (128),
  `Balance.LAMP_RADIUS` (96), `Balance.LAMP_ENERGY` (0.9), `Balance.AMBIENT_DARK`,
  `Balance.BACKGROUND_TINT`, `Balance.LIGHT_FADE_TIME` ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa 1](../design/JORNADA-DO-HEROI.md#jh-1) (a estação escura e silenciosa)
- **ADRs:** [ADR-002](../DECISIONS.md#adr-002) (Compatibility) · [ADR-003](../DECISIONS.md#adr-003)
  (384×216) · [ADR-005](../DECISIONS.md#adr-005) (placeholder-first) ·
  [ADR-F18-001](F18-luz-lanterna.md#adr-f18-001) · [ADR-F18-004](F18-luz-lanterna.md#adr-f18-004)
  (o `CanvasModulate` nunca é clareado por script)
- **Assets:** [TIL-CORE](../ASSETS.md#til-core) · [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) ·
  [FX-LIGHT](../ASSETS.md#fx-light)

## 3. Critério de avaliação atendido

- **Luz/Sombra:** agora a escuridão é medível — sem lanterna o cenário fora do sensor do chassi
  marca ~0,02–0,03 de luminância (invisível); com ela, ~0,27 na poça de luz, com sombras duras
  projetadas pelas bordas das plataformas.
- **Efeitos naturais (campo de visão):** o campo de visão passa a ser um obstáculo real; a
  lanterna é recurso, não conforto.

**Como o avaliador vê:** o apresentador gasta a única unidade de energia do Núcleo na porta, a
sala **apaga de verdade**, e ele só consegue atravessar acendendo a lanterna.

## 4. Escopo

### Inclui
- Tileset placeholder (`TIL-CORE`, `TIL-GREENHOUSE`) com **base de brilho médio**: novas chaves
  `tile` e `tile_back` por paleta em `tools/placeholders.json`, consumidas por `_draw_tile`.
- `ambient_color` de todas as fases escurecido; `ambient_restored` da Estufa recalibrado.
- `radius`/`energy` de todas as lâmpadas das fases recalibrados.
- Queda da textura de luz (`FX-LIGHT`) trocada de quadrática pura para **platô + smoothstep**,
  para a poça de luz ter miolo útil em vez de um pontinho.
- Lanterna com duas energias: **sensor** (fraco, 48 px) e **feixe** (forte, 128 px), com fade.
- Suíte `tests/test_light_darkness.gd` que trava os limites (ambiente escuro, tileset claro,
  produto dos dois ilegível, lâmpadas dentro da faixa).
- Sondas de QA (`tests/qa/scenes/dark_probe*`) que abrem a fase real num ponto escolhido e
  ligam/desligam sistemas de energia, para a medição ser repetível.

### Não inclui
- Arte definitiva dos tilesets (continua na [fila de geração](../ASSETS.md#fila-de-geracao)).
- Mexer em geometria, entidades, gatilhos ou no `.txt` das fases (outra rodada reforma a Estufa).
- Lanterna em cone, oclusão dinâmica, inimigos que enxergam a luz — Final.
- Mover as constantes novas para `scripts/core/balance.gd` (arquivo de outro agente nesta
  rodada — ver [ADR-F41-004](#adr-f41-004)).

## 5. Critérios de aceite

- [x] Num trecho sem lâmpada, o cenário fora do alcance do sensor fica **ilegível** sem a
      lanterna (medido: 0,019 no Núcleo, 0,035 na Estufa; 0 % dos pixels acima de 0,12).
- [x] Com a lanterna, a mesma região vira legível (perto do MU-7: 0,109 → 0,313 no Núcleo,
      0,047 → 0,267 na Estufa; 6,7 % → 88 % dos pixels acima de 0,12 na Estufa).
- [x] Com as luzes ligadas, a fase continua **bonita e legível**, sem estourar nem virar cinza
      (Núcleo iluminado: cenário 0,104, região longe do jogador 0,116 com 48,7 % legível).
- [x] O tileset placeholder tem base de brilho médio (sólidos: 0,638 no Núcleo, 0,605 na
      Estufa — antes 0,260 e 0,313), e os tiles continuam distinguíveis entre si.
- [x] Paletas de setor preservadas: azul frio no Núcleo, verde musgo na Estufa.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
tools/placeholders.json                  chaves tile / tile_back nas paletas core e greenhouse
tools/make_placeholders.gd               _draw_tile reescrito; _draw_radial com platô
scenes/player/mu7.gd                     FLASHLIGHT_ENERGY / SENSOR_ENERGY + tween de energy
data/levels/*.json                       ambient_color, ambient_restored, radius, energy
tests/test_light_darkness.gd             limites de escuridão travados
tests/qa/scenes/dark_probe.gd            sonda: abre a fase real num tile e liga/desliga sistemas
tests/qa/scenes/dark_probe_core.tscn             Núcleo com lights_core DESLIGADO, tile 43,11
tests/qa/scenes/dark_probe_core_lit.tscn         Núcleo com lights_core LIGADO, tile 16,11
tests/qa/scenes/dark_probe_greenhouse.tscn       Estufa, sala sem lâmpada, tile 10,17
tests/qa/scenes/dark_probe_greenhouse_lit.tscn   Estufa com corridor_light e grow_light ligados
tests/qa/f41_escuridao.json              roteiro das 6 capturas
```

### Valores — antes → depois

| O quê | Antes | Depois |
|---|---|---|
| `ambient_color` do Núcleo | `#5a757f` (luma 0,440) | `#0d1219` (luma 0,068) |
| `ambient_color` da Estufa | `#5f7f55` (luma 0,440) | `#0d1410` (luma 0,067) |
| `ambient_restored` da Estufa | `#8fbf7f` (luma 0,690) | `#3d5a36` (luma 0,319) |
| `ambient_color` das salas de prova | `#191d26` (luma 0,113) | `#0d1219` (luma 0,068) |
| Tileset sólido — Núcleo | luma média **0,260** | **0,638** |
| Tileset sólido — Estufa | luma média **0,313** | **0,605** |
| Cor de parede de fundo (`tile_back`) | não existia (usava `base`) | `#6E8496` / `#6C8A5E` |
| Lâmpadas do Núcleo | `radius 160`, `energy 1.6` | `radius 96`, `energy 1.4` |
| Lâmpada de emergência do Habitacional | `radius 128`, `energy 1.8` | `radius 80`, `energy 1.5` |
| Lâmpadas da Estufa | `radius 140–150`, `energy 1.5–1.7` | `radius 96`, `energy 1.4` |
| Queda da textura de luz | `(1 − d)²` (alfa médio 0,167) | platô 0,25 + smoothstep (alfa médio 0,419) |
| Energia da lanterna | 1,0 fixa (sensor e feixe) | sensor 0,7 · feixe 1,5, com fade |

### Autoloads / sinais do EventBus
- Nada novo. A lanterna continua emitindo `flashlight_toggled(on)`; as lâmpadas continuam
  escutando `energy_changed`.

### Dados (`data/`)
- `data/levels/<fase>.json`: só os campos de luz (`ambient_color`, `ambient_restored`,
  `ambient_motes` e `radius`/`energy`/`color` das entidades de lâmpada).

### Input actions / camadas de colisão
- Nenhuma mudança.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [TIL-CORE](../ASSETS.md#til-core) | Tiles do Núcleo com base de brilho médio | regerado por `tools/make_placeholders.gd` |
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Idem, Estufa | regerado |
| [FX-LIGHT](../ASSETS.md#fx-light) | `light_radial.png` com nova queda | regerado (é também o definitivo) |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Medir o tileset placeholder atual e confirmar o diagnóstico do `ASSETS.md`.
- [x] **Passo 2** — Chaves `tile`/`tile_back` nas paletas e `_draw_tile` reescrito; regerar.
- [x] **Passo 3** — Escurecer `ambient_color`/`ambient_restored` e recalibrar as lâmpadas.
- [x] **Passo 4** — Corrigir a queda da textura de luz e separar sensor × feixe da lanterna.
- [x] **Passo 5** — Sondas de QA + roteiro; capturar e **medir** as seis situações.
- [x] **Passo 6** — `tests/test_light_darkness.gd` travando os limites.
- [x] **Passo 7** — Portões §6.

## 10. Verificação

- **Testes (`tests/test_light_darkness.gd`):**
  - `test_ambient_of_playable_levels_is_dark` — luminância de `ambient_color` ≤ 0,10.
  - `test_solid_tiles_are_mid_bright` — luminância média das 2 primeiras linhas do atlas ≥ 0,45.
  - `test_unlit_scenery_is_illegible` — ambiente × tileset ≤ 0,06.
  - `test_restored_ambient_stays_readable` — `ambient_restored` acima de 0,10 e abaixo de 0,50.
  - `test_lamps_stay_inside_the_tuned_range` — raio 48–128 px, energia 0,8–2,0.
- **Smoke:** as sondas não entram em `tests/scenes.txt` (arquivo disputado nesta rodada); as
  fases reais `core_hub.tscn` e `greenhouse.tscn` já estão na lista e passam.
- **Roteiro godot-qa** (`tests/qa/f41_escuridao.json`; cena inicial
  `res://tests/qa/scenes/dark_probe_core.tscn`, `--fixed-fps 60`):

| Frame | Cena / input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 40 | Núcleo, `lights_core` desligado, tile 43,11 | `f41_01_nucleo_escuro_sem_lanterna` | Quase tudo preto; só o halo de 48 px do chassi |
| 50 | `flashlight` | — | — |
| 80 | — | `f41_02_nucleo_escuro_com_lanterna` | Parede, piso e vão do corredor revelados num raio de 128 px |
| 90 | → sonda da Estufa (sala sem lâmpada, tile 10,17) | — | — |
| 140 | — | `f41_03_estufa_escura_sem_lanterna` | Sala praticamente invisível |
| 150 | `flashlight` | — | — |
| 180 | — | `f41_04_estufa_escura_com_lanterna` | Piso, plataformas finas e **sombras duras** das bordas |
| 190 | → sonda do Núcleo iluminado (tile 16,11) | — | — |
| 240 | — | `f41_05_nucleo_iluminado` | Sala legível em azul frio, poça de luz no teto, cantos ainda escuros |
| 250 | → sonda da Estufa iluminada (tile 12,7) | — | — |
| 300 | — | `f41_06_estufa_iluminada` | Sala do Nó legível em verde musgo, sem estourar |

- **Medição de luminância** (script headless com `Image.load_from_file`, luma
  `0,2126 R + 0,7152 G + 0,0722 B`; caixas em coordenadas da captura de 384×216):

| Situação | Cenário `y 40–172` | Longe do MU-7 `x 8–112, y 110–172` | Perto do MU-7 `x 150–235, y 132–170` |
|---|---:|---:|---:|
| Núcleo escuro, sem lanterna | 0,039 (4,3 % legível) | **0,019** (0 % legível) | 0,109 |
| Núcleo escuro, com lanterna | 0,098 (26,7 %) | 0,042 | **0,313** (93,5 %) |
| Estufa escura, sem lanterna | 0,046 (7,5 %) | **0,035** (0 % legível) | 0,047 (6,7 %) |
| Estufa escura, com lanterna | 0,101 (26,6 %) | 0,043 | **0,267** (88,0 %) |
| Núcleo iluminado | 0,104 (28,2 %) | 0,116 (48,7 %) | — |
| Estufa iluminada | 0,083 (21,2 %) | 0,031 | — |

- **Playtest humano:** "sem a lanterna você consegue dizer onde fica o chão?" A resposta tem
  de ser não.

## 11. ADRs locais

<a id="adr-f41-001"></a>
### ADR-F41-001 — A compensação vai no tileset, não no ambiente
- **Contexto:** o placeholder escuro tinha empurrado o `ambient_color` das fases para
  luminância 0,44, o que anula qualquer `Light2D` e contraria [GDD-2.9](../design/GDD.md#gdd-2-9-visual).
- **Decisão:** o tileset placeholder passa a ter base de brilho médio (chaves `tile` e
  `tile_back` por paleta) e o `ambient_color` cai para ~0,068. O produto dos dois (0,043) é o
  "preto" do jogo, e é isso que o teste trava.
- **Consequências:** quando a arte definitiva chegar, ela **tem** de respeitar o mesmo contrato
  de brilho — o prompt do `ASSETS.md` já diz `MID-BRIGHT`, e agora há teste que reprova o
  contrário. Nenhum `ambient_color` precisa ser tocado de novo.
- **Data:** 2026-09-20

<a id="adr-f41-002"></a>
### ADR-F41-002 — A textura de luz precisa de platô
- **Contexto:** `light_radial.png` era gerada com alfa `(1 − d)²`. O alfa **médio** sobre o
  disco é 0,167, ou seja, 83 % da energia da luz se perdia na queda: a poça de luz de 128 px
  chegava ao olho como um halo de ~48 px, e aumentar `energy` só estourava o miolo.
- **Decisão:** alfa passa a ser `smoothstep` sobre `(1 − d) / (1 − 0,25)` — platô de alfa 1 até
  25 % do raio, queda suave até a borda. Alfa médio 0,419 (2,5× mais luz para a mesma energia),
  borda ainda macia.
- **Consequências:** lâmpadas e lanterna usam a mesma textura, então as duas ganharam alcance
  útil; as energias foram recalibradas para baixo na mesma passada. A escala continua sendo
  `LightMath.scale_for_radius`, então `VISION_RADIUS_*` e `LAMP_RADIUS` seguem significando
  pixels de raio.
- **Data:** 2026-09-20

<a id="adr-f41-003"></a>
### ADR-F41-003 — Sensor e feixe são duas energias, não dois raios
- **Contexto:** a lanterna desligada mantinha `energy = 1.0` e só encolhia o raio. Com o
  ambiente realmente escuro, o "sensor" de 48 px ficava tão brilhante quanto o feixe e
  entregava de graça o entorno do MU-7.
- **Decisão:** `SENSOR_ENERGY = 0.7` e `FLASHLIGHT_ENERGY = 1.5`; `_set_flashlight` interpola
  `texture_scale` **e** `energy` em paralelo, em `Balance.LIGHT_FADE_TIME`.
- **Consequências:** o sensor vira um brilho interno fraco e o feixe, luz de verdade. Medido:
  perto do MU-7 a Estufa vai de 0,047 para 0,267 ao acender.
- **Data:** 2026-09-20

<a id="adr-f41-004"></a>
### ADR-F41-004 — Constantes provisórias em `mu7.gd`
- **Contexto:** `FLASHLIGHT_ENERGY`, `SENSOR_ENERGY` e a nova queda da textura são números de
  gameplay e deveriam morar em `scripts/core/balance.gd` — que pertence a outro agente nesta
  rodada (ver contrato da rodada "menos informação, mais puzzle").
- **Decisão:** ficam como `const` nomeadas em `scenes/player/mu7.gd` e `RADIAL_PLATEAU` em
  `tools/make_placeholders.gd`, com pedido explícito de migração no relatório.
- **Consequências:** **dívida aberta** — mover `FLASHLIGHT_ENERGY = 1.5`, `SENSOR_ENERGY = 0.7`
  para o `Balance` e para a tabela [GDD-P](../design/GDD.md#gdd-p), e reavaliar
  `Balance.AMBIENT_DARK` (`#191d26`, luma 0,113) que hoje é o *default* de cenas sem fase e
  ficou claro demais para o novo tileset — o valor coerente é `#0d1219`.
- **Data:** 2026-09-20

<a id="adr-f41-005"></a>
### ADR-F41-005 — A sonda de QA abre a fase real, não uma sala de prova
- **Contexto:** medir escuridão numa sala de prova não prova nada sobre a fase entregue, e
  chegar a pé até o trecho escuro do Núcleo custa ~350 frames de caminhada mais uma fala
  travante — roteiro frágil, exatamente a armadilha da lição §9.
- **Decisão:** `dark_probe.gd` instancia `core_hub.tscn`/`greenhouse.tscn` de verdade,
  silencia a fala de entrada pela flag `dlg_<id>`, teleporta o MU-7 para um tile escolhido e
  emite `energy_changed` para ligar/desligar os sistemas que interessam.
- **Consequências:** a medição usa o tileset, o ambiente e as lâmpadas reais. O log do QA
  imprime a posição do jogador em cada captura (43,12 · 10,19 · 16,12 · 12,8), o que permite
  conferir que o roteiro não envelheceu.
- **Data:** 2026-09-20

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-20 — Feature criada e implementada
- **Quem**: agente C da rodada "menos informação, mais puzzle".
- **O que**: inversão da compensação de brilho (tileset claro + ambiente escuro), queda da
  textura de luz corrigida, sensor e feixe da lanterna separados, lâmpadas recalibradas,
  `tests/test_light_darkness.gd`, sondas e roteiro de QA.
- **Portões**: import 0 erros · 598 testes passando (1 falha pré-existente de outro agente:
  `test_level_greenhouse.gd::test_objective_and_dialogue_ids_exist`, falas `gh_spores`,
  `gh_terminal_first` e `gh_dark_corridor` apagadas pela F39 enquanto os gatilhos da fase
  ainda as citam) · smoke 71/71 · varreduras vazias.
- **QA visual**: 6 capturas lidas pelo agente e medidas pixel a pixel (tabela da §10).
- **Pendências**: constantes provisórias ([ADR-F41-004](#adr-f41-004)); arte definitiva dos
  tilesets e do `FX-SHEET` para a escuridão ficar bonita e não só escura.
- **Próximo passo**: migrar as constantes para o `Balance`/GDD-P e gerar TIL-CORE e
  TIL-GREENHOUSE definitivos com base de brilho médio.
