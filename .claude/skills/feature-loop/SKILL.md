---
name: feature-loop
description: Executa um lote de features do ÓRBITA em sequência de forma semi-autônoma — para cada uma roda estudar → decidir (ADR) → implementar → portões → QA por screenshot → docs → commit, delegando trabalho pesado a subagentes e mantendo um RUN-PLAN durável no scratchpad. Use quando o usuário pedir "faça as próximas features", "toque o Dia 1", "execute F01 a F06", ou um loop multi-feature.
---

# feature-loop — Loop sequencial de features

O orquestrador (você) fica **enxuto**: lê relatórios, decide, atualiza o RUN-PLAN e dispara o próximo passo. Implementação e QA rodam em subagentes.

## Passo 0 — RUN-PLAN (sobrevive à compactação)
Escreva `RUN-PLAN-<n>.md` no **scratchpad da sessão** (não no repo) com:
1. Lista ordenada de features (INDEX, respeitando `depends_on` e blocos).
2. Para cada uma: executar ou pular → handoff (se exigir decisão humana).
3. Decisões/ADRs tomados; ações humanas pendentes; commits feitos (hash).
Confirme o recorte com o usuário no início (o que entra, o que depende dele — ex.: assets, GitHub).

## Ciclo por feature (uma de cada vez, nunca em paralelo — todas mexem em project.godot/autoloads)
1. **Estudar** — leia a feature e as âncoras do GDD (ou Explore se for grande).
2. **Decidir** — ADR local na seção 11 da feature para o que não estiver especificado. Número novo → GDD-P + Ajustes.
3. **Marcar `[~]`** no INDEX e no frontmatter; entrada "Início" no log.
4. **Implementar (subagente general-purpose)** — prompt com: caminho da feature, regras duras do CLAUDE.md §2 repetidas literalmente (2D, sem comentários, Balance, EventBus, SceneManager, pt-BR/inglês), contrato de sinais/GameState, arquivos que pode tocar, e a exigência de rodar `/verify-gates` e reportar o output.
5. **Portões** — confira você mesmo: import, testes, smoke, varreduras.
6. **QA** — skill `godot-qa` com o roteiro da seção 10; leia as screenshots; bug → volta ao passo 4 com o problema concreto.
7. **Ação humana** — se a feature tem 🧑, pare o loop nesse ponto, mostre o passo-a-passo e espere.
8. **Docs** — `/update-feature-docs`.
9. **Commit** — `/commit-feature` (sem co-autor, sem docs/CLAUDE/.claude).
10. Atualize o RUN-PLAN e siga.

## Ambiguidade
Se o GDD não responde e a decisão muda a experiência (narrativa, corte), acumule no handoff e pule para a próxima feature independente. Se é técnica, decida e registre ADR.

## Ao final
Relatório curto ao usuário: features `[x]` com hash de commit, pendências humanas (assets, GitHub, playtest), próximos passos.
