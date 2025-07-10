import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView, Alert } from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { ArrowLeft, MessageCircle, Video, Phone, FileText, Calendar, DollarSign, AlertTriangle } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { mockCases, mockDetailedData } from './MyCasesList';
import { getCaseById } from '@/lib/services/cases';
import { shareCaseInfo, shareCaseReport } from '@/lib/services/sharing';
import PreAnalysisCard from '@/components/organisms/PreAnalysisCard';
import CaseCard from '@/components/organisms/CaseCard';
import CostRiskCard from '@/components/organisms/CostRiskCard';
import DocumentsList from '@/components/organisms/DocumentsList';
import TopBar from '@/components/layout/TopBar';
import Avatar from '@/components/atoms/Avatar';
import Badge from '@/components/atoms/Badge';
import ProgressBar from '@/components/atoms/ProgressBar';
import MoneyTile from '@/components/atoms/MoneyTile';
import StepItem from '@/components/molecules/StepItem';

export default function CaseDetail() {
  const route = useRoute<any>();
  const navigation = useNavigation();
  const { caseId } = route.params;
  
  const caseData = mockCases.find(c => c.id === caseId);
  const detailedData = mockDetailedData[caseId as keyof typeof mockDetailedData];

  if (!caseData) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Caso não encontrado</Text>
          <TouchableOpacity 
            style={styles.backButton}
            onPress={() => navigation.goBack()}
          >
            <Text style={styles.backButtonText}>Voltar</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar 
        title="Detalhes do Caso" 
        showBack 
        showShare 
        onShare={() => shareCaseInfo(caseData)}
      />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Case Overview Card */}
        <View style={styles.section}>
          <CaseCard
            {...caseData}
            onPress={() => {}}
            onViewSummary={() => navigation.navigate('AISummary', { caseId })}
            onChat={() => navigation.navigate('CaseChat', { caseId })}
          />
        </View>

        {/* Pre-Analysis Card */}
        {detailedData?.preAnalysis && (
          <View style={styles.section}>
            <PreAnalysisCard
              {...detailedData.preAnalysis}
              onViewFull={() => navigation.navigate('AISummary', { caseId })}
              onViewDetailedAnalysis={() => navigation.navigate('DetailedAnalysis', { caseId })}
              onScheduleConsult={() => navigation.navigate('ScheduleConsult', { caseId })}
            />
          </View>
        )}

        {/* Lawyer Card */}
        {caseData.lawyer && (
          <View style={styles.section}>
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <Text style={styles.cardTitle}>Advogado Responsável</Text>
                <Badge label="Ativo" intent="success" size="small" />
              </View>
              
              <View style={styles.lawyerSection}>
                <Avatar
                  src={caseData.lawyer.avatar}
                  name={caseData.lawyer.name}
                  size="large"
                />
                <View style={styles.lawyerInfo}>
                  <Text style={styles.lawyerName}>{caseData.lawyer.name}</Text>
                  <Text style={styles.lawyerSpecialty}>{caseData.lawyer.specialty}</Text>
                  <View style={styles.lawyerMeta}>
                    <Text style={styles.lawyerExperience}>8 anos de experiência</Text>
                    <View style={styles.rating}>
                      <Text style={styles.ratingText}>4.9</Text>
                      <Text style={styles.ratingStars}>⭐⭐⭐⭐⭐</Text>
                    </View>
                  </View>
                </View>
              </View>
              
              <View style={styles.lawyerActions}>
                <TouchableOpacity 
                  style={styles.actionButton}
                  onPress={() => navigation.navigate('CaseChat', { caseId })}
                >
                  <MessageCircle size={20} color="#006CFF" />
                  <Text style={styles.actionButtonText}>Chat</Text>
                  {caseData.unreadMessages > 0 && (
                    <View style={styles.unreadBadge}>
                      <Text style={styles.unreadText}>{caseData.unreadMessages}</Text>
                    </View>
                  )}
                </TouchableOpacity>
                
                <TouchableOpacity 
                  style={styles.actionButton}
                  onPress={() => Alert.alert('Videochamada', 'Funcionalidade em desenvolvimento')}
                >
                  <Video size={20} color="#006CFF" />
                  <Text style={styles.actionButtonText}>Vídeo</Text>
                </TouchableOpacity>
                
                <TouchableOpacity 
                  style={styles.actionButton}
                  onPress={() => Alert.alert('Ligação', 'Funcionalidade em desenvolvimento')}
                >
                  <Phone size={20} color="#006CFF" />
                  <Text style={styles.actionButtonText}>Ligar</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        )}

        {/* Consultation Info */}
        {detailedData?.consultInfo && (
          <View style={styles.section}>
            <View style={styles.card}>
              <Text style={styles.cardTitle}>Informações da Consulta</Text>
              
              <View style={styles.consultInfo}>
                <View style={styles.consultItem}>
                  <Calendar size={16} color="#6B7280" />
                  <Text style={styles.consultLabel}>Data:</Text>
                  <Text style={styles.consultValue}>
                    {new Date(detailedData.consultInfo.scheduledDate).toLocaleString('pt-BR')}
                  </Text>
                </View>
                
                <View style={styles.consultItem}>
                  <Text style={styles.consultLabel}>Duração:</Text>
                  <Text style={styles.consultValue}>{detailedData.consultInfo.duration}</Text>
                </View>
                
                <View style={styles.consultItem}>
                  <Text style={styles.consultLabel}>Tipo:</Text>
                  <Text style={styles.consultValue}>{detailedData.consultInfo.type}</Text>
                </View>
                
                <View style={styles.consultItem}>
                  <Text style={styles.consultLabel}>Plano:</Text>
                  <Badge label={detailedData.consultInfo.plan} intent="primary" size="small" />
                </View>
              </View>
            </View>
          </View>
        )}

        {/* Steps List */}
        {detailedData?.steps && (
          <View style={styles.section}>
            <View style={styles.card}>
              <Text style={styles.cardTitle}>Próximos Passos</Text>
              
              <View style={styles.stepsList}>
                {detailedData.steps.map((step, index) => (
                  <StepItem
                    key={index}
                    {...step}
                    isLast={index === detailedData.steps.length - 1}
                  />
                ))}
              </View>
            </View>
          </View>
        )}

        {/* Documents Summary Card */}
        {detailedData?.documents && (
          <View style={styles.section}>
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <Text style={styles.cardTitle}>Documentos</Text>
                <Badge 
                  label={detailedData.documents.length.toString()} 
                  intent="neutral" 
                  size="small" 
                />
              </View>
              
              <Text style={styles.documentsCount}>
                {detailedData.documents.length} documento(s) anexado(s)
              </Text>
              
              <TouchableOpacity 
                style={styles.viewDocumentsButton}
                onPress={() => navigation.navigate('CaseDocuments', { caseId })}
              >
                <FileText size={16} color="#006CFF" />
                <Text style={styles.viewDocumentsText}>Gerenciar Documentos</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* Cost and Risk */}
        {detailedData?.costs && (
          <View style={styles.section}>
            <CostRiskCard
              consultationCost={detailedData.costs.consultationFee}
              representationCost={detailedData.costs.legalFees}
              riskLevel="medium"
              riskScore={6}
              successProbability={75}
            />
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
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backIconButton: {
    padding: 8,
  },
  topBarTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
  },
  topBarActions: {
    flexDirection: 'row',
    gap: 8,
  },
  topBarAction: {
    padding: 8,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  section: {
    marginVertical: 8,
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
    marginBottom: 20,
  },
  lawyerInfo: {
    marginLeft: 16,
    flex: 1,
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
    marginBottom: 8,
  },
  lawyerMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  lawyerExperience: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  rating: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  ratingText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#1F2937',
  },
  ratingStars: {
    fontSize: 12,
  },
  lawyerActions: {
    flexDirection: 'row',
    gap: 12,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F0F9FF',
    paddingVertical: 12,
    paddingHorizontal: 16,
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
  stepsList: {
    marginTop: 8,
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
  documentsList: {
    gap: 12,
    marginTop: 8,
  },
  documentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  documentInfo: {
    flex: 1,
  },
  documentName: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#1F2937',
  },
  documentDate: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
    marginTop: 2,
  },
  costsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginBottom: 20,
  },
  riskSection: {
    paddingTop: 20,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  riskHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  riskTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
  },
  riskDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    marginTop: 8,
    lineHeight: 20,
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
}); 