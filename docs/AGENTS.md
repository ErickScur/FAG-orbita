# AGENTS.md — Protocolo para agentes de IA

> Define **como** um agente (Claude Code ou subagente) trabalha dentro da doc viva do ÓRBITA. No início de **toda** sessão, leia [`/CLAUDE.md`](../CLAUDE.md), este arquivo, [`INDEX.md`](INDEX.md) e [`ENTREGAS.md`](ENTREGAS.md) **antes de fazer qualquer coisa**.

---

## 1. Arquivos da doc viva

| Arquivo | Para que serve |
|---|---|
| [`/CLAUDE.md`](../CLAUDE.md) | **Como** construímos: regras duras, stack, arquitetura, convenções, portões |
| [`INDEX.md`](INDEX.md) | Catálogo mestre, status e ordem. **Ponto de partida obrigatório** |
| [`ENTREGAS.md`](ENTREGAS.md) | O que entra na Demo e no Final; rubrica → feature. **Confira o escopo antes de codar** |
| [`design/GDD.md`](design/GDD.md) | **Fonte da verdade** de regras, números (GDD-P) e telas |
| [`design/JORNADA-DO-HEROI.md`](design/JORNADA-DO-HEROI.md) | **Fonte da verdade** da narrativa (textos, personagens, tom) |
| [`VISION.md`](VISION.md) | Visão em 1 página. Leia uma vez por sessão |
| [`DECISIONS.md`](DECISIONS.md) | ADRs cross-cutting |
| [`GLOSSARY.md`](GLOSSARY.md) | Termos do jogo (use-os exatamente assim na UI) |
| [`ASSETS.md`](ASSETS.md) | Registro de assets. Toda arte/som nasce e é rastreada aqui |
| [`ASSET-PIPELINE.md`](ASSET-PIPELINE.md) | Estilo, paleta, sites gratuitos, template de prompt |
| [`EDITOR-GUIDE.md`](EDITOR-GUIDE.md) | Como escrever passos para o humano no editor |
| [`TEMPLATE-FEATURE.md`](TEMPLATE-FEATURE.md) | Template canônico de feature |
| [`features/F<id>-*.md`](features/) | Doc de cada feature; vive o ciclo de vida dela ali |

---

## 2. Legenda de status

| Símbolo | Frontmatter `status` | Significado |
|---|---|---|
| `[ ]` | `not-started` | Não iniciado |
| `[~]` | `in-progress` | Em progresso |
| `[x]` | `done` | Concluído (critérios de aceite + portões verdes + commit feito) |
| `[!]` | `blocked` | Bloqueado (motivo no log) |
| `[-]` | `skipped` | Removido / fora de escopo (ADR + log) |

---

## 3. Workflow obrigatório

### 3.1 Início de sessão
1. Leia `/CLAUDE.md`, `AGENTS.md`, `INDEX.md`, `ENTREGAS.md`.
2. Identifique a próxima feature:
   - Existe alguma `[~]`? **Continue ela.**
   - Senão, a primeira `[ ]` do menor bloco cujas `depends_on` estão todas `[x]`.
   - Bloco 5 (STRETCH) só depois do Bloco 4 inteiro `[x]`. Bloco 6+ só na fase da entrega final.
3. Abra `features/F<id>-*.md`, leia o frontmatter e o corpo inteiro.
4. Na seção **"2. Referências de design"**, abra **cada âncora** do GDD/Jornada citada e leia a seção inteira. Ordem mental: **feature** (o que fazer) → **GDD** (regras e números) → **Jornada** (tom e texto) → **código atual** (o que já existe).
5. Números? Confira na [tabela GDD-P](design/GDD.md#gdd-p) e em `scripts/core/balance.gd`. Nunca invente valor.

### 3.2 Ao começar a codar
1. `INDEX.md`: status `[~]` + data.
2. Frontmatter da feature: `status: in-progress`, `last_updated`.
3. Log de evolução:
   ```markdown
   ### YYYY-MM-DD — Início
   - **Quem**: <agente> · **O que vou fazer**: <1-3 linhas>
   ```

### 3.3 Durante o trabalho
- **Placeholder-first**: se o asset definitivo não existe, gere placeholder (`tools/make_placeholders.gd`) e registre/atualize a ficha no [`ASSETS.md`](ASSETS.md). Nunca pare por falta de arte.
- **Lógica pura primeiro, com teste**: o que for regra (energia, status, reator, parser, save) vai para `scripts/core/` com `tests/test_*.gd` antes da cena.
- Prefira **escrever `.tscn`/`.tres`/`project.godot` à mão** a pedir ação humana. Só peça o editor quando for realmente inviável (ex.: instalar export templates).
- Siga `/CLAUDE.md` (2D, sem comentários, EventBus, Balance, SceneManager).
- Decisão **local** → ADR na seção 11 da feature. Decisão **cross-cutting** → [`DECISIONS.md`](DECISIONS.md) + referência no log.
- Mudança de **regra ou número de jogo** → edite o [`GDD.md`](design/GDD.md) (tabela GDD-P e/ou seção) **e** registre uma linha em [Ajustes de implementação](design/GDD.md#gdd-ajustes). Depois propague para `balance.gd` e para as features afetadas.
- Bloqueio → status `[!]`, motivo no log, **pare e peça orientação ao humano**.

### 3.4 Ação humana necessária
1. Escreva o bloco `🧑 AÇÃO HUMANA` na seção 8 da feature, no formato do [`EDITOR-GUIDE.md`](EDITOR-GUIDE.md#formato-acao-humana).
2. Mostre o mesmo passo-a-passo ao humano na resposta e **espere a confirmação**.
3. Depois da confirmação, verifique o efeito por arquivo/CLI (ex.: o `.tscn` mudou, o export existe) e registre no log.

### 3.5 Ao fechar a sessão (mesmo sem terminar)
Log de evolução com: o que foi feito, decisões, próximo passo. Atualize `last_updated` no frontmatter e no INDEX.

### 3.6 Ao concluir a feature
1. Critérios de aceite um a um → todos `[x]`.
2. Portões do `/CLAUDE.md` §6 (`/verify-gates`) verdes + QA visual (`godot-qa`) do roteiro da seção 10.
3. Status `[x]` no INDEX e no frontmatter; entrada final no log.
4. Se a feature marca item da rubrica, atualize a coluna de status em [`ENTREGAS.md`](ENTREGAS.md#rubrica).
5. **Commit** (`/commit-feature`): só arquivos do jogo, mensagem `feat(F<id>): …`, **sem co-autor**.
6. Volte ao INDEX para a próxima.

---

## 4. Regras duras

- **Não pule blocos** sem ADR.
- **Não invente features nem mecânicas** fora do GDD. Se algo importante falta no INDEX, proponha (adicione a linha) antes de codar.
- **Não trabalhe fora do escopo da feature atual.** Refactor cross-cutting → ADR + nova feature.
- **Não duplique convenções** — a fonte é `/CLAUDE.md`.
- **Não delete entradas de log** nem linhas de Ajustes/ADRs. Append-only; corrija com nova entrada.
- **Regra e número moram no GDD.** Nunca mude só no código ou só na feature.
- `CLAUDE.md`, `.claude/` e `docs/` **são versionados**: commite a doc viva junto da feature (fica de fora só `.claude/settings.local.json`). **Nunca** coloque co-autor/menção a IA no commit.
- **2D sempre. Sem comentários no código.**

---

## 5. Quando pedir orientação ao humano

- Algo só possível no editor (depois de tentar por arquivo/CLI).
- Asset definitivo precisa ser gerado/baixado pelo humano (entregue a ficha pronta do `ASSETS.md`: link ou prompt).
- Critério de aceite ambíguo após reler GDD e Jornada.
- Decisão de narrativa/nomes (ex.: nome definitivo da Engenheira Chefe) ou corte de escopo da Demo.
- Push para o GitHub, criação de release, qualquer ação externa.

Caso contrário: **decida, registre como ADR e siga.** O prazo da Demo é curto; prefira a solução simples que funciona.
