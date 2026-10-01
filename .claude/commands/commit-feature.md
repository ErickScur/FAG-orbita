---
description: Faz o commit de uma feature do ÓRBITA seguindo as regras do projeto — só arquivos do jogo, mensagem pt-BR padronizada, SEM co-autor nem menção a IA.
---

# Commit de feature

1. `git status --short` — confira a lista. **Não pode aparecer** lixo (`.godot/`, `.DS_Store`, builds) nem `.claude/settings.local.json`. A doc viva (`docs/`, `CLAUDE.md`, `.claude/`) **entra** no commit da feature.
2. Adicione **por caminho**, nunca `git add -A` às cegas:
   `git add project.godot autoload/ scenes/ scripts/ data/ assets/ tests/ tools/ README.md docs/ CLAUDE.md .claude/ …` (só o que a feature tocou).
3. `git diff --cached --stat` — revise.
4. Mensagem (pt-BR), **uma linha** + corpo opcional curto:
   ```
   <tipo>(F<id>): <resumo no imperativo>

   - <detalhe relevante>
   ```
   Tipos: `feat`, `fix`, `chore`, `art`, `audio`, `docs`, `refactor`, `test`.
5. **PROIBIDO** na mensagem: `Co-Authored-By`, "Claude", "Generated with", "AI", emoji de robô. Use `git commit -m "..."` com a mensagem literal — nada de trailer.
6. Confira: `git log -1 --format='%an <%ae>%n%B'` → autor Erick Scur, sem trailer.
7. **Não faça push** sem o humano pedir. Push nunca com `--force`.
