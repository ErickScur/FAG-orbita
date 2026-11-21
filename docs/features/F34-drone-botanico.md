---
id: F34
title: Drone BOTÂNICO 04
status: done
scope: stretch
block: 5
priority: P2
rubric: ["Movimento aleatório de NPCs"]
depends_on: ["F12", "F18", "F21", "F29"]
unblocks: []
estimate: 1h
last_updated: 2026-11-21
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

> Revistos na implementação (ADR-F34-004 a 006): o drone mora no **Corredor de Serviço** (Zona E,
> tile `16,18`), não no `31,17` do mapa antigo da F29; não há fala `gh_botanico`.

- [x] O drone nasce no tile `b` (`16,18` da Estufa) e flutua em torno dele, mudando de direção de forma imprevisível, sem sair do corredor (território `zone` no JSON da fase).
- [x] Ele **não** atravessa paredes: todo destino é preso ao ar do território (corredor sem parede interna, provado em `test_greenhouse_drone_lives_in_the_dark_corridor`).
- [x] Com o MU-7 a menos de `Balance.DRONE_FOLLOW_RADIUS`, o drone acorda com um bipe e passa a vaguear **à frente e acima** dele, acompanhando sem grudar.
- [x] Saindo do território, o drone volta a vaguear perto da própria base (não persegue pela fase inteira).
- [x] A luz do drone ilumina o chão o bastante para revelar o poço do corredor escuro (captura `04_segue_e_ilumina_o_poco`).
- [x] Duas execuções do mesmo roteiro de QA produzem trajetos **diferentes**, e com RNG semeado o teste produz sempre o mesmo resultado.
- [x] Sem fala: o primeiro encontro só bipa (ADR-F34-005).
- [x] `tests/test_wander_logic.gd` verde.
- [x] Portões do `/CLAUDE.md` §6 verdes (exceto `test_each_sealed_door_really_guards_its_exit`, que já falhava na base `final/integracao`, sem relação com esta feature)
- [x] Sem comentários no código; nada 3D

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

### 6.1 Como ficou (2026-11-21)

```
scenes/npc/botanico.tscn (+ botanico.gd)   Botanico (Node2D, grupo npc, z 5)
  ├─ Lamp (PointLight2D)    #ffd98a, raio Balance.DRONE_LIGHT_RADIUS, sombra PCF13
  └─ Sprite (AnimatedSprite2D)  SPR-BOTANICO: hover (0–3) e spray (4–5)
scripts/core/wander_logic.gd  WanderLogic: pick_target, clamp_to, step, reached,
                              should_retarget, follow_point, should_follow, should_spray,
                              territory_rect (RNG injetado)
```

- **Sem física**: o drone é um `Node2D` que voa; quem garante "não atravessa parede" é o
  território (`"zone": [2, 16, 43, 6]` em tiles), um corredor sem parede interna. Destinos são
  presos ao ar do território (20 px abaixo do teto, 12 px acima do piso).
- **Sozinho**: sorteia um ponto em `home_radius` (56 px no JSON) em torno da base, a
  `DRONE_SPEED`; ao chegar, rega (`spray`, `DRONE_SPRAY_TIME`) com chance `DRONE_SPRAY_CHANCE`;
  troca de alvo a cada `DRONE_RETARGET_TIME`.
- **Acompanhando**: acorda quando o MU-7 chega a `DRONE_FOLLOW_RADIUS` e segue enquanto o pé
  dele estiver no território (estendido um tile para baixo, a linha do piso). O centro do sorteio
  é `DRONE_LEAD` à frente (lado do `facing` do MU-7) e `DRONE_HOVER_HEIGHT` acima do pé; raio
  `DRONE_FOLLOW_JITTER`, novo ponto a cada `DRONE_FOLLOW_RETARGET_TIME`, a `DRONE_FOLLOW_SPEED`
  (mais rápido que o MU-7, senão a luz fica atrás).
- **Bipe**: `ui_confirm` uma vez por cena, no primeiro encontro (sinal `noticed_player`).
- **Marcos de QA**: `is_following`, `has_met_player`, `is_within(d)`, `is_home(d)`,
  `lamp_lit`, `mark_position` + `moved_since_mark(d)`.
- **Limite de luzes**: `tests/test_light_crowding.gd` conta a luz do drone como se ocupasse o
  território inteiro mais o raio (pior caso de luz móvel).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-BOTANICO](../ASSETS.md#spr-botanico) | Drone 16×16: `hover` 4f, `spray` 2f | Círculo branco-esverdeado gerado |
| [FX-LIGHT](../ASSETS.md#fx-light) | Facho amarelo-quente | Gradiente radial |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `pickup` (bipe do encontro) | Beep gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Constantes novas na GDD-P (AJ-059) e em `Balance`.
- [x] **Passo 2** — `tests/test_wander_logic.gd` (RNG semeado) + `scripts/core/wander_logic.gd`.
- [x] **Passo 3** — `scenes/npc/botanico.tscn` + `botanico.gd` com a folha definitiva.
- [x] **Passo 4** — `b` no mapa da Estufa (a legenda já apontava para `scenes/npc/botanico.tscn`).
- [x] **Passo 5** — Bipe no primeiro encontro (sem fala, ADR-F34-005).
- [x] **Passo 6** — QA com marcos (`tests/qa/f34_botanico.json`, duas rodadas), portões, commit.

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

### ADR-F34-004 — A função de jogo é a luz do corredor escuro
- **Contexto:** o humano reprova objeto que não muda nada ("toda escolha tem consequência
  visível"); um drone que só passeia não passa no playtest. As duas rotas da Estufa atravessam o
  Corredor de Serviço com a ILUMINAÇÃO DO CORREDOR desligada, e os poços só aparecem sob luz.
- **Decisão:** o BOTÂNICO 04 mora nesse corredor (`16,18`) e, acompanhando, voa à frente e acima
  do MU-7 com luz própria de 88 px: mostra o poço seguinte sem gastar Carga da lanterna. Não
  resolve puzzle, não abre porta, não enfrenta a SR-3.
- **Consequências:** apagar o corredor no terminal continua custando (o resto da fase segue no
  escuro e a lanterna segue útil na câmara do Nó), mas o trecho mais injusto ganha um aliado.
- **Data:** 2026-11-21

### ADR-F34-005 — Sem fala no encontro
- **Contexto:** o plano previa `gh_botanico` (3 linhas da ÓRBITA). O playtest reprovou fala fora
  de marco ("muito diálogo e pouca gameplay"), e encontrar o drone não é marco de fase.
- **Decisão:** o drone só bipa (`ui_confirm`) uma vez; a presença dele é o texto.
- **Consequências:** nenhuma linha nova em `data/dialogue/greenhouse.json`.
- **Data:** 2026-11-21

### ADR-F34-006 — Território em vez de colisão
- **Contexto:** `CharacterBody2D` com `move_and_slide` contra os tiles exige esperar 2 quadros de
  física e trata quinas; o corredor não tem parede interna.
- **Decisão:** `Node2D` sem física; destinos presos a um retângulo de território vindo do JSON
  (`zone`, em tiles). O mesmo retângulo decide até onde ele segue o MU-7.
- **Consequências:** posicionar o drone noutra sala é só mudar `zone`; o teste confere que o
  território não cruza parede.
- **Data:** 2026-11-21

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.7-F1 e da Jornada (personagens) · **Próximo passo**: só depois do Bloco 4 inteiro `[x]`; é a **primeira** da ordem de corte ([ADR-009](../DECISIONS.md#adr-009)).

### 2026-11-21 — Implementada
- **Quem**: agente de features (F34+F71) · **O que**: `WanderLogic` + `Botanico` no Corredor de
  Serviço da Estufa (`16,18`, território `[2,16,43,6]`), luz própria que revela os poços, bipe no
  encontro, 9 constantes novas (AJ-059), limite de luzes contando o drone como luz móvel.
- **Testes**: `tests/test_wander_logic.gd` (19 casos, RNG semeado).
- **QA**: `tests/qa/f34_botanico.json` (cena `tests/qa/scenes/f34_probe_corridor.tscn`, corredor
  apagado), 16 marcos OK em duas rodadas. `01_vagueia_a`/`02`/`03`: três posições diferentes em
  torno da base; `04_segue_e_ilumina_o_poco`: drone à frente e acima do MU-7, poço à direita
  aceso; `06_virou_e_o_drone_veio`: drone do lado para onde o MU-7 olha; `07`: de volta à base
  depois de o MU-7 descer para a Copa. A captura `01` da 1ª e da 2ª rodada mostram o drone em
  pontos diferentes (aleatoriedade real em jogo).
- **Próximo passo**: playtest humano. Se o drone parecer nervoso, subir
  `DRONE_FOLLOW_RETARGET_TIME`; se a luz parecer fraca, `DRONE_LIGHT_ENERGY`.
