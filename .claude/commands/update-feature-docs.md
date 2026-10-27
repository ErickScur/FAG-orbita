---
description: Atualiza a documentação viva de uma feature na sequência canônica (feature → INDEX → ENTREGAS → GDD/Ajustes → DECISIONS → GLOSSARY/ASSETS) ao avançar ou concluir o trabalho.
---

# Atualizar docs da feature

A feature é a fonte da verdade do trabalho; o INDEX é o catálogo; o ENTREGAS acompanha a rubrica; o GDD guarda regras e números.

1. **`docs/features/F<id>-*.md`**
   - Frontmatter: `status` (`not-started`→`in-progress`→`done`), `last_updated`.
   - Marque critérios de aceite e passos do plano concluídos.
   - Entrada no **Log de evolução** (append-only): data, quem, o que foi feito, decisões, próximo passo.
2. **`docs/INDEX.md`** — marcador (`[ ]`→`[~]`→`[x]`) e data na linha da feature.
3. **`docs/ENTREGAS.md`** — se a feature atende item da rubrica e ficou `[x]`, marque o item.
4. **`docs/design/GDD.md`** — se mudou regra ou número: edite a seção/tabela GDD-P **e** adicione linha em "Ajustes de implementação". Espelhe em `scripts/core/balance.gd`.
5. **`docs/DECISIONS.md`** — decisão cross-cutting vira ADR (append-only). Decisão local fica na seção 11 da feature.
6. **`docs/GLOSSARY.md`** / **`docs/ASSETS.md`** — termo novo na UI; asset novo/alterado (status, licença, créditos).
7. **Lição aprendida** — armadilha real (sintoma silencioso, retrabalho, playtest reprovando)
   vira uma linha **na skill do assunto**: `godot-pitfalls` (engine/código), `godot-qa`
   (roteiros e capturas), `asset-request` (arte/áudio), `level-design` (fase, geometria,
   regra de design). Se vale para qualquer tarefa (processo, git, ferramenta), vai no `/CLAUDE.md`
   §9. Formato: regra → sintoma → causa → (feature).
8. **Mecanismo > lição** — se a armadilha pode ser pega por teste, marco de QA ou varredura do
   `tools/gates.sh`, escreva o mecanismo também. Lição sem mecanismo se repete.
