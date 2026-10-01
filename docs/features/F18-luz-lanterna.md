---
id: F18
title: Luz, sombra & lanterna
status: done
scope: demo
block: 2
priority: P0
rubric: ["Luz/Sombra", "Efeitos naturais (campo de visão, clima)"]
depends_on: ["F02", "F05", "F12", "F13", "F17", "F21"]
unblocks: ["F27", "F28", "F29", "F34"]
estimate: 2.5h
last_updated: 2026-09-19
---

# F18 — Luz, sombra & lanterna

## 1. Contexto e objetivo

**Regra de iluminação (pilar visual do GDD):** *a estação é escura por padrão. A luz não é decoração, é informação. Onde tem luz, tem energia; onde tem energia, algo está funcionando.*

Esta feature escurece o mundo com `CanvasModulate`, dá ao MU-7 uma **lanterna** que amplia o campo de visão de 48 px para 128 px consumindo 1 Carga/s, projeta **sombras** a partir dos tiles sólidos (`LightOccluder2D` no TileSet) e liga as lâmpadas do cenário aos sistemas do Terminal de Distribuição (F17) — fechando o ciclo "energia = luz = informação".

É o que transforma o corredor do Núcleo em um lugar assustador quando o jogador desliga a iluminação para abrir a porta, e o que dá peso à decisão da Estufa (luz de crescimento × iluminação do corredor).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 Estilo visual](../design/GDD.md#gdd-2-9-visual) (regra de iluminação, `CanvasModulate` + `Light2D`) · [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (`flashlight` F/LB: drena 1 Carga/s, visão 3 m → 8 m) · [GDD-2.6.2-E](../design/GDD.md#gdd-2-6-2-e) (escuridão total: sem lanterna o jogador não vê buracos) · [GDD-2.6.1 Habilidades](../design/GDD.md#gdd-2-6-1-habilidades) (lanterna é inicial) · [GDD-2.9 Paleta](../design/GDD.md#gdd-2-9-paleta) (azul frio no Núcleo, verde musgo na Estufa) · [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx) (clique + zumbido baixinho)
- **Parâmetros:** `Balance.VISION_RADIUS_OFF` (48), `Balance.VISION_RADIUS_ON` (128), `Balance.FLASHLIGHT_DRAIN` (1 Carga/s) — [GDD-P](../design/GDD.md#gdd-p) · [AJ-002](../design/GDD.md#gdd-ajustes) (1 m = 16 px). Novos (ADR-F18-001): `LIGHT_FADE_TIME`, `AMBIENT_DARK`, `LAMP_RADIUS`, `LAMP_ENERGY`
- **Jornada:** [Etapa 1](../design/JORNADA-DO-HEROI.md#jh-1) (estação escura e silenciosa) · [Etapa 5](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-002](../DECISIONS.md#adr-002) (renderer Compatibility — `Light2D` com sombras e `CanvasModulate` funcionam) · [ADR-003](../DECISIONS.md#adr-003) · [ADR-004](../DECISIONS.md#adr-004) (TileSet escrito pelo agente)
- **Assets:** [FX-LIGHT](../ASSETS.md#fx-light) · [TIL-CORE](../ASSETS.md#til-core) · [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) · [SFX-PACK](../ASSETS.md#sfx-pack) (`flashlight`)

## 3. Critério de avaliação atendido

- **Luz/Sombra:** mundo escuro com luzes 2D reais, sombras projetadas pelos tiles e fontes de luz ligadas à energia.
- **Efeitos naturais (campo de visão, clima):** o **campo de visão** do chassi (48 px sem lanterna, 128 px com), que é literalmente o "efeito natural" pedido — a escuridão como obstáculo.

**Como o avaliador vê:** o apresentador desliga a iluminação do Núcleo no terminal, a sala apaga, ele liga a lanterna (F) e um cone/halo de luz revela o caminho enquanto a barra de Carga cai.

## 4. Escopo

### Inclui
- `CanvasModulate` na cena da fase com a cor de ambiente vinda do JSON da fase (`ambient_color`), default `AMBIENT_DARK`.
- Lanterna: `PointLight2D` filho do MU-7 (`Flashlight`), textura [FX-LIGHT](../ASSETS.md#fx-light) radial; raio `VISION_RADIUS_OFF` sempre (sensor do chassi) e `VISION_RADIUS_ON` quando ligada; transição suave em `LIGHT_FADE_TIME`.
- Ação `flashlight` (F / LB): liga/desliga, emite `flashlight_toggled(on)`, SFX `flashlight`; drena `FLASHLIGHT_DRAIN` Carga/s via `GameState.spend_charge(FLASHLIGHT_DRAIN * delta)`; **desliga sozinha** quando a Carga acaba e não liga com Carga 0.
- Sombras: `shadow_enabled` na lanterna e nas lâmpadas; `LightOccluder2D` por tile sólido no TileSet (camada de oclusão), gerado junto com o TileSet (F21) **apenas** para tiles de borda (máscara ≠ 15).
- `scenes/world/powered_lamp.tscn` (+ `.gd`): lâmpada do cenário (`@` na legenda ASCII) com `PointLight2D`, cor/raio configuráveis pelo JSON da fase e `set_powered(on)` para o Terminal (F17); acende/apaga com fade e SFX `power_on`/`power_off` (silencioso na restauração).
- Ajuste do `light_mask`/`shadow_item_cull_mask` para que o sprite do jogador e as entidades sejam iluminados corretamente.
- Persistência visual: ao recarregar a fase, as lâmpadas nascem no estado correto (via `EnergyNetwork.apply_all(silent = true)`, F17).

### Não inclui
- Lanterna **direcional/cone** e inimigos que enxergam a luz (V-9) — Final (`light_cone.png` fica registrado no ASSETS, mas a demo usa o halo radial).
- Superaquecimento drenando Carga 2× — Final (F48).
- Luz volumétrica, God rays, normal maps, SDF/GI 2D ([ADR-002](../DECISIONS.md#adr-002) não suporta).
- Oclusão dinâmica por entidades móveis (portas/plataformas não projetam sombra na demo).
- Lâmpadas piscando por falha, lanterna com bateria própria — fora de escopo.

## 5. Critérios de aceite

- [x] Com `ambient_color` escuro, áreas sem lâmpada ficam praticamente pretas; o jogador só vê o entorno imediato (48 px).
- [x] `flashlight` liga: raio cresce para 128 px em `LIGHT_FADE_TIME`, SFX toca, `flashlight_toggled(true)` é emitido.
- [x] Com a lanterna ligada, a Carga cai ~1 pt/s (medido no HUD: 10 s ≈ 10 pts).
- [x] Carga chegando a 0 → lanterna desliga sozinha, `flashlight_toggled(false)`; apertar F com Carga 0 não liga (SFX `ui_back`).
- [x] As sombras dos tiles sólidos se movem com a lanterna (QA: dois screenshots com o jogador em posições diferentes mostram sombras diferentes).
- [x] Desligar `lights_core` no terminal (F17) apaga todas as lâmpadas do grupo `core_lights` imediatamente; religar acende.
- [ ] Ao recarregar a fase com `lights_core` desligado, a sala nasce escura e **sem** som de `power_off`. *(API pronta — `set_powered_silent()`; ponta a ponta depende do `EnergyNetwork` da F17)*
- [x] Nenhuma lâmpada ou luz usa número mágico: raio/energia vêm de `Balance` ou do JSON da fase.
- [ ] Desempenho: a Estufa com ~12 lâmpadas + lanterna roda sem queda perceptível de FPS na build Compatibility. *(só medível quando a F29 existir; 2 lâmpadas + lanterna + 3 oclusores rodaram a 60 fps travados no QA)*
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/player/mu7.tscn (+ mu7.gd)     nó Flashlight (PointLight2D) + lógica de toggle/drenagem
scenes/world/powered_lamp.tscn (+ .gd) lâmpada do cenário (char '@')
scenes/levels/level_base.tscn (+ .gd)  CanvasModulate configurado pelo JSON da fase
assets/fx/light_radial.png             gerado pela F05 (tools/make_placeholders.gd)
scripts/core/light_math.gd             class_name LightMath (pura: escala de textura, drenagem)
tests/test_light_math.gd
scenes/dev/light_test.tscn (+ .gd)
```

**Lanterna (`Flashlight`, `PointLight2D`):**
- `texture = assets/fx/light_radial.png` (256×256 radial), `energy = 1.0`, `shadow_enabled = true`, `shadow_filter = SHADOW_FILTER_PCF5`, `blend_mode = BLEND_MODE_ADD`, `color` = ciano pálido (`#cfeaf2`), `position = (0, -16)` (altura do "olho" do chassi).
- Raio efetivo: `texture_scale = LightMath.scale_for_radius(radius, texture_size)` = `radius * 2.0 / 256.0` → 0,375 (48 px) e 1,0 (128 px).
- Toggle em `mu7.gd`:
```gdscript
func _toggle_flashlight() -> void:
    if _flashlight_on:
        _set_flashlight(false)
    elif GameState.charge >= Balance.FLASHLIGHT_DRAIN:
        _set_flashlight(true)
    else:
        AudioManager.play_sfx("ui_back")
```
`_set_flashlight(on)`: `Tween` de `texture_scale` até o alvo em `LIGHT_FADE_TIME`, `AudioManager.play_sfx("flashlight")`, `EventBus.flashlight_toggled.emit(on)`.
- Drenagem (em `_physics_process`): `if _flashlight_on and not GameState.spend_charge(Balance.FLASHLIGHT_DRAIN * delta): _set_flashlight(false)`.
- `flip_h` do sprite **não** move a luz (halo radial é simétrico); o offset horizontal fica em 0.

**`powered_lamp.tscn`:**
```
PoweredLamp (Node2D)         script powered_lamp.gd
├─ Sprite2D                  tile de luminária do tileset (opcional, via JSON)
└─ Light2D (PointLight2D)    texture = light_radial, shadow_enabled = true
```
```gdscript
@export var lamp_color: Color = Color("#bfe6ff")
@export var radius: float = Balance.LAMP_RADIUS
@export var energy: float = Balance.LAMP_ENERGY
@export var powered: bool = true

func set_powered(on: bool) -> void
func set_powered_silent(on: bool) -> void
func configure(params: Dictionary) -> void
```
- `configure` lê `color`, `radius`, `energy`, `group` do JSON da fase (F21) e adiciona o nó ao grupo indicado (ex.: `core_lights`, `gh_corridor_lamps`) — é assim que o Terminal (F17) atinge o conjunto.
- `set_powered`: `Tween` de `energy` 0 ↔ `energy` em `LIGHT_FADE_TIME` + SFX `power_on`/`power_off`; a versão silenciosa aplica direto (usada na restauração).

**`CanvasModulate`:** filho de `level_base`, `color = Color(json.ambient_color)` ou `Balance.AMBIENT_DARK` (`#191d26`). Fases iluminadas (tutorial antes de desligar a luz) ficam escuras **por padrão** e são iluminadas pelas lâmpadas — o jogo nunca clareia o `CanvasModulate` por script.

**Oclusores (TileSet, coordenado com a F21):** o TileSet tem uma camada de oclusão (`occlusion_layer_0`) com um polígono quadrado 16×16 nos tiles **de borda** (máscara de vizinhança ≠ 15). Tiles totalmente cercados não recebem oclusor (não há luz que os alcance e economiza desenho). O gerador de TileSet da F21 recebe esse parâmetro. `light_mask` das luzes = 1; sprites do mundo ficam em `light_mask = 1`; a UI (`CanvasLayer`) não é afetada por luzes.

**`light_math.gd`** (pura):
```gdscript
class_name LightMath
extends RefCounted

static func scale_for_radius(radius: float, texture_size: float) -> float
static func drain_for(delta: float, drain_per_second: float) -> float
static func can_enable(charge: float, drain_per_second: float) -> bool
```

**`light_test.tscn`:** corredor de 3 telas montado por código com tiles sólidos (ou com a fase de teste da F21 quando existir), `CanvasModulate` escuro, duas `powered_lamp` no grupo `test_lamps`, um botão de teclado (`interact`) que chama `set_powered(!on)` nas duas e o MU-7 com lanterna.

### Autoloads / sinais do EventBus
- Emite: `flashlight_toggled(on)`.
- Escuta: nada obrigatório (as lâmpadas são chamadas pelo `EnergyNetwork`; opcionalmente escutam `energy_changed` para telemetria).
- Usa: `GameState.charge`, `GameState.spend_charge`, `Balance`, `AudioManager.play_sfx`.

### Dados (`data/`)
- JSON da fase (F21): `"ambient_color": "#141b1a"`, e por entidade `@`: `{"group": "gh_corridor_lamps", "color": "#bfe6ff", "radius": 64}`.
- JSON de energia (F17): `{"target": "group:gh_corridor_lamps", "action": "power"}`.

### Input actions / camadas de colisão
- Ação `flashlight` (F / LB — [GDD-2.4](../design/GDD.md#gdd-2-4)).
- Sem camadas novas (luzes e oclusores não têm colisão).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [FX-LIGHT](../ASSETS.md#fx-light) | `light_radial.png` 256×256 (lanterna e lâmpadas) | Gradiente radial gerado (é também o definitivo) |
| [TIL-CORE](../ASSETS.md#til-core) / [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Tiles de luminária no cenário + oclusores dos sólidos | Quadrados da paleta (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `flashlight`, `power_on`, `power_off`, `ui_back` | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Constantes novas (ADR-F18-001) no GDD-P + Ajustes e no `balance.gd`.
- [x] **Passo 2** — Garantir `assets/fx/light_radial.png` gerado pela F05 (se faltar, acrescentar ao `make_placeholders.gd`).
- [x] **Passo 3** — `tests/test_light_math.gd` → falha → `scripts/core/light_math.gd` → passa.
- [x] **Passo 4** — `CanvasModulate` no `level_base` lendo `ambient_color`.
- [x] **Passo 5** — `Flashlight` no `mu7.tscn` + toggle, fade, drenagem, auto-desligar, sinal e SFX.
- [x] **Passo 6** — `powered_lamp.tscn` + `configure`/`set_powered` + registro no mapa de entidades da F21 (`@`).
- [ ] **Passo 7** — Camada de oclusão no gerador de TileSet (combinar com a F21) e ajuste de `shadow_filter`. *(`shadow_filter = PCF5` feito; a camada de oclusão do TileSet é da F21 — ver ADR-F18-006)*
- [x] **Passo 8** — `scenes/dev/light_test.tscn`; `tests/scenes.txt`.
- [x] **Passo 9** — Portões + QA; se as sombras deixarem os tiles feios, ajustar (ver ADR-F18-003) e registrar.

## 10. Verificação

- **Testes (`tests/test_light_math.gd`):**
  - `test_scale_for_radius` — `scale_for_radius(48, 256) == 0.375`; `scale_for_radius(128, 256) == 1.0`.
  - `test_drain_for` — `drain_for(0.5, 1.0) == 0.5`; 60 chamadas de `drain_for(1/60, 1)` somam 1,0 (±0,001).
  - `test_can_enable` — `can_enable(0.0, 1.0) == false`; `can_enable(0.5, 1.0) == false` (precisa de pelo menos 1 tick cheio? ver regra: `charge >= drain_per_second`); `can_enable(5, 1) == true`.
  - `test_radius_constants_match_gdd` — `Balance.VISION_RADIUS_OFF == 48` e `VISION_RADIUS_ON == 128` (guarda contra edição acidental).
- **Smoke:** `res://scenes/world/powered_lamp.tscn`, `res://scenes/dev/light_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f18_light.json`; cena `res://scenes/dev/light_test.tscn`):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | — | `f18_01_lampadas_ligadas` | Corredor iluminado pelas duas lâmpadas; MU-7 visível; HUD Carga cheia |
| 20 | `interact` (desliga as lâmpadas) | — | — |
| 40 | — | `f18_02_escuro` | Quase tudo preto; só o halo de 48 px ao redor do MU-7 |
| 50 | `flashlight` | — | — |
| 65 | — | `f18_03_lanterna_on` | Halo grande (128 px) revelando o corredor; sombras atrás dos blocos |
| 66–240 | segurar `move_right` 3 s | — | — |
| 240 | — | `f18_04_sombras_movem` | Mesmas paredes com sombras em ângulo diferente; Carga ~3 pts menor |
| 241–900 | esperar a Carga zerar (cena inicia com Carga baixa: `@export var start_charge := 8.0`) | — | — |
| 900 | — | `f18_05_apagou_sozinha` | Halo pequeno de novo; HUD com Carga 0 |
| 910 | `flashlight` | `f18_06_nao_liga` | Continua escuro (não ligou com Carga 0) |

- **Playtest humano (opcional):** "a escuridão incomoda na medida certa? você sentiu que a lanterna é um recurso, não um botão de conforto?"

## 11. ADRs locais

### ADR-F18-001 — Constantes de luz
- **Contexto:** o GDD define os raios de visão e a drenagem, mas não a cor de ambiente, o fade nem as lâmpadas do cenário.
- **Decisão:** no `Balance` (+ GDD-P/Ajustes): `LIGHT_FADE_TIME = 0.15` s, `AMBIENT_DARK = Color("#191d26")`, `LAMP_RADIUS = 64` px, `LAMP_ENERGY = 0.9`. Cor e raio por lâmpada podem ser sobrescritos no JSON da fase (paleta do setor, [GDD-2.9](../design/GDD.md#gdd-2-9-paleta)).
- **Consequências:** tuning de atmosfera sem tocar em cena; cada setor mantém sua paleta.
- **Data:** 2026-09-19

### ADR-F18-002 — Lanterna radial (não cone) na demo
- **Contexto:** o ASSETS prevê `light_cone.png`, mas cone exige mira/direção e interage com inimigos que ainda não existem (V-9 é do Final).
- **Decisão:** demo usa halo radial com dois raios (48/128 px), exatamente os números do GDD-P.
- **Consequências:** implementação de 1 nó; o cone entra no Final junto com a V-9 (ficha do asset permanece).
- **Data:** 2026-09-19

### ADR-F18-003 — Oclusores só nos tiles de borda
- **Contexto:** oclusor em todo tile sólido custa desenho e deixa paredes internas com artefatos de sombra.
- **Decisão:** o gerador de TileSet (F21) adiciona `occlusion_layer_0` apenas em tiles cuja máscara de vizinhança ≠ 15 (não totalmente cercados).
- **Consequências:** sombras corretas na silhueta do cenário com menos oclusores. Se ainda houver artefato na face iluminada, a saída documentada é reduzir o polígono em 1 px (registrar no log).
- **Data:** 2026-09-19

### ADR-F18-004 — O `CanvasModulate` nunca é clareado por script
- **Contexto:** seria fácil "acender a fase" mudando o ambiente ao religar o setor.
- **Decisão:** a luz vem **sempre** de `Light2D` ligadas a sistemas de energia. O ambiente é fixo por fase.
- **Consequências:** a regra "onde tem luz, tem energia" continua verdadeira; religar o setor (F29) acende lâmpadas, não o ambiente.
- **Data:** 2026-09-19

### ADR-F18-005 — Constantes de luz entraram no `Balance`, ainda não no GDD-P
- **Contexto:** o `balance.gd` já trazia `AMBIENT_DARK`, `LAMP_RADIUS` (96, não 64) e `LAMP_ENERGY` por [AJ-012](../design/GDD.md#gdd-ajustes), mas faltavam o tempo de fade e as cores do ADR-F18-001.
- **Decisão:** acrescentar ao `Balance` exatamente os valores já decididos no ADR-F18-001/§6 desta feature — `LIGHT_FADE_TIME = 0.15`, `LAMP_COLOR = #bfe6ff`, `FLASHLIGHT_COLOR = #cfeaf2`. Nenhum valor foi inventado e nenhum número de luz ficou em script ou `.tscn`.
- **Consequências:** **pendência de documentação**: as três linhas ainda não estão na tabela [GDD-P](../design/GDD.md#gdd-p) (o agente de implementação não edita `docs/design/`). `LAMP_RADIUS` vale 96 px, não os 64 do ADR-F18-001.
- **Data:** 2026-09-19

### ADR-F18-006 — Oclusor no chão faz o chão sombrear a si mesmo
- **Contexto:** na primeira rodada de QA o corredor ficou preto mesmo com as lâmpadas ligadas. Medindo os pixels: com `LightOccluder2D` no polígono do **piso**, a própria superfície fica atrás da aresta do oclusor em relação à luz que vem de cima e cai na sombra dela mesma.
- **Decisão:** oclusor só em **obstáculo vertical** (pilar, parede, coluna) — nunca no polígono do piso ou do teto. Isso reforça e restringe o [ADR-F18-003](#adr-f18-003): "tiles de borda" precisa excluir a face superior do chão, senão a fase inteira nasce preta.
- **Consequências:** a camada `occlusion_layer_0` do TileSet (F21) deve pular os tiles de topo de chão. Registrado para a F21 antes de gerar o TileSet definitivo.
- **Data:** 2026-09-19

### ADR-F18-007 — `AmbientDarkness` como script de `CanvasModulate`
- **Contexto:** a F18 precisa do ambiente escuro em qualquer cena (salas de prova incluídas), e a F21 já colocou um `CanvasModulate` com a cor escrita à mão no `level_base.tscn`.
- **Decisão:** `scenes/world/ambient_darkness.gd` (`class_name AmbientDarkness extends CanvasModulate`) lê `Balance.AMBIENT_DARK` por padrão e expõe `configure(cor)` para o `ambient_color` do JSON da fase. Cenas sem fase (provas, futuras telas) instanciam o script direto.
- **Consequências:** a F21 pode trocar o `CanvasModulate` cru do `level_base.tscn` por este script e apagar a cor literal do `.tscn` — recomendado, não feito aqui para não mexer em arquivo de outra feature em andamento.
- **Data:** 2026-09-19

### ADR-F18-008 — `blend_mode = 0` é ADD (1 é SUB)
- **Contexto:** os `.tscn` de luz nasceram com `blend_mode = 1` por engano (a intenção era "ADD, o segundo da lista").
- **Decisão:** `Light2D.BLEND_MODE_ADD == 0`. Os `.tscn` (`powered_lamp.tscn`, `mu7.tscn`) usam `blend_mode = 0` e o `_ready()` de cada script reafirma `Light2D.BLEND_MODE_ADD` por constante nomeada.
- **Consequências:** nenhuma luz do projeto pode ser escrita com o inteiro cru; use a constante no script.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação (lote F13/F16/F18).
- **O que**: `scripts/core/light_math.gd` (pura) + `tests/test_light_math.gd` (7 casos); `Flashlight` (`PointLight2D`) no `mu7.tscn` com textura `assets/fx/light_radial.png`, `shadow_filter = PCF5`, `blend_mode` ADD, cor `Balance.FLASHLIGHT_COLOR` e `texture_scale` interpolado em `LIGHT_FADE_TIME` entre `VISION_RADIUS_OFF` e `VISION_RADIUS_ON`; toggle/drenagem/auto-desligar + `flashlight_toggled` no `mu7.gd`; `scenes/world/powered_lamp.tscn` + `.gd` (grupo `powered`, `@export terminal_id`/`system_id`, escuta `energy_changed` — [ADR-011](../DECISIONS.md#adr-011) —, `set_powered`/`set_powered_silent`/`configure`); `scenes/world/ambient_darkness.gd`. Sala `tests/qa/scenes/light_sandbox.tscn` com oclusores nos pilares, roteiro `tests/qa/f18_luz_lanterna.json`.
- **Portões**: import 0 erros · 272 testes passando · smoke 36/36 · varreduras vazias.
- **QA visual** (7 capturas lidas pelo agente, + medição de luminância pixel a pixel): com as lâmpadas ligadas há halo no ar e poça de luz no piso; ao emitir `energy_changed(..., false)` as duas lâmpadas **apagam na hora** e sobra só o halo de 48 px do chassi (perfil medido: luz só a ±32 px do MU-7); ligando a lanterna a poça cresce para ±128 px (perfil ±96..128 px) e a Carga cai 8→5 em ~2,3 s (≈1 Carga/s); andando para a direita os **pilares projetam sombras duras que giram com a lanterna**; com Carga 0 a lanterna **desliga sozinha** (halo volta a 48 px) e apertar F de novo não liga; reemitindo `energy_changed(..., true)` as lâmpadas voltam.
- **Pendências**: (1) as três constantes novas ainda não estão na tabela GDD-P (ADR-F18-005); (2) a camada de oclusão do TileSet é da F21 e **não pode** incluir a face superior do chão (ADR-F18-006); (3) o `level_base.tscn` da F21 tem um `CanvasModulate` com a cor literal — trocar por `AmbientDarkness` (ADR-F18-007); (4) restauração silenciosa ao recarregar a fase depende do `EnergyNetwork` (F17).
- **Próximo passo**: F17 chama `set_powered`/`set_powered_silent` pelo `system_id`; F21 gera os oclusores; F28/F29 definem `ambient_color` por fase.
