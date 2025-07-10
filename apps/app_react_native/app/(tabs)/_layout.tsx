import React from 'react';
import { Tabs, useRouter } from 'expo-router';
import { Home, Briefcase, User, Users, CreditCard, Gift, Star } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';
import { View, ActivityIndicator } from 'react-native';

const PRIMARY_COLOR = '#0D47A1';
const GREY_COLOR = '#64748B';

function AppTabs() {
  const { role } = useAuth();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: PRIMARY_COLOR,
        tabBarInactiveTintColor: GREY_COLOR,
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '500',
        },
        tabBarStyle: {
          borderTopWidth: 1,
          borderTopColor: '#E5E7EB',
          paddingTop: 5,
          paddingBottom: 5,
          height: 60,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Início',
          tabBarIcon: ({ color, size }) => <Home color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="(cases)"
        options={{
          title: 'Meus Casos',
          tabBarIcon: ({ color, size }) => <Briefcase color={color} size={size} />,
        }}
      />
      
      {role === 'client' && (
        <Tabs.Screen
          name="(internal)/recomendacoes"
          options={{
            title: 'Recomendações',
            tabBarIcon: ({ color, size }) => <Star color={color} size={size} />,
          }}
        />
      )}

      {role === 'lawyer' && (
        <Tabs.Screen
          name="ofertas/index"
          options={{
            title: 'Ofertas',
            tabBarIcon: ({ color, size }) => <Gift color={color} size={size} />,
          }}
        />
      )}

      <Tabs.Screen
        name="financeiro"
        options={{
          title: 'Financeiro',
          tabBarIcon: ({ color, size }) => <CreditCard color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Perfil',
          tabBarIcon: ({ color, size }) => <User color={color} size={size} />,
        }}
      />

      {/* Ocultar rotas que não devem aparecer como abas */}
      <Tabs.Screen name="advogados" options={{ href: null }} />
      <Tabs.Screen name="(internal)" options={{ href: null }} />
      <Tabs.Screen name="(clientes)" options={{ href: null }} />
      <Tabs.Screen name="(contract)" options={{ href: null }} />

    </Tabs>
  );
}

export default function TabsLayout() {
  const { isLoading } = useAuth();

  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color={PRIMARY_COLOR} />
      </View>
    );
  }

  return <AppTabs />;
}