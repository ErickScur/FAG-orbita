---
id: F66
title: Sala da escolha, finais alternativos, epílogo, 40 nomes e créditos
status: done
scope: final
block: 6
priority: P0
rubric: ["Fim de jogo alternativo", "Missões secundárias", "Tela de fim de jogo"]
depends_on: ["F10", "F20", "F42", "F45"]
unblocks: ["F65"]
estimate: 6h
last_updated: 2026-11-21
---

# F66 — Sala da escolha, finais alternativos, epílogo, 40 nomes e créditos

## 1. Contexto e objetivo

É o fim do jogo. Depois de ARGOS (F65), o MU-7 entra na **sala de comando** da ARTEMIS: silêncio, escuro, poucas luzes, a baia da cápsula de sementes de um lado e o transmissor do outro, e dois consoles de alavanca: **SEMEADURA** e **TRANSMISSÃO** ([Jornada 8](../design/JORNADA-DO-HEROI.md#jh-8)). Não há desafio mecânico; o peso é a escolha ([GDD-2.7-F6](../design/GDD.md#gdd-2-7-f6)). Confirmada, a tela corta seco para uma cutscene curta e **corta para o preto no instante da execução**: o jogo nunca mostra o resultado ([Jornada 9](../design/JORNADA-DO-HEROI.md#jh-9)). Depois vêm o epílogo em texto, que muda com os Dados de Pesquisa coletados, os **40 nomes** da tripulação, as estatísticas, a pergunta *"VOCÊ ESCOLHERIA DE NOVO?"* e os créditos.

Serve aos pilares **AUSÊNCIA** (os 40 nomes, a sala vazia) e **ESCOLHA** (não há final certo, GDD-2.5). Os Dados de Pesquisa, coleta opcional espalhada pelas fases, ganham a recompensa que o GDD promete: um epílogo mais específico e confiante.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.5 Vitória](../design/GDD.md#gdd-2-5-vitoria) (as duas contam como vitória) · [GDD-2.7-F6](../design/GDD.md#gdd-2-7-f6) (sala do terminal, silêncio, duas alavancas) · [GDD-2.8 tela 8](../design/GDD.md#gdd-2-8-telas) (sem "You Win"; epílogo → 40 nomes → estatísticas → pergunta) · [GDD-2.6.3](../design/GDD.md#gdd-2-6-3) (Dado de Pesquisa muda o epílogo) · [GDD-2.9](../design/GDD.md#gdd-2-9-musica) (sala da escolha em silêncio absoluto) · [GDD-2.10 cortes](../design/GDD.md#gdd-2-10-cortes) (variação por Dados é o 4º corte; aqui ela entra)
- **Parâmetros:** `Balance.CREW_TOTAL`, `EPILOGUE_SOME_RATIO`, `EPILOGUE_MOST_RATIO`, `ENDING_ROOM_BEAT_TIME`, `ENDING_SKIP_HOLD_TIME`, `ENDING_BLACK_TIME`, `ENDING_CUTSCENE_MIN_TIME`, `ENDING_CUTSCENE_MAX_TIME`, `ENDING_TEXT_CPS`, `ENDING_READ_CPS`, `ENDING_PARAGRAPH_MIN_HOLD`, `ENDING_NAMES_SPEED`, `CREDITS_SCROLL_SPEED` ([GDD-P](../design/GDD.md#gdd-p))
- **Ajustes:** [AJ-072, AJ-073, AJ-074](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 8 — Batalha Final](../design/JORNADA-DO-HEROI.md#jh-8) · [Etapa 9 — Retorno do Herói](../design/JORNADA-DO-HEROI.md#jh-9)
- **Referência viva:** [F10](F10-telas-fim-de-jogo.md) (FIM DA DEMO, `RunStats`), [F42](F42-cutscene-religamento.md) (cutscene, devolução do controle)

## 3. Critério de avaliação atendido

- **Fim de jogo alternativo**: dois finais completos e diferentes (cutscene, epílogo e título nas estatísticas), escolhidos pelo jogador na sala de comando.
- **Missões secundárias**: os Dados de Pesquisa mudam o epílogo em três faixas; o avaliador vê o mesmo final com 0 dados ("Vão quase às cegas") e com todos ("Pouso previsto: planície costeira... quarenta e um graus").
- **Tela de fim de jogo**: a tela de vitória do GDD-2.8 (8), com estatísticas e créditos.

Na apresentação: começar na sala (`res://scenes/levels/command_room.tscn` direto no editor, ou pelo fluxo da F65), escolher um final, pular a cutscene **segurando** qualquer tecla se faltar tempo, mostrar o epílogo, os nomes, as estatísticas e os créditos; voltar ao menu e mostrar a marca `ÚLTIMA ESCOLHA`.

## 4. Escopo

### Inclui
- Sala de comando pelo pipeline ASCII + JSON (`data/levels/command_room.*`), prefixo `cmd_`, com uma fala de marco da ÓRBITA.
- Dois consoles de alavanca com confirmação e as duas máquinas (baia da cápsula, transmissor) com arte gerada.
- Momento na sala (alavanca desce, máquina acende, luzes apagam da mais distante para a mais próxima, tremor) e corte seco.
- Cutscene externa por final, dirigida por dados (`data/endings/endings.json`), pulável segurando.
- Epílogo (2 finais × 3 faixas × 7 parágrafos), 40 nomes, estatísticas, pergunta e créditos.
- Registro da escolha e de "jogo concluído" no save; marca discreta no menu principal.
- Rota de entrada para a F65 (`EventBus.argos_defeated` → sala).

### Não inclui
- ARGOS e o Núcleo do Reator (F65), que chamam esta sala.
- Música (o GDD pede silêncio na sala; créditos também em silêncio). Nenhuma faixa nova.
- Trocar o fluxo `FIM DA DEMO` (`demo_completed`): continua valendo até a F65 existir (ver §6, integração).
- Tileset próprio da sala (ADR-F66-002).

## 5. Critérios de aceite

- [x] A sala carrega pelo `SceneManager` (tela de carregamento), sem música, sem objetivo no HUD e com o reator fora do relógio; ÓRBITA diz **uma** linha ao entrar, só na primeira vez.
- [x] Baia da cápsula à esquerda, transmissor à direita, cada console ao lado da sua máquina; os quatro são distinguíveis pela silhueta numa captura (`02_sala_de_comando`, `03_console_seeding`).
- [x] Interagir num console abre a confirmação (`LANÇAR`/`TRANSMITIR` × `VOLTAR`, foco em VOLTAR). VOLTAR devolve o controle só depois que a tecla é solta (lição da F42). Confirmar grava `flags.ending` e `flags.game_completed` e salva.
- [x] A alavanca desce, a máquina acende, as luzes apagam em 3 s e a tela corta seco para a cutscene.
- [x] Semeadura: a cápsula acopla, parte rumo ao planeta-alvo e a ARTEMIS apaga módulo por módulo; Transmissão: o transmissor carrega, dispara e ondas seguem para a Terra, com o planeta-alvo vazio ao lado. As duas cortam para o preto antes de qualquer resultado (13,5–14 s), 1,5 s de silêncio, epílogo.
- [x] Um toque não pula a cutscene; segurar qualquer tecla por 1 s pula (barra de progresso no canto).
- [x] Epílogo com 3 faixas por Dados, sobre `Balance.RESEARCH_TOTAL` (nunca o número cru); a faixa alta cita latitude e hora de bordo.
- [x] 40 nomes exatos (teste), rolando devagar; `[ENTER]` pula; depois `40 PESSOAS.`.
- [x] Estatísticas: TEMPO, LOGS x/total, DADOS x/total, MORTES, FINAL.
- [x] "VOCÊ ESCOLHERIA DE NOVO?" com SIM e NÃO; os dois levam aos créditos.
- [x] Créditos: logo, equipe, professor, disciplina, Godot 4.7, fonte, arte, som, "PARA OS 40."; `[ENTER]`/`[ESC]` pulam; o fim volta ao menu.
- [x] Menu principal mostra `ÚLTIMA ESCOLHA: <FINAL>` quando o save tem o jogo concluído.
- [x] Fonte só 16/32; todo texto com glifo existente na m5x7 (teste).
- [x] Portões do `/CLAUDE.md` §6 verdes; sem comentários; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/levels/command_room.tscn (+ command_room.gd, class CommandRoom)   instância do level_base + nó Room
scenes/world/ending_console.tscn (+ .gd, class EndingConsole)            Interactable: alavanca SEMEADURA/TRANSMISSÃO
scenes/world/ending_machine.tscn (+ .gd, class EndingMachine)            baia da cápsula / transmissor, acende ao escolher
scenes/ui/ending_cutscene.tscn (+ .gd, class EndingCutscene)             cutscene externa, linha do tempo vinda do JSON
scenes/ui/ending_epilogue.tscn (+ .gd, class EndingEpilogue)             epílogo → nomes → 40 PESSOAS → estatísticas → pergunta
scenes/ui/credits.tscn (+ .gd, class Credits)                            créditos rolando → menu
scripts/core/ending_data.gd (class EndingData)                           lógica pura: faixas, flags, save, estatísticas, nomes, créditos, validação
```
Os consoles e as máquinas entram na fase pelo símbolo `o` com `"scene"` no JSON (override do `LevelBuilder`), sem símbolo novo na legenda.

### Autoloads / sinais do EventBus
- `EventBus.argos_defeated()` — **novo**. O `SceneManager` responde com `goto(ScenePaths.COMMAND_ROOM)`.
- `EventBus.ending_chosen(ending_id: StringName)` — **novo**, emitido quando a escolha é confirmada (já gravada no save).
- `ScenePaths.COMMAND_ROOM`, `ENDING_CUTSCENE`, `ENDING_EPILOGUE`, `CREDITS` — novos.
- `GameState.flags.ending` (`"seeding"`/`"transmission"`) e `GameState.flags.game_completed` (`true`).
- A sala usa `SceneManager.goto_instant` para o corte seco (sem fade) e `SceneManager.goto` dali em diante.

### Integração com a F65 (o que trocar no fim)
1. **Entrada:** ao vencer ARGOS, a F65 chama `EventBus.argos_defeated.emit()` (ou, equivalente, `SceneManager.goto(ScenePaths.COMMAND_ROOM)`). Nada mais: a sala grava o próprio checkpoint na doca da entrada.
2. **`FIM DA DEMO`:** hoje a última fase sem `next_scene` no `SectorNarrative` emite `demo_completed` → `demo_end.tscn`. Quando o Reator existir, nenhuma fase do meio pode terminar em `demo_completed`: cada setor volta ao hub (padrão da F45) e o Reator termina em `argos_defeated`. Aí `ScenePaths.DEMO_END`, `SceneManager._on_demo_completed` e `demo_end.*` podem ser removidos (ou `demo_completed` redirecionado para `COMMAND_ROOM`). Os testes que esperam `demo_end` (F10) mudam junto.
3. **Totais:** o epílogo usa `Balance.RESEARCH_TOTAL` e `Balance.LOGS_TOTAL`; quando as Docas/Memória/Reator somarem dados (12 no fim), as faixas se ajustam sozinhas (0–3, 4–8, 9–12). O roteiro `tests/qa/f66_transmissao.json` registra `RESEARCH_TOTAL` dados lendo o `balance.gd`: rode `python3 tests/qa/gen/f66.py` depois de mudar o total.
4. **Nomes:** `data/endings/crew.json` é a fonte dos 40 tripulantes; log novo que citar alguém usa um nome dessa lista (o teste `test_the_crew_includes_everyone_the_logs_mention` cobre os nomes atuais dos logs: Helena, Samira, Marcos, Teodoro, Ana Lúcia; acrescente na constante se um log novo citar outro).

### Dados (`data/`)
- `data/levels/command_room.txt` / `.json` — 40×14, corredor de entrada com doca, câmara com 3 lâmpadas e 4 vigias; entidades `cmd_*`.
- `data/dialogue/command_room.json` — `cmd_enter`, 1 linha, `once`.
- `data/endings/endings.json` — textos de UI, por final: título, prompt, confirmação, linha do tempo da cutscene (`events` com `at` e `do` ∈ `charge`, `launch`, `lights_step`, `fire`, `ring`, `cut`) e epílogo por faixa (`few`/`some`/`most`).
- `data/endings/crew.json` — 40 `{name, role}`.
- `data/endings/credits.json` — seções dos créditos (espelho do `README.md`).

### Input actions / camadas de colisão
- Nenhuma ação nova. Console na camada 4 (`interactable`, valor 8). Pular a cutscene: qualquer ação do Input Map segurada (`ENDING_SKIP_HOLD_TIME`), só depois de todas soltas (a tecla do SIM não pula sozinha).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-CMD](../ASSETS.md#spr-cmd) | Baia da cápsula, transmissor e os dois consoles (parados e acionados) | `assets/placeholder/sprites/world/command_machines_sheet.png` |
| [SPR-ENDING](../ASSETS.md#spr-ending) | ARTEMIS por fora (acesa/apagada), cápsula em voo, planeta-alvo, Terra, clarão e onda do sinal | `assets/placeholder/sprites/fx/ending_space_sheet.png` |
| TIL-CORE, BG-SPACE, UI-LOGO, UI-FONT | Reaproveitados (sala, estrelas, créditos) | — |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Arte (gen-image, 2 folhas × 2 variações) em paralelo com o código.
- [x] **Passo 2** — `EndingData` + dados + GDD-P/AJ antes do `Balance`.
- [x] **Passo 3** — Sala (ASCII + JSON), console, máquina, `CommandRoom`.
- [x] **Passo 4** — Cutscene, epílogo, créditos, marca no menu, rota da F65.
- [x] **Passo 5** — Testes, smoke, roteiros de QA com marcos, docs.

## 10. Verificação

- **Testes:** `tests/test_ending_data.gd` (18: dados completos, faixas nos dois totais e com contagem ruim, faixas e finais com textos distintos, faixa alta cita latitude, flags e ida e volta pelo save, estatísticas, 40 nomes únicos com função, nomes dos logs na tripulação, créditos com a equipe do README e os autores de terceiros, glifos na m5x7) e `tests/test_command_room.gd` (9: mapa, rota, um console por final, máquinas nos lados opostos, piso plano até os consoles, sala sem música/objetivo/relógio, sem saída nem terminal e com poucas luzes, uma fala só, cenas e folha).
- **Smoke:** `ending_machine`, `ending_console`, `command_room`, `ending_cutscene`, `ending_epilogue`, `credits` em `tests/scenes.txt`.
- **Roteiros godot-qa** (gerados por `tests/qa/gen/f66.py`):
  - `f66_semeadura.json` (23 marcos): sala → fala → console (17,12) → confirmação → escolha gravada → cutscene → cápsula partiu → corte → epílogo `few` (7 parágrafos) → nomes → 40 PESSOAS → pergunta → créditos → menu com marca.
  - `f66_transmissao.json` (22 marcos): o mesmo com TRANSMISSÃO e todos os dados (`most`).
  - `f66_dados_alto_baixo.json` (6 marcos): 2º parágrafo da Semeadura com 0 e com todos os dados.
  - `f66_pular_cutscene.json` (4 marcos): toque não pula, segurar pula, epílogo.
- **Playtest humano:** o tempo da cutscene (14 s) e da rolagem dos nomes (~36 s) cansa ou pesa do jeito certo? O texto do epílogo soa como a ÓRBITA?

## 11. ADRs locais

### ADR-F66-001 — Sala pelo pipeline de fase, máquinas por `"scene"` no `o`
- **Contexto:** a sala é uma mini-fase (HUD, MU-7, doca, luz); símbolo novo na `LEGEND` do `LevelBuilder` conflitaria com as fases F62–F65 sendo feitas em paralelo.
- **Decisão:** a sala usa o `level_base` e o símbolo `o` com `"scene"` no JSON (override já existente). Console é `Interactable`; máquina é `Node2D` com luz própria que acende ao escolher.
- **Consequências:** nenhuma mudança no construtor; alcançabilidade e testes de fase valem sozinhos. **Data:** 2026-11-21.

### ADR-F66-002 — Sala com o tileset do Núcleo Central
- **Contexto:** o contrato pedia tileset do reator/comando "se não houver"; a F65 vai gerar o do Reator ao mesmo tempo.
- **Decisão:** a sala de comando usa `core_tileset.tres` (é o comando da estação, mesma arquitetura do Núcleo) e a arte nova vai para o que só existe aqui: máquinas, consoles e a cutscene. Quando o tileset do Reator chegar, trocar é uma linha no `command_room.json`.
- **Consequências:** zero conflito com a F65; a sala lê "estação" e não "reator em colapso". **Data:** 2026-11-21.

### ADR-F66-003 — Confirmação, sem volta, e a sala esquece a escolha ao recarregar
- **Contexto:** a escolha é irreversível no enredo; um `[E]` acidental não pode decidir o fim.
- **Decisão:** confirmação com foco em VOLTAR. Confirmado, grava e salva antes de qualquer animação. O checkpoint continua sendo a doca da entrada: **CONTINUAR** depois de zerar devolve o jogador à sala, e ele pode escolher de novo (a pergunta do GDD vira possível de verdade); a escolha nova sobrescreve a anterior.
- **Consequências:** não há estado "pós-final" a manter; a marca do menu mostra a última escolha. **Data:** 2026-11-21.

### ADR-F66-004 — Corte seco e cutscene em cena própria
- **Contexto:** Jornada 9: "a tela corta no instante da execução"; uma câmera dentro da sala não mostra a cápsula partindo nem a Terra.
- **Decisão:** 3 s na sala (alavanca, máquina, luzes apagando) e `goto_instant` para uma cena externa 2D (estrelas, ARTEMIS, planeta-alvo, Terra) dirigida por uma linha do tempo em JSON; ela termina num preto seco com `AudioManager.stop_all()`, 1,5 s de silêncio, e só então o epílogo entra com o fade normal.
- **Consequências:** a cutscene é dado (tempo e ordem dos eventos testáveis: um `cut`, último, entre 10 e 25 s); as posições são composição de tela, no script. **Data:** 2026-11-21.

### ADR-F66-005 — Pular segurando, não tocando
- **Contexto:** a F42 pula com qualquer toque; no final, o SIM da confirmação ou um toque nervoso apagaria a única cutscene que não se repete.
- **Decisão:** segurar qualquer ação por 1 s, só depois de todas soltas uma vez; barra de progresso e `SEGURE PARA PULAR` aparecem enquanto segura.
- **Consequências:** roteiro `f66_pular_cutscene.json` prova os dois lados. **Data:** 2026-11-21.

### ADR-F66-006 — Três faixas pela fração de `RESEARCH_TOTAL`
- **Contexto:** o total de Dados muda a cada fase nova (8 hoje, 12 no fim).
- **Decisão:** faixas por fração com teto (30 % e 75 %), não por contagem; textos por faixa no JSON.
- **Consequências:** com 12: 0–3 / 4–8 / 9–12; com 8: 0–2 / 3–5 / 6–8. Nada a mudar quando as fases chegarem. **Data:** 2026-11-21.

### ADR-F66-007 — "VOCÊ ESCOLHERIA DE NOVO?" com SIM e NÃO sem efeito
- **Contexto:** o GDD pede a pergunta e não fala de resposta.
- **Decisão:** dois botões, os dois levam aos créditos; nada é gravado.
- **Consequências:** o jogador responde para si; não há final "certo" (GDD-2.5). **Data:** 2026-11-21.

### ADR-F66-008 — Créditos espelham o README
- **Contexto:** `docs/` não vai na build; os créditos precisam existir em jogo.
- **Decisão:** `data/endings/credits.json` mantém equipe, professor, disciplina, motor, fonte, arte e som; testes conferem contra o `README.md` (seção Equipe e autores de terceiros).
- **Consequências:** asset novo de terceiros entra no README **e** no JSON, ou o teste reprova. **Data:** 2026-11-21.

### ADR-F66-009 — O `FIM DA DEMO` sai do jogo (removido, não redirecionado)
- **Contexto:** com o Reator (F65) no hub, toda fase tem `next_scene` e o único fim de vitória é
  `argos_defeated`. As saídas eram remover o fluxo da demo ou redirecionar `demo_completed` para a
  sala de comando.
- **Decisão:** **remover**. Saem `EventBus.demo_completed`, `SceneManager._on_demo_completed`,
  `ScenePaths.DEMO_END`, `scenes/ui/demo_end.*`, o gancho `SectorNarrative.demo_end_until` (e
  `ends_demo_here`), o roteiro `f10_demo_end` e o teste de frase de fechamento. Setor sem
  `next_scene` e portal sem alvo viram `push_error` (erro de dados, não fim de jogo). A sonda da F10
  troca o botão "FIM DA DEMO" por "ARGOS VENCIDO" (`argos_defeated`). Redirecionar deixaria dois
  caminhos para a sala de comando e um sinal com nome mentiroso.
- **Consequências:** `test_the_only_ending_is_argos` (`tests/test_scene_paths.gd`) reprova se o
  sinal, a cena ou um `demo_end_until` voltarem e confere que todo `next_scene` das fases existe. A
  tela da demo continua na tag `v0.1-demo`. GDD: [AJ-075](../design/GDD.md#gdd-ajustes).
  **Data:** 2026-11-21.

## 12. Log de evolução

### 2026-11-21 — Feature criada e entregue
- **Quem**: agente de final (worktree) · **O que**: sala de comando, dois finais, cutscenes, epílogo por Dados, 40 nomes, estatísticas, pergunta, créditos, marca no menu, rota `argos_defeated` para a F65.
- **Arte**: SPR-CMD e SPR-ENDING pela geração de imagem do Codex (2 variações cada), fatiadas a 64×64, alfa binarizado.
- **Testes**: `test_ending_data.gd`, `test_command_room.gd`; `test_dialogue_manager.gd` passa a contar 24 sequências (a `cmd_enter`).
- **QA** (`tools/qa.sh`): `f66_semeadura` 23/23 marcos, `f66_transmissao` 22/22, `f66_dados_alto_baixo` 6/6, `f66_pular_cutscene` 4/4. Capturas lidas: sala escura com as quatro silhuetas legíveis e o prompt `[E] SEMEADURA`; confirmação legível; a sala apagando com só a máquina escolhida acesa; ARTEMIS acesa com a cápsula acoplada e o planeta à direita; cápsula a meio caminho com a estação quase apagada; ondas do sinal rumo à Terra com o planeta-alvo vazio embaixo; epílogo centrado em fonte 16; a faixa alta cita "quarenta e um graus de latitude"; nomes em duas colunas; estatísticas com FINAL; pergunta em 32; créditos com a logo; menu com `ÚLTIMA ESCOLHA: TRANSMISSÃO` no canto.
- **Observações**: 1) a marca do menu sumiu na primeira rodada porque o `user://save.json` é dividido com as outras worktrees; o roteiro grava o próprio save antes de voltar ao menu e confere a marca com `expect_call`. 2) Marcar o avanço do epílogo com dois toques fixos por parágrafo saiu do trilho (o 1º parágrafo já tinha terminado de digitar); o gerador calcula o tempo de digitação de cada parágrafo a partir do JSON.
- **Próximo passo**: F65 emite `EventBus.argos_defeated`; remover o fluxo `FIM DA DEMO` na integração final (§6).

### 2026-11-21 — Integração com a F65: o fluxo de fim definitivo
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: ARGOS (`argos_defeated`)
  é o único fim de vitória; o `FIM DA DEMO` foi removido (ADR-F66-009, AJ-075). A Memória volta ao
  Núcleo sozinha e a comporta do Reator abre com o Root. `RESEARCH_TOTAL` 12: `f66.py` regenerado
  (`f66_transmissao`, `f66_dados_alto_baixo`).
- **QA**: `f66_semeadura` 23/23, `f66_transmissao` 22/22; `f65_reactor` 31/31 termina na sala de
  comando vindo do hub.
