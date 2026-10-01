---
id: F17
title: Terminal de Distribuição de Energia
status: done
scope: demo
block: 2
priority: P0
rubric: ["Puzzle"]
depends_on: ["F02", "F12", "F15", "F16", "F21"]
unblocks: ["F18", "F23", "F25", "F27", "F28", "F29"]
estimate: 4h
last_updated: 2026-09-19
---

# F17 — Terminal de Distribuição de Energia ⭐

## 1. Contexto e objetivo

**Esta é a mecânica que nunca pode ser cortada** ([GDD-2.10](../design/GDD.md#gdd-2-10-cortes)): *"NUNCA CORTAR: o Terminal de Distribuição de Energia. Ele é o jogo."*

Cada setor tem um **orçamento fixo** de energia e **mais sistemas do que orçamento**. Não existe estado em que tudo está ligado: ligar o quinto sistema exige desligar um dos quatro. O jogador abre o terminal, vê os sistemas do setor e move as unidades de energia entre eles; **o mundo reage na hora** — luz acende, porta abre, planta cresce, plataforma anda, esporos se expandem. *O nível não muda de forma, muda de ESTADO: o mesmo corredor é três corredores diferentes dependendo do que está ligado.*

Serve diretamente ao pilar **ESCASSEZ** e é o item **Puzzle** da rubrica. A demo entrega dois puzzles: o tutorial do Núcleo Central (**3 sistemas / 1 energia** desde a [F36](F36-tutorial-briefing.md)) e o da Estufa (**5 sistemas / 2 energias**, com dependência em cadeia e duas rotas de solução).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.5 Regra de energia](../design/GDD.md#gdd-2-5-energia) (**a regra mais importante do jogo**) · [GDD-2.6.1 Redirecionamento de energia](../design/GDD.md#gdd-2-6-1-redirecionamento) · [GDD-2.3 Loop principal](../design/GDD.md#gdd-2-3-macro) (passos 3–7) · [GDD-2.7 F0](../design/GDD.md#gdd-2-7-f0) (tutorial 2 sistemas/1 energia) · [GDD-2.7 F1](../design/GDD.md#gdd-2-7-f1) (luz de crescimento × lanterna do corredor) · [GDD-2.7 Curva](../design/GDD.md#gdd-2-7-curva) (complexidade do puzzle como eixo de dificuldade) · [GDD-2.5 Vitória por fase](../design/GDD.md#gdd-2-5-vitoria) (religar o Nó → +15%) · [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx) (clique de disjuntor + a sala inteira mudando de som)
- **Parâmetros:** `Balance.REACTOR_SECTOR_BONUS` (usado pela F14 ao ouvir `sector_restored`). Orçamento e custos **não** são `Balance`: são dados de puzzle em `data/energy/*.json` (ADR-F17-002).
- **Jornada:** [Ideia principal](../design/JORNADA-DO-HEROI.md#jh-ideia) ("ligar uma coisa significa desligar outra") · [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3) (Helena ensina a redirecionar energia) · [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) (conteúdo em JSON) · [ADR-004](../DECISIONS.md#adr-004) (fases em ASCII + metadados) · [ADR-009](../DECISIONS.md#adr-009) (nunca cortar)
- **Assets:** [SPR-TERMINAL](../ASSETS.md#spr-terminal) · [SPR-DOOR](../ASSETS.md#spr-door) · [UI-FONT](../ASSETS.md#ui-font) · [SFX-PACK](../ASSETS.md#sfx-pack)

## 3. Critério de avaliação atendido

- **Puzzle:** o puzzle central do jogo, com duas instâncias jogáveis na demo e solução não única.

**Como o avaliador vê (roteiro §4 do [ENTREGAS](../ENTREGAS.md#apresentacao)):** no Núcleo Central o apresentador abre o terminal, tenta ligar a porta e recebe "ENERGIA INSUFICIENTE"; desliga a iluminação, a sala escurece de verdade e a porta abre. Na Estufa, com 2 energias e 5 sistemas, ele mostra que ligar a luz de crescimento apaga o corredor e que desligar o aquecimento encolhe os esporos — e que existe mais de uma rota até o Nó.

## 4. Escopo

### Inclui
- **Lógica pura** `scripts/core/energy_grid.gd` (`class_name EnergyGrid`): orçamento, sistemas, custos, dependências (`requires`), cascata ao desligar, validação do JSON, serialização do estado. 100% testável headless.
- **Dados** `data/energy/<terminal>.json` (esquema completo na §6), com os efeitos no mundo declarados por alvo (`group:` / `id:`).
- **Rede da fase** `scenes/world/energy_network.gd` (`Node`, grupo `energy_network`): carrega os terminais da fase, restaura o estado de `GameState.energy_states`, aplica efeitos no mundo e emite `EventBus.energy_changed`.
- **Terminal físico** `scenes/world/distribution_terminal.tscn` (+ `.gd`): `Interactable` (F16) que abre a UI; também cobre o papel de **Nó de Energia do setor** (`role: "sector_node"`) e de **console repetidor** (vários consoles, mesmo `terminal_id`).
- **UI** `scenes/ui/energy_terminal_ui.tscn` (+ `.gd`): navegável por **teclado e controle**, lista de sistemas, medidor de energia, descrição, mensagens de erro em pt-BR, sem mouse obrigatório.
- **Reação do mundo** por contrato `set_powered(on: bool)` (duck-typing) em: porta (`|`), lâmpada (`@`, F18), planta que cresce (`g`, F25), plataforma móvel (`m`, F25), enxame de esporos (`~`, F23), aquecimento/ventilação (efeito ambiente do setor), piso eletrificado (`z`, F32).
- **Persistência**: `GameState.energy_states[terminal_id] = Array[StringName]` (ligados), salvo pela F11; ao recarregar a fase (respawn/load) o mundo volta ao mesmo estado.
- **Design dos dois puzzles da demo** (§6.6), com dados prontos para F28/F29.
- Emissão de `sector_restored(&"greenhouse")` pelo Nó de Energia + abertura do log de upgrade da Helena.

### Não inclui
- Layout físico das fases (onde fica cada porta/planta/plataforma) — F28/F29 (aqui fica a **proposta** de design e os JSONs de energia).
- As entidades em si: porta é da F17 (ver abaixo), lâmpada F18, planta/plataforma F25, esporos F23, piso elétrico F32. A F17 define **o contrato** `set_powered`.
- Acesso Root / sobrecarregar terminal — Final (F49).
- Puzzles de 6 sistemas/3 energias com cadeia longa (Docas) — Final.
- Mini-jogo de cabos, arrastar com mouse, animação 3D de painel — fora de escopo.

> **Porta de energia (`|`)**: `scenes/world/door.tscn` é criada **nesta feature** (é o efeito mais direto do terminal e o tutorial depende dela).

## 5. Critérios de aceite

- [x] `EnergyGrid` recusa ligar um sistema sem orçamento livre e devolve o motivo `NO_BUDGET`; a UI mostra `ENERGIA INSUFICIENTE — DESLIGUE UM SISTEMA`.
- [x] `EnergyGrid.validate()` falha quando a soma dos custos ≤ orçamento (**sempre** deve haver escassez), quando um `requires` aponta para id inexistente e quando há ciclo de dependência — com teste para cada caso.
- [x] Desligar um sistema do qual outro depende desliga o dependente em cascata, e a UI informa `DESLIGADO EM CADEIA: <NOME>`.
- [x] Ligar um sistema cujo `requires` não está ligado é recusado com `MISSING_DEPENDENCY` e mensagem `REQUER: <NOME>`.
- [x] O estado inicial de cada terminal vem do JSON (`initial`) e respeita o orçamento (validado em teste).
- [x] Ao alternar um sistema: `EventBus.energy_changed(terminal_id, system_id, powered)` é emitido **uma vez por sistema afetado** (inclusive os desligados em cascata) e o mundo reage **imediatamente** (porta abre, luz acende, planta cresce).
- [x] A UI abre com `interact` no terminal, navega com ↑/↓ (teclado e d-pad/analógico), alterna com `E`/`ESPAÇO`/`A` e fecha com `ESC`/`B`; o mouse é opcional e não é necessário em nenhuma etapa.
- [x] Enquanto a UI está aberta, o jogador não se move, não toma dano de contato e o reator **continua caindo** ([ADR-F14-004](F14-estabilidade-reator.md)).
- [x] Dois consoles com o mesmo `terminal_id` mostram e alteram o mesmo estado.
- [x] Morrer e renascer (ou salvar/carregar) mantém exatamente os sistemas ligados; o mundo é reconstruído coerente **sem** tocar SFX de ligar/desligar.
- [x] Tutorial (`core_hub`): 3 sistemas, 1 energia; é impossível ter luz e porta ao mesmo tempo, e o elevador opcional obriga a gastar e depois devolver a energia.
- [x] Estufa (`greenhouse`): 5 sistemas, 2 energias, com pelo menos **duas** sequências distintas que levam ao Nó (rota da planta e rota da plataforma) — verificadas por teste de simulação.
- [x] Religar o Nó emite `sector_restored` uma única vez, soma +15% no reator (F14), salva (F11) e abre o log da Helena com as Garras (F19/F24).
- [x] Todo texto exibido é pt-BR com acentos; ids e código em inglês.
- [x] **O painel diz o que o jogador quer conseguir:** cada terminal declara `goal_text` / `goal_done_text` / `goal_systems` no JSON, e a linha `META:` aparece em destaque logo abaixo do título; cumprida a meta, o texto vira `META CUMPRIDA:` e muda de cor.
- [x] **Cada sistema diz para que serve:** `tag` obrigatória por sistema (`ROTA`, `VISÃO`, `META`, `PERIGO`), exibida na linha; o sistema que abre a meta é o único marcado `META` (validado em teste de dados).
- [x] **A consequência aparece antes de confirmar:** o sistema selecionado mostra `AO LIGAR: <description>` quando desligado e `AO DESLIGAR: <effect_off>` quando ligado.
- [x] **A troca é explícita:** com o orçamento cheio, o painel mostra `LIGAR EXIGE DESLIGAR: <A> ou <B>` **antes** da tentativa, e a recusa vira `ENERGIA INSUFICIENTE - DESLIGUE: <A> ou <B>` — a lista sai de `EnergyGrid.shutdown_candidates()`, que exclui o que o próprio sistema exige (`requires`) e o que está selado.
- [x] **ÓRBITA comenta a mudança:** ao fechar o painel com o estado realmente alterado, uma fala **ambiente** (não congela o timer) descreve o efeito no mundo em uma frase; os textos moram em `data/dialogue/<setor>.json` e a mesma fala nunca sai duas vezes seguidas.
- [x] **A regra do jogo é lembrada na Estufa:** na primeira abertura do terminal da Estufa, `intro_bark` dispara "Dois circuitos para cinco sistemas. Alguma coisa vai ficar no escuro." (uma vez só, por `GameState.flags`).
- [x] As bancadas `core_test` e `energy_test` declaram `objective` no JSON da fase, então a linha de missão do HUD aparece fora das fases reais.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### 6.1 Cenas e scripts
```
scripts/core/energy_grid.gd              class_name EnergyGrid (pura, RefCounted)
scenes/world/energy_network.gd           Node — rede da fase (grupo "energy_network")
scenes/world/distribution_terminal.tscn  (+ .gd) terminal físico / console / Nó de setor
scenes/world/door.tscn                   (+ .gd) porta de energia (set_powered)
scenes/ui/energy_terminal_ui.tscn        (+ .gd) UI do terminal
data/energy/core_hub.json
data/energy/greenhouse.json
tests/test_energy_grid.gd
tests/test_energy_data.gd
scenes/dev/energy_test.tscn   bancada da Estufa (5 sistemas / 2 unidades)
scenes/dev/core_test.tscn     bancada do tutorial (3 sistemas / 1 unidade)
tests/test_energy_network.gd  integração: rede + mundo + persistência
```

### 6.2 `energy_grid.gd` (lógica pura)

```gdscript
class_name EnergyGrid
extends RefCounted

enum Result { OK, NO_BUDGET, MISSING_DEPENDENCY, UNKNOWN_SYSTEM, ALREADY_ON, ALREADY_OFF, LOCKED }

var id: StringName
var title: String
var budget: int
var systems: Array[Dictionary]          # {id, name, description, cost, requires, locked, effects}

static func from_dict(data: Dictionary) -> EnergyGrid
func validate() -> PackedStringArray
func system(system_id: StringName) -> Dictionary
func system_ids() -> Array[StringName]
func is_powered(system_id: StringName) -> bool
func powered() -> Array[StringName]
func used() -> int
func free_units() -> int
func can_power(system_id: StringName) -> Result
func power_on(system_id: StringName) -> Array[StringName]      # ids ligados (0 ou 1)
func power_off(system_id: StringName) -> Array[StringName]     # ids desligados (inclui cascata)
func toggle(system_id: StringName) -> Dictionary               # {result, on: [], off: []}
func set_state(ids: Array) -> void
func get_state() -> Array[StringName]
func dependents_of(system_id: StringName) -> Array[StringName]
```

Regras:
- `used()` = soma dos `cost` dos ligados; `free_units()` = `budget - used()`.
- `can_power`: id inexistente → `UNKNOWN_SYSTEM`; já ligado → `ALREADY_ON`; `locked` → `LOCKED`; algum `requires` desligado → `MISSING_DEPENDENCY`; `cost > free_units()` → `NO_BUDGET`; senão `OK`.
- `power_off` desliga o sistema e, recursivamente, todos que dependem dele (cascata), retornando a lista na ordem em que caíram.
- `toggle` decide por `is_powered` e devolve o que mudou + o motivo em caso de falha.
- `validate()` (erros como `String` legível, usados no teste de dados):
  - `budget >= 1`;
  - ids únicos e não vazios; `cost >= 1`;
  - **soma dos custos > budget** (garante a regra do GDD: nunca tudo ligado);
  - cada `requires` existe e não é o próprio sistema; sem ciclos (DFS);
  - `initial` cabe no orçamento e respeita `requires`.
- Nenhum acesso a `Node`, `get_tree()` ou `FileAccess` dentro de `EnergyGrid` (o JSON já chega como `Dictionary`).

### 6.3 Esquema de `data/energy/<terminal>.json`

```json
{
  "id": "greenhouse",
  "title": "ESTUFA - DISTRIBUIÇÃO",
  "budget": 2,
  "initial": ["heating", "corridor_light"],
  "systems": [
    {
      "id": "heating",
      "name": "AQUECIMENTO DO MÓDULO",
      "description": "Mantém a hidráulica e o solo aquecidos. O calor faz os esporos se expandirem.",
      "cost": 1,
      "requires": [],
      "locked": false,
      "effects": [
        { "target": "group:gh_spores", "action": "power" },
        { "target": "group:gh_heat_vents", "action": "power" }
      ]
    }
  ]
}
```

| Campo | Tipo | Obrigatório | Significado |
|---|---|:--:|---|
| `id` | string | sim | Igual ao nome do arquivo; usado em `GameState.energy_states` e em `energy_changed` |
| `title` | string | sim | Cabeçalho da UI (pt-BR, caixa alta) |
| `budget` | int ≥ 1 | sim | Unidades de energia do setor |
| `goal_text` | string | sim | A meta do setor enquanto pendente (`META: <texto>` no topo do painel) |
| `goal_done_text` | string | sim | A mesma meta já cumprida (`META CUMPRIDA: <texto>`) |
| `goal_systems` | array de ids | sim | Sistemas que, ligados, cumprem a meta |
| `intro_bark` | id de sequência | não | Fala ambiente na **primeira** abertura do terminal (uma vez, via `GameState.flags`) |
| `initial` | array de ids | sim | Sistemas ligados ao entrar na fase pela primeira vez |
| `systems[].id` | string | sim | Id em inglês, snake_case |
| `systems[].name` | string | sim | Nome mostrado (pt-BR) |
| `systems[].description` | string | sim | Uma linha explicando o que acontece **ao ligar** (o jogador decide por aqui) |
| `systems[].tag` | string | sim | Etiqueta curta de função na linha: `ROTA`, `VISÃO`, `META`, `PERIGO` |
| `systems[].effect_off` | string | sim | Uma linha explicando o que se **perde ao desligar** |
| `systems[].bark_on` / `bark_off` | id de sequência | sim | Fala ambiente da ÓRBITA ao fechar o painel depois de ligar/desligar este sistema |
| `systems[].cost` | int ≥ 1 | sim | Unidades consumidas |
| `systems[].requires` | array de ids | não | Precisa estar ligado antes |
| `systems[].locked` | bool | não | Aparece na lista mas não pode ser alternado (narrativa / Final) |
| `systems[].effects[].target` | string | sim | `group:<nome_do_grupo>` ou `id:<entity_id da fase>` |
| `systems[].effects[].action` | string | sim | `power` (chama `set_powered(on)`) ou `invert` (chama `set_powered(not on)`) |

**Contrato do mundo:** todo nó alvo implementa `func set_powered(on: bool) -> void`. Alvos `id:` são resolvidos pelo grupo `entity:<id>` que o `LevelBuilder` (F21) adiciona a cada entidade com id no JSON da fase; alvos `group:` usam grupos definidos no JSON da fase (`"groups": ["gh_spores"]`).

### 6.4 `energy_network.gd` (cola entre dados, estado e mundo)

- Nó filho de `level_base` (F21), no grupo `energy_network`.
- `_ready()`: para cada id em `level_json.terminals`: carrega `data/energy/<id>.json`, `EnergyGrid.from_dict`, roda `validate()` (erro → `push_error` e aborta a fase em dev), restaura `GameState.energy_states.get(id, grid_from_initial)` com `set_state`, e aplica todos os efeitos **em silêncio** (`apply_all(silent = true)` — sem SFX, sem animação de porta).
- API:
```gdscript
func grid(terminal_id: StringName) -> EnergyGrid
func toggle(terminal_id: StringName, system_id: StringName) -> Dictionary
func apply_all(terminal_id: StringName, silent: bool) -> void
```
- `toggle`: chama `EnergyGrid.toggle`, e para **cada** sistema afetado: aplica efeitos (`set_powered`), grava `GameState.energy_states[terminal_id] = grid.get_state()` e emite `EventBus.energy_changed(terminal_id, system_id, powered)`. Toca `terminal_breaker` sempre, mais `power_on`/`power_off` conforme o resultado.
- Resolução de alvo: `group:` → `get_tree().get_nodes_in_group(nome)`; `id:` → `get_tree().get_nodes_in_group("entity:" + id)`; alvo sem `set_powered` → `push_warning` (fase incompleta, não quebra).

### 6.5 Terminal físico e UI

**`distribution_terminal.gd`** (`Interactable`, sprite [SPR-TERMINAL](../ASSETS.md#spr-terminal)):
```gdscript
@export var terminal_id: StringName
@export var role: StringName = &"console"     # console | sector_node
@export var sector_id: StringName = &""
@export var log_on_restore: StringName = &""
```
- `console`: `prompt_text = "ACESSAR TERMINAL"`; `interact()` → instancia `energy_terminal_ui.tscn` em `get_tree().current_scene`, passa `terminal_id` e o `EnergyNetwork`, trava o jogador (`set_input_locked(true)`), marca invencibilidade e espera o sinal `closed` para destravar. Sprite `active` enquanto aberto, `on` quando há energia no setor, `off` quando o setor está morto (`enabled = false`, prompt `TERMINAL SEM ENERGIA`).
- `sector_node`: `prompt_text = "RELIGAR NÓ DE ENERGIA"`; no `interact()`, se `sector_id` ainda não está em `GameState.sectors_restored`: adiciona, `EventBus.sector_restored.emit(sector_id)`, `AudioManager.play_sfx("power_on")`, `SaveManager.save_game()`, e, se `log_on_restore != &""`, `DialogueManager.open_log(log_on_restore)`. Depois vira `enabled = false` com prompt `NÓ RELIGADO`.
- Parâmetros vêm do JSON da fase (F21) via `configure(params: Dictionary)`.

**`energy_terminal_ui.tscn`** — `CanvasLayer` layer 20, `process_mode = PROCESS_MODE_ALWAYS`:
```
EnergyTerminalUI (CanvasLayer)
└─ Panel (PanelContainer 360 de largura, centralizado)
   ├─ Title (Label)            "ESTUFA - DISTRIBUIÇÃO"
   ├─ Goal (Label)             "META: Abrir a Porta do Nó do Setor e religar o Nó" (âmbar;
   │                            vira "META CUMPRIDA: ..." em ciano quando os goal_systems ligam)
   ├─ BudgetRow                Budget (Label) + Meter (ColorRect por unidade)
   ├─ List (VBoxContainer)     uma SystemRow (Button) por sistema
   ├─ Description (Label)      "AO LIGAR: ..." / "AO DESLIGAR: ..." (autowrap, 2 linhas)
   ├─ Message (Label)          troca disponível ou feedback transitório (autowrap, 2 linhas)
   └─ Hints (Label)            "SETAS SELECIONAR · E ALTERNAR · ESC SAIR"
```
`SystemRow`: `[lâmpada] PERIGO  AQUECIMENTO DO MÓDULO        1u   LIGADO`. A etiqueta do sistema da meta sai em âmbar, igual à linha `META` do topo — é o fio que liga "o que eu quero" a "qual linha faz isso".
`SystemRow`: `[■] AQUECIMENTO DO MÓDULO        1u   LIGADO` / `[ ] PORTA DO NÓ DO SETOR      1u   DESLIGADO`; sistema bloqueado mostra `[x]` e `SELADO`; dependência não satisfeita mostra `REQUER: <NOME>` em cinza.

Mensagens (pt-BR, na UI):

| Situação | Texto |
|---|---|
| `NO_BUDGET` | `ENERGIA INSUFICIENTE — DESLIGUE UM SISTEMA` |
| `MISSING_DEPENDENCY` | `REQUER: <NOME DO SISTEMA>` |
| `LOCKED` | `CIRCUITO SELADO` |
| cascata ao desligar | `DESLIGADO EM CADEIA: <NOMES>` |
| troca possível (permanente, sem erro) | `LIGAR EXIGE DESLIGAR: <A> ou <B>` |
| `NO_BUDGET` com candidatos | `ENERGIA INSUFICIENTE - DESLIGUE: <A> ou <B>` |
| sucesso ao ligar | `<NOME>: ONLINE` |
| sucesso ao desligar | `<NOME>: OFFLINE` |

Input: `_input()` com `set_input_as_handled()` para `ui_up`/`ui_down`/`move_up`/`move_down` (navegar, SFX `ui_move`), `interact`/`ui_accept`/`jump` (alternar, SFX `terminal_breaker`), `pause`/`ui_cancel` (fechar, SFX `ui_back`) — marcar como handled impede que `pause` abra o menu da F09. O foco começa no primeiro sistema; navegação circular.

### 6.6 Design dos dois puzzles da demo

#### A) Tutorial — Núcleo Central (`data/energy/core_hub.json`): **3 sistemas / 1 energia**

| Sistema | Custo | Estado inicial | Efeito no mundo |
|---|:--:|:--:|---|
| `lights_core` — `ILUMINAÇÃO DO NÚCLEO` | 1 | **ligado** | `group:core_lights` (lâmpadas `@` do Núcleo, F18) |
| `door_habitat` — `PORTA DO SETOR HABITACIONAL` | 1 | desligado | `id:door_habitat` (porta `|` para o corredor) |

**A lição:** o jogador chega com a sala iluminada, tenta ligar a porta e recebe `ENERGIA INSUFICIENTE`. Ele precisa **desligar a luz para abrir a porta** — e o Núcleo escurece de verdade, o que ensina a lanterna (F18) no mesmo movimento. Soma dos custos (2) > orçamento (1). É a regra do jogo na versão mais simples possível, exatamente como pede o [GDD-2.7 F0](../design/GDD.md#gdd-2-7-f0).

```json
{
  "id": "core_hub",
  "title": "NÚCLEO CENTRAL - DISTRIBUIÇÃO",
  "budget": 1,
  "initial": ["lights_core"],
  "systems": [
    { "id": "lights_core", "name": "ILUMINAÇÃO DO NÚCLEO",
      "description": "Lâmpadas de teto do Núcleo. Sem elas, só a lanterna do chassi.",
      "cost": 1, "requires": [],
      "effects": [{ "target": "group:core_lights", "action": "power" }] },
    { "id": "door_habitat", "name": "PORTA DO SETOR HABITACIONAL",
      "description": "Comporta que liga o Núcleo ao corredor habitacional e à Estufa.",
      "cost": 1, "requires": [],
      "effects": [{ "target": "id:door_habitat", "action": "power" }] }
  ]
}
```

#### B) Estufa (`data/energy/greenhouse.json`): **5 sistemas / 2 energias**, 2 rotas

| Sistema | Custo | Requer | Inicial | Efeito no mundo |
|---|:--:|---|:--:|---|
| `heating` — `AQUECIMENTO DO MÓDULO` | 1 | — | **ligado** | `group:gh_spores` (esporos expandidos, F23) + `group:gh_heat_vents` (vapor quente decorativo) |
| `corridor_light` — `ILUMINAÇÃO DO CORREDOR` | 1 | — | **ligado** | `group:gh_corridor_lamps` (lâmpadas `@` do corredor inferior, F18) |
| `grow_light` — `LUZ DE CRESCIMENTO` | 1 | — | desligado | `group:gh_grow_lamps` + `id:gh_plant_1` (planta vira plataforma, F25) |
| `lift_platform` — `PLATAFORMA DE CARGA` | 1 | `heating` | desligado | `id:gh_lift` (plataforma móvel vertical, F25) |
| `node_door` — `PORTA DO NÓ DO SETOR` | 1 | — | desligado | `id:gh_node_door` (porta `|` da câmara do Nó) |

Soma dos custos = 5 > orçamento = 2 ✔. Dois consoles com `terminal_id = "greenhouse"`: **console A** na entrada (perto do corredor) e **console B** na plataforma alta, ao lado da porta do Nó — sem o repetidor o jogador não conseguiria abrir a porta depois de subir.

**Tensões de design (as decisões que o jogador sente):**
1. **Luz de crescimento × iluminação do corredor** (literal do [GDD-2.7 F1](../design/GDD.md#gdd-2-7-f1)): ligar a planta apaga o corredor, e o corredor tem um poço com buracos — ou você anda de lanterna (gastando Carga), ou você volta e troca de novo.
2. **Aquecimento × esporos**: o aquecimento é o que mantém a **plataforma de carga** funcionando (`requires`), mas o calor expande o enxame de esporos que bloqueia a passagem pela trepadeira e causa CORROSÃO (impede recarga).
3. **Sempre falta 1 unidade para a porta do Nó**: chegar lá em cima é metade do problema; abrir é a outra.

**Rota 1 (planta):** desligar `heating` (esporos encolhem, caminho da trepadeira abre) → ligar `grow_light` (2/2 com `corridor_light`) → subir pela planta → no console B, desligar `corridor_light` → ligar `node_door` → entrar na câmara do Nó.
**Rota 2 (plataforma):** desligar `corridor_light` → ligar `lift_platform` (exige `heating` ligado) → subir pela plataforma **atravessando a zona de esporos expandida** (toma CORROSÃO, gasta Integridade) → no console B, desligar `lift_platform` (ou `heating`, que derruba o elevador em cascata) → ligar `node_door`.
**Rota 3 (opcional, coleta):** manter `corridor_light` e explorar o poço para achar o Dado de Pesquisa e a parede falsa (F27) antes de subir — custa tempo de reator.

Cada rota é uma combinação válida: *"não existe combinação certa única — existe a combinação que abre a rota que você quer usar"* ([GDD-2.3](../design/GDD.md#gdd-2-3-macro)).

**Nó de Energia:** dentro da câmara, um `T` com `role = "sector_node"`, `sector_id = "greenhouse"`, `log_on_restore = "log_gh_03"` (o log da Helena que libera as Garras Magnéticas — F19/F24). Religar → `sector_restored` → +15% no reator (F14), save (F11), música/luz do setor (F29).

### 6.7 Porta de energia (`door.tscn`)
`AnimatableBody2D` (camada `world`) + `AnimatedSprite2D` ([SPR-DOOR](../ASSETS.md#spr-door), 16×48, 3 tiles de altura ancorada no tile inferior) + `CollisionShape2D`. `set_powered(true)` → animação `opening` → `open` + colisão desligada + SFX `door_open`; `set_powered(false)` → fecha (se o jogador estiver no vão, empurra para fora pelo lado mais próximo). Em modo silencioso (restauração de estado) pula animação e SFX.

### 6.8 Autoloads / sinais do EventBus
- Emite: `energy_changed(terminal_id, system_id, powered)`, `sector_restored(sector_id)`.
- Escuta: nada obrigatório (o mundo reage por `set_powered`; sistemas externos podem escutar `energy_changed` para áudio/telemetria).
- Usa: `GameState.energy_states`, `GameState.sectors_restored`, `SaveManager.save_game()`, `AudioManager.play_sfx`, `DialogueManager.open_log`.

### 6.9 Dados (`data/`)
- `data/energy/core_hub.json`, `data/energy/greenhouse.json` (acima).
- Metadados de fase (F21) que a F17 consome: `"terminals": ["greenhouse"]`, `"groups"` por entidade, `"entities"` com `terminal`, `role`, `sector`, `log_on_restore`.

### 6.10 Input actions / camadas de colisão
- Ações: `interact` (abrir/alternar), `ui_up`/`ui_down`/`move_up`/`move_down` (navegar), `ui_accept`/`jump` (alternar), `ui_cancel`/`pause` (fechar).
- Terminal: `Interactable` na camada `interactable` (4). Porta: `world` (1).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-TERMINAL](../ASSETS.md#spr-terminal) | Terminal de Distribuição `off`/`on`/`active` (3f) | Caixa 24×28 cinza com tela verde (F05) |
| [SPR-DOOR](../ASSETS.md#spr-door) | Porta `closed`/`opening`(4f)/`open` + variante selada | Barra 16×48 cinza com faixa amarela (F05) |
| [UI-FONT](../ASSETS.md#ui-font) | Texto da UI do terminal (acentos, 8 px) | Fonte padrão |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `terminal_breaker`, `power_on`, `power_off`, `door_open`, `ui_move`, `ui_confirm`, `ui_back` | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_energy_grid.gd` (seção 10) → falha → `scripts/core/energy_grid.gd` → passa.
- [x] **Passo 2** — `data/energy/core_hub.json` e `data/energy/greenhouse.json` + `tests/test_energy_data.gd` (carrega, valida, simula as rotas).
- [x] **Passo 3** — `scenes/world/door.tscn` com `set_powered`.
- [x] **Passo 4** — `scenes/world/energy_network.gd` (carga, restauração silenciosa, `toggle`, efeitos, sinais, persistência em `GameState`).
- [x] **Passo 5** — `scenes/world/distribution_terminal.tscn` (console + Nó de setor) integrando com a F16.
- [x] **Passo 6** — `scenes/ui/energy_terminal_ui.tscn` + navegação teclado/controle + mensagens.
- [x] **Passo 7** — `scenes/dev/energy_test.tscn`: sala com 2 consoles `greenhouse`, uma porta, uma lâmpada placeholder e um nó dummy com `set_powered` que muda de cor — valida a cadeia inteira sem depender de F18/F23/F25.
- [x] **Passo 8** — Persistência: morrer/recarregar mantém estado (QA).
- [x] **Passo 9** — Portões + QA; revisar os textos em pt-BR (caixa alta, acentos).

## 10. Verificação

- **Testes (`tests/test_energy_grid.gd`):**
  - `test_initial_state_from_json` — `initial` liga exatamente os ids esperados; `used()` correto.
  - `test_power_on_without_budget` — com 2/2 em uso, `can_power` de um terceiro → `NO_BUDGET`; estado inalterado.
  - `test_power_on_after_power_off` — desligar 1 libera unidade e permite ligar outro.
  - `test_requires_blocks` — `lift_platform` com `heating` desligado → `MISSING_DEPENDENCY`.
  - `test_cascade_off` — com `heating` e `lift_platform` ligados, `power_off("heating")` retorna `["heating", "lift_platform"]`.
  - `test_toggle_returns_reason` — `toggle` de sistema sem orçamento devolve `result == NO_BUDGET` e listas vazias.
  - `test_state_roundtrip` — `get_state()` → `set_state()` reproduz `used()`/`powered()` idênticos.
  - `test_validate_detects_no_scarcity` — grid com soma de custos == budget → erro "sem escassez".
  - `test_validate_detects_unknown_requirement` e `test_validate_detects_cycle`.
  - `test_validate_detects_invalid_initial` — `initial` acima do orçamento → erro.
- **Testes (`tests/test_energy_data.gd`)** — carregam os JSONs reais:
  - `test_all_energy_json_load_and_validate` — todo arquivo em `data/energy/` carrega, `validate()` vazio.
  - `test_core_hub_is_two_one` — 2 sistemas, budget 1, impossível ligar ambos.
  - `test_greenhouse_route_plant` — sequência `off heating`, `on grow_light`, `off corridor_light`, `on node_door` → todos `OK` e `node_door` ligado no fim.
  - `test_greenhouse_route_lift` — sequência `off corridor_light`, `on lift_platform`, `off lift_platform`, `on node_door` → todos `OK`.
  - `test_greenhouse_cannot_power_everything` — não existe estado com 3 sistemas ligados.
  - `test_effect_targets_have_prefix` — todo `target` começa com `group:` ou `id:` e toda `action` é `power`/`invert`.
- **Smoke:** `res://scenes/world/distribution_terminal.tscn`, `res://scenes/world/door.tscn`, `res://scenes/ui/energy_terminal_ui.tscn`, `res://scenes/dev/energy_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f17_terminal.json`; cena `res://scenes/dev/energy_test.tscn`, que carrega o terminal `greenhouse` com dois consoles, uma porta `id:gh_node_door`, uma lâmpada `group:gh_corridor_lamps` e um dummy `id:gh_plant_1`):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | — | `f17_01_sala` | Sala com lâmpada do corredor **acesa**, porta **fechada**, planta pequena |
| 30 | `interact` (no console A) | — | — |
| 45 | — | `f17_02_ui_aberta` | Painel "ESTUFA — DISTRIBUIÇÃO", `ENERGIA: 2/2 EM USO`, `AQUECIMENTO` e `ILUMINAÇÃO DO CORREDOR` marcados `[■]` |
| 50 | `ui_down` ×2 até `LUZ DE CRESCIMENTO`; `interact` | — | — |
| 60 | — | `f17_03_sem_energia` | Mensagem `ENERGIA INSUFICIENTE — DESLIGUE UM SISTEMA`; nada mudou na sala |
| 70 | `ui_up` ×2 até `AQUECIMENTO`; `interact` | — | — |
| 80 | — | `f17_04_desligou` | `AQUECIMENTO ... OFFLINE`, medidor `1/2`, dummy de esporos encolhido |
| 90 | `ui_down` ×2; `interact` (LUZ DE CRESCIMENTO) | — | — |
| 105 | — | `f17_05_planta` | `2/2`, planta (dummy) grande — **mundo reagiu com a UI aberta** |
| 115 | `ui_cancel` | — | — |
| 130 | — | `f17_06_mundo` | UI fechada, jogador livre, corredor aceso, planta grande, porta fechada |
| 140–260 | andar até o console B; `interact`; desligar `ILUMINAÇÃO DO CORREDOR`; ligar `PORTA DO NÓ` | — | — |
| 280 | — | `f17_07_porta_aberta` | Corredor **escuro**, porta **aberta** |
| 300 | andar até o Nó; `interact` | `f17_08_no_religado` | Prompt `NÓ RELIGADO`, log da Helena abrindo (se F19 pronta), HUD com reator +15% |

- Teste manual de persistência: morrer (ou salvar e carregar) depois do frame 280 e conferir que a porta continua aberta e o corredor apagado, **sem** som de porta.
- **Playtest humano (obrigatório nesta feature):** pedir ao humano para resolver a Estufa sem dicas e responder: "em algum momento você entendeu que precisava desligar algo para ligar outra coisa? qual foi a decisão mais difícil?".

## 11. ADRs locais

### ADR-F17-001 — Ligar exige desligar manualmente (sem troca automática)
- **Contexto:** poderíamos desligar o sistema mais barato automaticamente para caber o novo.
- **Decisão:** a UI **recusa** e informa `ENERGIA INSUFICIENTE — DESLIGUE UM SISTEMA`. O jogador escolhe o que sacrificar.
- **Consequências:** a escolha (pilar ESCASSEZ) fica explícita e o tutorial ensina a regra em uma tentativa.
- **Data:** 2026-09-19

### ADR-F17-002 — Orçamento e custos são dados, não `Balance`
- **Contexto:** a regra do `/CLAUDE.md` §4.2 manda números em `Balance`, mas orçamento/custo são **conteúdo de puzzle** por setor, não tuning global.
- **Decisão:** viver em `data/energy/*.json` ([ADR-006](../DECISIONS.md#adr-006)), validados por teste. `Balance` guarda só o bônus do reator ao religar o setor.
- **Consequências:** editar um puzzle não exige tocar em código; o teste de dados protege contra JSON inválido.
- **Data:** 2026-09-19

### ADR-F17-003 — Efeitos no mundo declarados no JSON por `group:`/`id:` e contrato `set_powered`
- **Contexto:** o mundo precisa reagir "na hora" sem que o terminal conheça portas, plantas ou esporos.
- **Decisão:** cada sistema declara alvos; o `EnergyNetwork` resolve por grupo (`entity:<id>` vindo do LevelBuilder) e chama `set_powered(on)`. Quem não implementa gera `push_warning`.
- **Consequências:** F18/F23/F25/F32 só precisam implementar um método; a mesma configuração vale para restauração silenciosa após respawn.
- **Data:** 2026-09-19

### ADR-F17-004 — Estado por terminal em `GameState.energy_states`, restaurado em silêncio
- **Contexto:** respawn recarrega a fase (ADR-F13-005) e o save (F11) precisa reproduzir o setor.
- **Decisão:** `energy_states[terminal_id] = Array[StringName]` com os ligados; ao carregar, aplicar efeitos com `silent = true` (sem SFX/animação).
- **Consequências:** o jogador nunca perde o progresso do puzzle ao morrer; o save fica pequeno e legível.
- **Data:** 2026-09-19

### ADR-F17-005 — Vários consoles para o mesmo terminal
- **Contexto:** na Estufa, a porta do Nó fica longe do console de entrada; sem repetidor o puzzle vira ida e volta chata.
- **Decisão:** `terminal_id` pode se repetir em vários `T`; todos operam a mesma `EnergyGrid`.
- **Consequências:** level design ganha liberdade; o teste de dados não precisa saber quantos consoles existem.
- **Data:** 2026-09-19

### ADR-F17-006 — Nó de Energia é o mesmo objeto com `role = "sector_node"`
- **Contexto:** a legenda ASCII não tem caractere para o Nó, e ele é um "terminal que você liga uma vez".
- **Decisão:** reaproveitar `T` com `role` no JSON da fase; ele emite `sector_restored` e abre o log de upgrade.
- **Consequências:** zero caractere novo na legenda (F21); F29 só configura parâmetros.
- **Data:** 2026-09-19

### ADR-F17-007 — A rede carrega por `load_terminals()`, não no `_ready()`
- **Contexto:** a §6.4 previa carregar os terminais no `_ready()` do `EnergyNetwork`. Em Godot o `_ready()` dos filhos roda **antes** do `_ready()` do pai, ou seja, antes de `LevelBuilder.build_entities()` — a rede aplicaria os efeitos num mundo vazio.
- **Decisão:** o `EnergyNetwork` só age quando a fase chama `load_terminals(ids)` (contrato que a `level_base.gd` da F21 já usa, depois de construir as entidades).
- **Consequências:** o estado restaurado alcança todas as entidades; a cena da rede continua carregável sozinha no smoke.
- **Data:** 2026-09-19

### ADR-F17-008 — A UI do terminal não pausa a árvore; o reator continua caindo
- **Contexto:** "congelar o jogo" enquanto o painel está aberto poderia ser feito com `get_tree().paused = true`, mas isso também congelaria o `GameState._process` e, com ele, o timer do reator.
- **Decisão:** a UI **não** pausa a árvore. Ela trava o jogador (`set_input_locked(true)`) e o torna invulnerável (`set_invincible(true)`, novo em `mu7.gd`), e marca o input como tratado para o menu de pausa não abrir por cima. O reator **continua caindo**, como manda [GDD-2.5](../design/GDD.md#gdd-2-5-energia) (só pause, diálogo e log congelam) e [ADR-F14-004](F14-estabilidade-reator.md).
- **Consequências:** decidir custa tempo — é o pilar ESCASSEZ. Divergência registrada em relação ao pedido de "não deixar o timer correr": o design manda ([CLAUDE.md §2.6]).
- **Data:** 2026-09-19

### ADR-F17-009 — O `EnergyNetwork` aplica e só depois anuncia
- **Contexto:** o ADR-011 global manda os nós reagirem a `energy_changed` pelo grupo `powered`; a §6.3 desta feature manda o terminal aplicar os `effects` declarados no JSON. Rodar os dois causaria chamada dupla.
- **Decisão:** o `EnergyNetwork` é a autoridade. Para cada sistema afetado ele resolve **os dois** conjuntos de alvos (grupo `powered` com `terminal_id`/`system_id` casando, mais os `effects` `group:`/`id:`), chama `set_powered` (ou `set_powered_silent`) uma única vez por nó, grava `GameState.energy_states` e **só então** emite `energy_changed`. `set_powered` é idempotente em todos os nós, então quem também escuta o barramento não faz nada.
- **Consequências:** restauração silenciosa funciona mesmo para nós que só escutam o sinal; alvo sem `set_powered` vira `push_warning`; grupo vazio é silencioso (a fase pode não ter aquele objeto ainda).
- **Data:** 2026-09-19

### ADR-F17-010 — Medidor e marcador de sistema são `ColorRect`, não glifos
- **Contexto:** a §6.5 desenhava a UI com `■ □` e `↑↓`. A fonte do jogo (m5x7) **não tem** esses glifos — conferido com `Font.has_char` (`■ □ ↑ ↓ ▮ ▼ — •` todos `false`).
- **Decisão:** o medidor de orçamento e o marcador de cada sistema são `ColorRect` coloridos (aceso/apagado/selado); as dicas usam palavras (`SETAS SELECIONAR · E ALTERNAR · ESC SAIR`) e o separador `·`, que existe na fonte.
- **Consequências:** zero tofu, leitura melhor em 384×216 e as cores viram informação. **Pendência para a F15/F19:** `hud.tscn` e `dialogue_box.tscn` ainda usam `▮` e `▼`.
- **Data:** 2026-09-19

### ADR-F17-011 — O Nó do setor continua interativo depois de religado
- **Contexto:** a §6.5 pedia `enabled = false` com prompt `NÓ RELIGADO`. Na F16 um `Interactable` com `enabled = false` é **descartado** pelo seletor de alvo, ou seja, não mostra prompt nenhum.
- **Decisão:** o Nó continua `enabled`, troca o prompt para `NÓ DO SETOR RELIGADO` e ignora novas interações por flag interna (`_restored`), de modo que `sector_restored` só sai uma vez.
- **Consequências:** o jogador vê que aquilo já foi feito, em vez de o objeto ficar mudo.
- **Data:** 2026-09-19

### ADR-F17-012 — Os termos da UI vêm do GLOSSARY
- **Contexto:** esta feature escrevia "Nó de Energia"; o [GLOSSARY](../GLOSSARY.md) registra **Nó do setor**.
- **Decisão:** a UI usa `RELIGAR NÓ DO SETOR`, `NÓ DO SETOR RELIGADO`, `PORTA DO NÓ DO SETOR`, `ORÇAMENTO DE ENERGIA` e `TERMINAL DE DISTRIBUIÇÃO`. Títulos dos JSONs usam `-` no lugar de `—` (a fonte não tem travessão).
- **Consequências:** vocabulário único entre GDD, glossário e tela.
- **Data:** 2026-09-19

### ADR-F17-013 — A meta do setor é dado do terminal, não texto de cena
- **Contexto:** o playtest humano devolveu "ficou confuso para mim o que preciso fazer, qual a ordem, objetivo". O painel mostrava estado (o quê está ligado) mas nunca intenção (o quê eu quero).
- **Decisão:** cada `data/energy/*.json` declara `goal_text`, `goal_done_text` e `goal_systems`. A UI mostra `META: <goal_text>` abaixo do título e troca para `META CUMPRIDA: <goal_done_text>` (e de âmbar para ciano) quando **todos** os `goal_systems` estão ligados. `validate()` exige os três campos e que cada `goal_system` exista.
- **Alternativas:** reaproveitar `GameState.current_objective` (a linha do HUD) — recusada: o objetivo do HUD é da fase inteira ("atravessar o Habitacional"), a meta do painel é o que **este terminal** resolve, e os dois coexistem na mesma tela.
- **Consequências:** o painel abre respondendo "para que eu vim aqui"; o estado cumprido é derivado do puzzle, sem flag nova em `GameState`.
- **Data:** 2026-09-19

### ADR-F17-014 — Etiqueta de função por sistema, com `META` reservada ao sistema da meta
- **Contexto:** cinco linhas com nome e custo não dizem **por quê** trocar uma pela outra.
- **Decisão:** campo `tag` obrigatório por sistema (`ROTA`, `VISÃO`, `META`, `PERIGO`), exibido em coluna própria de 46 px. O código **não** compara com a string `"META"`: a linha destacada em âmbar é a que está em `goal_systems`. A convenção "sistema da meta usa a etiqueta META" é garantida por teste de dados (`test_goal_systems_carry_the_goal_tag`), não por lógica.
- **Consequências:** a leitura fica "PERIGO/VISÃO/ROTA/META" em vez de cinco nomes iguais; a `EnergyGrid` continua pura e agnóstica de idioma.
- **Data:** 2026-09-19

### ADR-F17-015 — `shutdown_candidates()` responde "o que dá para desligar" na lógica pura
- **Contexto:** `ENERGIA INSUFICIENTE - DESLIGUE UM SISTEMA` manda o jogador adivinhar **qual**; na Estufa, desligar o `AQUECIMENTO` para ligar a `PLATAFORMA DE CARGA` é justamente a tentativa que nunca funciona (a plataforma depende dele).
- **Decisão:** `EnergyGrid.shutdown_candidates(system_id)` devolve só os candidatos que **realmente** resolvem: descarta o fecho transitivo de `requires` do alvo, os selados e os que não liberam orçamento suficiente. Simula por `get_state()`/`power_off()`/`set_state()` e restaura o estado — a consulta não altera nada (teste `test_shutdown_candidates_preserve_state`). A UI usa a lista duas vezes: de forma permanente (`LIGAR EXIGE DESLIGAR: ...`) e na recusa (`ENERGIA INSUFICIENTE - DESLIGUE: ...`).
- **Consequências:** o custo da escolha aparece **antes** do erro; a regra continua em lógica testável, não em texto de UI.
- **Data:** 2026-09-19

### ADR-F17-016 — ÓRBITA comenta ao fechar o painel, em modo ambiente e sem repetir a fala anterior
- **Contexto:** o mundo reage na hora, mas o jogador está com o painel na frente e não vê a sala mudar; ao sair, não sabe o que mudou.
- **Decisão:** `EnergyNetwork` guarda um retrato do estado em `begin_session()` (abertura) e, em `announce_change()` (fechamento), dispara a fala do **último** sistema alterado (`bark_on`/`bark_off` do JSON) **apenas** se o estado final for diferente do inicial e se a fala não for igual à anterior (`_last_bark`). Todas as falas são `mode: "ambient"` e `once: false` — não congelam o timer do reator ([ADR-F17-008](#adr-f17-008)) e podem repetir em outra visita.
- **Alternativas:** uma fala por sistema afetado (vira parede de texto a cada troca) e fala na hora do clique (fica atrás do painel).
- **Consequências:** o jogador sai do terminal sabendo o que perdeu e o que ganhou, em uma frase, no tom da ÓRBITA. Teste de dados garante que toda fala referenciada existe, é ambiente e é repetível.
- **Data:** 2026-09-19

### ADR-F17-017 — `description` é o "ao ligar"; `effect_off` é o "ao desligar"
- **Contexto:** a §6.3 já pedia que `description` fosse "uma linha explicando a consequência", mas a UI a mostrava solta, sem dizer de qual lado da troca ela falava.
- **Decisão:** a `description` passa a ser lida (e rotulada) como `AO LIGAR:`; o campo novo `effect_off` (obrigatório) fornece o `AO DESLIGAR:`. Evita um terceiro texto por sistema e mantém o painel em duas linhas.
- **Consequências:** o mesmo espaço de tela informa os dois lados da decisão; `validate()` exige `effect_off`, então nenhum sistema entra no jogo sem dizer o que custa desligá-lo.
- **Data:** 2026-09-19

### ADR-F17-018 — `data/objectives.json` também passa a dizer "Nó do Setor"
- **Contexto:** o painel (ADR-F17-012) diz `PORTA DO NÓ DO SETOR` e a linha do HUD dizia "Religar o Nó de Energia da Estufa" — dois nomes para a mesma coisa na mesma tela.
- **Decisão:** `obj_restore_gh` e `obj_reach_node` passam a usar **Nó do Setor**, como manda o [GLOSSARY](../GLOSSARY.md). Três suítes que fixavam o texto antigo foram atualizadas.
- **Consequências:** vocabulário único entre HUD, painel e glossário.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD, incluindo o design concreto dos dois puzzles da demo · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `EnergyGrid` (lógica pura), `EnergyNetwork`, `distribution_terminal`, `sector_node`, `door`, `energy_terminal_ui`, os dois JSONs de puzzle, duas fases de bancada (`core_test`, `energy_test`) e 84 testes novos (356 no total, 44 cenas no smoke). · **Próximo passo**: F23/F25 implementarem `set_powered` em esporos, planta e plataforma; F28/F29 posicionarem consoles e Nó nas fases reais.
- **Decisões**: ADR-F17-007 a ADR-F17-012 (acima).
- **QA**: `tests/qa/f17_tutorial.json` (cena `res://scenes/dev/core_test.tscn`) e `tests/qa/f17_estufa.json` (cena `res://scenes/dev/energy_test.tscn`), 25 screenshots lidas — prompt, painel, recusa por orçamento, dependência não satisfeita, cascata, troca luz↔porta com o mundo reagindo, persistência ao reabrir, foco preso no painel e Nó do setor religado abrindo o log da Helena com `BACKUP SALVO`.
- **Divergências**: (1) o reator **continua** caindo com o painel aberto (ADR-F17-008, segue o GDD e a ADR-F14-004, contraria o pedido de congelar o timer); (2) `data/levels/test_room.json` (fixture da F21) aponta lâmpadas para os sistemas `heater_core` e `grow_light` do terminal `core_hub`, que não existem no puzzle 2/1 do tutorial — inerte hoje, mas convém alinhar na F28; (3) `hud.tscn`/`dialogue_box.tscn` usam glifos que a m5x7 não tem (`▮`, `▼`).

### 2026-09-19 — Legibilidade do puzzle (retorno do jogador)
- **Origem**: **retorno real do jogador humano** no playtest obrigatório da §10 — *"ficou confuso para mim o que preciso fazer, qual a ordem, objetivo"*. O puzzle funcionava; ele não se explicava.
- **Quem**: agente de UX · **O que**: (1) meta do setor no topo do painel, vinda do JSON, com estado pendente/cumprido; (2) etiqueta de função por sistema (`ROTA`/`VISÃO`/`META`/`PERIGO`) em coluna própria; (3) consequência do sistema selecionado (`AO LIGAR:` / `AO DESLIGAR:`) e a troca explícita (`LIGAR EXIGE DESLIGAR: A ou B`, e a recusa passou a nomear os candidatos); (4) fala ambiente da ÓRBITA ao fechar o painel com o estado alterado; (5) `objective` nas bancadas `core_test`/`energy_test`; (6) lembrete da regra na primeira abertura do terminal da Estufa.
- **Arquivos**: `scripts/core/energy_grid.gd` (campos de meta, `tag`, `effect_off`, `bark_on/off`, `intro_bark`, `goal_met()`, `goal_line()`, `shutdown_candidates()`, validações novas) · `scenes/ui/energy_terminal_ui.{tscn,gd}` (painel 360 px, linha `Goal`, coluna de etiqueta, linha de consequência, mensagem com candidatos) · `scenes/world/energy_network.gd` (`begin_session`, `announce_change`) · `scenes/world/distribution_terminal.gd` (chama os dois) · `data/energy/{core_hub,greenhouse}.json` · `data/dialogue/{core_hub,greenhouse}.json` (15 falas ambientes novas) · `data/levels/{core_test,energy_test}.json` · `data/objectives.json` · `tests/{test_energy_grid,test_energy_data,test_dialogue_manager,test_objectives,test_reactor_state,test_save_manager}.gd`.
- **Decisões**: ADR-F17-013 a ADR-F17-018 (acima).
- **Portões**: `--import` sem erro · **469 testes, 0 falhas** · smoke em 51 cenas · varreduras de comentário, fonte fora de múltiplo de 16 e nós 3D vazias.
- **QA**: `tests/qa/f17_ux_tutorial.json` (cena `res://scenes/dev/core_test.tscn`) e `tests/qa/f17_ux_estufa.json` (cena `res://scenes/dev/energy_test.tscn`), 16 screenshots lidas. O painel do tutorial abre com `META: Abrir a porta do Setor Habitacional`; selecionar `PORTA DO SETOR HABITACIONAL` mostra `AO LIGAR: Destrava a comporta...` **e** `LIGAR EXIGE DESLIGAR: ILUMINAÇÃO DO NÚCLEO` antes de qualquer tentativa; a recusa vira `ENERGIA INSUFICIENTE - DESLIGUE: ILUMINAÇÃO DO NÚCLEO`; ligada a porta, o topo troca para `META CUMPRIDA: Porta do Setor Habitacional aberta` em ciano. Na Estufa, a primeira abertura dispara "Dois circuitos para cinco sistemas. Alguma coisa vai ficar no escuro." por cima do painel com as cinco linhas etiquetadas, e a troca da porta do Nó lista **os dois** candidatos (`AQUECIMENTO DO MÓDULO ou ILUMINAÇÃO DO CORREDOR`). Ao fechar, ÓRBITA comenta ("A porta do Nó destravou. O setor está a um passo de voltar.") com a linha de missão visível no HUD da bancada.
- **Pendências**: a linha de missão do HUD não some nem avança quando a meta do painel é cumprida (ex.: segue "Abrir a porta do Setor Habitacional no Terminal de Distribuição" com a porta já aberta) — progressão de objetivo é F15/F28. A etiqueta `PERIGO` do `AQUECIMENTO` esconde que ele também é pré-requisito da `PLATAFORMA DE CARGA`; hoje isso só aparece na linha `REQUER:` da plataforma.

### 2026-09-20 — ampliado pela [F36](F36-tutorial-briefing.md)
- O puzzle do tutorial foi de 2 para **3 sistemas / 1 energia** com a entrada de `lift_core`. A ausência de softlock voltou a ser provada por força bruta sobre todos os subconjuntos (`test_core_hub_has_no_softlock`).
