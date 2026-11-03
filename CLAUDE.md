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
10. **Assets sempre registrados** em [`docs/ASSETS.md`](docs/ASSETS.md) com fonte (site gratuito + licença **ou** prompt Nano Banana Pro) e contrato técnico. Asset sem licença compatível não entra no repo.

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
| Arte IA | **Gemini / Nano Banana Pro** | Prompts no [`ASSET-PIPELINE.md`](docs/ASSET-PIPELINE.md) |
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
scenes/
  boot/                   splash.tscn, loading.tscn
  ui/                     main_menu, options_menu, pause_menu, hud, dialogue_box, chassis_lost, game_over, demo_end, energy_terminal_ui
  player/                 mu7.tscn + mu7.gd
  enemies/                sr3.tscn, spore_swarm.tscn
  world/                  terminal, distribution_terminal, door, backup_dock, collectible, moving_platform, grow_plant, magnetic_wall, secret_wall, space_parallax, log_object, level_exit, sector_node, powered_lamp, steam_vent, electric_floor
  npc/                    botanico.tscn (F34)
  levels/                 level_base.tscn, core_hub.tscn, greenhouse.tscn
data/
  levels/*.txt            fases em ASCII + legenda
  energy/*.json           definição dos terminais (orçamento, sistemas, efeitos)
  logs/*.json             fragmentos de log (autor, setor, texto)
  dialogue/*.json         falas da ÓRBITA / tutorial
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

**Sinais do `EventBus`:** `integrity_changed(current: int, maximum: int)` · `charge_changed(current: float, maximum: float)` · `reactor_changed(percent: float)` · `reactor_critical(active: bool)` · `player_damaged(amount: int)` · `player_died()` · `player_respawned()` · `status_applied(status_id: StringName, duration: float)` · `status_cleared(status_id: StringName)` · `interaction_available(prompt: String)` · `interaction_cleared()` · `energy_changed(terminal_id: StringName, system_id: StringName, powered: bool)` · `sector_restored(sector_id: StringName)` · `ability_unlocked(ability_id: StringName)` · `collectible_picked(kind: StringName, item_id: StringName)` · `log_opened(log_id: StringName)` · `log_closed(log_id: StringName)` · `dialogue_started()` · `dialogue_finished()` · `objective_changed(text: String)` · `checkpoint_reached(checkpoint_id: StringName)` · `game_over(reason: StringName)` · `demo_completed()` · `flashlight_toggled(on: bool)` · `game_paused(paused: bool)`.

**`GameState`** — campos: `reactor_percent`, `integrity`, `integrity_max`, `charge`, `charge_max`, `logs_collected`, `research_collected`, `collected_ids`, `abilities`, `sectors_restored` (`Array[StringName]`), `energy_states: Dictionary`, `checkpoint: Dictionary {scene, dock_id}`, `deaths`, `play_time`, `flags: Dictionary`, `current_objective`. Métodos: `new_game()`, `is_timer_frozen() -> bool`, `apply_damage(amount: int)`, `repair(amount: int)`, `is_dead() -> bool`, `add_charge(v: float)`, `spend_charge(v: float) -> bool`, `change_reactor(amount: float)`, `reactor_multiplier() -> float`, `register_pickup(kind: StringName, item_id: StringName) -> bool`, `set_objective(id: StringName)`, `get_stats() -> Dictionary`, `to_dict()`, `from_dict(d)`.

**`Settings`** (`user://settings.cfg`): `master_volume`, `music_volume`, `sfx_volume`, `voice_volume` (0..1), `difficulty` (`&"easy"|&"normal"|&"hard"`), `no_timer`, `fullscreen`. Multiplicadores em [GDD-P](docs/design/GDD.md#gdd-p-dificuldade), aplicados **só** em `GameState.apply_damage` e no decaimento do reator.

**Demais:** `SceneManager.goto(path)` / `goto_with_loading(path)` / `is_transitioning()` · `AudioManager.play_music(id, fade)` / `stop_music()` / `play_sfx(name)` (sorteia variações `nome_N`) / `play_voice()` / `stop_voice()` / `stop_all()` / `set_bus_volume(bus, linear)` / `get_bus_volume(bus)` / `apply_volumes()` / `current_music()` / **`play_one_shot(id, resume_previous := true)`** (toca uma vez, sem loop, toma o lugar da trilha e devolve sozinha quando acaba) / `stop_one_shot(fade)` / `is_one_shot_playing()` / `current_one_shot()` / **`play_layer(id, fade)`** (loop somando por cima da trilha da fase, a `MUSIC_LAYER_GAIN_DB`) / `stop_layer(fade)` / `current_layer()`. Atenção: `current_music()` devolve o id do toque único enquanto ele toca; `play_music()` cancela o toque único e não mexe na camada; `stop_music()` e `stop_all()` silenciam os três · `SaveManager.save_game()` / `load_game()` / `has_save()` · `DialogueManager.play()` / `enqueue()` / `open_log()` / `is_active()` / `freezes_timer()` / `has_played()` · `QACapture` só age com `--qa` (ver [F06](docs/features/F06-testes-portoes-qa.md)).

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

Antes de marcar uma feature `[x]` e antes de commitar, rode **nesta ordem** (comando `/verify-gates`):

```bash
"$GODOT" --headless --path . --import                       # 1. importa assets, compila scripts
"$GODOT" --headless --path . -s res://tests/run_tests.gd     # 2. testes de lógica (exit code 0)
tools/smoke.sh                                                # 3. carrega cada cena de tests/scenes.txt, 0 erros
```

4. **QA visual** com a skill `godot-qa` (janela real, input roteirizado, screenshots lidas pelo agente).
5. **Varreduras:** `grep -rnE "Node3D|Camera3D|MeshInstance3D|Body3D" --include=*.gd --include=*.tscn .` vazio; `grep -rnE "^\s*#" --include=*.gd .` vazio; `git status --short` sem lixo (`.godot/`, `.DS_Store`, builds) e sem `.claude/settings.local.json`.

Qualquer `SCRIPT ERROR`, `Parse Error` ou `ERROR:` no output reprova o portão.

---

## 7. Como rodar

```bash
export GODOT="/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot"   # já vem do .claude/settings.json
"$GODOT" --path .                                   # abre o jogo (cena principal)
"$GODOT" --path . res://scenes/levels/greenhouse.tscn   # roda uma cena específica
"$GODOT" -e --path .                                # abre o editor
"$GODOT" --path . --fixed-fps 60 -- --qa --qa-scene=res://... --qa-script=res://tests/qa/<roteiro>.json --qa-out=<dir> --qa-screen=1   # QA (skill godot-qa)
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
| [`docs/design/GDD.pdf`](docs/design/GDD.pdf) | Versão de apresentação do GDD. Fonte em `docs/design/gdd-pdf/`, regerada com `tools/render_gdd_pdf.sh` (Chromium headless) | sim |
| [`docs/design/JORNADA-DO-HEROI.md`](docs/design/JORNADA-DO-HEROI.md) | **Narrativa canônica** | **sim** |

Skills/comandos do projeto (`.claude/`): `/verify-gates`, `/update-feature-docs`, `/commit-feature`, skills `plan-feature`, `feature-loop`, `godot-qa`, `asset-request`.

> Ao terminar qualquer trabalho, **atualize a doc viva** (status no INDEX, log na feature, ASSETS se mexeu em asset). Documentação desatualizada é dívida.

---

## 9. Lições aprendidas (append-only)

> Armadilhas reais encontradas durante o desenvolvimento. Uma linha cada, com a feature de origem.

- **(bootstrap)** O macOS não tem `timeout`. Todo comando `$GODOT` não interativo deve ter limite de tempo: `perl -e 'alarm 60; exec @ARGV' "$GODOT" --headless --path . ...`. Sem cena principal (`run/main_scene`) o Godot imprime "no main scene defined" e **fica pendurado** em vez de sair.
- **(F05/F03)** Fonte pixel exige tamanho nativo: a **m5x7 só fica nítida em múltiplos de 16**; 8/12/24 produzem glifos derretidos que só aparecem na resolução grande. No `.import` da fonte, `keep_rounding_remainders=false` (além de `antialiasing=0`, `hinting=0`, `subpixel_positioning=0`).
- **(F06)** Captura de tela no QA é **síncrona**: `RenderingServer.force_draw(false)` + `get_viewport().get_texture().get_image()`. Com `await RenderingServer.frame_post_draw` as continuações resolvem em lote quando a janela está sem foco e várias fotos saem idênticas; e pausar a árvore para esperar o desenho **trava o jogo** (o await nunca resolve).
- **(F06)** O auto-pause por perda de foco (`NOTIFICATION_APPLICATION_FOCUS_OUT`) precisa ignorar o modo QA — com a janela sem foco ele abriria a pausa em cima de toda captura.
- **(QA)** A janela de QA abre no **segundo monitor** e sem roubar foco (`ORBITA_QA_SCREEN=1` no `.claude/settings.json`, ou `--qa-screen=N`). O humano usa a tela primária enquanto os agentes trabalham — piscar janela em cima dele é interrupção real.
- **(F12)** Roteiro de QA deve exercitar **o controle que o GDD documenta**, não o que o código faz: a descida de plataforma fina passou no QA com ↓+pulo e quebrou na mão do jogador, que apertou só ↓ (como o GDD-2.4 manda).
- **(F35)** `Tween` criado em nó comum é `TWEEN_PAUSE_BOUND` e **congela durante fala travante** (o diálogo pausa a árvore). Efeito visual que acompanha fala precisa de `set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` — sem isso o clarão simplesmente não acontece.
- **(F35)** Deslize horizontal com `clip_contents` **corta o texto** em container de largura fixa (o aviso do HUD virou "DADO DE PESQUISA 01/1"). Anime na vertical ou sem recorte.
- **(F35)** Offset de câmera em 384×216 com escala inteira tem de ser **arredondado a pixel inteiro**, senão o tremor borra a tela pelo mesmo motivo da lição da fonte.
- **(F26)** `Parallax2D` no Godot 4.7 nasce com `follow_viewport = true`, que significa "a camada onde eu moro já me arrasta". Numa `CanvasLayer` com `follow_viewport_enabled = false` isso soma a compensação de volta e **o fundo corre para o lado errado**. As duas flags precisam casar (ambas `false` no nosso caso).
- **(F09)** Sobreposição de UI (modal, opções por cima do pause) **precisa de trava de foco**: sem `focus_neighbor_*` explícitos, a navegação por setas/controle "escapa" para os botões da tela de baixo — com mouse parece funcionar, o que esconde o bug. Use `FocusTrap` (`scripts/core/focus_trap.gd`): ele desliga o foco de todo `Control` fora do modal e liga os botões permitidos em ciclo.
- **(F10)** Em telas ProMotion a janela roda a ~120 fps, então `frame` nos roteiros `godot-qa` vale ~1/120 s. Passe `--fixed-fps 60` ao capturar, ou dobre as esperas do roteiro.
- **(F02)** Em edição de markdown por script, `str.replace(a, b)` do Python troca **todas** as ocorrências: uma linha de tabela usada como âncora (`| AJ-012 |`) apareceu 17 vezes e duplicou um bloco inteiro dentro da tabela GDD-P. Ancore por linha inteira e passe `count=1`, e confira o trecho depois.
- **(F43)** No renderer **Compatibility** cada item de canvas aceita no máximo **16 `Light2D`**; da 17ª em diante a luz é descartada **em silêncio** (nenhum erro no log). As 19 luzes de brilho por tile da parede magnética empurravam a lanterna do MU-7 para fora da lista e ela simplesmente não iluminava. Brilho de cenário repetido por tile precisa ser **fundido por trecho**; `tests/test_light_crowding.gd` trava 12 luzes por janela de 256 px.
- **(F50)** `OccluderPolygon2D` de tile inteiro faz o tile **projetar sombra sobre a própria face**: num jogo 2D de lado o que se vê de um bloco é a face, e ela é a primeira coisa que a luz deveria acender. Oclusão tem de ser o **contorno da ilha sólida** com `cull_mode` (só a face oposta à luz projeta) — com oclusor por tile, ligar `cull_mode` não adianta, porque as arestas entre dois sólidos vizinhos continuam sombreando uma à outra.
- **(bootstrap)** O humano pode estar com o editor aberto no mesmo projeto. Rodar headless em paralelo funciona, mas o editor pode sobrescrever `project.godot` ao salvar — peça para fechar o editor antes de editar `project.godot` à mão.
- **(F37)** `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` usa `PRESET_MODE_MINSIZE` por padrão: chamado antes do primeiro layout (pai ainda com largura 0) ele grava `offset_right = largura_mínima` e o `Control` termina com **largura do pai + largura mínima**. O aviso do HUD nasceu deslocado para a direita assim e ficou errado desde a F15 sem ninguém notar. Defina `size`/`position` explicitamente, ou passe `PRESET_MODE_KEEP_SIZE`.
- **(F36)** A fonte `ui_font.ttf` (m5x7) **não tem** `—` (em-dash), `←` `→` `↑` `↓` nem `✓`; tem `·`, `-` e todos os acentos. Como o `.import` está com `allow_system_fallback=true`, um glifo ausente não some: cai numa fonte do sistema e sai borrado no meio do pixel art, o que é pior que um erro. Escreva as teclas por extenso (`[SETAS]`, `[CIMA]`, `[BAIXO]`) e use `[OK]` no lugar do `✓`. Para conferir: `font.has_char(code)` num script headless.
- **(F36)** Roteiro de `godot-qa` **mente quando o mapa muda**: o nome do arquivo continua dizendo `41_fim_da_demo` enquanto a foto mostra o jogador parado no ponto de partida. O log do QA imprime a posição do jogador em cada captura — **compare as posições entre capturas que deveriam mostrar progresso**; posição idêntica é roteiro quebrado, não jogo quebrado. Ao mexer numa fase, rode e releia os roteiros dela antes de confiar neles.
- **(F36)** Diálogo travante pausa a árvore, então **aperto de `interact` sobrando em cima de um terminal de registros reabre o log** que acabou de fechar, e as capturas seguintes mostram as primeiras linhas de novo, parecendo que o log "voltou". Cada linha custa dois apertos (o primeiro completa a digitação, o segundo avança): um log de 10 linhas fecha em 20. Conte, ou ande para longe do terminal antes de apertar mais.
- **(F29/F19)** `DialogueManager._finish_current()` aplica os efeitos da fala **antes** de esconder a caixa, e um efeito (`unlock_ability`, `set_flags`) pode iniciar uma fala nova ali mesmo, de forma síncrona. Sem checar `_current` de novo depois de `_apply_effects()`, a função escondia a caixa da fala que acabara de começar: a fala das garras rodava **invisível**, congelando o timer sem mostrar nada. Toda função que limpa estado depois de chamar um gancho precisa reconferir se o gancho recriou esse estado.
- **(F36)** O cartão de tutorial ignorava a tecla sempre que houvesse diálogo no frame anterior, para que o `[E]` que avança uma fala não completasse o cartão por tabela. Como a Estufa quase sempre tem fala ambiente na tela, o cartão de escalar **nunca completava** e ficava preso até o fim da fase. A guarda tem de valer só para as teclas que o diálogo realmente consome (`DialogueManager.ADVANCE_ACTIONS`), não para qualquer tecla.
- **(F43)** O topo colidível da `GrowPlant` fica **64 px acima do pé** (4 tiles) e o pulo alcança 40 px: uma trepadeira **não é escalável a partir do chão**. Toda planta que serve de rota precisa de um patamar de embarque a 2 tiles do topo. O mapa antigo escondia isso porque a planta era só degrau intermediário.
- **(F43)** As garras agarram a até 10 px da parede, mas o corpo do MU-7 tem 14 px de largura: escalando afastado 3 px, a lateral invade a coluna vizinha, o jogador bate `is_on_ceiling` e **para de subir sem nenhum erro no log**. Chaminé de escalada precisa de **2 tiles de largura**.
- **(F43)** Plataformas finas empilhadas só são transponíveis com **pelo menos 2 colunas de sobreposição horizontal**: o apogeu de 40 px chega, mas o deslocamento horizontal acumulado durante a subida não.
- **(F22)** Atribuir `sprite_frames` a um `AnimatedSprite2D` já **escolhe** a primeira animação (`animation` deixa de ser `"default"`) mas **não toca** nada. Um guarda `if sprite.animation == anim: return` conclui "já estou nela" e a animação nunca começa — o sprite fica congelado no quadro 0 enquanto o nó anda. O guarda tem de exigir `and sprite.is_playing()`.
- **(F22)** Sonda de borda de inimigo precisa da **mesma máscara de colisão do corpo**. Com `mask = 1 | 7` a `FloorProbe` via plataforma fina como chão, mas o corpo (`mask = 1`) atravessa: a SR-3 andava para fora do parapeito e caía da fase.
- **(F49)** Chave de magenta por **distância euclidiana deixa franja rosa**: um pixel meio a meio entre o fundo e o desenho fica longe o bastante da cor-chave para receber alfa cheio. Use "magentice" (`(r+b)/2 − g`), que vale ~245 no fundo e ~0 numa silhueta cinza-azulada, clara ou escura, mais o *unmix* `F = (C − K·(1−a))/a`.
- **(F49)** O teste do resolvedor de assets precisa de um asset **ainda sem arte final** como cobaia. A cada entrega de arte ele quebra e alguém troca a cobaia — já aconteceu três vezes (SR-3, esporo, e a próxima será o botânico). Vale trocar por uma cobaia sintética que nunca vá existir de verdade.
- **(F49)** Arte de parallax larga pode ter o assunto **fora de qualquer enquadramento alcançável**: o planeta-alvo caía em x≈700 de uma tira de 1152, e com `scroll_scale` 0,18 numa fase de 768 px o jogo só revelava x ∈ [34, 488] — ele nunca apareceria. Confira onde o assunto cai **depois** de aplicar a escala de rolagem, e role a tira se preciso (como a camada fecha em ciclo, rolar não cria emenda).
- **(F47)** Rodar `tests/qa/f29_greenhouse.json` **sem `--qa-new-game`** faz o jogo entrar pelo menu e cair no `user://save.json` que a rodada anterior deixou — o MU-7 nasce noutro lugar, todo o roteiro de input se perde e a demo "não fecha". O sintoma imita um bug de dado (o jogador trava contra um muro), mas não há nenhum `ERROR` no log. Comece por conferir a posição do MU-7 nas primeiras capturas contra os marcos documentados na F43 §10 antes de culpar o código.
- **(F47)** Colar uma faixa de arte sobre um tile com `Image.blit_rect` **copia o alfa** e abre buraco onde a faixa era transparente (a silhueta do musgo vazou o topo de 8 das 16 máscaras da Estufa — ou seja, de toda superfície de piso). Use `blend_rect`, que mistura sobre a base. Nenhuma screenshot mostrou isso; quem pegou foi um teste que conta pixels transparentes por tile.
- **(F47)** Coordenada crua de atlas (`LevelBuilder.ONE_WAY_TILE`, `MagneticWall.TILE_COLUMN/ROW`, `SecretWall.tile_column/row`) é contrato entre código e arte que ninguém revalida quando a arte é regerada. Toda folha nova precisa passar por `tests/test_level_tileset.gd`, que confere papel por papel.
- **(F52)** A resolução de efeito sonoro procurava o **arquivo direto** antes das variações `nome_N`, nos dois diretórios. Como o placeholder tinha `pickup.wav` e `door_open.wav`, as variações definitivas `pickup_1/2` e `door_open_1..3` **nunca seriam tocadas**: arquivo novo no disco, som velho no jogo, sem erro nenhum. Resolva **por grupo** — o conjunto inteiro (direto ou variações) no diretório definitivo primeiro, placeholder só depois.
- **(F52)** Normalize áudio por **RMS**, não por pico. Um pacote inteiro pode chegar com pico ≈ −1 dBFS e ainda ter 21 dB de diferença de volume percebido entre os arquivos; normalizar por pico não muda nada e o passo continua estourando ao lado do alarme inaudível.
- **(F50)** Rodar `git add -A` com agentes trabalhando em paralelo **varre o trabalho em andamento de quem ainda não entregou** para dentro do seu commit. Conferir `git status` alguns minutos antes não basta: entre a conferência e o `add` o outro agente escreve. Ou **staja caminhos explícitos**, ou confira `git status` no mesmo comando do `add`.
- **(F54)** Raycast contra `TileMapLayer` **falha na primeira física depois do `_ready()`**: a colisão dos tiles ainda não está registrada e o raio atravessa o teto como se não houvesse nada. A porta da Estufa nasceu com 48 px de antepara enfiada dentro da parede por causa disso. Espere **2 quadros de física** antes de medir o mundo.
