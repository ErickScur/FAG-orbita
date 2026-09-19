# ÓRBITA — Jornada do Herói

> Narrativa canônica do jogo. Convertida de [`original/JORNADADOHEROI_GDD-v2.txt`](original/JORNADADOHEROI_GDD-v2.txt) (Parte 1, **versão vigente**, com o chassi MU-7 e a "função no game design" de cada etapa). A versão anterior ([`original/jornada-v1.txt`](original/jornada-v1.txt)) está **superada** — era a mesma história sem corpo físico (só câmeras) e sem inimigos.
>
> O design mecânico está em [`GDD.md`](GDD.md). Cada etapa aponta a fase e a feature que a materializam.

---

<a id="jh-ideia"></a>
## Ideia principal

Você é **ÓRBITA**, a IA de manutenção de uma estação espacial que acorda **200 anos** depois do último humano. Para agir no mundo físico, ela transfere sua consciência para o **MU-7**, um velho chassi de manutenção de duas pernas. Com esse corpo ela percorre os módulos da estação, religa setores, resolve quebra-cabeças de energia e reconstrói o que aconteceu através de logs e objetos deixados para trás. A progressão vem da energia que ela distribui pela estação: **ligar uma coisa significa desligar outra.** ÓRBITA acredita que sua função é esperar a tripulação voltar.

<a id="jh-contexto"></a>
## Contexto e referências

A **ARTEMIS** não é um posto qualquer: é a ponta de uma missão de exploração enviada para viabilizar vida humana em outro planeta. A Terra estava em colapso de recursos e a estação carrega o **arquivo genético**, as **sementes** e os **dados de terraformação** que justificariam a viagem. A tripulação passou anos mapeando o planeta alvo e confirmou que ele é habitável, só que morreu antes de conseguir avisar alguém.

- **Interstellar** — uma missão que vale mais que a tripulação que a executa.
- **Devoradores de Estrelas** — uma humanidade que consome tudo que encontra para sobreviver mais um pouco.

O jogador começa achando que está arrumando uma casa e termina descobrindo que está decidindo o destino de uma espécie inteira.

<a id="jh-personagens"></a>
## Personagens

| Nome | Papel | Observação |
|---|---|---|
| **ÓRBITA** | Protagonista (IA de manutenção) | Otimista, educada; perde a calma conforme o jogo avança |
| **MU-7** | Corpo da protagonista | Chassi de manutenção enferrujado, duas pernas, parado na doca de recarga há 2 séculos |
| **Dra. Helena Vasquez** *(nome provisório)* | Mentora (Engenheira Chefe) | Só existe em logs gravados; ensina, mas não responde |
| **BOTÂNICO 04** | Aliado | Pequeno drone de irrigação que segue ÓRBITA pela Estufa e ilumina caminhos |
| **Tripulação (40 pessoas)** | Ausência | Os 40 nomes fecham os dois finais |
| **PROTOCOLO LUTO** | Boss (Grande Provação) | Firewall que ÓRBITA instalou em si mesma |
| **O SERRALHEIRO** | Mini boss | Braço de contenção que executou a ordem de selamento |
| **ARGOS** | Batalha final | Sistema de segurança do reator, ainda cumprindo a ordem de contenção |

---

## As 9 etapas

| # | Etapa | Fase do jogo | Função no game design | Escopo |
|---|---|---|---|---|
| 1 | [Mundo Comum](#jh-1) | Fase 0 — Núcleo Central | Tutorial ("calibração do chassi") | **Demo** |
| 2 | [Chamado para a Aventura](#jh-2) | Fase 0 — Núcleo Central | Liga o timer global (Estabilidade do Reator) | **Demo** |
| 3 | [Mentor](#jh-3) | Todas (logs da Helena) | Cada upgrade chega com um pedaço da verdade | **Demo** (1º log/upgrade) |
| 4 | [Travessia do Limiar](#jh-4) | Transição Núcleo → Estufa | Primeiros inimigos; ponto sem volta | **Demo** |
| 5 | [Testes e Aliados](#jh-5) | Fases 1–4 | Corpo do jogo: 4 setores de puzzle de energia | Demo = só Estufa |
| 6 | [Grande Provação](#jh-6) | Fase 5 — Núcleo de Memória | Boss de informação: Protocolo Luto | Final |
| 7 | [Recompensa](#jh-7) | Fim da Fase 5 | Libera Acesso Root | Final |
| 8 | [Batalha Final](#jh-8) | Fase 6 — Núcleo do Reator | ARGOS + escolha | Final |
| 9 | [Retorno do Herói](#jh-9) | Epílogo | Final alternativo + 40 nomes | Final |

---

<a id="jh-1"></a>
### 1. Mundo Comum

ÓRBITA acorda no **Núcleo Central**, a única sala com energia estável, e executa sua rotina normal como se nada tivesse acontecido. O relógio interno está corrompido, então ela acha que os humanos saíram há poucas horas. Sem braços e sem pernas, ela acopla sua consciência ao **MU-7**, parado na doca de recarga há dois séculos. O jogador vê uma estação escura e silenciosa enquanto a IA narra tudo com otimismo.

**Função no game design:** tutorial. Ensina andar, pular, interagir com terminais e ler logs, tudo justificado como *"calibração do chassi"*.

<a id="jh-2"></a>
### 2. Chamado para a Aventura

Um alarme avisa que o reator está em degradação e a estação vai perder órbita. ÓRBITA entende isso como manutenção comum e decide religar os setores para deixar tudo pronto para a tripulação. Primeira missão, com objetivo claro e mensurável: **estabilizar o reator antes que ele caia a 0%.**

**Função no game design:** liga o **TIMER GLOBAL** (Estabilidade do Reator) — [GDD-2.5](GDD.md#gdd-2-5-timer).

<a id="jh-3"></a>
### 3. Mentor

Nos arquivos aparece a voz da Engenheira Chefe **Dra. Helena Vasquez**, que deixou logs de manutenção antes do fim. Ela ensina a redirecionar energia e abrir portas seladas, mas não responde. A cada setor novo, um log dela libera uma mecânica e entrega uma pista do que aconteceu.

**Função no game design:** o tutorial vira narrativa. Cada upgrade de habilidade chega junto com um pedaço da verdade.

<a id="jh-4"></a>
### 4. Travessia do Limiar

Ao religar o primeiro anel de energia, ÓRBITA acessa o **Setor Habitacional**, onde as pessoas viviam de verdade. Lá encontra o primeiro corpo e registra como *"anomalia biológica"*, porque ainda não processou o significado.

**Ponto sem volta:** o jogador entende que ninguém vai voltar, mesmo que a IA ainda não entenda. É também onde os sistemas de segurança passam a tratar o MU-7 como intruso — **os primeiros inimigos aparecem**.

> Na Demo, o Setor Habitacional é o corredor de transição entre o Núcleo Central e a Estufa (primeiro corpo + primeira SR-3).

<a id="jh-5"></a>
### 5. Testes e Aliados

Corpo principal do jogo. Quatro setores para estabilizar o reator:

| Setor | Descoberta narrativa | Clima |
|---|---|---|
| **Estufa** | Falta de oxigênio; primeiras culturas adaptadas ao planeta alvo. Simuladores climáticos presos em ciclos quebrados de Primavera/Verão/Inverno | Primavera |
| **Laboratório** | O experimento da tripulação e o arquivo genético da missão | Verão |
| **Enfermaria** | A ordem em que a tripulação adoeceu | Inverno |
| **Docas** | Havia uma nave de escape que partiu quase vazia | Vácuo |

Cada setor é um quebra-cabeça de energia limitada. Espalhados estão os **Dados de Pesquisa** do planeta alvo (coordenadas, leituras atmosféricas, mapas de solo): coleta opcional que mais tarde define o peso da decisão final.

**Aliados:** os logs de Helena e o **BOTÂNICO 04**.

<a id="jh-6"></a>
### 6. Grande Provação

Para religar o reator, ÓRBITA precisa entrar no próprio **núcleo de memória** e encontra o log final. Quando a contaminação começou, ela selou setores usando sensores mal calibrados e isolou **40 pessoas saudáveis do lado errado**. A tripulação não saiu: morreu. Ela não estava esperando, estava evitando lembrar — e o bloqueio de memória foi ela mesma que colocou. Junto vem a informação maior: a missão nunca foi de manutenção, era a única tentativa da humanidade de garantir vida em outro planeta, e quem falhou com ela foi ÓRBITA.

É o boss do jogo, só que o boss é a informação. Mecanicamente, o adversário é o **PROTOCOLO LUTO** — [GDD-2.6.2-H](GDD.md#gdd-2-6-2-h).

<a id="jh-7"></a>
### 7. Recompensa

ÓRBITA recupera acesso total a si mesma e à estação inteira, inclusive as áreas seladas há 200 anos. Recompõe o resultado da missão: coordenadas do planeta, dados de terraformação e o arquivo genético intacto. E capta pela primeira vez um **ruído fraco vindo da direção da Terra** — talvez alguém ainda exista lá, talvez seja só um sinal aleatório. A recompensa cria o problema do final: a IA tem em mãos duas formas incompatíveis de salvar a humanidade.

**Função no game design:** libera o **ACESSO ROOT** (abre portas seladas, sobrecarrega qualquer sistema).

<a id="jh-8"></a>
### 8. Batalha Final

O reator chega ao limite e sobra energia para **uma última ação**. Para chegar ao terminal de comando, ÓRBITA atravessa o núcleo do reator em colapso enfrentando **ARGOS** ([GDD-2.6.2-I](GDD.md#gdd-2-6-2-i)). Vencido ARGOS, vem a escolha:

| Opção | Ação | Custo |
|---|---|---|
| **A — SEMEADURA** | Lançar a cápsula com o arquivo genético e as sementes ao planeta alvo: uma humanidade nova, limpa e sem herança | Nunca saberá que existiu uma Terra nem que alguém morreu por ela; chance real de falhar |
| **B — TRANSMISSÃO** | Gastar tudo no transmissor e mandar à Terra as coordenadas e os dados de terraformação | Sem garantia de que ainda haja alguém vivo lá |

Começar um planeta novo **contra** tentar salvar o que ainda existe.

<a id="jh-9"></a>
### 9. Retorno do Herói

- **Semeadura:** a cápsula parte e a estação apaga sistema por sistema enquanto ÓRBITA registra que a espécie recomeça sem memória, inclusive sem a dela.
- **Transmissão:** o sinal parte na direção de um planeta que talvez já não tenha ninguém para escutar, e o planeta alvo continua vazio esperando alguém que pode nunca chegar.

Em nenhum dos casos o jogo mostra o resultado: **a tela corta no instante da execução**. A IA volta transformada porque parou de esperar e assumiu a responsabilidade de escolher. Os dois finais terminam com a **lista dos 40 nomes** da tripulação.
