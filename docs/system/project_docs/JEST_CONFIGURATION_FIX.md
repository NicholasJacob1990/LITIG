# Correção do Problema "Unable to resolve module console" no Jest

## 🐛 Problema Identificado

O erro ocorria quando executar testes com `@testing-library/react-native`:

```
Unable to resolve module console from /Users/.../node_modules/@testing-library/react-native/build/helpers/logger.js: 
console could not be found within the project or in these directories:
  node_modules
  ../../../node_modules
```

## 🔧 Solução Implementada

### 1. **Configuração do Jest (`jest.config.js`)**

```javascript
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['<rootDir>/jest-setup.js'],
  testEnvironment: 'node', // Mudado de 'jsdom' para 'node'
  setupFiles: ['<rootDir>/jest-polyfills.js'], // Adicionado
  transformIgnorePatterns: [
    'node_modules/(?!(jest-)?@react-native|react-native|@expo|expo|@testing-library|@babel)',
  ],
  // ... outras configurações
};
```

### 2. **Polyfills Necessários (`jest-polyfills.js`)**

```javascript
// Polyfill para console do Node.js
const originalConsole = console;
global.console = {
  ...originalConsole,
  Console: function Console(stdout, stderr) {
    this.log = stdout.write.bind(stdout);
    this.warn = stderr.write.bind(stderr);
    this.error = stderr.write.bind(stderr);
    this.info = stdout.write.bind(stdout);
    this.debug = stdout.write.bind(stdout);
  },
};

// Mock do módulo console para compatibilidade
jest.mock('console', () => ({
  ...console,
  Console: function Console(stdout, stderr) {
    // Implementação do constructor Console
  },
}));
```

### 3. **Configuração do Babel (`babel.config.js`)**

```javascript
module.exports = function(api) {
  api.cache(true);
  
  const isTest = process.env.NODE_ENV === 'test';
  
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      !isTest && 'react-native-reanimated/plugin', // Desabilitado em testes
      // ... outros plugins
    ].filter(Boolean),
    env: {
      test: {
        presets: [
          ['babel-preset-expo', { jsxImportSource: 'react' }],
        ],
      },
    },
  };
};
```

### 4. **Setup de Testes (`jest-setup.js`)**

```javascript
import '@testing-library/jest-native/extend-expect';

// Polyfill para console (no início do arquivo)
const originalConsole = console;
global.console = {
  ...originalConsole,
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
};

// Configuração adicional para React Native
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;
```

## ✅ Resultado

Após implementar essas correções:

- ✅ Todos os testes passam sem o erro do módulo console
- ✅ `@testing-library/react-native` funciona corretamente
- ✅ Mocks do Expo Router e outras bibliotecas funcionam
- ✅ Snapshots são gerados corretamente
- ✅ Ambiente de teste estável

## 📋 Comandos de Teste

```bash
# Executar todos os testes
npm test

# Executar teste específico
npm test -- --testPathPattern=MatchesPage.test.tsx

# Executar testes em modo watch
npm test -- --watch

# Executar testes com cobertura
npm test -- --coverage
```

## 🔍 Arquivos Modificados

- `jest.config.js` - Configuração principal do Jest
- `jest-polyfills.js` - Polyfills para módulos Node.js
- `jest-setup.js` - Setup global de testes
- `babel.config.js` - Configuração específica para ambiente de teste

## 📚 Referências

- [React Native Testing Library](https://callstack.github.io/react-native-testing-library/)
- [Jest Configuration](https://jestjs.io/docs/configuration)
- [Expo Testing](https://docs.expo.dev/develop/unit-testing/)
- [React Native Testing Guide](https://reactnative.dev/docs/testing-overview) 