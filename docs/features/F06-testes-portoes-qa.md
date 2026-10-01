---
id: F06
title: Testes, portões & QA por screenshot
status: done
scope: demo
block: 0
priority: P0
rubric: []
depends_on: ["F01"]
unblocks: ["F02", "F05"]
estimate: 2.5h
last_updated: 2026-09-19
---

# F06 — Testes, portões & QA por screenshot

## 1. Contexto e objetivo

O humano não conhece Godot e 100% do jogo é feito por agentes. O agente precisa de três olhos: **testes de lógica** headless, **smoke** que carrega cada cena procurando erros e **QA visual** que roda o jogo com janela, injeta inputs roteirizados e salva screenshots para o agente ler ([ADR-007](../DECISIONS.md#adr-007)). Esta feature implementa o lado do jogo dessas três ferramentas, que viram os portões do [`/CLAUDE.md` §6](../../CLAUDE.md).

A skill `.claude/skills/godot-qa/SKILL.md` (escrita pelo orquestrador) apenas **chama** o que é construído aqui. Nenhum pilar de jogo é servido diretamente; o que se protege é o prazo da Demo.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (nomes das ações que o QA injeta)
- **Parâmetros:** nenhum
- **ADRs:** [ADR-007](../DECISIONS.md#adr-007) · [ADR-010](../DECISIONS.md#adr-010) (teste do Input Map) · [ADR-002](../DECISIONS.md#adr-002)/[ADR-003](../DECISIONS.md#adr-003) (teste das configurações)

## 3. Critério de avaliação atendido

Nenhum item direto. Na apresentação ("Por dentro", [ENTREGAS §4](../ENTREGAS.md#apresentacao)) pode-se mostrar `run_tests.gd` e as screenshots de QA como parte da arquitetura.

## 4. Escopo

### Inclui
- `tests/test_case.gd` (`class_name TestCase`) com asserções.
- `tests/run_tests.gd` (`extends SceneTree`): descobre `tests/test_*.gd`, roda `test_*`, imprime resultado, sai com código ≠ 0 em falha; filtro opcional.
- `tests/test_project_settings.gd` (valida F01: ações, camadas, renderer, viewport).
- `tools/smoke.sh` + `tests/scenes.txt`.
- Autoload `QACapture` (`autoload/qa_capture.gd`) registrado no `[autoload]` (fica por último quando a F02 registrar os outros).
- Formato de roteiro JSON em `tests/qa/*.json` e pasta `tests/qa/scenes/` para cenas-sonda.

### Não inclui
- Addons GUT/gdUnit4 (vetados pelo ADR-007).
- Testes de cena/física automáticos (cobertos pelo smoke + QA visual).
- Gravação de vídeo, comparação automática de imagens (o agente lê as screenshots) — Final se útil.
- CI no GitHub Actions — Final.
- A skill `godot-qa` em si (orquestrador).

## 5. Critérios de aceite

- [x] `"$GODOT" --headless --path . -s res://tests/run_tests.gd` roda todas as suítes, imprime `PASS`/`FAIL` por teste e um resumo `N passed, M failed`, e sai com código 0 só se `M == 0`.
- [x] `-- --filter=test_balance` roda apenas arquivos cujo nome contém o filtro.
- [x] Uma asserção falsa num teste de exemplo faz o exit code ser 1 e mostra arquivo, método e mensagem.
- [x] `tests/test_project_settings.gd` passa: 12 ações do GDD-2.4 existem no `InputMap`, 7 nomes de camada corretos, `rendering_method == "gl_compatibility"`, viewport 384×216, stretch `viewport`/`integer`.
- [x] `tools/smoke.sh` lê `tests/scenes.txt`, carrega cada cena por 60 frames headless e falha (exit 1) listando as cenas com `SCRIPT ERROR`, `Parse Error` ou `ERROR:`; linhas vazias e iniciadas por `;` são ignoradas.
- [x] Sem `--qa`, `QACapture` não faz nada (`set_process(false)`), não imprime nada.
- [x] Com `-- --qa --qa-scene=<cena> --qa-script=<json> --qa-out=<dir>`: abre a cena, injeta as ações nos frames indicados, salva `<dir>/<nome>.png` nos frames indicados, grava `<dir>/qa_log.txt` e fecha o jogo sozinho ~30 frames após o último evento.
- [x] Screenshots saem na resolução interna 384×216 e, com `--qa-scale=3`, ampliadas por nearest (1152×648).
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
tests/test_case.gd              class_name TestCase extends RefCounted
tests/run_tests.gd              extends SceneTree
tests/test_project_settings.gd  extends TestCase
tests/scenes.txt
tests/qa/                       roteiros *.json
tests/qa/scenes/                cenas-sonda de QA (entram no smoke)
tools/smoke.sh                  bash, chmod +x
autoload/qa_capture.gd          extends Node, process_mode ALWAYS
```

### `TestCase`
```gdscript
class_name TestCase
extends RefCounted

var failures: Array[String] = []

func assert_true(value: bool, message: String = "") -> void
func assert_false(value: bool, message: String = "") -> void
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void
func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void
func assert_not_null(value: Variant, message: String = "") -> void
```
Hooks opcionais: `before_each()`, `after_each()`. Uma suíte = um arquivo `tests/test_<assunto>.gd` com métodos `test_<caso>()` sem argumentos.

### `run_tests.gd`
- `_initialize()`: `await process_frame` (garante autoloads prontos); se `root.get_node_or_null("EventBus")` for nulo mas existir `autoload/EventBus` em `ProjectSettings`, instancia manualmente cada autoload listado em `ProjectSettings` (`autoload/<Nome>`, removendo o `*`) e adiciona à `root` com o nome certo.
- Lista `res://tests/` via `DirAccess`, ordena, filtra `test_*.gd` e o `--filter` de `OS.get_cmdline_user_args()`.
- Para cada arquivo: `load(path).new()`; para cada método de `get_method_list()` que começa com `test_`: `before_each` → método → `after_each`; falhas coletadas de `failures` (zerado entre testes).
- Saída: `PASS test_balance.gd::test_constants_match_gdd` / `FAIL … — mensagem`; ao fim `N passed, M failed`; `quit(1 if M > 0 else 0)`.
- `print` é permitido aqui (infra de teste).

### `tools/smoke.sh`
```bash
#!/usr/bin/env bash
set -u
GODOT="${GODOT:-/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.."
failed=0
while IFS= read -r scene || [ -n "$scene" ]; do
  case "$scene" in ""|";"*) continue ;; esac
  out=$("$GODOT" --headless --path . --quit-after 60 "$scene" 2>&1)
  if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error|ERROR:"; then
    echo "SMOKE FAIL $scene"; echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR:" | head -5; failed=1
  else
    echo "SMOKE OK   $scene"
  fi
done < tests/scenes.txt
exit $failed
```
(Arquivo `.sh` não é `.gd`: o `#!` é necessário; a varredura de comentários só olha `*.gd`.)

### `tests/scenes.txt`
Uma cena `res://…tscn` por linha; cada feature acrescenta as suas. Inicial:
```
res://scenes/boot/splash.tscn
```

### `QACapture`
Flags de usuário (depois de `--`), lidas de `OS.get_cmdline_user_args()`:

| Flag | Efeito |
|---|---|
| `--qa` | Ativa o autoload (sem ela nada acontece) |
| `--qa-scene=res://…tscn` | Troca para essa cena no primeiro frame (`get_tree().change_scene_to_file`, exceção do ADR-F06-001) |
| `--qa-script=res://tests/qa/<nome>.json` | Roteiro de eventos |
| `--qa-out=/caminho/absoluto` | Pasta de saída (criada se não existir); padrão `user://qa/` |
| `--qa-scale=3` | Fator inteiro de ampliação nearest das screenshots (padrão 1) |
| `--qa-new-game` | Chama `GameState.new_game()` antes de abrir a cena (se o autoload existir) |

Roteiro JSON (array; frames contados a partir do primeiro `process` depois da troca de cena):
```json
[
  {"frame": 10, "screenshot": "f12_idle"},
  {"frame": 20, "action": "move_right", "pressed": true},
  {"frame": 80, "action": "move_right", "pressed": false},
  {"frame": 82, "screenshot": "f12_walked_right"},
  {"frame": 90, "action": "jump", "pressed": true},
  {"frame": 96, "action": "jump", "pressed": false},
  {"frame": 100, "screenshot": "f12_jump_apex"},
  {"frame": 160, "quit": true}
]
```
- Ação: cria `InputEventAction` (`action`, `pressed`, `strength = 1.0`) e chama `Input.parse_input_event` — atualiza `Input.is_action_pressed` **e** dispara `_input`/`_unhandled_input` (menus com foco respondem a `ui_accept`, `ui_down` etc.).
- Screenshot: `await RenderingServer.frame_post_draw`; `get_viewport().get_texture().get_image()`; se `scale > 1`, `resize(w*scale, h*scale, Image.INTERPOLATE_NEAREST)`; `save_png(out/<nome>.png)`.
- `quit`: `get_tree().quit(0)`. Sem `quit` explícito, sai 30 frames após o último evento. Timeout de segurança: 3600 frames.
- `qa_log.txt`: uma linha por evento executado (`frame 82 screenshot f12_walked_right.png`) + cena atual a cada troca.
- Comando completo (o que a skill `godot-qa` executa):
```bash
"$GODOT" --path . --fixed-fps 60 -- --qa --qa-scene=res://scenes/boot/splash.tscn \
  --qa-script=res://tests/qa/f03_splash.json --qa-out=/tmp/orbita-qa/f03 --qa-scale=3
```
`--fixed-fps 60` torna a contagem de frames determinística.

### Autoloads / sinais do EventBus
- `QACapture="*res://autoload/qa_capture.gd"` no `[autoload]`. Não usa EventBus.

### Input actions / camadas de colisão
- Só lê/injeta as existentes.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| — | Nenhum | — |

## 8. 🧑 Ação humana

Nenhuma. (Na primeira execução com janela, o macOS pode pedir permissão de "Gravação de Tela" — não é o caso aqui, porque a captura é do viewport do próprio Godot e não da tela do sistema.)

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_case.gd` e `tests/run_tests.gd`; suíte `tests/test_runner_selfcheck.gd` com um teste que passa; rodar (exit 0). Temporariamente um teste que falha → exit 1; remover.
- [x] **Passo 2** — `tests/test_project_settings.gd`.
- [x] **Passo 3** — `tools/smoke.sh` (`chmod +x`) + `tests/scenes.txt`.
- [x] **Passo 4** — `autoload/qa_capture.gd` + registro no `project.godot`.
- [x] **Passo 5** — Roteiro `tests/qa/f06_selfcheck.json` e cena `tests/qa/scenes/input_probe.tscn` (Label que mostra quais das 12 ações estão pressionadas e um contador de frames).
- [ ] **Passo 6** — Rodar os 3 portões + QA; commit `test(F06): runner de testes, smoke de cenas e captura de QA`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_runner_selfcheck.gd` (asserções básicas do `TestCase`), `test_project_settings.gd` (seção 5).
- **Smoke:** `res://scenes/boot/splash.tscn`, `res://tests/qa/scenes/input_probe.tscn`.
- **Roteiro godot-qa:** cena `input_probe.tscn`, roteiro `f06_selfcheck.json`: frame 10 screenshot `f06_idle` (nenhuma ação listada, contador ~10); frame 20 `move_right` true; frame 25 screenshot `f06_move_right` (Label mostra `move_right`); frame 30 `move_right` false; frame 35 `jump` true; frame 36 screenshot `f06_jump` (mostra `jump`); frame 40 `quit`. Conferir `qa_log.txt` com 5 linhas de evento e as 3 PNGs em 1152×648 com `--qa-scale=3`.
- **Playtest humano (opcional):** —

## 11. ADRs locais

### ADR-F06-001 — `QACapture` troca de cena sem `SceneManager`
- **Contexto:** a regra é trocar cena só pelo `SceneManager`, mas fade/loading atrapalham a contagem de frames e a F06 vem antes da F03.
- **Decisão:** `QACapture` usa `change_scene_to_file` diretamente, só com `--qa`. É a única exceção permitida.
- **Consequências:** roteiros começam exatamente na cena pedida. **Data:** 2026-09-19.

### ADR-F06-002 — Runner instancia autoloads se preciso
- **Contexto:** não há garantia documentada de que autoloads existem com `-s` em todas as versões 4.x.
- **Decisão:** o runner espera um frame e, se faltar, instancia manualmente a partir de `ProjectSettings`.
- **Consequências:** testes podem usar `Settings`/`EventBus`; testes de lógica pura continuam instanciando scripts com `.new()`. **Data:** 2026-09-19.

### ADR-F06-003 — F06 antes da F02
- **Contexto:** a F02 nasce com testes; o runner precisa existir antes.
- **Decisão:** ordem efetiva do Bloco 0: F01 → F06 → F02 → F05 → F03 → F04 (respeitando `depends_on`).
- **Consequências:** TDD desde a primeira linha de lógica. **Data:** 2026-09-19.

### ADR-F06-004 — `smoke.sh` ignora o balanço de recursos do desligamento
- **Contexto:** ao sair por `--quit-after`, o Godot 4.7.2 imprime `ERROR: N resources still in use at exit` (+ `at: clear (core/io/resource.cpp)`) sempre que **há áudio tocando no instante do encerramento**. Não é erro da cena: o `Main::cleanup` faz o balanço depois de a cena ter rodado inteira e sem falha. Comprovado por bisseção: cena com SFX curto que termina antes de sair → sem vazamento; cena com música em loop → vazamento; parar a música ~40 frames antes de sair → sem vazamento. Como `--quit-after` não notifica nó nenhum (`NOTIFICATION_WM_CLOSE_REQUEST` não é disparado), nenhuma cena consegue se defender.
- **Decisão:** o `smoke.sh` filtra **apenas** essas duas linhas antes da varredura. `SCRIPT ERROR`, `Parse Error` e qualquer outro `ERROR:` continuam reprovando.
- **Consequências:** o portão 3 permanece útil quando as fases da F28/F29 tocarem trilha. O `AudioManager` ganhou `stop_all()` e o `QACapture` o chama antes de sair, então as execuções de QA saem limpas. Fluxos que fecharem o jogo (F07 "Sair", F09) devem chamar `AudioManager.stop_all()` antes de `get_tree().quit()`. **Data:** 2026-09-19.

### ADR-F06-005 — `test_case.gd` fora da descoberta e limpeza de áudio no runner
- **Contexto:** `tests/test_case.gd` casa com o padrão `test_*.gd` e seria coletado como suíte; e, depois das suítes de áudio, o runner saía com o mesmo balanço de recursos do ADR-F06-004.
- **Decisão:** o runner exclui `test_case.gd` e `run_tests.gd` por nome e, antes de `quit()`, silencia todo `AudioStreamPlayer` da árvore e espera `create_timer(0.3)` — tempo real, porque quem recolhe os playbacks parados é a thread de áudio, não o frame.
- **Consequências:** portão 2 sai 100% limpo (`68 passed, 0 failed`, sem `WARNING`/`ERROR`). **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do ADR-007 e do contrato do QACapture · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**:
  - `tests/test_case.gd` (`class_name TestCase`) com `assert_true/false/eq/ne/almost_eq/not_null/null`, `fail()`, hooks `before_each`/`after_each` e `failures: Array[String]`. As 4 suítes que já existiam (`test_balance`, `test_game_state`, `test_settings`, `test_scene_paths`) passaram **sem nenhuma alteração** — o formato escrito por elas é exatamente o da seção 6.
  - `tests/run_tests.gd` (`extends SceneTree`): descoberta ordenada em `res://tests/`, `--filter=`, `PASS/FAIL <arquivo>::<método>`, resumo `N passed, M failed`, `quit(1)` em falha.
  - `tests/test_runner_selfcheck.gd` e `tests/test_project_settings.gd` (12 ações, 7 camadas, renderer, 384×216, stretch, filtro nearest, main_scene, 8 autoloads).
  - `tools/smoke.sh` (`chmod +x`, com `perl -e 'alarm 90'` por causa da ausência de `timeout` no macOS) + `tests/scenes.txt` com 4 cenas.
  - `autoload/qa_capture.gd` registrado **por último** no `[autoload]`; flags `--qa`, `--qa-scene`, `--qa-script`, `--qa-out`, `--qa-scale`, `--qa-new-game`; roteiro JSON com `frame`/`action`/`pressed`/`screenshot`/`scene`/`quit`; `qa_log.txt`; saída automática 30 frames após o último evento; trava de segurança em 3600 frames.
  - Roteiros `tests/qa/f06_selfcheck.json` e `tests/qa/f06_boot.json`; sondas `tests/qa/scenes/input_probe.tscn`/`.gd`.
- **Decisões**: ADR-F06-004 (filtro do balanço de recursos no smoke) e ADR-F06-005 (exclusão do `test_case.gd` + limpeza de áudio no runner). O ADR-F06-002 continua valendo como rede de segurança, mas foi **verificado** que o Godot 4.7.2 **já cria os 8 autoloads** com `-s`: o caminho manual nunca dispara.
- **Verificações**: import limpo; `68 passed, 0 failed` (exit 0); asserção falsa proposital → exit 1 com `FAIL test_tempfail.gd::test_intentional_failure — falha proposital — esperado 2, obtido 1`; `--filter=test_balance` → só 5 testes; smoke 4/4 OK; varreduras 3D e de comentários vazias. QA com janela: `f06_idle` (FRAME 10 / NENHUMA), `f06_move_right` (FRAME 25 / `move_right`), `f06_jump`, `f06_splash` (logo ÓRBITA no meio do fade-in), `f06_loading` (CARREGANDO SETOR + barra + dica) — todas 1152×648 com `--qa-scale=3` e 384×216 sem a flag.
- **Próximo passo**: commit `test(F06): runner de testes, smoke de cenas e captura de QA` (Passo 6 segue `[ ]` porque o agente desta rodada não faz git). Cada feature nova acrescenta a sua cena em `tests/scenes.txt` e o seu roteiro em `tests/qa/`.
