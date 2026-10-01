---
id: F23
title: Enxame de Esporos & efeitos de status
status: done
scope: demo
block: 3
priority: P1
rubric: ["Efeitos naturais (campo de visão, clima)"]
depends_on: ["F02", "F13", "F15", "F17", "F21"]
unblocks: ["F29", "F31", "F32"]
estimate: 2h
last_updated: 2026-09-19
---

# F23 — Enxame de Esporos & efeitos de status

## 1. Contexto e objetivo

A Estufa é o setor "vivo" da ARTEMIS e o experimento da tripulação saiu do controle: nuvens de esporos ocupam corredores, causam **5 de dano por segundo** e aplicam o status **CORROSÃO**, que impede recarregar Carga por 6 s. A nuvem é estática, mas **se expande quando há calor no ambiente** — na Demo, quando o sistema `heating` (Aquecimento) está ligado no Terminal de Distribuição da Estufa. Desligar o aquecimento encolhe a nuvem: é a primeira vez que o jogador resolve um problema de combate **mexendo na energia**, não no botão de ação.

Esta feature entrega duas coisas: (a) o **enxame** em si e (b) o **framework de efeitos de status** (`scripts/core/status_effects.gd`, lógica pura e testável) que já aceita os **5 status do GDD** ([GDD-2.6.2-F](../design/GDD.md#gdd-2-6-2-f)), mesmo que só a CORROSÃO seja aplicada de fato na Demo. O framework é o que a F48 (Final) vai preencher sem refatorar nada.

Serve aos pilares **ESCASSEZ** (dano + bloqueio de recarga) e **DESCOBERTA** (a nuvem é o rastro narrativo do experimento).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.2-D — Enxame de Esporos](../design/GDD.md#gdd-2-6-2-d) · [GDD-2.6.2-F — Efeitos de status](../design/GDD.md#gdd-2-6-2-f) · [GDD-2.7-F1 — Estufa](../design/GDD.md#gdd-2-7-f1) · [GDD-2.5 regra de energia](../design/GDD.md#gdd-2-5-energia) · [GDD-2.8 HUD (ícones de status com contador)](../design/GDD.md#gdd-2-8-hud)
- **Parâmetros:** `Balance.SPORE_DPS` (5), `Balance.CORROSION_TIME` (6,0) — [GDD-P](../design/GDD.md#gdd-p). **Novos (ADR-F23-001):** `Balance.SPORE_RADIUS`, `Balance.SPORE_RADIUS_HEATED`, `Balance.SPORE_EXPAND_TIME`, `Balance.STATUS_EXPOSURE_GRACE`, `Balance.OVERHEAT_DPS`, `Balance.OVERHEAT_CHARGE_MULT`, `Balance.FREEZE_SPEED_MULT`, `Balance.FREEZE_JUMP_MULT`, `Balance.DISCHARGE_TIME`, `Balance.OVERLOAD_TIME`, `Balance.OVERLOAD_SPEED_MULT`.
- **Jornada:** [Etapa 5 — Testes e Aliados (Estufa)](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) · [ADR-007](../DECISIONS.md#adr-007) · [ADR-005](../DECISIONS.md#adr-005)
- **Features vizinhas:** [F17 — Terminal de Distribuição](F17-terminal-distribuicao.md) (sinal `energy_changed`), [F13](F13-integridade-carga-respawn.md) (Integridade/Carga/doca), [F15](F15-hud-objetivos.md) (ícones de status), [F29](F29-fase-estufa.md) (onde as nuvens ficam).

## 3. Critério de avaliação atendido

**Efeitos naturais (campo de visão, clima)** ([rubrica](../ENTREGAS.md#rubrica)) — junto com a [F18](F18-luz-lanterna.md). O avaliador vê, na Estufa: a nuvem verde-rosada ocupando o corredor; o MU-7 perdendo Integridade dentro dela e o ícone **CORROSÃO** com contagem regressiva no HUD; a doca de recarga recusando a recarga enquanto o ícone está aceso; e, depois de o jogador desligar o **AQUECIMENTO** no terminal, a mesma nuvem encolher na hora — o "clima" do setor mudando por decisão de energia.

## 4. Escopo

### Inclui
- `scripts/core/status_effects.gd` — `class_name StatusEffects`, lógica pura (sem nós, sem `get_tree()`), com os **5 status do GDD** declarados em `DEFINITIONS` e modificadores consultáveis.
- Integração mínima no `GameState`: instância `statuses`, `apply_status()`, tick por frame, emissão de `status_applied` / `status_cleared`, bloqueio de ganho de Carga durante CORROSÃO.
- `scenes/enemies/spore_swarm.tscn` + `spore_swarm.gd`: `Area2D` de dano contínuo (`Balance.SPORE_DPS`) que aplica CORROSÃO enquanto o MU-7 está dentro, com partículas 2D.
- Expansão/retração da nuvem por energia: nó no grupo `"powered"` com `system_id` / `terminal_id` (raio e partículas com `Tween` em `Balance.SPORE_EXPAND_TIME`).
- `scripts/core/dot_accumulator.gd` — `class_name DotAccumulator`, converte dano por segundo em dano inteiro (reusado pela [F32](F32-obstaculos-ambientais.md)).
- Imunidade durante o dash (se a [F31](F31-dash-feixe.md) existir): "atravessar de dash" do GDD.
- Ícone de CORROSÃO no HUD com contador (a arte e o slot são da [F15](F15-hud-objetivos.md); aqui só garantimos os sinais e o `remaining()`).
- SFX `spores` em loop posicional enquanto a nuvem está ativa.

### Não inclui
- **Aplicar de fato** SUPERAQUECIMENTO, CONGELAMENTO, DESCARGA e SOBRECARGA — não há fonte desses climas na Demo (Verão/Inverno/elétrico são F40/F41/F32). O framework os define, testa e expõe; **ninguém os emite** — F48 no Final.
- Esporos no Laboratório (F40).
- Partículas com shader/GPU avançada: usamos `CPUParticles2D` (renderer Compatibility, [ADR-002](../DECISIONS.md#adr-002)).
- Cura de CORROSÃO por item (não existe no GDD).

## 5. Critérios de aceite

- [x] Entrar na nuvem: Integridade cai ~5/s (dano inteiro acumulado pela `DamageArea` da F13, com o multiplicador de dificuldade aplicado no `GameState`) e o ícone CORROSÃO aparece no HUD.
- [x] Sair da nuvem: o ícone permanece e conta 6 s regressivos; ao zerar, `EventBus.status_cleared(&"corrosion")` é emitido e o ícone some.
- [x] Com CORROSÃO ativa, parar numa doca **não** recarrega Carga e a Célula de Energia (`c`) **não** é coletada (ela continua no chão); sem CORROSÃO, ambas funcionam.
- [x] Com `energy_changed("greenhouse", "heating", true)`, a nuvem cresce de `SPORE_RADIUS` para `SPORE_RADIUS_HEATED` em `SPORE_EXPAND_TIME` (área de colisão **e** partículas) e cobre a passagem; com `false`, encolhe de volta.
- [x] Ao carregar a fase, a nuvem já nasce no tamanho correto para o estado de energia (grupo `powered` + `set_powered_silent`, ADR-011).
- [x] Morrer e renascer limpa todos os status (`player_respawned`).
- [x] `StatusEffects` conhece os 5 status do GDD-2.6.2-F, com duração e modificadores corretos, e é 100% testável sem cena.
- [x] `tests/test_status_effects.gd` (16 casos) e `tests/test_game_state_status.gd` (9 casos) verdes — `DotAccumulator` não foi criado, ver [ADR-F23-006](#adr-f23-006).
- [x] Portões do `/CLAUDE.md` §6 verdes — 399 testes, 48 cenas no smoke.
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/status_effects.gd     class_name StatusEffects  (RefCounted, pura)
scripts/core/dot_accumulator.gd    class_name DotAccumulator (RefCounted, pura)
scenes/enemies/spore_swarm.tscn (+ spore_swarm.gd)
  SporeSwarm (Area2D)              collision_layer = 5 (hazard) · collision_mask = 2 (player) · monitoring
  ├─ CollisionShape2D              CircleShape2D (radius = Balance.SPORE_RADIUS)
  ├─ Particles (CPUParticles2D)    emission_shape = SPHERE, texture SPR-SPORE, amount 24, lifetime 2.0, gravity (0,-4)
  └─ Loop (AudioStreamPlayer2D)    stream SFX `spores` (loop), bus de efeitos da F04
autoload/game_state.gd             (+ statuses, apply_status, _physics_process, guarda em add_charge)
```

`scripts/core/status_effects.gd`:
```gdscript
class_name StatusEffects
extends RefCounted

const CORROSION := &"corrosion"
const OVERHEAT := &"overheat"
const FREEZE := &"freeze"
const DISCHARGE := &"discharge"
const OVERLOAD := &"overload"

const ORDER: Array[StringName] = [CORROSION, OVERHEAT, FREEZE, DISCHARGE, OVERLOAD]

const DEFINITIONS := {
    CORROSION: {"duration": 6.0, "blocks_charge_gain": true},
    OVERHEAT: {"duration": 0.0, "integrity_dps": 3.0, "charge_drain_mult": 2.0},
    FREEZE: {"duration": 0.0, "speed_mult": 0.5, "jump_mult": 0.7, "slippery": true},
    DISCHARGE: {"duration": 3.0, "blocks_abilities": true},
    OVERLOAD: {"duration": 10.0, "speed_mult": 1.3},
}
```
- Os valores vêm de `Balance` no `_init` (o dicionário acima documenta o contrato; o código lê `Balance.CORROSION_TIME`, `Balance.OVERHEAT_DPS`, …). `duration: 0.0` significa **enquanto exposto**: a fonte reaplica todo frame com `Balance.STATUS_EXPOSURE_GRACE`.
- API: `apply(id: StringName, duration := -1.0) -> bool` (retorna `true` só quando é aplicação **nova**; reaplicar apenas renova o tempo restante para o maior valor), `clear(id)`, `clear_all()`, `tick(delta) -> Array[StringName]` (ids que expiraram), `has(id) -> bool`, `remaining(id) -> float`, `active_ids() -> Array[StringName]` (na ordem de `ORDER`), `blocks_charge_gain() -> bool`, `blocks_abilities() -> bool`, `speed_multiplier() -> float`, `jump_multiplier() -> float`, `charge_drain_multiplier() -> float`, `integrity_dps() -> float`.
- Multiplicadores combinam por produto; `integrity_dps` soma.

`scripts/core/dot_accumulator.gd`:
```gdscript
class_name DotAccumulator
extends RefCounted

var _pending: float = 0.0

func add(dps: float, delta: float) -> int: ...   # acumula e devolve a parte inteira, guardando o resto
func reset() -> void: ...
```

`GameState` (adições — ver ADR-F23-002):
```gdscript
var statuses: StatusEffects = StatusEffects.new()

func apply_status(id: StringName, duration: float = -1.0) -> void: ...
    # se statuses.apply(id, duration): EventBus.status_applied.emit(id, statuses.remaining(id))
func _physics_process(delta: float) -> void: ...
    # for id in statuses.tick(delta): EventBus.status_cleared.emit(id)
func add_charge(v: float) -> void: ...
    # if statuses.blocks_charge_gain(): return
```
O HUD ([F15](F15-hud-objetivos.md)) mostra o contador lendo `GameState.statuses.remaining(id)` a cada frame; `status_applied` só entra/sai o ícone. `player_respawned` → `statuses.clear_all()` + `status_cleared` para cada id ativo.

`spore_swarm.gd`:
```gdscript
extends Area2D

@export var terminal_id: StringName = &"greenhouse"
@export var system_id: StringName = &"heating"

var _dot := DotAccumulator.new()
var _heated: bool = false
```
- `_ready()`: `add_to_group("powered")`; lê o estado inicial de energia **do mesmo jeito que a porta da F17** (`GameState.energy_states`); aplica o raio sem `Tween`; conecta `EventBus.energy_changed`.
- `_on_energy_changed(t, s, powered)`: ignora se `t != terminal_id or s != system_id`; senão `Tween` do `radius` do `CircleShape2D`, do `emission_sphere_radius` e da `scale` visual entre `Balance.SPORE_RADIUS` e `Balance.SPORE_RADIUS_HEATED` em `Balance.SPORE_EXPAND_TIME`.
- `_physics_process(delta)`: para cada corpo do grupo `"player"` sobreposto: se o corpo tem `is_dashing()` e está dando dash → não faz nada; senão `var dmg := _dot.add(Balance.SPORE_DPS, delta)`; se `dmg > 0` → `GameState.apply_damage(dmg)`; e `GameState.apply_status(StatusEffects.CORROSION)` (renova os 6 s). Sem corpo sobreposto → `_dot.reset()`.

### Autoloads / sinais do EventBus
- **Escuta:** `energy_changed(terminal_id, system_id, powered)` (nuvem), `player_respawned()` (limpar status).
- **Emite:** `status_applied(status_id, duration)`, `status_cleared(status_id)`; indiretamente `player_damaged`/`integrity_changed` via `GameState.apply_damage`.
- `AudioManager.play_sfx` não é usado para o loop: o chiado é um `AudioStreamPlayer2D` dentro da cena (som posicional contínuo).

### Dados (`data/`)
- `data/energy/greenhouse.json` ([F17](F17-terminal-distribuicao.md)) declara o sistema `heating` (rótulo `AQUECIMENTO`, ligado no estado inicial).
- Parâmetros por coordenada no JSON da fase ([F29](F29-fase-estufa.md)), caractere `~`:
```json
{ "entities": {
  "24,36": { "terminal_id": "greenhouse", "system_id": "heating" },
  "28,36": { "terminal_id": "greenhouse", "system_id": "heating" },
  "25,26": { "terminal_id": "greenhouse", "system_id": "heating" }
} }
```

### Input actions / camadas de colisão
- Sem input novo. Nuvem: layer 5 `hazard`, mask 2 `player`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-SPORE](../ASSETS.md#spr-spore) | Partícula 8×8 do `CPUParticles2D` | Círculos verde-rosados semitransparentes |
| [UI-HUD](../ASSETS.md#ui-hud) | Ícone de status **Corrosão** (e os outros 4, já no sheet) | Ícones 16×16 gerados |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `spores` (loop) | Chiado gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Constantes já presentes em `Balance` (raio, tempo de expansão, janela de exposição e os números dos 5 status) — nenhum número novo foi inventado.
- [x] **Passo 2** — Dispensado: a conversão de dano/s em dano inteiro já vive em `Vitals.accumulate` + `DamageArea` ([ADR-F23-006](#adr-f23-006)).
- [x] **Passo 3** — `tests/test_status_effects.gd` + `scripts/core/status_effects.gd` (os 5 status do GDD).
- [x] **Passo 4** — `GameState`: `statuses`, `apply_status()`, `clear_status()`, `clear_statuses()`, `has_status()`, tick no `_process`, guarda no `add_charge`, limpeza no respawn/`new_game`/`from_dict`.
- [x] **Passo 5** — Doca (F13) já escutava `status_applied`/`status_cleared`; coletável `c` ganhou a guarda de CORROSÃO.
- [x] **Passo 6** — `scenes/enemies/spore_swarm.tscn` + `spore_swarm.gd` com expansão/retração por `energy_changed`.
- [x] **Passo 7** — Ícone de CORROSÃO do HUD (F15) confirmado no QA, com contagem 6 → 4 → 1 → some.
- [x] **Passo 8** — Sandbox `tests/qa/scenes/spore_sandbox.tscn` + roteiro `tests/qa/f23_esporos.json`; cenas em `tests/scenes.txt`; portões verdes. Commit fica com o humano.

## 10. Verificação

- **Testes (`tests/test_status_effects.gd`):**
  - `test_defines_five_gdd_statuses`: `StatusEffects.ORDER.size() == 5` e todas as chaves existem em `DEFINITIONS`.
  - `test_corrosion_expires_after_balance_time`: `apply(CORROSION)` → `remaining == Balance.CORROSION_TIME`; `tick(6.0)` devolve `[CORROSION]` e `has(CORROSION) == false`.
  - `test_reapply_refreshes_and_returns_false`: aplicar, `tick(3.0)`, aplicar de novo → retorno `false`, `remaining == 6.0`.
  - `test_corrosion_blocks_charge_gain`: `blocks_charge_gain()` só com CORROSÃO ativa.
  - `test_freeze_multipliers`: com FREEZE, `speed_multiplier() == Balance.FREEZE_SPEED_MULT` e `jump_multiplier() == Balance.FREEZE_JUMP_MULT`.
  - `test_overload_and_freeze_multiply`: os dois ativos → `speed_multiplier()` é o produto.
  - `test_discharge_blocks_abilities` / `test_overheat_dps_and_drain`.
  - `test_exposure_status_needs_refresh`: `apply(OVERHEAT, Balance.STATUS_EXPOSURE_GRACE)`; `tick(grace)` expira.
  - `test_clear_all_returns_nothing_active`.
- **Testes (`tests/test_dot_accumulator.gd`):** `test_accumulates_to_integer` (5 dps × 0,1 s dez vezes → soma 5 de dano, nunca dano fracionário); `test_reset_drops_partial`.
- **Smoke:** `res://scenes/enemies/spore_swarm.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f23_spores.json`) — sala `tests/qa/levels/qa_spores.txt` com um terminal (`T`, terminal_id `greenhouse`), uma nuvem (`~`), uma doca (`D`) e uma célula (`c`):

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 30 | — | `01_heated.png` | nuvem grande (estado inicial: `heating` ligado) cobrindo o corredor |
  | 31–150 | segurar `move_right` | `02_inside.png` (f120) | MU-7 dentro da nuvem, Integridade caindo, ícone CORROSÃO no HUD |
  | 160 | — | `03_corrosion_timer.png` | fora da nuvem, ícone com contagem < 6 s |
  | 165–200 | andar até a doca (`move_left`) e parar | `04_no_recharge.png` (f200) | MU-7 na doca com a barra de Carga **parada** e o ícone ainda aceso |
  | 560 | — | `05_recharging.png` | ícone sumiu (6 s) e a Carga voltou a subir |
  | 600 | `interact` no terminal; desligar `heating` na UI (`ui_down`/`ui_accept` do roteiro) | `06_terminal.png` | UI do terminal com AQUECIMENTO sendo desligado |
  | 700 | fechar a UI | `07_shrunk.png` | nuvem pequena, corredor livre |
- **Playtest humano (opcional):** a nuvem grande parece intransponível o bastante para o jogador **querer** mexer no terminal?

## 11. ADRs locais

### ADR-F23-001 — Números que faltam no GDD-P para esporos e status
- **Contexto:** o GDD dá 5 dps, CORROSÃO 6 s e os efeitos dos outros status em texto, mas não o **tamanho** da nuvem, o tempo de expansão nem os números dos status em forma de tabela.
- **Decisão:** novas constantes em `Balance`: `SPORE_RADIUS = 16` (px, 1 tile), `SPORE_RADIUS_HEATED = 40` (px, 2,5 tiles), `SPORE_EXPAND_TIME = 1.5` (s), `STATUS_EXPOSURE_GRACE = 0.25` (s), e os números do GDD-2.6.2-F promovidos a constantes: `OVERHEAT_DPS = 3`, `OVERHEAT_CHARGE_MULT = 2.0`, `FREEZE_SPEED_MULT = 0.5`, `FREEZE_JUMP_MULT = 0.7`, `DISCHARGE_TIME = 3.0`, `OVERLOAD_TIME = 10.0`, `OVERLOAD_SPEED_MULT = 1.3`. **Entradas propostas no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.6.2-D e 2.6.2-F) + linha em [Ajustes](../design/GDD.md#gdd-ajustes).
- **Consequências:** a F48 (Final) implementa os outros status sem inventar número.
- **Data:** 2026-09-19

### ADR-F23-002 — Os status vivem no `GameState`, não no jogador
- **Contexto:** o contrato de autoloads não previa status; quem precisa deles são o jogador (velocidade/pulo), a doca e os coletáveis (Carga) e o HUD (ícones).
- **Decisão:** uma única instância `GameState.statuses: StatusEffects` (não serializada no save: status não sobrevive a load nem a respawn). Todo mundo consulta `GameState.statuses`; quem aplica chama `GameState.apply_status()`.
- **Consequências:** extensão pequena do contrato do `GameState`; sem duplicação de estado. O `GameState` passa a ter `_physics_process` (respeita pause e diálogo automaticamente, pois pausa junto com a árvore).
- **Data:** 2026-09-19

### ADR-F23-003 — CORROSÃO bloqueia **toda** fonte de recarga, e a Célula não é consumida
- **Contexto:** "Impede recarga de Carga" pode significar só a doca ou também a Célula de Energia.
- **Decisão:** bloqueia as duas (`GameState.add_charge` retorna sem efeito). Para não desperdiçar o item, o coletável `c` **não é coletado** enquanto a CORROSÃO estiver ativa (continua no chão, e o HUD já explica o porquê pelo ícone).
- **Consequências:** o status tem consequência visível mesmo numa demo curta; o jogador aprende a esperar 6 s ou a evitar a nuvem.
- **Data:** 2026-09-19

<a id="adr-f23-004"></a>
### ADR-F23-004 — `status_applied` é emitido em toda aplicação, inclusive na renovação
- **Contexto:** o HUD da F15 mantém o próprio contador e só o reinicia quando recebe `status_applied`. Se o `GameState` emitisse apenas na aplicação **nova**, o ícone continuaria descendo enquanto o MU-7 estivesse dentro da nuvem e chegaria a zero antes da hora.
- **Decisão:** `GameState.apply_status()` devolve `true` só para aplicação nova (contrato do `StatusEffects.apply`), mas **emite** `status_applied(id, remaining)` sempre que o status fica ativo.
- **Consequências:** o contador do HUD acompanha a exposição; o sinal é barato e a fonte (o enxame) pode reaplicar todo frame físico sem estado próprio.
- **Data:** 2026-09-19

<a id="adr-f23-005"></a>
### ADR-F23-005 — O enxame **é** uma `DamageArea`, não contém uma
- **Contexto:** a F13 já resolve dano por segundo, acumulação inteira e multiplicador de dificuldade: o `mu7.gd` varre as `DamageArea` sobrepostas à Hurtbox. O `mu7.gd` só chama `notify_status()` no ramo de dano por **contato**, então um enxame puramente `damage_per_second` nunca aplicaria o status sozinho.
- **Decisão:** `SporeSwarm extends DamageArea` (`damage_per_second = Balance.SPORE_DPS`, layer `hazard`, mask `player`, `monitoring` ligado no `_ready` depois do `super()`), e o próprio enxame chama `GameState.apply_status(CORROSION)` para cada corpo do grupo `player` sobreposto. Uma única forma de colisão serve ao dano e à detecção, e o raio muda nos dois de uma vez.
- **Consequências:** zero duplicação da regra de dano; quando a F31 trouxer `is_dashing()`, a imunidade do dash já está prevista no laço.
- **Data:** 2026-09-19

<a id="adr-f23-006"></a>
### ADR-F23-006 — `DotAccumulator` não foi criado
- **Contexto:** a seção 6 previa `scripts/core/dot_accumulator.gd`, mas a F13 entregou `Vitals.accumulate(acumulador, por_segundo, delta)` (pura, testada) e o `mu7.gd` já a usa para converter dano/s em dano inteiro.
- **Decisão:** não criar a classe; o enxame não acumula dano nenhum (quem acumula é a F13). Criar um invólucro seria duplicação e código morto (regra dura de arquitetura §4.2.3).
- **Consequências:** a F32 (obstáculos ambientais) reusa `Vitals.accumulate` ou declara uma `DamageArea` com `damage_per_second`, como o vapor e o piso elétrico já fazem.
- **Data:** 2026-09-19

<a id="adr-f23-007"></a>
### ADR-F23-007 — O tween mexe só no raio; a quantidade de partículas é fixa
- **Contexto:** no QA a nuvem **sumia** durante a expansão: escrever `amount` num `CPUParticles2D` reinicia o sistema, e o tween escrevia a cada frame.
- **Decisão:** o tween anima apenas o raio do `CircleShape2D` e o `emission_sphere_radius`; `amount` fica em 24 e a textura é **um** quadro 8×8 do sheet `SPR-SPORE` (`AssetResolver.atlas`), não a tira inteira de 32×8.
- **Consequências:** a nuvem fria fica mais densa e a quente mais espalhada, sem piscar. Anotado nas lições do `CLAUDE.md` se voltar a aparecer.
- **Data:** 2026-09-19

<a id="adr-f23-008"></a>
### ADR-F23-008 — A célula recusada não é reoferecida sem sair e voltar
- **Contexto:** o `Collectible` (F20) decide no `body_entered`; com CORROSÃO ativa a coleta devolve `false` e o item fica no chão, mas o sinal não repete enquanto o MU-7 continuar em cima.
- **Decisão:** aceitar o comportamento na Demo — o jogador sai de cima e volta (ou espera os 6 s longe dali).
- **Consequências:** se incomodar no playtest, a F20 passa a reavaliar a coleta enquanto houver corpo sobreposto.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.6.2-D/F · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scripts/core/status_effects.gd` (os 5 status do GDD, duração, renovação, consulta e modificadores combinados), integração no `GameState` (`statuses`, `apply_status`, tick, guarda no `add_charge`, limpeza no respawn/novo jogo/load), guarda de CORROSÃO na Célula de Energia, `scenes/enemies/spore_swarm.tscn` + `spore_swarm.gd` (nuvem `DamageArea` com partículas 2D que cresce/encolhe por `energy_changed`), `tests/test_status_effects.gd`, `tests/test_game_state_status.gd`, `tests/test_enemy_scenes.gd`, sandbox `tests/qa/scenes/spore_sandbox.tscn` + roteiro `tests/qa/f23_esporos.json`. ADRs F23-004 a F23-008.
- **Portões**: import limpo · 399 testes, 0 falhas · 48 cenas no smoke, 0 erros · varreduras 3D e de comentários vazias.
- **QA lido**: nuvem quente (raio 48) no início; dentro dela Integridade 100 → 95 em ~1 s (5/s) com o ícone CORROSÃO 6 s no HUD; Célula pega normalmente antes da nuvem (+40) e **recusada** em cima dela com CORROSÃO ativa; na doca a Carga trava em 83 enquanto o ícone conta 4 → 1 (o reparo continua); ícone some e a Carga volta a subir (83 → 87 → 100); `heating` desligado encolhe a nuvem para raio 24 e ligado devolve 48.
- **Pendência**: só a CORROSÃO tem fonte na Demo; os outros 4 status estão definidos e testados, mas ninguém os emite (F48).
- **Próximo passo**: F29 coloca os `~` na Estufa apontando para `greenhouse`/`heating` e a F17 liga o sinal de verdade.
