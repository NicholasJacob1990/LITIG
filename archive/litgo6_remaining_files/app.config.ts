import { ExpoConfig, ConfigContext } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'LITGO',
  slug: 'litgo5',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/images/icon.png',
  scheme: 'com.anonymous.boltexponativewind',
  userInterfaceStyle: 'automatic',
  splash: {
    image: './assets/images/jacob_logo.png',
    resizeMode: 'contain',
    backgroundColor: '#0F172A'
  },
  ios: {
    supportsTablet: true,
    bundleIdentifier: "com.anonymous.boltexponativewind"
  },
  android: {
    adaptiveIcon: {
      foregroundImage: './assets/images/icon.png',
      backgroundColor: '#0F172A'
    },
    package: "com.anonymous.boltexponativewind"
  },
  web: {
    bundler: "metro",
    output: "static",
    favicon: './assets/images/favicon.png'
  },
  plugins: [
    ...((config.plugins || []).filter((p: any) => p !== 'expo-maps')),
    "expo-router",
  ],
  experiments: {
    "typedRoutes": true
  },
  extra: {
    router: {
      origin: false
    },
    eas: {
      projectId: "2ec83ef1-3235-4926-98c2-107ef29fde7d"
    }
  }
}); 