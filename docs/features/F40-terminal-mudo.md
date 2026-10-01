---
id: F40
title: Terminal mudo fora do tutorial
status: done
scope: demo
block: 6
priority: P1
rubric: ["Puzzle"]
depends_on: ["F17", "F36"]
unblocks: []
estimate: 2h
last_updated: 2026-09-20
---

# F40 — Terminal mudo fora do tutorial

## 1. Contexto e objetivo

Retorno direto do jogador humano depois de jogar a demo:

> "Nos terminais (tirando o tutorial). Precisamos tirar essas descrições das ações (META, VISAO, etc...). Tirar tambem o Ao Ligar, e tambem Ligar exige desligar. É um jogo de puzzle, precisamos dar menos informações, o jogador só vai saber o objetivo, e tem que se virar. Nao aplicar no tutorial, lá é excecção."

A [F17](F17-terminal-distribuicao.md) tinha respondido a um playtest anterior ("não entendi o que preciso fazer") enchendo o painel de explicação: etiqueta de função por sistema, `AO LIGAR:` / `AO DESLIGAR:` do sistema selecionado e a linha permanente `LIGAR EXIGE DESLIGAR: A ou B`. Isso resolveu o problema **no tutorial** e matou o puzzle **fora dele**: com a consequência de cada troca escrita na tela, o painel resolve o setor sozinho e o jogador só confirma.

Esta feature separa os dois papéis. O terminal do Núcleo Central continua sendo uma **aula** e não muda em nada. Os terminais das fases viram **um painel de estado**: título, orçamento, nome de cada sistema e `LIGADO`/`DESLIGADO`. Nem a meta do setor fica — o objetivo já vive no HUD, e a linha `META:` da Estufa dizia mais do que ele ([ADR-F40-006](#adr-f40-006)). O que cada sistema faz no mundo o jogador descobre ligando e olhando a estação — que é o pilar **ESCASSEZ** ([GDD pilares](../design/GDD.md#gdd-pilares)) funcionando como jogo em vez de como texto.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.5 Regra de energia](../design/GDD.md#gdd-2-5-energia) (a regra continua intacta; muda só o quanto a UI conta dela) · [GDD-2.3 Loop principal](../design/GDD.md#gdd-2-3-macro) ("não existe combinação certa única") · [GDD-2.7 F0](../design/GDD.md#gdd-2-7-f0) (o Núcleo é tutorial) · [GDD-2.7 F1](../design/GDD.md#gdd-2-7-f1) (a Estufa é a primeira fase de verdade)
- **Parâmetros:** nenhum novo. `Balance.HUD_TOAST_TIME` (tempo da mensagem transitória) segue como estava.
- **Jornada:** [Ideia principal](../design/JORNADA-DO-HEROI.md#jh-ideia) — "ligar uma coisa significa desligar outra" é para ser **sentido**, não lido.
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) (conteúdo em JSON) · [ADR-F17-013](F17-terminal-distribuicao.md#adr-f17-013) a [ADR-F17-017](F17-terminal-distribuicao.md#adr-f17-017) (o que está sendo restringido ao tutorial)

## 3. Critério de avaliação atendido

- **Puzzle:** na apresentação, a Estufa deixa de ser "leia as cinco linhas e escolha" e volta a ser dedução — o avaliador vê o apresentador **testando** combinações e o mundo respondendo. O tutorial do Núcleo continua ensinando a regra em uma tentativa, então ninguém fica perdido na primeira sala.

## 4. Escopo

### Inclui
- Chave declarativa `"verbose": true` em `data/energy/<terminal>.json` (ausente = terminal mudo), lida por `EnergyGrid.verbose`.
- `energy_terminal_ui.gd` em dois modos: **explicativo** (idêntico ao que existia) e **mudo**.
- Reequilíbrio do layout do painel mudo (linhas mais altas, sem coluna de etiqueta, sem linha de consequência, sem a linha `META:` enquanto o setor não está resolvido).
- Limpeza das falas ambientes da Estufa (`bark_on`/`bark_off` de todos os sistemas e `intro_bark`), que eram narração do efeito de cada sistema.
- Testes de dados que amarram a regra: só o tutorial é explicativo, e terminal mudo não declara fala nenhuma.

### Não inclui
- Mudança na `EnergyGrid` além de carregar a chave nova: orçamento, custos, dependências, cascata e `shutdown_candidates()` continuam idênticos (a lógica pura não sabe o que a UI mostra).
- Apagar `tag`, `description` e `effect_off` dos JSONs — o dado fica como documentação de design e continua validado; quem decide mostrar é a UI ([ADR-F40-002](#adr-f40-002)).
- Os textos de diálogo em si (`data/dialogue/greenhouse.json`) — F39.
- Qualquer mudança no terminal do Núcleo Central.

## 5. Critérios de aceite

- [x] `data/energy/core_hub.json` declara `"verbose": true`; nenhum outro terminal declara.
- [x] No terminal do Núcleo **nada muda**: coluna de etiqueta (`VISÃO`/`ACESSO`/`META`), `AO LIGAR:` / `AO DESLIGAR:`, `LIGAR EXIGE DESLIGAR: <A> ou <B>` e a recusa nomeando o candidato continuam na tela.
- [x] No terminal da Estufa somem: a coluna de etiqueta, a linha de consequência, a linha de troca e a linha `META:` do topo. A recusa por orçamento vira `ENERGIA INSUFICIENTE - DESLIGUE UM SISTEMA`, sem nomear ninguém.
- [x] Permanecem no terminal mudo: título, `ORÇAMENTO DE ENERGIA: X/Y EM USO` com o medidor, nome, custo e `LIGADO`/`DESLIGADO`/`REQUER`/`SELADO` de cada sistema, o retorno transitório `<NOME>: ONLINE` / `OFFLINE` / `DESLIGADO EM CADEIA: <NOMES>` e a recusa `REQUER: <NOME>`.
- [x] `META CUMPRIDA: <texto>` em ciano **aparece** no terminal mudo quando os `goal_systems` ligam: confirmação de resultado, não dica.
- [x] A linha em âmbar que ligava a etiqueta do sistema da meta ao topo do painel só existe no modo explicativo.
- [x] O painel mudo da Estufa (5 sistemas) cabe em 384×216 com folga, sem buraco onde estavam os blocos removidos, fonte em múltiplos de 16.
- [x] Fechar o painel da Estufa não dispara fala da ÓRBITA (nenhum `bark_on`/`bark_off` sobrou no JSON) e abrir pela primeira vez não dispara `intro_bark`.
- [x] Um terminal novo entra mudo por padrão: quem quiser explicar precisa pedir.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/energy_terminal_ui.gd     modos explicativo/mudo (_verbose, _apply_mode)
scripts/core/energy_grid.gd         var verbose: bool, lida em from_dict
data/energy/core_hub.json           "verbose": true
data/energy/greenhouse.json         sem intro_bark, sem bark_on/bark_off
tests/test_energy_grid.gd           test_verbose_is_declared_by_the_terminal
tests/test_energy_data.gd           test_tutorial_is_the_only_verbose_terminal
                                    test_mute_terminals_say_nothing_beyond_state
tests/qa/f40_nucleo.json            tutorial continua explicativo
tests/qa/f40_estufa.json            bancada da Estufa, painel mudo
tests/qa/f40_estufa_fase.json       Estufa de verdade (fase escura), painel legível
```

O modo entra em `open()` (`_verbose = _grid.verbose`) e é aplicado por `_apply_mode()` antes de montar as linhas:

| | explicativo | mudo |
|---|---|---|
| linha `Goal` (`META: ...`) | sempre visível | só quando a meta está cumprida (`META CUMPRIDA:` em ciano) |
| coluna de etiqueta (`_tags`) | visível, 46 px | `visible = false` (o `HBoxContainer` não reserva espaço) |
| `Description` (`AO LIGAR:` / `AO DESLIGAR:`) | visível, 26 px | `visible = false` |
| `Message` permanente (`LIGAR EXIGE DESLIGAR`) | sim | vazia (só retorno transitório) |
| altura da linha / separação | 17 / 1 | 19 / 2 |
| altura reservada da mensagem | 26 | 13 |
| etiqueta do sistema da meta em âmbar | sim | não |
| recusa `NO_BUDGET` | `ENERGIA INSUFICIENTE - DESLIGUE: <A> ou <B>` | `ENERGIA INSUFICIENTE - DESLIGUE UM SISTEMA` |

### Autoloads / sinais do EventBus
- Nenhum sinal novo. `EnergyNetwork.begin_session()` / `announce_change()` continuam iguais: com `intro_bark` e barks vazios no JSON, eles viram no-op na Estufa.

### Dados (`data/`)
- `data/energy/<terminal>.json`: campo novo opcional `verbose` (bool, padrão `false`). `goal_text`, `goal_done_text` e `goal_systems` continuam obrigatórios em todo terminal: no modo mudo só o texto de meta cumprida chega à tela, e `goal_met()` segue alimentando o estado do painel.
- `data/energy/greenhouse.json`: removidos `intro_bark` e os dez `bark_on`/`bark_off`.

### Input actions / camadas de colisão
- Sem mudanças.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-FONT](../ASSETS.md#ui-font) | texto do painel (16 px) | já integrado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `verbose` em `EnergyGrid.from_dict` + teste unitário (padrão `false`).
- [x] **Passo 2** — `"verbose": true` no `core_hub.json`; limpeza dos barks e do `intro_bark` no `greenhouse.json`.
- [x] **Passo 3** — dois modos em `energy_terminal_ui.gd` (`_apply_mode`, guardas em `_refresh_description`, `_refresh_hint`, `_refresh_row`, `_failure_text`).
- [x] **Passo 4** — reequilíbrio vertical do painel mudo e conferência por captura.
- [x] **Passo 5** — testes de dados (só o tutorial fala) e portões + QA nos dois terminais.

## 10. Verificação

- **Testes:**
  - `tests/test_energy_grid.gd::test_verbose_is_declared_by_the_terminal` — terminal sem a chave nasce mudo; com `"verbose": true` fica explicativo e continua válido.
  - `tests/test_energy_data.gd::test_tutorial_is_the_only_verbose_terminal` — `core_hub` é explicativo, todos os outros arquivos de `data/energy/` são mudos.
  - `tests/test_energy_data.gd::test_mute_terminals_say_nothing_beyond_state` — terminal mudo não tem `intro_bark` nem `bark_on`/`bark_off`.
  - `tests/test_energy_data.gd::test_goal_systems_always_narrate_the_switch` — passou a exigir fala do sistema da meta **só** nos terminais explicativos.
  - As suítes de puzzle da F17 (rotas, cascata, escassez, ausência de softlock) seguem intactas: a lógica não mudou.
- **Smoke:** nenhuma cena nova; `res://scenes/ui/energy_terminal_ui.tscn` e as bancadas já estavam em `tests/scenes.txt`.
- **Roteiro godot-qa:**
  - `tests/qa/f40_nucleo.json` (cena `res://scenes/dev/core_test.tscn`) — painel do tutorial com as três etiquetas, `AO DESLIGAR:` do sistema ligado, `AO LIGAR:` + `LIGAR EXIGE DESLIGAR: ILUMINAÇÃO DO NÚCLEO` na porta, recusa nomeando o candidato e `META CUMPRIDA:` em ciano no fim.
  - `tests/qa/f40_estufa.json` (cena `res://scenes/dev/energy_test.tscn`) — painel abre com título, orçamento e cinco linhas, sem etiqueta, sem consequência, sem linha de troca e sem `META:`; recusa genérica; `AQUECIMENTO DO MÓDULO: OFFLINE` e `1/2 EM USO` depois de desligar; `PORTA DO NÓ DO SETOR: ONLINE` com `META CUMPRIDA:`; ao fechar, nenhuma fala da ÓRBITA.
  - `tests/qa/f40_estufa_fase.json` (cena `res://scenes/levels/greenhouse.tscn`) — o mesmo painel dentro da fase já escurecida (F41), para provar que a `CanvasLayer` continua legível.
- **Playtest humano:** pedir para resolver a Estufa sem dicas e responder "você descobriu o que cada sistema faz olhando a estação?". Se o jogador travar sem nunca tentar uma combinação, o problema é do mundo (feedback visual), não do painel.

## 11. ADRs locais

### ADR-F40-001 — O modo do painel é uma chave do terminal, não um `if` por id
- **Contexto:** a regra é "o tutorial explica, o resto não". Escrever `if terminal_id == &"core_hub"` na UI funcionaria hoje e apodreceria na primeira fase nova.
- **Decisão:** cada `data/energy/*.json` declara `verbose`. Ausente = mudo, que é o padrão do jogo; o tutorial é a exceção e precisa pedir por escrito. A UI só pergunta `_grid.verbose`.
- **Alternativas:** flag em `Balance` (não é tuning global, é papel de cada terminal) e `if` por id (não escala, e o terceiro terminal esqueceria de ser mudo).
- **Consequências:** fase futura escolhe o modo em uma linha de JSON; o teste de dados falha se alguém ligar `verbose` fora do tutorial sem querer.
- **Data:** 2026-09-20

### ADR-F40-002 — O dado explicativo continua no JSON; quem some é a tela
- **Contexto:** `tag`, `description` e `effect_off` deixaram de ser exibidos na Estufa. Apagá-los do JSON pareceria coerente.
- **Decisão:** os campos ficam, obrigatórios e validados por `EnergyGrid.validate()`. Eles são a documentação de design de cada sistema ("o que este circuito faz e o que custa desligá-lo"), o tutorial os usa, e um terminal futuro pode voltar a mostrá-los.
- **Consequências:** nenhuma migração de dados; escrever um sistema novo continua obrigando a responder o que ele faz, mesmo que o jogador nunca leia.
- **Data:** 2026-09-20

### ADR-F40-003 — Fora do tutorial a recusa não nomeia o que desligar; a causa da recusa continua na tela
- **Contexto:** `ENERGIA INSUFICIENTE - DESLIGUE: A ou B` é a mesma informação de `LIGAR EXIGE DESLIGAR: A ou B`, só que na hora do erro. `REQUER: <NOME>` é outra coisa: é o motivo de uma recusa que o jogador não pediu.
- **Decisão:** no modo mudo a recusa por orçamento volta ao texto genérico. A recusa por dependência **continua nomeando** o sistema exigido, e a linha do sistema bloqueado continua marcada `REQUER`. Um painel que recusa sem dizer por quê é lido como bug, não como puzzle.
- **Consequências:** a escassez vira descoberta (o jogador escolhe o que sacrificar), mas a dependência em cadeia da Estufa (`PLATAFORMA DE CARGA` exige `AQUECIMENTO`) não vira tentativa e erro cega. Se o humano quiser esconder também isso, é uma linha em `_failure_text`.
- **Data:** 2026-09-20

### ADR-F40-004 — As falas ambientes da Estufa saem junto com as descrições
- **Contexto:** os `gh_bark_*` narravam exatamente o que o painel deixou de contar ("os esporos encolheram e o elevador parou"). Mantê-los devolveria a explicação pela porta dos fundos, dois segundos depois.
- **Decisão:** `intro_bark` e todos os `bark_on`/`bark_off` saem de `data/energy/greenhouse.json`; os `core_bark_*` do Núcleo ficam. `test_mute_terminals_say_nothing_beyond_state` impede a volta.
- **Consequências:** o efeito de cada troca passa a ser visto na estação (luz, planta, elevador, esporos), nunca narrado. Casa com a remoção das sequências correspondentes em `data/dialogue/greenhouse.json` ([F39](F39-dialogo-enxuto.md)).
- **Data:** 2026-09-20

### ADR-F40-005 — O painel mudo é reequilibrado, não recortado
- **Contexto:** tirando a coluna de etiqueta, a linha de consequência e a linha de troca, o painel ficaria com dois buracos e cinco linhas espremidas no topo.
- **Decisão:** no modo mudo a linha de sistema cresce de 17 para 19 px com separação 2, a `Description` é escondida (o `VBoxContainer` não reserva espaço para filho invisível) e a área de mensagem reserva uma linha em vez de duas. A largura de 360 px é mantida nos dois modos porque a linha `META:` da Estufa precisa dela.
- **Consequências:** o painel da Estufa fica com ~186 px de altura, centralizado, com o HUD visível acima e abaixo; as cinco linhas ficam distribuídas em vez de amontoadas.
- **Data:** 2026-09-20

### ADR-F40-006 — No terminal mudo a meta pendente sai; a meta cumprida fica
- **Contexto:** com o painel esvaziado, a linha `META: Abrir a Porta do Nó do Setor e religar o Nó` virou o texto mais gritante da tela — e ela diz **mais** que o objetivo do HUD ("Religar o Nó do Setor da Estufa"): ensina a ordem das coisas ("abrir a porta **e depois** religar"), que é justamente a dedução que o jogador deveria fazer.
- **Decisão:** no modo mudo a linha `Goal` fica `visible = false` enquanto a meta está pendente e aparece, em ciano, como `META CUMPRIDA: <goal_done_text>` quando os `goal_systems` ligam. O objetivo do setor continua no HUD o tempo todo. No tutorial nada muda.
- **Alternativas:** manter a linha reservando espaço vazio (buraco no topo do painel) e apagar `goal_text` do JSON (perde a documentação de design e o tutorial).
- **Consequências:** o painel mudo abre com título, orçamento e sistemas, nada mais; o painel cresce uma linha no instante em que o puzzle é resolvido, o que funciona como confirmação. `goal_text` continua obrigatório e validado.
- **Data:** 2026-09-20

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-20 — Feature criada e implementada
- **Origem**: retorno do jogador humano ("é um jogo de puzzle, precisamos dar menos informações... não aplicar no tutorial").
- **Quem**: agente de UX · **O que**: chave `verbose` por terminal, painel em dois modos, layout mudo reequilibrado, barks da Estufa removidos, três testes novos e três roteiros de QA.
- **Arquivos**: `scripts/core/energy_grid.gd` · `scenes/ui/energy_terminal_ui.gd` · `data/energy/{core_hub,greenhouse}.json` · `tests/{test_energy_grid,test_energy_data}.gd` · `tests/qa/f40_{nucleo,estufa,estufa_fase}.json`.
- **Decisões**: ADR-F40-001 a ADR-F40-005.
- **Portões**: `--import` sem erro · testes de energia verdes (`test_energy_*` sem falha) · smoke em 69 cenas · varreduras de comentário, 3D e fonte fora de múltiplo de 16 vazias.
- **QA**: 3 roteiros, 14 capturas lidas. Núcleo idêntico ao anterior (etiquetas, `AO LIGAR`, `LIGAR EXIGE DESLIGAR`, recusa nomeando a iluminação, `META CUMPRIDA` em ciano). Estufa muda na bancada e na fase de verdade: cinco nomes, custo e estado, nada mais; recusa genérica; `OFFLINE`/`ONLINE` como único retorno; nenhuma fala ao fechar o painel. Na Estufa já escurecida pela F41 (escuridão de verdade) o painel continua perfeitamente legível (a `CanvasLayer` não recebe a luz da fase).
- **Pendências**: a linha `META:` do painel repete (e amplia) a linha de objetivo do HUD na Estufa — levado ao orquestrador.

### 2026-09-20 — A meta pendente também sai do painel mudo
- **Origem**: decisão do orquestrador sobre a pendência acima. O objetivo já está no HUD; a linha `META:` da Estufa ensinava a ordem das ações, que é dica, não estado.
- **Quem**: agente de UX · **O que**: `_refresh_goal()` esconde a linha `Goal` no modo mudo enquanto a meta está pendente e a mostra como `META CUMPRIDA:` em ciano quando resolvida. `goal_text` continua no JSON. Tutorial intocado.
- **Arquivos**: `scenes/ui/energy_terminal_ui.gd`.
- **Decisões**: [ADR-F40-006](#adr-f40-006).
- **Portões**: `--import` sem erro · testes de energia verdes · smoke em 69 cenas · varreduras limpas.
- **QA**: `f40_estufa.json` e `f40_nucleo.json` rodados de novo, 4 capturas lidas. Estufa abre com `ESTUFA - DISTRIBUIÇÃO`, `ORÇAMENTO DE ENERGIA: 2/2 EM USO` e as cinco linhas — nenhuma linha de meta; com a porta do Nó ligada aparece `META CUMPRIDA: Porta do Nó do Setor aberta. Falta religar o Nó` em ciano junto de `PORTA DO NÓ DO SETOR: ONLINE`. Núcleo continua com `META: Abrir a porta do Setor Habitacional` em âmbar, as três etiquetas, `AO LIGAR:`/`AO DESLIGAR:`, `LIGAR EXIGE DESLIGAR:` e a recusa nomeando a iluminação.
