---
name: plan-feature
description: Planeja uma feature do ÓRBITA (F<id>) com força total — lê a feature, as âncoras do GDD/Jornada, o código atual e o ASSETS, desenha cenas/scripts/dados, o roteiro de QA e os passos humanos, fecha decisões com o usuário e entrega um plano executável. Use quando o usuário pedir para planejar uma feature, "planeje a F..", ou para criar o arquivo de uma feature FINAL (Bloco 6+) que ainda não existe.
---

# plan-feature — Planejamento de feature

Rode em **plan mode** quando disponível; termina em aprovação do usuário (ExitPlanMode), nunca em código.

## Passo 1 — Estudo (paralelo, Explore)
Lance até 3 Explore em paralelo:
1. **Design:** a feature (`docs/features/F<id>-*.md`, ou a linha do INDEX se ainda não existe) + cada âncora do `docs/design/GDD.md` e `docs/design/JORNADA-DO-HEROI.md` citada. Extraia regras, números (`Balance.*`), textos.
2. **Código:** o que já existe e será tocado — autoloads, sinais do EventBus, cenas e scripts vizinhos, `data/`, `tests/`. Pontos de extensão; o que reutilizar.
3. **Assets e conteúdo:** fichas do `docs/ASSETS.md` necessárias, placeholders existentes, JSONs de fase.

## Passo 2 — Desenho
- **Cenas e nós** (árvore de nós 2D exata), scripts e `class_name`, sinais novos no EventBus (evite; reutilize os existentes).
- **Lógica pura** em `scripts/core/` + testes `tests/test_*.gd`.
- **Dados** (esquema JSON) e **números** (novos → GDD-P + Ajustes).
- **Integração:** quem emite, quem escuta, o que salva no `GameState`/save, efeitos no HUD, áudio (SFX-PACK), luz.
- **Roteiro godot-qa:** cena, inputs por frame, screenshots esperadas.
- **🧑 Ação humana** (se houver) no formato do `docs/EDITOR-GUIDE.md`.
- **Assets:** fichas novas via skill `asset-request`.

## Passo 3 — Decisões
Pergunte ao usuário só o que muda o jogo (narrativa, corte de escopo, sensação). O resto: decida e registre como ADR local.

## Passo 4 — Plano
Escreva/atualize o arquivo da feature seguindo `docs/TEMPLATE-FEATURE.md` (se for FINAL, crie o arquivo e troque a linha do INDEX por link). O plano do plan mode resume: contexto, arquivos, passos, verificação.

**Ponta solta é defeito de planejamento**: toda cena tem como ser alcançada, todo dado tem quem leia, todo sinal tem quem escute.
