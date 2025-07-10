import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView, Alert, ActivityIndicator, RefreshControl } from 'react-native';
import { useRoute, useNavigation, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { MessageCircle, Video, Phone, FileText, Calendar, Star } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { getCaseById } from '@/lib/services/cases';
import { getLatestReview } from '@/lib/services/reviews';
import { shareCaseInfo } from '@/lib/services/sharing';
import { downloadCaseReport } from '@/lib/services/reports';
import PreAnalysisCard from '@/components/organisms/PreAnalysisCard';
import TopBar from '@/components/layout/TopBar';
import Avatar from '@/components/atoms/Avatar';
import Badge from '@/components/atoms/Badge';
import CaseMeta from '@/components/molecules/CaseMeta';
import { CasesStackParamList } from '@/lib/types/cases';
import { getCaseTasks, Task } from '@/lib/services/tasks';
import NextStepsList from '@/components/organisms/NextStepsList';
import CaseTimeline from '@/components/molecules/CaseTimeline';
import { useQuery } from '@tanstack/react-query';
import CaseHeader from '@/components/organisms/CaseHeader';
import CaseActions from '@/components/molecules/CaseActions';
import { getProcessEvents, ProcessEventData } from '@/lib/services/processEvents';
import { startVideoSession } from '@/lib/services/video';
import { useAuth } from '@/lib/contexts/AuthContext';

type CaseDetailRouteProp = RouteProp<CasesStackParamList, 'CaseDetail'>;
type CaseDetailNavigationProp = NativeStackNavigationProp<CasesStackParamList, 'CaseDetail'>;

export default function CaseDetail() {
  const route = useRoute<CaseDetailRouteProp>();
  const navigation = useNavigation<CaseDetailNavigationProp>();
  const { caseId } = route.params;
  const { role } = useAuth();
  
  const [caseData, setCaseData] = useState<any>(null);
  const [latestReview, setLatestReview] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [timelineEvents, setTimelineEvents] = useState<ProcessEventData[]>([]);
  const [isStartingVideo, setIsStartingVideo] = useState(false);

  const { data: caseDataQuery, isLoading: caseLoading, error: caseError, refetch: refetchCase } = useQuery({
    queryKey: ['case', caseId],
    queryFn: () => getCaseById(caseId),
    enabled: !!caseId,
  });

  const { data: tasksQuery, isLoading: tasksLoading } = useQuery({
    queryKey: ['caseTasks', caseId],
    queryFn: () => getCaseTasks(caseId),
    enabled: !!caseId,
  });

  const { data: timelineEventsQuery, isLoading: timelineLoading } = useQuery({
    queryKey: ['timelineEvents', caseId],
    queryFn: () => getProcessEvents(caseId),
    enabled: !!caseId,
  });

  const isLoading = caseLoading || tasksLoading || timelineLoading;

  const loadCaseDetails = useCallback(async () => {
    await refetchCase();
  }, [refetchCase]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadCaseDetails();
    setRefreshing(false);
  };

  const handleExportPdf = async () => {
    try {
      await downloadCaseReport(caseId);
      Alert.alert('Sucesso', 'O relatório do caso foi salvo em seus downloads.');
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível baixar o relatório.');
      console.error(error);
    }
  };

  const handleStartVideoCall = async () => {
    setIsStartingVideo(true);
    try {
      const sessionData = await startVideoSession(caseId);
      const token = role === 'lawyer' ? sessionData.lawyerToken : sessionData.clientToken;
      
      if (!sessionData.roomUrl || !token) {
        throw new Error('Não foi possível obter os dados da sala ou o token de acesso.');
      }

      navigation.navigate('VideoConsultation', {
        roomUrl: sessionData.roomUrl,
        token: token,
      });

    } catch (error) {
      console.error("Erro ao iniciar videochamada:", error);
      Alert.alert('Erro', 'Não foi possível iniciar a videochamada. Tente novamente.');
    } finally {
      setIsStartingVideo(false);
    }
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <TopBar title="Detalhes do Caso" showBack />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#006CFF" />
          <Text>Carregando...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (caseError) {
    return (
      <SafeAreaView style={styles.container}>
        <TopBar title="Detalhes do Caso" showBack />
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Erro: {caseError.message}</Text>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <Text style={styles.backButtonText}>Voltar</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  if (!caseData) {
    return (
      <SafeAreaView style={styles.container}>
        <TopBar title="Detalhes do Caso" showBack />
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Caso não encontrado</Text>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <Text style={styles.backButtonText}>Voltar</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const { ai_analysis: preAnalysis, lawyer, status, unread_messages: unreadMessages } = caseData;

  const statusLabelMap: Record<string, string> = {
    pending_assignment: 'Aguardando Atribuição',
    assigned: 'Advogado Atribuído',
    in_progress: 'Em Andamento',
    summary_generated: 'Pré-análise Pronta',
    closed: 'Concluído',
    cancelled: 'Cancelado',
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar 
        title={preAnalysis?.classificacao?.area_principal || 'Detalhes do Caso'}
        subtitle={`Caso #${caseId.substring(0, 4)} • ${statusLabelMap[status] || status}`}
        showBack 
        onShare={() => shareCaseInfo(caseData)}
        onExportPdf={handleExportPdf}
      />

      <ScrollView 
        style={styles.content} 
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
      >
        {lawyer && (
          <View style={styles.section}>
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <Text style={styles.cardTitle}>Advogado Responsável</Text>
                <Badge label="Ativo" intent="success" size="small" />
              </View>
              <View style={styles.lawyerSection}>
                <Avatar src={lawyer.avatar_url} name={lawyer.name} size="large" />
                <View style={styles.lawyerInfo}>
                  <Text style={styles.lawyerName}>{lawyer.name}</Text>
                  <Text style={styles.lawyerSpecialty}>{lawyer.specialty}</Text>
                  <View style={styles.lawyerMeta}>
                    <Text style={styles.lawyerExperience}>{lawyer.experience_years || 8} anos</Text>
                    {lawyer.rating > 0 && (
                      <View style={styles.ratingContainer}>
                        <Star size={16} color="#F59E0B" fill="#F59E0B" />
                        <Text style={styles.ratingText}>{lawyer.rating.toFixed(1)}</Text>
                        <Text style={styles.reviewCount}>({lawyer.review_count} avaliações)</Text>
                    </View>
                    )}
                  </View>
                </View>
              </View>

              {latestReview && (
                <View style={styles.latestReviewContainer}>
                  <Text style={styles.latestReviewComment}>"{latestReview.comment}"</Text>
                  <Text style={styles.latestReviewAuthor}>- {latestReview.client?.full_name || 'Cliente'}</Text>
                </View>
              )}
              
              <View style={styles.lawyerActions}>
                <TouchableOpacity style={styles.actionButton} onPress={() => navigation.navigate('CaseChat', { caseId })}>
                  <MessageCircle size={20} color="#006CFF" />
                  <Text style={styles.actionButtonText}>Chat</Text>
                  {unreadMessages > 0 && (
                    <View style={styles.unreadBadge}><Text style={styles.unreadText}>{unreadMessages}</Text></View>
                  )}
                </TouchableOpacity>
                <TouchableOpacity style={styles.actionButton} onPress={handleStartVideoCall} disabled={isStartingVideo}>
                  {isStartingVideo ? <ActivityIndicator size="small" color="#006CFF" /> : <Video size={20} color="#006CFF" />}
                  <Text style={styles.actionButtonText}>Vídeo</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.actionButton} onPress={handleStartVideoCall} disabled={isStartingVideo}>
                  {isStartingVideo ? <ActivityIndicator size="small" color="#006CFF" /> : <Phone size={20} color="#006CFF" />}
                  <Text style={styles.actionButtonText}>Ligar</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        )}

        {caseData.consultation && (
          <View style={styles.section}>
            <View style={styles.card}>
              <Text style={styles.cardTitle}>Informações da Consulta</Text>
              <View style={styles.consultInfo}>
                <View style={styles.consultItem}><Calendar size={16} color="#6B7280" /><Text style={styles.consultLabel}>Data:</Text><Text style={styles.consultValue}>{new Date(caseData.consultation.scheduled_for).toLocaleString('pt-BR')}</Text></View>
                <View style={styles.consultItem}><Text style={styles.consultLabel}>Duração:</Text><Text style={styles.consultValue}>{caseData.consultation.duration_minutes} minutos</Text></View>
                <View style={styles.consultItem}><Text style={styles.consultLabel}>Tipo:</Text><Text style={styles.consultValue}>{caseData.consultation.type}</Text></View>
                <View style={styles.consultItem}><Text style={styles.consultLabel}>Plano:</Text><Badge label={caseData.consultation.plan || 'Plano por Ato'} intent="primary" size="small"/></View>
              </View>
            </View>
          </View>
        )}

        {preAnalysis && (
          <View style={styles.section}>
            <PreAnalysisCard
              area={preAnalysis.classificacao?.area_principal || 'N/A'}
              priority={preAnalysis.priority || 'medium'}
              urgencyLevel={preAnalysis.urgency?.level_numeric || 5}
              summary={preAnalysis.summary || 'Análise não disponível.'}
              requiredDocuments={preAnalysis.required_documents || []}
              consultationCost={preAnalysis.estimated_costs?.consultation || 350}
              representationCost={preAnalysis.estimated_costs?.representation || 2500}
              riskAssessment={preAnalysis.risk_assessment?.summary || 'Risco não avaliado.'}
              onViewFull={() => navigation.navigate('AISummary', { caseId })}
            />
          </View>
        )}

          <View style={styles.section}>
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <Text style={styles.cardTitle}>Documentos</Text>
              <Badge label={(caseData.documents?.length || 0).toString()} intent="secondary" size="small" />
              </View>
            <Text style={styles.documentsCount}>{(caseData.documents?.length || 0)} documento(s) anexado(s)</Text>
            <TouchableOpacity style={styles.viewDocumentsButton} onPress={() => navigation.navigate('CaseDocuments', { caseId })}>
                <FileText size={16} color="#006CFF" />
                <Text style={styles.viewDocumentsText}>Gerenciar Documentos</Text>
              </TouchableOpacity>
            </View>
          </View>

        <View style={styles.section}>
          <NextStepsList 
            steps={tasks || []} 
            loading={tasksLoading}
            onViewAll={() => navigation.navigate('CaseProgress', { caseId })}
          />
        </View>

        <View style={styles.section}>
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardTitle}>Andamento Processual</Text>
              {timelineEvents && timelineEvents.length > 0 &&
                <Badge label={`${timelineEvents.length}`} intent="secondary" size="small" />
              }
            </View>

            {timelineLoading ? (
              <ActivityIndicator color="#006CFF" />
            ) : timelineEvents && timelineEvents.length > 0 ? (
              <View>
                <View style={styles.timelinePreview}>
                  <View style={styles.timelineMarker} />
                  <View>
                    <Text style={styles.eventTitle}>{timelineEvents[0].title}</Text>
                    <Text style={styles.eventDate}>{new Date(timelineEvents[0].event_date).toLocaleDateString('pt-BR')}</Text>
                  </View>
                </View>
                <TouchableOpacity 
                  style={styles.viewMoreButton} 
                  onPress={() => navigation.navigate('CaseProgress', { caseId })}
                >
                  <Text style={styles.viewMoreButtonText}>Ver Andamento Completo</Text>
                </TouchableOpacity>
              </View>
            ) : (
              <Text style={styles.noEventsText}>Nenhum andamento processual disponível.</Text>
            )}
          </View>
        </View>

        {/* Seção de Avaliação - Visível apenas para casos concluídos */}
        {caseData.status === 'closed' && (
          <View style={styles.section}>
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <Text style={styles.cardTitle}>Feedback</Text>
              </View>
              <Text style={styles.feedbackDescription}>
                Sua opinião é muito importante para nós. Por favor, avalie o atendimento recebido neste caso.
              </Text>
              <TouchableOpacity
                style={styles.evaluateButton}
                onPress={() => navigation.navigate('SubmitReview', { caseId, contractId: caseData.contract?.id })}
              >
                <Star size={20} color="#FFFFFF" />
                <Text style={styles.evaluateButtonText}>Avaliar Atendimento</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
        backgroundColor: '#F8FAFC',
  },
      loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
      content: {
        flex: 1,
        paddingHorizontal: 20,
      },
      section: {
        marginVertical: 12,
      },
      card: {
        backgroundColor: '#FFFFFF',
        borderRadius: 16,
        padding: 20,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 3,
      },
      cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
        marginBottom: 16,
      },
      cardTitle: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 18,
        color: '#1F2937',
      },
      lawyerSection: {
        flexDirection: 'row',
        marginBottom: 16,
      },
      lawyerInfo: {
        marginLeft: 16,
        flex: 1,
        justifyContent: 'center',
      },
      lawyerName: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 20,
        color: '#1F2937',
        marginBottom: 4,
      },
      lawyerSpecialty: {
        fontFamily: 'Inter-Regular',
    fontSize: 16,
        color: '#6B7280',
      },
      lawyerMeta: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        marginTop: 8,
      },
      lawyerExperience: {
        fontFamily: 'Inter-Regular',
        fontSize: 14,
        color: '#6B7280',
  },
      ratingContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
      },
      ratingText: {
        fontFamily: 'Inter-Bold',
        fontSize: 14,
        color: '#F59E0B',
        marginLeft: 2,
      },
      reviewCount: {
        fontFamily: 'Inter-Regular',
        fontSize: 12,
    color: '#6B7280',
  },
      latestReviewContainer: {
        marginTop: 16,
        paddingTop: 16,
        borderTopWidth: 1,
        borderTopColor: '#F3F4F6',
      },
      latestReviewComment: {
        fontFamily: 'Inter-Italic',
        fontSize: 14,
        color: '#4B5563',
        lineHeight: 20,
      },
      latestReviewAuthor: {
        fontFamily: 'Inter-Medium',
        fontSize: 12,
        color: '#6B7280',
        textAlign: 'right',
        marginTop: 8,
      },
      lawyerActions: {
        flexDirection: 'row',
        gap: 12,
        paddingTop: 16,
        borderTopWidth: 1,
        borderTopColor: '#F3F4F6',
      },
      actionButton: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#F0F9FF',
        paddingVertical: 12,
        borderRadius: 12,
        gap: 8,
        position: 'relative',
      },
      actionButtonText: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 14,
        color: '#006CFF',
      },
      unreadBadge: {
        position: 'absolute',
        top: -4,
        right: -4,
        backgroundColor: '#E44C2E',
        borderRadius: 10,
        minWidth: 20,
        height: 20,
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 2,
        borderColor: '#FFFFFF',
      },
      unreadText: {
        fontFamily: 'Inter-Bold',
        fontSize: 10,
        color: '#FFFFFF',
      },
      consultInfo: {
        gap: 12,
      },
      consultItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
      },
      consultLabel: {
        fontFamily: 'Inter-Medium',
        fontSize: 14,
        color: '#6B7280',
        minWidth: 80,
      },
      consultValue: {
        fontFamily: 'Inter-Regular',
        fontSize: 14,
        color: '#1F2937',
        flex: 1,
      },
      documentsCount: {
        fontFamily: 'Inter-Regular',
        fontSize: 14,
        color: '#6B7280',
        marginBottom: 16,
      },
      viewDocumentsButton: {
    flexDirection: 'row',
    alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#F0F9FF',
        paddingVertical: 12,
        borderRadius: 12,
        gap: 8,
      },
      viewDocumentsText: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 14,
        color: '#006CFF',
      },
      errorContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        paddingHorizontal: 20,
      },
      errorText: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 18,
        color: '#1F2937',
        marginBottom: 20,
      },
      backButton: {
        backgroundColor: '#006CFF',
        paddingHorizontal: 24,
        paddingVertical: 12,
    borderRadius: 8,
      },
      backButtonText: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 16,
        color: '#FFFFFF',
  },
      feedbackDescription: {
        fontFamily: 'Inter-Regular',
        fontSize: 14,
        color: '#4B5563',
        marginBottom: 16,
        lineHeight: 20,
      },
      evaluateButton: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#10B981',
        paddingVertical: 12,
        borderRadius: 12,
        gap: 8,
      },
      evaluateButtonText: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 16,
        color: '#FFFFFF',
      },
      sectionTitle: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 18,
        color: '#1F2937',
        marginBottom: 12,
      },
      timelinePreview: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingVertical: 8,
      },
      timelineMarker: {
        width: 12,
        height: 12,
        borderRadius: 6,
        backgroundColor: '#006CFF',
        borderWidth: 2,
        borderColor: '#E0EFFF',
      },
      eventTitle: {
        fontFamily: 'Inter-Medium',
        fontSize: 14,
        color: '#1F2937',
      },
      eventDate: {
        fontFamily: 'Inter-Regular',
        fontSize: 12,
        color: '#6B7280',
      },
      viewMoreButton: {
        backgroundColor: '#F3F4F6',
        paddingVertical: 12,
        borderRadius: 10,
        alignItems: 'center',
        marginTop: 16,
      },
      viewMoreButtonText: {
        fontFamily: 'Inter-SemiBold',
        fontSize: 14,
        color: '#374151',
      },
      noEventsText: {
        fontFamily: 'Inter-Regular',
        fontSize: 14,
        color: '#6B7280',
        textAlign: 'center',
        paddingVertical: 16,
      },
}); 