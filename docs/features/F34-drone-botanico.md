---
id: F34
title: Drone BOTÂNICO 04
status: not-started
scope: stretch
block: 5
priority: P2
rubric: ["Movimento aleatório de NPCs"]
depends_on: ["F12", "F18", "F21", "F29"]
unblocks: []
estimate: 1h
last_updated: 2026-09-19
---

# F34 — Drone BOTÂNICO 04

## 1. Contexto e objetivo

**BOTÂNICO 04** é o único "aliado" vivo da Demo: um pequeno drone de irrigação que sobrou na Estufa, **vagueia sem rumo fixo** pelo corredor e **ilumina caminhos** ([GDD-2.7-F1](../design/GDD.md#gdd-2-7-f1), [Jornada — personagens](../design/JORNADA-DO-HEROI.md#jh-personagens)). Ele não ataca, não é atacado e não resolve puzzle nenhum: é presença. Num jogo cujo terceiro pilar é a **AUSÊNCIA**, um bichinho de metal que ainda rega plantas mortas faz um trabalho emocional enorme — e, mecanicamente, alivia um pouco a escuridão do corredor superior.

Entrega o item **Movimento aleatório de NPCs** da rubrica: o drone escolhe destinos aleatórios dentro de um raio (em torno da própria base quando sozinho, e em torno do MU-7 quando ele chega perto), com pausas e mudanças de direção imprevisíveis.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7-F1 — Estufa (BOTÂNICO 04, drone de irrigação que segue ÓRBITA e ilumina caminhos)](../design/GDD.md#gdd-2-7-f1) · [GDD-2.9 estilo visual (a luz é informação)](../design/GDD.md#gdd-2-9-visual) · [GDD-2.2 nós previstos](../design/GDD.md#gdd-2-2)
- **Parâmetros:** `Balance.TILE_SIZE`, `Balance.WALK_SPEED` (referência de ritmo) — [GDD-P](../design/GDD.md#gdd-p). **Novos (ADR-F34-002):** `Balance.DRONE_SPEED`, `Balance.DRONE_WANDER_RADIUS`, `Balance.DRONE_RETARGET_TIME`, `Balance.DRONE_FOLLOW_RADIUS`.
- **Jornada:** [Personagens (BOTÂNICO 04)](../design/JORNADA-DO-HEROI.md#jh-personagens) · [Etapa 5 — Testes e Aliados (aliados: logs da Helena e o BOTÂNICO 04)](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-000](../DECISIONS.md#adr-000) · [ADR-005](../DECISIONS.md#adr-005) · [ADR-007](../DECISIONS.md#adr-007) (teste com RNG semeado) · [ADR-009](../DECISIONS.md#adr-009)
- **Features vizinhas:** [F18 — Luz, sombra & lanterna](F18-luz-lanterna.md) (o drone é uma fonte de luz), [F29 — Estufa](F29-fase-estufa.md) (o `b` em `31,17`, no corredor escuro), [F21](F21-construtor-fases-ascii.md) (legenda `b`), [F19](F19-dialogo-logs.md) (a fala da primeira aproximação).

## 3. Critério de avaliação atendido

**Movimento aleatório de NPCs** ([rubrica](../ENTREGAS.md#rubrica)). Na apresentação: no corredor superior da Estufa, o drone está flutuando em ziguezague pelo próprio canto, com um facho amarelo no chão; quando o MU-7 se aproxima, ele "acorda", solta um bipe e passa a acompanhá-lo **sem seguir em linha reta** — ele erra, dá voltas, para, escolhe outro ponto. Duas execuções seguidas nunca desenham o mesmo caminho.

## 4. Escopo

### Inclui
- `scenes/world/botanico_drone.tscn` + `botanico_drone.gd`: `CharacterBody2D` voador (sem gravidade), colidindo só com paredes.
- Vagueio aleatório: escolhe um ponto ao acaso dentro de `Balance.DRONE_WANDER_RADIUS` em torno da **âncora**, anda até ele, e troca de destino ao chegar ou a cada `Balance.DRONE_RETARGET_TIME`.
- Âncora dinâmica: a posição de nascimento enquanto o MU-7 estiver longe; a posição do MU-7 quando ele entra em `Balance.DRONE_FOLLOW_RADIUS` (é assim que ele "segue ÓRBITA" **e** se move ao acaso).
- `PointLight2D` amarelo-quente que ilumina o corredor (e ajuda de verdade quando as LUZES DO CORREDOR estão desligadas pelo puzzle).
- Animações `hover` (4f) e `spray` (2f) com bobbing senoidal leve.
- Fala curta da ÓRBITA no primeiro encontro (`gh_botanico`).
- Lógica pura `scripts/core/wander_logic.gd` com `RandomNumberGenerator` **injetado** (semeado nos testes → resultado determinístico).

### Não inclui
- Pathfinding (`NavigationAgent2D`): o drone é um voador burro que esbarra e escolhe outro ponto.
- Atravessar de zona (ele fica no andar em que nasceu) e seguir o jogador para outra cena.
- Regar plantas de verdade / acelerar o crescimento da [F25](F25-plataformas-moveis-planta.md), interagir com esporos ou com a SR-3.
- Dano, vida, ou ser desligado pelo Feixe ([F31](F31-dash-feixe.md)).
- Segundo drone ou drone no Núcleo Central.

## 5. Critérios de aceite

- [ ] O drone nasce no tile `b` (`31,17` da Estufa) e flutua em torno dele, mudando de direção de forma imprevisível, sem sair do corredor.
- [ ] Ele **não** atravessa paredes nem fica preso nelas (ao bater, escolhe outro destino em até `Balance.DRONE_RETARGET_TIME`).
- [ ] Com o MU-7 a menos de `Balance.DRONE_FOLLOW_RADIUS`, o drone passa a vaguear em torno **dele**, acompanhando sem grudar.
- [ ] Afastando-se, o drone volta a vaguear perto da própria base (não persegue pela fase inteira).
- [ ] A luz do drone ilumina o chão o bastante para revelar um dos buracos do corredor escuro.
- [ ] Duas execuções do mesmo roteiro de QA produzem trajetos **diferentes** (aleatoriedade real em jogo) — e, com RNG semeado, o teste produz sempre o mesmo resultado.
- [ ] O primeiro encontro dispara `gh_botanico` uma única vez.
- [ ] Sem esta feature, a Estufa continua jogável (o `b` é tratado como tile vazio — [ADR-F29-003](F29-fase-estufa.md)).
- [ ] `tests/test_wander_logic.gd` verde.
- [ ] Portões do `/CLAUDE.md` §6 verdes
- [ ] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/botanico_drone.tscn (+ botanico_drone.gd)
  BotanicoDrone (CharacterBody2D)   collision_layer = 0 · collision_mask = 1 (world) · motion_mode = FLOATING
  ├─ CollisionShape2D               CircleShape2D raio 5
  ├─ AnimatedSprite2D               SPR-BOTANICO 16×16: hover (4f), spray (2f)
  ├─ Lamp (PointLight2D)            FX-LIGHT, cor #ffd98a, texture_scale 0.45, energy 0.9
  └─ Sense (Area2D)                 CircleShape2D raio Balance.DRONE_FOLLOW_RADIUS · mask = 2 (player)
scripts/core/wander_logic.gd        class_name WanderLogic (RefCounted, só static)
```
```gdscript
class_name WanderLogic
extends RefCounted

static func pick_target(anchor: Vector2, radius: float, rng: RandomNumberGenerator) -> Vector2: ...
    # ângulo aleatório 0..TAU, distância aleatória 0..radius
static func step(position: Vector2, target: Vector2, speed: float, delta: float) -> Vector2: ...
    # avança no máximo speed*delta em direção ao alvo, sem ultrapassar
static func reached(position: Vector2, target: Vector2, tolerance: float) -> bool: ...
static func should_retarget(time_since: float, retarget_time: float, blocked: bool, arrived: bool) -> bool: ...
```
`botanico_drone.gd`:
```gdscript
extends CharacterBody2D

@export var home_radius: float = 0.0

var _rng := RandomNumberGenerator.new()
var _anchor: Vector2
var _target: Vector2
var _time_since_target: float = 0.0
var _player: Node2D = null
```
- `_ready()`: `_rng.randomize()`; `_anchor = global_position`; `home_radius` cai para `Balance.DRONE_WANDER_RADIUS` se vier 0; primeiro `_target` por `WanderLogic.pick_target`.
- `_physics_process(delta)`: `_anchor` = posição do `_player` se ele estiver dentro do `Sense`, senão a posição de nascimento; `velocity = (WanderLogic.step(global_position, _target, Balance.DRONE_SPEED, delta) - global_position) / delta`; `move_and_slide()`; se `WanderLogic.should_retarget(_time_since_target, Balance.DRONE_RETARGET_TIME, get_slide_collision_count() > 0, WanderLogic.reached(global_position, _target, 4.0))` → novo `_target` e zera o cronômetro; bobbing pelo `offset.y` do sprite.
- `Sense.body_entered`: guarda `_player`, toca `AudioManager.play_sfx("pickup")` como bipe e dispara `DialogueManager.play("gh_botanico")` na primeira vez (flag em `GameState.flags`).

### Autoloads / sinais do EventBus
- **Usa:** `DialogueManager.play("gh_botanico")`, `AudioManager.play_sfx`.
- **Emite:** nada novo. Não escuta `energy_changed` — o drone tem bateria própria, o que é justamente o motivo de ele ser útil quando o corredor está no escuro.

### Dados (`data/`)
Já previsto no JSON da [F29](F29-fase-estufa.md):
```json
{ "entities": { "31,17": { "id": "botanico_04", "home_radius": 96 } } }
```
Fala nova em `data/dialogue/greenhouse.json`:
```json
{ "gh_botanico": ["Unidade de irrigação BOTÂNICO 04. Ainda operacional.", "Duzentos anos regando um canteiro que ninguém colhe.", "Fica comigo, então."] }
```

### Input actions / camadas de colisão
- Sem input. O drone não tem `collision_layer` (ninguém colide com ele); ele só **mascara** `world` para não atravessar parede, e o `Sense` mascara `player`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-BOTANICO](../ASSETS.md#spr-botanico) | Drone 16×16: `hover` 4f, `spray` 2f | Círculo branco-esverdeado gerado |
| [FX-LIGHT](../ASSETS.md#fx-light) | Facho amarelo-quente | Gradiente radial |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `pickup` (bipe do encontro) | Beep gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [ ] **Passo 1** — Constantes do ADR-F34-002 em `Balance` + proposta de GDD-P e Ajustes.
- [ ] **Passo 2** — `tests/test_wander_logic.gd` (RNG semeado) + `scripts/core/wander_logic.gd`.
- [ ] **Passo 3** — Placeholder do SPR-BOTANICO; `botanico_drone.tscn` + `botanico_drone.gd`.
- [ ] **Passo 4** — Legenda `b` apontando para a cena no `LevelBuilder`.
- [ ] **Passo 5** — Fala `gh_botanico` + flag de primeiro encontro.
- [ ] **Passo 6** — QA (roteiro da seção 10), conferindo dois trajetos diferentes; `/verify-gates`; commit `feat(F34): drone BOTÂNICO 04 com vagueio aleatório e luz`.

## 10. Verificação

- **Testes (`tests/test_wander_logic.gd`)** — `RandomNumberGenerator` com `seed = 42`:
  - `test_target_inside_radius`: 100 sorteios, todos com `distance_to(anchor) <= radius`.
  - `test_targets_vary`: 10 sorteios seguidos produzem pelo menos 8 pontos distintos.
  - `test_same_seed_same_sequence`: dois RNGs com a mesma semente geram a mesma sequência (determinismo do teste).
  - `test_step_moves_toward_target` e `test_step_does_not_overshoot` (delta grande para no alvo).
  - `test_reached_within_tolerance`.
  - `test_should_retarget_on_arrival` / `on_block` / `on_timeout` / `false_when_travelling`.
- **Smoke:** `res://scenes/world/botanico_drone.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f34_botanico.json`), cena `res://scenes/levels/greenhouse.tscn` com save de QA posicionado no corredor superior (ou sala `tests/qa/levels/qa_drone.txt`):

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 30 | — | `01_idle_a.png` | drone flutuando perto da base, facho amarelo no chão |
  | 150 | — | `02_idle_b.png` | drone em **outra** posição, em torno da mesma base |
  | 270 | — | `03_idle_c.png` | terceira posição diferente (trajeto não linear) |
  | 300–420 | `move_right` aproximando o MU-7 | `04_meet.png` (f420) | bipe + fala `gh_botanico`; drone perto do MU-7 |
  | 480–700 | `move_right` seguindo o corredor | `05_follow.png` (f600) · `06_follow2.png` (f700) | drone acompanhando em ziguezague, nunca grudado, iluminando um buraco do piso |
  | 760–900 | `move_left` afastando-se muito | `07_back_home.png` (f900) | drone voltou a vaguear perto da base |
  | — | **rodar o roteiro inteiro uma 2ª vez** | `01_idle_a.png` (run 2) | posições diferentes da 1ª execução (prova da aleatoriedade em jogo) |
- **Playtest humano (opcional):** o drone parece "vivo" ou parece bug? Se parecer errático demais, aumentar `DRONE_RETARGET_TIME`; se parecer robótico, diminuir.

## 11. ADRs locais

### ADR-F34-001 — Vagueio aleatório com âncora móvel = "segue ÓRBITA" + rubrica
- **Contexto:** o GDD diz que o BOTÂNICO 04 **segue** ÓRBITA e ilumina caminhos; a rubrica premia **movimento aleatório** de NPC. Perseguição em linha reta não é aleatória; vagueio puro não segue ninguém.
- **Decisão:** um único comportamento com **âncora dinâmica**: o drone sempre sorteia destinos aleatórios dentro de um raio, e o centro desse raio é a base dele ou o MU-7, conforme a distância. Cumpre as duas coisas sem código dobrado.
- **Consequências:** o movimento é sempre imprevisível (rubrica) e a presença é sempre companheira (GDD). Registrar em [Ajustes](../design/GDD.md#gdd-ajustes) se implementada.
- **Data:** 2026-09-19

### ADR-F34-002 — Números do drone
- **Contexto:** o GDD não dá velocidade, raio nem cadência.
- **Decisão:** `Balance.DRONE_SPEED = 40` (px/s, mais lento que o MU-7 a 110 para nunca atrapalhar), `DRONE_WANDER_RADIUS = 48` (px = 3 tiles), `DRONE_RETARGET_TIME = 2.0` (s), `DRONE_FOLLOW_RADIUS = 96` (px = 6 tiles). **Entradas propostas no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.7-F1) + linha em Ajustes.
- **Consequências:** ajustar a "personalidade" do drone é mexer em quatro números num lugar só.
- **Data:** 2026-09-19

### ADR-F34-003 — RNG injetado na lógica pura
- **Contexto:** comportamento aleatório é, por definição, difícil de testar; e o [ADR-007](../DECISIONS.md#adr-007) exige testes headless determinísticos.
- **Decisão:** `WanderLogic` recebe o `RandomNumberGenerator` como parâmetro. Em jogo, o drone usa `randomize()`; nos testes, `seed = 42`.
- **Consequências:** o mesmo padrão serve a qualquer inimigo com comportamento estocástico no Final (V-9, Serralheiro).
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.7-F1 e da Jornada (personagens) · **Próximo passo**: só depois do Bloco 4 inteiro `[x]`; é a **primeira** da ordem de corte ([ADR-009](../DECISIONS.md#adr-009)).
