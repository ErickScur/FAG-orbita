# Modelo de briefing para subagente do ÓRBITA

Destilado dos 49 subagentes da demo. Os que acertaram de primeira tinham **todas** as seções
abaixo; os que precisaram de retrabalho quase sempre não tinham "Estado atual" ou "O que eu já
verifiquei". O subagente só sabe o que está no prompt.

```markdown
Você é o AGENTE <PAPEL> do jogo ÓRBITA (Godot 4.7.2, 2D pixel art, 384×216, renderer
Compatibility). Projeto em /Users/BRScurPaEr/code/fag/jogo.

LEIA PRIMEIRO, NA ORDEM:
1. `CLAUDE.md` inteiro (regras duras §2, contrato dos autoloads §4.3, portões §6, lições §9)
2. Skills do assunto: `.claude/skills/godot-pitfalls/SKILL.md` (seções <luz | UI | ...>),
   e `level-design` / `godot-qa` / `asset-request` quando couber
3. `docs/features/F<id>-*.md` e as âncoras do GDD citadas nela
4. Os arquivos de código que você vai tocar: <lista>

## O pedido (nas palavras do humano, quando houver)
> "<citação literal>"
<o problema em 2-4 linhas, com o que o humano viu>

## Estado atual (pronto — reutilize, não refaça)
- <N> testes verdes, <M> cenas no smoke
- <sistemas existentes que resolvem parte do problema, com caminho e nome de método>

## O que eu já verifiquei (não repita)
- <hipóteses descartadas, com a medida que as descartou>

## O que construir
<entregáveis numerados, critérios de aceite verificáveis>

## Arquivos
- Seus (pode criar/editar): <lista>
- Proibidos (outros agentes estão neles): <lista>
- Docs: só `docs/features/F<id>-*.md` (log + critérios + ADR local)

## Regras
- 2D sempre; sem comentários em .gd; GDScript tipado; números só no `Balance` (GDD-P antes);
  texto do jogador em pt-BR com acentos; EventBus/SceneManager.
- Godot só com timeout: `tools/gates.sh`, `tools/qa.sh`, ou `perl -e 'alarm N; exec @ARGV' "$GODOT" ...`.
- Teste novo: leia `tests/test_case.gd` antes (API de asserts).
- QA de gameplay: roteiro com marcos `expect_tile`/`expect_scene`; leia as capturas.
- **Não faça commit nem `git add`.**

## Relatório final (curto)
- O que mudou, arquivo por arquivo
- Resultado de `tools/gates.sh` (cole o fim) e do `tools/qa.sh` (resumo de marcos)
- Decisões tomadas (viraram ADR local?) e o que ficou pendente
- **Armadilha nova encontrada** (sintoma, causa, regra) — vira lição na skill do assunto
```

## Variações que funcionaram
- **Bug de playtest**: cite a fala do humano, descreva a captura que ele mandou ("o que **eu**
  vejo nela"), liste hipóteses "para testar, não se prenda a elas".
- **Asset**: tabela arquivo → ID → contrato → **medida real** (largura × altura, proporção), e a
  instrução de recusar em vez de forçar.
- **Rodada com vários agentes**: um `CONTRATO-<rodada>.md` no scratchpad com donos de arquivo e
  decisões comuns, citado por todos os prompts.
