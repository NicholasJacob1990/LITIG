const { getDefaultConfig } = require('@expo/metro-config');
const path = require('path');

const config = getDefaultConfig(__dirname);

// Resolver problemas de compatibilidade
config.resolver.extraNodeModules = {
  ...(config.resolver.extraNodeModules || {}),
  'react-native-safe-area-context': path.resolve(__dirname, 'shims/react-native-safe-area-context'),
  '@daily-co/daily-js': path.resolve(__dirname, 'node_modules/@daily-co/react-native-daily-js'),
};

// Resolver problemas com módulos nativos no web
config.resolver.platforms = ['ios', 'android', 'native', 'web'];

// Resolver problemas com Stripe e outros módulos nativos
config.resolver.resolverMainFields = ['react-native', 'browser', 'main'];

// Resolver problemas com testing-library
config.resolver.blockList = [
  /node_modules\/@testing-library\/react-native\/build\/helpers\/logger\.js$/,
];

// Resolver problemas com módulos Node.js
config.resolver.alias = {
  ...(config.resolver.alias || {}),
  'console': false,
  'react-native/Libraries/Utilities/codegenNativeCommands': false,
};

module.exports = config; 