import { Stack } from 'expo-router';
import React from 'react';

export default function AuthLayout() {
  return (
    <Stack>
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen name="role-selection" options={{ title: 'Criar Conta', headerBackTitle: 'Voltar' }} />
      <Stack.Screen name="register-client" options={{ title: 'Cadastro de Cliente', headerBackTitle: 'Voltar' }} />
      <Stack.Screen name="register-lawyer" options={{ title: 'Habilitação de Advogado', headerBackTitle: 'Voltar' }} />
    </Stack>
  );
} 