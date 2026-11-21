---
id: F33
title: Arquivo de Logs (codex)
status: done
scope: final
block: 5
priority: P2
rubric: ["Diálogo", "Itens e inventário"]
depends_on: ["F09", "F15", "F19", "F20"]
unblocks: []
estimate: 2h
last_updated: 2026-11-21
---

# F33 — Arquivo de Logs (codex)

## 1. Contexto e objetivo

O **Arquivo de Logs** (tecla `L`, item da pausa e **ARQUIVO** na tela inicial) é o codex do jogo:
lista os Fragmentos de Log por setor e por autor e permite reler qualquer um já encontrado
([GDD-2.8, telas 1, 3 e 5](../design/GDD.md#gdd-2-8-telas)).

É a feature que transforma a coleta em **inventário legível**: um log lido às pressas no meio do
corredor não some, e a história — pilar **DESCOBERTA** — não depende de o jogador ter prestado
atenção na primeira vez. O timer do reator **não corre** com o arquivo aberto
([GDD-2.5](../design/GDD.md#gdd-2-5-timer)).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 telas (1 — ARQUIVO; 3 — Pause com ARQUIVO DE LOGS; 5 — Arquivo de Logs)](../design/GDD.md#gdd-2-8-telas) · [GDD-2.6.3 (Fragmento de Log)](../design/GDD.md#gdd-2-6-3) · [GDD-2.5 timer](../design/GDD.md#gdd-2-5-timer) · [AJ-053](../design/GDD.md#gdd-ajustes)
- **Parâmetros:** `Balance.LOGS_TOTAL` (contador), `Balance.REACTOR_LOG_BONUS` (que o arquivo **não** concede) — [GDD-P](../design/GDD.md#gdd-p). Nenhum número novo.
- **Jornada:** [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3) · [Personagens](../design/JORNADA-DO-HEROI.md#jh-personagens)
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) (conteúdo em JSON) · [ADR-010](../DECISIONS.md#adr-010) (ação `log_archive` já mapeada em `L`)
- **Features vizinhas:** [F19](F19-dialogo-logs.md) (esquema dos logs), [F20](F20-coletaveis-contadores.md) (`GameState.collected_ids`), [F09](F09-pause-recomecar.md) (pausa), [F38](F38-narrativa-enxuta.md) (poucos logs, grandes), [F67](F67-mapa-estacao.md) (mesma ordem de setores, `data/map/station.json`).

## 3. Critério de avaliação atendido

- **Diálogo** e **Itens e inventário** ([rubrica](../ENTREGAS.md#rubrica)), somando à F19 e à F20.
- Na apresentação: `L` no meio da fase abre a lista **NÚCLEO CENTRAL / ESTUFA / LABORATÓRIO /
  ENFERMARIA** com os logs achados e `???` nos que faltam; `[LADOS]` reagrupa por autor;
  `ENTER` no log da Dra. Helena mostra o texto inteiro, com rolagem. Na tela inicial, **ARQUIVO**
  abre o mesmo codex a partir do backup.

## 4. Escopo

### Inclui
- `scenes/ui/log_archive.tscn` + `.gd`: tela cheia; lista à esquerda (grupos + títulos), ficha à
  direita (título, autor na cor do `speakers.json`, cargo, setor, primeira frase, `[ENTER] LER`),
  leitor em tela cheia com rolagem.
- Abertura por `L` em jogo (o `PauseMenu`, que vive no `SceneManager`, abre o arquivo "direto":
  pausa sem mostrar o menu e, ao fechar, volta ao jogo); pelo item **ARQUIVO DE LOGS** da pausa
  (fecha de volta para a pausa); pelo **ARQUIVO** da tela inicial (lê o `user://save.json`).
- Agrupamento **POR SETOR** (ordem do `data/map/station.json`) e **POR AUTOR** (ausentes num grupo
  `NÃO ENCONTRADOS` no fim, para não revelar o autor).
- Logs não encontrados: `???`, setor visível, texto `REGISTRO AUSENTE. CONTINUE PROCURANDO.`
- Contador `LOGS x/y` no cabeçalho (`Balance.LOGS_TOTAL`, coerente com o chassi).
- Voz: se o log tiver `"voice": "res://..."`, reler toca a voz (`AudioManager.play_voice`); sempre
  toca o chiado de fita (`tape_hiss`), como a leitura em jogo.
- Seleção e agrupamento lembrados entre aberturas (variável estática).
- `scripts/core/log_catalog.gd` (`LogCatalog`, lógica pura).

### Não inclui
- Dados de Pesquisa no codex (contam no chassi, no mapa por setor e no epílogo).
- Filtro/busca, marcação de "não lido".
- Voz gravada (nenhum log tem `voice` ainda — a infraestrutura fica pronta).

## 5. Critérios de aceite

- [x] `L` durante o jogo abre o arquivo; `ESC`/`L` fecha e devolve o jogo exatamente como estava.
- [x] Abrir pela pausa também funciona, e fechar volta para a **pausa**, com foco no item.
- [x] **ARQUIVO** na tela inicial abre o arquivo com o que está no backup; sem backup, desabilitado.
- [x] Com o arquivo aberto, o reator **não** cai (`GameState.is_timer_frozen()`; marco de QA).
- [x] Lista por setor na ordem do hub; `[LADOS]` alterna para por autor.
- [x] Logs não encontrados aparecem como `???` e não abrem.
- [x] Abrir um log mostra o texto inteiro, com acentos e rolagem, legível em 384×216.
- [x] Reabrir o arquivo mantém a seleção e o agrupamento.
- [x] Reler não dá `+0,5%` nem conta coleta (teste com o `GameState`).
- [x] O foco não escapa para os botões da pausa (vizinhos explícitos; marco `overlay_owns_focus`).
- [x] `tests/test_log_catalog.gd` verde.
- [x] Portões do `/CLAUDE.md` §6 verdes (validação no Godot 4.7.2, 2026-11-21)
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/log_archive.tscn (+ .gd)   Control em tela cheia, PROCESS_MODE_ALWAYS, sinal closed()
scenes/ui/pause_menu.(tscn|gd)       botão ARQUIVO DE LOGS, ação log_archive, open_archive()
scenes/ui/main_menu.(tscn|gd)        botão ARQUIVO (lê o backup)
scripts/core/log_catalog.gd          LogCatalog (pura)
```
`LogCatalog`: `entries(logs, collected)`, `group_by_sector(entries, sectors)`,
`group_by_author(entries, speakers, unknown_label)`, `flatten`, `index_of`, `ids_for_sector`,
`found_count`, `collected_count`, `author_name`, `author_color`, `collected_from_save(path)`.

Entrada: toda a entrada de teclado do arquivo é tratada em `_input` (antes da GUI), exceto
`[CIMA]/[BAIXO]` na lista, que ficam com a navegação de foco dos botões (vizinhos explícitos em
anel). No leitor, `[CIMA]/[BAIXO]` rolam 16 px.

### Autoloads / sinais do EventBus
- **Não emite** `log_opened`/`log_closed` (ADR-F33-003) e não chama `DialogueManager.open_log`
  nem `GameState.register_pickup` — teste de fonte garante.
- Lê `GameState.collected_ids` (ou o `collected_override` vindo do backup no menu),
  `DialogueManager.logs()`/`speakers()`.
- `AudioManager.play_sfx("ui_confirm" | "ui_move" | "ui_back" | "ui_error" | "tape_hiss")`,
  `play_voice`/`stop_voice`.

### Dados (`data/`)
- `data/ui/log_archive.json` — textos.
- Consome `data/logs/*.json`; campo opcional novo **`voice`** (caminho `res://` do áudio).
- Setor do log (`"sector"`) = `id` ou `level` de um setor do `data/map/station.json` (teste).

### Input actions / camadas de colisão
- `log_archive` (L), `ui_up/down/left/right`, `move_*`, `ui_accept`, `ui_cancel`, `pause`.
  Nenhuma ação nova. Linha `ARQUIVO  L` no painel de controles da pausa.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-FONT](../ASSETS.md#ui-font) | m5x7 16 px | — |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `ui_*`, `tape_hiss` (existentes) | — |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `LogCatalog` + `tests/test_log_catalog.gd`.
- [x] **Passo 2** — `log_archive.tscn/.gd` (lista, ficha, leitor, agrupamento).
- [x] **Passo 3** — `L` em jogo (pausa direta) e item da pausa.
- [x] **Passo 4** — ARQUIVO na tela inicial, lendo o backup.
- [x] **Passo 5** — QA (`tests/qa/f33_*.json`), smoke, docs, commit `feat(F67,F33)`.

## 10. Verificação

- **Testes (`tests/test_log_catalog.gd`):** catálogo = `LOGS_TOTAL` com título/autor/texto; setor de
  todo log existe no mapa; todo autor tem nome no `speakers.json`; coletados marcados; grupos na
  ordem do hub; setor desconhecido vai para o fim; por autor esconde os ausentes; contagem por
  setor; leitura do backup; **reler não muda reator nem coleta**; log ausente não abre; fonte sem
  `open_log`/`register_pickup`/`log_opened`; textos sem glifo ausente e rodapés cabendo (fonte do
  tema); títulos cabem na coluna; pause/menu/smoke apontam para a cena.
- **Smoke:** `res://scenes/ui/log_archive.tscn`.
- **Roteiros godot-qa:** `tests/qa/f33_archive_key.json` (L no Laboratório, setas, por autor,
  leitura com rolagem, foco preso, ESC volta ao jogo) e `tests/qa/f33_archive_pause.json` (pausa →
  ARQUIVO DE LOGS → ESC volta à pausa → retomar).

## 11. ADRs locais

### ADR-F33-001 — Logs não coletados aparecem como `???`
- **Contexto:** mostrar só o coletado esconde o progresso; mostrar tudo entrega a narrativa.
- **Decisão:** todas as entradas aparecem; as não achadas como `???`, com o setor (dica de onde
  procurar), sem autor e sem texto.
- **Data:** 2026-09-19 (revisto em 2026-11-20: `■■■■` virou `???`, a m5x7 não tem `■`)

### ADR-F33-002 — O arquivo não concede bônus de Estabilidade
- **Contexto:** reler poderia virar bomba de reator infinita.
- **Decisão:** o arquivo nunca registra coleta; o +0,5% continua só na primeira leitura em jogo.
- **Data:** 2026-09-19

### ADR-F33-003 — O arquivo tem leitor próprio, não o `DialogueManager`
- **Contexto:** reabrir pelo `DialogueManager.open_log` passaria pela caixa de legenda linha a
  linha, emitiria `log_opened` (gatilhos de narrativa escutam esse sinal) e brigaria com a pausa.
- **Decisão:** o arquivo mostra o texto inteiro num leitor com rolagem, toca `tape_hiss` e a voz
  opcional, e não emite sinal de gameplay.
- **Consequências:** reler é rápido e não tem efeito colateral; o retrato da Helena fica só na
  leitura em jogo.
- **Data:** 2026-11-20

### ADR-F33-004 — `L` é tratado pelo `PauseMenu`
- **Contexto:** o arquivo precisa abrir em qualquer fase sem mexer em `scenes/levels` nem no HUD.
- **Decisão:** o `PauseMenu` (filho do `SceneManager`, sempre presente) escuta `log_archive`, pausa
  a árvore com os painéis escondidos e abre o arquivo no overlay; ao fechar, se a abertura foi
  direta, fecha a pausa junto. Mesmas recusas do `can_pause()` (fala travante, transição, menu).
- **Data:** 2026-11-20

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.8 (tela 5).

### 2026-11-20 — Implementada junto da F67
- **Quem**: agente de UI (worktree) · **O que**: `LogCatalog`, cena do arquivo, `L` pela pausa,
  item na pausa e na tela inicial, campo `voice`, testes e roteiros. Escopo passa de STRETCH a
  FINAL (pedido do jogo completo).
- **Portões / QA:** **não rodados** — todo lançamento do Godot (até `--headless --version`) travou no macOS nesta sessão. Testes, smoke e roteiros (`tests/qa/f67_*`, `f33_*`) estão escritos; os critérios marcados `[x]` são de projeto, não de execução. **Próximo passo:** `tools/gates.sh`, os quatro roteiros de QA e leitura das capturas; só então `[x]` no INDEX.

### 2026-11-21 — Validação com Godot
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: primeira execução com
  o Godot 4.7.2. Os scripts novos não tinham erro de tipagem nem de parse: o import e os
  930 testes passaram de primeira, menos um (abaixo). `tools/gates.sh` completo verde.
- **QA com marcos (todos OK):** `f33_archive_key` (9 marcos; ganhou o marco de nascimento 5,42),
  `f33_archive_pause` (7). Capturas lidas: `02_arquivo_por_setor` (LOGS 5/8, grupos Núcleo
  Central/Estufa/Laboratório com `???`, ficha à direita com autor em âmbar), `04_por_autor`
  (Dra. Helena Vasquez + NÃO ENCONTRADOS), `05_lendo` (texto inteiro, acentos, rolagem; a última
  linha visível corta na borda da área de rolagem, como esperado). Fonte só em 16 px.

### 2026-11-21 — Correção da revisão da campanha (grupo A)
- **Dica de leitura com o glifo do dispositivo**: `read_hint` virou `"%s LER"` e o arquivo põe
  `[ENTER]` ou `[A]` conforme o último aperto (`InteractionRules.note_device`, o mesmo rastreio do
  prompt de interação). QA `f33_archive_key` 9/9 (`[ENTER] LER`).
- **Erro do motor com `L` durante o ARGOS**: `ERROR: Condition "p_elem->_root" is true
  (self_list.h:46)` 2× a partir do 3º abre/fecha do arquivo pelo `L` no Reator. Isolado por
  bisseção de roteiros: só o caminho direto (que despausava em `close.call_deferred()`) dava; pela
  pausa, nunca. O `PauseMenu` agora fecha o arquivo direto na hora. `review_campaign_telas_reator`
  21/21 sem nenhum `ERROR`. Lição no `godot-pitfalls`.
