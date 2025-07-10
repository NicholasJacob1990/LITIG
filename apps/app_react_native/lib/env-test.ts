// Arquivo de teste para verificar variáveis de ambiente
export const testEnvironmentVariables = () => {
  console.log('=== TESTE DE VARIÁVEIS DE AMBIENTE ===');
  console.log('EXPO_PUBLIC_SUPABASE_URL:', process.env.EXPO_PUBLIC_SUPABASE_URL);
  console.log('EXPO_PUBLIC_SUPABASE_ANON_KEY:', process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ? 'Definida' : 'Não definida');
  console.log('EXPO_PUBLIC_API_URL:', process.env.EXPO_PUBLIC_API_URL);
  console.log('NODE_ENV:', process.env.NODE_ENV);
  console.log('=======================================');
  
  return {
    supabaseUrl: process.env.EXPO_PUBLIC_SUPABASE_URL,
    supabaseAnonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
    apiUrl: process.env.EXPO_PUBLIC_API_URL,
    nodeEnv: process.env.NODE_ENV
  };
}; 