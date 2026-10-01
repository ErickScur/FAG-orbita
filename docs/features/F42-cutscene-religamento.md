---
id: F42
title: Cutscene de religamento do setor
status: in-progress
scope: demo
block: 5
priority: P1
rubric: ["Efeitos visuais/sonoros", "Recompensas"]
depends_on: ["F17", "F18", "F21", "F28", "F29", "F35"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F42 — Cutscene de religamento do setor

## 1. Contexto e objetivo

Religar o **Nó do Setor** é o clímax da fase ([GDD-2.5](../design/GDD.md#gdd-2-5-vitoria)): é por isso que o jogador atravessou a Estufa inteira. Até aqui o jogo respondia com uma frase de texto e a tela de `FIM DA DEMO` — nenhuma recompensa visual para a única coisa que a fase pede.

A F42 transforma o religamento numa **passagem de câmera**: o jogo assume o controle, solta a câmera do MU-7 e leva o jogador de volta pelo caminho que ele acabou de fazer, acendendo lâmpadas, abrindo portas, fazendo a trepadeira crescer e os esporos recuarem **à medida que a câmera chega neles**. No fim a câmera volta ao MU-7, o controle é devolvido e só então vem a fala de encerramento.

Serve ao pilar de **consequência visível** (energia é a mecânica; ver a energia voltar é a recompensa) e vale para **qualquer fase**: o percurso é derivado da própria fase, não escrito à mão.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.5 — Condições de vitória](../design/GDD.md#gdd-2-5-vitoria) (religar o Nó = vitória da fase) · [GDD-2.5 — Regra do timer](../design/GDD.md#gdd-2-5-timer) (o timer não cai durante pausa, diálogo ou leitura de log — a cutscene entra na mesma regra)
- **Parâmetros:** `Balance.CAMERA_OFFSET_Y`, `Balance.SECTOR_FLASH_COLOR`, `Balance.SECTOR_FLASH_TIME`, `Balance.SECTOR_SETTLE_TIME` e as dez `Balance.CUTSCENE_*` ([GDD-P](../design/GDD.md#gdd-p)) — ver §11 ADR-F42-004.
- **Jornada:** [Etapa 5 — A Estufa](../design/JORNADA-DO-HEROI.md#jh-5) (a estação voltando a respirar)
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (384×216, escala inteira — câmera em pixel inteiro) · [ADR-004](../DECISIONS.md#adr-004) (fases em ASCII — o percurso sai delas)
- **Features:** [F18](F18-luz-lanterna.md) (lâmpadas), [F29](F29-fase-estufa.md) (Nó do setor e fim da Demo), [F35](F35-polimento-visual.md) (tween/pixel/câmera)

## 3. Critério de avaliação atendido

- **Efeitos visuais/sonoros:** a passagem é o maior efeito do jogo — luzes acendendo em sequência, portas abrindo, ambiente mudando de cor, `power_on` tocando lâmpada a lâmpada.
- **Recompensas:** a fase tem um clímax visível; o avaliador vê, na apresentação, o setor inteiro voltando à vida logo depois do puzzle de energia.

## 4. Escopo

### Inclui
- Câmera própria da cutscene que assume o lugar da câmera do MU-7 e devolve no fim.
- Percurso derivado da fase (limites do nível + posições dos elementos com energia), sem lista de coordenadas por fase.
- Efeitos disparados por proximidade da câmera (lâmpadas, portas, plataformas, plantas, esporos).
- Congelamento do timer do reator igual à leitura de log.
- HUD fora de cena e controle do jogador bloqueado durante a passagem.
- Pulo da cutscene com qualquer tecla/botão, deixando o mundo no estado final.
- Fala de encerramento e `FIM DA DEMO` só **depois** da cutscene.

### Não inclui
- Trilha ou SFX dedicados à cutscene (usa o `power_on` de cada elemento e o `sector_restored` do Nó).
- Cortes de câmera cinematográficos, letterbox, zoom.
- Cutscene em outros momentos (morte, chegada ao setor, etc.).
- Bloco `cutscene` opcional no JSON da fase — o padrão automático cobriu os dois níveis da Demo (ADR-F42-002).

## 5. Critérios de aceite

- [x] Religar o Nó tira o controle do jogador, esconde o HUD e move a câmera sozinha.
- [x] A câmera percorre a fase do Nó até o começo dela e volta ao MU-7.
- [x] Lâmpadas/portas/plantas acendem **em sequência**, conforme a câmera chega em cada uma.
- [x] No fim a câmera volta ao MU-7 e o controle é devolvido antes da fala de encerramento.
- [x] Qualquer tecla pula a cutscene; o estado final é idêntico ao da versão completa.
- [x] A tecla que pula **não** faz o MU-7 pular: o controle só volta depois que ela é solta (ou depois da carência).
- [x] O timer do reator não corre durante a cutscene.
- [x] O percurso é derivado da fase: uma fase nova ganha cutscene sem configuração.
- [x] Câmera sempre em pixel inteiro (sem borrão na escala inteira).
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/cutscene_route.gd    class_name CutsceneRoute — lógica pura do percurso (sem nós)
scenes/fx/sector_cutscene.tscn    Node2D + Camera2D
scenes/fx/sector_cutscene.gd      class_name SectorCutscene — máquina de fases da passagem
scenes/levels/level_base.gd       monta a cutscene e injeta limites/início/ambiente
scenes/levels/greenhouse.gd       fala de encerramento passa a esperar a cutscene
```

### Autoloads / sinais do EventBus
- **Novos:** `sector_cutscene_started(sector_id: StringName)` e `sector_cutscene_finished(sector_id: StringName)`.
- `GameState._cutscene_active` entra em `is_timer_frozen()` (mesma regra de pausa/diálogo/log).
- Escuta `EventBus.sector_restored` para começar; emite `sector_cutscene_finished` **sempre** (mesmo quando desiste, p.ex. sem jogador em cena), para nunca travar quem espera por ela.

### Derivação do percurso
1. **Início** = posição da câmera do jogador no instante do religamento (o MU-7 está colado no Nó).
2. **Fim** = `level_base.start_position()`, o spawn do `.txt` da fase (o começo do percurso do jogador).
3. **Paradas** = todo nó do grupo `powered` que ainda não está no estado "religado" (lâmpadas, portas, plataformas, plantas, esporos), ordenado pela **projeção no eixo início→fim** (funciona igual em fase horizontal e vertical), com paradas a menos de 96 px uma da outra fundidas e o total limitado a 8.
4. **Duração** = comprimento do percurso ÷ velocidade da câmera, limitado entre 3 s e 7 s.
5. A câmera usa os mesmos `limit_*` da câmera do jogador (`LevelBuilder.camera_rect`), então nunca mostra fora da fase.
6. Os efeitos não dependem das paradas: **todo** elemento com energia liga quando entra na caixa de 144×88 px em volta da câmera.

### Dados (`data/`)
- Nenhum arquivo novo. A cutscene lê `ambient_restored` do JSON da fase quando existe (já usado pela Estufa) e, quando não existe, simplesmente não mexe na cor do ambiente.

### Input actions / camadas de colisão
- Nenhuma ação nova. O pulo da cutscene aceita qualquer tecla, botão de controle, clique ou `InputEventAction` (o injetor do `QACapture`).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| — | Nenhum asset novo: a cutscene reaproveita lâmpadas, portas, plantas e o SFX `power_on`. | — |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `scripts/core/cutscene_route.gd` (lógica pura) + `tests/test_cutscene_route.gd`.
- [x] **Passo 2** — `scenes/fx/sector_cutscene.tscn/.gd` com as fases da passagem e o pulo.
- [x] **Passo 3** — montagem e injeção em `level_base.gd`; HUD no grupo `hud`; `start_position()`.
- [x] **Passo 4** — sinais no `EventBus` e congelamento no `GameState`.
- [x] **Passo 5** — `greenhouse.gd` passa a fechar a Demo depois da cutscene.
- [x] **Passo 6** — sondas de QA (`cutscene_probe`) e os três roteiros.
- [x] **Passo 7** — portões + leitura das screenshots.

## 10. Verificação

- **Testes (`tests/test_cutscene_route.gd`):** 14 casos — ordem das paradas em fase horizontal e vertical, fusão de paradas coladas, limite de paradas, fase sem nenhum elemento, caminhada pela polilinha, amostragem monotônica, duração limitada, arredondamento a pixel inteiro, curva de aceleração, caixa de revelação, **devolução do controle** (tecla presa segura, tecla solta libera, carência destrava) e **congelamento do timer** com `sector_cutscene_started/finished`.
- **Smoke:** `res://scenes/fx/sector_cutscene.tscn`, `res://tests/qa/scenes/cutscene_probe_core.tscn` e `res://tests/qa/scenes/cutscene_probe_greenhouse.tscn` em `tests/scenes.txt`.
- **Roteiros godot-qa:**
  - `tests/qa/f42_cutscene_completa.json` (sonda do Núcleo Central) — 11 capturas ao longo da passagem.
  - `tests/qa/f42_cutscene_pulada.json` — pula no meio com toque curto e compara o estado final.
  - `tests/qa/f42_cutscene_pulada_segurando.json` — pula segurando a tecla por 40 quadros (o caso que fazia o MU-7 pular).
  - `tests/qa/f42_cutscene_estufa.json` (sonda da Estufa) — passagem vertical + fala de encerramento + `FIM DA DEMO`.
  - As sondas (`tests/qa/scenes/cutscene_probe.gd`) desligam tudo que tem energia, disparam `sector_restored` sozinhas e desenham `CAM x,y · LIGADOS n/m · CONTROLE …` no canto, para a screenshot provar movimento e sequência.
- **Playtest humano:** sentir se 8–10 s de passagem é o tamanho certo ou se cansa; e se o pulo cai bem na mão.

## 11. ADRs locais

### ADR-F42-001 — Câmera própria, sem tocar no MU-7
- **Contexto:** a cutscene precisa mover a câmera, mas `scenes/player/mu7.gd` é de outro agente nesta rodada e a regra §4.2 proíbe caminho de nó entre sistemas.
- **Decisão:** a cutscene tem o seu próprio `Camera2D`. Ela guarda `get_viewport().get_camera_2d()` antes de assumir e chama `make_current()`/`reset_smoothing()` nessa câmera guardada ao devolver. O MU-7 não sabe que a cutscene existe.
- **Consequências:** zero mudança no jogador; funciona com qualquer câmera que estiver ativa. O alvo de volta é `jogador + Balance.CAMERA_OFFSET_Y`, então a troca não dá solavanco.
- **Data:** 2026-09-20

### ADR-F42-002 — Percurso derivado, sem lista por fase
- **Contexto:** o pedido era explícito: fase nova deve ganhar cutscene de graça, e `data/levels/*` estava em reforma por outro agente.
- **Decisão:** o percurso sai de (a) posição do jogador no religamento, (b) `spawn` do `.txt` da fase e (c) posições dos nós do grupo `powered`. A ordem vem da projeção no eixo início→fim, o que serve igualmente a uma fase horizontal (Núcleo) e a uma vertical (Estufa). Nenhum bloco `cutscene` foi criado no JSON porque o padrão automático bastou nas duas fases da Demo; se um dia precisar, ele entra como ajuste opcional sem quebrar o padrão.
- **Consequências:** nenhum dado novo para manter; o percurso acompanha a fase quando ela muda. Em troca, não há controle fino de enquadramento por fase.
- **Data:** 2026-09-20

### ADR-F42-003 — A passagem religa tudo que tem energia
- **Contexto:** o orçamento de energia ([GDD-2.5](../design/GDD.md#gdd-2-5-energia)) diz que nunca há estado com tudo ligado. A cutscene, porém, existe para mostrar o setor voltando.
- **Decisão:** durante a passagem, cada elemento com energia é ligado ao entrar na tela (esporos fazem o contrário: recuam). No fim — completa **ou** pulada — os que sobraram são aplicados de uma vez, para que os dois caminhos terminem no mesmo mundo.
- **Consequências:** o orçamento continua valendo durante toda a fase; ele só deixa de valer depois que o Nó do setor foi religado, que é exatamente a ficção ("o setor voltou"). Na Demo isso acontece no último segundo de jogo.
- **Data:** 2026-09-20

### ADR-F42-004 — Números no `Balance`, como manda a regra dura 6
- **Contexto:** as constantes da cutscene nasceram provisórias dentro de `SectorCutscene` porque `scripts/core/balance.gd` estava reservado a outro agente.
- **Decisão:** assim que o arquivo foi liberado, as dez migraram para o `Balance` (e para a tabela GDD-P) e o script passou a ler de lá: `CUTSCENE_CAMERA_SPEED = 220.0`, `CUTSCENE_TRAVEL_MIN_TIME = 3.0`, `CUTSCENE_TRAVEL_MAX_TIME = 7.0`, `CUTSCENE_HOLD_START_TIME = 0.8`, `CUTSCENE_HOLD_END_TIME = 1.0`, `CUTSCENE_RETURN_TIME = 1.2`, `CUTSCENE_WAYPOINT_SPACING = 96.0`, `CUTSCENE_WAYPOINT_LIMIT = 8`, `CUTSCENE_REVEAL_HALF_SIZE = Vector2(144, 88)`, `CUTSCENE_SKIP_ARM_TIME = 0.4`. `SectorCutscene` não tem mais nenhum número de jogo próprio.
- **Consequências:** ajustar o ritmo da cutscene é mexer em um lugar só. `CUTSCENE_SKIP_ARM_TIME` passou a ter dois usos: o arme do pulo e a carência de devolução do controle (ADR-F42-006).
- **Data:** 2026-09-20

### ADR-F42-006 — O controle só volta com a tecla solta
- **Contexto:** pular a cutscene com `jump` fazia o MU-7 dar um pulinho no quadro seguinte: o jogador ainda estava com a tecla apertada quando o controle voltava, e o `Input.is_action_just_pressed` do mesmo quadro chegava nele. Consumir o evento não resolve — o MU-7 lê o `Input` por polling, não por evento.
- **Decisão:** o fim da cutscene virou duas etapas. `_finish_cutscene()` devolve câmera, HUD e mundo na hora e entra na fase `RELEASE`, com o jogador **ainda travado**; `_release_control()` só acontece quando `CutsceneRoute.can_release_control(elapsed, Balance.CUTSCENE_SKIP_ARM_TIME, any_pressed)` diz que nenhuma ação está apertada — ou que a carência de 0,4 s passou, para quem segura a tecla não ficar preso. Nos dois caminhos o `just_pressed` já passou, então nada vaza para o MU-7. `sector_cutscene_finished` é emitido no fim de verdade, então a fala de encerramento também espera.
- **Consequências:** o fim natural da cutscene atravessa a mesma fase e custa um quadro a mais. A decisão é lógica pura e tem teste; o `SectorCutscene` só pergunta ao `InputMap` quem está apertado.
- **Data:** 2026-09-20

### ADR-F42-005 — A fala de encerramento espera a cutscene
- **Contexto:** `greenhouse.gd` tocava `gh_restored` no mesmo quadro do religamento, o que colocaria a caixa de fala por cima da passagem.
- **Decisão:** a Estufa marca que está encerrando ao receber `sector_restored` e só toca a fala em `sector_cutscene_finished`. Se não houver nó no grupo `sector_cutscene` (fase sem cutscene), ela toca na hora, como antes. O `demo_completed` continua saindo do fim da fala, mas agora só da fala de encerramento (antes, qualquer fala que terminasse durante o encerramento servia).
- **Consequências:** a ordem vira Nó → cutscene → fala → `FIM DA DEMO`. O clarão do ambiente saiu de `greenhouse.gd` e virou genérico dentro da cutscene (`ambient_restored` do JSON), então qualquer fase ganha o efeito.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Início
- **Quem**: agente C · **O que vou fazer**: cutscene de câmera no religamento do Nó, com percurso derivado da fase, efeitos por proximidade e pulo a qualquer momento.

### 2026-09-20 — Implementação e QA
- **Quem**: agente C
- **O que**: `CutsceneRoute` (lógica pura + 13 testes), `SectorCutscene` (câmera própria, 4 fases, pulo, efeitos por proximidade, clarão do ambiente), montagem em `level_base.gd` (+ `start_position()`, HUD no grupo `hud`), dois sinais novos no `EventBus`, congelamento do timer no `GameState`, `greenhouse.gd` fechando a Demo depois da passagem.
- **Portões**: `--import` ok · 612 testes verdes · smoke 74 cenas ok · varreduras 3D/comentários vazias.
- **QA visual** (`--fixed-fps 60`, sondas do Núcleo e da Estufa):
  - Núcleo Central, completa: câmera saiu de `1192,176` e passou por `958` → `332` → `88`, com `LIGADOS` indo de `0/8` a `8/8` **em sequência** (2/8 quando passou pela primeira lâmpada, 4/8 no terminal, 7/8 perto do início). HUD sumiu no primeiro quadro da passagem e voltou no fim; o marcador mostrou `CONTROLE CUTSCENE` durante e `CONTROLE JOGADOR` no quadro `f42_09`, com a câmera de volta exatamente em `1192,176`.
  - Núcleo Central, pulada: aos 3 s de passagem (câmera em `958`, `4/8`) uma tecla devolveu tudo em ~20 quadros; a captura tardia da versão pulada é **igual** à da versão completa (`CAM 1192,176 · LIGADOS 8/8 · CONTROLE JOGADOR`, mesmas luzes e porta aberta).
  - Estufa, vertical: câmera desceu `72,112` → `136,92` → `469,367` → `250,552`, com `LIGADOS` indo de `0/14` a `13/14` conforme descia, e o ambiente subindo do verde escuro para o verde religado. Depois da volta veio a fala `ÓRBITA — Estufa religada.` e, em seguida, a tela `FIM DA DEMO`.
- **Observações**: 1) a tecla que pula era lida pelo jogador no quadro seguinte e fazia o MU-7 dar um pulinho — corrigido na entrada seguinte. 2) O marcador da sonda congela junto com a árvore quando a fala travante começa — artefato da sonda, não do jogo.
- **Próximo passo**: migrar as constantes do ADR-F42-004 para `Balance`/GDD-P quando o arquivo estiver livre.

### 2026-09-20 — Constantes no Balance e fim do pulinho
- **Quem**: agente C
- **O que**: (1) as dez constantes saíram de `SectorCutscene` e agora vêm de `Balance.CUTSCENE_*` (ADR-F42-004) — o script não tem mais número de jogo próprio; (2) fase `RELEASE` + `CutsceneRoute.can_release_control()` (ADR-F42-006): mundo, câmera e HUD voltam na hora, mas o controle do MU-7 só é devolvido quando nenhuma ação está apertada ou quando passa a carência de `Balance.CUTSCENE_SKIP_ARM_TIME`.
- **Portões**: `--import` ok · **618 testes, 0 falhas** (14 em `test_cutscene_route.gd`) · smoke 74 cenas ok · varreduras 3D/comentários/linhas longas vazias.
- **QA visual** (sonda do Núcleo, `--fixed-fps 60`):
  - **Toque curto** (aperta no quadro 190, solta no 194): quadro `198` já mostra `CAM 1192,176 · LIGADOS 8/8 · CONTROLE JOGADOR`, HUD de volta e **o MU-7 parado, com os pés no chão** — o log do QA confirma `jogador em 74,12` em todas as capturas (antes, o pulo aparecia como `74,11`).
  - **Tecla segurada** (aperta no 190, solta só no 230): no quadro `200` o mundo já está inteiro religado e a câmera de volta, mas o marcador ainda diz `CONTROLE CUTSCENE`; no `226`, depois da carência, diz `CONTROLE JOGADOR` com a tecla **ainda apertada** e o MU-7 continua parado; no `240`, depois de soltar, segue parado.
- **Concorrência**: durante o trabalho, `data/levels/greenhouse.*`, `data/energy/greenhouse.json`, `scripts/core/balance.gd`, `docs/design/GDD.md` e `scenes/world/magnetic_wall.*` foram alterados por outros agentes; não encostei em nenhum. `scenes/levels/greenhouse.gd` continua com apenas as minhas 25 linhas de mudança.
- **Próximo passo**: commit pelo `/commit-feature` quando o humano autorizar.
