import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import supabase from '../../lib/supabase';
import {
  Eye,
  EyeOff,
  Rocket,
  Zap,
  ShieldCheck,
  TrendingUp,
  Lock,
  CreditCard,
  ArrowRight,
  Building2,
} from 'lucide-react-native';

const { width } = Dimensions.get('window');

const WelcomeView = ({ onLoginPress }: { onLoginPress: () => void }) => {
  const router = useRouter();
  return (
    <ScrollView style={styles.containerScrollView} showsVerticalScrollIndicator={false}>
      <View style={styles.heroContent}>
        <View style={styles.brandContainer}>
          <Text style={styles.brandTitle}>LITGO</Text>
          <View style={styles.brandBadge}>
            <ShieldCheck size={16} color="#10B981" />
            <Text style={styles.brandBadgeText}>Plataforma Oficial</Text>
          </View>
        </View>
        <Text style={styles.brandSubtitle}>Plataforma Jurídica Inteligente</Text>
        <Text style={styles.heroDescription}>
          Conecte-se à justiça com transparência total. Nossa IA realiza pré-análise do seu caso
          antes mesmo do pagamento, garantindo decisões informadas e confiança mútua.
        </Text>

        <TouchableOpacity
          style={styles.primaryCTA}
          onPress={() => router.push('/role-selection')}
          activeOpacity={0.8}>
          <Rocket size={20} color="#FFFFFF" />
          <Text style={styles.primaryCTAText}>Criar Nova Conta</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.secondaryButton} onPress={onLoginPress}>
          <Text style={styles.secondaryButtonText}>Já tenho uma conta</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.contentContainer}>
        <View style={styles.trustSection}>
          <View style={styles.trustCard}>
            <View style={styles.trustIconContainer}>
              <Eye size={24} color="#3B82F6" />
            </View>
            <Text style={styles.trustNumber}>100%</Text>
            <Text style={styles.trustLabel}>Transparente</Text>
            <Text style={styles.trustDescription}>
              Síntese IA compartilhada com cliente e advogado
            </Text>
          </View>

          <View style={styles.trustCard}>
            <View style={styles.trustIconContainer}>
              <Zap size={24} color="#10B981" />
            </View>
            <Text style={styles.trustNumber}>24h</Text>
            <Text style={styles.trustLabel}>Resposta Rápida</Text>
            <Text style={styles.trustDescription}>Atribuição automática de especialistas</Text>
          </View>

          <View style={styles.trustCard}>
            <View style={styles.trustIconContainer}>
              <ShieldCheck size={24} color="#F59E0B" />
            </View>
            <Text style={styles.trustNumber}>LGPD</Text>
            <Text style={styles.trustLabel}>Compliance Total</Text>
            <Text style={styles.trustDescription}>Conformidade OAB e proteção de dados</Text>
          </View>
        </View>

        <View style={styles.processSection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Como Funciona</Text>
            <Text style={styles.sectionSubtitle}>
              Processo transparente e inteligente em 3 etapas principais
            </Text>
          </View>

          <View style={styles.processSteps}>
            <View style={styles.processStep}>
              <View style={styles.stepIconContainer}>
                <View style={styles.stepIcon}>
                  <Text style={styles.stepIconText}>1</Text>
                </View>
                <View style={styles.stepConnector} />
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>Descrição do Caso</Text>
                <Text style={styles.stepDescription}>
                  Descreva sua questão jurídica através de texto ou voz. Nossa IA classifica
                  automaticamente área e urgência.
                </Text>
              </View>
            </View>

            <View style={styles.processStep}>
              <View style={styles.stepIconContainer}>
                <View style={styles.stepIcon}>
                  <Text style={styles.stepIconText}>2</Text>
                </View>
                <View style={styles.stepConnector} />
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>Análise Prévia por IA</Text>
                <Text style={styles.stepDescription}>
                  Receba uma síntese jurídica preliminar antes do pagamento. Transparência total
                  desde o início.
                </Text>
              </View>
            </View>

            <View style={styles.processStep}>
              <View style={styles.stepIconContainer}>
                <View style={styles.stepIcon}>
                  <Text style={styles.stepIconText}>3</Text>
                </View>
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>Atendimento Especializado</Text>
                <Text style={styles.stepDescription}>
                  Advogado especialista assume o caso com base na análise prévia. Chat ou vídeo
                  com IA assistente.
                </Text>
              </View>
            </View>
          </View>
        </View>

        <View style={styles.benefitsSection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Por que Escolher LITGO?</Text>
          </View>

          <View style={styles.benefitsGrid}>
            <View style={styles.benefitCard}>
              <View style={styles.benefitIcon}>
                <TrendingUp size={24} color="#3B82F6" />
              </View>
              <Text style={styles.benefitTitle}>Inteligência Artificial Jurídica</Text>
              <Text style={styles.benefitDescription}>
                Triagem automática e sugestões de jurisprudência em tempo real durante o
                atendimento.
              </Text>
            </View>

            <View style={styles.benefitCard}>
              <View style={styles.benefitIcon}>
                <Eye size={24} color="#10B981" />
              </View>
              <Text style={styles.benefitTitle}>Transparência Total</Text>
              <Text style={styles.benefitDescription}>
                Síntese do caso compartilhada simultaneamente com cliente e advogado antes do
                pagamento.
              </Text>
            </View>

            <View style={styles.benefitCard}>
              <View style={styles.benefitIcon}>
                <Lock size={24} color="#F59E0B" />
              </View>
              <Text style={styles.benefitTitle}>Segurança e Compliance</Text>
              <Text style={styles.benefitDescription}>
                Conformidade total com LGPD, Provimento 205 OAB e criptografia de ponta a ponta.
              </Text>
            </View>

            <View style={styles.benefitCard}>
              <View style={styles.benefitIcon}>
                <CreditCard size={24} color="#EF4444" />
              </View>
              <Text style={styles.benefitTitle}>Pagamento Flexível</Text>
              <Text style={styles.benefitDescription}>
                Escolha entre modalidades: Ato, Hora, Êxito ou Assinatura. PIX e cartão aceitos.
              </Text>
            </View>
          </View>
        </View>

        <View style={styles.finalCTASection}>
            <Text style={styles.finalCTATitle}>Pronto para Começar?</Text>
            <Text style={styles.finalCTADescription}>
              Obtenha sua análise jurídica preliminar gratuita em minutos
            </Text>
            <TouchableOpacity
              style={styles.secondaryCTA}
              onPress={() => router.push('/role-selection')}
              activeOpacity={0.8}>
              <ArrowRight size={18} color="#10B981" />
              <Text style={styles.secondaryCTAText}>Consultar Agora</Text>
            </TouchableOpacity>
        </View>

        <View style={styles.legalFooter}>
          <View style={styles.legalHeader}>
            <Building2 size={20} color="#3B82F6" />
            <Text style={styles.legalTitle}>JACOBS ADVOGADOS ASSOCIADOS</Text>
          </View>
          <Text style={styles.legalText}>
            Esta plataforma é um canal oficial do escritório Jacobs Advogados Associados. A
            análise preliminar gerada por inteligência artificial é sujeita à conferência e
            validação por advogado qualificado, em conformidade com o art. 34, VII do EOAB.
          </Text>
          <Text style={styles.legalText}>
            Dados protegidos conforme LGPD. Retenção de 5 anos, posterior pseudonimização.
          </Text>
        </View>
      </View>
    </ScrollView>
  );
};

const LoginView = ({ onBackPress }: { onBackPress: () => void }) => {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [isPasswordVisible, setIsPasswordVisible] = useState(false);

  const handleLogin = async () => {
    setLoading(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      Alert.alert('Erro no Login', error.message);
    } else {
      router.replace('/(tabs)');
    }
    setLoading(false);
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={styles.loginContainer}>
      <Text style={styles.loginTitle}>Acesse sua Conta</Text>
      <TextInput
        style={styles.input}
        placeholder="E-mail"
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        autoCapitalize="none"
        placeholderTextColor="#9CA3AF"
      />
      <View style={styles.passwordContainer}>
        <TextInput
          style={styles.passwordInput}
          placeholder="Senha"
          value={password}
          onChangeText={setPassword}
          secureTextEntry={!isPasswordVisible}
          placeholderTextColor="#9CA3AF"
        />
        <TouchableOpacity
          onPress={() => setIsPasswordVisible(!isPasswordVisible)}
          style={styles.eyeIcon}>
          {isPasswordVisible ? (
            <EyeOff size={20} color="#6B7280" />
          ) : (
            <Eye size={20} color="#6B7280" />
          )}
        </TouchableOpacity>
      </View>

      <TouchableOpacity style={styles.primaryButton} onPress={handleLogin} disabled={loading}>
        {loading ? (
          <ActivityIndicator color="#1F2937" />
        ) : (
          <Text style={styles.primaryButtonText}>Entrar</Text>
        )}
      </TouchableOpacity>
      <TouchableOpacity style={styles.secondaryButton} onPress={onBackPress}>
        <Text style={styles.secondaryButtonText}>Voltar</Text>
      </TouchableOpacity>
    </KeyboardAvoidingView>
  );
};

export default function AuthIndex() {
  const [view, setView] = useState<'welcome' | 'login'>('welcome');

  return (
    <LinearGradient colors={['#1F2937', '#111827']} style={styles.container}>
      <SafeAreaView style={styles.safeArea}>
        {view === 'welcome' ? (
          <WelcomeView onLoginPress={() => setView('login')} />
        ) : (
          <LoginView onBackPress={() => setView('welcome')} />
        )}
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  safeArea: {
    flex: 1,
  },
  containerScrollView: {
    flex: 1,
  },
  heroGradient: {
    paddingTop: 80,
    paddingBottom: 60,
    paddingHorizontal: 24,
  },
  heroContent: {
    alignItems: 'center',
    paddingTop: 60,
    paddingBottom: 40,
    paddingHorizontal: 24,
  },
  brandContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  brandTitle: {
    fontSize: 42,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 3,
    marginRight: 12,
  },
  brandBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  brandBadgeText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
    marginLeft: 4,
  },
  brandSubtitle: {
    fontSize: 18,
    color: '#E2E8F0',
    marginBottom: 24,
    textAlign: 'center',
    fontWeight: '500',
  },
  heroDescription: {
    fontSize: 16,
    color: '#FFFFFF',
    textAlign: 'center',
    lineHeight: 26,
    marginBottom: 40,
    opacity: 0.95,
    paddingHorizontal: 10,
  },
  primaryCTA: {
    backgroundColor: '#3B82F6',
    paddingVertical: 18,
    paddingHorizontal: 40,
    borderRadius: 50,
    flexDirection: 'row',
    alignItems: 'center',
    elevation: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    marginBottom: 16,
  },
  primaryCTAText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '700',
    marginLeft: 8,
  },
  contentContainer: {
    paddingHorizontal: 20,
    backgroundColor: '#111827',
  },
  trustSection: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginVertical: 40,
    gap: 12,
  },
  trustCard: {
    flex: 1,
    backgroundColor: '#1F2937',
    padding: 20,
    borderRadius: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#374151',
  },
  trustIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#374151',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  trustNumber: {
    fontSize: 28,
    fontWeight: '800',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  trustLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: '#D1D5DB',
    marginBottom: 8,
    textAlign: 'center',
  },
  trustDescription: {
    fontSize: 12,
    color: '#9CA3AF',
    textAlign: 'center',
    lineHeight: 16,
  },
  processSection: {
    marginBottom: 40,
  },
  sectionHeader: {
    alignItems: 'center',
    marginBottom: 32,
  },
  sectionTitle: {
    fontSize: 32,
    fontWeight: '800',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 12,
  },
  sectionSubtitle: {
    fontSize: 16,
    color: '#9CA3AF',
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: 20,
  },
  processSteps: {
    gap: 32,
  },
  processStep: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  stepIconContainer: {
    alignItems: 'center',
    marginRight: 20,
  },
  stepIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#3B82F6',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  stepIconText: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '800',
  },
  stepConnector: {
    width: 2,
    height: 40,
    backgroundColor: '#374151',
  },
  stepContent: {
    flex: 1,
    paddingTop: 8,
  },
  stepTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  stepDescription: {
    fontSize: 15,
    color: '#D1D5DB',
    lineHeight: 22,
  },
  benefitsSection: {
    marginBottom: 40,
  },
  benefitsGrid: {
    gap: 16,
  },
  benefitCard: {
    backgroundColor: '#1F2937',
    padding: 24,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#374151',
  },
  benefitIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#374151',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  benefitTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  benefitDescription: {
    fontSize: 14,
    color: '#9CA3AF',
    lineHeight: 20,
  },
  finalCTASection: {
    marginBottom: 40,
    borderRadius: 20,
    overflow: 'hidden',
    backgroundColor: '#10B981',
    padding: 40,
    alignItems: 'center',
  },
  finalCTATitle: {
    fontSize: 28,
    fontWeight: '800',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 12,
  },
  finalCTADescription: {
    fontSize: 16,
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 32,
    opacity: 0.95,
    lineHeight: 24,
  },
  secondaryCTA: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 50,
    flexDirection: 'row',
    alignItems: 'center',
  },
  secondaryCTAText: {
    color: '#10B981',
    fontSize: 16,
    fontWeight: '700',
    marginLeft: 8,
  },
  legalFooter: {
    backgroundColor: '#1F2937',
    padding: 24,
    borderRadius: 16,
    marginBottom: 40,
    borderWidth: 1,
    borderColor: '#374151',
  },
  legalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  legalTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: '#FFFFFF',
    textAlign: 'center',
    letterSpacing: 1,
    marginLeft: 8,
  },
  legalText: {
    fontSize: 13,
    color: '#9CA3AF',
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 12,
  },
  loginContainer: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  loginTitle: {
    fontSize: 32,
    fontFamily: 'Inter-Bold',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 24,
  },
  input: {
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderRadius: 8,
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: '#1F2937',
    marginBottom: 16,
  },
  passwordContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderRadius: 8,
    marginBottom: 24,
  },
  passwordInput: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: '#1F2937',
  },
  eyeIcon: {
    padding: 12,
  },
  primaryButton: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 5,
    elevation: 8,
  },
  primaryButtonText: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
  },
  secondaryButton: {
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  secondaryButtonText: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#FFFFFF',
  },
}); 