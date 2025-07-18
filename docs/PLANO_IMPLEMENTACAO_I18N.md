# Plano de Implementação: Internacionalização (i18n)

**Data:** 19 de Janeiro de 2025  
**Autor:** Análise Técnica LITIG-1  
**Status:** Planejado

---

## 1. Visão Geral e Objetivos

Este documento detalha a estratégia e os passos para refatorar o aplicativo LITIG-1, adicionando suporte a múltiplos idiomas (Internacionalização, ou i18n) de forma escalável, manutenível e seguindo as melhores práticas do ecossistema Flutter.

-   **Objetivo Principal:** Remover todos os textos "hardcoded" da base de código da UI e substituí-los por um sistema que carrega o texto apropriado com base no idioma selecionado pelo usuário ou pelo sistema operacional.
-   **Idiomas Iniciais:**
    -   `pt` (Português) - Idioma base atual do sistema.
    -   `en` (Inglês) - Primeiro idioma de tradução para expansão.
-   **Escalabilidade:** A arquitetura deve permitir a adição fácil de novos idiomas (ex: `es` para Espanhol) no futuro, apenas adicionando um novo arquivo de tradução, sem a necessidade de alterar o código Dart.

---

## 2. Tecnologia Selecionada

-   **Framework:** `flutter_localizations`
    -   **Justificativa:** É o pacote oficial do Flutter, garantindo integração perfeita com o `MaterialApp`, suporte a widgets nativos (como `DatePicker`), e conformidade com as melhores práticas da plataforma.

-   **Formato de Arquivo:** `ARB (.arb)` - Application Resource Bundle
    -   **Justificativa:** Formato recomendado oficialmente pelo Flutter e Google. É superior ao JSON para i18n por oferecer suporte nativo a funcionalidades essenciais como:
        -   **Placeholders:** Inserir variáveis dentro dos textos (ex: "Bem-vindo, {userName}").
        -   **Pluralização:** Lidar com textos que mudam com base em uma contagem (ex: "1 caso" vs. "5 casos").
        -   **Seleção:** Escolher textos com base em um valor, como gênero.
        -   **Metadados:** Adicionar descrições para os tradutores (`@key_name`) para dar contexto.

-   **Geração de Código:** `intl` e o comando `flutter gen-l10n`
    -   **Justificativa:** Automatiza a criação do código Dart necessário para carregar e acessar os textos. Isso fornece **type safety** (o compilador avisa se uma chave de texto não existe), **autocompletar na IDE**, e elimina erros de digitação em chaves de texto, que são comuns em sistemas baseados em strings.

---

## 3. Estrutura de Arquivos e Configuração

### Passo 1: Adicionar Dependências
No arquivo `apps/app_flutter/pubspec.yaml`, adicionar as dependências e habilitar a geração de código:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Adicionar estas duas linhas
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1 # Usar a versão mais recente

# ... outras dependências

flutter:
  # Garantir que esta linha exista e esteja como true
  generate: true
```

### Passo 2: Configurar a Ferramenta de Geração
Na raiz de `apps/app_flutter/`, criar o arquivo `l10n.yaml`:

```yaml
# apps/app_flutter/l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_pt.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

### Passo 3: Criar os Arquivos de Tradução
No diretório `apps/app_flutter/`, criar a pasta `lib/l10n` e, dentro dela, os arquivos ARB.

**Arquivo de Modelo (Português):**
```jsonc
// lib/l10n/app_pt.arb
{
  "@@locale": "pt",

  "searchTab": "Buscar",
  "@searchTab": { "description": "Texto da aba de busca na tela de advogados" },

  "recommendationsTab": "Recomendações",
  "@recommendationsTab": { "description": "Texto da aba de recomendações na tela de advogados" },

  "welcomeUser": "Bem-vindo, {userName}",
  "@welcomeUser": {
    "description": "Saudação ao usuário logado na tela inicial",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "Nicholas"
      }
    }
  },

  "caseCount": "{count, plural, =0{Nenhum caso encontrado} =1{1 caso encontrado} other{{count} casos encontrados}}",
  "@caseCount": {
    "description": "Indica o número de casos em uma lista",
    "placeholders": {
      "count": { "type": "int" }
    }
  }
}
```

**Arquivo de Tradução (Inglês):**
```jsonc
// lib/l10n/app_en.arb
{
  "@@locale": "en",

  "searchTab": "Search",
  "recommendationsTab": "Recommendations",
  "welcomeUser": "Welcome, {userName}",
  "caseCount": "{count, plural, =0{No cases found} =1{1 case found} other{{count} cases found}}"
}
```

### Passo 4: Integrar no MaterialApp
No arquivo `apps/app_flutter/lib/main.dart`, configurar o widget `MaterialApp` para usar o sistema de localização.

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meu_app/l10n/app_localizations.dart'; // Importar a classe gerada

// ...

class MyApp extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ...
      // Adicionar estas 3 propriedades:
      localizationsDelegates: const [
        AppLocalizations.delegate, // Nosso delegate gerado
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', ''), // Português
        Locale('en', ''), // Inglês
      ],
      // O locale será resolvido automaticamente com base nas configurações do SO.
      // Futuramente, podemos controlar isso com um Provider/Bloc.
    );
  }
}
```

---

## 4. Processo de Refatoração

### Geração de Código
Após a configuração, executar `flutter pub get` no terminal. O Flutter irá gerar automaticamente o arquivo `app_localizations.dart` com getters para cada string, garantindo acesso seguro e fácil.

### Estratégia de Uso
A refatoração consistirá em substituir textos estáticos por chamadas à classe gerada.

**Antes:**
```dart
Text('Buscar')
```

**Depois:**
```dart
// Em qualquer widget que tenha acesso ao BuildContext
Text(AppLocalizations.of(context)!.searchTab)
```

**Com Placeholders:**
```dart
// Antes: Text('Bem-vindo, $userName')
// Depois:
Text(AppLocalizations.of(context)!.welcomeUser(userName))
```

### Fases da Refatoração

1.  **Fase 1 (Componentes Recentes e Telas Chave):**
    -   Refatorar todos os textos nos componentes da última sprint: `CompactSearchCard`, `CompactFirmCard`, `InlineSearchFilters`, `FirmTeamScreen`.
    -   Refatorar as telas principais do fluxo de usuário: `LoginScreen`, `RegisterClientScreen`, `RegisterLawyerScreen`.

2.  **Fase 2 (Features Principais):**
    -   Mapear e refatorar as features mais utilizadas: `PartnersScreen`, `CasesScreen`, `CaseDetailScreen`, `OffersScreen`, `ProfileScreen`.

3.  **Fase 3 (Textos em Enums e Models):**
    -   Para textos que vêm de `Enums` (ex: `EntityFilter.label`), criar `extension methods` para obter o texto localizado, recebendo o `BuildContext`.
    
    ```dart
    // Exemplo de como localizar um Enum
    extension EntityFilterExtension on EntityFilter {
      String getLabel(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        switch (this) {
          case EntityFilter.individuais:
            return l10n.filterIndividuals; // 'filterIndividuals' seria uma nova chave no .arb
          case EntityFilter.escritorios:
            return l10n.filterFirms;
          case EntityFilter.todos:
            return l10n.filterAll;
        }
      }
    }
    ```

4.  **Fase 4 (Mensagens de Erro e Feedback):**
    -   Revisar `BLoCs` e `Repositories` para garantir que as mensagens de erro que são exibidas ao usuário (ex: em `SnackBars` ou `Dialogs`) também sejam originadas dos arquivos ARB.

---

## 5. Mecanismo de Troca de Idioma (Pós-refatoração)

Para permitir que o usuário troque de idioma ativamente no aplicativo:

1.  **Gerenciamento de Estado:** Criar um `LocaleCubit` (ou `Provider`) para gerenciar o `Locale` atual do aplicativo.
2.  **Persistência:** Usar o pacote `shared_preferences` para salvar a escolha de idioma do usuário e carregá-la na inicialização do app.
3.  **UI de Configurações:** Criar uma tela de configurações onde o usuário possa selecionar um dos `supportedLocales`. Ao selecionar, o `LocaleCubit` é atualizado.
4.  **Integração Final:** O `MaterialApp` irá ouvir as mudanças no `LocaleCubit` e definir sua propriedade `locale`, reconstruindo a árvore de widgets com o novo idioma sempre que ele for alterado.

---

## 6. Ferramentas e Boas Práticas

-   **IDE Extensions:** Utilizar extensões do VS Code ou Android Studio (como "Flutter Intl" ou "Dart ARB Editor") para facilitar a edição dos arquivos `.arb` e a extração de strings do código para os arquivos de tradução.
-   **Processo para Novos Textos:**
    1.  Adicionar a nova chave e o texto em português ao arquivo `app_pt.arb`.
    2.  Adicionar a mesma chave e a tradução em inglês ao `app_en.arb`.
    3.  A geração de código (`flutter gen-l10n`) será executada automaticamente ao compilar.
    4.  Usar o novo getter (`AppLocalizations.of(context)!.novaChave`) no código Dart.
-   **Contexto para Tradutores:** Sempre que possível, adicionar uma descrição (`@chave`) no arquivo `.arb` para dar contexto a quem for traduzir o texto. 