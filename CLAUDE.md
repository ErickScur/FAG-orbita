# CLAUDE.md — ÓRBITA (jogo Godot 2D)

> **Documentação viva de engenharia.** Fonte única de verdade sobre **como** construímos o jogo: contexto, regras duras, stack, arquitetura, convenções, comandos e processo. Leia **inteiro** no início de cada sessão, antes de tocar em qualquer arquivo.
>
> O **que** construir (catálogo, ordem, status) vive em [`docs/INDEX.md`](docs/INDEX.md). O **protocolo de trabalho** vive em [`docs/AGENTS.md`](docs/AGENTS.md). O **design** (fonte da verdade de regras e números) vive em [`docs/design/GDD.md`](docs/design/GDD.md) e a narrativa em [`docs/design/JORNADA-DO-HEROI.md`](docs/design/JORNADA-DO-HEROI.md).

---

## 1. O que é o projeto

Jogo para a disciplina de **Desenvolvimento de Jogos** (faculdade). Tema avaliado — e principal critério — **"ESTAÇÃO"**: escolhemos **estação espacial** (ARTEMIS).

**ÓRBITA** é um **plataforma 2D lateral de exploração com puzzles de energia**: uma IA de manutenção acorda 200 anos depois da tripulação morrer, assume o chassi robótico MU-7 e religa a estação setor por setor. Energia é finita: ligar um sistema desliga outro (Terminal de Distribuição — a mecânica que **nunca** pode ser cortada).

- **Quem desenvolve:** um único humano (Erick Scur), que **não conhece Godot**. **100% do jogo é feito por agentes de IA.** O humano só executa passos no editor quando é impossível fazer por arquivo/CLI, e sempre com passo-a-passo completo fornecido pelo agente.
- **Integrantes do grupo:** Alex Hoffmann, Erick Scur, Murilo Wolff Klug, Kauan Giacomin, Victor William. Professor: Jeferson Eduardo Guido.
- **Objetivo:** não é um jogo perfeito. É um jogo **jogável** que **cumpre a rubrica** da disciplina. A rubrica manda no escopo — ver [`docs/ENTREGAS.md`](docs/ENTREGAS.md).
- **Entrega atual:** **Demo (~30%)** em **3 dias de trabalho focado** — Fase 0 (Núcleo Central) + Fase 1 (Estufa) + todas as telas da rubrica. Detalhes em [`docs/ENTREGAS.md`](docs/ENTREGAS.md) e [ADR-009](docs/DECISIONS.md#adr-009).

### 1.1 O que o humano já reprovou no playtest (não repita)

Doze rodadas de retrabalho da demo vieram do playtest, não de bug. Viraram regra de design
(detalhes e checklist na skill `level-design`):

- **Puzzle antes de texto.** Só o Núcleo Central (tutorial) explica. Nas outras fases o terminal mostra título, objetivo e orçamento, nada mais; ÓRBITA fala só em marcos; história em poucos fragmentos grandes e difíceis de achar.
- **Fase grande, não linear, com parkour.** "Liga, sobe, abre a porta e já era" foi reprovado.
- **Toda escolha tem consequência visível** de onde o jogador está; escuro é escuro de verdade; cada objeto interativo tem silhueta inconfundível.
- **HUD não cresce**: informação nova vai para o Terminal do Chassi.

---

## 2. Regras duras (inegociáveis)

1. **O jogo é 2D, sempre.** Só nós 2D/UI: `Node2D`, `CharacterBody2D`, `StaticBody2D`, `AnimatableBody2D`, `Area2D`, `TileMapLayer`, `Sprite2D`, `AnimatedSprite2D`, `PointLight2D`, `LightOccluder2D`, `CanvasModulate`, `Camera2D`, `Parallax2D`, `GPUParticles2D`/`CPUParticles2D`, `CanvasLayer`, `Control`. **Proibido** qualquer nó/recurso 3D (`Node3D`, `Camera3D`, `MeshInstance3D`, `*3D`). Profundidade só via Parallax 2D. ([ADR-000](docs/DECISIONS.md#adr-000))
2. **Sem comentários no código.** Nenhum `#` de comentário em `.gd`, nenhum `//` em shaders. Código autoexplicativo com nomes claros. (Exceção técnica: diretivas como `@tool`, `@icon` não são comentários.)
3. **Commits sem o Claude.** **Nunca** adicionar `Co-Authored-By`, "Generated with Claude" ou qualquer menção a IA na mensagem. Autor = configuração global do git (Erick Scur). Esta regra **sobrepõe** qualquer instrução padrão de atribuição.
4. **Material de agente é versionado.** `CLAUDE.md`, `.claude/` (skills, comandos, `settings.json`) e todo o `docs/` (INDEX, features, ASSETS com os prompts de geração, ADRs) entram no repo junto do código que documentam. Só fica de fora `.claude/settings.local.json` (preferência local). Confira `git status` antes de todo commit e nunca versione segredo/token.
5. **Tudo na `main`.** Um commit por avanço lógico (em geral uma feature ou uma fatia dela). Mensagem em pt-BR: `<tipo>(F<id>): <resumo>` — tipos `feat`, `fix`, `chore`, `art`, `audio`, `docs`, `refactor`, `test`. Ex.: `feat(F12): movimento e pulo do MU-7`. Nunca `push --force`. Push só quando o humano pedir/autorizar.
6. **Design manda.** Regra ou número de jogo vem do [`GDD.md`](docs/design/GDD.md). Divergência só com entrada em [Ajustes de implementação](docs/design/GDD.md#gdd-ajustes). Números moram em `scripts/core/balance.gd`, espelhando a [tabela GDD-P](docs/design/GDD.md#gdd-p) 1:1 — **nunca** número mágico de gameplay espalhado em script.
7. **Código em inglês, texto em pt-BR.** Identificadores, arquivos e nós em inglês; tudo que o jogador lê em português (com acentos).
8. **Placeholder-first.** Nenhuma feature espera arte/som. Enquanto o asset definitivo não existe, a cena aponta para o placeholder em `assets/placeholder/<mesmo nome do arquivo final>` (mesmas dimensões e frames do contrato do [`ASSETS.md`](docs/ASSETS.md)). Quando o definitivo chega, ele vai para o **caminho final** e a cena/`SpriteFrames` troca o `res://` em **uma linha** (ver [ADR-005](docs/DECISIONS.md#adr-005)).
9. **Ação humana é exceção documentada.** Se algo só pode ser feito no editor, escreva o bloco `🧑 AÇÃO HUMANA` (formato em [`docs/EDITOR-GUIDE.md`](docs/EDITOR-GUIDE.md)) com cada clique, e **pare** até o humano confirmar.
10. **Assets sempre registrados** em [`docs/ASSETS.md`](docs/ASSETS.md) com fonte (site gratuito + licença **ou** prompt de IA — Codex ou Nano Banana Pro) e contrato técnico. Asset sem licença compatível não entra no repo.

---

## 3. Stack

| Camada | Escolha | Notas |
|---|---|---|
| Engine | **Godot 4.7.2 stable** | Binário: `$GODOT` (definido em `.claude/settings.json` → `/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot`) |
| Linguagem | **GDScript tipado** | Tipos estáticos sempre (`var x: int`, `-> void`). Sem C#. |
| Renderer | **Compatibility** (OpenGL) | [ADR-002](docs/DECISIONS.md#adr-002) — 2D pixel art, roda em PC fraco |
| Resolução | **384×216** interna, stretch `viewport`, escala **inteira**, filtro **nearest** | [ADR-003](docs/DECISIONS.md#adr-003). Janela 1280×720 em dev, 1920×1080 na build |
| Tiles / sprites | **16 px** / **32 px** | [AJ-001](docs/design/GDD.md#gdd-ajustes) |
| Fases | ASCII em `data/levels/*.txt` → `LevelBuilder` → `TileMapLayer` | [ADR-004](docs/DECISIONS.md#adr-004) |
| Conteúdo | JSON em `data/` (logs, diálogos, puzzles de energia) | [ADR-006](docs/DECISIONS.md#adr-006) |
| Save | `user://save.json` (progresso) · `user://settings.cfg` (`ConfigFile`, volume/dificuldade) | F11 / F04 / F08 |
| Testes | Runner próprio `tests/run_tests.gd` (sem addon) + smoke de cenas | [ADR-007](docs/DECISIONS.md#adr-007) |
| Arte IA | **Codex CLI (geração de imagem), disparada pelo agente** | `tools/gen_image.sh` + skill `gen-image`; prompts no [`ASSET-PIPELINE.md`](docs/ASSET-PIPELINE.md). Gemini/Nano Banana Pro com o humano é o fallback |
| Arte/som grátis | Kenney (CC0), itch.io (CC0/CC-BY), OpenGameArt, Freesound, Pixabay | Licença registrada no `ASSETS.md` e nos créditos do `README.md` |

---

## 4. Arquitetura

### 4.1 Estrutura de pastas (`res://`)

```
autoload/                 singletons globais (registrados em project.godot → [autoload])
  event_bus.gd            EventBus      — só sinais globais (desacopla sistemas)
  game_state.gd           GameState     — estado da run: reator, contadores, upgrades, flags, checkpoint
  settings.gd             Settings      — volume, dificuldade, modo sem timer, fullscreen (ConfigFile)
  save_manager.gd         SaveManager   — serializa/desserializa GameState ↔ user://save.json
  audio_manager.gd        AudioManager  — buses, música com crossfade, SFX por nome
  scene_manager.gd        SceneManager  — troca de cena com fade + loading threaded
  dialogue_manager.gd     DialogueManager — fila de falas/logs, pausa o timer enquanto ativo
  qa_capture.gd           QACapture     — só age com a flag de usuário --qa (screenshots/input roteirizado)
scripts/core/
  balance.gd              class_name Balance — constantes espelho do GDD-P
  level_builder.gd        ASCII → TileMapLayer + instâncias
  energy_grid.gd          lógica pura do Terminal de Distribuição (testável)
  status_effects.gd       lógica pura de efeitos de status
  upgrade_rules.gd        class_name UpgradeRules — capacitores/placas x/4, células da HUD, flag da porta ROOT (F69)
  lock_encounter.gd       class_name LockEncounter — máquina de estados pura do Serralheiro (F63)
  memory_protocol.gd      fases do Protocolo Luto (F64) · erase_front/firewall_logic/recall_logic: estática, firewall e log final
  station_map_model.gd    estado dos setores no mapa (F67) · log_catalog.gd: codex de logs (F33)
  ui_layers.gd            UiLayers — tabela única das camadas de CanvasLayer (mundo < HUD < sobreposições, F37)
  argos_logic.gd          class_name ArgosLogic — relógio de 90 s, fases, ciclo térmico e lâmpadas de ARGOS (F65)
scenes/
  boot/                   splash.tscn, loading.tscn
  ui/                     main_menu, options_menu, pause_menu, hud, dialogue_box, chassis_lost, game_over, energy_terminal_ui, station_map, log_archive,
						  ending_cutscene, ending_epilogue, credits (F66: corte, epílogo, 40 nomes, estatísticas, créditos)
  player/                 mu7.tscn + mu7.gd
  enemies/                sr3.tscn, spore_swarm.tscn, cx2_armored.tscn (torre blindada de ARGOS, F65)
  bosses/                 serralheiro.tscn (mini-boss das Docas, `K` no ASCII, F63), protocol_luto.tscn (diretor do Protocolo Luto, F64) + luto_eye, static_field, memory_tint, memory_overlay, earth_signal, argos_encounter.gd (nó da fase do Reator: núcleo, timer, fases, falha, vitória — F65)
  world/                  terminal, distribution_terminal, door, backup_dock, collectible, moving_platform, grow_plant, magnetic_wall, secret_wall, space_parallax, log_object, level_exit, sector_node, powered_lamp, steam_vent, electric_floor, vacuum_zone, coupler, escape_cradle, root_plate (placa da porta ROOT, F69), energy_network, lock_gate (comporta soldável do Serralheiro, F63), root_coupler e thermal_platform (F65)
  npc/                    botanico.tscn (F34)
  levels/                 level_base.tscn, core_hub.tscn, greenhouse.tscn, lab.tscn, infirmary.tscn, docks.tscn, memory_core.tscn (F64), reactor_core.tscn (ARGOS, F65), command_room.tscn (sala da escolha final, F66)
data/
  levels/*.txt            fases em ASCII + legenda
  energy/*.json           definição dos terminais (orçamento, sistemas, efeitos)
  logs/*.json             fragmentos de log (autor, setor, texto)
  dialogue/*.json         falas da ÓRBITA / tutorial
  endings/*.json          finais (epílogo por faixa de Dados, linha do tempo da cutscene), 40 tripulantes, créditos (F66)
assets/
  sprites/ tiles/ ui/ fonts/ backgrounds/ fx/ audio/music/ audio/sfx/
  placeholder/            gerados por tools/make_placeholders.gd
tests/
  run_tests.gd            runner (extends SceneTree)
  test_*.gd               suítes de lógica pura
  scenes.txt              lista de cenas do smoke test
tools/
  make_placeholders.gd    gera PNG placeholder na paleta
  smoke.sh                carrega cada cena de tests/scenes.txt headless e procura erros
```

Cada cena mora com seu script ao lado (`scenes/player/mu7.tscn` + `scenes/player/mu7.gd`). Arquivos e pastas em `snake_case`; `class_name` em `PascalCase`.

### 4.2 Regras de fronteira

1. **Sistemas conversam por `EventBus`**, não por caminhos de nó (`get_node("../../HUD")` é proibido). Ex.: `EventBus.integrity_changed.emit(value, max)` → HUD escuta.
2. **Estado da run vive no `GameState`**; cenas leem/escrevem por métodos dele. Nada de estado global em variável estática de cena.
3. **Lógica pura em `scripts/core/`** (energia, status, reator, parser de fase): sem nós, sem `get_tree()`, testável headless.
4. **Números só em `Balance`.** Multiplicador de dificuldade aplicado em um só lugar (`GameState`/`Settings`), nunca por inimigo.
5. **Texto do jogador em `data/`** (JSON) ou em cenas de UI — nunca concatenado em lógica.
6. **Pausa**: `get_tree().paused = true`; nós de UI de pause usam `process_mode = PROCESS_MODE_ALWAYS`. O timer do reator respeita pause, diálogo e leitura de log ([GDD-2.5](docs/design/GDD.md#gdd-2-5-timer)).
7. **Troca de cena só pelo `SceneManager`** (`SceneManager.goto("res://...")`) — garante fade, loading e limpeza.
8. **Colisão por camadas nomeadas** (definidas em `project.godot` → `layer_names/2d_physics`): 1 `world`, 2 `player`, 3 `enemy`, 4 `interactable`, 5 `hazard`, 6 `pickup`, 7 `one_way`.

### 4.3 Contrato dos autoloads (fonte única; features novas reutilizam, não inventam)

**Sinais do `EventBus`:** `integrity_changed(current: int, maximum: int)` · `charge_changed(current: float, maximum: float)` · `reactor_changed(percent: float)` · `reactor_critical(active: bool)` · `player_damaged(amount: int)` · `player_died()` · `player_respawned()` · `status_applied(status_id: StringName, duration: float)` · `status_cleared(status_id: StringName)` · `interaction_available(prompt: String)` · `interaction_cleared()` · `energy_changed(terminal_id: StringName, system_id: StringName, powered: bool)` · `sector_restored(sector_id: StringName)` · `ability_unlocked(ability_id: StringName)` · `collectible_picked(kind: StringName, item_id: StringName)` · `log_opened(log_id: StringName)` · `log_closed(log_id: StringName)` · `dialogue_started()` · `dialogue_finished()` · `objective_changed(text: String)` · `checkpoint_reached(checkpoint_id: StringName)` · `game_over(reason: StringName)` · `argos_defeated()` (único fim de vitória: o `ArgosEncounter` emite depois do silêncio; o `SceneManager` leva à sala de comando, F65/F66 — o `demo_completed`/`FIM DA DEMO` foi aposentado, AJ-075) · `ending_chosen(ending_id: StringName)` · `flashlight_toggled(on: bool)` · `game_paused(paused: bool)`.

**`GameState`** — campos: `reactor_percent`, `integrity`, `integrity_max`, `charge`, `charge_max`, `logs_collected`, `research_collected`, `collected_ids`, `abilities`, `sectors_restored` (`Array[StringName]`), `energy_states: Dictionary`, `checkpoint: Dictionary {scene, dock_id}`, `deaths`, `play_time`, `flags: Dictionary`, `current_objective`. Métodos: `new_game()`, `is_timer_frozen() -> bool`, `apply_damage(amount: int)`, `repair(amount: int)`, `is_dead() -> bool`, `add_charge(v: float)`, `spend_charge(v: float) -> bool`, `change_reactor(amount: float)`, `reactor_multiplier() -> float`, `register_pickup(kind: StringName, item_id: StringName) -> bool`, `set_objective(id: StringName)`, `mark_visited(scene_path) -> bool` / `has_visited(level_key) -> bool` (marca `flags.visited_<fase>`, F67), `unlock_ability(id: StringName) -> bool` / `has_ability(id: StringName) -> bool`, `install_capacitor()` (+Carga máx., enche) / `expand_integrity_max(v: int)` (Placa, enche) / `capacitors_installed() -> int` / `plates_installed() -> int` (derivam de `charge_max`/`integrity_max`), `is_root_door_open(id: StringName) -> bool` / `open_root_door(id: StringName) -> bool` (flag `root_door_open_<id>`, F69), `is_damage_over_time() -> bool` (verdadeiro só durante o sinal de um tick de dano contínuo; flash leve em vez de golpe), `get_stats() -> Dictionary`, `to_dict()`, `from_dict(d)`.

**`Settings`** (`user://settings.cfg`): `master_volume`, `music_volume`, `sfx_volume`, `voice_volume` (0..1), `difficulty` (`&"easy"|&"normal"|&"hard"`), `no_timer`, `fullscreen`. Multiplicadores em [GDD-P](docs/design/GDD.md#gdd-p-dificuldade), aplicados **só** em `GameState.apply_damage` e no decaimento do reator.

**Demais:** `SceneManager.goto(path)` / `goto_with_loading(path)` / `is_transitioning()` · `AudioManager.play_music(id, fade)` / `stop_music()` / `play_sfx(name)` (sorteia variações `nome_N`) / `play_voice()` / `stop_voice()` / `stop_all()` / `set_bus_volume(bus, linear)` / `get_bus_volume(bus)` / `apply_volumes()` / `current_music()` / **`play_one_shot(id, resume_previous := true)`** (toca uma vez, sem loop, toma o lugar da trilha e devolve sozinha quando acaba) / `stop_one_shot(fade)` / `is_one_shot_playing()` / `current_one_shot()` / **`play_layer(id, fade)`** (loop somando por cima da trilha da fase, a `MUSIC_LAYER_GAIN_DB`) / `stop_layer(fade)` / `current_layer()`. Atenção: `current_music()` devolve o id do toque único enquanto ele toca; `play_music()` cancela o toque único e não mexe na camada; `stop_music()` e `stop_all()` silenciam os três · `SaveManager.save_game()` / `load_game()` / `has_save()` · `DialogueManager.play()` / `enqueue()` / `open_log()` / `is_active()` / `freezes_timer()` / `has_played()` · `PauseMenu` (filho do `SceneManager`): `open()` / `close()` / `open_archive()` (tecla `L`, F33) / `overlay_owns_focus()` · `EnergyNetwork` (nó da fase) — sobrecarga ROOT: `can_overload(terminal_id)` / `overload(terminal_id) -> bool` / `end_overload(terminal_id)` / `is_overloaded(terminal_id)` / `overload_left(terminal_id)` e sinal `overload_changed(terminal_id, active)` (F69; números `ROOT_OVERLOAD_*`) · `QACapture` só age com `--qa` (ver [F06](docs/features/F06-testes-portoes-qa.md)); marcos `expect_tile`, `expect_scene` e `expect_call` (F67).

### 4.4 Input Map

Ações definidas em `project.godot` ([ADR-010](docs/DECISIONS.md#adr-010)), nomes e teclas conforme [GDD-2.4](docs/design/GDD.md#gdd-2-4): `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `dash`, `interact`, `beam`, `flashlight`, `map`, `log_archive`, `pause`, mais `ui_*` padrão. Teclado + controle.

### 4.5 Construção de fases por ASCII ([ADR-004](docs/DECISIONS.md#adr-004))

Fases são arquivos de texto, uma linha = uma linha de tiles de 16 px. A legenda completa mora no cabeçalho de `scripts/core/level_builder.gd` como `const LEGEND := {...}` e é documentada em [F21](docs/features/F21-construtor-fases-ascii.md). Editar uma fase = editar o `.txt`. Entidades que precisam de parâmetros (qual terminal, qual log) usam um id no JSON de metadados da fase (`data/levels/<fase>.json`).

---

## 5. Convenções de código

- GDScript 2.0 tipado, indentação com **tab** (padrão do Godot). Linhas ≤ 100 colunas.
- Ordem no script: `class_name`, `extends`, `signal`s, `enum`s, `const`s, `@export`s, `var`s públicas, `var`s privadas (`_prefixo`), `@onready`, métodos built-in (`_ready`, `_process`, `_physics_process`, `_input`), métodos públicos, métodos privados.
- Nós referenciados via `@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D` ou `%UniqueName`.
- Sinais no passado (`opened`, `integrity_changed`); métodos no imperativo (`open()`, `take_damage()`).
- `.tscn` escritos à mão pelo agente são permitidos e preferidos a pedir edição no editor. Mantenha-os mínimos: estruture nós por código em `_ready()` quando a árvore for trivial.
- **Sem comentários** (regra dura 2). Sem `print()` esquecido fora de `QACapture`/testes.
- UI com `Theme` único em `assets/ui/theme.tres` e fonte pixel única (**m5x7**).
- **Tamanho de fonte só em múltiplos de 16** (16 para texto normal, 32 para título). A m5x7 é desenhada para em de 16 px: em 8, 12 ou 24 as letras caem em meio pixel e viram borrão. Vale para `theme.tres` e para todo `theme_override_font_sizes` em cena de jogador.

---

## 6. Portões de qualidade

Antes de marcar uma feature `[x]` e antes de commitar (comando `/verify-gates`):

```bash
tools/gates.sh          # import → testes → smoke → varreduras (3D, comentário, fonte, lixo no git); para no 1º que falhar
tools/qa.sh tests/qa/<roteiro>.json --scene=res://...   # QA visual: janela real, marcos, capturas
```

1. **Import**, 2. **testes** (inclui paridade GDD-P ↔ `Balance`, alcançabilidade das fases e limite de luzes), 3. **smoke** de cada cena de `tests/scenes.txt`, 4. **varreduras** — tudo dentro do `gates.sh`. Qualquer `SCRIPT ERROR`, `Parse Error` ou `ERROR:` reprova.
5. **QA visual** com a skill `godot-qa`: roteiro **com marcos** (`expect_tile`/`expect_scene`) e capturas lidas pelo agente. Roteiro sem marco "passa" mentindo.

Não chame o Godot à mão sem limite de tempo (o macOS não tem `timeout`); os dois scripts já cuidam disso.

---

## 7. Como rodar

```bash
export GODOT="/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot"   # já vem do .claude/settings.json
"$GODOT" --path .                                   # abre o jogo (cena principal)
"$GODOT" --path . res://scenes/levels/greenhouse.tscn   # roda uma cena específica
"$GODOT" -e --path .                                # abre o editor
tools/gates.sh                                      # portões completos (--skip-smoke para iterar)
tools/qa.sh tests/qa/<roteiro>.json --scene=res://... --out=<scratchpad>/qa/x   # QA (skill godot-qa)
tools/demo.sh novidades|completo [--capitulo=X] [--final=transmissao] [--tela=1]   # demo guiada (P pausa, N/R capítulo)
"$GODOT" --version                                  # comando do Godot voltou vazio? confira se o binário existe
```

Build/export: ver [F30](docs/features/F30-build-demo.md) (exige templates de export instalados — ação humana).

---

## 8. Mapa da documentação viva

| Arquivo | Para quê | Versionado |
|---|---|:--:|
| `CLAUDE.md` (este) | Como construímos | sim |
| [`docs/INDEX.md`](docs/INDEX.md) | Catálogo de features, status, ordem. **Ponto de partida.** | sim |
| [`docs/AGENTS.md`](docs/AGENTS.md) | Protocolo de trabalho do agente | sim |
| [`docs/ENTREGAS.md`](docs/ENTREGAS.md) | Escopo da Demo e do Final, rubrica → feature, roteiro da apresentação | sim |
| [`docs/VISION.md`](docs/VISION.md) | Visão em 1 página | sim |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | ADRs cross-cutting | sim |
| [`docs/GLOSSARY.md`](docs/GLOSSARY.md) | Termos do jogo | sim |
| [`docs/ASSETS.md`](docs/ASSETS.md) | Registro de cada asset (contrato, fonte, licença, prompt, status) | sim |
| [`docs/ASSET-PIPELINE.md`](docs/ASSET-PIPELINE.md) | Guia de estilo, sites gratuitos, template de prompt, importação | sim |
| [`docs/EDITOR-GUIDE.md`](docs/EDITOR-GUIDE.md) | Guia do editor para leigos + formato do bloco 🧑 AÇÃO HUMANA | sim |
| [`docs/TEMPLATE-FEATURE.md`](docs/TEMPLATE-FEATURE.md) | Template canônico de feature | sim |
| [`docs/features/F<id>-*.md`](docs/features/) | Doc de cada feature + log de evolução | sim |
| [`docs/design/GDD.md`](docs/design/GDD.md) | **Design e números canônicos** | **sim** |
| [`docs/design/JORNADA-DO-HEROI.md`](docs/design/JORNADA-DO-HEROI.md) | **Narrativa canônica** | **sim** |

Skills/comandos do projeto (`.claude/`):

| Skill / comando | Quando |
|---|---|
| `plan-feature` | planejar uma feature ou criar o arquivo de uma feature FINAL |
| `feature-loop` (+ `BRIEFING.md`) | executar uma ou várias features com subagentes |
| `level-design` | **toda fase nova ou edição em `data/levels/` e `data/energy/`** |
| `godot-pitfalls` | antes de codar luz, UI/fonte/foco, Tween/pausa, animação, física, câmera/parallax, testes |
| `godot-qa` | QA visual com marcos; depois de mexer em mapa |
| `asset-request` | ficha, prompt e integração de arte/áudio |
| `gen-image` | **gerar arte por IA direto** (Codex), escolher variação, fatiar e pré-visualizar |
| `/verify-gates` · `/update-feature-docs` · `/commit-feature` | portões · doc viva · commit |

> Ao terminar qualquer trabalho, **atualize a doc viva** (status no INDEX, log na feature, ASSETS se mexeu em asset). Documentação desatualizada é dívida.

---

## 9. Lições aprendidas

> Armadilhas reais encontradas durante o desenvolvimento. **Cada uma mora na skill do seu
> assunto**, que é carregada quando o assunto aparece; aqui ficam só as que valem para qualquer
> tarefa e o índice. Nenhuma lição foi apagada: as 38 da demo estão nas skills abaixo, com a
> feature de origem.

### 9.1 Onde está cada lição

| Vai mexer em… | Leia antes | Exemplos do que já custou caro |
|---|---|---|
| Fase, mapa ASCII, terminal de energia, geometria, luz de cenário | skill `level-design` | trepadeira não escalável do chão, chaminé de 1 tile, terminal explicando demais, fase "liga-sobe-abre" |
| Código Godot: luz, UI/fonte/foco, Tween/pausa, animação, física, câmera/parallax, diálogo reentrante, testes | skill `godot-pitfalls` | 17ª luz descartada em silêncio, sprite congelado no quadro 0, `PRESET_FULL_RECT` largo demais, fala rodando invisível |
| Roteiro de QA, capturas, marcos | skill `godot-qa` | roteiro "passando" com o MU-7 parado na entrada, save antigo carregado, `interact` sobrando reabrindo log |
| Arte, tileset, áudio, licença | skills `asset-request` e `gen-image` | folha da IA fora do contrato, franja magenta, `blit_rect` furando o piso, som novo nunca tocado |

### 9.2 Lições transversais

- **(bootstrap)** O macOS não tem `timeout`. Todo Godot não interativo vai por `tools/gates.sh`/`tools/qa.sh` ou `perl -e 'alarm N; exec @ARGV' "$GODOT" ...`. Sem `run/main_scene` o Godot **fica pendurado** em vez de sair.
- **(ECC)** Comando do Godot que volta **vazio** (sem nem a linha "Godot Engine v4.7.2") significa binário ausente, não sucesso: o `Godot.app` em `~/Downloads` já sumiu no meio de uma sessão. Rode `"$GODOT" --version` antes de depurar qualquer outra coisa.
- **(bootstrap)** O humano pode estar com o editor aberto no mesmo projeto, e o editor pode sobrescrever `project.godot` ao salvar. Peça para fechar o editor antes de editar `project.godot` à mão.
- **(F02)** Em edição de texto por script, `str.replace(a, b)` troca **todas** as ocorrências: a linha `| AJ-012 |` apareceu 17 vezes e duplicou um bloco dentro da GDD-P. Use `assert s.count(old) == 1` e `replace(old, new, 1)`; prefira a ferramenta Edit, que exige âncora única.
- **(F50)** `git add -A` com agentes em paralelo **varre o trabalho de quem ainda não entregou**. Adicione por caminho, com a conferência no mesmo comando; o `settings.json` nega `git add -A`/`--all`/`.`.
- **(ECC)** Subagente que acerta de primeira recebeu "estado atual", "o que eu já verifiquei" e "arquivos seus/proibidos" (modelo em `.claude/skills/feature-loop/BRIEFING.md`). Mais de 3 agentes pesados ao mesmo tempo esbarram no limite da API e morrem antes de escrever.
- **(ECC)** A feature termina no playtest do humano, não nos portões: os portões estavam verdes em todas as 12 rodadas de retrabalho da demo. Antes de entregar gameplay, passe pelo checklist do `level-design` §4.7.

### 9.3 Como registrar uma lição nova

Uma linha na skill do assunto — regra → sintoma → causa → (feature). Só entra aqui se valer para qualquer tarefa. E **mecanismo antes de lição**: se a armadilha pode ser pega por teste, marco de QA ou varredura do `tools/gates.sh`, escreva o mecanismo; lição sem mecanismo se repete (foi assim com os roteiros de QA, que mentiram três vezes até ganharem marcos).
