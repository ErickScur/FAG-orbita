<!--
TEMPLATE CANÔNICO DE FEATURE — ÓRBITA
Copie para `features/F<id>-<slug>.md`. Mantenha TODAS as seções (vazias com "—" ou "N/A").
A seção 2 (Referências de design) é OBRIGATÓRIA e nunca fica vazia: toda feature nasce do GDD/Jornada.
-->

---
id: F00
title: <Nome humano da feature>
status: not-started   # not-started | in-progress | done | blocked | skipped
scope: demo           # demo | stretch | final
block: 0              # bloco do INDEX.md
priority: P0          # P0 (crítico para a entrega) | P1 (importante) | P2 (nice-to-have)
rubric: []            # itens da rubrica que esta feature atende (nomes exatos de ENTREGAS.md)
depends_on: []        # ["F01","F02"] — precisam estar [x] antes
unblocks: []
estimate: 1h          # esforço estimado para um agente
last_updated: 2026-09-19
---

# F00 — <Nome humano da feature>

## 1. Contexto e objetivo

> 1-3 parágrafos. Que necessidade do jogo resolve? Qual pilar ([GDD pilares](../design/GDD.md#gdd-pilares)) serve? Onde aparece para o jogador?

## 2. Referências de design (ler ANTES de codar)

> Links para as âncoras exatas. O GDD é a fonte da verdade de regras e números; a Jornada, do tom e dos textos.

- **GDD:** [GDD-x.y — …](../design/GDD.md#gdd-x-y)
- **Parâmetros:** `Balance.X`, `Balance.Y` ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa N — …](../design/JORNADA-DO-HEROI.md#jh-n) (se aplicável)
- **ADRs:** [ADR-00X](../DECISIONS.md#adr-00x)

## 3. Critério de avaliação atendido

> Quais itens da rubrica ([ENTREGAS.md](../ENTREGAS.md#rubrica)) esta feature entrega e **como o avaliador vai ver isso** durante a apresentação.

## 4. Escopo

### Inclui
- …

### Não inclui
- …

## 5. Critérios de aceite

- [ ] … (verificáveis: o que o jogador vê/faz e o que o teste confere)
- [ ] Portões do `/CLAUDE.md` §6 verdes
- [ ] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/…/x.tscn (+ x.gd)
scripts/core/…
```

### Autoloads / sinais do EventBus
- …

### Dados (`data/`)
- …

### Input actions / camadas de colisão
- …

## 7. Assets necessários

> Ids do [`ASSETS.md`](../ASSETS.md). Todo asset tem placeholder até o definitivo chegar.

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| … | … | … |

## 8. 🧑 Ação humana

> Formato em [`EDITOR-GUIDE.md`](../EDITOR-GUIDE.md#formato-acao-humana). Se nada exige o editor, escreva **"Nenhuma."**

Nenhuma.

## 9. Plano de execução

- [ ] **Passo 1** — …
- [ ] **Passo 2** — …

## 10. Verificação

- **Testes (`tests/test_*.gd`):** …
- **Smoke:** cenas adicionadas em `tests/scenes.txt`: …
- **Roteiro godot-qa:** cena, sequência de inputs, o que cada screenshot deve mostrar.
- **Playtest humano (opcional):** o que pedir para o humano sentir/avaliar.

## 11. ADRs locais

### ADR-F00-001 — <título>
- **Contexto / Decisão / Consequências / Data**

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.
