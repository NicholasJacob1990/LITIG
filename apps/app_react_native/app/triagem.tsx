import { StyleSheet, TouchableOpacity, ScrollView, View, Text, Alert, ActivityIndicator } from 'react-native';
import { useState, useEffect } from 'react';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';
import { ArrowLeft, Bot, CheckCircle } from 'lucide-react-native';

import { createCase, getMatches, startTriage } from '@/lib/services/api';
import { createEmbedding } from '@/lib/openai';
import { useTaskPolling } from '@/hooks/useTaskPolling';

interface TriagemQuestion {
  id: string;
  question: string;
  options: string[];
}

export default function TriagemScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ texto_cliente?: string }>();

  const [isAnalyzing, setIsAnalyzing] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [taskId, setTaskId] = useState<string | null>(null);
  const [questions, setQuestions] = useState<TriagemQuestion[]>([]);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [analysisResult, setAnalysisResult] = useState({
    area: '',
    urgencia: '',
    resumo: ''
  });

  // Hook para polling da tarefa de triagem
  const { taskResult, isLoading: isPolling, error: pollingError } = useTaskPolling(taskId);

  // Simula análise IA inicial
  useEffect(() => {
    setTimeout(() => {
      setIsAnalyzing(false);
      setAnalysisResult({
        area: 'Direito Civil',
        urgencia: 'Média',
        resumo: 'Questão relacionada a contratos e responsabilidade civil.'
      });
      setQuestions([
        {
          id: '1',
          question: 'Há quanto tempo o problema ocorreu?',
          options: ['Menos de 30 dias', '1-6 meses', '6 meses - 1 ano', 'Mais de 1 ano']
        },
        {
          id: '2',
          question: 'Você possui documentos relacionados ao caso?',
          options: ['Sim, todos', 'Sim, alguns', 'Não tenho', 'Não sei quais preciso']
        },
        {
          id: '3',
          question: 'Já procurou orientação jurídica antes?',
          options: ['Nunca', 'Consulta informal', 'Advogado particular', 'Defensoria Pública']
        }
      ]);
    }, 3000);
  }, []);

  // Efeito para lidar com a conclusão da tarefa
  useEffect(() => {
    if (taskResult?.status === 'completed') {
      const caseId = taskResult.result?.result?.case_id;
      if (caseId) {
        // Agora que temos o case_id, buscamos os matches
        fetchAndNavigateToMatches(caseId);
      } else {
        Alert.alert('Erro', 'Não foi possível obter os detalhes do caso após a triagem.');
        setIsSubmitting(false);
      }
    } else if (taskResult?.status === 'failed') {
      Alert.alert('Erro na Triagem', 'Houve um problema ao analisar seu caso. Por favor, tente novamente.');
      setIsSubmitting(false);
    }
  }, [taskResult]);

  const handleAnswer = (questionId: string, answer: string) => {
    setAnswers({ ...answers, [questionId]: answer });
  };

  const handleFinishTriagem = async () => {
    setIsSubmitting(true);
    try {
      const payload = { texto_cliente: `Relato: ${params.texto_cliente}` }; // Simplificado
      const taskResponse = await startTriage(payload);
      setTaskId(taskResponse.task_id); // Inicia o polling
    } catch (error) {
      console.error("Erro ao iniciar a triagem:", error);
      Alert.alert(
        'Erro', 
        'Ocorreu um erro ao processar sua solicitação. Por favor, tente novamente.'
      );
      setIsSubmitting(false);
    }
  };

  const fetchAndNavigateToMatches = async (caseId: string) => {
    try {
      const matches = await getMatches(caseId);
      router.push({
        pathname: '/MatchesPage',
        params: { matches: JSON.stringify(matches) },
      });
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível buscar os advogados recomendados.');
    } finally {
      setIsSubmitting(false);
      setTaskId(null);
    }
  };

  const currentStatusText = () => {
    if (isSubmitting && !isPolling) return 'Enviando para análise...';
    if (isPolling) return 'Processando seu caso...';
    return 'Encontrar Advogado Ideal';
  };

  if (isAnalyzing) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <LinearGradient
          colors={['#1E40AF', '#3B82F6']}
          style={styles.background}
        />
        
        {/* Header com Botão Voltar */}
        <View style={styles.header}>
          <TouchableOpacity 
            style={styles.backButton} 
            onPress={() => router.back()}
          >
            <ArrowLeft size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>

        <View style={styles.loadingContainer}>
          <View style={styles.loadingIcon}>
            <Bot size={48} color="#FFFFFF" />
          </View>
          <Text style={styles.loadingTitle}>Analisando seu caso...</Text>
          <Text style={styles.loadingText}>
            Nossa IA está processando as informações e classificando sua consulta.
          </Text>
          <View style={styles.loadingIndicator}>
            <Text style={styles.loadingDots}>● ● ●</Text>
          </View>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <LinearGradient
        colors={['#1E40AF', '#3B82F6']}
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
          <Text style={styles.headerTitle}>Triagem Inteligente</Text>
          <View style={styles.headerSpacer} />
        </View>
        
        <View style={styles.headerContent}>
          <Text style={styles.title}>Análise Preliminar Concluída</Text>
          <Text style={styles.subtitle}>Etapa 2 de 3</Text>
        </View>
      </LinearGradient>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Análise Inicial */}
        <View style={styles.analysisCard}>
          <View style={styles.cardHeader}>
            <CheckCircle size={24} color="#10B981" />
            <Text style={styles.cardTitle}>Análise Preliminar</Text>
          </View>
          
          <View style={styles.analysisItem}>
            <Text style={styles.analysisLabel}>Área identificada:</Text>
            <Text style={styles.analysisValue}>{analysisResult.area}</Text>
          </View>
          <View style={styles.analysisItem}>
            <Text style={styles.analysisLabel}>Nível de urgência:</Text>
            <Text style={styles.analysisValue}>{analysisResult.urgencia}</Text>
          </View>
          <View style={styles.analysisItem}>
            <Text style={styles.analysisLabel}>Resumo:</Text>
            <Text style={styles.analysisValue}>{analysisResult.resumo}</Text>
          </View>
        </View>

        {/* Perguntas Dinâmicas */}
        <View style={styles.questionsSection}>
          <Text style={styles.sectionTitle}>
            Perguntas Complementares
          </Text>
          <Text style={styles.sectionDescription}>
            Para uma análise mais precisa, responda algumas perguntas adicionais:
          </Text>

          {questions.map((question, index) => (
            <View key={question.id} style={styles.questionCard}>
              <Text style={styles.questionText}>
                {index + 1}. {question.question}
              </Text>
              <View style={styles.optionsContainer}>
                {question.options.map((option) => (
                  <TouchableOpacity
                    key={option}
                    style={[
                      styles.optionButton,
                      answers[question.id] === option && styles.optionButtonSelected
                    ]}
                    onPress={() => handleAnswer(question.id, option)}
                    activeOpacity={0.7}
                  >
                    <Text style={[
                      styles.optionText,
                      answers[question.id] === option && styles.optionTextSelected
                    ]}>
                      {option}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          ))}
        </View>

        {/* Botão de Finalização */}
        <TouchableOpacity 
          style={[
            styles.finishButton,
            (Object.keys(answers).length < questions.length || isSubmitting) && styles.finishButtonDisabled
          ]}
          onPress={handleFinishTriagem}
          disabled={Object.keys(answers).length < questions.length || isSubmitting}
          activeOpacity={0.8}
        >
          <LinearGradient
            colors={(Object.keys(answers).length >= questions.length && !isSubmitting) ? ['#10B981', '#059669'] : ['#9CA3AF', '#6B7280']}
            style={styles.finishButtonGradient}
          >
            {isSubmitting ? (
              <ActivityIndicator size="small" color="#FFFFFF" />
            ) : (
              <Bot size={20} color="#FFFFFF" />
            )}
            <Text style={styles.finishButtonText}>
              {currentStatusText()}
            </Text>
          </LinearGradient>
        </TouchableOpacity>

        {/* Disclaimer */}
        <View style={styles.disclaimer}>
          <Text style={styles.disclaimerText}>
            Esta análise preliminar é gerada por IA e está sujeita à conferência humana por um advogado qualificado.
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
  background: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: 0,
    height: '100%',
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
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  loadingIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
  },
  loadingTitle: {
    fontSize: 24,
    fontFamily: 'Inter-Bold',
    color: '#FFFFFF',
    marginBottom: 16,
    textAlign: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 24,
  },
  loadingIndicator: {
    alignItems: 'center',
  },
  loadingDots: {
    fontSize: 24,
    color: '#FFFFFF',
  },
  analysisCard: {
    backgroundColor: '#FFFFFF',
    padding: 24,
    borderRadius: 16,
    marginBottom: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 20,
  },
  cardTitle: {
    fontSize: 18,
    fontFamily: 'Inter-SemiBold',
    color: '#1F2937',
    marginLeft: 8,
  },
  analysisItem: {
    marginBottom: 16,
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
  },
  questionsSection: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
    marginBottom: 8,
  },
  sectionDescription: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
    marginBottom: 20,
    lineHeight: 20,
  },
  questionCard: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  questionText: {
    fontSize: 16,
    fontFamily: 'Inter-Medium',
    color: '#1F2937',
    marginBottom: 16,
    lineHeight: 24,
  },
  optionsContainer: {
    gap: 8,
  },
  optionButton: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    backgroundColor: '#FFFFFF',
  },
  optionButtonSelected: {
    backgroundColor: '#1E40AF',
    borderColor: '#1E40AF',
  },
  optionText: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#1F2937',
  },
  optionTextSelected: {
    color: '#FFFFFF',
    fontFamily: 'Inter-Medium',
  },
  finishButton: {
    marginBottom: 24,
    borderRadius: 12,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  finishButtonDisabled: {
    shadowOpacity: 0,
    elevation: 0,
  },
  finishButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    paddingHorizontal: 24,
    gap: 8,
  },
  finishButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    marginLeft: 8,
  },
  disclaimer: {
    backgroundColor: '#FEF3C7',
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FCD34D',
    marginBottom: 32,
  },
  disclaimerText: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#92400E',
    textAlign: 'center',
    lineHeight: 18,
  },
}); 