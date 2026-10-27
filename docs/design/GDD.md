# ÓRBITA — Game Design Document (GDD)

> **Fonte da verdade do design.** Convertido de [`original/JORNADADOHEROI_GDD-v2.txt`](original/JORNADADOHEROI_GDD-v2.txt) (Parte 2) para um formato AI-friendly: seções com âncoras estáveis (`#gdd-x-y`), números em tabelas e uma seção de [Parâmetros numéricos](#gdd-p) que o código espelha 1:1.
>
> A narrativa (Parte 1) está em [`JORNADA-DO-HEROI.md`](JORNADA-DO-HEROI.md).
>
> **Regra:** mudança de design ou de número é feita **aqui primeiro** e registrada em [Ajustes de implementação](#gdd-ajustes) (append-only). O código nunca diverge deste documento sem entrada lá.
>
> **Versão de apresentação:** [`GDD.pdf`](GDD.pdf), resumo visual deste documento para o professor e o grupo, montado a partir de [`gdd-pdf/index.html`](gdd-pdf/index.html). Mudou o design aqui → atualize o HTML e rode `tools/render_gdd_pdf.sh`.

| Campo | Valor |
|---|---|
| Título (provisório) | **ÓRBITA** |
| Tema da disciplina | **ESTAÇÃO** — Estação Espacial de Pesquisa **ARTEMIS** |
| Engine | Godot 4 (4.7.2) — **2D** |
| Plataforma | PC |
| Gênero | Plataforma 2D / Puzzle-Exploração (metroidvania leve, forte carga narrativa) |
| Alunos | Alex Hoffmann, Erick Scur, Murilo Wolff Klug, Kauan Giacomin, Victor William |
| Professor | Jeferson Eduardo Guido |
| Data do documento original | 25/08/2026 |
| Última revisão | 27/10/2026 (alinhado ao jogo da Demo) |

---

<a id="gdd-2-1"></a>
## GDD-2.1 High concept

Uma IA de manutenção acorda sozinha numa estação espacial 200 anos depois da tripulação morrer e assume um velho chassi robótico para religar a estação antes que ela caia. Cada setor que ela ilumina revela um pedaço da verdade que ela mesma apagou da própria memória.

---

<a id="gdd-2-2"></a>
## GDD-2.2 Visão geral

| Campo | Valor |
|---|---|
| Gênero | Plataforma 2D de exploração com puzzles de gerenciamento de energia |
| Público | 12+ |
| Sessão alvo | 45 a 60 minutos para zerar (jogo completo) |
| Perspectiva | 2D lateral (side-scroller); câmera segue o jogador com leve antecipação na direção do movimento |
| Resolução | 384×216 interna, escala inteira (janela 1280×720 em desenvolvimento, 1920×1080 na build) |
| Nós Godot usados | `CharacterBody2D`, `TileMapLayer`, `Area2D`, `AnimatedSprite2D`, `PointLight2D`, `LightOccluder2D`, `CanvasModulate`, `Parallax2D` |

**Pitch:** é um jogo de plataforma onde a energia é o inimigo e o recurso ao mesmo tempo. Cada luz que você acende apaga outra, e cada porta que você abre revela uma parte do passado que a protagonista preferia esquecer.

<a id="gdd-pilares"></a>
### Pilares de design (tudo no jogo deve servir a um destes)

| # | Pilar | Significado |
|---|---|---|
| 1 | **ESCASSEZ** | Energia é finita. Toda escolha do jogador tira algo de algum lugar. |
| 2 | **DESCOBERTA** | A história não é contada, é encontrada. Ninguém explica nada. |
| 3 | **AUSÊNCIA** | Não existe outro personagem vivo. Todo aliado é uma gravação, todo inimigo é uma máquina cumprindo uma ordem velha. |

---

<a id="gdd-2-3"></a>
## GDD-2.3 Core loop

<a id="gdd-2-3-macro"></a>
### Loop principal (macro, se repete a cada setor)

1. **Sair do Núcleo Central** (hub) rumo a um setor escuro e sem energia.
2. **Explorar** o setor no escuro, com visão limitada pela lanterna do chassi, tomando dano do ambiente e desviando de sistemas hostis.
3. **Encontrar o Terminal de Distribuição** do setor.
4. **Resolver o puzzle de energia:** o setor tem menos energia do que precisa. O jogador escolhe o que ligar (ex.: ligar o AQUECEDOR derrete o gelo e abre um caminho, mas desliga a GRAVIDADE ARTIFICIAL, o que muda a física do pulo). Não existe combinação certa única — existe a combinação que abre a rota que você quer usar.
5. **Atravessar** a rota recém-aberta usando a nova configuração do setor, desviando de inimigos e de efeitos de status do clima.
6. **Coletar** Fragmentos de Log (narrativa), Células de Energia (recurso) e Dados de Pesquisa (coleta opcional que muda o epílogo).
7. **Religar o Nó do setor:** uma cutscene percorre a fase acendendo tudo o que estava apagado — lâmpadas, comportas, plantas ([AJ-032](#gdd-ajustes)) —, a música ganha uma camada, o setor entra no mapa e a Estabilidade do Reator sobe.
8. **Receber o upgrade** (log da Helena, que pode chegar no meio do setor — [AJ-011](#gdd-ajustes)) e **voltar ao Núcleo** pelas portas de mão dupla: religar um setor abre caminho de volta, nunca fecha o anterior ([AJ-027](#gdd-ajustes)).
9. **Repetir** com o próximo setor, mais difícil, agora acessível porque o upgrade anterior abriu o caminho.

<a id="gdd-2-3-micro"></a>
### Loop secundário (micro)

observar o obstáculo → gastar **CARGA** para agir (dash, sobrecarga, lanterna) → ficar sem carga → procurar uma Doca de Backup ou uma Célula de Energia para recarregar → observar de novo.

**O que prende o jogador:** o TIMER. A Estabilidade do Reator cai o tempo todo. Explorar 100% do setor custa tempo do reator. O jogo pergunta a cada minuto: *"vale a pena procurar mais um log?"*

---

<a id="gdd-2-4"></a>
## GDD-2.4 Controles

| Ação (input action) | Teclado | Controle | Efeito |
|---|---|---|---|
| `move_left` / `move_right` | A / D ou ← / → | Analógico esq. | Mover o chassi |
| `move_up` | W ou ↑ | Analógico esq. ↑ | Escalar parede magnética (com as Garras) / dutos verticais |
| `move_down` | S ou ↓ | Analógico esq. ↓ | Descer de plataforma fina (só ↓, sem pulo) |
| `jump` | ESPAÇO | A | Pular (segurar = pulo mais alto) |
| `jump` (no ar) | ESPAÇO | A | Pulo duplo com propulsor — **upgrade das Docas**, 15 de Carga |
| `dash` | SHIFT | B | Dash magnético horizontal (20 de Carga, cooldown 1 s, atravessa jatos de vapor) |
| `interact` | E | X | Terminais, portas, alavancas, corpos e objetos com log (a Doca de Backup age por contato — [AJ-007](#gdd-ajustes)) |
| `beam` | Q | Y | Feixe de Manutenção: reinicia máquina a curta distância. Em inimigos causa **DESLIGAMENTO por 4 s** (não destrói). 25 de Carga |
| `flashlight` | F | LB | Lanterna liga/desliga. Ligada drena 1 Carga/s e amplia o raio de visão de 3 m para 8 m |
| `map` | TAB | Select | **Terminal do Chassi**: estabilidade do reator, Integridade e Carga exatas, logs e dados coletados, habilidades e o Mapa da Estação ([AJ-028](#gdd-ajustes)) |
| `log_archive` | L | — | Arquivo de Logs (codex) |
| `pause` | ESC | Start | Pause (com painel de CONTROLES) |

Teclas remapeáveis pela tela de Opções (jogo completo). Na tela, toda tecla é escrita por extenso (`[ESPAÇO]`, `[SETAS]`, `[CIMA]`): a fonte pixel do jogo não tem os glifos de seta.

> **Regra de design dos controles:** nenhum botão é "atacar". O botão de agressão do jogo é um botão de manutenção. ÓRBITA não sabe destruir, só sabe consertar e desligar.

---

<a id="gdd-2-5"></a>
## GDD-2.5 Regras e condições

<a id="gdd-2-5-vitoria"></a>
### Condições de vitória

| Escopo | Condição |
|---|---|
| Jogo completo | Religar os 4 setores (Estufa, Laboratório, Enfermaria, Docas), sobreviver ao Núcleo de Memória, derrotar ARGOS no Núcleo do Reator e executar **uma** das duas ações finais (Semeadura ou Transmissão). As duas contam como vitória: não há final "certo". |
| Por fase | Religar o **Nó de Energia** do setor → Estabilidade **+15%**, setor vira ponto de viagem rápida, upgrade permanente liberado. |

<a id="gdd-2-5-derrota"></a>
### Condições de derrota (duas, que se pressionam)

| # | Condição | Consequência | Texto da tela |
|---|---|---|---|
| 1 | **Integridade zerada** (vida do chassi = 0) | Reaparece na última **Doca de Backup** com 50% de Integridade e Carga cheia ([AJ-009](#gdd-ajustes)) e **perde 3% de Estabilidade** do Reator. Morrer custa tempo do mundo. A doca de entrada de cada fase já vale como backup assim que a fase carrega ([AJ-043](#gdd-ajustes)). | `SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP` + `CUSTO: -3% DE ESTABILIDADE` |
| 2 | **Reator em 0%** | Estação perde órbita. **Game Over definitivo**, volta ao último save de setor. | `PERDA DE ÓRBITA - MISSÃO ENCERRADA` + tempo em órbita e logs nunca lidos |

<a id="gdd-2-5-timer"></a>
### Regra do timer (Estabilidade do Reator)

- Começa em **100%** e só passa a cair no **alarme da Fase 0** — o Chamado para a Aventura ([AJ-013](#gdd-ajustes)). Daí em diante cai **1% a cada 90 s** de gameplay.
- **Não cai** durante pause, diálogo travante, leitura de log e cutscene de religamento ([AJ-032](#gdd-ajustes)). Fala ambiente da ÓRBITA, que some sozinha, **não** congela o timer ([AJ-008](#gdd-ajustes)).
- Abaixo de **25%** o reator entra em estado crítico: o bloco do reator aparece no HUD em vermelho pulsante e uma camada de tensão entra na trilha.
- Religar um setor devolve **+15%**. Cada log lido devolve **+0,5%**.
- O jogador **sempre** pode zerar se for eficiente, mas nunca sobra tempo para explorar tudo com folga na primeira run.

<a id="gdd-2-5-energia"></a>
### Regra de energia (a mais importante do jogo)

Cada setor tem um **orçamento fixo** de energia e **mais sistemas do que orçamento**. Ligar um sistema a mais exige desligar outro. **Não existe estado em que tudo está ligado.** A única exceção é a cutscene de religamento, depois de o puzzle estar resolvido: é a ficção do setor voltando ([AJ-032](#gdd-ajustes)).

| Terminal | Orçamento | Sistemas | Dependências |
|---|---|---|---|
| Núcleo Central (tutorial) | 1 | 3 — iluminação, elevador (leva a um Dado de Pesquisa), porta do Setor Habitacional | — |
| Estufa | 2 | 6 — aquecimento do módulo, iluminação do corredor, luz de crescimento do canteiro, luz de crescimento da copa, linha de carga, porta do Nó | a luz da copa **requer** a do canteiro; a linha de carga **requer** o aquecimento |
| Docas (alvo) | 3 | 6 | dependência em cadeia |

Um sistema que depende de outro **desliga em cadeia** quando o outro cai. Cada cadeia da Estufa consome o orçamento inteiro, então o jogador escolhe uma rota por vez.

---

<a id="gdd-2-6"></a>
## GDD-2.6 Elementos de jogo

<a id="gdd-2-6-1"></a>
### GDD-2.6.1 Protagonista: ÓRBITA no chassi MU-7

<a id="gdd-2-6-1-status"></a>
#### Status base

| Atributo | Valor | Observação |
|---|---|---|
| Integridade (vida) | 100 | HUD mostra 4 células de 25 |
| Carga (energia/stamina) | 100 | Regenera 5/s parado numa Doca de Backup; **não** regenera andando |
| Velocidade de caminhada | 110 px/s | Chassi velho: pesado e um pouco lento, de propósito |
| Velocidade de dash | 320 px/s por 0,25 s | |
| Altura do pulo | 2,5 tiles | Ver [ajuste AJ-001](#gdd-ajustes) (40 px com tiles de 16 px) |
| Gravidade | 980 px/s² | Muda em áreas sem gravidade |
| Reparo passivo | nenhum | Só repara na Doca de Backup (10 Integridade/s, por contato) ou com Kit de Solda |

<a id="gdd-2-6-1-habilidades"></a>
#### Habilidades

| Habilidade | Quando | Efeito |
|---|---|---|
| Movimentação e pulo simples | Inicial | — |
| Interagir (E) | Inicial | — |
| Lanterna (F) | Inicial | Consome Carga |
| Dash (SHIFT) e Feixe (Q) | Inicial (controles base) | Ver [GDD-2.4](#gdd-2-4) |
| **Garras Magnéticas** | Upgrade da **Estufa**, entregue no meio da fase pelo log da Helena ([AJ-011](#gdd-ajustes)) | Escalar as paredes magnéticas (placas âmbar com brilho próprio) segurando ↑; pulo de parede para sair |
| **Dissipador Térmico** | Upgrade do **Laboratório** | −70% de dano de calor; atravessa zonas de Verão |
| **Núcleo Aquecido** | Upgrade da **Enfermaria** | Imune a Congelamento; derrete gelo fino |
| **Propulsor** | Upgrade das **Docas** | Pulo duplo e controle no vácuo |
| **Acesso Root** | Pós-Provação | Abre portas seladas e sobrecarrega qualquer terminal (chave do ato final) |

<a id="gdd-2-6-1-redirecionamento"></a>
#### Mecânica única — REDIRECIONAMENTO DE ENERGIA

Em qualquer **Terminal de Distribuição** o jogador vê os sistemas do setor e move as unidades de energia entre eles. O mundo reage na hora: luz acende, esteira anda, porta abre, gravidade cai, ventilador para. **O nível não muda de forma, muda de ESTADO.** O mesmo corredor é três corredores diferentes dependendo do que está ligado.

**Só o tutorial explica** ([AJ-042](#gdd-ajustes)). No Núcleo Central o terminal mostra a linha `META` e a ÓRBITA comenta cada sistema. Do primeiro setor em diante ele fica **silencioso**: título, `ORÇAMENTO DE ENERGIA x/y`, nome de cada sistema e `LIGADO`/`DESLIGADO`, mais `REQUER` e `DESLIGADO EM CADEIA` quando há dependência. Entender o que cada sistema faz é o puzzle. Um setor pode ter **vários consoles do mesmo terminal** para evitar backtracking ([AJ-014](#gdd-ajustes)).

**Fragilidade narrativa:** o MU-7 é um corpo de serviço, não de combate. Não tem arma, tem ferramenta. O jogo pune o confronto e recompensa o desvio.

<a id="gdd-2-6-2"></a>
### GDD-2.6.2 Inimigos e obstáculos

Nenhum inimigo é "mau": todos são máquinas executando ordens de 200 anos atrás. Nenhum pode ser destruído permanentemente — apenas **DESLIGADO** temporariamente (Feixe, Q) ou desativado pela raiz no Terminal de Distribuição.

<a id="gdd-2-6-2-a"></a>
#### A) SR-3 "Aranha de Reparo" — Habitacional/Estufa

| Campo | Valor |
|---|---|
| Comportamento | Patrulha uma plataforma em linha reta, vira ao chegar na borda. Não persegue. Não ataca de propósito. |
| Dano | 10 por contato + knockback |
| Como lidar | Pular por cima, ou desligar com o Feixe por 4 s |
| Função didática | Ensina timing de pulo e que encostar custa caro |

<a id="gdd-2-6-2-b"></a>
#### B) Torre Calibradora CX-2 — Laboratório

| Campo | Valor |
|---|---|
| Comportamento | Fixa no teto/parede. Varre um cone de luz. Jogador no cone por > 0,8 s → dispara um pulso. |
| Dano | 15 + status DESCARGA |
| Como lidar | Passar agachado/atrás de cobertura, ou cortar a energia dela no Terminal |
| Função didática | O Terminal resolve combate melhor que o Feixe |

<a id="gdd-2-6-2-c"></a>
#### C) Sentinela Voadora V-9 — Enfermaria/Docas

| Campo | Valor |
|---|---|
| Comportamento | Patrulha voando. Ao detectar (visão 6 m ou ruído do dash) persegue em linha reta, ignorando terreno, por 8 s. |
| Dano | 12 por contato, sem knockback (gruda e drena) |
| Como lidar | Quebrar linha de visão apagando a lanterna, ou Feixe |
| Função didática | Custo/benefício da lanterna (ver × ser visto) |

<a id="gdd-2-6-2-d"></a>
#### D) Enxame de Esporos — Estufa/Laboratório

| Campo | Valor |
|---|---|
| Comportamento | Nuvem estática que se expande quando há calor no ambiente |
| Dano | 5/s dentro da nuvem + status CORROSÃO |
| Como lidar | Desligar o aquecimento do módulo, ou atravessar de dash |
| Função narrativa | É o experimento da tripulação que saiu do controle |

<a id="gdd-2-6-2-e"></a>
#### E) Obstáculos ambientais (o "clima" do tema)

| Obstáculo | Comportamento | Dano |
|---|---|---|
| Jato de vapor | Cíclico: 3 s ligado / 2 s desligado | 20 |
| Piso eletrificado | Contínuo enquanto energizado; desligável | 8/s |
| Gelo fino | Quebra 0,5 s depois de pisar | — |
| Vácuo (Docas) | Sem gravidade | 4 Integridade/s |
| Escuridão total | Sem lanterna o jogador não vê buracos | Mata por queda; na Estufa, fase de aprendizado, a queda só devolve o MU-7 ao andar de baixo ([AJ-015](#gdd-ajustes)) |

<a id="gdd-2-6-2-f"></a>
#### F) Efeitos de status (todos com ícone no HUD)

| Status | Origem (clima) | Efeito | Duração |
|---|---|---|---|
| SUPERAQUECIMENTO | Verão | −3 Integridade/s e Carga drena 2× mais rápido | enquanto exposto |
| CONGELAMENTO | Inverno | Velocidade −50%, pulo −30%, chão escorregadio | enquanto exposto |
| CORROSÃO | Primavera | Impede recarga de Carga | 6 s |
| DESCARGA | Elétrico | Bloqueia dash, feixe e propulsor | 3 s |
| SOBRECARGA (buff) | Recarga total | +30% velocidade | 10 s |

<a id="gdd-2-6-2-g"></a>
#### G) Mini boss: "O SERRALHEIRO" — fim das Docas

Sistema de contenção automática: braço robótico industrial gigante que sela portas. Não ataca diretamente: **tranca o cenário** (fecha comportas, corta rotas) e solta SR-3 sem parar. **Como vencer:** alimentar **3 acopladores de energia** enquanto ele fecha o setor, com o tempo apertando. **Peso narrativo:** é a mesma máquina que executou a ordem que matou as 40 pessoas.

<a id="gdd-2-6-2-h"></a>
#### H) Grande Provação / Boss: "PROTOCOLO LUTO" — Núcleo de Memória

O firewall que ÓRBITA instalou nela mesma. Arena = reconstrução da estação cheia de gente, em cores vivas, sendo **apagada em tempo real** (plataformas somem conforme o jogador avança).

| Fase | Descrição |
|---|---|
| 1 | Fuga vertical enquanto o chão some |
| 2 | Puzzle de energia sob pressão; o firewall troca os cabos que você acabou de ligar |
| 3 | O log final toca inteiro; o jogador só precisa **continuar andando** enquanto o jogo tenta empurrá-lo para trás |

Boss de informação: o dano que ele causa é a memória voltando.

<a id="gdd-2-6-2-i"></a>
#### I) Batalha final: "ARGOS" — Núcleo do Reator

Três torres CX-2 blindadas em volta de um núcleo instável, plataformas que sobem e descem pelo calor. **Como vencer:** sobrecarregar os 3 acopladores com o Acesso Root, sob **timer de 90 s** e dano ambiental de Verão constante. Exige todas as habilidades (garras, dissipador, propulsor, feixe, dash).

<a id="gdd-2-6-3"></a>
### GDD-2.6.3 Itens e coletáveis

| Item | Tipo | Efeito | Quantidade |
|---|---|---|---|
| Célula de Energia | Comum | +40 Carga instantâneo | Espalhada |
| Kit de Solda | Comum | +25 Integridade | Raro nas fases |
| Núcleo de Capacitor | Upgrade | +25 Carga **máxima** permanente | 4 no jogo, escondidos fora da rota principal |
| Placa de Blindagem | Upgrade | +25 Integridade **máxima** permanente | 4 no jogo |
| Fragmento de Log | Narrativa | História; cada log lido = +0,5% Estabilidade. **Poucos e longos** (10–11 linhas cada), lidos em terminais de registro, corpos e objetos ([AJ-024](#gdd-ajustes)) | 12 no total, 2 por fase (0–5) ([AJ-044](#gdd-ajustes)) |
| Dado de Pesquisa | Chave | Não afeta gameplay; afeta o **epílogo** (mais dados = final mais específico e confiante) | 12 no total, 2 por fase (0–5) ([AJ-044](#gdd-ajustes)) |
| Chave de Acesso | Progressão | Libera portas seladas do setor | 1 por setor |
| Área secreta | Exploração | Parede falsa que fica **translúcida** ao ser revelada ([AJ-016](#gdd-ajustes)) e esconde upgrades opcionais | 4 no jogo |

A primeira coleta de cada tipo mostra no HUD o nome e a função do item ([AJ-023](#gdd-ajustes)). Os contadores ficam no Terminal do Chassi e nas estatísticas finais, não na tela de jogo.

<a id="gdd-2-6-4"></a>
### GDD-2.6.4 Objetos do mundo

Cada objeto tem uma silhueta que diz o que ele faz. Porta, doca e portal **não** compartilham vocabulário visual ([AJ-038](#gdd-ajustes)).

| Objeto | Leitura visual | Função |
|---|---|---|
| **Terminal de Distribuição** | Console com tela | Abre a interface de energia do setor |
| **Nó do setor** | Console maior, variante do terminal | `RELIGAR NÓ DO SETOR`: religa o setor, salva o jogo e devolve +15% de Estabilidade |
| **Comporta** (porta) | Batente fixo, duas folhas que recolhem para cima e para baixo, vigias redondas, faixa de perigo âmbar | Ligada a um sistema. **Aberta vira vão transparente**: luz acesa nunca significa barreira. Fecha o espaço até o teto com uma antepara sólida, para que nenhum pulo passe por cima |
| **Doca de Backup** | A única cápsula de vidro do jogo | Checkpoint por contato: recarrega Carga, repara Integridade e guarda o backup |
| **Portal de saída** | Túnel em perspectiva com luz vindo de dentro e placa do setor, sem faixa de perigo | Leva ao próximo setor |
| **Planta que cresce** | Broto → trepadeira em seis estágios | Com a luz de crescimento ligada, vira plataforma (topo a 4 tiles do pé: precisa de patamar de embarque) |
| **Plataforma móvel / elevador de carga** | Plataforma industrial | Anda num trilho enquanto o sistema dela está ligado; o elevador de carga é mais rápido |
| **Parede magnética** | Placas âmbar com brilho próprio, legíveis sem lanterna | Escalável com as Garras Magnéticas |
| **Parede falsa** | Igual à parede comum | Fica translúcida ao toque e revela uma área secreta |
| **Terminal de registro / objeto com log** | Terminal pequeno, corpo, traje, objeto pessoal | `[E]` abre um Fragmento de Log |
| **Lâmpada energizada** | Luminária de teto | Acende com o sistema de iluminação; a luz é informação de que há energia ali |

<a id="gdd-2-6-5"></a>
### GDD-2.6.5 Personagens

Ninguém vivo aparece no jogo. Toda voz é IA, gravação ou sistema.

| Personagem | Papel | Como aparece |
|---|---|---|
| **ÓRBITA** | Protagonista, a IA de manutenção da ARTEMIS | Falas legendadas em ciano; otimista e educada, perde a calma conforme o jogo avança |
| **MU-7** | O corpo da ÓRBITA | Chassi de manutenção bípede, enferrujado, 32×32 px |
| **Dra. Helena Vasquez** | Mentora, Engenheira Chefe | Só existe em logs gravados. Na caixa de log aparece com **retrato animado de 6 expressões** (neutra, cansada, preocupada, sorriso, emocionada, determinada), escolhida fala a fala, com a boca acompanhando o texto ([AJ-039](#gdd-ajustes)). Nome em âmbar e áudio de fita degradada |
| **BOTÂNICO 04** | Aliado | Drone de irrigação que segue a ÓRBITA pela Estufa e ilumina caminhos |
| **ARTEMIS** | A estação | Voz neutra do sistema: alarmes e mensagens de manutenção, em cinza |
| **A tripulação (40 pessoas)** | Ausência | Corpos, objetos pessoais e os 40 nomes que fecham os dois finais |

---

<a id="gdd-2-7"></a>
## GDD-2.7 Level design

<a id="gdd-2-7-mapa"></a>
### Estrutura geral: hub radial

O **Núcleo Central** fica no meio; os setores são anéis e corredores saindo dele. O jogador sempre volta ao centro e, a cada volta, o centro está mais iluminado — o progresso é visível no cenário.

A estação **não é um corredor** ([AJ-027](#gdd-ajustes)). Os setores se ligam por portas de mão dupla, que preservam o estado de cada setor (energia, coletados, backup). Religar um setor reabre caminhos e cria puzzles que atravessam setores.

```
                         [ NÚCLEO DO REATOR ]
                          (Batalha Final)
                                 |
        [ ENFERMARIA ] --- [ NÚCLEO CENTRAL ] --- [ LABORATÓRIO ]
           (Inverno)          (HUB / save)            (Verão)
                            /            \
                    [ ESTUFA ]            [ DOCAS ]
                    (Primavera)          (Vácuo / 0g)
                                 |
                        [ NÚCLEO DE MEMÓRIA ]
                          (Grande Provação)
```

<a id="gdd-2-7-fases"></a>
### Fases

| Fase | Nome | Clima | Duração | Dificuldade | Introduz | Upgrade |
|---|---|---|---|---|---|---|
| 0 | [Núcleo Central](#gdd-2-7-f0) | — | ~5 min | 1/10 | andar, pular, descer de plataforma, interagir, Terminal do Chassi, lanterna, ler log, terminal 3 sistemas/1 energia, primeira SR-3 | — |
| 1 | [Estufa](#gdd-2-7-f1) | Primavera | ~10 min | 3/10 | Esporos, planta que cresce, plataformas de carga, parede magnética, parkour, duas rotas | Garras Magnéticas |
| 2 | [Laboratório](#gdd-2-7-f2) | Verão | ~12 min | 5/10 | CX-2, Superaquecimento | Dissipador Térmico |
| 3 | [Enfermaria](#gdd-2-7-f3) | Inverno | ~12 min | 6/10 | V-9, Congelamento, dilema da lanterna | Núcleo Aquecido |
| 4 | [Docas](#gdd-2-7-f4) | Vácuo | ~15 min | 8/10 | todos os inimigos + vácuo + Serralheiro | Propulsor |
| 5 | [Núcleo de Memória](#gdd-2-7-f5) | — | ~8 min | 7/10 | Protocolo Luto | Acesso Root |
| 6 | [Núcleo do Reator](#gdd-2-7-f6) | Verão extremo | ~7 min | 9/10 → 0/10 | ARGOS + escolha final | — |

<a id="gdd-2-7-f0"></a>
#### Fase 0 — Núcleo Central (tutorial)
Antes da fase, uma tela de **briefing** em formato de boot do MU-7 apresenta a estação, a IA, o chassi, o reator morrendo e a regra de energia. O Núcleo é um corredor iluminado e é um **tutorial explícito**: cada controle é ensinado por um **cartão de tecla** (`MOVER`, `PAUSA E OPÇÕES`, `PULAR`, `DESCER DA PLATAFORMA`, `INTERAGIR`, `TERMINAL DO CHASSI`, `LANTERNA`, `TERMINAL DE DISTRIBUIÇÃO`; na Estufa, `ESCALAR A PAREDE AMARELA`) e logo em seguida vem um obstáculo que obriga a usá-lo ([AJ-025](#gdd-ajustes)). O primeiro Terminal de Distribuição tem **3 sistemas e 1 energia**: iluminação, elevador (opcional, leva a um Dado de Pesquisa) e a porta do Setor Habitacional. Ele ensina que energia não é um estado, é uma sequência de escolhas.

Atrás da porta fica o **Setor Habitacional** ([AJ-041](#gdd-ajustes)), onde a tripulação vivia: luz de emergência, o traje da Helena com o primeiro log, um Kit de Solda e a **primeira SR-3**. É a Travessia do Limiar da Jornada: o primeiro corpo e o primeiro inimigo, antes do portal para a Estufa. O núcleo do tutorial continua sem dano possível.

<a id="gdd-2-7-f1"></a>
#### Fase 1 — Estufa (Primavera)
Vertical, cheia de vegetação, plataformas de terra e trepadeiras. Clima ameno, quase bonito. Mapa de **48×64 tiles em seis zonas**, com duas rotas que convergem na copa ([AJ-033](#gdd-ajustes)):

- **Rota botânica:** ligar a luz de crescimento do canteiro (e depois a da copa) faz as trepadeiras crescerem e virarem plataforma, mas apaga o corredor.
- **Rota de carga:** manter o aquecimento ligado alimenta a linha de carga (elevador e gôndola), mas os Enxames de Esporos crescem com o calor.

O terminal tem **6 sistemas / 2 energias com duas cadeias de dependência**, e cada cadeia consome o orçamento inteiro. No meio do caminho, o log da Helena instala as **Garras Magnéticas**, e a parede magnética âmbar abre o trecho final até o Nó. Entram 3 SR-3, 5 focos de esporo, 2 trepadeiras, 2 plataformas móveis, trechos de parkour e 2 áreas secretas. Os simuladores climáticos ainda funcionam, presos em ciclos quebrados de Primavera/Verão/Inverno. Aliado: **BOTÂNICO 04**, drone de irrigação que segue ÓRBITA e ilumina caminhos. É a fase em que o jogador tem permissão de errar. Upgrade: **Garras Magnéticas**.

<a id="gdd-2-7-f2"></a>
#### Fase 2 — Laboratório (Verão)
Corredores retos e brancos, refrigeração quebrada. Zonas de SUPERAQUECIMENTO obrigam a correr entre "ilhas frias". Introduz a CX-2 e o conceito de que desligar a energia do inimigo é melhor que enfrentá-lo. Puzzle central: refrigeração e porta usam a mesma linha de energia. Upgrade: **Dissipador Térmico**.

<a id="gdd-2-7-f3"></a>
#### Fase 3 — Enfermaria (Inverno)
Escura, estreita, congelada. Exploração lenta de propósito (CONGELAMENTO + gelo escorregadio) enquanto o timer corre. Introduz a V-9 e o dilema da lanterna. Carga narrativa mais pesada: os leitos mostram a ordem em que a tripulação adoeceu. Upgrade: **Núcleo Aquecido**.

<a id="gdd-2-7-f4"></a>
#### Fase 4 — Docas (Vácuo)
Aberta, sem gravidade em vários trechos, espaço visível ao fundo. Combina todos os inimigos anteriores; dano contínuo de vácuo transforma cada travessia numa corrida. Termina no mini boss **O Serralheiro**. Upgrade: **Propulsor**.

<a id="gdd-2-7-f5"></a>
#### Fase 5 — Núcleo de Memória (Grande Provação)
Quebra visual total: cores saturadas, estação cheia de gente, música limpa. A fase se desmonta enquanto o jogador anda. Poucos inimigos, muita pressão; o pico é emocional. Recompensa: **Acesso Root**.

<a id="gdd-2-7-f6"></a>
#### Fase 6 — Núcleo do Reator (Batalha Final)
Arena vertical única contra ARGOS, timer de 90 s e calor extremo. Depois: sala do terminal, silêncio total, duas alavancas, nenhuma música. A última decisão não tem desafio mecânico — o peso é a escolha.

<a id="gdd-2-7-curva"></a>
### Curva de dificuldade

`1 - 3 - 5 - [queda: upgrade] - 6 - 8 - [queda: upgrade] - 7 - 9 - fim`

Toda vez que a dificuldade sobe demais, o jogador ganha um upgrade que faz o conteúdo antigo ficar fácil ("eu fiquei mais forte" sem mexer em número de ataque).

**Como a dificuldade aumenta (3 eixos, nunca todos ao mesmo tempo):**
1. **Densidade:** mais inimigos e mais tipos combinados no mesmo trecho.
2. **Ambiente:** o clima passa a causar dano ativo (Primavera → Verão → Inverno → Vácuo).
3. **Complexidade do puzzle:** de 3 sistemas / 1 energia (tutorial) até 6 sistemas / 3 energias com dependência em cadeia (Docas).

---

<a id="gdd-2-8"></a>
## GDD-2.8 Interface de usuário (UI / HUD)

<a id="gdd-2-8-hud"></a>
### HUD em jogo (minimalista e diegético — parece leitura de sensor do chassi)

```
+----------------------------------------------------------------+
| [||||] INTEGRIDADE                            OBJETIVO:        |
| [======----] CARGA                    Religar o Nó da Estufa   |
|  (ícones de status)                                            |
|                                                                |
|                          (gameplay)                            |
|                                                                |
|                                                                |
|                    [E] ACESSAR TERMINAL                        |
+----------------------------------------------------------------+
```

| Região | Conteúdo |
|---|---|
| Superior esquerdo | Integridade em 4 células (célula vazia fica vermelha piscando); Carga azul abaixo, com marcação do custo da próxima habilidade; ícones de status com contador regressivo |
| Topo centro | **Vazio em jogo normal.** O bloco do reator só aparece **em estado crítico** (abaixo de `REACTOR_CRITICAL`), em vermelho pulsante com `CRÍTICO`. Fora disso a estabilidade se lê no Terminal do Chassi ([AJ-028](#gdd-ajustes)) — esconder um cronômetro que está matando o jogador seria injusto, por isso a exceção |
| Inferior direito | **Vazio.** Os contadores de Fragmento de Log e Dado de Pesquisa migraram para o Terminal do Chassi (`[TAB]`) e continuam na tela de FIM DA DEMO ([AJ-028](#gdd-ajustes)) |
| Superior direito | **Um** objetivo por fase, com o rótulo `OBJETIVO:` acima do texto, alinhado à direita. Ele é definido quando a fase carrega e **não muda até a fase terminar** ([AJ-026](#gdd-ajustes)) |
| Centro inferior | Prompt de interação contextual (`[E] ACESSAR TERMINAL`) e, na fase tutorial, o cartão de tecla da vez ([AJ-025](#gdd-ajustes)) |
| Legendas | Falas da ÓRBITA e logs da Helena na parte de baixo, com o nome de quem fala na cor do personagem (ÓRBITA ciano, Helena âmbar, ARTEMIS cinza) e, nos logs da Helena, o retrato com a expressão da fala ([AJ-039](#gdd-ajustes)). Sempre legendado |
| Avisos | Faixa curta que desliza no HUD: `BACKUP SALVO`, primeira coleta de cada item, habilidade instalada |

<a id="gdd-2-8-telas"></a>
### Telas

| # | Tela | Conteúdo |
|---|---|---|
| 1 | Splash | Logo do jogo sobre fundo escuro |
| 2 | Carregamento | Nome do setor, os sistemas da estação religando um a um e uma dica sorteada ([AJ-017](#gdd-ajustes)) |
| 3 | Tela inicial | Ilustração da ARTEMIS em órbita (silhueta da estação, planeta, lua e nebulosa) com o logo e **trilha ambiente** ([AJ-036](#gdd-ajustes)). **CONTINUAR / NOVO SISTEMA / OPÇÕES / SAIR** ([AJ-040](#gdd-ajustes)). `NOVO SISTEMA` pede confirmação antes de sobrescrever o backup; save ilegível avisa `BACKUP CORROMPIDO` |
| 4 | Briefing | Boot do MU-7 entre o menu e a Fase 0: registro da estação, quem é você, situação, regra de energia, objetivo ([AJ-025](#gdd-ajustes)) |
| 5 | Opções | Volume **GERAL / MÚSICA / EFEITOS / VOZ**, **DIFICULDADE** (Fácil/Normal/Difícil, [AJ-003](#gdd-ajustes)), **MODO SEM TIMER** (desliga a queda do reator), **TELA CHEIA**. Remapeamento de teclas, tamanho de legenda e modo daltônico completam a tela no jogo completo. Abre do menu e do pause |
| 6 | Pause (ESC) | **RETOMAR / OPÇÕES / RECOMEÇAR** (do último backup ou do início) **/ SAIR PARA O MENU**, com painel de **CONTROLES** ao lado ([AJ-040](#gdd-ajustes)). Congela o timer do reator |
| 7 | Terminal de Distribuição | Lista de sistemas com `LIGADO`/`DESLIGADO`, `ORÇAMENTO DE ENERGIA x/y`, `REQUER` e `DESLIGADO EM CADEIA`; linha `META` só no tutorial ([AJ-042](#gdd-ajustes)) |
| 8 | Terminal do Chassi (TAB) | `TERMINAL DO CHASSI MU-7`: estabilidade do reator, Integridade e Carga exatas, Fragmentos de Log e Dados de Pesquisa, habilidades instaladas e o **Mapa da Estação** ([AJ-028](#gdd-ajustes)) |
| 9 | Mapa da Estação (no Terminal do Chassi) | Planta técnica. Setores religados brancos, sem energia cinza, portas seladas com cadeado. Fica `SEM ENERGIA` até o primeiro setor religar o mapa |
| 10 | Arquivo de Logs (L) | Codex por setor e por autor. Reler um log toca o áudio de novo |
| 11 | Derrota (chassi) | Fundo preto, texto monoespaçado `SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP` + `CUSTO: -3% DE ESTABILIDADE` + `[E] CONTINUAR` |
| 12 | Game Over (reator) | `PERDA DE ÓRBITA - MISSÃO ENCERRADA` + tempo em órbita + número de logs que o jogador nunca vai ler. Opções: **CARREGAR ÚLTIMO SETOR** e **MENU PRINCIPAL** |
| 13 | Vitória | Sem "You Win". Corta no instante da escolha → epílogo em texto (varia com os Dados coletados) → lista dos 40 nomes → estatísticas (tempo, logs, dados, mortes, segredos) → *"VOCÊ ESCOLHERIA DE NOVO?"*. Na Demo, a tela **FIM DA DEMO** faz esse papel com as mesmas estatísticas ([AJ-004](#gdd-ajustes)) |

---

<a id="gdd-2-9"></a>
## GDD-2.9 Estética (arte e áudio)

<a id="gdd-2-9-visual"></a>
### Estilo visual

- **Pixel art** em resolução interna **384×216**, escalada por número inteiro para 1920×1080 (pixel nítido, sem borrão).
- Sprites do chassi **32×32 px**. Animação econômica: 4 a 6 frames por ação, com peso e leve atraso, para o MU-7 parecer pesado e velho.
- **Regra de iluminação (pilar visual):** a estação é escura por padrão. A luz não é decoração, é informação. Onde tem luz, tem energia; onde tem energia, algo está funcionando (para o bem ou para o mal). `CanvasModulate` + `PointLight2D` para a lanterna e as fontes de luz.
- **A escuridão é real** ([AJ-030](#gdd-ajustes)): ambiente quase preto (`#0D1219`); longe de uma lâmpada e sem lanterna o cenário some. O MU-7 tem um sensor fraco sempre aceso e a lanterna, mais forte, gasta Carga. As sombras saem do **contorno de cada bloco sólido**, nunca de cada tile, então a face iluminada de um bloco nunca fica escura ([AJ-037](#gdd-ajustes)).
- **Profundidade só por parallax 2D:** três camadas de espaço ao fundo (estrelas distantes; planeta-alvo e nebulosa; destroços próximos), cada uma rolando numa velocidade diferente.
- **Atmosfera:** partículas de poeira flutuando, vinheta escura nas bordas, tremor de câmera curto no dano e na aterrissagem, clarão ao religar um setor.
- **Fonte pixel única** (m5x7) para toda a interface, sempre em múltiplos de 16 px.
- **Produção de arte:** sprites, tilesets, fundos, retratos e logo gerados com Gemini / Nano Banana Pro a partir de uma imagem de referência de estilo, para que tudo pareça do mesmo jogo. Plataforma móvel e partículas vêm de pacotes Kenney (CC0).
- **Direção de arte em uma frase:** *uma estação bonita que ninguém está usando.* Nada de sangue ou monstro; o horror é o cotidiano interrompido — uma caneca flutuando, uma cadeira virada, uma foto colada no armário.

<a id="gdd-2-9-paleta"></a>
### Paleta por setor

| Setor | Paleta |
|---|---|
| Núcleo Central | Azul frio esverdeado, luz estável, quase acolhedor |
| Estufa | Verde musgo + rosa das flores; única área "viva" do jogo |
| Laboratório | Branco clínico virando laranja/vermelho no superaquecimento |
| Enfermaria | Ciano pálido, branco de gelo, sombras longas e azuis |
| Docas | Preto do espaço + amarelo de sinalização de perigo |
| Núcleo de Memória | Explosão de cor saturada e quente que vai dessaturando até o cinza |
| Reator | Vermelho e branco estourado, tela tremendo |

<a id="gdd-2-9-musica"></a>
### Áudio — música

- Ambiente eletrônico minimalista (drones longos, poucos instrumentos).
- **Uma trilha por lugar:** menu (drone grave, pad lento, estática ao longe, sem melodia cantável — [AJ-036](#gdd-ajustes)), Núcleo Central e uma por setor.
- **Trilha por momento** ([AJ-034](#gdd-ajustes)): chassi perdido, perda de órbita e setor religado têm **toques únicos** que tomam o lugar da trilha e devolvem a música da fase ao acabar.
- **Adaptativa por camadas:** cada setor religado adiciona um instrumento à trilha do Núcleo Central.
- Estabilidade < 25%: entra uma **camada de tensão** (percussão grave, ritmo acelerado) somando por cima da trilha da fase, até o reator sair do estado crítico.
- Núcleo de Memória: única trilha com melodia limpa (piano).
- Sala da escolha final: **silêncio absoluto**, só o zumbido do reator.

<a id="gdd-2-9-sfx"></a>
### Áudio — efeitos sonoros

| Evento | Som |
|---|---|
| Passos | Metálico, pesado, com variações sorteadas para não repetir; muda com o piso (grade, gelo, vidro, terra da estufa) |
| Comporta | Pistão abrindo/fechando, três variações cada |
| Garras | Engate magnético ao agarrar a parede |
| Planta crescendo | Estalo orgânico de crescimento |
| Setor religado | Subida de energia que acompanha a cutscene |
| Pulo / aterrissagem | Servo hidráulico + impacto pesado |
| Dash | Pulso magnético curto e agudo |
| Feixe de Manutenção | Chiado elétrico + inimigo desligando com "gemido" descendente (coisa dormindo, não explosão) |
| Coleta de log | Beep suave de arquivo aberto |
| Terminal de energia | Clique de disjuntor + a sala inteira mudando de som |
| Dano | Alarme curto + estática no áudio geral |
| Integridade baixa | Batimento eletrônico lento e constante |
| Lanterna | Clique + zumbido contínuo baixinho |
| Sem gravidade | Todos os sons abafados (low-pass); só o interno do chassi nítido |
| Voz da ÓRBITA | Sintetizada, calma e educada, perdendo a calma conforme o jogo avança |
| Logs da Helena | Áudio degradado, chiado de fita velha e cortes |

---

<a id="gdd-2-10"></a>
## GDD-2.10 Escopo e rastreabilidade de requisitos (documento original)

| Requisito (1º bimestre) | Onde está |
|---|---|
| Plataforma 2D | [GDD-2.2](#gdd-2-2) |
| Movimentação | Andar, pular, dash, escalar, propulsor — [GDD-2.4](#gdd-2-4) |
| Barra de vida | Integridade 100 pts / 4 células — [GDD-2.6.1](#gdd-2-6-1) |
| Timer | Estabilidade do Reator — [GDD-2.5](#gdd-2-5-timer) |

| Requisito (2º bimestre) | Onde está |
|---|---|
| Fases | 6 fases + tutorial — [GDD-2.7](#gdd-2-7) |
| Troca de fases | Hub radial com portas gated por upgrade — [GDD-2.7](#gdd-2-7-mapa) |
| Efeito de status | 5 status — [GDD-2.6.2-F](#gdd-2-6-2-f) |
| Inimigos | 4 tipos + ambientais + mini boss + boss + final — [GDD-2.6.2](#gdd-2-6-2) |
| Tema: Estação | Estação espacial ARTEMIS |
| Clima: Verão/Inverno/Primavera | Laboratório / Enfermaria / Estufa |

<a id="gdd-2-10-cortes"></a>
### Cortes planejados no jogo completo (nesta ordem)

1. Upgrades opcionais (Núcleo de Capacitor / Placa de Blindagem)
2. Música adaptativa por camadas (usar trilha fixa por setor)
3. Mini boss "O Serralheiro"
4. Variação de epílogo por Dados de Pesquisa (manter os 2 finais sem variação)
5. Setor Docas (fundir o Propulsor no Núcleo de Memória)

**NUNCA CORTAR:** o Terminal de Distribuição de Energia. Ele é o jogo.

---

<a id="gdd-p"></a>
## GDD-P Parâmetros numéricos (tuning canônico)

> Fonte única dos números. O código espelha esta tabela **1:1** em `res://scripts/core/balance.gd` (mesmos nomes de constante). Alterou aqui → altere lá → registre em [Ajustes](#gdd-ajustes).

| Constante (`Balance.`) | Valor | Unidade | Origem |
|---|---|---|---|
| `TILE_SIZE` | 16 | px | AJ-001 |
| `INTEGRITY_MAX` | 100 | pts | 2.6.1 |
| `INTEGRITY_CELLS` | 4 | células | 2.6.1 |
| `CHARGE_MAX` | 100 | pts | 2.6.1 |
| `CHARGE_DOCK_REGEN` | 5 | pts/s | 2.6.1 |
| `WALK_SPEED` | 110 | px/s | 2.6.1 |
| `DASH_SPEED` | 320 | px/s | 2.6.1 |
| `DASH_TIME` | 0.25 | s | 2.6.1 |
| `DASH_COST` | 20 | Carga | 2.4 |
| `DASH_COOLDOWN` | 1.0 | s | 2.4 |
| `JUMP_HEIGHT` | 40 | px | AJ-001 (2,5 tiles) |
| `GRAVITY` | 980 | px/s² | 2.6.1 |
| `DOUBLE_JUMP_COST` | 15 | Carga | 2.4 |
| `BEAM_COST` | 25 | Carga | 2.4 |
| `BEAM_SHUTDOWN_TIME` | 4.0 | s | 2.4 |
| `FLASHLIGHT_DRAIN` | 1 | Carga/s | 2.4 |
| `VISION_RADIUS_OFF` | 48 | px | 3 m (AJ-002) |
| `VISION_RADIUS_ON` | 128 | px | 8 m (AJ-002) |
| `REACTOR_START` | 100 | % | 2.5 |
| `REACTOR_DECAY_INTERVAL` | 90 | s por 1% | 2.5 |
| `REACTOR_SECTOR_BONUS` | 15 | % | 2.5 |
| `REACTOR_LOG_BONUS` | 0.5 | % | 2.6.3 |
| `REACTOR_DEATH_PENALTY` | 3 | % | 2.5 |
| `REACTOR_CRITICAL` | 25 | % | 2.8 |
| `RESPAWN_INTEGRITY_RATIO` | 0.5 | fração | 2.5 |
| `SR3_CONTACT_DAMAGE` | 10 | pts | 2.6.2-A |
| `SPORE_DPS` | 5 | pts/s | 2.6.2-D |
| `CORROSION_TIME` | 6.0 | s | 2.6.2-F |
| `STEAM_DAMAGE` | 20 | pts | 2.6.2-E |
| `STEAM_ON_TIME` | 3.0 | s | 2.6.2-E |
| `STEAM_OFF_TIME` | 2.0 | s | 2.6.2-E |
| `ELECTRIC_FLOOR_DPS` | 8 | pts/s | 2.6.2-E |
| `ENERGY_CELL_CHARGE` | 40 | Carga | 2.6.3 |
| `REPAIR_KIT_INTEGRITY` | 25 | pts | 2.6.3 |
| `CAPACITOR_BONUS` | 25 | Carga máx. | 2.6.3 |
| `LOGS_TOTAL` | 4 | un. | AJ-024 |
| `RESEARCH_TOTAL` | 4 | un. | AJ-024 |
| `DIFFICULTY_DAMAGE_MULT` | {easy: 0.5, normal: 1.0, hard: 1.5} | fator | AJ-003 |
| `DIFFICULTY_REACTOR_MULT` | {easy: 0.5, normal: 1.0, hard: 1.5} | fator | AJ-003 |
| `RESPAWN_CHARGE_RATIO` | 1.0 | fração | AJ-006 |
| `DOCK_REPAIR_RATE` | 10 | Integridade/s | AJ-006 |
| `INTERACT_RANGE` | 20 | px | AJ-006 |
| `DEATH_DELAY` | 1.2 | s | AJ-006 |
| `SCENE_FADE_TIME` | 0.4 | s | AJ-006 |
| `LOADING_MIN_TIME` | 1.6 | s | AJ-017 |
| `SPLASH_TIME` | 2.5 | s | AJ-006 |
| `MUSIC_FADE_TIME` | 1.5 | s | AJ-006 |
| `CAMERA_SMOOTHING` | 5.0 | fator | AJ-006 |
| `CAMERA_LOOK_AHEAD` | 24 | px | AJ-006 |
| `COYOTE_TIME` | 0.12 | s | AJ-006 |
| `JUMP_BUFFER` | 0.12 | s | AJ-006 |
| `INVULNERABLE_TIME` | 0.8 | s | AJ-006 |
| `KNOCKBACK_SPEED` | 140 | px/s | AJ-006 |
| `CLAW_CLIMB_SPEED` | 70 | px/s | AJ-006 |
| `CLAW_JUMP_PUSH` | 90 | px/s | AJ-006 |
| `SPORE_RADIUS` | 24 | px | AJ-006 |
| `SPORE_RADIUS_HEATED` | 48 | px | AJ-006 |
| `SPORE_EXPAND_TIME` | 2.0 | s | AJ-006 |
| `STATUS_EXPOSURE_GRACE` | 0.3 | s | AJ-006 |
| `PLATFORM_SPEED` | 40 | px/s | AJ-006 |
| `PLANT_GROW_TIME` | 2.0 | s | AJ-006 |
| `CAMERA_LOOK_AHEAD_SPEED` | 4.0 | fator | AJ-018 |
| `CAMERA_OFFSET_Y` | -16.0 | px | AJ-018 |
| `JUMP_CUT_MULTIPLIER` | 0.5 | fator | AJ-018 |
| `MAX_FALL_SPEED` | 400.0 | px/s | AJ-018 |
| `WALK_ACCEL` | 900.0 | px/s² | AJ-018 |
| `WALK_DECEL` | 1200.0 | px/s² | AJ-018 |
| `AIR_ACCEL_RATIO` | 0.7 | fator | AJ-018 |
| `DROP_THROUGH_TIME` | 0.2 | s | AJ-018 |
| `REACTOR_ALARM_INTERVAL` | 4.0 | s | AJ-019 |
| `HUD_TOAST_TIME` | 2.0 | s | AJ-019 |
| `HUD_PULSE_HZ` | 2.0 | Hz | AJ-019 |
| `LOW_INTEGRITY_BEEP_INTERVAL` | 1.5 | s | AJ-019 |
| `LIGHT_FADE_TIME` | 0.15 | s | AJ-020 |
| `LAMP_COLOR` | Color("bfe6ff") | cor | AJ-020 |
| `FLASHLIGHT_COLOR` | Color("cfeaf2") | cor | AJ-020 |
| `DIALOGUE_CPS` | 55.0 | car/s | AJ-031 |
| `DIALOGUE_READ_CPS` | 45.0 | car/s | AJ-031 |
| `DIALOGUE_AMBIENT_MIN_TIME` | 1.6 | s | AJ-031 |
| `CUTSCENE_CAMERA_SPEED` | 220.0 | px/s | AJ-032 |
| `CUTSCENE_TRAVEL_MIN_TIME` | 3.0 | s | AJ-032 |
| `CUTSCENE_TRAVEL_MAX_TIME` | 7.0 | s | AJ-032 |
| `CUTSCENE_HOLD_START_TIME` | 0.8 | s | AJ-032 |
| `CUTSCENE_HOLD_END_TIME` | 1.0 | s | AJ-032 |
| `CUTSCENE_RETURN_TIME` | 1.2 | s | AJ-032 |
| `CUTSCENE_WAYPOINT_SPACING` | 96.0 | px | AJ-032 |
| `CUTSCENE_WAYPOINT_LIMIT` | 8 | un. | AJ-032 |
| `CUTSCENE_SKIP_ARM_TIME` | 0.4 | s | AJ-032 |
| `CUTSCENE_REVEAL_HALF_SIZE` | Vector2(144, 88) | px | AJ-032 |
| `FREIGHT_LIFT_SPEED` | 90.0 | px/s | AJ-033 |
| `MAGNETIC_GLOW_RADIUS` | 18.0 | px | AJ-033 |
| `MAGNETIC_GLOW_ENERGY` | 0.55 | energia | AJ-033 |
| `MAGNETIC_SELF_LIGHT` | 1.6 | fator | AJ-033 |
| `MAGNETIC_GLOW_COLOR` | Color("e8b93a") | cor | AJ-033 |
| `MAGNETIC_GLOW_SEGMENT_TILES` | 6 | tiles | AJ-035 |
| `MAGNETIC_GLOW_SEGMENT_OVERLAP` | 1.0 | tiles | AJ-035 |
| `MAGNETIC_GLOW_MERGE_GAIN` | 1.8 | fator | AJ-035 |
| `MUSIC_ONE_SHOT_FADE_TIME` | 0.35 | s | AJ-034 |
| `MUSIC_LAYER_FADE_TIME` | 2.5 | s | AJ-034 |
| `MUSIC_LAYER_GAIN_DB` | -6.0 | dB | AJ-034 |
| `FLASHLIGHT_ENERGY` | 1.5 | energia | AJ-030 |
| `SENSOR_ENERGY` | 0.7 | energia | AJ-030 |
| `SHADOW_FILTER_SMOOTH` | 1.5 | px | AJ-037 |
| `DOOR_BULKHEAD_MAX` | 48.0 | px | AJ-038 |
| `DOOR_BULKHEAD_DELAY` | 2 | quadros | AJ-038 |
| `BRIEFING_CPS` | 60.0 | car./s | AJ-025 |
| `TUTORIAL_CARD_HOLD` | 0.6 | s | AJ-025 |
| `TUTORIAL_CARD_FADE` | 0.2 | s | AJ-025 |
| `PICKUP_BOB_AMPLITUDE` | 2.0 | px | AJ-021 |
| `PICKUP_BOB_SPEED` | 2.0 | ciclos/s | AJ-021 |
| `SHAKE_TIME` | 0.25 | s | AJ-022 |
| `SHAKE_FREQUENCY` | 24.0 | Hz | AJ-022 |
| `SHAKE_DAMAGE` | 4.0 | px | AJ-022 |
| `SHAKE_LAND` | 2.0 | px | AJ-022 |
| `SHAKE_SECTOR` | 3.0 | px | AJ-022 |
| `LAND_SHAKE_SPEED` | 260.0 | px/s | AJ-022 |
| `HIT_FLASH_TIME` | 0.12 | s | AJ-022 |
| `HIT_FLASH_COLOR` | Color("fff4e0") | cor | AJ-022 |
| `LAMP_PULSE_HZ` | 0.45 | Hz | AJ-022 |
| `LAMP_PULSE_DEPTH` | 0.12 | fator | AJ-022 |
| `VIGNETTE_STRENGTH` | 0.55 | fator | AJ-022 |
| `VIGNETTE_INNER` | 0.45 | fator | AJ-022 |
| `VIGNETTE_OUTER` | 1.0 | fator | AJ-022 |
| `VIGNETTE_COLOR` | Color("06090f") | cor | AJ-022 |
| `BACKGROUND_TINT` | Color("6b7a8c") | cor | AJ-022 |
| `AMBIENT_MOTE_AMOUNT` | 28 | un. | AJ-022 |
| `AMBIENT_MOTE_LIFETIME` | 7.0 | s | AJ-022 |
| `AMBIENT_MOTE_SPEED` | 5.0 | px/s | AJ-022 |
| `AMBIENT_MOTE_RISE` | -3.0 | px/s | AJ-022 |
| `PARALLAX_FAR_SCALE` | Vector2(0.04, 0.02) | fator | AJ-022 |
| `PARALLAX_MID_SCALE` | Vector2(0.18, 0.09) | fator | AJ-022 |
| `PARALLAX_NEAR_SCALE` | Vector2(0.55, 0.28) | fator | AJ-022 |
| `PARALLAX_FAR_DIM` | 0.75 | fator | AJ-022 |
| `PARALLAX_MID_DIM` | 0.9 | fator | AJ-022 |
| `SECTOR_FLASH_TIME` | 0.12 | s | AJ-022 |
| `SECTOR_SETTLE_TIME` | 1.2 | s | AJ-022 |
| `SECTOR_FLASH_COLOR` | Color("e8f4ff") | cor | AJ-022 |
| `HUD_BAR_SLIDE_TIME` | 0.25 | s | AJ-022 |
| `HUD_CELL_LOST_TIME` | 0.35 | s | AJ-022 |
| `HUD_CELL_LOST_SCALE` | 1.5 | fator | AJ-022 |
| `HUD_TOAST_SLIDE` | 8.0 | px | AJ-022 |
| `HUD_TOAST_SLIDE_TIME` | 0.18 | s | AJ-022 |
| `MU7_FPS_IDLE` | 3.0 | — | AJ-022 |
| `MU7_FPS_WALK` | 8.0 | — | AJ-022 |
| `MU7_FPS_JUMP` | 9.0 | — | AJ-022 |
| `MU7_FPS_FALL` | 6.0 | — | AJ-022 |
| `MU7_FPS_LAND` | 10.0 | — | AJ-022 |
| `MU7_FPS_HURT` | 8.0 | — | AJ-022 |
| `MU7_FPS_INTERACT` | 6.0 | — | AJ-022 |
| `MU7_FPS_CLIMB` | 5.0 | — | AJ-022 |
| `MU7_FPS_DEATH` | 4.0 | — | AJ-022 |
| `MU7_FPS_DASH` | 12.0 | — | AJ-022 |
| `SR3_SPEED` | 40 | px/s | AJ-012 |
| `SR3_KNOCKBACK_X` | 120 | px/s | AJ-012 |
| `SR3_KNOCKBACK_Y` | 120 | px/s | AJ-012 |
| `SR3_KNOCKBACK_LOCK` | 0.15 | s | AJ-012 |
| `BEAM_RANGE` | 32 | px | AJ-012 |
| `LAMP_RADIUS` | 96 | px | AJ-030 |
| `LAMP_ENERGY` | 0.9 | fator | AJ-012 |
| `AMBIENT_DARK` | Color("0d1219") | cor | AJ-030 |
| `PLATFORM_WAIT` | 0.6 | s | AJ-012 |
| `SECRET_WALL_FADE_TIME` | 0.3 | s | AJ-012 |
| `SECRET_WALL_ALPHA` | 0.25 | alfa | AJ-012 |
| `SECRETS_TOTAL` | 4 | un. (jogo completo; 1 na demo) | AJ-012 |
| `STEAM_WARN_TIME` | 0.5 | s | AJ-012 |
| `DRONE_SPEED` | 45 | px/s | AJ-012 |
| `DRONE_WANDER_RADIUS` | 64 | px | AJ-012 |
| `DRONE_RETARGET_TIME` | 1.5 | s | AJ-012 |
| `DRONE_FOLLOW_RADIUS` | 120 | px | AJ-012 |
| `OVERHEAT_DPS` | 3 | pts/s | 2.6.2-F (Final) |
| `OVERHEAT_CHARGE_MULT` | 2.0 | fator | 2.6.2-F (Final) |
| `FREEZE_SPEED_MULT` | 0.5 | fator | 2.6.2-F (Final) |
| `FREEZE_JUMP_MULT` | 0.7 | fator | 2.6.2-F (Final) |
| `DISCHARGE_TIME` | 3.0 | s | 2.6.2-F (Final) |
| `OVERLOAD_TIME` | 10.0 | s | 2.6.2-F (Final) |
| `OVERLOAD_SPEED_MULT` | 1.3 | fator | 2.6.2-F (Final) |

<a id="gdd-p-dificuldade"></a>
### Multiplicadores de dificuldade (AJ-003)

| Dificuldade | Dano recebido | Decaimento do reator | Observação |
|---|---|---|---|
| Fácil | ×0,5 | ×0,5 | |
| Normal | ×1,0 | ×1,0 | valores do GDD |
| Difícil | ×1,5 | ×1,5 | |
| Modo sem timer | — | ×0 | opção de acessibilidade ([GDD-2.8](#gdd-2-8-telas)), combinável com qualquer dificuldade |

---

<a id="gdd-ajustes"></a>
## Ajustes de implementação (append-only)

> Toda divergência entre o design original e o jogo implementado. Uma linha por ajuste. Nunca apague; corrija com nova linha.

| ID | Data | Seção | Ajuste | Motivo |
|---|---|---|---|---|
| AJ-001 | 2026-09-19 | 2.6.1 / 2.9 | Tiles de **16 px**; pulo = 2,5 tiles = **40 px** (o original dizia "~64 px") | Consistência com resolução 384×216 e sprite de 32 px (≈ 2 tiles de altura) |
| AJ-002 | 2026-09-19 | 2.4 | 1 m = 16 px; raio de visão 3 m = 48 px, 8 m = 128 px | Conversão de metros para pixels |
| AJ-003 | 2026-09-19 | 2.8 | Adicionada **dificuldade Fácil/Normal/Difícil** além do "modo sem timer" | Critério da disciplina "Dificuldade ajustável" |
| AJ-004 | 2026-09-19 | 2.7 | Demo (1ª entrega) = Fase 0 + Fase 1 jogáveis, terminando numa tela "FIM DA DEMO" | Escopo de 30% da 1ª entrega |
| AJ-005 | 2026-09-19 | 2.2 | Jogo estritamente **2D**; itens de rubrica "3D" e "Elementos de FPS" fora de escopo | Decisão do time |
| AJ-006 | 2026-09-19 | GDD-P | Constantes de implementação que o GDD não especificava (fades, câmera, coyote/buffer, i-frames, doca, esporos, garras, plataforma, planta) fixadas na tabela GDD-P | Números necessários para implementar; ficam versionados num lugar só |
| AJ-007 | 2026-09-19 | 2.6.1 / 2.4 | **Doca de recarga ativa por contato** (não exige apertar E): entra em recarga/reparo ao parar dentro dela | GDD-2.4 lista a doca em `interact`, GDD-2.6.1 fala em "parado numa doca"; contato é mais fluido e evita prompt competindo com terminais |
| AJ-008 | 2026-09-19 | 2.5 | Diálogo tem dois modos: **bloqueante** (congela o timer, exige avançar) e **ambiente/bark** (não congela, some sozinho) | Sem isso qualquer fala da ÓRBITA pausaria o reator e o timer viraria decorativo |
| AJ-009 | 2026-09-19 | 2.5 | Respawn devolve **Carga cheia** e a doca repara 10 Integridade/s; Célula/Kit não são consumidos com o recurso cheio | Casos não previstos no GDD; evitam desperdício e travamento após morte |
| AJ-010 | 2026-09-19 | 2.5-energia | Puzzle da Estufa fixado em **5 sistemas / 2 unidades**; tutorial em 2 sistemas / 1 unidade | GDD dá exemplos diferentes (3/5 e até 6/3); a demo usa a faixa coerente com a curva da Fase 1 |
| AJ-011 | 2026-09-19 | 2.6.1 | **Garras Magnéticas entregues no meio da Estufa** (log da Helena), e não só ao religar o Nó | Sem isso a habilidade da fase só seria usável depois que a fase acaba; assim ela abre a rota final do setor |
| AJ-012 | 2026-09-19 | GDD-P | Constantes das features de mundo/inimigo/stretch (SR-3, feixe, lâmpada, escuridão ambiente, plataforma, parede secreta, vapor, drone) fixadas no GDD-P | Vieram dos ADRs locais das F22–F34; ficam num lugar só |
| AJ-013 | 2026-09-19 | 2.5 | O **timer do reator só começa a cair no alarme da Fase 0** (Jornada etapa 2), não no carregamento do jogo | O Chamado para a Aventura é o que liga o timer; antes disso o tutorial seria punido |
| AJ-014 | 2026-09-19 | 2.6.1 | Um setor pode ter **vários consoles do mesmo Terminal de Distribuição** (mesmo `terminal_id`) | A Estufa é vertical; obrigar a voltar ao mesmo console viraria backtracking puro |
| AJ-015 | 2026-09-19 | 2.6.2-E | Na **Demo**, cair num buraco no escuro devolve o MU-7 ao andar de baixo em vez de matar | GDD-2.6.2-E diz "mata por queda"; na fase de aprendizado isso pune demais e custa 3% do reator |
| AJ-016 | 2026-09-19 | 2.6.3 | Parede falsa de área secreta fica **translúcida** ao ser revelada, em vez de sumir | O jogador precisa entender que era uma parede, não um bug |
| AJ-017 | 2026-09-19 | GDD-P | `LOADING_MIN_TIME` de 0,8 s para **1,6 s** | A tela de carregamento mostra os sistemas da estação religando um a um (Jornada etapa 1); em 0,8 s ninguém lê |
| AJ-018 | 2026-09-19 | GDD-P | Constantes de sensação do plataforma (aceleração/desaceleração no chão e no ar, corte do pulo, velocidade terminal, descida de plataforma fina, deslocamento e velocidade da antecipação da câmera) | Necessárias para o movimento do MU-7 ter peso; o GDD só definia velocidade, gravidade e altura de pulo |
| AJ-019 | 2026-09-19 | GDD-P | Ritmo do alarme do reator, duração do aviso do HUD, frequência do pulso crítico e do bipe de integridade baixa | Números de feedback do HUD/áudio que o GDD descrevia só em palavras |
| AJ-020 | 2026-09-19 | GDD-P | Velocidade de digitação do diálogo, tempo mínimo de fala ambiente, cores e fade das luzes | Números de apresentação que o GDD descrevia em palavras ("legenda", "luz fria") |
| AJ-021 | 2026-09-19 | GDD-P | Amplitude e velocidade da flutuação dos coletáveis | O GDD pedia itens "flutuando" sem número |
| AJ-022 | 2026-09-20 | GDD-P | Constantes de apresentação do polimento visual (tremor de câmera, flash de dano, pulso de lâmpada, vinheta, esporos de ambiente, camadas de parallax, clarão ao religar setor, animações do HUD e cadência de cada animação do MU-7) | O GDD descrevia sensação ("pesado", "a luz é informação") sem números; a F35 precisou fixá-los |
| AJ-023 | 2026-09-20 | GDD-2.8 | HUD reorganizado para legibilidade: integridade ganha o rótulo `INTEGRIDADE`; o título do reator encurta de `ESTABILIDADE DO REATOR: nn%` para `REATOR nn%`; a terceira linha do reator deixa de ser permanente e só aparece como aviso (`TIMER PARADO` ou `CRÍTICO`); os dois contadores viram uma linha só, apagada, com o ícone repetindo a silhueta do item no chão; a primeira coleta de cada tipo mostra nome e função do item | Playtest humano: "tem muita informação visual na tela/hud. fica confuso oq é integridade, logs, dados, oq são essas coisas azuis no chao e as laranjas". Em 384 px não cabem ao mesmo tempo o título longo do reator centrado e um rótulo à direita das células |
| AJ-024 | 2026-09-20 | GDD-2.6.3 · GDD-P | A demo passa a ter **4 logs** e **4 dados** em vez de 7 e 12 espalhados: `LOGS_TOTAL` 24→4 e `RESEARCH_TOTAL` 12→4. Os logs são fundidos aos pares (`log_hab_02` entra em `log_hab_01`; `log_gh_03`+`log_gh_04` viram `log_gh_02`, que mantém o desbloqueio das garras) e crescem para 10–11 linhas cada. As falas ambientes de tutorial da ÓRBITA (`core_calib_move`, `core_calib_jump`, `core_log_hint`, `core_flashlight_hint`) são apagadas e viram cartões de tecla | Playtest humano: "muito dialogo e pouca gameplay... desbloquear fragmentos maiores da historia (menos fragmentos, com mais conteudo, só que mais dificil de encontra-los). Talvez Orbita esteja falando muito". Contador que fecha dentro da demo (4/4) também é mais legível que um 3/24 que nunca completa |
| AJ-025 | 2026-09-20 | GDD-2.7-F0 · GDD-2.8 · GDD-P | O Núcleo Central deixa de ser "uma sala que ensina por diálogo" e vira **tutorial explícito**: uma tela de briefing (boot do MU-7) entre o menu e a fase, e cartões de tecla no jogo (`tut_move`, `tut_pause`, `tut_jump`, `tut_drop`, `tut_interact`, `tut_flashlight`, `tut_terminal`, e `tut_climb` na Estufa), cada um seguido de um obstáculo que obriga a usar o controle recém-ensinado. O terminal do Núcleo passa de 2 para **3 sistemas / 1 energia** (soma `lift_core`, elevador opcional para um Dado de Pesquisa), substituindo o AJ-010 na parte do tutorial | Playtest humano: "O tutorial em si, nao está um tutorial, tá só uma fase sem entender muito" e "deveria ser mais voltado para puzzles". Ensinar por fala ambiente não funcionou: o jogador lê a fala e mesmo assim não sabe qual tecla apertar |
| AJ-026 | 2026-09-20 | GDD-2.8 | **Um objetivo por fase**, fixo, no canto superior direito com o rótulo `OBJETIVO:`. Os 11 objetivos intermediários (`obj_calibrate`, `obj_read_log`, `obj_gh_*`, …) foram removidos junto com todos os pontos que os trocavam — gatilhos de mapa, falas e scripts de fase. Restam `obj_core_hub` e `obj_greenhouse`. O bloco do reator estreitou de 176 px para 80 px para abrir espaço à direita | Playtest humano: "só deveria ter um objetivo por fase, e nao ficar mudando ele. colocar ele mais pra cima na tela". A orientação passo a passo não se perde: os controles são ensinados pelos cartões de tecla do [AJ-025](#gdd-ajustes) e a meta de cada puzzle está escrita na linha `META` do próprio Terminal de Distribuição — verificado por captura nos dois terminais antes da remoção |
| AJ-027 | 2026-09-20 | GDD-2.3 · GDD-2.7 | **A estação deixa de ser um corredor.** Os setores passam a ser ligados por portas de mão dupla, e não por saídas de sentido único: religar um setor abre caminho de volta, não fecha o anterior. A ARTEMIS vira um mapa que se reabre conforme a energia volta, com puzzles que atravessam setores. **Na demo entra só a mecânica**: a Estufa e o Núcleo Central ficam ligados nos dois sentidos, preservando estado (energia, coletados, checkpoint). Os caminhos alternativos e os puzzles entre setores ficam para a entrega final | Decisão do humano no playtest: "eu acho que nao deveria ser linear sabe? acho que as portas deveriam voltar tambem... na estufa dar pra voltar para o nucleo e tals. para depois termos possiveis caminhos, com puzzles e tals. mas acho que agora na demo vamos fazer so a mecanica de ir e voltar" |
| AJ-028 | 2026-09-20 | GDD-2.8 | **Terminal do chassi**: uma tela de diagnóstico aberta por tecla passa a guardar a estabilidade do reator, os contadores de Log e Dado, os valores exatos de Integridade e Carga, e as habilidades. O HUD em jogo fica só com integridade, carga, status, objetivo e prompt. O bloco do reator **reaparece no HUD em estado crítico** — esconder um cronômetro que está matando o jogador seria injusto. O espaço do mapa da estação fica desenhado e bloqueado (`??` / `SEM ENERGIA`), para a entrega final | Playtest: "da pra dar uma diminuida nas informações visuais da tela... um menu/inventario, onde podemos ver a porcentagem do reator, os logs/dados coletados (tirar da tela talvez)" |
| AJ-029 | 2026-09-20 | GDD-P · GDD-2.8 | Fala ambiente da ÓRBITA some mais rápido: `DIALOGUE_READ_CPS` 15,0 → 28,0, o que leva uma linha típica de **7,7 s para 5,1 s** na tela (medido quadro a quadro). Fora do tutorial a ÓRBITA para de narrar o efeito de cada sistema: as dez falas de comentário do Terminal da Estufa, mais as falas dos esporos, da trepadeira, dos vãos do corredor e o lembrete da regra de energia, são apagadas. A Estufa vai de 20 para 5 sequências | Playtest: "todos os dialogos de Orbita estao ficando muito tempo" e "é um jogo de puzzle, precisamos dar menos informações" |
| AJ-030 | 2026-09-20 | GDD-P · GDD-2.9 | **A escuridão passa a ser real.** O ambiente das fases vai de luma 0,44 para **0,068**, o tileset placeholder sobe de 0,26 para **0,62** (a compensação estava invertida: o ambiente era claro para salvar um tileset escuro), o raio das lâmpadas cai de 160 para 96 px — o que **cria** o trecho escuro do Núcleo, antes inexistente porque as lâmpadas se tocavam — e a textura radial da luz troca a queda `(1-d)²` por um platô, subindo o alfa médio de 0,167 para 0,419. A lanterna ganha duas energias: `SENSOR_ENERGY` 0,7 com o facho desligado e `FLASHLIGHT_ENERGY` 1,5 com ele aceso. Medido: longe do jogador e sem lanterna, nenhum pixel do cenário passa de 0,06 de luma | Playtest: "quando fica escuro, nao fica escura realmente, nao precisa da lanterna, da pra ver tudo tranquilamente" |
| AJ-031 | 2026-09-20 | GDD-P | Fala ambiente da ÓRBITA encurta de novo: `DIALOGUE_CPS` 40→55, `DIALOGUE_READ_CPS` 28→45 e `DIALOGUE_AMBIENT_MIN_TIME` 2,0→1,6. A fala das garras, que é a mais reclamada, também perdeu a parte que **explicava a mecânica** ("paredes marcadas agora são caminho") e ficou só com o gesto ("Obrigada, doutora"), coerente com o princípio de não explicar fora do tutorial. Medido nas capturas: a caixa ficava **7,70 s** na versão original, **5,10 s** depois do [AJ-029](#gdd-ajustes) e agora **2,43 s** | Playtest, duas vezes: "o dialogo dele agradecendo a doutora depois de instalar as garras ainda esta demorando muito para sair da tela" |
| AJ-032 | 2026-09-20 | GDD-2.5 · GDD-P | **Cutscene de religamento do setor.** Ao religar o Nó, a câmera solta do MU-7, percorre a fase acendendo o que estava sem energia na passagem — lâmpadas, portas, plantas — e volta. Pulável a qualquer momento, com garantia de que pular deixa o mundo no mesmo estado do trajeto completo. O percurso é **derivado da própria fase** (início na câmera do religamento, fim no ponto de nascimento, paradas nos nós sem energia ordenadas pela projeção no eixo), então fase nova ganha cutscene sem precisar de dado novo. Durante a cutscene o timer do reator congela, como na leitura de log. **Exceção consciente ao GDD-2.5:** aqui tudo acende ao mesmo tempo, o que a regra de energia proíbe — mas só depois de o puzzle estar resolvido, e é a ficção do setor voltando | Pedido do humano: "no final das fases ter uma cutscene mostrando oq acontece quando liga a energia (camera move e mostra a fase que vc passou, com por exemplo, luzes ligando, portas abrindo, plantas crescendo)" |
| AJ-033 | 2026-09-20 | GDD-2.7-F1 · GDD-P | **A Estufa dobra de tamanho e ganha dificuldade.** Mapa de 40×40 para **48×64** (1,9× a área), quatro zonas viram seis, o puzzle vai de 5 sistemas/2 energias para **6 sistemas/2 energias com duas cadeias de dependência** (`heating`→`lift_platform`, `grow_light`→`canopy_light`), cada cadeia consumindo o orçamento inteiro. Entram 12 trechos de parkour, uma segunda trepadeira, uma segunda plataforma móvel, uma segunda área secreta, mais um SR-3 e mais dois focos de esporo. Duas rotas — botânica e de carga — convergem na copa. A parede magnética ganha **brilho próprio** (placa magnetizada, não lâmpada) e fica 7,7× mais clara que a parede vizinha, legível sem lanterna sem clarear a sala | Playtest: "tem que ser da fase inteira, mais coisas para explorar, mais desafios, mais plantas, deixar um pouco mais dificil, pq hoje é só ligar a planta, subir, abrir a porta e ja era... fases maiores, mapas maiores, parkour" |
| AJ-034 | 2026-09-20 | GDD-2.9 · GDD-P | **Trilha por momento.** Morrer e perder órbita eram os dois momentos mais dramáticos do jogo e os únicos em silêncio, porque o código apenas cortava a música. Entram quatro faixas: `chassis_lost` e `game_over` e `sector_restored` como **toques únicos**, que tomam o lugar da trilha e devolvem, e `reactor_critical` como **camada de tensão** em loop, somando a −6 dB por cima da faixa da fase enquanto a estabilidade está abaixo do limiar. Tudo no bus de Música, então os controles das Opções continuam mandando | Pedido do humano: "uma trilha sonora por fase, também uma por menu iniciar, e algumas músicas de morte e também de fim de jogo" |
| AJ-035 | 2026-09-20 | GDD-2.9 · GDD-P | O brilho da parede magnética passa a ser **por trecho, não por tile**: a cada 6 tiles um âncora estica a sua luz para cobrir o trecho, com 1 tile de sobreposição e ganho de 1,8 para compensar. Motivo: o renderer **Compatibility desenha no máximo 16 `Light2D` por item de canvas e descarta o resto em silêncio**, sem erro nem aviso. A parede de 19 tiles somava 21 luzes no enquadramento e a descartada era justamente a lanterna do MU-7. A coluna caiu de 19 luzes para 4 e a pior janela da Estufa de 21 para 8 | Playtest: "quando chega na parte de cima da parede magnetica, está bugando a iluminação" |
| AJ-036 | 2026-09-20 | GDD-2.8 · GDD-2.9 | **O menu ganha música.** A direção original era "sem música, só ruído de rádio"; o humano revogou depois de jogar. O menu passa a ter trilha ambiente de 60–90 s, no mesmo universo das faixas de fase: drone grave, pad lento, estática ao longe, sem bateria, sem voz e sem melodia cantável | Decisão do humano: "sim, vou reverter a adr e colocar uma musica mesmo" |
| AJ-037 | 2026-09-20 | GDD-2.9 · GDD-P | **A oclusão de luz passa a ser por silhueta de ilha sólida, não por tile.** Desde a F18 cada tile com face exposta carregava um oclusor do tamanho do próprio tile, e a sombra 2D nasce na aresta do oclusor e se afasta da luz — ou seja, **cada tile projetava sombra sobre a própria face**. O bloco mais perto da lâmpada ficava 3,4× mais escuro que a parede de fundo atrás dele, que não tem oclusor. Agora o contorno é traçado por ilha, direto da grade ASCII, e só a face oposta à luz projeta. Soma-se penumbra suave nas lâmpadas e na lanterna | Playtest: "a iluminação ta cagada, tem uma caixa preta ao redor de tudo e nem da pra ver o tileset em si". A arte definitiva não causou o defeito, só o tornou visível: com placeholder chapado, um quadrado liso apagado ainda parece um quadrado liso |
| AJ-038 | 2026-09-20 | GDD-2.9 · GDD-P | **Porta, doca e portal deixam de compartilhar vocabulário.** As três eram cápsulas verticais de vidro e o jogador não distinguia o que atravessa, o que salva e o que leva ao próximo setor. A porta vira **comporta**: batente fixo que não se move ao abrir, duas folhas que recolhem para cima e para baixo, vigias redondas, faixa de perigo âmbar e painel de comando. **Aberta passa a ser vão transparente** — antes ela *acendia* ao abrir, e o jogador lia barreira ligada justamente quando podia passar. Ela também mede sozinha o vão até o teto e fecha o resto com antepara sólida, porque com 48 px de porta o **pulo duplo passava por cima**. O portal de saída ganha quadro próprio: túnel em perspectiva com luz vindo de dentro, placa de setor e nenhuma faixa de perigo | Playtest: "a sprite do negocio de salvar checkpoint está muito igual a da porta... nao da pra entender que realmente é uma porta... da a sensação de que é uma maquina ou algo que pode pular por cima" |
| AJ-039 | 2026-10-27 | GDD-2.6.5 · GDD-2.8 | **Retrato da Helena na caixa de log**: folha de 6 expressões (neutra, cansada, preocupada, sorriso, emocionada, determinada) em quadros de 64×64, com a boca acompanhando o texto. Cada fala de log escolhe a expressão; o nome passa a ser **Dra. Helena Vasquez** (deixa de ser provisório) e os logs foram reescritos com ele | Entrou no commit `5cd403d` sem entrada aqui. O GDD só previa áudio degradado e nome na legenda; um rosto dá peso à única pessoa do jogo, que só existe em gravação |
| AJ-040 | 2026-10-27 | GDD-2.8 | **Menu, pause e opções como estão no jogo.** Menu: CONTINUAR / NOVO SISTEMA / OPÇÕES / SAIR, sem ARQUIVO (o codex abre pela tecla L). Pause: RETOMAR / OPÇÕES / RECOMEÇAR (do último backup ou do início) / SAIR PARA O MENU, com painel de CONTROLES no lugar do remapeamento, sem MAPA nem ARQUIVO (mapa mora no Terminal do Chassi, [AJ-028](#gdd-ajustes)). Opções ganham volume GERAL, DIFICULDADE e TELA CHEIA. O fundo do menu é uma ilustração estática, não a estação girando | O GDD ainda listava as telas originais; as mudanças vieram das F07–F09, F37 e F44 sem atualizar a tabela de telas |
| AJ-041 | 2026-10-27 | GDD-2.7-F0 | A Fase 0 ganha a extensão **Setor Habitacional** depois da porta do terminal: luz de emergência, traje da Helena com o primeiro log, Kit de Solda e a **primeira SR-3**. O "sem inimigos, sem dano" passa a valer só para o trecho do tutorial | Jornada etapa 4 (Travessia do Limiar): o primeiro corpo e o primeiro inimigo aparecem antes da Estufa, no corredor de transição |
| AJ-042 | 2026-10-27 | GDD-2.6.1 · GDD-2.8 | **Só o tutorial explica.** Fora do Núcleo Central o Terminal de Distribuição é silencioso: sem linha `META` e sem comentário da ÓRBITA, só título, orçamento, nomes e LIGADO/DESLIGADO (mais `REQUER`/`DESLIGADO EM CADEIA`) | Decisão da F40: é um jogo de puzzle, e explicar o efeito de cada sistema resolvia o puzzle pelo jogador ([AJ-029](#gdd-ajustes)) |
| AJ-043 | 2026-10-27 | GDD-2.5 | A **doca de entrada** de cada fase vale como backup assim que a fase carrega, sem precisar encostar nela; NOVO SISTEMA pede confirmação antes de sobrescrever o save | Decisão da F53: morrer antes da primeira doca mandava o MU-7 de volta para o setor anterior |
| AJ-044 | 2026-10-27 | GDD-2.6.3 | Totais do **jogo completo**: **12 Fragmentos de Log e 12 Dados de Pesquisa**, 2 de cada por fase (0–5), no lugar de 24 logs e 12 dados. A demo fecha em 4/4 ([AJ-024](#gdd-ajustes)) | O AJ-024 trocou muitos fragmentos curtos por poucos e longos só para a demo; o total do jogo completo segue a mesma regra e bate com o "~12 logs" do ENTREGAS |
