module.exports = function(api) {
  api.cache(true);
  
  const isTest = process.env.NODE_ENV === 'test';
  
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      !isTest && 'react-native-reanimated/plugin',
      [
        'module-resolver',
        {
          root: ['./'],
          alias: {
            '@': './',
            '@/lib': './lib',
            '@/components': './components',
            '@/app': './app',
            '@/assets': './assets',
            '@/hooks': './hooks',
          },
        },
      ],
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