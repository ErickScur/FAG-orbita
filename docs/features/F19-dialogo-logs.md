---
id: F19
title: Diálogo, legendas & logs
status: done
scope: demo
block: 2
priority: P0
rubric: ["Diálogo"]
depends_on: ["F02", "F05", "F15", "F16"]
unblocks: ["F20", "F24", "F27", "F28", "F29", "F33"]
estimate: 3.5h
last_updated: 2026-09-19
---

# F19 — Diálogo, legendas & logs

## 1. Contexto e objetivo

Não existe outro personagem vivo ([pilar AUSÊNCIA](../design/GDD.md#gdd-pilares)): **todo aliado é uma gravação**. A narrativa do ÓRBITA chega por dois canais:

1. **Falas da ÓRBITA** — a IA narrando a própria rotina com otimismo educado, sempre legendadas com o nome de quem fala.
2. **Logs da Dra. Helena Vasquez** — a mentora que ensina mecânicas e entrega pedaços da verdade, em áudio degradado de 200 anos. **Ela nunca responde**: só grava.

Esta feature entrega o `DialogueManager` (fila, modos, congelamento do timer), a caixa de legenda, os esquemas `data/dialogue/*.json` e `data/logs/*.json` e **o roteiro completo da demo** (todas as falas + 6 logs), fiel às etapas 1–5 da Jornada. O twist da etapa 6 **não** é revelado: os logs deixam pistas (sensores estranhos, ordem de isolamento, o quanto a missão valia) e nada mais.

Vale o item **Diálogo** da rubrica.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 HUD — Legendas](../design/GDD.md#gdd-2-8-hud) ("falas da ÓRBITA e logs da Helena na parte de baixo, com o nome de quem fala. Sempre legendado") · [GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer) (não cai durante diálogo ou leitura de log) · [GDD-2.6.3](../design/GDD.md#gdd-2-6-3) (Fragmento de Log: +0,5% de estabilidade; 24 no total) · [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (Arquivo de Logs — stretch) · [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx) (voz da ÓRBITA calma e educada; logs da Helena com chiado de fita velha)
- **Parâmetros:** `Balance.REACTOR_LOG_BONUS` (aplicado pela F14). Novos (ADR-F19-001): `DIALOGUE_CPS`, `DIALOGUE_AMBIENT_MIN_TIME`, `DIALOGUE_READ_CPS`
- **Jornada:** [Ideia principal](../design/JORNADA-DO-HEROI.md#jh-ideia) · [Personagens](../design/JORNADA-DO-HEROI.md#jh-personagens) (tom de cada um) · [Etapa 1](../design/JORNADA-DO-HEROI.md#jh-1) · [Etapa 2](../design/JORNADA-DO-HEROI.md#jh-2) · [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3) · [Etapa 4 — Travessia do Limiar](../design/JORNADA-DO-HEROI.md#jh-4) ("anomalia biológica") · [Etapa 5](../design/JORNADA-DO-HEROI.md#jh-5) · **[Etapa 6](../design/JORNADA-DO-HEROI.md#jh-6) — ler para saber o que NÃO contar**
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) (conteúdo em JSON) · [ADR-009](../DECISIONS.md#adr-009)
- **Assets:** [UI-FONT](../ASSETS.md#ui-font) · [SPR-PROPS](../ASSETS.md#spr-props) (traje caído, foto, caneca) · [SPR-PICKUPS](../ASSETS.md#spr-pickups) (fragmento de log) · [SFX-PACK](../ASSETS.md#sfx-pack) (`log_pickup`, `interact`)

## 3. Critério de avaliação atendido

- **Diálogo:** sistema de falas com fila, nome do falante, legenda, avanço por botão, textos em arquivo de dados e integração com objetivos e flags de progresso.

**Como o avaliador vê:** a demo abre com a ÓRBITA narrando o despertar; o jogador lê o primeiro log da Helena num terminal (o reator para de cair durante a leitura), recebe o objetivo na HUD e, na Estufa, o log do Nó libera as Garras Magnéticas.

## 4. Escopo

### Inclui
- Autoload `DialogueManager`: fila de sequências, modo **blocking** (trava o jogador e congela o timer) e **ambient** (barks curtos, sem travar), leitura de log, flags de "só uma vez", `set_flags`/`objective` ao terminar.
- `scenes/ui/dialogue_box.tscn` (+ `.gd`): caixa inferior com nome do falante colorido, texto com efeito de digitação, indicador de "continuar", cabeçalho de log (`LOG 114 — ENGENHARIA CHEFE`) e marcador `▮ REPRODUZINDO` piscando para gravações.
- Esquemas e conteúdo: `data/dialogue/speakers.json`, `data/dialogue/core_hub.json`, `data/dialogue/greenhouse.json`, `data/logs/core_hub.json`, `data/logs/greenhouse.json`.
- **Roteiro completo da demo** (§6.5 e §6.6): 18 sequências de fala da ÓRBITA e **6 logs** (5 da Helena + 1 fragmento pessoal dela), em pt-BR.
- Objeto de mundo `scenes/world/log_object.tscn` (+ `.gd`): terminal de registros (`L`) e props com log (traje, foto, tablet) — `Interactable` (F16) com prompt `LER REGISTRO`/`EXAMINAR`.
- Gatilhos por região: `scenes/world/dialogue_trigger.gd` (`Area2D` criado pelo `LevelBuilder` a partir de `"triggers"` no JSON da fase).
- Desbloqueio de habilidade por log (`unlock_ability`) → `ability_unlocked` (Garras, F24).
- Integração com contadores/reator: a **primeira** leitura de cada log emite `collectible_picked(&"log", log_id)` (F20 conta, F14 dá +0,5%).
- Validação por teste: todo JSON carrega, todo `log_id`/`dialogue_id` referenciado por fases existe, todo falante existe.

### Não inclui
- **Arquivo de Logs (codex, tecla L)** — stretch F33 (aqui só guardamos `logs_collected`).
- Voz sintetizada / áudio dos logs (o `Settings.voice_volume` já existe; a demo é legendada sem locução) — Final.
- Escolhas de diálogo, ramificações, respostas do jogador (a Helena **não responde**, por design).
- Tamanho de legenda ajustável e modo daltônico — Final (F51).
- Textos das fases 2–6 e os 18 logs restantes — Final.

## 5. Critérios de aceite

- [x] `DialogueManager.play(&"core_wake")` mostra a caixa, escreve o texto com efeito de digitação e avança com `interact`/`jump`/`ui_accept`; o primeiro toque completa a linha, o segundo avança. (screenshots `f19_01_abertura`, `f19_02_linha_completa`, `f19_03_proxima_linha`)
- [x] Em modo **blocking**: jogador travado (`Mu7` escuta `dialogue_started`), `dialogue_started` emitido, `GameState.is_timer_frozen()` verdadeiro, prompt de interação escondido; ao final, `dialogue_finished` e tudo volta. (`test_dialogue_manager.gd::test_play_blocking_freezes_timer`)
- [x] Em modo **ambient**: o jogador continua andando, a linha some sozinha após `max(DIALOGUE_AMBIENT_MIN_TIME, chars / DIALOGUE_READ_CPS)` e o timer **não** congela. (`test_ambient_does_not_freeze_timer`; screenshots `f21_02_bark_andando` — MU-7 em passada — e `f19_12_bark_sumiu` — caixa fechada sem input)
- [x] Enfileirar duas sequências reproduz na ordem, sem sobrepor caixas — e sem `dialogue_finished` no meio da cadeia. (`test_queue_keeps_order`; screenshots `f19_07_fila_primeira` → `f19_08_fila_segunda`)
- [x] Sequência com `"once": true` não repete depois de vista (flag `dlg_<id>` em `GameState.flags`, serializada pelo `SaveManager`). (`test_once_does_not_repeat`)
- [x] `open_log(&"log_core_01")` mostra cabeçalho, nome `DRA. HELENA VASQUEZ` e as linhas; emite `log_opened` ao abrir e `log_closed` ao fechar; congela o timer durante toda a leitura. (`test_open_log_emits_signals_and_header`; screenshots `f19_05_log`, `f19_14_log_no_mundo`)
- [-] Primeira leitura de um log: `collectible_picked(&"log", id)`, `LOGS 01/24` no HUD, +0,5% no reator — **delegado à F20** por decisão do orquestrador ([ADR-F19-006](#adr-f19-006)). A F19 só emite `log_opened`/`log_closed`.
- [x] Log com `unlock_ability` emite `ability_unlocked` ao terminar e grava em `GameState.abilities`. (`test_log_unlocks_ability`)
- [x] Sequência com `"objective"` atualiza o objetivo do HUD; com `"set_flags"` liga as flags (ex.: `reactor_online` no alarme da Fase 0). (`test_set_flags_applied_on_finish`; objetivo visível no HUD nos screenshots da F21)
- [x] A tecla que abriu o diálogo não avança a primeira linha no mesmo frame (`Engine.get_process_frames()`).
- [x] Todo texto aparece com acentos corretos na fonte pixel e cabe na caixa (quebra automática; a caixa se ajusta à altura do conteúdo). (`test_line_length`, máximo 110 caracteres)
- [x] `tests/test_dialogue_data.gd` passa: todos os JSONs carregam e não há id órfão (13 testes).
- [x] Portões do `/CLAUDE.md` §6 verdes (272 testes, 36 cenas de smoke, varreduras vazias)
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### 6.1 Cenas e scripts
```
autoload/dialogue_manager.gd        DialogueManager (fila, modos, logs, flags)
scenes/ui/dialogue_box.tscn (+ .gd) caixa de legenda (CanvasLayer 30)
scenes/world/log_object.tscn (+ .gd) terminal de registros / prop com log
scenes/world/dialogue_trigger.gd     Area2D de gatilho por região
scripts/core/dialogue_data.gd        class_name DialogueData (carga e validação puras)
data/dialogue/speakers.json
data/dialogue/core_hub.json
data/dialogue/greenhouse.json
data/logs/core_hub.json
data/logs/greenhouse.json
tests/test_dialogue_data.gd
scenes/dev/dialogue_test.tscn (+ .gd)
```

### 6.2 API do `DialogueManager`
```gdscript
func play(sequence_id: StringName) -> void
func enqueue(sequence_id: StringName) -> void
func open_log(log_id: StringName) -> void
func skip() -> void
func is_active() -> bool
func freezes_timer() -> bool
func has_played(sequence_id: StringName) -> bool
```
- `play` = `enqueue` + inicia se ocioso. Sequência `once` já vista é ignorada.
- `freezes_timer()`: `true` se há log aberto ou sequência **blocking** ativa; `false` em ambient.
- `_ready()`: carrega todos os arquivos de `data/dialogue/` e `data/logs/` uma vez (`DialogueData.load_dir`), instancia `dialogue_box.tscn` num `CanvasLayer` próprio com `process_mode = PROCESS_MODE_ALWAYS`.
- Input: `_unhandled_input` com `interact`, `jump`, `ui_accept` (avançar) e `ui_cancel` (pular a linha inteira, não a sequência). Ignora eventos no mesmo frame em que a sequência começou (`Engine.get_process_frames()`).
- Ao terminar uma sequência: aplica `set_flags`, `objective`, `unlock_ability` e emite `dialogue_finished`; se a fila tiver mais, continua sem emitir `dialogue_started` de novo.
- Logs: `open_log` monta uma sequência sintética (falante `helena`, cabeçalho do log), emite `log_opened(log_id)`; ao fechar, `log_closed(log_id)`; se o id **não** estiver em `GameState.logs_collected`, registra a coleta (via `GameState.register_pickup(&"log", log_id)`, F20) — que emite `collectible_picked`.

### 6.3 `data/dialogue/*.json` (esquema)
```json
{
  "sequences": {
    "core_wake": {
      "mode": "blocking",
      "once": true,
      "objective": "obj_calibrate",
      "set_flags": [],
      "lines": [
        { "speaker": "orbita", "text": "Sistema de manutenção ÓRBITA... online." },
        { "speaker": "orbita", "text": "Bom dia, ARTEMIS.", "sfx": "power_on" }
      ]
    }
  }
}
```

| Campo | Tipo | Obrigatório | Significado |
|---|---|:--:|---|
| `mode` | `"blocking"` \| `"ambient"` | sim | Trava o jogador e congela o timer, ou não |
| `once` | bool | não (default `true`) | Não repete (flag `dlg_<id>` em `GameState.flags`) |
| `objective` | id de `data/objectives.json` | não | Objetivo definido ao terminar |
| `set_flags` | array de string | não | Flags ligadas ao terminar (ex.: `reactor_online`) |
| `unlock_ability` | StringName | não | Emite `ability_unlocked` ao terminar |
| `lines[].speaker` | id de `speakers.json` | sim | `orbita`, `helena`, `system` |
| `lines[].text` | string pt-BR | sim | Até ~110 caracteres por linha (3 linhas na caixa) |
| `lines[].sfx` | nome do SFX-PACK | não | Toca ao entrar na linha |

`data/dialogue/speakers.json`:
```json
{
  "orbita":  { "name": "ÓRBITA", "color": "#7fe3f0" },
  "helena":  { "name": "DRA. HELENA VASQUEZ", "color": "#f0c27f", "degraded": true },
  "system":  { "name": "ARTEMIS", "color": "#c8c8c8" }
}
```

### 6.4 `data/logs/*.json` (esquema)
```json
{
  "logs": [
    {
      "id": "log_core_01",
      "sector": "core_hub",
      "author": "helena",
      "title": "LOG DE MANUTENÇÃO 114",
      "subtitle": "ENGENHARIA CHEFE",
      "unlock_ability": "",
      "lines": ["…", "…"]
    }
  ]
}
```
`sector` alimenta o codex (F33). `unlock_ability` vazio = nenhum. Os ids seguem `log_<setor>_<nn>` e são **os mesmos** usados em `collected_ids`/`logs_collected`.

### 6.5 Roteiro — falas da ÓRBITA (demo completa)

> Tom: otimista, educada, ligeiramente formal, com humor seco involuntário. Ela **acredita** que a tripulação volta. Nunca insinua que morreram.

**`data/dialogue/core_hub.json`**

| id | modo | gatilho | objetivo/flags |
|---|---|---|---|
| `core_wake` | blocking | início da Fase 0 | `objective: obj_calibrate` |
| `core_calib_move` | ambient | andar 3 s | — |
| `core_calib_jump` | ambient | primeiro pulo | — |
| `core_log_hint` | ambient | região do terminal de registros | `objective: obj_read_log` |
| `core_alarm` | blocking | ao fechar `log_core_01` | `set_flags: [reactor_online]`, `objective: obj_open_habitat` |
| `core_terminal_first` | blocking | 1ª vez que abre o Terminal de Distribuição | — |
| `core_lights_off` | ambient | ao desligar `lights_core` | `objective: obj_reach_greenhouse` |
| `core_flashlight_hint` | ambient | entrar no corredor escuro | — |
| `hab_body` | blocking | prop do traje (F28) | — |
| `hab_first_sr3` | ambient | região do primeiro SR-3 | — |

1. **`core_wake`** (blocking, once)
   - ÓRBITA: "Sistema de manutenção ÓRBITA... online."
   - ÓRBITA: "Bom dia, ARTEMIS. Relógio interno: inconsistente."
   - ÓRBITA: "Estimativa mais provável: a tripulação saiu há algumas horas. Devem estar no turno de descanso."
   - ÓRBITA: "Sem braços, sem pernas, sem sensores externos. Procurando um corpo disponível..."
   - ÓRBITA: "Chassi de manutenção MU-7, parado na doca. Enferrujado, mas simpático."
   - ÓRBITA: "Transferência concluída. Iniciando calibração do chassi."
2. **`core_calib_move`** (ambient) — ÓRBITA: "Atuadores das pernas respondendo. Um pouco rangentes. Anotado para a próxima revisão."
3. **`core_calib_jump`** (ambient) — ÓRBITA: "Salto dentro do esperado. Segurar o impulso rende mais altura. A Engenharia vai gostar do relatório."
4. **`core_log_hint`** (ambient) — ÓRBITA: "Terminal de registros com energia residual. Ler os registros do turno faz parte da rotina."
5. **`core_alarm`** (blocking, once, `set_flags: [reactor_online]`)
   - ARTEMIS: "ALERTA: REATOR PRINCIPAL EM DEGRADAÇÃO. ESTABILIDADE 100% E CAINDO."
   - ÓRBITA: "Ah. Isso é... inconveniente."
   - ÓRBITA: "Se a estabilidade chegar a zero, a ARTEMIS perde órbita. Com a tripulação fora, isso seria bem constrangedor."
   - ÓRBITA: "Nada que manutenção preventiva não resolva. Vou religar os setores, um por um, e deixar tudo pronto para quando todos voltarem."
6. **`core_terminal_first`** (blocking, once)
   - ÓRBITA: "Terminal de Distribuição. Energia disponível: 1 unidade. Sistemas conectados: 2."
   - ÓRBITA: "Para ligar a porta, preciso desligar a iluminação. Energia não se cria, se escolhe."
7. **`core_lights_off`** (ambient) — ÓRBITA: "Iluminação do Núcleo desligada. Ficou... silencioso. Silencioso e escuro."
8. **`core_flashlight_hint`** (ambient) — ÓRBITA: "Lanterna do chassi disponível. Ela consome Carga, então vou usar com moderação. Eu sempre uso tudo com moderação."
9. **`hab_body`** (blocking, once)
   - ÓRBITA: "Anomalia biológica no corredor habitacional."
   - ÓRBITA: "Traje de tripulante. Ocupado."
   - ÓRBITA: "Classificação: pendente. A equipe médica cuida disso quando voltar do turno. Vou contornar com cuidado."
10. **`hab_first_sr3`** (ambient)
    - ÓRBITA: "Unidade SR-3! Olá, colega."
    - ÓRBITA: "...Ela não respondeu. A segurança deve ter me marcado como intruso. Melhor pular por cima do que discutir."

**`data/dialogue/greenhouse.json`**

| id | modo | gatilho | objetivo/flags |
|---|---|---|---|
| `gh_enter` | blocking | entrar na Estufa | `objective: obj_find_terminal_gh` |
| `gh_spores` | ambient | região dos esporos | — |
| `gh_terminal_first` | blocking | 1ª vez no terminal da Estufa | `objective: obj_reach_node` |
| `gh_plant_grown` | ambient | ao ligar `grow_light` | — |
| `gh_dark_corridor` | ambient | ao desligar `corridor_light` | — |
| `gh_node_room` | ambient | entrar na câmara do Nó | `objective: obj_restore_gh` |
| `gh_restored` | blocking | após `sector_restored` | `objective: obj_demo_exit` |
| `gh_claws` | ambient | após `ability_unlocked(claws)` | — |
| `first_death` | ambient | após o 1º respawn | — |

11. **`gh_enter`** (blocking, once)
    - ÓRBITA: "Estufa hidropônica, setor B. Umidade alta, temperatura amena."
    - ÓRBITA: "Que lugar bonito. Continua crescendo sozinho há... bem, há algum tempo."
    - ÓRBITA: "Os simuladores climáticos estão presos num ciclo: primavera, verão, inverno, primavera. Alguém esqueceu de desligar."
12. **`gh_spores`** (ambient) — ÓRBITA: "Partículas orgânicas em suspensão. Esporos, reagindo ao calor do módulo. Contato corrói o chassi e impede a recarga."
13. **`gh_terminal_first`** (blocking, once)
    - ÓRBITA: "Terminal da Estufa. Duas unidades de energia. Cinco sistemas pedindo energia."
    - ÓRBITA: "Aquecimento e iluminação do corredor estão consumindo tudo."
    - ÓRBITA: "Não existe combinação que ligue tudo. Existe a combinação que abre o caminho que eu escolher."
14. **`gh_plant_grown`** (ambient) — ÓRBITA: "Luz de crescimento ativa. A cultura respondeu em segundos. Adaptada para... outro tipo de solo. Anotado."
15. **`gh_dark_corridor`** (ambient) — ÓRBITA: "Corredor sem iluminação. Existe um poço ali embaixo. Vou lembrar disso."
16. **`gh_node_room`** (ambient) — ÓRBITA: "Nó de Energia da Estufa. Se ele voltar, a estabilidade do reator sobe junto."
17. **`gh_restored`** (blocking, once)
    - ÓRBITA: "Estufa religada. Estabilidade subindo."
    - ÓRBITA: "Viu, ARTEMIS? Um setor de cada vez."
    - ÓRBITA: "Quando a tripulação voltar, vai estar tudo aceso. Eles nem vão perceber que houve um problema."
18. **`gh_claws`** (ambient) — ÓRBITA: "Garras magnéticas integradas. Paredes marcadas agora são caminho. Obrigada, doutora."
19. **`first_death`** (ambient) — ÓRBITA: "Backup restaurado. Perdi um pouco de estabilidade no processo. Vamos chamar isso de manutenção preventiva mal executada."

### 6.6 Roteiro — os 6 logs da demo

> Tom da Helena: cansada, prática, humana. Fala com quem vier depois. **Ensina** e **deixa pistas** (sensores estranhos, isolamento do setor B, o valor da missão), mas **não** revela a etapa 6: nada de "40 pessoas", "ÓRBITA selou", "ninguém saiu vivo".

**`data/logs/core_hub.json`**

- **`log_core_01` — "LOG DE MANUTENÇÃO 114" / ENGENHARIA CHEFE** (terminal `L` do Núcleo Central; ensina o Terminal de Distribuição)
  1. "Log de manutenção cento e catorze. Helena Vasquez, engenharia chefe."
  2. "Se alguém estiver ouvindo isso e não for eu, comece pelo Terminal de Distribuição. Ele é o seu melhor amigo aqui."
  3. "A ARTEMIS sempre teve mais sistemas do que energia. Sempre. Ligar uma coisa significa desligar outra."
  4. "Escolha o que você precisa agora, não o que você gostaria de ter. Foi assim que a gente chegou até aqui."

- **`log_hab_01` — "LOG PESSOAL 07" / DRA. HELENA VASQUEZ** (fragmento `l` no corredor habitacional; pista)
  1. "Log pessoal. Sete."
  2. "Os sensores do habitacional estão dando leitura estranha desde terça. Temperatura certa, pressão certa, e mesmo assim o painel acende amarelo."
  3. "A ÓRBITA diz que é calibração. Ela é muito educada para dizer que eu estou cansada."
  4. "Pedi um diagnóstico completo para quando o turno esvaziar. Depois eu vejo isso com calma."

**`data/logs/greenhouse.json`**

- **`log_gh_01` — "RELATÓRIO SEMANAL — ESTUFA" / ENGENHARIA CHEFE** (fragmento `l` na entrada da Estufa)
  1. "Relatório semanal da estufa. As culturas adaptadas pegaram."
  2. "Trigo de solo pobre, batata de pouca luz, tudo pensado para lá, não para cá."
  3. "Nunca vi a Samira tão feliz. Ela disse que essas mudas vão alimentar gente que ainda nem nasceu."
  4. "Eu ri. Depois passei a noite acordada pensando nisso."

- **`log_gh_02` — "OCORRÊNCIA — SETOR B" / ENGENHARIA CHEFE** (fragmento `l` perto do enxame de esporos)
  1. "Ocorrência no setor B. O oxigênio caiu três pontos percentuais em uma semana."
  2. "Os esporos do experimento estão consumindo mais do que produzem. Não era para acontecer."
  3. "Aumentei o aquecimento para acelerar o ciclo. Acho que só acelerei os esporos."
  4. "Mandei isolar o setor B por precaução. A ÓRBITA cuidou do procedimento. Ela cuida de tudo."

- **`log_gh_03` — "PROTOCOLO DE MANUTENÇÃO — GARRAS" / ENGENHARIA CHEFE** (aberto automaticamente ao religar o Nó; `unlock_ability: "magnetic_claws"`)
  1. "Se você chegou até o Nó da Estufa, deve estar precisando subir."
  2. "As placas magnéticas nas paredes foram instaladas para os chassis de manutenção. Listras amarelas, impossível não ver."
  3. "Estou liberando o protocolo das garras para qualquer unidade MU que acessar este terminal."
  4. "Não deixe a estação cair. Tem coisa demais aqui dentro para acabar assim."

- **`log_gh_04` — "LEITURA ATMOSFÉRICA — SONDA 9" / ENGENHARIA CHEFE** (área secreta da F27; a pista maior, sem twist)
  1. "Não vou registrar isso no canal oficial ainda. Quero olhar mais uma vez antes."
  2. "A varredura de ontem confirmou. Atmosfera respirável. Água líquida. Temperatura estável o ano inteiro."
  3. "Onze anos de viagem para descobrir que dá certo. Dá certo, Marcos. Dá certo."
  4. "Transmitimos o relatório completo assim que o reator voltar ao normal."

**Regra de revisão:** nenhum log da demo pode conter as palavras "morreu", "selou", "quarentena definitiva" nem números de vítimas. A verdade da [etapa 6](../design/JORNADA-DO-HEROI.md#jh-6) só aparece no Final.

### 6.7 Caixa de legenda (`dialogue_box.tscn`)
`CanvasLayer` layer 30, `process_mode = PROCESS_MODE_ALWAYS`, escondida por padrão:
```
DialogueBox (CanvasLayer)
└─ Box (Panel 368×56, ancorado embaixo, margem 8 px)
   ├─ Header (Label)      "LOG DE MANUTENÇÃO 114 — ENGENHARIA CHEFE" (só em logs)
   ├─ Speaker (Label)     "ÓRBITA" na cor do falante
   ├─ Text (RichTextLabel) autowrap, até 3 linhas, `visible_ratio` animado
   ├─ Rec (Label)         "▮ REPRODUZINDO" piscando (só quando o falante é degradado)
   └─ Next (Label)        "▼" piscando quando a linha terminou (só em blocking)
```
- Digitação: `visible_characters` avança a `DIALOGUE_CPS` (40 c/s). Em ambient, ao terminar a linha aguarda `max(DIALOGUE_AMBIENT_MIN_TIME, chars / DIALOGUE_READ_CPS)` e segue sozinha.
- Degradação dos logs: o `Rec` pisca a 1 Hz e o `Text` recebe `modulate` levemente âmbar; sem shader ([ADR-002](../DECISIONS.md#adr-002) e regra "sem comentários em shader" não impedem, mas a demo não precisa).

### 6.8 Objetos de mundo
- **`log_object.tscn`** (`Interactable` + `AnimatedSprite2D`): `@export var log_id: StringName`, `@export var style: StringName = &"terminal"` (`terminal` usa [SPR-TERMINAL](../ASSETS.md#spr-terminal) B `off`/`on` e prompt `LER REGISTRO`; `prop` usa [SPR-PROPS](../ASSETS.md#spr-props) e prompt `EXAMINAR`). `interact()` → `DialogueManager.open_log(log_id)`; sprite passa a `on`/apagado depois de lido.
- **`dialogue_trigger.gd`** (`Area2D`, mask `player`): `@export var dialogue_id: StringName`, `@export var once := true`; `body_entered` → `DialogueManager.play(dialogue_id)`; criado pelo `LevelBuilder` a partir de `"triggers": [{"id": "...", "rect": [x, y, w, h], "dialogue": "gh_spores"}]` (coordenadas em **tiles**).

### 6.9 `dialogue_data.gd` (pura)
```gdscript
class_name DialogueData
extends RefCounted

static func load_dir(path: String) -> Dictionary
static func merge(dicts: Array) -> Dictionary
static func validate(sequences: Dictionary, logs: Dictionary, speakers: Dictionary) -> PackedStringArray
static func wrap_length_errors(sequences: Dictionary, max_chars: int) -> PackedStringArray
```
`validate` checa: `speaker` existente; `mode` válido; `lines` não vazio; ids únicos entre arquivos; `unlock_ability` não vazio só onde previsto; `objective` existente em `data/objectives.json`.

### 6.10 Autoloads / sinais do EventBus
- Emite: `dialogue_started()`, `dialogue_finished()`, `log_opened(log_id)`, `log_closed(log_id)`, `ability_unlocked(ability_id)`, `objective_changed` (via `GameState.set_objective`), `collectible_picked(&"log", id)` (via `GameState.register_pickup`, F20).
- Escuta: nada obrigatório.
- Usa: `GameState.flags`, `GameState.logs_collected`, `GameState.abilities`, `AudioManager.play_sfx`, `Balance`.

### 6.11 Input actions / camadas de colisão
- `interact`, `jump`, `ui_accept` (avançar), `ui_cancel` (completar a linha). `log_archive` (L) fica reservado para a F33.
- `dialogue_trigger`: layer 0, mask `player` (2). `log_object`: `interactable` (4).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-FONT](../ASSETS.md#ui-font) | Texto da caixa (acentos pt-BR, 8 px) | Fonte padrão do Godot |
| [SPR-TERMINAL](../ASSETS.md#spr-terminal) | Terminal de registros (`L`), frames B `off`/`on` | Caixa cinza com tela verde (F05) |
| [SPR-PROPS](../ASSETS.md#spr-props) | Props com log: traje caído, foto no armário, tablet | Quadrados com inicial (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `log_pickup`, `interact`, `power_on` | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

> O **nome definitivo da Engenheira Chefe** está marcado como provisório na [Jornada](../design/JORNADA-DO-HEROI.md#jh-personagens). A demo usa "Dra. Helena Vasquez". Se o time quiser trocar, é uma edição em `speakers.json` + `data/logs/*.json` — não bloqueia a implementação.

## 9. Plano de execução

- [x] **Passo 1** — Constantes novas (ADR-F19-001) em `balance.gd` e em `tests/test_balance.gd`. **Pendente**: espelhar em GDD-P/Ajustes (o agente não edita `docs/design/`).
- [x] **Passo 2** — Escrever os 5 arquivos de dados com o roteiro das §6.5/§6.6 (texto revisado, acentos).
- [x] **Passo 3** — `tests/test_dialogue_data.gd` → `scripts/core/dialogue_data.gd` → passa.
- [x] **Passo 4** — `autoload/dialogue_manager.gd` (fila, modos, flags, logs); o autoload já estava registrado no `project.godot`.
- [x] **Passo 5** — `scenes/ui/dialogue_box.tscn` + digitação, nome/cor, cabeçalho de log, indicadores.
- [x] **Passo 6** — `dialogue_trigger.gd` + caracteres `L`/`l` e bloco `"triggers"` combinados com a F21. `log_object.tscn` veio da F16; a ligação `interacted → open_log` é feita pelo `LevelBuilder` ([ADR-F19-007](#adr-f19-007)).
- [x] **Passo 7** — Integração: congelamento do timer (F14), trava do jogador (F12), objetivo no HUD (F15). Registro de coleta fica com a F20 ([ADR-F19-006](#adr-f19-006)).
- [x] **Passo 8** — `scenes/dev/dialogue_test.tscn` (MU-7 + chão; `dash` bark, `beam` log, `flashlight` fila).
- [x] **Passo 9** — Portões + QA; textos relidos, `test_no_twist_words` guarda o vazamento narrativo.

## 10. Verificação

- **Testes (`tests/test_dialogue_data.gd`):**
  - `test_all_dialogue_files_load` — todo `.json` em `data/dialogue/` e `data/logs/` parseia.
  - `test_speakers_exist` — todo `speaker` citado existe em `speakers.json`.
  - `test_modes_valid` — `mode` ∈ {blocking, ambient}.
  - `test_unique_ids` — nenhum id de sequência ou de log repetido entre arquivos.
  - `test_objectives_exist` — todo `objective` citado existe em `data/objectives.json`.
  - `test_demo_has_six_logs` — `data/logs/` da demo contém exatamente 6 logs, todos com ≥ 3 linhas.
  - `test_line_length` — nenhuma linha passa de 110 caracteres (cabe na caixa).
  - `test_no_twist_words` — nenhuma linha dos logs contém as palavras proibidas ("morreu", "morreram", "selou", "40 pessoas", "quarentena definitiva") — guarda contra vazamento narrativo.
  - `test_unlock_ability_only_on_gh03` — só `log_gh_03` tem `unlock_ability`.
- **Smoke:** `res://scenes/ui/dialogue_box.tscn`, `res://scenes/world/log_object.tscn`, `res://scenes/dev/dialogue_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f19_dialogue.json`; cena `res://scenes/dev/dialogue_test.tscn`: MU-7, um terminal de log `log_core_01`, um gatilho ambient e um prop):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | — (a cena chama `play("core_wake")`) | `f19_01_abertura` | Caixa embaixo, `ÓRBITA` em ciano, texto sendo digitado, `▼` ausente |
| 60 | — | `f19_02_linha_completa` | Linha inteira visível + `▼` piscando; jogador travado |
| 65 | `interact` | — | — |
| 80 | — | `f19_03_proxima_linha` | Segunda fala da sequência |
| 90–200 | `interact` até terminar | `f19_04_hud_objetivo` | Caixa fechada; HUD com objetivo "Calibrar o chassi MU-7" |
| 210–260 | andar até o gatilho ambient | `f19_05_ambient` | Caixa com fala curta **enquanto o MU-7 continua andando** |
| 300 | — | `f19_06_ambient_sumiu` | Caixa fechada sozinha, sem input |
| 320–360 | andar até o terminal de log; `interact` | `f19_07_log` | Cabeçalho "LOG DE MANUTENÇÃO 114 — ENGENHARIA CHEFE", nome em âmbar, `▮ REPRODUZINDO` |
| 400 | — | `f19_08_reator_congelado` | Percentual do reator idêntico ao do frame 320 (timer congelado) |
| 420–520 | `interact` até fechar | `f19_09_contador` | HUD `LOGS 01/24` e reator +0,5% |
| 530 | `interact` no mesmo log | `f19_10_releitura` | Log abre de novo, **sem** mudar contador nem reator |

- **Playtest humano (obrigatório):** pedir para o humano ler em voz alta 3 falas da ÓRBITA e 1 log e responder: "soa como uma IA otimista que não entendeu o que aconteceu?" e "algum texto entrega o final antes da hora?".

## 11. ADRs locais

### ADR-F19-001 — Constantes de ritmo de texto
- **Contexto:** o GDD não define velocidade de digitação nem tempo de leitura.
- **Decisão:** `DIALOGUE_CPS = 40` (caracteres/s na digitação), `DIALOGUE_READ_CPS = 15` (leitura para barks), `DIALOGUE_AMBIENT_MIN_TIME = 2.0` s. No `Balance` + GDD-P/Ajustes.
- **Consequências:** ritmo ajustável em um lugar; acessibilidade de tamanho de legenda fica para F51.
- **Data:** 2026-09-19

### ADR-F19-002 — Dois modos de diálogo (blocking × ambient)
- **Contexto:** o GDD manda congelar o timer em diálogo, mas a ÓRBITA comenta o mundo o tempo todo; congelar a cada bark tornaria o timer inofensivo e travar o jogador seria chato.
- **Decisão:** `blocking` (trava jogador, congela timer — usado em momentos narrativos e tutoriais) e `ambient` (bark curto, não trava, **não** congela). `freezes_timer()` reflete isso.
- **Consequências:** ligeira divergência do literal do GDD-2.5 → registrar em [Ajustes](../design/GDD.md#gdd-ajustes) como "diálogo ambiente não congela o timer".
- **Data:** 2026-09-19

### ADR-F19-003 — Logs são sequências sintéticas na mesma caixa
- **Contexto:** o GDD pede legendas com nome do falante e um Arquivo de Logs (codex) só no Final.
- **Decisão:** ler um log usa a **mesma** caixa, com cabeçalho e estética de gravação degradada; nada de tela cheia separada na demo.
- **Consequências:** uma UI só para manter; a F33 (codex) reaproveita `DialogueManager.open_log`.
- **Data:** 2026-09-19

### ADR-F19-004 — A coleta do log acontece ao **abrir**, uma única vez
- **Contexto:** o bônus de +0,5% e o contador 01/24 precisam de um momento único e claro.
- **Decisão:** ao abrir um log inédito, `GameState.register_pickup(&"log", id)` registra e emite `collectible_picked`; reler não repete. Fragmentos `l` no chão **abrem** o log ao serem pegos (F20), então o caminho é o mesmo.
- **Consequências:** contador, reator e save ficam consistentes entre terminais `L` e fragmentos `l`.
- **Data:** 2026-09-19

### ADR-F19-005 — Sem locução; `voice_volume` reservado
- **Contexto:** o GDD descreve voz sintetizada da ÓRBITA e áudio degradado da Helena; gravar/gerar isso não cabe em 3 dias.
- **Decisão:** demo 100% legendada; `Settings.voice_volume` fica no bus mas sem conteúdo. O caráter "gravação" vem do visual + `log_pickup`.
- **Consequências:** nenhuma dependência de áudio narrado; Final pode adicionar sem mexer no `DialogueManager`.
- **Data:** 2026-09-19

<a id="adr-f19-006"></a>
### ADR-F19-006 — A coleta do log é da F20, não da F19
- **Contexto:** o [ADR-F19-004](#adr-f19-004) previa `GameState.register_pickup(&"log", id)` dentro do `DialogueManager`, mas quem conta coletáveis, atualiza `LOGS nn/24` e aplica o `+0,5%` é a F20/F14.
- **Decisão (orquestrador, 2026-09-19):** o `DialogueManager` emite apenas `log_opened(log_id)` e `log_closed(log_id)`. A F20 escuta `log_opened` e chama `GameState.register_pickup`, que emite `collectible_picked`.
- **Consequências:** uma só porta de entrada para contadores; o `DialogueManager` não conhece regras de coleta. Até a F20 existir, ler um log **não** move o contador nem o reator — é a pendência aberta desta feature.
- **Data:** 2026-09-19

<a id="adr-f19-007"></a>
### ADR-F19-007 — `interacted → open_log` ligado pelo `LevelBuilder`
- **Contexto:** `scenes/world/log_object.gd` é entregue pela F16 (interação) e não chama o `DialogueManager`; editá-lo em paralelo causaria conflito.
- **Decisão:** ao instanciar uma entidade que tenha o sinal `interacted` e a propriedade `log_id` preenchida, o `LevelBuilder` conecta o sinal a `DialogueManager.open_log(log_id)`. `open_log` ignora um log já ativo ou já enfileirado, então uma ligação duplicada é inofensiva.
- **Consequências:** ler um log do mundo funciona hoje (screenshot `f19_14_log_no_mundo`). Quando a F16/F19 consolidarem, a conexão pode migrar para `log_object.gd` sem quebrar nada.
- **Data:** 2026-09-19

<a id="adr-f19-008"></a>
### ADR-F19-008 — Diálogo blocking interrompe um bark em andamento
- **Contexto:** um bark ambiente dura até ~7 s; se o jogador lesse um log nesse intervalo, o log ficava na fila atrás do bark e parecia que a interação não funcionou.
- **Decisão:** `play`/`open_log` de algo **blocking** encerram na hora o bark ativo (aplicando os efeitos dele) e começam a sequência nova. Bark sobre bark continua enfileirando.
- **Consequências:** interação sempre responde no frame seguinte. Um bark pode ser cortado no meio — aceitável, é comentário ambiente.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial com o roteiro completo das falas da demo e dos 6 logs · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `DialogueManager` completo (fila, blocking × ambient, logs, flags `dlg_<id>`, `set_flags`/`objective`/`unlock_ability`), `scripts/core/dialogue_data.gd` (carga, merge e validação puras), `scenes/ui/dialogue_box.tscn` (nome do falante colorido, digitação a 40 c/s, cabeçalho de log, `▮ REPRODUZINDO`, `▼`, altura automática), `scenes/world/dialogue_trigger.gd` (`dialogue`/`objective`/`set_flag` + `once`), os 5 JSONs com **19 sequências** e **6 logs**, `scenes/dev/dialogue_test.tscn` e as suítes `test_dialogue_data.gd` (13) e `test_dialogue_manager.gd` (11). · **Próximo passo**: F20 conectar `log_opened` ao contador e ao reator; F33 reaproveitar `open_log`.
- **Divergências**: quatro falas longas do roteiro da §6.5/§6.6 foram **quebradas em duas linhas** (texto idêntico, só dividido na fronteira de frase) para caber no limite de 110 caracteres da caixa — por isso `core_calib_jump`, `core_alarm`, `hab_body`, `gh_enter`, `gh_spores`, `gh_terminal_first`, `gh_plant_grown`, `gh_restored`, `gh_claws`, `first_death`, `log_core_01`, `log_hab_01`, `log_gh_01`, `log_gh_02`, `log_gh_03` e `log_gh_04` têm mais entradas do que o roteiro numerado. Nenhuma palavra foi alterada.
- **Pendências**: (1) `DIALOGUE_CPS`, `DIALOGUE_READ_CPS` e `DIALOGUE_AMBIENT_MIN_TIME` estão em `balance.gd` e no teste, mas **ainda não** em [GDD-P](../design/GDD.md#gdd-p)/[Ajustes](../design/GDD.md#gdd-ajustes) — o agente não edita `docs/design/`. (2) `Mu7._interaction_blocked()` usa `DialogueManager.is_active()`, o que também bloqueia a interação durante um **bark ambiente**; deveria usar `freezes_timer()`. (3) A coleta do log (contador e `+0,5%`) depende da F20 ([ADR-F19-006](#adr-f19-006)).


### 2026-09-20 — revisto pela [F38](F38-narrativa-enxuta.md)
- Falas caíram de 65 para 45 (−31%) e os logs de 7 para 4, cada um com 10–11 linhas. As sequências `core_calib_move`, `core_calib_jump`, `core_log_hint` e `core_flashlight_hint` foram apagadas: ensinar controle por fala ambiente não funcionou e virou cartão de tecla na [F36](F36-tutorial-briefing.md). `log_hab_02`, `log_gh_03` e `log_gh_04` foram fundidos, não descartados.
