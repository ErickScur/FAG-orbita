---
id: F14
title: Estabilidade do Reator (timer global)
status: done
scope: demo
block: 2
priority: P0
rubric: []
depends_on: ["F02", "F08", "F10", "F13"]
unblocks: ["F15", "F17", "F28", "F29"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F14 — Estabilidade do Reator (timer global)

## 1. Contexto e objetivo

A **Estabilidade do Reator** é o timer global do jogo e o que "prende o jogador" ([GDD-2.3](../design/GDD.md#gdd-2-3-micro)): começa em 100% e cai 1% a cada 90 s de gameplay. Religar um setor devolve +15%, cada log lido +0,5%, cada morte custa −3%. Em 0% a estação perde órbita: **Game Over definitivo**. A pergunta constante é *"vale a pena procurar mais um log?"*.

Narrativamente, o timer é **ligado** na etapa 2 da Jornada (Chamado para a Aventura): até o alarme do Núcleo Central, o reator não cai. Abaixo de 25% o HUD pulsa em vermelho e toca um alarme diegético. O timer **congela** em pause, diálogo e leitura de log. Existe um **modo sem timer** (acessibilidade) e multiplicadores por dificuldade.

Serve ao pilar **ESCASSEZ** (o tempo é o recurso mais escasso de todos).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.5 Regra do timer](../design/GDD.md#gdd-2-5-timer) · [GDD-2.5 Derrota](../design/GDD.md#gdd-2-5-derrota) (condição 2: reator 0% → `PERDA DE ÓRBITA - MISSÃO ENCERRADA`) · [GDD-2.5 Vitória por fase](../design/GDD.md#gdd-2-5-vitoria) (+15%) · [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud) (<25% pulsa e alarme) · [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (modo sem timer; pause congela) · [GDD-2.6.3 Itens](../design/GDD.md#gdd-2-6-3) (log +0,5%)
- **Parâmetros:** `Balance.REACTOR_START`, `Balance.REACTOR_DECAY_INTERVAL`, `Balance.REACTOR_SECTOR_BONUS`, `Balance.REACTOR_LOG_BONUS`, `Balance.REACTOR_DEATH_PENALTY`, `Balance.REACTOR_CRITICAL` — [GDD-P](../design/GDD.md#gdd-p) · [Multiplicadores de dificuldade](../design/GDD.md#gdd-p-dificuldade). Novos (ADR-F14-001): `REACTOR_ALARM_INTERVAL`, `DIFFICULTY_REACTOR_MULT`
- **Jornada:** [Etapa 2 — Chamado para a Aventura](../design/JORNADA-DO-HEROI.md#jh-2) (liga o TIMER GLOBAL)
- **ADRs:** [ADR-009](../DECISIONS.md#adr-009)
- **Assets:** [SFX-PACK](../ASSETS.md#sfx-pack) (`reactor_alarm`)

## 3. Critério de avaliação atendido

Não pontua sozinho na rubrica, mas é o **requisito "Timer" do 1º bimestre** ([GDD-2.10](../design/GDD.md#gdd-2-10)) e sustenta **Dificuldade ajustável** (F08: decaimento ×0,5/×1/×1,5 e modo sem timer) e **Tela de fim de jogo** (F10: game over do reator). O avaliador vê o percentual no topo do HUD caindo, parando no pause/diálogo, subindo +0,5% ao ler um log, +15% ao religar a Estufa e −3% ao morrer.

## 4. Escopo

### Inclui
- Lógica pura `scripts/core/reactor_clock.gd` (decaimento, bônus, crítico, exibição).
- Tick do reator no `GameState._process` (autoload), ativo só quando: `flags.reactor_online == true`, a cena atual está no grupo `level` e `is_timer_frozen() == false`.
- Implementação de `GameState.is_timer_frozen()`: árvore pausada **ou** diálogo/log bloqueante (`DialogueManager.freezes_timer()`) **ou** transição de cena em andamento (`SceneManager.is_transitioning()` se existir).
- Multiplicador de dificuldade (`DIFFICULTY_REACTOR_MULT[Settings.difficulty]`) e **modo sem timer** (`Settings.no_timer` → ×0).
- Bônus: `sector_restored` → +`REACTOR_SECTOR_BONUS`; primeiro recolhimento de cada log (`collectible_picked(&"log", id)`) → +`REACTOR_LOG_BONUS`. Teto = `REACTOR_START` (100%).
- Penalidade: `player_died` → −`REACTOR_DEATH_PENALTY` (não multiplicada pela dificuldade).
- Crítico: ao cruzar abaixo de `REACTOR_CRITICAL` → `reactor_critical(true)`; ao voltar a ≥ → `reactor_critical(false)`. Alarme `reactor_alarm` a cada `REACTOR_ALARM_INTERVAL` s enquanto crítico e não congelado.
- 0% → `game_over(&"reactor")` uma única vez + `SceneManager.goto("res://scenes/ui/game_over.tscn")` (se o jogador estiver morrendo, a F13 faz a troca — ver F13 §6).
- Emissão de `reactor_changed(percent)` quando o valor exibido (inteiro) muda, e sempre após bônus/penalidade.
- Ligar o timer: flag `reactor_online`, ligada pelo diálogo do alarme da Fase 0 (F19/F28, `on_finish.set_flags`) ou pelo JSON da fase (`"reactor_online": true`, usado na Estufa e em salas de teste).
- Cena de teste `scenes/dev/reactor_test.tscn` que acelera o tempo para validar crítico e game over.

### Não inclui
- Desenho da barra/percentual no HUD e o pulso vermelho — F15 (escuta os sinais).
- Telas de game over — F10.
- Música com percussão abaixo de 25% (camadas adaptativas) — Final (F50).
- "CARREGAR ÚLTIMO SETOR" (lógica de load) — F10/F11.
- Timer de 90 s do ARGOS — Final (F45).

## 5. Critérios de aceite

- [x] `new_game()` → `reactor_percent == Balance.REACTOR_START` e `flags.reactor_online == false`; o reator **não cai** antes do alarme da Fase 0.
- [x] Com o timer ligado em Normal, após 90 s de gameplay o reator está em 99% (±0,05).
- [x] Fácil cai metade (0,5% em 90 s); Difícil 1,5%; modo sem timer não cai em nenhuma dificuldade.
- [x] Durante pause (`get_tree().paused`), diálogo bloqueante e leitura de log o valor não muda (QA: screenshot antes/depois idêntico).
- [x] Ler um log pela primeira vez soma +0,5%; reler o mesmo log não soma.
- [x] `sector_restored` soma +15%, sem passar de 100%.
- [x] Morrer subtrai 3% exatos em qualquer dificuldade.
- [x] Ao cair abaixo de 25%: `reactor_critical(true)` uma vez, alarme toca a cada `REACTOR_ALARM_INTERVAL` s; ao subir para ≥ 25%: `reactor_critical(false)` e o alarme para.
- [x] Ao chegar a 0%: `game_over(&"reactor")` emitido uma vez e troca para a tela `PERDA DE ÓRBITA - MISSÃO ENCERRADA`.
- [x] O valor exibido é `ceil` do percentual (0,4% mostra "1%"; só 0,0 mostra "0%").
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/reactor_clock.gd       class_name ReactorClock (static, pura)
autoload/game_state.gd              (tick, bônus, penalidade, crítico, game over, is_timer_frozen)
scenes/dev/reactor_test.tscn (+ .gd)
tests/test_reactor_clock.gd
```

**`reactor_clock.gd`**:
```gdscript
class_name ReactorClock
extends RefCounted

static func decay_per_second(interval: float, multiplier: float) -> float
static func step(percent: float, delta: float, interval: float, multiplier: float) -> float
static func apply_delta(percent: float, amount: float, cap: float) -> float
static func is_critical(percent: float, threshold: float) -> bool
static func display_percent(percent: float) -> int
```
- `decay_per_second`: `0.0 if interval <= 0 else multiplier / interval`.
- `step`: `maxf(0.0, percent - decay_per_second(interval, multiplier) * delta)`.
- `apply_delta`: `clampf(percent + amount, 0.0, cap)` (bônus positivo, penalidade negativa).
- `is_critical`: `percent < threshold`.
- `display_percent`: `clampi(ceili(percent), 0, 100)`; retorna 0 só quando `percent <= 0.0`.

**`GameState` (partes desta feature):**
```gdscript
var _critical: bool = false
var _alarm_left: float = 0.0
var _game_over_sent: bool = false
var _last_display: int = -1

func _ready() -> void
func _process(delta: float) -> void
func is_timer_frozen() -> bool
func reactor_multiplier() -> float
func change_reactor(amount: float) -> void
```
- `_ready`: conecta `EventBus.sector_restored`, `EventBus.collectible_picked`, `EventBus.player_died`.
- `reactor_multiplier`: `0.0 if Settings.no_timer else Balance.DIFFICULTY_REACTOR_MULT[Settings.difficulty]`.
- `is_timer_frozen`: `get_tree().paused or not flags.get("reactor_online", false) or not _in_level() or DialogueManager.freezes_timer()`; `_in_level()` = `get_tree().current_scene != null and get_tree().current_scene.is_in_group(&"level")`. (A F21 põe `level_base` no grupo `level`.)
- `_process(delta)`: se `is_timer_frozen()` → retorna. `reactor_percent = ReactorClock.step(reactor_percent, delta, Balance.REACTOR_DECAY_INTERVAL, reactor_multiplier())`; depois `_after_reactor_change()`.
- `change_reactor(amount)`: `reactor_percent = ReactorClock.apply_delta(reactor_percent, amount, Balance.REACTOR_START)`; `EventBus.reactor_changed.emit(reactor_percent)`; `_after_reactor_change()`.
- `_after_reactor_change()`: emite `reactor_changed` se `display_percent` mudou; atualiza crítico (emite só na borda); se crítico, decrementa `_alarm_left` e toca `AudioManager.play_sfx("reactor_alarm")` quando ≤ 0 (reinicia em `REACTOR_ALARM_INTERVAL`); se `reactor_percent <= 0` e não `_game_over_sent` → `_game_over_sent = true`, `EventBus.game_over.emit(&"reactor")`, e, **se o jogador não estiver morto** (`not is_dead()`), `SceneManager.goto("res://scenes/ui/game_over.tscn")`.
- Handlers:
  - `sector_restored(_id)` → `change_reactor(Balance.REACTOR_SECTOR_BONUS)`.
  - `collectible_picked(kind, _id)` com `kind == &"log"` → `change_reactor(Balance.REACTOR_LOG_BONUS)` (o sinal só é emitido na **primeira** coleta — garantido pela F20).
  - `player_died()` → `change_reactor(-Balance.REACTOR_DEATH_PENALTY)`.
- `new_game()` / `from_dict()` zeram `_critical`, `_alarm_left`, `_game_over_sent`, `_last_display` (e reemitem `reactor_changed` + `reactor_critical` coerentes após load).

**`reactor_test.tscn`:** `Node2D` no grupo `level` com script que em `_ready()` faz `GameState.new_game()`, `GameState.flags["reactor_online"] = true`, `GameState.reactor_percent = float(start_percent)` (`@export var start_percent: float = 25.3`) e `Engine.time_scale = time_scale` (`@export var time_scale: float = 60.0`); instancia a HUD (se existir). Em `_exit_tree` restaura `Engine.time_scale = 1.0`. Com 60×, 1% cai em 1,5 s real.

### Autoloads / sinais do EventBus
- Emite: `reactor_changed(percent)`, `reactor_critical(active)`, `game_over(reason)`.
- Escuta: `sector_restored`, `collectible_picked`, `player_died`.
- Usa: `Settings.difficulty`, `Settings.no_timer`, `DialogueManager.freezes_timer()` (F19; até existir, considerar `false`), `AudioManager.play_sfx`, `SceneManager.goto`.

### Dados (`data/`)
- Chave opcional no JSON de fase (F21): `"reactor_online": true` → o `level_base` faz `GameState.flags["reactor_online"] = true` ao carregar.
- Chave opcional em sequências de diálogo (F19): `"on_finish": {"set_flags": ["reactor_online"]}` — usada no alarme da Fase 0.

### Input actions / camadas de colisão
- Nenhuma.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SFX-PACK](../ASSETS.md#sfx-pack) | `reactor_alarm` (tocado a cada `REACTOR_ALARM_INTERVAL` s em estado crítico) | Beep grave gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Registrar `REACTOR_ALARM_INTERVAL` e `DIFFICULTY_REACTOR_MULT` no GDD-P + Ajustes e no `balance.gd` (se a F08 já criou o dicionário com outro nome, reutilizar).
- [x] **Passo 2** — `tests/test_reactor_clock.gd` → falha → `reactor_clock.gd` → passa.
- [x] **Passo 3** — Tick, `is_timer_frozen`, `change_reactor`, crítico, alarme e game over no `GameState`.
- [x] **Passo 4** — Handlers de `sector_restored`, `collectible_picked(&"log")`, `player_died`.
- [x] **Passo 5** — Leitura de `"reactor_online"` no `level_base` (se a F21 ainda não existir, anotar no log para a F21 incluir).
- [x] **Passo 6** — `scenes/dev/reactor_test.tscn`; `tests/scenes.txt`.
- [x] **Passo 7** — Portões + QA.

## 10. Verificação

- **Testes (`tests/test_reactor_clock.gd`):**
  - `test_decay_normal_90s` — `step(100, 90, 90, 1.0)` ≈ 99,0.
  - `test_decay_multipliers` — com multiplicador 0,5 → 99,5; 1,5 → 98,5; 0,0 → 100,0.
  - `test_step_never_negative` — `step(0.2, 90, 90, 1.0) == 0.0`.
  - `test_bonus_caps_at_start` — `apply_delta(95, 15, 100) == 100`.
  - `test_penalty` — `apply_delta(10, -3, 100) == 7`; `apply_delta(2, -3, 100) == 0`.
  - `test_critical_threshold` — `is_critical(24.99, 25) == true`; `is_critical(25.0, 25) == false`.
  - `test_display_ceil` — `display_percent(74.2) == 75`; `display_percent(0.4) == 1`; `display_percent(0.0) == 0`; `display_percent(100.0) == 100`.
  - `test_frame_by_frame_matches_bulk` — 5400 passos de 1/60 s somam o mesmo que um passo de 90 s (±0,001).
- **Smoke:** `res://scenes/dev/reactor_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f14_reactor.json`; cena `res://scenes/dev/reactor_test.tscn` com `start_percent = 25.3`, `time_scale = 60`):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 5 | — | `f14_01_start` | HUD: "ESTABILIDADE DO REATOR: 26%" (ceil de 25,3), barra normal |
| 60 | — | `f14_02_critical` | HUD: 25% ou menos, barra/percentual em vermelho pulsando (F15) |
| 61 | `pause` | — | — |
| 90 | — | `f14_03_paused_a` | Menu de pause; percentual X |
| 150 | — | `f14_04_paused_b` | Mesmo percentual X do frame 90 (congelado) |
| 151 | `pause` | — | — |
| 2000 | — | `f14_05_game_over` | Tela "PERDA DE ÓRBITA - MISSÃO ENCERRADA" (F10) |

- Teste manual extra (log): numa cena com log (após F19/F20), anotar o percentual, abrir o log, confirmar que não cai durante a leitura e sobe +0,5% ao coletar.
- **Playtest humano (opcional):** "você sentiu pressão do tempo? em algum momento parou de explorar por causa do reator?"

## 11. ADRs locais

### ADR-F14-001 — Constantes novas do reator
- **Contexto:** o GDD define o alarme abaixo de 25% mas não a cadência; o dicionário de multiplicadores de decaimento precisa de um nome no `Balance`.
- **Decisão:** `REACTOR_ALARM_INTERVAL = 4.0` s; `DIFFICULTY_REACTOR_MULT = {&"easy": 0.5, &"normal": 1.0, &"hard": 1.5}` (espelho de [GDD-P Dificuldade](../design/GDD.md#gdd-p-dificuldade)). Registrar no GDD-P + Ajustes.
- **Consequências:** o alarme é um SFX pontual repetido (não exige API de loop no `AudioManager`).
- **Data:** 2026-09-19

### ADR-F14-002 — Tick no `GameState`, não numa cena
- **Contexto:** bônus e penalidades chegam por sinais que podem ocorrer perto de trocas de cena; um nó de cena poderia perdê-los.
- **Decisão:** o tick e os handlers vivem no autoload `GameState`; a cena atual só "habilita" o timer por estar no grupo `level`. Menus, telas de fim e loading nunca decaem o reator.
- **Consequências:** um ponto único de verdade; `is_timer_frozen()` fica completo e testável por QA.
- **Data:** 2026-09-19

### ADR-F14-003 — O timer só liga após o alarme da Fase 0
- **Contexto:** a Jornada diz que a etapa 2 "liga o TIMER GLOBAL"; a etapa 1 é calibração sem pressão.
- **Decisão:** flag `reactor_online` (em `GameState.flags`, salva pela F11) ligada pelo diálogo do alarme ou pelo JSON da fase. Antes disso, o HUD pode ocultar a barra (decisão visual da F15).
- **Consequências:** o tutorial não pune; carregar direto a Estufa (teste/QA) liga o timer pelo JSON.
- **Data:** 2026-09-19

### ADR-F14-004 — Terminal de Distribuição não congela o timer
- **Contexto:** o GDD lista só pause, diálogo e log como congelantes.
- **Decisão:** a UI do terminal (F17) **não** congela o reator: decidir custa tempo, coerente com ESCASSEZ.
- **Consequências:** puzzles devem ser legíveis rápido (poucos sistemas na demo).
- **Data:** 2026-09-19

### ADR-F14-005 — `is_timer_frozen()` continua sendo só "congelamento", e quem decide o tique é `is_reactor_running()`
- **Contexto:** o §6 desta feature propunha embutir `reactor_online` e "estar numa fase" dentro de `is_timer_frozen()`. Isso mudaria o significado do método já usado pela F02/F09 (e pelo teste `test_timer_freezes_without_timer_setting`): o reator "não estar ligado ainda" não é a mesma coisa que "o timer está congelado" — o HUD precisa distinguir os dois para escrever `congelado` em vez de esconder a barra.
- **Decisão:** `is_timer_frozen()` continua respondendo só por pause, diálogo, leitura de log e modo sem timer. A condição completa do tique virou `is_reactor_running() = is_reactor_online() and is_in_level() and not is_timer_frozen()`. `is_in_level()` aceita tanto o grupo `level` (F21) quanto qualquer cena sob `res://scenes/levels/`.
- **Consequências:** nenhum teste existente quebrou; o HUD (F15) lê os três predicados separadamente; `set_reactor_online(bool)` virou o caminho oficial para ligar o timer (emite `reactor_changed` para o HUD aparecer na hora).
- **Data:** 2026-09-19

### ADR-F14-006 — `game_over(&"reactor")` é só emissão (ADR-013 manda)
- **Contexto:** o §6 pedia `SceneManager.goto("res://scenes/ui/game_over.tscn")` dentro do `GameState`, mas o [ADR-013](../DECISIONS.md#adr-013) já tinha dado a política de fim de jogo para a F10, e o `SceneManager` já escuta `EventBus.game_over`.
- **Decisão:** o `GameState` apenas emite `game_over(&"reactor")` uma única vez; quem troca de cena é a F10. A verificação de "jogador morrendo" também sai do `GameState` (o `SceneManager._on_player_died` já ignora a morte do chassi quando o reator está em 0%).
- **Consequências:** um único dono da troca de cena; QA confirma a tela `PERDA DE ÓRBITA - MISSÃO ENCERRADA` sem troca dupla.
- **Data:** 2026-09-19

### ADR-F14-007 — Cenas de prova moram em `tests/qa/scenes/`
- **Contexto:** o §6 pedia `scenes/dev/reactor_test.tscn`, mas todas as cenas de prova do projeto (F06 a F13) já moram em `tests/qa/scenes/*_probe|sandbox`.
- **Decisão:** `tests/qa/scenes/reactor_probe.tscn` (`start_percent = 25,3`, `time_scale = 90`) e `tests/qa/scenes/reactor_zero_probe.tscn` (`start_percent = 0,6`) — ambas nos grupos `level` e `gameplay` (o segundo é o que a F09 exige para a pausa funcionar) e ambas forçam `Settings.difficulty = normal` e `no_timer = false` para o QA ser determinístico.
- **Consequências:** convenção única de cenas de prova; a build não carrega nada de `scenes/dev/`.
- **Data:** 2026-09-19

### ADR-F14-008 — `reactor_changed` só quando o inteiro exibido muda
- **Contexto:** emitir a cada frame do tique encheria o EventBus com 60 sinais por segundo para um número que só muda de 1 em 1%.
- **Decisão:** o tique emite `reactor_changed` apenas quando `ReactorClock.display_percent()` muda; bônus e penalidades (`change_reactor`) emitem sempre.
- **Consequências:** HUD atualiza em degraus de 1% (a barra também), sem custo por frame; testado em `test_reactor_changed_uses_display_steps`.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scripts/core/reactor_clock.gd` (lógica pura), tique do reator no `GameState` (`_tick_reactor`, `_update_alarm`, `_after_reactor_change`, `is_reactor_online`/`set_reactor_online`/`is_in_level`/`is_reactor_running`/`is_reactor_critical`), handlers de `sector_restored` (+15%), `collectible_picked(&"log")` (+0,5%) e `player_died` (−3%), crítico com alarme a cada `REACTOR_ALARM_INTERVAL`, `game_over(&"reactor")` uma única vez, `Balance.REACTOR_ALARM_INTERVAL = 4.0`, cenas `tests/qa/scenes/reactor_probe.tscn` e `reactor_zero_probe.tscn`, suítes `tests/test_reactor_clock.gd` (10 casos) e `tests/test_reactor_state.gd` (16 casos), roteiros `tests/qa/f14_reactor.json` e `f14_game_over.json`. Portões: import limpo, 271 testes passando, 36 cenas no smoke, varreduras 3D/comentários/fonte vazias. QA leu as 8 capturas: 26% (ceil de 25,3) em branco → 24% em vermelho abaixo do limiar → congelado e idêntico por 180 frames de pausa → 23% ao retomar → tela `PERDA DE ÓRBITA - MISSÃO ENCERRADA` no zero.
- **Pendências**: `REACTOR_ALARM_INTERVAL` **ainda não está na tabela [GDD-P](../design/GDD.md#gdd-p) nem nos Ajustes** — esta execução foi proibida de editar `docs/design/`; registrar (junto com as três constantes da F15). O `level_base` (F21) escreve `GameState.flags["reactor_online"] = true` direto em vez de `set_reactor_online(true)`: funciona porque o HUD reavalia a visibilidade por frame, mas o caminho oficial é o método.
- **Próximo passo**: F17 (religar setor → `sector_restored`) e F19/F28 (alarme da Fase 0 liga a flag; o JSON `data/dialogue/core_hub.json` já traz `set_flags: ["reactor_online"]`).
