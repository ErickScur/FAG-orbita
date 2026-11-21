---
id: F68
title: Status restantes (DESCARGA e SOBRECARGA) e leitura de status
status: done
scope: final
block: 6
priority: P1
rubric: ["Efeitos naturais", "Efeitos visuais/sonoros"]
depends_on: ["F23", "F31", "F44", "F60", "F61", "F62"]
unblocks: ["F64", "F65"]
estimate: 4h
last_updated: 2026-11-21
---

# F68 — Status restantes (DESCARGA e SOBRECARGA) e leitura de status

## 1. Contexto e objetivo

Fecha o catálogo de efeitos de status do [GDD-2.6.2-F](../design/GDD.md#gdd-2-6-2-f). CORROSÃO
(F23), SUPERAQUECIMENTO (F60) e CONGELAMENTO (F61) já existiam; a DESCARGA só tinha uma fonte
(pulso da CX-2) e nenhum retorno quando o jogador tentava usar a habilidade bloqueada, e a
SOBRECARGA estava definida no `StatusEffects` mas ninguém a aplicava. Esta feature dá fonte,
regra e leitura aos dois e mostra o significado de cada status no Terminal do Chassi sem a HUD
crescer. Junto vem o piso eletrificado (F32), a fonte elétrica contínua que as fases finais
(Núcleo de Memória e Núcleo do Reator) vão usar.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.2-F — Efeitos de status](../design/GDD.md#gdd-2-6-2-f) ·
  [GDD-2.6.2-E — Obstáculos ambientais](../design/GDD.md#gdd-2-6-2-e) ·
  [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud)
- **Parâmetros:** `Balance.DISCHARGE_TIME` (3), `Balance.OVERLOAD_TIME` (10),
  `Balance.OVERLOAD_SPEED_MULT` (1,3), `Balance.OVERLOAD_MIN_RECHARGE` (10, novo, AJ-057),
  `Balance.ELECTRIC_FLOOR_DPS` (8), `Balance.CHARGE_DOCK_REGEN` (5) —
  [GDD-P](../design/GDD.md#gdd-p)
- **Ajustes:** [AJ-040](../design/GDD.md#gdd-ajustes) (DESCARGA nas garras),
  AJ-057 (gatilho da SOBRECARGA), AJ-058 (piso, fontes elétricas, legenda no Terminal do Chassi)
- **Features vizinhas:** [F23](F23-esporos-status.md) (framework), [F32](F32-obstaculos-ambientais.md)
  (piso e vapor), [F37](F37-legibilidade-hud.md)/[F44](F44-terminal-do-chassi.md) (HUD não cresce),
  [F60](F60-fase-laboratorio.md) (CX-2, vapor), [F62](F62-fase-docas.md) (Propulsor)

## 3. Critério de avaliação atendido

**Efeitos naturais** e **Efeitos visuais/sonoros** ([rubrica](../ENTREGAS.md#rubrica)): os cinco
status do GDD existem com fonte, ícone e contador no HUD. Na apresentação: pisar no piso
energizado (faísca, ícone de raio, dash recusado com faísca e zumbido), desligar o piso no
Terminal (fica apagado e inerte) e encher a Carga numa doca (rastro claro, MU-7 mais rápido, ícone
de seta com 10 s).

## 4. Escopo

### Inclui
- **DESCARGA**: fontes elétricas = piso eletrificado (renova enquanto pisa) e pulso da CX-2.
  Bloqueia dash, feixe, pulo duplo/propulsor (GDD) e as garras (AJ-040) por 3 s. Ao começar: faísca
  e zumbido; enquanto dura: faíscas intermitentes no MU-7; tentar dash/feixe/pulo duplo/propulsor:
  faísca + `electric_buzz` (limitado a um a cada 0,3 s), sem texto.
- **SOBRECARGA**: a doca aplica ao **completar** a recarga, uma vez por encaixe, se aquele
  encaixe devolveu pelo menos 10 de Carga (AJ-057). +30% na velocidade de andar por 10 s, rastro
  claro e brilho pulsante no MU-7, pulso de luz e `power_on` na doca.
- Lógica pura `scripts/core/overload_rule.gd` (`OverloadRule`) com testes.
- `DamageArea.notify_status()` passa a aplicar pelo `GameState.apply_status` (antes só emitia o
  sinal e o estado do jogo não sabia do status) e o MU-7 notifica também fontes de dano contínuo.
- Terminal do Chassi: com status ativo, o bloco ESTAÇÃO ARTEMIS dá lugar à lista de status
  (ícone, nome · efeito, segundos), até 2 linhas, sem a tela crescer (ADR-F68-002).
- HUD: nada novo. Os ícones de status com contador já existiam na linha de status da F23/F51
  (`hud_sheet.png` quadros 5–9, até 4 ícones); confirmado no QA com DESCARGA e SOBRECARGA juntas.

### Não inclui
- Arte nova de ícone (os ícones de raio e seta da F51 servem).
- SFX definitivos (`electric_buzz` e `steam_hiss` seguem placeholder, F52).
- Pôr o piso nas fases reais: é das F64/F65 (seção 6, "Como as fases usam").

## 5. Critérios de aceite

- [x] Pisar no piso energizado aplica DESCARGA e tira 8 de Integridade/s (QA: 92 depois de 1 s)
- [x] Com DESCARGA o dash não sai; aparece faísca e toca o zumbido (QA `dash_nao_sai`)
- [x] DESCARGA vence 3 s depois de sair da fonte; dash volta (QA `dash_volta`)
- [x] Recarregar até 100% na doca dá SOBRECARGA uma vez; parado em 100% não renova (testes)
- [x] Com SOBRECARGA o MU-7 anda 9 tiles em 60 quadros contra 7 sem ela (QA)
- [x] Ícones de DESCARGA e SOBRECARGA com contador no HUD, juntos, sem crescer a HUD
- [x] Terminal do Chassi lista o significado de cada status ativo
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
- `scripts/core/overload_rule.gd` — `OverloadRule.begin()` abre um encaixe; `feed(antes, depois,
  máximo) -> bool` soma a Carga devolvida e devolve `true` uma única vez, quando cruza o máximo
  com `OVERLOAD_MIN_RECHARGE` acumulado; `reaches_full()` estático.
- `scenes/world/backup_dock.gd` — `_recharge()` passa cada passo de recarga pela regra; ao
  disparar: `GameState.apply_status(OVERLOAD)`, `power_on`, pulso de luz. Encaixe novo a cada
  `body_entered` do MU-7.
- `scenes/player/mu7.gd` — `_refuse(discharged)`, `_spark()`, `_update_status_fx()`,
  `_update_overload_fx()`, `is_discharged()`, `is_overloaded()`; rastro `OverloadTrail`
  (`CPUParticles2D` sem luz) criado em `_setup_status_fx()`. A velocidade já vinha do
  `StatusEffects.speed_multiplier()` (F61).
- `scenes/world/damage_area.gd` — `notify_status()` pelo `GameState`.
- `scenes/ui/chassis_menu.*` + `data/ui/chassis_menu.json` (`status_<id>`, `status_seconds`).

### Autoloads / sinais do EventBus
- Usa `GameState.apply_status`, `GameState.statuses`, `status_applied`/`status_cleared` (já
  existentes). Nenhum sinal novo.

### Dados (`data/`)
- `data/ui/chassis_menu.json`: `status_corrosion`, `status_overheat`, `status_freeze`,
  `status_discharge`, `status_overload`, `status_seconds`.
- Bancada de teste: `data/levels/hazard_test.*`, `data/energy/hazard_test.json`,
  `scenes/dev/hazard_test.tscn` (piso ligado à GRADE DO PISO, vapor, doca, console).

### Como as fases usam o piso eletrificado (F64/F65)
1. No `.txt` da fase, troque os `#` do **chão** por `z` (uma letra por tile; o tile embaixo
   continua sólido para o autotile, a sombra e a alcançabilidade).
2. No `.json` da fase, cada `z` recebe o vínculo com o sistema que o energiza:
   `"x,y": { "id": "mem_floor_a", "terminal_id": "memory", "system_id": "floor_grid" }`
   (ids com o prefixo da fase; o `system_id` precisa existir no `data/energy/<terminal>.json`).
   Para o piso responder a efeito de grupo em vez de vínculo direto, use `"group": "<grupo>"` e
   `"system_id": ""` (godot-pitfalls, Energia).
3. Opcional: `"powered": false` faz a placa nascer desligada antes do Terminal aplicar o estado.
4. A luz é fundida a cada 4 placas seguidas (`ElectricFloor.GLOW_SEGMENT_TILES`) e entra na conta
   do `test_light_crowding` sozinha.

## 7. Assets necessários

| Asset id | Uso | Status |
|---|---|---|
| [SPR-ELECTRIC-FLOOR](../ASSETS.md#spr-electric-floor) | Placa do piso eletrificado, 4 quadros ligados + 4 apagados | integrado (Codex) |
| [UI-HUD](../ASSETS.md#ui-hud) | Ícones 8 (DESCARGA) e 9 (SOBRECARGA) | já existia |
| SFX `electric_buzz`, `steam_hiss`, `power_on` | Zumbido da DESCARGA, aviso do vapor, SOBRECARGA | placeholder (F52) |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] AJ-057/AJ-058 e `OVERLOAD_MIN_RECHARGE` no GDD-P antes do `Balance`
- [x] `OverloadRule` + testes; gatilho na doca
- [x] Retorno da DESCARGA e leitura da SOBRECARGA no MU-7
- [x] Piso eletrificado (F32) e letra `z`
- [x] Legenda de status no Terminal do Chassi
- [x] Bancada `hazard_test`, QA com marcos, portões

## 10. Verificação

- **Testes:** `tests/test_overload_rule.gd` (13: dispara uma vez, parado em 100% não dispara,
  dreno da lanterna não conta, mínimo inclusivo, encaixe novo, corrosão, Carga máxima maior,
  +30%, DESCARGA bloqueia dash/feixe/propulsor por 3 s, renovação no piso) ·
  `tests/test_electric_floor.gd` (11: dano/status do piso, sólido, desligado inerte e escuro,
  Terminal liga/desliga, `notify_status` pelo `GameState`, luz fundida por trecho, letra `z`
  sólida para tiles e alcançabilidade, bancada, legenda do Chassi, ícones distintos).
- **Smoke:** `scenes/world/electric_floor.tscn`, `scenes/dev/hazard_test.tscn`.
- **QA** `tests/qa/f68_hazards.json` (gerado por `tests/qa/gen/f68_hazards.py`, 18 marcos, 2
  rodadas iguais) e `tests/qa/f68_chassi_status.json` (2 marcos). Ver log de 2026-11-21.

## 11. ADRs locais

### ADR-F68-001 — SOBRECARGA: uma vez por encaixe, com mínimo de recarga
- **Contexto:** "Recarga total" sem mais regra vira buff infinito: a lanterna acesa na doca drena
  1/60 por quadro e a doca devolve no mesmo quadro, "completando" a recarga 60 vezes por segundo.
- **Decisão:** `OverloadRule` por encaixe (entrar na zona da doca abre um), dispara uma vez ao
  cruzar o máximo e só se o encaixe devolveu `OVERLOAD_MIN_RECHARGE` = 10 de Carga (2 s de doca).
  Célula de energia não dá SOBRECARGA. Registrado como AJ-057.
- **Consequências:** o buff é uma recompensa por voltar à doca com a Carga gasta, e dura o
  suficiente para atravessar o trecho seguinte. Explorar exige sair e voltar e gastar 10 de Carga.
- **Data:** 2026-11-21

### ADR-F68-002 — Legenda de status no Terminal do Chassi sem a tela crescer
- **Contexto:** o painel do Chassi já ocupa ~210 dos 216 px com 6 habilidades; uma seção nova
  estouraria a tela (e a HUD não pode crescer, F37/F44).
- **Decisão:** com status ativo, o bloco ESTAÇÃO ARTEMIS (título + mapa/setores, 2 linhas) dá lugar
  à lista de status, até 2 linhas (ícone, `NOME · EFEITO`, segundos). Sem status, volta o bloco. O
  mapa e os setores continuam na página do mapa (`[TAB]` de novo). Registrado em AJ-058.
- **Consequências:** altura constante; um terceiro status simultâneo aparece só na HUD.
- **Data:** 2026-11-21

### ADR-F68-003 — Fontes de DESCARGA: piso e CX-2; o vapor não
- **Contexto:** o pedido deixava em aberto se o jato de vapor também descarrega.
- **Decisão:** não. O vapor é calor (20 de dano, empurrão); DESCARGA fica com o que é elétrico: o
  piso eletrificado (renova enquanto pisa) e o pulso da CX-2 (3 s). AJ-058.
- **Consequências:** cada obstáculo pede uma resposta diferente: vapor se lê pelo ritmo (ou se
  atravessa de dash), piso se desliga no Terminal ou se pula.
- **Data:** 2026-11-21

### ADR-F68-004 — Retorno de habilidade recusada: faísca e zumbido, sem texto
- **Decisão:** dash, feixe, pulo duplo e propulsor recusados por DESCARGA soltam a faísca do
  `spark_burst` (sem luz, ciano claro) e `electric_buzz`, no máximo a cada 0,3 s; sem Carga
  continua o `ui_error` de antes. O início da DESCARGA também solta faísca e zumbido, e enquanto
  ela dura o MU-7 solta faíscas a cada 0,45 s. As constantes de ritmo são visuais e moram no
  `mu7.gd`.
- **Data:** 2026-11-21

## 12. Log de evolução

### 2026-11-21 — Feature criada e entregue
- **Quem**: agente de sistemas (rodada "jogo completo") · **O que**: estudo mostrou que DESCARGA e
  SOBRECARGA já estavam definidas no `StatusEffects` (F23), a DESCARGA já bloqueava dash, feixe,
  garras e propulsor (F31/F60/F62) e a HUD já tinha os ícones; faltavam a fonte da SOBRECARGA, o
  retorno ao tentar usar habilidade bloqueada, a leitura no MU-7, a legenda no Chassi e o piso
  eletrificado. Achado: `DamageArea.notify_status()` só emitia o sinal (o `GameState` não ficava
  com o status); corrigido.
- **QA** `f68_hazards` (2 rodadas, 18/18 marcos): base 60 quadros 1→8; SOBRECARGA ausente em 400 e
  presente em 440 (recarga de 15 a 5/s); com ela 1→10 em 60 quadros; no piso (21,10) DESCARGA
  ativa, dash não sai, Integridade 100→92 em 60 quadros; Terminal desliga a GRADE DO PISO; de volta
  no piso por 3,6 s, Integridade 100 e sem DESCARGA; dash volta. `f68_chassi_status` (2/2): HUD com
  raio 30 e seta 30 lado a lado; Chassi com as 6 habilidades + 2 linhas de status no lugar de
  ESTAÇÃO ARTEMIS, mesma altura; sem status o bloco volta.
- **Próximo passo**: F64/F65 colocam `z` nas fases (seção 6).
