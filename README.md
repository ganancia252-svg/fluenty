# Fluenta — app de aprendizado de inglês por conversação

MVP full-stack inspirado em apps como a Oddi: **o aluno conversa em inglês com um tutor de IA**, que mantém a
conversa no personagem, corrige erros na hora, adapta a dificuldade ao nível CEFR e acumula vocabulário para revisão
espaçada.

- **Front-end:** React 18 + Vite
- **Back-end:** Node/Express (ESM)
- **Banco:** SQLite (`better-sqlite3`) — arquivo único em `data/fluenta.db`
- **IA:** OpenAI, Google Gemini, Anthropic, OpenRouter ou modo demonstração offline
- **Voz:** modo conversa por voz com reconhecimento de fala do navegador, envio automático ao terminar a fala e narração do tutor (voz neural com chave, ou voz do navegador sem chave)

![Tela de conversa](docs/screens/09-correcao.png)

---

## 0. Testar rápido (sem instalar nada)

Existe uma **demonstração offline em arquivo único**: `demo-offline.html`. Basta abrir no navegador (duplo clique) — o
tutor roda inteiro no próprio arquivo, com conversa, correções, flashcards, relatório e progresso na memória da página.
Serve para mostrar o produto antes de subir servidor ou configurar chave de IA.

O que ela **não** tem (por ser offline): login, banco, IA real, voz neural e histórico persistente — isso está no app
completo, descrito abaixo.

---

Se quiser publicar num **link fixo**, veja `deploy/README.md` (Netlify Drop para o demo, Render/Fly/Docker para o app
completo).

---

## 1. Rodar em 2 minutos

```bash
npm install
npm run seed:demo     # opcional: cria a conta demo com histórico e vocabulário
npm run dev           # API em :4173 + Vite em :5173 (proxy automático de /api)
```

Acesse **http://localhost:5173** (ou o preview que a plataforma mostrar).

**Conta demo:** `demo@fluenta.app` / `demo1234`

Para servir tudo em um endereço único (produção):

```bash
npm run build && npm start        # http://localhost:4173
```

Scripts disponíveis:

| Script | O que faz |
| --- | --- |
| `npm run dev` | sobe API + front simultaneamente (concurrently) |
| `npm run server` | só a API (porta 4173) |
| `npm run client` | só o Vite (porta 5173) |
| `npm run build` | gera o `dist/` do front |
| `npm start` | serve API + front buildado em :4173 |
| `npm run seed:demo` | recria a conta de demonstração |

---

## 2. Ligar a IA de verdade (importante)

O app **funciona 100% sem chave**: nesse modo o tutor responde com um motor local de demonstração (corrige erros
clássicos de brasileiros, mantém a conversa e sugere vocabulário). Para conversa gerada por IA e narração em voz
neural, há dois caminhos:

**A) Chave por usuário (recomendado para vários alunos)** — Perfil → *Motor de IA* → escolher o provedor, colar a chave
e clicar em *Salvar chave* + *Testar conexão*. A chave fica criptografada no banco (AES-256-GCM) e é usada somente
naquele usuário.

**B) Chave no servidor** — copie `.env.example` para `.env`:

```env
AI_PROVIDER=openai      # openai | gemini | anthropic | openrouter | mock
AI_API_KEY=sk-...
SERVER_SECRET=uma-frase-longa-e-secreta
PORT=4173
```

Provedores e observações:

| Provedor | Conversa | Voz neural (TTS) | Nota |
| --- | --- | --- | --- |
| OpenAI | `gpt-4o-mini` | `gpt-4o-mini-tts` (vozes nova, alloy, …) | melhor combinação custo/benefício |
| Gemini | `gemini-2.5-flash` | não (usa voz do navegador) | tem camada gratuita |
| Anthropic | `claude-sonnet-4-5` | não | correções e explicações muito boas |
| OpenRouter | qualquer modelo | não | acesso a dezenas de modelos |
| mock | roteiro local | voz do navegador | **sem chave, sem custo** |

> A chave de IA é do usuário que está usando o app. Nunca a exponha no front-end — todas as chamadas saem do servidor.

---

## 3. O que já está implementado

**Conta e onboarding**
- Cadastro em 3 passos (dados → nível → meta), login, sessão com token de 30 dias
- Teste de nivelamento de 6 questões que sugere o CEFR (A1–B2)
- Senha com scrypt + salt; chaves de API criptografadas

**Conversa com o tutor**
- Cenários em personagem ("Alex", o tutor) com objetivo, foco gramatical e frases-alvo
- Correção não intrusiva: o erro aparece num cartão com a frase original, a versão correta, o porquê em português e o botão *ouvir a versão correta*
- Sugestões de vocabulário a cada turno, com `＋` para mandar direto para a revisão
- Adaptação por nível: aluno que responde pouco recebe apoio; aluno avançado recebe contra-argumentos
- Memória de erros recorrentes: os padrões mais frequentes do aluno entram no prompt das próximas sessões
- Conversação por voz: modo voz liga/desliga, microfone com envio automático ao terminar a fala, narração automática e *push-to-talk* com Ctrl + espaço
- Relatório ao encerrar: nota, respostas, palavras faladas, correções, XP e próximo passo da trilha

**Currículo**
- 35 lições em 12 unidades, de A1 a B2 (apresentação pessoal, compras, viagens, reuniões, negociação, debate, idioms)
- Conversa livre com 10 temas sugeridos
- Trilha mostra o nível do aluno + o nível seguinte (revisão + desafio)

**Progresso e retenção**
- XP por turno, bônus por resposta sem erro, XP de revisão e de conclusão de sessão
- Sequência diária (streak) com recorde, meta diária em minutos e anel de progresso
- Gráfico dos últimos 7 dias, trilha por nível e histórico das últimas 50 conversas
- Revisão espaçada em 6 caixas (1 → 2 → 4 → 8 → 16 → 32 dias) com flashcards e modo "hoje"

---

## 4. Estrutura do projeto

```
fluenta/
├── server/
│   ├── index.js        # API Express: auth, currículo, conversa, vocab, stats, TTS
│   ├── db.js           # SQLite, migrações, scrypt, AES-GCM, streak e XP
│   ├── ai.js           # prompt do tutor + adaptadores (OpenAI/Gemini/Anthropic/OpenRouter) + modo demo
│   ├── curriculum.js   # 35 lições em 12 unidades (A1→B2) e temas livres
│   └── seed.js         # conta de demonstração
├── src/
│   ├── App.jsx         # shell, rotas e sessão
│   ├── api.js          # cliente HTTP + token
│   ├── speech.js       # fala (TTS neural/navegador) e escuta (Web Speech API)
│   ├── styles.css      # design system (neutro, minimalista, responsivo)
│   ├── ui.jsx          # ProgressRing, Modal, Stat, Skeleton, Empty
│   └── screens/        # Auth, Home, Talk, Review, ProgressScreen, Settings
├── docs/screens/       # capturas de tela do app
└── data/               # banco SQLite (criado em runtime, fora do git)
```

### API (resumo)

| Rota | Descrição |
| --- | --- |
| `POST /api/auth/register` · `/login` · `/logout` | conta e sessão |
| `GET/PATCH /api/me` | perfil, nível, meta, voz |
| `PUT/DELETE /api/me/ai-key` | chave de IA do usuário (criptografada) |
| `POST /api/ai/test` | testa a conexão com o provedor |
| `GET /api/curriculum` | trilha com progresso por lição |
| `GET /api/stats` | XP, streak, 7 dias, totais |
| `POST /api/conv/start` · `/:id/message` · `/:id/end` | conversa: abre, gera turno do tutor, fecha com relatório |
| `GET /api/conv` · `/api/conv/:id` | histórico e retomada de sessão |
| `GET/POST /api/vocab` · `POST /api/vocab/:id/review` | revisão espaçada |
| `POST /api/tts` | narração (204 quando não há provedor com voz — o cliente usa a do navegador) |

---

## 5. Telemetria de uso

O `payload` de cada mensagem do tutor guarda a correção, o vocabulário sugerido e o provedor usado — dá para medir
depois: taxa de erro por tipo de correção, palavras mais sugeridas e aproveitamento por lição.

## 6. Limites deste MVP (o que falta para produção)

- **Autenticação:** token simples funciona, mas o ideal é cookie httpOnly + refresh token, verificação de e-mail e recuperação de senha.
- **Voz:** o reconhecimento usa a Web Speech API (Chrome/Edge); para iOS/Safari o caminho é gravar áudio e mandar para um STT (Whisper) no servidor.
- **Escala:** SQLite atende bem até algumas centenas de alunos simultâneos; para mais, migrar para Postgres.
- **Pagamento:** não há cobrança/planos — o app é Free de ponta a ponta.
- **Moderação/abuso:** sem rate limit por usuário nas chamadas de IA.
- **Sem app mobile nativo:** o layout responde bem no celular, mas não há build iOS/Android.

---

## 7. Capturas de tela

| | |
| --- | --- |
| ![Boas-vindas](docs/screens/01-boas-vindas.png) | ![Início](docs/screens/07-inicio-conta-demo.png) |
| ![Conversa](docs/screens/08-conversa.png) | ![Correção](docs/screens/09-correcao.png) |
| ![Relatório](docs/screens/11-relatorio.png) | ![Vocabulário](docs/screens/13-flashcard-revelado.png) |
| ![Progresso](docs/screens/14-progresso.png) | ![Perfil](docs/screens/15-perfil.png) |
