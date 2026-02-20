# Diabetter

Aplicativo multiplataforma para **controle e acompanhamento de diabetes**, desenvolvido com [Flutter](https://flutter.dev/) e [Supabase](https://supabase.com/).

> **Status do projeto:** em desenvolvimento ativo · versão 1.0.0

---

## Sumário

- [Visão Geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Arquitetura do Projeto](#arquitetura-do-projeto)
- [Pré-requisitos](#pré-requisitos)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Executando o Projeto](#executando-o-projeto)
- [Testes](#testes)
- [Plataformas Suportadas](#plataformas-suportadas)
- [Contribuição](#contribuição)
- [Licença](#licença)

---

## Visão Geral

O **Diabetter** permite que pessoas com diabetes registrem eventos de saúde (glicemia, insulina, alimentação, etc.), visualizem gráficos e tendências, configurem metas glicêmicas, exportem relatórios em PDF e recebam notificações.

O backend é totalmente serverless, utilizando **Supabase** para autenticação, banco de dados (PostgreSQL), Row-Level Security (RLS), Edge Functions e agendamento de cron jobs.

---

## Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| **Autenticação** | Cadastro e login com e-mail/senha via Supabase Auth |
| **Registro de Eventos** | Lançamento de glicemia, insulina, alimentação e atividade física |
| **Dashboard** | Visão consolidada dos registros mais recentes |
| **Gráficos** | Visualização de tendências glicêmicas ao longo do tempo |
| **Perfil** | Configuração de metas glicêmicas e horários de notificação |
| **Onboarding** | Fluxo guiado de boas-vindas e configuração inicial |
| **Exportação PDF** | Geração e compartilhamento de relatórios em PDF |
| **Notificações** | Lembretes via e-mail acionados por Supabase Edge Functions |
| **Predições** | Serviço de projeções baseado no histórico de registros |

---

## Arquitetura do Projeto

```
Diabetter-P1/
├── lib/
│   ├── main.dart                    # Ponto de entrada da aplicação
│   ├── config/
│   │   ├── app_config.dart          # Configurações gerais (mock/produção)
│   │   └── app_theme.dart           # Tema e design system
│   ├── models/
│   │   ├── models.dart              # Modelos de domínio (User, GlucoseRecord…)
│   │   ├── event_record.dart        # Modelo de evento de saúde
│   │   └── plano.dart               # Modelo de plano alimentar
│   ├── repositories/
│   │   ├── repository_interfaces.dart  # Contratos (interfaces) dos repositórios
│   │   ├── auth_repository.dart     # Implementação – autenticação
│   │   ├── health_repository.dart   # Implementação – registros de saúde
│   │   ├── plano_repository.dart    # Implementação – planos alimentares
│   │   └── mocks/                   # Implementações mock para desenvolvimento
│   ├── screens/
│   │   ├── app_shell.dart           # Shell com navegação por abas
│   │   ├── login_screen.dart        # Tela de login
│   │   ├── register_screen.dart     # Tela de cadastro
│   │   ├── onboarding_screen.dart   # Fluxo de onboarding
│   │   ├── dashboard_screen.dart    # Dashboard principal
│   │   ├── record_screen.dart       # Registro de eventos
│   │   ├── charts_screen.dart       # Gráficos e tendências
│   │   ├── profile_screen.dart      # Perfil e configurações
│   │   ├── complementary_data_screen.dart  # Dados complementares
│   │   └── safety_disclaimer_screen.dart   # Aviso de segurança
│   ├── services/
│   │   ├── supabase_service.dart    # Inicialização do Supabase
│   │   ├── charts_service.dart      # Lógica de geração de gráficos
│   │   ├── predictions_service.dart # Serviço de predições
│   │   ├── export_service.dart      # Exportação de relatórios (PDF)
│   │   ├── export_service_io.dart   # Exportação – plataformas nativas
│   │   ├── export_service_web.dart  # Exportação – plataforma web
│   │   └── export_service_stub.dart # Stub para compilação condicional
│   └── widgets/
│       ├── success_dialog.dart      # Diálogo de sucesso reutilizável
│       └── in_construction_dialog.dart  # Diálogo de recurso em construção
├── test/
│   ├── widget_test.dart             # Teste base de widgets
│   ├── repositories/               # Testes de repositórios mock
│   └── services/                   # Testes de serviços (charts, predictions)
├── supabase/
│   ├── schema.sql                   # Schema do banco de dados
│   ├── migrations_v2.sql            # Migrações
│   ├── rls_policies.sql             # Políticas de Row-Level Security
│   ├── triggers.sql                 # Triggers do banco
│   ├── cron_notifications.sql       # Jobs de notificação agendados
│   └── functions/                   # Supabase Edge Functions
├── android/                         # Projeto Android nativo
├── ios/                             # Projeto iOS nativo
├── web/                             # Projeto Web (PWA)
├── linux/                           # Projeto Linux nativo
├── macos/                           # Projeto macOS nativo
├── windows/                         # Projeto Windows nativo
├── pubspec.yaml                     # Dependências e configuração do projeto
├── analysis_options.yaml            # Regras de lint do Dart
├── .env.example                     # Template de variáveis de ambiente
├── POLITICA_DE_PRIVACIDADE.md       # Política de privacidade
└── TERMOS_DE_USO.md                 # Termos de uso
```

### Padrões Adotados

- **Repository Pattern** — interfaces em `repository_interfaces.dart` com implementações concretas (Supabase) e mocks intercambiáveis.
- **Separação por camada** — `models/`, `repositories/`, `services/`, `screens/`, `widgets/`.
- **Compilação condicional** — `export_service_io.dart` / `export_service_web.dart` com stub para suporte multiplataforma.
- **Configuração centralizada** — modo mock vs. produção controlado em `app_config.dart`.

---

## Pré-requisitos

| Ferramenta | Versão Mínima |
|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.0.0 |
| [Dart SDK](https://dart.dev/get-dart) | ≥ 3.0.0, < 4.0.0 (incluso no Flutter) |
| Android Studio **ou** Xcode | Última versão estável |
| Conta no [Supabase](https://supabase.com/) | — |

---

## Configuração do Ambiente

1. **Clone o repositório:**

   ```bash
   git clone https://github.com/Cecili4na/Diabetter-P1.git
   cd Diabetter-P1
   ```

2. **Crie o arquivo de variáveis de ambiente:**

   ```bash
   cp .env.example .env
   ```

   Edite `.env` com suas credenciais do Supabase:

   ```dotenv
   SUPABASE_URL=https://SEU_PROJETO.supabase.co
   SUPABASE_ANON_KEY=sua_anon_key_aqui
   ```

3. **Instale as dependências:**

   ```bash
   flutter pub get
   ```

4. **Verifique a instalação:**

   ```bash
   flutter doctor
   ```

---

## Executando o Projeto

```bash
# Listar dispositivos disponíveis
flutter devices

# Executar no dispositivo/emulador padrão
flutter run

# Executar na web (Chrome)
flutter run -d chrome

# Build de produção para web
flutter build web
```

> **Modo Mock:** para desenvolvimento local sem conexão ao Supabase, defina `useMockRepositories = true` em `lib/config/app_config.dart`.

---

## Testes

```bash
# Executar todos os testes
flutter test

# Executar com relatório de cobertura
flutter test --coverage

# Executar um arquivo de teste específico
flutter test test/services/charts_service_test.dart
```

### Testes Disponíveis

| Arquivo | Cobertura |
|---|---|
| `test/services/charts_service_test.dart` | Serviço de gráficos |
| `test/services/predictions_service_test.dart` | Serviço de predições |
| `test/repositories/mock_health_repository_test.dart` | Repositório mock de saúde |

---

## Plataformas Suportadas

| Plataforma | Status |
|---|---|
| Android | ✅ Suportado |
| iOS | ✅ Suportado |
| Web | ✅ Suportado |
| Linux | ✅ Suportado |
| macOS | ✅ Suportado |
| Windows | ✅ Suportado |

---

## Contribuição

1. Crie um fork do repositório.
2. Crie uma branch para sua feature: `git checkout -b feature/minha-feature`.
3. Faça commit das alterações: `git commit -m 'feat: descrição da alteração'`.
4. Envie para o repositório remoto: `git push origin feature/minha-feature`.
5. Abra um **Pull Request** descrevendo a mudança.

### Convenção de Commits

Este projeto segue o padrão [Conventional Commits](https://www.conventionalcommits.org/):

| Prefixo | Uso |
|---|---|
| `feat:` | Nova funcionalidade |
| `fix:` | Correção de bug |
| `docs:` | Alteração em documentação |
| `refactor:` | Refatoração sem mudança de comportamento |
| `test:` | Adição ou modificação de testes |
| `chore:` | Tarefas de manutenção |

---

## Licença

Este projeto é de uso privado. Consulte os mantenedores para informações sobre licenciamento.
