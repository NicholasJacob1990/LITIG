// Polyfills necessários para React Native Testing Library
// Resolve o problema "Unable to resolve module console"

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
    this.log = stdout.write.bind(stdout);
    this.warn = stderr.write.bind(stderr);
    this.error = stderr.write.bind(stderr);
    this.info = stdout.write.bind(stdout);
    this.debug = stdout.write.bind(stdout);
  },
}));

// Polyfills adicionais para React Native
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;

// Mock para fetch se não estiver disponível
if (!global.fetch) {
  global.fetch = jest.fn();
}

// Mock para URL se não estiver disponível
if (!global.URL) {
  global.URL = class URL {
    constructor(url) {
      this.href = url;
    }
  };
}

// Mock para crypto se não estiver disponível
if (!global.crypto) {
  global.crypto = {
    getRandomValues: jest.fn((arr) => {
      for (let i = 0; i < arr.length; i++) {
        arr[i] = Math.floor(Math.random() * 256);
      }
      return arr;
    }),
  };
} 