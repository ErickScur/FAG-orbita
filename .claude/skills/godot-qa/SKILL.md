---
name: godot-qa
description: Roda o ÓRBITA (ou uma cena) com janela real, injeta inputs roteirizados, confere marcos de posição/cena, captura screenshots e o log de erros, e o agente LÊ as imagens para validar a feature. Use para QA visual de qualquer feature com UI/gameplay, "teste no jogo", "veja se está aparecendo", ao fechar uma feature, ou depois de mexer num mapa (os roteiros da fase ficam falsos).
---

# godot-qa — QA visual que não mente

Na demo, o QA visual gastou 54 rodadas e várias delas "passaram" mentindo: capturas com nome
de progresso mostrando o MU-7 parado na entrada. A regra agora é: **o roteiro prova o progresso
com marcos; a screenshot confirma a aparência.**

## 1. Roteiro — `tests/qa/<feature>_<caso>.json`
Lista JSON **plana** de eventos (não há chave `scene` nem `steps`), ordenada por `frame`:

```json
[
  {"frame": 1, "call": "GameState.new_game", "args": []},
  {"frame": 1, "scene": "res://scenes/levels/core_hub.tscn"},
  {"frame": 20, "expect_scene": "res://scenes/levels/core_hub.tscn"},
  {"frame": 30, "screenshot": "01_inicio"},
  {"frame": 31, "expect_tile": [3, 61], "label": "spawn"},
  {"frame": 32, "action": "move_right", "pressed": true},
  {"frame": 90, "action": "move_right", "pressed": false},
  {"frame": 95, "expect_tile": [9, 61], "tolerance": 1, "label": "pe_do_console"},
  {"frame": 96, "screenshot": "02_pe_do_console"},
  {"frame": 120, "call": "GameState.apply_damage", "args": [100]},
  {"frame": 400, "expect_scene": "res://scenes/ui/demo_end.tscn"},
  {"frame": 410, "quit": true}
]
```

| Evento | O que faz |
|---|---|
| `action` + `pressed` | injeta ação do Input Map (nomes do CLAUDE.md §4.4; `ui_accept`/`ui_down` em menus) |
| `screenshot` | captura síncrona, loga `jogador em coluna,linha` |
| `expect_tile` (+`tolerance`, `label`) | **marco**: reprova se o MU-7 não estiver no tile (±1 padrão) |
| `expect_scene` | marco de cena atual (`scene_file_path`) |
| `expect_call` + `equals` (+`args`, `label`) | **marco de estado**: chama `Caminho/Do/No.metodo` e reprova se o retorno não for `equals` (número com tolerância; `String`≡`StringName`). Ex.: `{"expect_call": "GameState.is_timer_frozen", "equals": true}`, `{"expect_call": "SceneManager/PauseMenu.overlay_owns_focus", "equals": true}` (F67) |
| `call` + `args` | chama método por caminho a partir da raiz (`GameState.x`, `DialogueManager.y`) |
| `scene` | troca de cena no meio do roteiro |
| `quit` | encerra; sem ele o roteiro roda até o limite de segurança |

**Obrigatório em roteiro de gameplay**:
- **O roteiro carrega a própria cena** no frame 1 (`call GameState.new_game` e depois `scene`) e
  a confere com `expect_scene`. Cena inicial que só existe como `--scene` na linha de comando
  é armadilha: quem roda sem ela recebe o menu, os apertos caem nele, e as capturas "passam"
  mostrando o MU-7 parado na doca (aconteceu com `f29_greenhouse.json` em 2026-10-27).
  O `new_game` vem **antes** do `scene`: carregar a fase duas vezes grava o checkpoint da doca
  e muda o ponto de nascimento.
- Um `expect_tile` depois de cada trecho, **em ponto de repouso** (nunca no meio de um salto), e
  `expect_scene` a cada troca de cena. Roteiro sem marco não prova nada (`qa.sh` avisa).
- Avanço de diálogo com `ui_accept` e **contagem exata** (2 apertos por linha): `ui_accept` só
  avança fala, ao contrário de `interact`, que reabre o terminal de registros.
- Referência viva: `tests/qa/f29_greenhouse.json` (Estufa inteira, 27 marcos).

## 2. Execução — sempre por `tools/qa.sh`
```bash
tools/qa.sh tests/qa/<roteiro>.json --scene=res://scenes/levels/<fase>.tscn \
  --out=<scratchpad>/qa/<feature>
```
O script já resolve as armadilhas: `--fixed-fps 60` (ProMotion roda a ~120 fps e "frame" muda
de valor), `--qa-new-game` (sem isso o jogo carrega o `user://save.json` da rodada anterior e o
MU-7 nasce noutro lugar), **janela na tela secundária, sem tela cheia e sem roubar o foco**
(`--windowed --screen $ORBITA_QA_SCREEN`, padrão 1 = tela do notebook; o jogo é lançado por
`open -g` e, se o Godot tomar o foco na partida, o script devolve ao app que o humano usava;
o log do QA registra `janela na tela N (LxA)`), limite de tempo, encerramento do processo que
ficar pendurado depois do resumo, e o resumo de erros, capturas e marcos.
Sai ≠0 em erro de script, marco falho ou MU-7 parado em todas as capturas. Use `--keep-save`
só quando o caso é justamente carregar um save. Começar direto na cena da fase tira a variação
de tempo do menu e do carregamento; passe pelo menu só no roteiro que testa o menu. O
`--scene=` do `qa.sh` existe, mas prefira a cena dentro do roteiro (§1).

Saída no scratchpad da sessão, nunca no repo.

## 3. Análise
1. Leia o resumo do `qa.sh`: zero `ERRO`, todos os marcos OK, posições mudando onde deveriam.
2. **Leia cada PNG com a ferramenta Read** e compare com a seção 10 da feature: posição, HUD,
   luz, texto em pt-BR com acentos e sem glifo borrado (a m5x7 não tem setas/em-dash), nenhum
   sprite faltando.
3. O nome da captura tem de bater com o que ela mostra. Se não bater, o roteiro está errado:
   conserte a temporização e rode de novo, não aceite.
4. Registre no log da feature: roteiro, resultado do `qa.sh`, o que as capturas-chave mostram.

## 4. Armadilhas conhecidas
- **(F12)** Exercite **o controle que o GDD documenta**, não o que o código aceita: a descida de
  plataforma fina passou com ↓+pulo e quebrou na mão do jogador, que apertou só ↓.
- **(F36)** **Mexeu no mapa → os roteiros da fase mentem.** Rode e releia todos eles; os marcos
  vão reprovar, que é o objetivo.
- **(F36, corrigida na F61)** O log **abre** com um `interact` e **avança** com `ui_accept`, dois
  apertos por linha (completa a digitação, depois avança): um log de 10 linhas fecha com ~22.
  `interact` repetido não avança — na F61 o log ficou parado na linha 1 com 22 apertos. Aperto de
  `interact` sobrando em cima do terminal de registros **reabre o log**.
- **(F36/F35)** Fala travante pausa a árvore: Tween comum congela e o tempo do roteiro continua
  correndo. Dê folga depois de cada fala.
- **(F47)** Screenshot não revela tudo: buraco de alfa num tile (`blit_rect` copiando
  transparência) passou por todas as capturas e só um teste contando pixels pegou. Defeito de
  arte se prova com teste de pixel, não com foto.
- **(F06)** A captura é síncrona (`RenderingServer.force_draw(false)` + `get_image()`); não troque
  por `await frame_post_draw` (fotos idênticas com a janela sem foco) nem pause a árvore para
  esperar o desenho (trava o jogo).
- Deixe ~30 frames depois de trocar de cena antes de capturar (fade + loading).
- **(F61)** Com **um monitor só**, `--screen 1` vira erro do Godot e reprova o QA. O `qa.sh` conta
  os monitores (`system_profiler`) e só pede a tela secundária quando ela existe; senão a janela
  abre no principal, em janela e sem roubar o foco, e o script avisa `QA AVISO`.
- **(F61)** Marco de troca de cena precisa de folga para a tela de carregamento (mínimo de 1,6 s):
  ~100 quadros depois de entrar na saída. Com 80 o `f60_hub_return` reprovou na tela de loading.
- **(F61)** Roteiro longo de fase se monta **por trechos encadeados** com um gerador
  (`R` de `qa_build.py`, guardado na receita da F61): cada trecho termina com captura a cada 4–6
  quadros para ler a posição, e o tempo do trecho seguinte sai dessas posições. Repetir um trecho
  depois (a volta pela mesma rota) é o mesmo bloco com um deslocamento de quadros.
- **(F31)** **Arte trocada no disco não aparece no QA sem reimportar**: o jogo lê a textura de
  `.godot/imported`. A captura "depois do conserto" mostrou a folha antiga e quase aprovou o defeito.
  Hoje o `qa.sh` roda `--import` antes de abrir o jogo; não tire esse passo.
- **(F31, suspeita)** Não rode `tools/qa.sh` em paralelo com `tools/gates.sh` no mesmo projeto: uma
  rodada perdeu o trilho junto com o import do outro e não se repetiu sozinha.
- **(F60)** O QA abriu em **tela cheia no monitor principal** e roubou o foco do humano: o
  `Settings` carrega antes do `QACapture` e aplicava o `fullscreen=true` do `settings.cfg` dele,
  e janela em tela cheia não muda de monitor. Hoje `Settings.is_qa_run()` pula a tela cheia, a
  janela nasce na tela certa pelo `--screen` do motor (mover por código ativava o app) e o
  `qa.sh` lança por `open -g`. Nunca mova a janela do QA por código.
- **(F60)** Não espere `RenderingServer.frame_post_draw` no QA: com a janela em segundo plano e
  coberta o macOS para de desenhá-la, o sinal nunca chega e o jogo não sai (travou o `_finish`).
- **(F45)** Eventos do mesmo quadro rodam **na ordem do roteiro** só desde 2026-11-21 (antes o
  `sort_custom` instável embaralhava `new_game`/`from_dict`/`scene` e o roteiro mentia às vezes).
  Roteiro que depende de save (`Continuar`) grava o próprio com `{"call": "SaveManager.save_game"}`
  logo depois do `from_dict`: o `user://save.json` é dividido com as outras worktrees.
- **(F60)** O roteiro herda a dificuldade do `user://settings.cfg` do humano (ele joga no
  Difícil). Fixe `{"frame": 1, "call": "Settings.set", "args": ["difficulty", "normal"]}`: é o `set`
  de propriedade, não grava no arquivo dele.
- **(F60)** `pressed` sem o `released` correspondente desliga em silêncio todo pulo seguinte
  (`is_action_just_pressed` nunca mais dispara). Solte tudo antes de cada trecho acabar.
- **(F60)** Inimigo e varredura andam em **tempo real desde a carga da cena** (CX-2, patrulhas):
  roteiro que para dentro de um cone para fotografar passa numa rodada e perde o trilho na
  outra. Rode roteiro longo **pelo menos duas vezes** antes de concluir, e calibre trecho dentro
  da rodada encadeada, não a partir de estado montado.
- **(F62)** **`GameState.new_game` + `from_dict` + `scene` no meio do roteiro não calam a fala que o
  trecho anterior deixou tocando**: o `DialogueManager` é autoload e segue com a sequência. No
  `f61_hub_return` a fala de entrada da Enfermaria (trecho 1) apareceu no hub do trecho 2 e os
  `ui_accept` contados para a fala do hub foram gastos nela. Marque a fala do trecho anterior como
  vista nas `flags` (`dlg_<id>`) ou espere ela acabar antes de trocar de estado.
- **(F62)** Quem entra numa fase **por uma porta** nasce **no portal de volta** (`<x>_exit_core`),
  não no `P` (ADR-F45-002): nas Docas o MU-7 chega em 1,48, duas colunas antes do `P` (3,48). O marco
  de chegada vale o portal; o `P` só vale para jogo novo direto na cena.
- **(F66)** **Texto digitado não fecha com contagem fixa de toques**: no epílogo, dois `ui_accept`
  por parágrafo saíram do trilho porque o 1º parágrafo já tinha terminado de digitar. O gerador do
  roteiro calcula o tempo de digitação de cada parágrafo a partir do JSON (caracteres ÷ cps).
- **(F71)** QA que fechava Opções **gravava o `settings.cfg` do humano** (teclas remapeadas,
  dificuldade). Hoje `Settings.save_settings()` não grava com `--qa`; teste usa caminho próprio.
- **(F71)** `tools/gates.sh` usa `$TMPDIR/orbita-gates`, **compartilhado entre worktrees**: dois
  portões ao mesmo tempo misturam logs e relatórios. Rode com `TMPDIR=<scratchpad>/gates-<nome>`.
- **(F63)** **Luta reaproveitável entre roteiros**: escreva a luta como função com quadros relativos
  ao pouso (`tests/qa/gen/f63_fight.py`, usada pelo `f63_serralheiro` e pelo `f62_docks`) e **alinhe
  o MU-7 contra uma parede** antes do primeiro trecho: o ponto de pouso muda de um roteiro para o
  outro e a parede apaga a diferença. Para provar o fim por tempo sem esperar o relógio inteiro,
  `call` em `<nó>.set_indexed` com `"_fight:time_left"` (propriedade de um objeto filho).
- **(F63/F69)** **Roteiro que monta o save (`from_dict`) roda sem `--scene`**: o `--scene=<fase>`
  carrega a fase antes do `new_game`/`from_dict`, a fala de entrada dispara com o estado zerado e
  continua bloqueando depois que o roteiro recarrega a cena; os marcos falham com o MU-7 parado
  (`f69_f_placa_docas` na fala `dk_enter`).
- **(F64)** **Setor novo na campanha quebra roteiros antigos do hub que montam `sectors_restored`
  com ele**: a revisita nova (`core_return_<setor>`) dispara a fala ao entrar e o MU-7 fica parado
  (`f69_c_comporta_reator` falhou 3 marcos). Ponha a flag `dlg_core_return_<setor>` no `from_dict`
  de todo roteiro que já tinha o setor religado.
- **(F65)** **Pulo de 3 quadros é pulo cortado** (`JUMP_CUT_MULTIPLIER`): o bloco de 4 tiles não
  passava. Segure o `jump` ~11 quadros e solte antes do segundo aperto do pulo duplo (aperto novo).
- **(F65)** **Teleporte para dentro do cone de uma torre** dá 0,8 s até o pulso; DESCARGA trava
  o Feixe. Dispare o Feixe nos primeiros quadros e conte a Carga do roteiro (dash 20, pulo duplo
  15, Feixe 25): o 3º Feixe do Reator falhou sem Carga até o roteiro recarregar na doca.
- **(F65)** Troca de cena depois de cutscene longa: conte cutscene + silêncio + tela de
  carregamento (≥ 1,6 s) antes do `expect_scene`; o roteiro do Reator pegou a tela de loading duas vezes.
