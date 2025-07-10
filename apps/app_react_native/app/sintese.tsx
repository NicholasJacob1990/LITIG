import { StyleSheet, TouchableOpacity, ScrollView, View, Text } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';
import { ArrowLeft, CheckCircle, FileText, Calendar, ArrowRight, Shield } from 'lucide-react-native';

export default function SinteseScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  
  // Dados mockados para demonstração (em produção viriam da análise da IA)
  const sinteseData = {
    numeroProtocolo: 'LITGO-2025-0001',
    dataGeracao: new Date().toLocaleDateString('pt-BR'),
    area: 'Direito Civil',
    urgencia: 'Média',
    resumo: 'Questão relacionada a contratos e responsabilidade civil envolvendo prestação de serviços.',
    analiseCompleta: `SÍNTESE JURÍDICA PRELIMINAR

1. RESUMO DOS FATOS:
   O cliente relatou questões contratuais relacionadas à prestação de serviços, com possíveis vícios e necessidade de revisão dos termos acordados.

2. ÁREA JURÍDICA IDENTIFICADA:
   Direito Civil - Contratos e Responsabilidade Civil

3. POSSÍVEIS DIREITOS:
   - Revisão contratual
   - Indenização por danos
   - Rescisão por inadimplemento

4. DOCUMENTOS NECESSÁRIOS:
   - Contrato original
   - Comprovantes de pagamento
   - Correspondências trocadas
   - Evidências dos vícios alegados

5. PRÓXIMOS PASSOS:
   Análise detalhada por advogado especialista em Direito Civil para elaboração de estratégia jurídica adequada.

💡 Esta análise foi gerada pelo LEX-9000 (IA) após triagem conversacional completa.`,
    disclaimer: 'Esta análise preliminar foi gerada por IA e está sujeita à conferência humana por um advogado qualificado.'
  };

  const handleContinuar = () => {
    // Redirecionar para a tela principal
    router.push('/(tabs)');
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <LinearGradient
        colors={['#10B981', '#059669']}
        style={styles.headerGradient}
      >
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity 
            style={styles.backButton} 
            onPress={() => router.back()}
          >
            <ArrowLeft size={24} color="#FFFFFF" />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Síntese Jurídica</Text>
          <View style={styles.headerSpacer} />
        </View>
        
        <View style={styles.headerContent}>
          <Text style={styles.title}>Análise Concluída</Text>
          <Text style={styles.subtitle}>Sua pré-análise está pronta</Text>
        </View>
      </LinearGradient>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Status Card */}
        <View style={styles.statusCard}>
          <View style={styles.statusIcon}>
            <CheckCircle size={32} color="#FFFFFF" />
          </View>
          <Text style={styles.statusTitle}>Pré-análise Concluída</Text>
          <Text style={styles.statusText}>
            Sua consulta foi analisada e um advogado especialista será atribuído ao seu caso.
          </Text>
        </View>

        {/* Protocolo */}
        <View style={styles.protocolCard}>
          <View style={styles.protocolHeader}>
            <FileText size={20} color="#1E40AF" />
            <Text style={styles.protocolLabel}>Número do Protocolo</Text>
          </View>
          <Text style={styles.protocolNumber}>{sinteseData.numeroProtocolo}</Text>
          <Text style={styles.protocolDate}>Gerado em: {sinteseData.dataGeracao}</Text>
        </View>

        {/* Análise Resumida */}
        <View style={styles.analysisCard}>
          <Text style={styles.cardTitle}>Resumo da Análise</Text>
          
          <View style={styles.analysisGrid}>
            <View style={styles.analysisItem}>
              <Text style={styles.analysisLabel}>Área Jurídica:</Text>
              <Text style={styles.analysisValue}>{sinteseData.area}</Text>
            </View>
            
            <View style={styles.analysisItem}>
              <Text style={styles.analysisLabel}>Urgência:</Text>
              <Text style={styles.analysisValue}>{sinteseData.urgencia}</Text>
            </View>
            
            <View style={styles.analysisItem}>
              <Text style={styles.analysisLabel}>Resumo:</Text>
              <Text style={styles.analysisValue}>{sinteseData.resumo}</Text>
            </View>
          </View>
        </View>

        {/* Análise Completa */}
        <View style={styles.fullAnalysisCard}>
          <Text style={styles.cardTitle}>Análise Detalhada</Text>
          <View style={styles.analysisTextContainer}>
            <Text style={styles.analysisText}>{sinteseData.analiseCompleta}</Text>
          </View>
        </View>

        {/* Próximos Passos */}
        <View style={styles.nextStepsCard}>
          <Text style={styles.cardTitle}>Próximos Passos</Text>
          
          <View style={styles.stepItem}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>1</Text>
            </View>
            <Text style={styles.stepText}>
              Um advogado especialista será atribuído ao seu caso
            </Text>
          </View>
          
          <View style={styles.stepItem}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>2</Text>
            </View>
            <Text style={styles.stepText}>
              Você receberá uma mensagem de boas-vindas
            </Text>
          </View>
          
          <View style={styles.stepItem}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>3</Text>
            </View>
            <Text style={styles.stepText}>
              Escolha o plano de atendimento que melhor se adequa ao seu caso
            </Text>
          </View>
        </View>

        {/* Botão de Ação */}
        <TouchableOpacity style={styles.continueButton} onPress={handleContinuar} activeOpacity={0.8}>
          <LinearGradient
            colors={['#1E40AF', '#3B82F6']}
            style={styles.continueButtonGradient}
          >
            <Text style={styles.continueButtonText}>Continuar para Atribuição</Text>
            <ArrowRight size={20} color="#FFFFFF" />
          </LinearGradient>
        </TouchableOpacity>

        {/* Disclaimer */}
        <View style={styles.disclaimer}>
          <Shield size={16} color="#92400E" />
          <Text style={styles.disclaimerText}>
            {sinteseData.disclaimer}
          </Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  headerGradient: {
    paddingTop: 60,
    paddingBottom: 40,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 24,
    marginBottom: 20,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    flex: 1,
    color: '#FFFFFF',
    fontSize: 18,
    fontFamily: 'Inter-SemiBold',
    textAlign: 'center',
  },
  headerSpacer: {
    width: 40,
  },
  headerContent: {
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  title: {
    fontSize: 24,
    fontFamily: 'Inter-Bold',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'center',
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 24,
  },
  statusCard: {
    backgroundColor: '#10B981',
    padding: 24,
    borderRadius: 16,
    alignItems: 'center',
    marginBottom: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  statusIcon: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  statusTitle: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  statusText: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: 'rgba(255, 255, 255, 0.9)',
    textAlign: 'center',
    lineHeight: 24,
  },
  protocolCard: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 12,
    marginBottom: 24,
    borderLeftWidth: 4,
    borderLeftColor: '#1E40AF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  protocolHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  protocolLabel: {
    fontSize: 14,
    fontFamily: 'Inter-Medium',
    color: '#6B7280',
    marginLeft: 8,
  },
  protocolNumber: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#1E40AF',
    marginBottom: 4,
  },
  protocolDate: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#9CA3AF',
  },
  analysisCard: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 12,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  cardTitle: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
    marginBottom: 16,
  },
  analysisGrid: {
    gap: 16,
  },
  analysisItem: {
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  analysisLabel: {
    fontSize: 14,
    fontFamily: 'Inter-Medium',
    color: '#6B7280',
    marginBottom: 4,
  },
  analysisValue: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: '#1F2937',
    lineHeight: 24,
  },
  fullAnalysisCard: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 12,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  analysisTextContainer: {
    backgroundColor: '#F9FAFB',
    padding: 16,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  analysisText: {
    fontSize: 14,
    fontFamily: 'Courier New',
    color: '#374151',
    lineHeight: 22,
  },
  nextStepsCard: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 12,
    marginBottom: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  stepItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  stepNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#1E40AF',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
    marginTop: 2,
  },
  stepNumberText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontFamily: 'Inter-Bold',
  },
  stepText: {
    flex: 1,
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#374151',
    lineHeight: 20,
  },
  continueButton: {
    marginBottom: 24,
    borderRadius: 12,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  continueButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    paddingHorizontal: 24,
    gap: 8,
  },
  continueButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
  },
  disclaimer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: '#FEF3C7',
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FCD34D',
    marginBottom: 32,
  },
  disclaimerText: {
    flex: 1,
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#92400E',
    lineHeight: 18,
    marginLeft: 8,
  },
}); 