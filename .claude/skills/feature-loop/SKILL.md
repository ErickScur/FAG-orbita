---
name: feature-loop
description: Executa um lote de features do ÓRBITA em sequência de forma semi-autônoma — para cada uma roda estudar → decidir (ADR) → implementar → portões → QA com marcos → docs → commit, delegando trabalho pesado a subagentes com o briefing padrão e mantendo um RUN-PLAN durável no scratchpad. Use quando o usuário pedir "faça as próximas features", "toque o Dia 1", "execute F01 a F06", "faça a fase do Laboratório", ou um loop multi-feature.
---

# feature-loop — Loop de features

O orquestrador (você) fica **enxuto**: lê relatórios, decide, atualiza o RUN-PLAN e dispara o
próximo passo. Implementação e QA rodam em subagentes.

## Passo 0 — RUN-PLAN (sobrevive à compactação)
Escreva `RUN-PLAN-<n>.md` no **scratchpad da sessão** (não no repo) com:
1. Lista ordenada de features (INDEX, respeitando `depends_on` e blocos).
2. Para cada uma: executar ou pular → handoff (se exigir decisão humana).
3. Decisões/ADRs tomados; ações humanas pendentes; commits feitos (hash).
Confirme o recorte com o usuário no início (o que entra, o que depende dele — assets, GitHub).

## Ciclo por feature
1. **Estudar** — feature + âncoras do GDD (ou Explore se for grande). Fase nova → skill
   `level-design` antes de tudo.
2. **Decidir** — ADR local na seção 11 para o que não estiver especificado. Número novo → GDD-P +
   Ajustes **antes** do `Balance` (`tests/test_gdd_parity.gd` reprova o contrário).
3. **Marcar `[~]`** no INDEX e no frontmatter; entrada "Início" no log.
4. **Implementar (subagente)** — prompt montado com o modelo de [`BRIEFING.md`](BRIEFING.md).
   Nunca mande "leia o CLAUDE.md e implemente" sem as seções do modelo.
5. **Portões** — `tools/gates.sh` você mesmo; não confie só no relatório do subagente.
6. **QA** — skill `godot-qa` com marcos; leia as capturas-chave você mesmo. Bug → volta ao passo
   4 com o problema concreto **e o que você já descartou** (foi assim que o bug da SR-3 saiu
   rápido: o prompt já provava que a arte estava certa).
7. **Pré-playtest** — feature com gameplay ou UI passa pelo checklist do `level-design` §4.7
   antes de ir para o humano. As 12 rodadas de retrabalho da demo vieram do playtest; o checklist
   é a lista do que o humano reprovou.
8. **Ação humana** — se a feature tem 🧑, pare nesse ponto, mostre o passo-a-passo e espere.
9. **Docs** — `/update-feature-docs` (armadilha nova vai para a skill do assunto).
10. **Commit** — `/commit-feature`. A doc viva (`docs/`, `CLAUDE.md`, `.claude/`) **entra** no
    commit da feature (regra dura 4); só `.claude/settings.local.json` fica de fora.
11. Atualize o RUN-PLAN e siga.

## Paralelismo
- Features que mexem em `project.godot`, autoloads ou no mesmo `.gd` correm **em série**.
- Trabalho independente (assets diferentes, fases diferentes, bugs em sistemas distintos) pode
  correr em paralelo com **no máximo 3 agentes pesados de uma vez**. Na demo, 4 agentes de
  assets lançados juntos bateram no limite da API e 3 morreram antes de escrever qualquer coisa.
- Cada agente paralelo recebe **lista explícita de arquivos que é dono** e de arquivos que não
  pode tocar. Ninguém roda `git add` além do orquestrador, e o orquestrador adiciona **por
  caminho**, com `git status` no mesmo comando (F50: `git add -A` varreu trabalho de outro agente).
- Agente que morreu por limite de API: relance com "uma tentativa anterior morreu antes de
  escrever; a árvore está limpa (N testes verdes)" — confira antes que é verdade.

## Ambiguidade
Se o GDD não responde e a decisão muda a experiência (narrativa, corte, sensação), acumule no
handoff e pule para a próxima feature independente. Se é técnica, decida e registre ADR.

## Ao final
Relatório curto ao usuário: features `[x]` com hash de commit, pendências humanas (assets,
GitHub, playtest), o que ele deve testar primeiro ao jogar, próximos passos.
