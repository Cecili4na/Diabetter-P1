# Diabetter — Guia técnico (setup e execução)

Este documento contém as instruções de instalação, configuração e execução do Diabetter para revisores, contribuidores e desenvolvedores. Para a apresentação do projeto, ver o [README](../README.md).

---

## Sumário

- [Pré-requisitos](#pré-requisitos)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Executando o Projeto](#executando-o-projeto)
- [Testes](#testes)
- [Plataformas Suportadas](#plataformas-suportadas)
- [Estrutura completa do repositório](#estrutura-completa-do-repositório)

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

> **Modo Mock:** para desenvolvimento local sem conexão ao Supabase, defina `useMockRepositories = true` em `lib/config/app_config.dart`. As implementações mock em `lib/repositories/mocks/` permitem rodar a aplicação completa offline para fins de teste e demonstração.

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
| Android | ✅ |
| iOS | ✅ |
| Web (PWA) | ✅ |
| Linux | ✅ |
| macOS | ✅ |
| Windows | ✅ |

---

## Estrutura completa do repositório

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
│   ├── repositories/                # Testes de repositórios mock
│   └── services/                    # Testes de serviços (charts, predictions)
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

---

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
