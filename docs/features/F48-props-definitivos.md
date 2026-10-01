---
id: F48
title: Props definitivos — terminais, porta, planta, objetos e plataforma
status: in-progress
scope: demo
block: 8
priority: P1
rubric: ["Arte coerente", "Cenário e ambientação"]
depends_on: ["F17", "F19", "F25", "F28", "F29"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F48 — Props definitivos (SPR-TERMINAL, SPR-DOOR, SPR-PLANT, SPR-PROPS, SPR-PLATFORM)

## 1. Contexto e objetivo

Cinco folhas de arte definitiva substituem os placeholders do mundo: os dois terminais
(distribuição e registros), a porta de energia, a planta que cresce, os seis objetos do
cotidiano interrompido e a plataforma móvel. Servem ao pilar de ambientação
("uma estação bonita que ninguém está usando") e ao momento narrativo do **primeiro corpo**
— o traje vazio do tripulante no Setor Habitacional.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 paleta](../design/GDD.md#gdd-2-9-paleta)
- **Jornada:** o traje caído é a primeira prova física de que a tripulação morreu
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (nearest, 384×216), [ADR-005](../DECISIONS.md#adr-005) (placeholder → definitivo em uma linha)
- **Assets:** `SPR-TERMINAL`, `SPR-DOOR`, `SPR-PLANT`, `SPR-PROPS`, `SPR-PLATFORM` no [`ASSETS.md`](../ASSETS.md)

## 3. Critério de avaliação atendido

Arte coerente e cenário legível na apresentação: o avaliador vê terminais com estado visual
(desligado / ligado / em uso), porta que abre, planta que cresce em seis estágios e vira
plataforma, objetos do cotidiano espalhados e a plataforma de carga levando o MU-7.

## 4. Escopo

### Inclui
- Fatiamento das cinco folhas para os contratos do `ASSETS.md`.
- Ajuste das cenas/scripts que consomem cada folha.
- `LogObject` passa a honrar o parâmetro `style` da legenda ASCII (`terminal` vs `prop`).

### Não inclui
- `SPR-DOCK` (doca de backup) — segue placeholder.
- `docs/ASSETS.md` (fichas atualizadas por outro agente).
- Correção do `frame` do traje em `data/levels/core_hub.json` (arquivo de outro agente).

## 5. Critérios de aceite

- [x] Cinco PNG definitivos em `assets/sprites/world/` e `assets/sprites/props/`.
- [x] Contagem de quadros do fatiador conferida contra o contrato de cada ficha.
- [x] Nitidez (pixels semitransparentes) igual ou melhor que a referência do MU-7 (~23%).
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/distribution_terminal.gd   colunas 0/1/2 de terminal_sheet (32x32)
scenes/world/log_object.gd              style=terminal -> colunas 3/4 de terminal_sheet
                                        style=prop     -> coluna N de props_sheet
scenes/world/door.gd                    FRAME_SIZE 32x48, 5 quadros, selada = quadro 0 + tinta
scenes/world/grow_plant.gd              FRAME_SIZE 64x64, 6 quadros
scenes/world/moving_platform.gd         moving_platform.png 48x8
tests/qa/scenes/props_probe.gd          sonda de QA (fase + spawn + energia + overrides)
```

### Dados (`data/`)
Nenhum arquivo de dados alterado. O `style` já vinha da `LEGEND` do `LevelBuilder`
(`L` → `terminal`, `o` → `prop`) e era silenciosamente ignorado.

## 7. Assets necessários

| Asset id | Uso nesta feature | Situação |
|---|---|---|
| SPR-TERMINAL | terminal de distribuição (3f) + terminal de registros (2f) | definitivo, 160×32 |
| SPR-DOOR | porta de energia | definitivo, 160×48 (**5 quadros de 32×48**, contrato revisto) |
| SPR-PLANT | planta que cresce | definitivo, 384×64 (**6 quadros de 64×64**, contrato revisto) |
| SPR-PROPS | seis objetos do cotidiano | definitivo, 192×32 |
| SPR-PLATFORM | plataforma móvel | definitivo, 48×8 (Kenney *Pixel Platformer: Industrial Expansion*, CC0) |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — medir as folhas cruas e conferir layout contra o contrato.
- [x] **Passo 2** — fatiar com `tools/autoslice_sheet.gd` (`--fit=contain` onde a proporção não casa).
- [x] **Passo 3** — montar a plataforma a partir do tilesheet CC0 da Kenney.
- [x] **Passo 4** — ajustar scripts consumidores.
- [x] **Passo 5** — portões §6 e QA visual por sonda.

## 10. Verificação

- **Testes:** suíte completa (`tests/run_tests.gd`), 649 verdes.
- **Smoke:** `tools/smoke.sh`, 75 cenas, zero erro.
- **Roteiros godot-qa:** `tests/qa/f48_log.json`, `f48_console.json`, `f48_hab.json`,
  `f48_sealed.json`, `f48_lift.json`, `f48_planta.json`, sobre as sondas
  `tests/qa/scenes/f48_probe_*.tscn`.

## 11. ADRs locais

### ADR-F48-001 — Porta com 5 quadros de 32×48 e variante selada por tinta
- **Contexto:** a folha entregue traz 5 quadros (painel escuro → campo de energia aceso) e
  nenhuma variante com cadeado vermelho. O desenho tem proporção ~0,6 (largura/altura);
  forçá-lo em 16×48 deixaria a porta com 27 px de altura dentro de um quadro de 48.
- **Decisão:** quadro de **32×48** (a arte fica 28×48, cabe inteira) mantendo a colisão em
  16×48 (uma coluna de tile). `closed`=0, `opening`=1..3, `open`=4, `sealed`=quadro 0 com
  `modulate` vermelho.
- **Consequências:** o sprite transborda 8 px para cada lado da coluna de tile; em todas as
  fases o `|` fica em corredor aberto, então lê como batente. A porta selada fica vermelha
  inteira em vez de ter um cadeado.
- **Data:** 2026-09-20

### ADR-F48-002 — Planta em quadro de 64×64
- **Contexto:** a copa adulta é mais larga que alta em relação ao contrato (413×451 px na
  folha crua). Em 32×64 a copa seria cortada em 10 px de cada lado; com `--fit=contain` a
  planta encolheria para 35 px de altura e a colisão do topo (y=-62) ficaria no vazio.
- **Decisão:** quadro de **64×64**, `--fit=height`. A planta fica 59×64, a colisão do topo
  continua 32 px de largura em y=-62.
- **Consequências:** o MU-7 pisa no meio da copa; as folhas passam ~13 px para cada lado da
  área pisável. Nenhum número de gameplay mudou.
- **Data:** 2026-09-20

### ADR-F48-003 — `LogObject.style` passa a existir
- **Contexto:** a `LEGEND` do `LevelBuilder` mandava `style: "terminal"` para o símbolo `L`
  e `style: "prop"` para `o`, mas `LogObject` não tinha essa propriedade. Resultado: o
  "terminal de registros" do Núcleo desenhava a **coluna 0 da folha de props** — com a arte
  definitiva, uma caneca de café.
- **Decisão:** `LogObject` ganha `style`; `terminal` usa as colunas 3/4 da `terminal_sheet`
  (tela apagada / tela verde depois de lido), `prop` mantém a folha de props.
- **Consequências:** os dois quadros de terminal de registro da SPR-TERMINAL, que nunca
  chegavam à tela, passam a ser usados. `scenes/world/terminal.gd` continua órfão.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Arte definitiva integrada
- **Quem**: agente PROPS · **O que**: cinco folhas fatiadas e integradas, contratos de
  SPR-DOOR e SPR-PLANT revistos, `LogObject.style` implementado, seis sondas e seis
  roteiros de QA novos · **Próximo passo**: corrigir `frame` do traje em
  `data/levels/core_hub.json` (1 → 3) e atualizar as fichas do `ASSETS.md`.
