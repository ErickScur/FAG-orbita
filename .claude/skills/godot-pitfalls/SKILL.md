---
name: godot-pitfalls
description: Armadilhas reais de Godot 4.7 / GDScript que já custaram horas no ÓRBITA, organizadas por assunto — luz e sombra, UI/fonte/foco, pausa e Tween, animação, física e raycast, câmera e parallax, estado reentrante (diálogo), testes e números. Leia a seção do assunto ANTES de escrever ou mudar código que toque nele, e ao depurar algo que "não funciona sem erro no log".
---

# godot-pitfalls — o que o Godot faz em silêncio

Quase todas estas armadilhas têm o mesmo sintoma: **nenhum erro no log**, o jogo só faz a coisa
errada. Por isso valem leitura antes de codar, não depois. Formato: regra → por quê (feature de
origem).

## Testes e números (leia antes de escrever qualquer teste)
- **API do runner** (`tests/test_case.gd`): `before_each()`, `after_each()`, `fail(msg)`,
  `assert_true(v, msg)`, `assert_false(v, msg)`, `assert_eq(actual, expected, msg)`,
  `assert_ne`, `assert_almost_eq`, `assert_not_null`, `assert_null`. Nada além disso — já houve
  parse error por chamar assert inexistente. Suítes são `tests/test_*.gd`.
- **Número novo entra primeiro na GDD-P** (`docs/design/GDD.md#gdd-p`) e só depois em
  `scripts/core/balance.gd`: `tests/test_gdd_parity.gd` lê a tabela do GDD e reprova constante
  sem linha na GDD-P e valor numérico divergente (a divergência já aconteceu com as constantes
  da cutscene, F42, e só foi pega por um script improvisado).
- **Erro de script dentro de um teste não lança exceção**: o GDScript aborta só aquela função e
  o chamador segue. Até 2026-10-27 o runner contava esse teste como PASS — o
  `test_constants_match_gdd` quebrava num `Vector2` e as chaves seguintes nunca eram conferidas.
  Hoje o `run_tests.gd` escuta erros de script com um `Logger` (`OS.add_logger`) e reprova o
  teste. `ERROR:` comum (ex.: "Parse JSON failed" do teste de save corrompido) é esperado e não
  reprova.
- **Teste que depende de "asset ainda sem arte final" quebra a cada entrega de arte** (já trocamos
  a cobaia três vezes, F49). Use cobaia sintética que nunca vá existir.
- **Raycast/medição do mundo no `_ready()` mente**: a colisão dos tiles só existe depois de
  **2 quadros de física** (F54).
- **Dano por segundo escala a taxa, não os pedaços**: acumular 1 ponto por vez e passar cada
  ponto por `Vitals.scale_damage` (que arredonda para cima) fez o Fácil tirar o mesmo que o
  Normal e o Difícil o dobro, de F23 a F60 — a fornalha matava no Difícil. Use
  `GameState.apply_damage_over_time(per_second, delta, acumulador)`; teste
  `test_damage_over_time_follows_difficulty` (F60).

## Luz e sombra (renderer Compatibility)
- **Máximo de 16 `Light2D` por item de canvas**; da 17ª em diante é descartada **em silêncio**.
  19 luzes de brilho por tile tiraram a lanterna do MU-7 da lista (F43). Brilho repetido é fundido
  por trecho; `tests/test_light_crowding.gd` trava 12 luzes por janela de 256 px.
- **`OccluderPolygon2D` por tile faz o bloco sombrear a própria face.** Oclusão é o contorno da
  ilha sólida, com `cull_mode`; com oclusor por tile o `cull_mode` não adianta, porque as arestas
  entre vizinhos se sombreiam (F50).
- **Ambiente claro para compensar tileset escuro é compensar no lugar errado**: o tileset tem base
  de brilho médio e o motor escurece (F41).

## UI, fonte e foco
- **Fonte `ui_font.ttf` (m5x7) só em múltiplos de 16** (16 texto, 32 título); 8/12/24 derretem os
  glifos. No `.import`: `antialiasing=0`, `hinting=0`, `subpixel_positioning=0`,
  `keep_rounding_remainders=false` (F05/F03).
- **A m5x7 não tem `—` `←` `→` `↑` `↓` `✓` `■` `□` `▮` `▼` `•`**; tem `·`, `-` e acentos. Com
  `allow_system_fallback=true` o glifo ausente cai numa fonte do sistema, borrado. Escreva
  `[SETAS]`, `[CIMA]`, `[BAIXO]`, `[OK]`. Conferir: `font.has_char(code)` headless (F36).
- **`set_anchors_and_offsets_preset(PRESET_FULL_RECT)` antes do primeiro layout** grava
  `offset_right = largura mínima` (pai ainda com 0) e o `Control` fica largo demais. Defina
  `size`/`position` ou use `PRESET_MODE_KEEP_SIZE` (F37 — o aviso do HUD ficou torto desde a F15).
- **Modal por cima de outra tela precisa de trava de foco**: sem `focus_neighbor_*` a navegação
  por setas/controle escapa para os botões de baixo; com mouse parece funcionar. Use `FocusTrap`
  (`scripts/core/focus_trap.gd`) (F09).
- **`clip_contents` + deslize horizontal corta o texto** em container de largura fixa ("DADO DE
  PESQUISA 01/1"). Anime na vertical ou sem recorte (F35).
- **Auto-pause por perda de foco** (`NOTIFICATION_APPLICATION_FOCUS_OUT`) precisa ignorar o modo
  QA, senão abre a pausa em cima de toda captura (F06).

## Pausa, Tween e diálogo
- **Tween de nó comum é `TWEEN_PAUSE_BOUND`** e congela durante fala travante (o diálogo pausa a
  árvore). Efeito que acompanha fala: `set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` (F35).
- **Gancho que cria estado de novo**: `DialogueManager._finish_current()` aplica efeitos antes de
  esconder a caixa, e um efeito pode iniciar fala nova na hora. Toda função que limpa estado
  depois de chamar um gancho **reconfere se o gancho recriou esse estado** — sem isso a fala das
  garras rodou invisível, congelando o timer (F29/F19).
- **Guarda de "tecla consumida pelo diálogo"** vale só para `DialogueManager.ADVANCE_ACTIONS`,
  não para qualquer tecla — senão o cartão de tutorial nunca completa numa fase com fala
  ambiente (F36).

## Animação
- **Atribuir `sprite_frames` escolhe a primeira animação mas não toca.** O guarda
  `if sprite.animation == anim: return` precisa de `and sprite.is_playing()`, senão o sprite fica
  congelado no quadro 0 enquanto o nó anda (F22 — "a aranha não anima").

## Física
- **Sonda de borda com a mesma máscara do corpo**: com `mask = 1 | 7` a `FloorProbe` via
  plataforma fina como chão e o corpo (`mask = 1`) atravessava; a SR-3 caía da fase (F22).
- Raycast no `_ready()`: ver "Testes e números" (2 quadros de física).
- **`RayCast2D.hit_from_inside` é `false` por padrão**: raio que começa dentro de um corpo ignora
  esse corpo. O feixe disparado com a V-9 grudada no MU-7 não acertava nada e não dava erro.
  Ferramenta à queima-roupa usa `hit_from_inside = true` (F61).
- **Raio horizontal na altura do peito passa por cima da SR-3** (10 px de altura): o feixe sai a
  −8 px do pé e colide **só com corpos** — área de gatilho fica na camada 1 por padrão e bloquearia
  o raio (F31).

## Energia (Terminal e grupo `powered`)
- **Nó comandado por `invert` entra só por `group`**, nunca pelo par `terminal_id`/`system_id`
  do mesmo sistema: o `EnergyNetwork._drive` liga primeiro o vínculo direto, a lista `touched`
  pula o `invert`, e o esporo fazia o contrário. Mecanismo: `tests/test_energy_bindings.gd` (F60).
- **Entidade sem `terminal_id`/`system_id` herda o padrão do script** (o esporo nasce
  `greenhouse/heating`): em fase nova passe `"system_id": ""` explícito quando ela só deve
  responder a efeito de grupo (F60).

## Câmera e parallax
- **Offset de câmera arredondado a pixel inteiro** em 384×216 com escala inteira; fração borra o
  tremor (F35).
- **`Parallax2D` nasce com `follow_viewport = true`.** Numa `CanvasLayer` com
  `follow_viewport_enabled = false` a compensação soma e o fundo corre para o lado errado. As duas
  flags casam (ambas `false` aqui) (F26).

## Processo (ferramentas)
- macOS não tem `timeout`: use `tools/gates.sh`/`tools/qa.sh`, ou
  `perl -e 'alarm N; exec @ARGV' "$GODOT" ...`. Sem `run/main_scene` o Godot **fica pendurado**.
- O editor aberto pode sobrescrever `project.godot` ao salvar: peça para fechar antes de editar à
  mão (bootstrap).
- UID inventado à mão em `.tscn` não pode ter `z`: o alfabeto de UID do Godot é `a`–`y` + `0`–`9`
  (F60).

> Armadilha nova de engine entra aqui, na seção do assunto, com a feature de origem. Se ela valer
> para qualquer tarefa (processo, git, ferramenta), entra também no `CLAUDE.md` §9.
