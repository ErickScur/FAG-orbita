# ÓRBITA — Roteiro da apresentação final

> Guia de fala para usar com a gameplay automática (`tools/demo.sh`). O jogo joga sozinho; vocês
> contam a história e apontam o que importa. **P** congela tudo para explicar com calma; **P** de
> novo retoma do mesmo ponto.

## Antes de começar (5 min antes)

1. Feche o editor do Godot e outros apps pesados; ligue o carregador.
2. Projetor em **espelhamento** (ou use `--tela=N` para escolher o monitor).
3. Volume do Mac em ~60% (as fases novas ainda não têm música própria; o som é dos efeitos).
4. No terminal, dentro da pasta do projeto, deixe pronto **um** dos comandos:
   - `tools/demo.sh novidades` — só o que veio depois da Enfermaria (~14 min sem pausas).
   - `tools/demo.sh completo` — do menu aos créditos (~26 min sem pausas).
5. Teclas durante a demo (o teclado normal do jogo fica desligado, nada atrapalha o roteiro):
   - **P** congela tudo / retoma do mesmo ponto (aparece um selo PAUSADO no canto; a música continua).
   - **N** pula para o próximo capítulo · **R** reinicia o capítulo atual.
   - **Esc segurado 1 s** ou **Cmd+Q** fecha.
   - Opções do comando: `--tela=1` (projetor), `--final=transmissao`, `--capitulo=reator`,
     `--janela`, `--rapido` (falas sem tempo de leitura), `--sem-selo` (sem o selo PAUSADO).
6. Ensaio: `tools/demo.sh novidades --verificar` roda mudo, sem roubar a tela, e diz no fim se
   todos os capítulos passaram (~14 min). Rode uma vez antes de sair de casa, **sem outro Godot
   aberto** (janelas disputando o foco podem soltar uma tecla segurada do roteiro).

Se o professor decidir na hora: comece por `completo`. Se ele disser "só o que é novo", aperte
**N** até chegar nas Docas (ou feche e rode `novidades`).

## Plano B

- O MU-7 travou ou algo saiu do roteiro: **N** pula para o próximo capítulo, que começa limpo.
- O jogo fechou: `tools/demo.sh <playlist> --capitulo=<nome>` volta direto ao capítulo.
- Precisa explicar uma tela com calma: **P**. Nada anda enquanto estiver congelado.

---

## Roteiro A — Novidades (depois da Enfermaria)

| # | Capítulo | Começa em | Na tela |
|---|---|---|---|
| 1 | `hub_docas` | 00:00 | Volta ao Núcleo depois da Enfermaria; Terminal do Chassi, **mapa da estação** e **arquivo de logs**; portal das Docas |
| 2 | `docas` | 00:22 | Vácuo, Propulsor, cabine secreta, terminais, luta com o Serralheiro passo a passo, setor religado |
| 3 | `hub_memoria` | 03:59 | Núcleo: comporta da Memória |
| 4 | `memoria` | 04:14 | Protocolo Luto (registro escondido, fuga, firewall, log final), Acesso Root, sinal da Terra |
| 5 | `revisita_lab` | 06:57 | Volta ao Laboratório: o Acesso Root abre a comporta e dá a Placa de Blindagem |
| 6 | `revisita` | 07:46 | Placa do Núcleo, portas ROOT da Estufa e das Docas (4/4 placas) |
| 7 | `reator` | 08:57 | Comporta ROOT do reator, travessia, log do reator, ARGOS com os 3 acopladores e o último dado (12/12), silêncio |
| 8 | `final` | 11:36 | Sala de comando, escolha, cutscene, epílogo, 40 nomes, estatísticas (13/13 · 12/12 · 0 mortes), créditos, menu |

Tempos sem pausas (~14 min no total); cada P empurra o resto. A demo joga **100%**: pega todos
os dados, logs, capacitores, placas e segredos, sem teleporte nem atalho.

### Abertura (antes de apertar Enter, 30 s)
- Na entrega anterior mostramos o Núcleo Central, a Estufa, o Laboratório e a Enfermaria.
- Agora o jogo está completo: mais três fases, um mini-boss, dois chefes, dois finais, epílogo e
  créditos com os 40 nomes da tripulação.
- Na Jornada do Herói, saímos da etapa 5 (Testes e Aliados) e vamos até a 9 (Retorno do Herói).

### Volta ao Núcleo (capítulo 1)
- **Mapa da estação** (Tab duas vezes): setores religados, onde está cada coisa. **Arquivo de
  logs** (L): reler a história a qualquer momento. Nada disso cresce a HUD; mora no Terminal do
  Chassi.

### Docas — o último setor de "Testes e Aliados"
- **História:** a Enfermaria contou a ordem em que a tripulação adoeceu. Nas Docas, ÓRBITA
  descobre que havia uma nave de fuga, a SELENE, e que ela partiu quase vazia.
- **Mecânica nova — vácuo:** a baia do hangar está aberta para o espaço. Sem ar, o MU-7 flutua e
  só muda de rumo com o **Propulsor**, que dá também o pulo duplo. O Propulsor vem num log da
  Helena: cada upgrade chega junto de um pedaço da verdade (etapa 3, Mentor).
- **Puzzle de energia:** seis sistemas e só três unidades de energia. Ligar uma coisa desliga
  outra — a regra que segura o jogo inteiro.
- **Mini-boss — O Serralheiro:** o braço industrial que soldou as comportas na noite do acidente.
  Ele não ataca e não tem barra de vida: tranca o cenário e solta robôs SR-3 sem parar. O jogador
  vence alimentando três acopladores com energia, um deles no vácuo. Cada acoplador ligado muda a
  arena. No fim nada é destruído: o braço só desliga. Nenhum inimigo do jogo é mau, todos estão
  cumprindo uma ordem.
- **O que aparece na luta, em ordem** (cada etapa tem uma pausa curta para explicar):
  1. o braço acorda e o MU-7 só observa;
  2. 1º acoplador ligado → o braço solda uma comporta (o cenário muda);
  3. o braço tranca o 2º acoplador; o MU-7 vai para o 3º;
  4. um SR-3 cai do teto e é desligado com o Feixe; 3º acoplador ligado;
  5. purga de vácuo: o MU-7 flutua com o Propulsor até o 2º acoplador e espera o braço soltar;
  6. braço desligado, leitura da última ordem.
- **Gancho:** depois da luta, ÓRBITA lê a última ordem dele: "selar o hangar às três e doze.
  Remetente: rede central." O nome de quem assinou foi apagado. *Apagado com cuidado.*

### Núcleo de Memória — a Grande Provação (etapa 6)
- **História:** para religar o reator, ÓRBITA entra na própria memória. A fase é a estação do
  jeito que ela se lembra: com gente, barulho, o pão da Samira e o desenho do Davi na parede.
- **Visual:** quebra total de paleta. Depois de fases escuras, cores vivas: painéis coral e
  dourados, o mural do planeta, a tripulação no refeitório.
- **Chefe — Protocolo Luto:** o firewall que a própria ÓRBITA instalou para não lembrar, um olho
  de anéis que apaga a memória enquanto o MU-7 anda. A cada fase da luta a cor escorre para o
  cinza e o cenário vira estática. O adversário é a informação: o "dano" é a memória voltando.
- **Na tela:** na Fase 1 o MU-7 desvia para ler um registro escondido num nicho antes que a
  estática o alcance (a estática para enquanto ele lê). A demo para ~2 s em cada virada de fase:
  bom momento para apontar a cor sumindo.
- **Revelação (pausar aqui, P):** o log final. Quem mandou o Serralheiro selar as comportas foi a
  própria ÓRBITA. Os sensores erravam 3%, ela selou o lado errado e quem estava saudável ficou
  preso com os esporos. Ela instalou o bloqueio de memória com a instrução "esperar a tripulação
  voltar" — a mesma frase com que o jogo começa.
- **Recompensa (etapa 7):** Acesso Root à estação inteira, os dados do planeta alvo intactos e um
  sinal fraco vindo da direção da Terra. É o que cria o dilema do final.

### Núcleo do Reator — a Batalha Final (etapa 8)
- **Chefe — ARGOS:** o sistema de segurança do reator, ainda cumprindo a ordem de não deixar
  ninguém passar. Três torres blindadas, três acopladores e o núcleo no meio.
- **Mecânica:** a luta tem 90 segundos. Vence-se sobrecarregando os três acopladores com o
  Acesso Root, enquanto as plataformas sobem e descem com o calor. Cada acoplador queimado racha o
  núcleo, derruba um anel e acelera o calor. É a junção de tudo o que o jogador aprendeu: energia,
  Propulsor, dash, garras e Root. Depois de ARGOS, silêncio.
- **O que aparece na luta, em ordem** (o relógio de 90 s fica no topo; a demo vence com ~45 s
  sobrando, com uma pausa curta depois de cada acoplador):
  1. o MU-7 cai na arena e olha o núcleo;
  2. no console, tira a refrigeração e liga as linhas de energia (a regra de energia vale até
     aqui);
  3. Feixe na torre oeste → 1º acoplador sobrecarregado com ROOT → o núcleo racha;
  4. troca as linhas no outro console; atravessa as plataformas térmicas (sobem e descem com o
     calor) → 2º acoplador;
  5. escala a parede magnética, pega o último Dado de Pesquisa (12/12) e atordoa a torre do teto
     → 3º acoplador → ARGOS cai.
- **Timer global:** a estabilidade do reator (o número da HUD desde o tutorial) chega ao limite
  aqui. Sobra energia para uma última ação.

### Revisita com o Acesso Root (dois capítulos curtos, antes do Reator)
- O Acesso Root abre as portas ROOT que estavam seladas desde o começo nos setores antigos. Atrás
  delas ficam as Placas de Blindagem. A demo volta ao Laboratório, à Estufa e às Docas e pega as
  quatro (a do Núcleo fica no alto da parede magnética). Ida e volta pela estação é parte do jogo
  (metroidvania): habilidade nova abre caminho em fase velha.

### Sala de comando e finais (etapas 8 e 9)
- **A escolha (pausar, P):** Semeadura — lançar a cápsula com sementes e arquivo genético para o
  planeta alvo, uma humanidade nova sem memória da Terra — ou Transmissão — mandar as coordenadas
  à Terra, sem garantia de que alguém escute.
- **Consequência:** o epílogo muda conforme os Dados de Pesquisa que o jogador coletou ao longo do
  jogo (poucos, alguns ou quase todos). Coleta opcional vira peso narrativo. A demo joga **100%**
  (12/12 dados, 13/13 logs, 4/4 capacitores, 4/4 placas, 5/5 segredos), então mostra o epílogo
  mais completo; as estatísticas no fim provam isso.
- **Corte:** o jogo nunca mostra o resultado; a tela corta no instante da execução.
- **Fecho:** os 40 nomes da tripulação, as estatísticas da partida e a pergunta "VOCÊ
  ESCOLHERIA DE NOVO?". Depois os créditos.

### Outras novidades para citar (se der tempo)
- Ida e volta: o hub tem uma ala com a porta de cada setor; dá para revisitar fases antigas.
- Upgrades: 4 Núcleos de Capacitor e 4 Placas de Blindagem escondidos; portas ROOT nos setores
  antigos que só abrem depois do Núcleo de Memória.
- BOTÂNICO 04, o drone aliado da Estufa que ilumina o caminho.
- Status Descarga e Sobrecarga, piso eletrificado.
- Opções: remapear teclas, legenda grande e modo daltônico.

---

## Roteiro B — Gameplay completa

| # | Capítulo | Começa em | Na tela |
|---|---|---|---|
| 1 | `tutorial` | 00:00 | Menu, Novo jogo, briefing, tutorial no Núcleo Central |
| 2 | `estufa` | 02:17 | Estufa 100%: 3 dados, 2 logs, capacitor, os 2 segredos, BOTÂNICO 04, garras |
| 3 | `hub_lab` | 04:46 | Volta ao Núcleo, rumo ao Laboratório |
| 4 | `laboratorio` | 04:57 | Laboratório 100% (2 dados, 2 logs, capacitor, segredo) |
| 5 | `hub_enfermaria` | 08:09 | Volta ao Núcleo, rumo à Enfermaria |
| 6 | `enfermaria` | 08:21 | Enfermaria 100%: farmácia, sala de cima com o segredo, poço oeste |
| 7–14 | os capítulos do Roteiro A | 11:36 | hub_docas 11:36 · docas 11:58 · hub_memoria 15:35 · memoria 15:50 · revisita_lab 18:33 · revisita 19:22 · reator 20:33 · final 23:12 |

São 26 minutos: se o tempo da apresentação for curto, use **N** para pular os setores antigos
depois de alguns segundos de cada um.

Até a Enfermaria, falem rápido (o professor já viu); a partir das Docas, sigam o Roteiro A.

- **Menu e briefing:** tema "Estação" → estação espacial ARTEMIS. ÓRBITA, a IA de manutenção,
  acorda 200 anos depois e assume o chassi MU-7 (Mundo Comum, etapa 1).
- **Núcleo Central (tutorial):** andar, pular, terminal, logs — tudo justificado como
  "calibração do chassi". O alarme do reator liga o timer global (Chamado, etapa 2). O primeiro
  corpo e a primeira SR-3 marcam a Travessia do Limiar (etapa 4).
- **Estufa (Primavera):** escuridão e lanterna, SR-3 e esporos, planta que cresce, garras.
- **Laboratório (Verão):** o experimento e o arquivo genético da missão.
- **Enfermaria (Inverno):** a ordem em que a tripulação adoeceu.
- A partir daqui → Roteiro A.

---

## Encerramento (1 min, com os créditos ou o menu ao fundo)
- Escopo: 7 fases, 1 mini-boss, 2 chefes, 2 finais com epílogo variável, 13 logs e 12 Dados.
- Como foi feito: Godot 4 em 2D, fases desenhadas em texto (ASCII), números de design numa
  tabela única do GDD, testes automáticos e roteiros de QA que jogam o jogo sozinhos — esta
  própria apresentação roda em cima deles.
- Pendências conhecidas: músicas próprias das fases novas e a build exportada.
