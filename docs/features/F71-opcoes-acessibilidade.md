---
id: F71
title: Remapeamento de teclas & acessibilidade
status: done
scope: final
block: 6
priority: P1
rubric: []
depends_on: ["F08", "F09", "F36"]
unblocks: []
estimate: 3h
last_updated: 2026-11-21
---

# F71 — Remapeamento de teclas & acessibilidade

## 1. Contexto e objetivo

A tela de Opções do [GDD-2.8](../design/GDD.md#gdd-2-8-telas) pede volume, **remapeamento de
teclas**, **tamanho de legenda**, **modo daltônico** e o modo sem timer. A F08 entregou volume,
dificuldade, modo sem timer e tela cheia; esta feature completa o resto. Ela não vale item da
rubrica, mas fecha a tela como o GDD a descreve e deixa o jogo jogável por quem não usa WASD,
lê mal fonte pequena ou não separa verde de vermelho.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 Telas (2 — Opções)](../design/GDD.md#gdd-2-8-telas) · [GDD-2.4 Controles](../design/GDD.md#gdd-2-4)
- **Ajuste:** [AJ-060](../design/GDD.md#gdd-ajustes)
- **Parâmetros:** nenhum número de jogo novo (tamanhos de fonte 16/32 são a grade da m5x7)
- **ADRs:** [ADR-010](../DECISIONS.md#adr-010) (Input Map no `project.godot`)
- **Features vizinhas:** [F08](F08-opcoes-dificuldade.md) (tela de Opções), [F09](F09-pause-recomecar.md) (pausa abre Opções), [F36](F36-tutorial-briefing.md) (cartões de tecla), [F19](F19-dialogo-logs.md) (caixa de diálogo)

## 3. Critério de avaliação atendido

Nenhum item novo da rubrica. Na apresentação: abrir OPÇÕES na pausa, descer até CONTROLES,
trocar PULAR para `K`, voltar ao jogo e pular com `K`; ligar MODO DALTÔNICO e mostrar o LED das
placas da ala trocando de verde/vermelho para azul/laranja.

## 4. Escopo

### Inclui
- Tela de Opções com rolagem (seções ÁUDIO, JOGO, ACESSIBILIDADE, CONTROLES) e foco preso nela.
- **CONTROLES**: tecla principal das 12 ações (`move_*`, `jump`, `dash`, `interact`, `beam`,
  `flashlight`, `map`, `log_archive`, `pause`); conflito troca as duas teclas e avisa; setas
  são fixas (segunda tecla do movimento) e recusadas; `RESTAURAR PADRÕES`; `[ESC]` cancela a
  captura (exceto quando a ação é a própria PAUSA).
- Persistência em `user://settings.cfg` (`[controls]` só com as teclas que diferem do padrão,
  `[accessibility]` com `subtitle_size` e `colorblind`).
- **LEGENDA** NORMAL (16) / GRANDE (32) na caixa de diálogo (fala e log).
- **MODO DALTÔNICO**: paleta central `Accessibility.PALETTE` aplicada no LED da placa de setor,
  mensagens/meta/lâmpadas do Terminal de Distribuição, célula de integridade perdida e reator
  crítico.
- Cartões de tecla e prompt `[E] ...` leem a tecla atual do Input Map.
- QACapture ganha o evento `key` (tecla física injetada) e o `Settings` não grava o
  `settings.cfg` real durante QA.

### Não inclui
- Remapear o controle (fica no padrão; a tela diz isso).
- Rodapés com tecla escrita nas telas do Mapa (`station_map`) e do Arquivo (`log_archive`) e o
  `[ESPAÇO]/[ESC]` do briefing: continuam com o texto padrão (arquivos de outras features; ver
  pendências no log).

## 5. Critérios de aceite

- [x] Trocar PULAR para `K` na tela de Opções faz o MU-7 pular com `K` e não com `ESPAÇO`.
- [x] Escolher a tecla de outra ação troca as duas e mostra `[E] era de INTERAGIR: as duas trocaram`.
- [x] Seta é recusada: `[CIMA] é fixa de SUBIR / ESCALAR`.
- [x] `RESTAURAR PADRÕES` volta ao Input Map do projeto; reabrir o jogo aplica o que foi salvo.
- [x] Cartão de tecla mostra `[K] PULAR` depois do remapeamento; prompt de interação segue a tecla.
- [x] LEGENDA GRANDE mostra fala e log em 32 px; NORMAL em 16 (nunca 8/12/24).
- [x] MODO DALTÔNICO troca o LED das placas na hora (redesenho por `Settings.accessibility_changed`).
- [x] A paleta daltônica separa todos os pares de sinal sob simulação de deuteranopia e protanopia
  (distância ≥ 0,5; a normal chega a 0,31).
- [x] Opções abre do menu principal e da pausa; foco por teclado/controle não escapa (lista
  circular de 23 controles).
- [x] Portões do `/CLAUDE.md` §6 verdes (exceto `test_each_sealed_door_really_guards_its_exit`,
  que já falhava na base `final/integracao`)
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/key_bindings.gd   KeyBindings: layout {ação: {primary, fixed}}, assign (troca /
                               reserva / inválida), overrides ↔ arquivo, sanitize, read/write do
                               InputMap (preserva eventos de controle), key_label, relabel
scripts/core/accessibility.gd  Accessibility: tamanhos de legenda, PALETTE por papel (normal,
                               daltônico), simulação deutan/protan, weakest_contrast
autoload/settings.gd           + subtitle_size, colorblind, key_overrides; apply_bindings(),
                               rebind(), restore_default_bindings(), signal_color(),
                               subtitle_font_size(); sinais accessibility_changed, bindings_changed
scenes/ui/options_menu.tscn/gd ScrollContainer (follow_focus) + linhas de tecla geradas por código
scenes/ui/dialogue_box.gd      fonte da fala = Settings.subtitle_font_size()
scenes/ui/tutorial_card.gd     KeyBindings.relabel(tecla do cartão, ações do cartão)
scripts/core/interaction_rules.gd  glyph(false) = tecla atual de interact
scenes/world/sector_plate.gd, scenes/ui/energy_terminal_ui.gd, scenes/ui/hud.gd
                               cores de sinal via Settings.signal_color(papel)
autoload/qa_capture.gd         evento {"key": "K", "pressed": true}
```

### Autoloads / sinais
- `Settings.accessibility_changed()` e `Settings.bindings_changed()` (sinais do próprio autoload,
  não do EventBus: só a UI escuta).

### Dados (`data/`)
- `data/ui/options.json`: rótulos das seções, nomes das 12 ações em pt-BR e mensagens.

### Input actions
- Nenhuma ação nova. O remapeamento troca o **primeiro** `InputEventKey` de cada ação; as setas
  (segundo evento de `move_*`) e os eventos de controle ficam.

## 7. Assets necessários

Nenhum.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `KeyBindings` + `Accessibility` com testes.
- [x] **Passo 2** — `Settings` (campos, persistência, aplicar no boot).
- [x] **Passo 3** — Tela de Opções com rolagem e captura de tecla.
- [x] **Passo 4** — Consumidores: diálogo, cartão, prompt, placa, terminal, HUD.
- [x] **Passo 5** — QA com marcos e portões.

## 10. Verificação

- **Testes:** `tests/test_key_bindings.gd` (13) e `tests/test_accessibility.gd` (9) —
  arquivo próprio `user://test_accessibility_settings.cfg`; o Input Map é restaurado depois de
  cada caso.
- **Smoke:** `options_menu.tscn` já estava em `tests/scenes.txt`.
- **Roteiros godot-qa** (gerados por `tests/qa/gen/f71.py`):
  - `f71_remap_pulo.json` — Opções → 13× baixo → PULAR → `K`; conflito com `E`; seta recusada;
    volta para `K`; cena da Estufa: `ESPAÇO` não pula, `K` pula, cartão mostra `[K] PULAR`.
    16 marcos.
  - `f71_legenda_daltonico.json` — LEGENDA GRANDE e MODO DALTÔNICO pela tela; log da Estufa
    aberto em 32 px.
  - `f71_placas_daltonico.json` — ala do hub com a Estufa religada; LED verde/vermelho vira
    azul/laranja ao ligar o modo.
- **Playtest humano:** remapear algo e jogar a Estufa; ver se a legenda grande cabe nos logs
  mais longos (103 caracteres) sem cobrir a cena demais.

## 11. ADRs locais

### ADR-F71-001 — Conflito troca, seta é reservada
- **Contexto:** "detecção de conflito" pode recusar ou trocar. Recusar deixa o jogador sem saída
  quando quer mover uma tecla já usada; aceitar sem trocar deixa ação sem tecla ou duas ações na
  mesma tecla.
- **Decisão:** tecla de outra ação → as duas trocam, com aviso. Seta (fixa) → recusada, com aviso.
- **Consequências:** nunca há ação sem tecla nem tecla com duas ações; as setas garantem
  navegação e movimento mesmo depois de um remapeamento ruim.
- **Data:** 2026-11-21

### ADR-F71-002 — Arquivo guarda só a diferença do padrão
- **Contexto:** gravar o mapa inteiro congelaria o padrão de hoje no arquivo do jogador.
- **Decisão:** `[controls]` guarda só `ação = keycode físico` das teclas trocadas; ao abrir, o
  `Settings` aplica sobre o Input Map do projeto, passando cada uma pelo mesmo `assign` (arquivo
  editado à mão com duas ações na mesma tecla vira troca, não duplicata).
- **Consequências:** mudar uma tecla padrão no `project.godot` chega a quem nunca remapeou.
- **Data:** 2026-11-21

### ADR-F71-003 — Paleta daltônica no eixo azul/laranja, por papel
- **Contexto:** as cores que carregam significado estavam espalhadas em constantes por cena; o
  par que mais importa (LED religado × pendente) é verde × vermelho.
- **Decisão:** `Accessibility.PALETTE` com um par (normal, daltônico) por **papel** de sinal; as
  cenas pedem `Settings.signal_color(papel)`. A versão daltônica usa azul/laranja/amarelo
  (Okabe-Ito). Teste mede a distância sob simulação de deuteranopia e protanopia (Viénot).
- **Consequências:** cor de sinal nova entra como papel na paleta; o teste já cobra contraste.
- **Data:** 2026-11-21

### ADR-F71-004 — QA nunca grava o `settings.cfg` do humano
- **Contexto:** fechar Opções salva; o roteiro de QA remapeia teclas e mexe em dificuldade, e o
  `settings.cfg` é o mesmo do humano (e das outras worktrees).
- **Decisão:** `Settings.save_settings()` no caminho padrão não grava quando há `--qa`.
- **Consequências:** roteiros podem fechar Opções à vontade; testes usam caminho próprio.
- **Data:** 2026-11-21

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-11-21 — Feature criada e implementada
- **Quem**: agente de features (F34+F71) · **O que**: tudo da seção 4.
- **QA**: `f71_remap_pulo` 16 marcos OK (`04_pulo_em_k`, `05_conflito_trocou`,
  `06_seta_reservada`, `08_cartao_mostra_k`, `09_pulou_com_k`); `f71_legenda_daltonico` OK
  (`03_log_com_legenda_grande`: log da Helena em 32 px, 3 linhas por quadro); `f71_placas_daltonico`
  OK (LED da Estufa verde → azul, dos setores pendentes vermelho → laranja).
- **Pendências**: rodapés com tecla escrita no Mapa (`data/ui/station_map.json`), no Arquivo
  (`data/ui/log_archive.json`), no Terminal do Chassi (`[TAB] MAPA [ESC] FECHAR`), no briefing e
  em `chassis_lost` ainda mostram a tecla padrão; basta passar o texto por
  `KeyBindings.relabel(texto, [ações])` em cada tela. Remapear controle fica para depois.
