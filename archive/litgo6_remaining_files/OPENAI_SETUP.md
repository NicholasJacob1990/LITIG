# 🤖 Configuração da OpenAI API (ChatGPT)

Este aplicativo foi atualizado para usar a API do ChatGPT (OpenAI) em vez do Google Gemini.

## 📋 Passos para Configuração

### 1. Obter a Chave da API

1. Acesse [platform.openai.com](https://platform.openai.com/)
2. Faça login ou crie uma conta
3. Navegue para "API Keys" no menu lateral
4. Clique em "Create new secret key"
5. Copie a chave gerada (ela só aparece uma vez!)

### 2. Configurar no Projeto

1. Abra o arquivo `.env` na raiz do projeto
2. Substitua `SUA_CHAVE_OPENAI_AQUI` pela sua chave real:

```bash
EXPO_PUBLIC_OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Modelos Disponíveis

O aplicativo está configurado para usar o modelo `gpt-4o-mini`, que é:
- ✅ Mais rápido
- ✅ Mais econômico  
- ✅ Ainda muito capaz para análises jurídicas

Se quiser usar um modelo mais poderoso, edite o arquivo `lib/openai.ts` e mude:
```typescript
model: 'gpt-4o-mini'  // Para gpt-4o ou gpt-4-turbo
```

### 4. Custos Estimados

Para análises jurídicas típicas:
- **gpt-4o-mini**: ~$0.005 por análise
- **gpt-4o**: ~$0.05 por análise
- **gpt-4-turbo**: ~$0.08 por análise

### 5. Testando a Configuração

1. Reinicie o aplicativo
2. Vá para "Triagem Jurídica" (Legal Intake)
3. Descreva um caso jurídico
4. A IA deve responder em JSON estruturado

## 🔒 Segurança

- ✅ Nunca compartilhe sua chave API
- ✅ A chave fica apenas no seu dispositivo local
- ✅ Use variáveis de ambiente (não código-fonte)

## 🆘 Solução de Problemas

### Erro: "A funcionalidade de IA está desativada"
- Verifique se a chave está correta no arquivo `.env`
- Certifique-se de que não há espaços extras

### Erro: "OpenAI API error: 401"
- Sua chave API está incorreta ou expirada
- Gere uma nova chave na plataforma OpenAI

### Erro: "OpenAI API error: 429"  
- Você excedeu o limite de uso
- Verifique seus limites na plataforma OpenAI

## 📞 Suporte

Se tiver problemas, verifique:
1. Arquivo `.env` está configurado corretamente
2. Sua conta OpenAI tem créditos disponíveis
3. A chave API tem as permissões necessárias 