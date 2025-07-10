# Guia de Configuração Manual para OAuth do Google Calendar

Este guia detalha os passos para criar as credenciais necessárias para integrar o LITGO5 com o Google Calendar.

## Passo 1: Configurar um Projeto no Google Cloud Platform

1.  **Acesse o [Google Cloud Console](https://console.cloud.google.com/)**.
2.  Crie um novo projeto ou selecione um existente.
    *   Clique no seletor de projetos no topo da página.
    *   Clique em **"Novo projeto"**.
    *   Dê um nome ao projeto (ex: `LITGO5-App`) e clique em **"Criar"**.

## Passo 2: Ativar a API do Google Calendar

1.  No menu de navegação, vá para **"APIs e serviços"** > **"Biblioteca"**.
2.  Procure por **"Google Calendar API"**.
3.  Selecione a API e clique em **"Ativar"**.

## Passo 3: Configurar a Tela de Consentimento OAuth

Esta tela é o que os usuários veem quando autorizam o acesso à sua conta Google.

1.  No menu, vá para **"APIs e serviços"** > **"Tela de consentimento OAuth"**.
2.  Selecione o tipo de usuário **"Externo"** e clique em **"Criar"**.
3.  **Preencha as informações do aplicativo:**
    *   **Nome do app:** LITGO5
    *   **E-mail de suporte do usuário:** (seu e-mail)
    *   **Logotipo do app:** (opcional)
    *   **Informações de contato do desenvolvedor:** (seu e-mail)
4.  Clique em **"Salvar e continuar"**.
5.  **Escopos:**
    *   Clique em **"Adicionar ou remover escopos"**.
    *   Filtre por **"Google Calendar API"**.
    *   Selecione os seguintes escopos:
        *   `.../auth/calendar`
        *   `.../auth/calendar.events`
    *   Clique em **"Atualizar"**.
6.  Clique em **"Salvar e continuar"**.
7.  **Usuários de teste:**
    *   Clique em **"Adicionar usuários"**.
    *   Adicione o endereço de e-mail da conta Google que você usará para testar a integração.
    *   Clique em **"Adicionar"**.
8.  Clique em **"Salvar e continuar"** e depois em **"Voltar para o painel"**.

## Passo 4: Criar as Credenciais de Cliente OAuth 2.0

Você precisará de três credenciais diferentes: uma para **iOS**, uma para **Android** e uma para **Web**.

### 1. Credencial para iOS

1.  No menu, vá para **"APIs e serviços"** > **"Credenciais"**.
2.  Clique em **"Criar credenciais"** > **"ID do cliente OAuth"**.
3.  Selecione **"iOS"** como tipo de aplicativo.
4.  **ID do pacote:** `com.anonymous.boltexponativewind` (Este é o valor do `ios.bundleIdentifier` no seu `app.json`).
5.  Clique em **"Criar"**.
6.  **Copie o "ID do cliente iOS"**. Você precisará dele.

### 2. Credencial para Android

1.  Volte para a tela de **"Credenciais"**.
2.  Clique em **"Criar credenciais"** > **"ID do cliente OAuth"**.
3.  Selecione **"Android"** como tipo de aplicativo.
4.  **Nome do pacote:** `com.anonymous.boltexponativewind` (Este é o valor do `android.package` no seu `app.json`).
5.  **Impressão digital do certificado de assinatura SHA-1:**
    *   No seu terminal, no diretório do projeto, execute:
        ```bash
        npx expo-cli fetch:android:hashes
        ```
    *   Ou, se você tem um build local, use o `keytool`:
        ```bash
        keytool -list -v -keystore ./android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android
        ```
    *   Copie o valor da **"Impressão digital do certificado SHA1"** e cole no campo.
6.  Clique em **"Criar"**.
7.  **Copie o "ID do cliente Android"**. Você precisará dele.

### 3. Credencial para Web

1.  Volte para a tela de **"Credenciais"**.
2.  Clique em **"Criar credenciais"** > **"ID do cliente OAuth"**.
3.  Selecione **"Aplicativo da Web"** como tipo de aplicativo.
4.  **Nome:** `LITGO5 Web Client`
5.  **URIs de redirecionamento autorizados:**
    *   Clique em **"ADICIONAR URI"**.
    *   Adicione os seguintes URIs (um de cada vez):
        *   `https://auth.expo.io/@anonymous/LITGO5` (Substitua `@anonymous/LITGO5` pelo seu slug do Expo, se diferente).
        *   `exp://127.0.0.1:8081/--/expo-auth-session` (Para testes locais com Expo Go).
        *   Você pode precisar adicionar o IP da sua máquina também: `exp://<SEU_IP_LOCAL>:8081`
6.  Clique em **"Criar"**.
7.  Uma janela aparecerá com o **"ID do cliente"** e o **"Segredo do cliente"**. Copie ambos.

## Passo 5: Usar as Credenciais

Agora você tem todas as chaves necessárias:
-   ID do Cliente iOS
-   ID do Cliente Android
-   ID do Cliente Web
-   Segredo do Cliente Web

Execute o script `configure_credentials.sh` no seu terminal e insira esses valores quando solicitado. O script os salvará com segurança no seu arquivo `.env`.

---

**Links Úteis:**
- [Google Cloud Console](https://console.cloud.google.com/)
- [OAuth 2.0 Playground](https://developers.google.com/oauthplayground/)
- [Expo AuthSession Docs](https://docs.expo.dev/guides/authentication/) 