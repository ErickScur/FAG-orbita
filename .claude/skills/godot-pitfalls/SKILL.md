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

- **`Array.sort_custom` não é estável**: elementos com a mesma chave saem em qualquer ordem. O
  `QACapture` ordenava o roteiro só pelo quadro e rodava `new_game` depois do `from_dict` do mesmo
  quadro, apagando o checkpoint (o MU-7 nascia no `P`). Desempate pelo índice original
  (`QAMarks.ordered_events`, teste `test_events_in_the_same_frame_keep_the_script_order`) (F45).
- **`AnimatableBody2D` com `sync_to_physics` desfaz o `position` atribuído fora do passo de
  física**: no teste síncrono a plataforma "não saía do lugar". O movimento vale no jogo; o teste
  confere o alvo calculado (`ThermalPlatform.point_at`), não o `position` (F65).

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
  (`scripts/core/focus_trap.gd`) (F09). O `FocusTrap` liga os controles em **lista circular**
  (esquerda = anterior): para navegação 2D (mapa radial) ponha os 4 vizinhos + `focus_next/previous`
  à mão, apontando para dentro da tela ou para o próprio botão (F67).
- **`TAB` é `ui_focus_next` do Godot**: com um botão focado, a GUI consome o `TAB` antes do
  `_unhandled_input`. Tela que usa a ação `map` (TAB) trata em `_input` e marca como tratado (F67).
- **Tela que dá foco a um botão precisa soltar o foco ao fechar**: o `can_open()` do Terminal do
  Chassi recusa abrir com qualquer foco na tela (é como ele sabe que há modal); um botão do mapa
  esquecido focado trava o `[TAB]` seguinte em silêncio. `release_focus()` no fechar; marco
  `expect_call ... can_open` no QA (F67).
- **`clip_contents` + deslize horizontal corta o texto** em container de largura fixa ("DADO DE
  PESQUISA 01/1"). Anime na vertical ou sem recorte (F35).
- **Auto-pause por perda de foco** (`NOTIFICATION_APPLICATION_FOCUS_OUT`) precisa ignorar o modo
  QA, senão abre a pausa em cima de toda captura (F06).
- **`relabel` de teclas em sequência estraga trocas A↔D**: trocar `A` por `D` e depois `D` por `A`
  devolve tudo `A`. Troque primeiro para um token intermediário único e só depois para a tecla
  final (F71).
- **`ScrollContainer` com `follow_focus` empurra o título da seção para fora** ao focar o 1º
  botão; volte o scroll ao topo com `call_deferred` depois de dar o foco (F71).
- **Ruído desenhado por código lê como texto embaralhado em 384 × 216**: um ponto aleatório a cada
  2 px, redesenhado todo quadro, vira "letras" sobre o rótulo do sinal da Terra. Use uma portadora
  regular (senoide de 1 px), linhas primitivas (`draw_polyline` com largura −1) e caixa fora da
  faixa da HUD (y > 32) (F64).

- **"O mundo está por cima da HUD" quase sempre é contraste, não camada**: rótulo sem fundo sobre
  parede clara, com um objeto do mundo encostado, lê como "atrás". Meça antes de mexer em camada
  (`tests/qa/hud_*.json`: lâmpada com `z_index` 4096 atrás de cada rótulo e lista de
  `CanvasLayer` vivos). `z_index` nunca atravessa `CanvasLayer`; luz e `CanvasModulate` só agem na
  camada 0 por padrão. Legibilidade da m5x7: **sombra 1,1**, não contorno — `outline_size` engrossa
  o traço de 1 px até virar borrão. Tema local no `Root` da HUD vale só para os filhos (F37).
- **Duas `CanvasLayer` com o mesmo `layer` empatam pela ordem da árvore**: a escolha de final
  (50) desenhava por cima da pausa (50). Toda camada vem de `UiLayers`; `test_ui_layers.gd`
  reprova número solto, camada fora da tabela e empate (F37).

## Pausa, Tween e diálogo
- **Tween de nó comum é `TWEEN_PAUSE_BOUND`** e congela durante fala travante (o diálogo pausa a
  árvore). Efeito que acompanha fala: `set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` (F35).
- **Script filho de fase montada pelo `level_base` roda `_ready` antes da fase ser construída**:
  o nó ainda não vê tiles nem entidades e a configuração some em silêncio. Configure em
  `call_deferred` (F66).
- **Gancho que cria estado de novo**: `DialogueManager._finish_current()` aplica efeitos antes de
  esconder a caixa, e um efeito pode iniciar fala nova na hora. Toda função que limpa estado
  depois de chamar um gancho **reconfere se o gancho recriou esse estado** — sem isso a fala das
  garras rodou invisível, congelando o timer (F29/F19).
- **Guarda de "tecla consumida pelo diálogo"** vale só para `DialogueManager.ADVANCE_ACTIONS`,
  não para qualquer tecla — senão o cartão de tutorial nunca completa numa fase com fala
  ambiente (F36).

- **Despausar a árvore dentro de `call_deferred` com a arena do ARGOS viva dá
  `ERROR: Condition "p_elem->_root" is true (self_list.h:46)`** (2× por vez, a partir do 3º ciclo
  abre/fecha do arquivo pelo `L`; o caminho pela pausa, que despausa no `_unhandled_input`, nunca
  dava). O `PauseMenu` fechava o arquivo direto com `close.call_deferred()`; hoje fecha na hora.
  Mude `get_tree().paused` no fluxo de input, não no flush de chamadas adiadas; repro em
  `tests/qa/review_campaign_telas_reator.json` (o `stderr` vai para o fim do `godot.log` do QA:
  para saber o quadro do erro leia o `user://logs/godot.log`, que intercala na ordem) (revisão da
  campanha).
- **Pisca de invencibilidade por `visible` some com o MU-7 dentro da doca**: a captura caiu no
  quadro apagado e a revisão leu "renasce escondido atrás da doca". O pisca esmaece
  (`modulate.a` 0,4), nunca esconde; flash branco só em golpe — dano contínuo dá um pulso fraco a
  cada 0,6 s (`HitFlashRules`, `GameState.is_damage_over_time()`) (revisão da campanha).
- Status aplicado por fonte de dano tem de passar por `GameState.apply_status`: o antigo
  `DamageArea.notify_status()` só emitia o sinal, a HUD mostrava o ícone e o efeito nunca valia
  (F68; `test_notify_status_goes_through_game_state`).
- O Terminal do Chassi recusa abrir, em silêncio, numa cena fora de `scenes/levels/` sem o grupo
  `gameplay` (banco em `scenes/dev/`): QA do chassi usa `tests/qa/scenes/chassis_probe.tscn` (F68).

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
- **Contato tangencial também é colisão**: o MU-7 deslizando rente ao teto no vácuo recebia
  `get_last_slide_collision()` a cada quadro e se reancorava parado. Só trate como batida quando a
  velocidade de antes do `move_and_slide` tinha componente contra a normal (F62).

## Energia (Terminal e grupo `powered`)
- **Nó comandado por `invert` entra só por `group`**, nunca pelo par `terminal_id`/`system_id`
  do mesmo sistema: o `EnergyNetwork._drive` liga primeiro o vínculo direto, a lista `touched`
  pula o `invert`, e o esporo fazia o contrário. Mecanismo: `tests/test_energy_bindings.gd` (F60).
- **Entidade sem `terminal_id`/`system_id` herda o padrão do script** (o esporo nasce
  `greenhouse/heating`): em fase nova passe `"system_id": ""` explícito quando ela só deve
  responder a efeito de grupo (F60).
- **Subclasse de cena compartilhada (`extends Coupler`) quebra quando outra feature acrescenta
  membro na base**: o `RootCoupler` (F65) e o `Coupler` da F63 declararam `_actor` em branches
  separadas e a integração deu `Parse Error: The member "_actor" already exists in parent class`
  (o script inteiro some, o teste para no meio). Em subclasse, prefixe os membros privados com o
  papel (`_charger`, não `_actor`) e, ao integrar, esconda o que a base nova constrói sozinha no
  `_ready` (soquete, pips) se a subclasse não usa (F65, integração).

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
- **Godot que trava antes de abrir** (até `--headless --version` não volta, `sample <pid>` mostra
  o processo parado em `_dyld_start`) é o macOS segurando o lançamento (serviço de assinatura),
  não o projeto: cada nova tentativa empilha mais um processo preso. Teste antes com
  `perl -e 'alarm 20; exec @ARGV' "$GODOT" --headless --version`, mate o que travar e avise o
  humano; não mexa em quarentena nem em segurança do sistema (F62).
- `--fixed-fps` desliga o `Engine.max_fps`/`--max-fps`: o tempo real fica limitado só pelo vsync
  (2× numa tela de 120 Hz, ~20× com a janela em segundo plano). Quem precisa de tempo real com
  `--fixed-fps` limita os quadros por conta própria (`OS.delay_usec`, F72).
- A carga em thread da tela de loading (`load_threaded_request`) corre em tempo real, não em
  quadros: roteiro longo encadeado pré-carrega as cenas ou espera com `wait_scene`, nunca com
  folga fixa de quadros (25 marcos do reator caíram em cascata, F72).
- UID inventado à mão em `.tscn` não pode ter `z`: o alfabeto de UID do Godot é `a`–`y` + `0`–`9`
  (F60).

> Armadilha nova de engine entra aqui, na seção do assunto, com a feature de origem. Se ela valer
> para qualquer tarefa (processo, git, ferramenta), entra também no `CLAUDE.md` §9.
