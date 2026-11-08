# Medições do SLA · Testes de carga do Unilink

Medições de **latência**, **vazão** e **concorrência** de três serviços do Unilink, feitas com o [k6](https://k6.io/).

- **Medição 1** (entrega de 09/11/2026): o sistema como está, para achar os gargalos.
- **Medição 2** (entrega de 16/11/2026): depois das otimizações, comparando com a medição 1.

[Serviço 1 · Login](#serviço-1--login) · [Serviço 2 · Agenda de eventos](#serviço-2--agenda-de-eventos) · [Serviço 3 · Confirmar presença](#serviço-3--confirmar-presença) · [Comparação entre os serviços](#comparação-entre-os-serviços) · [Como rodar](#como-rodar)

## Como os testes foram feitos

- **Ferramenta:** k6. Cada serviço tem o seu script, e todos usam o mesmo perfil de carga
  ([`comum.js`](comum.js)), para dar para comparar um serviço com o outro.
- **Concorrência:** o número de usuários virtuais (VUs) simultâneos sobe em patamares de **10, 50, 100, 200 e 500**,
  com 10 s de subida e 40 s parado em cada patamar (cerca de 4 min e meio por serviço).
  Cada VU faz uma requisição, espera 1 s e repete.
- **Latência:** tempo médio de resposta (`http_req_duration`), também com P95 e P99.
- **Vazão:** requisições por segundo (média de cada patamar e evolução segundo a segundo).
- **Limite de concorrência:** o maior patamar em que o SLA ainda vale.
- **SLA usado:** RNF002 (responder em até 2 s, medido pelo P95) e RNF003 (estabilidade: menos de 1% de erros).
- **Massa de dados:** [`massa-de-dados.sql`](massa-de-dados.sql) cria 2000 estudantes com perfil e 50 eventos futuros,
  para cada VU usar um estudante diferente.
- **Gráficos:** gerados pelo [`graficos.py`](graficos.py) a partir do CSV do k6, como no exemplo da monitoria.

### Configuração do ambiente

| Item | Valor |
| --- | --- |
| Computador | 12th Gen Intel(R) Core(TM) i5-12450H - 8GB RAM |
| Sistema operacional | Windows 11 |
| Containers (Docker Desktop) | `unilink-mysql`: MySQL 8.0 · `unilink-backend`: Java 21 (eclipse-temurin:21-jre) com Spring Boot 3.5 |
| Back-end | Tomcat embutido (padrão: até 200 threads) e pool de conexões HikariCP (padrão: 10 conexões) |
| Gerador de carga | k6 rodando no mesmo computador, fora do Docker, em `http://localhost:8080` |

### Arquivos com o código fonte da medição do SLA

- [`comum.js`](comum.js): perfil de carga e SLA comuns aos três serviços
- [`login.js`](login.js), [`eventos.js`](eventos.js), [`presenca.js`](presenca.js): um script por serviço
- [`massa-de-dados.sql`](massa-de-dados.sql): massa de dados do teste
- [`rodar-testes.bat`](rodar-testes.bat): roda os três serviços e gera os gráficos
- [`graficos.py`](graficos.py): gráficos, tabelas e este README

---

## Serviço 1 · Login

- **Endpoint:** `POST /api/login` (UC02)
- **Tipo de operação:** leitura (busca o estudante pelo e-mail e confere o hash da senha)
- **Arquivos envolvidos:**
  [`EstudanteController.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/controller/EstudanteController.java) ·
  [`EstudanteService.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/service/EstudanteService.java) ·
  [`Senhas.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/service/Senhas.java) ·
  [`EstudanteRepository.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/repository/EstudanteRepository.java) ·
  [`Login.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/model/Login.java) ·
  [`Estudante.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/model/Estudante.java) ·
  [`01-schema.sql`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/database/01-schema.sql) (tabela `estudante`)
- **Código da medição:** [`login.js`](login.js) e [`comum.js`](comum.js)

### Medição 1

<!-- MEDICAO1:login -->
- **Data da medição:** 07/11/2026
- **Requisições no teste:** 42941
- **Limite de concorrência dentro do SLA** (p95 < 2000 ms e erros < 1%): o SLA valeu em todos os patamares, até **500 VUs** (o limite real fica acima disso)

| Concorrência (VUs) | Latência média (ms) | p95 (ms) | Vazão (req/s) | Erros (%) | SLA |
| --- | --- | --- | --- | --- | --- |
| 10 | 9.72 | 12.98 | 9.6 | 0.00 | ✅ |
| 50 | 5.87 | 7.66 | 48.5 | 0.00 | ✅ |
| 100 | 5.30 | 7.81 | 97.0 | 0.00 | ✅ |
| 200 | 5.89 | 12.07 | 193.3 | 0.00 | ✅ |
| 500 | 5.90 | 8.79 | 484.9 | 0.00 | ✅ |

| Métrica (teste inteiro) | Média | Mediana | Mín | Máx | P95 | P99 |
| --- | --- | --- | --- | --- | --- | --- |
| Latência, `http_req_duration` (ms) | 5.70 | 5.26 | 0.00 | 569.28 | 9.38 | 16.16 |
| Tempo bloqueado, `http_req_blocked` (ms) | 0.03 | 0.00 | 0.00 | 30.27 | 0.00 | 1.12 |

![Latência de Login](resultados/medicao-1/login-latencia.png)
![Vazão de Login](resultados/medicao-1/login-vazao.png)
![Erros de Login](resultados/medicao-1/login-erros.png)
![Tempo bloqueado de Login](resultados/medicao-1/login-bloqueio.png)
<!-- /MEDICAO1:login -->

**Hipóteses de potenciais gargalos**

- **O que a medição mostrou:** até 500 VUs a vazão acompanhou os VUs (484,9 req/s com 500) e a latência média ficou perto de 6 ms, sem erros. O gargalo do login não apareceu nesta faixa. A latência maior com 10 VUs (9,72 ms) e o máximo de 569 ms devem ser do aquecimento da aplicação (primeiras requisições depois de ligar o Java).
- **Pool de conexões:** cada login ocupa uma das 10 conexões do HikariCP. Se a latência subir enquanto a vazão para de acompanhar os VUs, as requisições estão esperando conexão livre.
- **Gerador de carga na mesma máquina:** o k6 e os containers dividem a mesma CPU, então nos patamares altos parte do tempo medido pode ser disputa de CPU, e não do Unilink.
- **Consulta e senha:** a busca é pelo e-mail, que tem índice (`UNIQUE`), e o hash MD5 é barato, por isso a consulta em si não deve ser o gargalo.

### Medição 2

<!-- MEDICAO2:login -->
(medição de 16/11)
<!-- /MEDICAO2:login -->

<!-- COMPARACAO:login -->
<!-- /COMPARACAO:login -->

**Melhorias/otimizações:** (16/11: listar os arquivos modificados)

---

## Serviço 2 · Agenda de eventos

- **Endpoint:** `GET /api/eventos?email=` (UC06)
- **Tipo de operação:** leitura (lista todos os eventos e marca os que o estudante já confirmou)
- **Arquivos envolvidos:**
  [`EventoController.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/controller/EventoController.java) ·
  [`EventoService.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/service/EventoService.java) ·
  [`EventoRepository.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/repository/EventoRepository.java) ·
  [`Evento.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/model/Evento.java) ·
  [`01-schema.sql`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/database/01-schema.sql) (tabelas `evento`, `presenca_evento` e `estudante`)
- **Código da medição:** [`eventos.js`](eventos.js) e [`comum.js`](comum.js)

### Medição 1

<!-- MEDICAO1:eventos -->
- **Data da medição:** 07/11/2026
- **Requisições no teste:** 42799
- **Limite de concorrência dentro do SLA** (p95 < 2000 ms e erros < 1%): o SLA valeu em todos os patamares, até **500 VUs** (o limite real fica acima disso)

| Concorrência (VUs) | Latência média (ms) | p95 (ms) | Vazão (req/s) | Erros (%) | SLA |
| --- | --- | --- | --- | --- | --- |
| 10 | 6.63 | 8.58 | 9.7 | 0.00 | ✅ |
| 50 | 6.21 | 8.96 | 48.5 | 0.00 | ✅ |
| 100 | 8.18 | 14.32 | 96.7 | 0.00 | ✅ |
| 200 | 7.99 | 14.23 | 193.4 | 0.00 | ✅ |
| 500 | 10.27 | 22.39 | 483.8 | 0.00 | ✅ |

| Métrica (teste inteiro) | Média | Mediana | Mín | Máx | P95 | P99 |
| --- | --- | --- | --- | --- | --- | --- |
| Latência, `http_req_duration` (ms) | 9.02 | 7.59 | 1.58 | 111.27 | 18.20 | 34.17 |
| Tempo bloqueado, `http_req_blocked` (ms) | 0.04 | 0.00 | 0.00 | 13.88 | 0.00 | 1.28 |

![Latência de Agenda de eventos](resultados/medicao-1/eventos-latencia.png)
![Vazão de Agenda de eventos](resultados/medicao-1/eventos-vazao.png)
![Erros de Agenda de eventos](resultados/medicao-1/eventos-erros.png)
![Tempo bloqueado de Agenda de eventos](resultados/medicao-1/eventos-bloqueio.png)
<!-- /MEDICAO1:eventos -->

**Hipóteses de potenciais gargalos**

- **O que a medição mostrou:** sem erros até 500 VUs, mas é o serviço de leitura que mais piora com a carga: a latência média foi de 6,63 ms (10 VUs) para 10,27 ms (500 VUs) e o p95 de 8,58 ms para 22,39 ms.
- **Sem paginação:** a agenda devolve todos os eventos de uma vez, então o tempo e o tamanho da resposta crescem a cada evento cadastrado.
- **Subconsulta por linha:** para cada evento roda um `EXISTS` em `presenca_evento` para saber se o estudante confirmou, além do `JOIN` com `estudante` para o nome do organizador.
- **Pool de conexões:** como no login, a consulta disputa as 10 conexões do HikariCP.

### Medição 2

<!-- MEDICAO2:eventos -->
(medição de 16/11)
<!-- /MEDICAO2:eventos -->

<!-- COMPARACAO:eventos -->
<!-- /COMPARACAO:eventos -->

**Melhorias/otimizações:** (16/11: listar os arquivos modificados)

---

## Serviço 3 · Confirmar presença

- **Endpoint:** `POST /api/eventos/{id}/presenca` (UC06)
- **Tipo de operação:** inserção (linha em `presenca_evento`) e atualização (contador `qtd_confirmados` do evento), na mesma transação
- **Arquivos envolvidos:**
  [`EventoController.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/controller/EventoController.java) ·
  [`EventoService.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/service/EventoService.java) ·
  [`EventoRepository.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/repository/EventoRepository.java) ·
  [`EstudanteRepository.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/repository/EstudanteRepository.java) ·
  [`Validacao.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/service/Validacao.java) ·
  [`Solicitante.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/model/Solicitante.java) ·
  [`Evento.java`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/backend/src/main/java/br/unirio/unilink/model/Evento.java) ·
  [`01-schema.sql`](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago/blob/main/database/01-schema.sql) (tabelas `presenca_evento` e `evento`)
- **Código da medição:** [`presenca.js`](presenca.js) e [`comum.js`](comum.js)

### Medição 1

<!-- MEDICAO1:presenca -->
- **Data da medição:** 07/11/2026
- **Requisições no teste:** 35716
- **Limite de concorrência dentro do SLA** (p95 < 2000 ms e erros < 1%): o SLA já não vale no primeiro patamar (10 VUs)

| Concorrência (VUs) | Latência média (ms) | p95 (ms) | Vazão (req/s) | Erros (%) | SLA |
| --- | --- | --- | --- | --- | --- |
| 10 | 23.13 | 32.20 | 9.5 | 1.02 | ❌ |
| 50 | 18.62 | 31.49 | 48.0 | 31.27 | ❌ |
| 100 | 39.93 | 72.81 | 93.7 | 54.97 | ❌ |
| 200 | 33.54 | 69.54 | 188.0 | 67.48 | ❌ |
| 500 | 439.40 | 1077.32 | 328.0 | 86.19 | ❌ |

| Métrica (teste inteiro) | Média | Mediana | Mín | Máx | P95 | P99 |
| --- | --- | --- | --- | --- | --- | --- |
| Latência, `http_req_duration` (ms) | 204.88 | 44.13 | 5.58 | 3082.39 | 859.09 | 1336.64 |
| Tempo bloqueado, `http_req_blocked` (ms) | 3.73 | 1.09 | 0.00 | 395.82 | 10.27 | 64.44 |

![Latência de Confirmar presença](resultados/medicao-1/presenca-latencia.png)
![Vazão de Confirmar presença](resultados/medicao-1/presenca-vazao.png)
![Erros de Confirmar presença](resultados/medicao-1/presenca-erros.png)
![Tempo bloqueado de Confirmar presença](resultados/medicao-1/presenca-bloqueio.png)
<!-- /MEDICAO1:presenca -->

**Hipóteses de potenciais gargalos**

- **O que a medição mostrou:** é o único serviço que quebrou o SLA, e já com 10 VUs (1,02% de erros). Os erros sobem a cada patamar (31% com 50, 55% com 100, 67% com 200 e 86% com 500), e com 500 VUs a vazão parou em 328 req/s e a latência média subiu para 439 ms. A latência continua abaixo de 2 s: o que derruba o SLA são os erros.
- **Deadlock no MySQL:** a mesma transação insere em `presenca_evento` (a chave estrangeira trava a linha do evento para leitura) e depois atualiza `qtd_confirmados` dessa mesma linha. Duas confirmações no mesmo evento ao mesmo tempo se travam, e o MySQL cancela uma delas (`Deadlock found when trying to get lock`), que volta como erro 500.
- **Linha disputada:** todo mundo que confirma presença no mesmo evento atualiza a mesma linha (o contador), então as confirmações acabam sendo feitas uma de cada vez.
- **Consultas extras:** antes de gravar, o serviço confere se o estudante existe e busca o evento, o que dá quatro idas ao banco por confirmação.

### Medição 2

<!-- MEDICAO2:presenca -->
(medição de 16/11)
<!-- /MEDICAO2:presenca -->

<!-- COMPARACAO:presenca -->
<!-- /COMPARACAO:presenca -->

**Melhorias/otimizações:** (16/11: listar os arquivos modificados)

---

## Comparação entre os serviços

### Medição 1

<!-- SERVICOS:1 -->
![Comparação entre os serviços](resultados/medicao-1/comparacao-servicos.png)
<!-- /SERVICOS:1 -->

### Medição 2

<!-- SERVICOS:2 -->
<!-- /SERVICOS:2 -->

---

## Como rodar

Precisa do Docker Desktop, do k6 e do Python com o matplotlib. No Windows, uma vez só:
`winget install k6 --source winget`, `winget install Python.Python.3.12` e, num cmd novo, `pip install matplotlib`.

O código do Unilink está no repositório [unilink-pi2-amanda-thiago](https://github.com/thiagoramos19/unilink-pi2-amanda-thiago). Copie esta pasta `testes-de-carga` para dentro dele antes de rodar.

1. Na pasta do projeto, ligue o sistema: `docker compose up -d --build`.
2. No **cmd**, na pasta do projeto, carregue a massa de dados:

   ```
   docker compose exec -T mysql mysql -uunilink -punilink unilink_db < testes-de-carga\massa-de-dados.sql
   ```

3. Dois cliques em `testes-de-carga\rodar-testes.bat` (medição 1). Para a medição 2, no cmd: `rodar-testes.bat 2`.
   No fim ele chama o `graficos.py`, que gera os gráficos em `resultados\medicao-N` e preenche este README.

O teste de confirmar presença grava no banco e o mesmo estudante não pode confirmar duas vezes o mesmo evento.
Para repetir uma medição, recrie o banco antes (`docker compose down -v`, `docker compose up -d --build` e o passo 2).
Os CSVs brutos (`resultados\medicao-N\bruto`) são grandes e não vão para o repositório.
