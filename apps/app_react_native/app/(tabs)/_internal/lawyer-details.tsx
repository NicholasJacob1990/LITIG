import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image, Alert, Linking } from 'react-native';
import { useState, useEffect } from 'react';
import { LinearGradient } from 'expo-linear-gradient';
import { 
  ArrowLeft, Star, MapPin, Clock, Award, MessageCircle, Video, Users, 
  Phone, Mail, Calendar, CheckCircle, Shield, Globe, BookOpen, 
  TrendingUp, Heart, Share, ExternalLink 
} from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { router, useLocalSearchParams } from 'expo-router';
import { LawyerService, Lawyer } from '@/lib/supabase';
import { getOrCreatePreHiringChat } from '@/lib/services/chat';
import RadarChart from '@/components/organisms/RadarChart';
import EducationSection from '@/components/molecules/EducationSection';
import PublicationsSection from '@/components/molecules/PublicationsSection';
import { Match } from '@/lib/services/api';

const SuccessStatusBadge: React.FC<{ status?: string }> = ({ status }) => {
  if (!status || status === 'N') {
    return null;
  }

  const statusMap = {
    V: { label: 'Êxito Verificado', color: '#10B981', icon: <CheckCircle size={14} color="#FFFFFF" /> },
    P: { label: 'Êxito Autodeclarado', color: '#F59E0B', icon: <TrendingUp size={14} color="#FFFFFF" /> },
  };

  const currentStatus = statusMap[status as keyof typeof statusMap];
  if (!currentStatus) return null;

  return (
    <View style={[styles.badgeBase, { backgroundColor: currentStatus.color }]}>
      {currentStatus.icon}
      <Text style={styles.badgeText}>{currentStatus.label}</Text>
    </View>
  );
};

export default function LawyerDetailsScreen() {
  const { lawyerId, matchData: matchDataString } = useLocalSearchParams<{ lawyerId: string, matchData?: string }>();
  const [lawyer, setLawyer] = useState<Lawyer | null>(null);
  const [matchData, setMatchData] = useState<Match | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreatingChat, setIsCreatingChat] = useState(false);
  const [selectedConsultationType, setSelectedConsultationType] = useState<'chat' | 'video' | 'presential'>('chat');

  const getYearsSince = (dateString?: string) => {
    if (!dateString) return null;
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return null;
    return new Date().getFullYear() - date.getFullYear();
  };

  useEffect(() => {
    if (lawyerId) {
      loadLawyerDetails();
    }
    if (matchDataString) {
      setMatchData(JSON.parse(matchDataString));
    }
  }, [lawyerId, matchDataString]);

  const loadLawyerDetails = async () => {
    try {
      setIsLoading(true);
      const lawyerData = await LawyerService.getLawyerById(lawyerId);
      if (lawyerData) {
        setLawyer(lawyerData);
      } else {
        Alert.alert('Erro', 'Advogado não encontrado');
        router.back();
      }
    } catch (error) {
      console.error('Erro ao carregar detalhes:', error);
      Alert.alert('Erro', 'Erro ao carregar detalhes do advogado');
      router.back();
    } finally {
      setIsLoading(false);
    }
  };

  const handleStartPreHiringChat = async () => {
    if (!lawyerId) return;
    setIsCreatingChat(true);
    try {
      const chat = await getOrCreatePreHiringChat(lawyerId);
      if (chat && chat.id) {
        router.push(`/pre-hiring-chat/${chat.id}`);
      } else {
        Alert.alert('Erro', 'Não foi possível iniciar a conversa. Tente novamente.');
      }
    } catch (error) {
      console.error('Erro ao iniciar chat pré-contratação:', error);
      Alert.alert('Erro', 'Ocorreu um erro ao iniciar a conversa.');
    } finally {
      setIsCreatingChat(false);
    }
  };

  const handleStartConsultation = () => {
    if (!lawyer) return;

    const typeLabels = {
      chat: 'Chat',
      video: 'Videochamada',
      presential: 'Presencial'
    };

    Alert.alert(
      'Iniciar Consulta',
      `Deseja iniciar uma consulta por ${typeLabels[selectedConsultationType]} com ${lawyer.name}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        { 
          text: 'Continuar', 
          onPress: () => {
            // Navegar para tela de pagamento - (T-future)
            // router.push({
            //   pathname: '/(tabs)/payment',
            //   params: { 
            //     lawyerId: lawyer.id,
            //     lawyerName: lawyer.name,
            //     consultationType: selectedConsultationType,
            //     consultationFee: lawyer.consultation_fee.toString()
            //   }
            // });
            Alert.alert("A ser implementado", "A tela de pagamento será implementada em um próximo sprint.");
          }
        }
      ]
    );
  };

  const handleContact = (type: 'phone' | 'email') => {
    if (!lawyer) return;

    if (type === 'phone') {
      Linking.openURL(`tel:+5511999999999`); // Mock phone
    } else {
      Linking.openURL(`mailto:${lawyer.name.toLowerCase().replace(' ', '.')}@example.com`); // Mock email
    }
  };

  const handleShare = () => {
    Alert.alert('Compartilhar', 'Funcionalidade de compartilhamento será implementada');
  };

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Carregando perfil...</Text>
      </View>
    );
  }

  if (!lawyer) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>Advogado não encontrado</Text>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Text style={styles.backButtonText}>Voltar</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const consultationTypes = [
    { id: 'chat', label: 'Chat', icon: MessageCircle, color: '#1E40AF', price: lawyer.consultation_fee },
    { id: 'video', label: 'Vídeo', icon: Video, color: '#059669', price: lawyer.consultation_fee * 1.5 },
    { id: 'presential', label: 'Presencial', icon: Users, color: '#7C3AED', price: lawyer.hourly_rate },
  ];

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      {/* Header com Avatar */}
      <LinearGradient colors={['#1E40AF', '#3B82F6']} style={styles.header}>
        <TouchableOpacity style={styles.backIcon} onPress={() => router.back()}>
          <ArrowLeft size={24} color="#FFFFFF" />
        </TouchableOpacity>
        
        <TouchableOpacity style={styles.shareIcon} onPress={handleShare}>
          <Share size={24} color="#FFFFFF" />
        </TouchableOpacity>
        
        <View style={styles.profileSection}>
          <Image source={{ uri: lawyer.avatar_url }} style={styles.avatar} />
          {lawyer.is_available && <View style={styles.onlineIndicator} />}
          
          <Text style={styles.lawyerName}>{lawyer.name}</Text>
          <Text style={styles.oabNumber}>{lawyer.oab_number}</Text>
          
          <View style={styles.ratingContainer}>
            <Star size={20} color="#FCD34D" fill="#FCD34D" />
            <Text style={styles.rating}>{lawyer.rating.toFixed(1)}</Text>
            <Text style={styles.reviewCount}>({lawyer.review_count} avaliações)</Text>
          </View>
        </View>
      </LinearGradient>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Métricas Principais */}
        <View style={styles.metricsSection}>
          <View style={styles.metricCard}>
            <Award size={24} color="#059669" />
            <Text style={styles.metricValue}>{lawyer.experience}</Text>
            <Text style={styles.metricLabel}>Anos de Experiência</Text>
          </View>
          {getYearsSince(lawyer.oab_inscription_date) !== null && (
            <View style={styles.metricCard}>
              <BookOpen size={24} color="#A0522D" />
              <Text style={styles.metricValue}>{getYearsSince(lawyer.oab_inscription_date)}</Text>
              <Text style={styles.metricLabel}>Anos de Inscrição</Text>
            </View>
          )}
          <View style={styles.metricCard}>
            <TrendingUp size={24} color="#1E40AF" />
            <Text style={styles.metricValue}>{lawyer.success_rate}%</Text>
            <View style={{flexDirection: 'row', alignItems: 'center', marginTop: 4}}>
            <Text style={styles.metricLabel}>Taxa de Sucesso</Text>
                <SuccessStatusBadge status={lawyer.success_status} />
            </View>
          </View>
          <View style={styles.metricCard}>
            <Clock size={24} color="#F59E0B" />
            <Text style={styles.metricValue}>{lawyer.response_time}</Text>
            <Text style={styles.metricLabel}>Tempo Resposta</Text>
          </View>
        </View>

        {matchData?.breakdown && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Análise de Compatibilidade</Text>
            <RadarChart data={matchData.breakdown as any} size={300} />
          </View>
        )}

        {/* Especialidades */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Área de Atuação</Text>
          <View style={styles.specialtyContainer}>
            <Text style={styles.primarySpecialty}>{lawyer.primary_area}</Text>
          </View>
        </View>

        {/* Idiomas */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Idiomas</Text>
          <View style={styles.languagesContainer}>
            {lawyer.languages.map((language, index) => (
              <View key={index} style={styles.languageTag}>
                <Globe size={14} color="#6B7280" />
                <Text style={styles.languageText}>{language}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Biografia (mock) */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Sobre</Text>
          <Text style={styles.bioText}>
            {lawyer.bio || `Advogado especializado em ${lawyer.primary_area.toLowerCase()} com ${lawyer.experience} anos de experiência.`}
          </Text>
        </View>

        {/* Integração dos novos componentes */}
        <EducationSection 
          education={typeof lawyer.education === 'string' ? JSON.parse(lawyer.education) : lawyer.education} 
          experience={typeof lawyer.professional_experience === 'string' ? JSON.parse(lawyer.professional_experience) : lawyer.professional_experience}
        />
        <PublicationsSection 
          publications={lawyer.publications || []} 
          certifications={lawyer.certifications || []} 
        />

        {/* Tipos de Consulta */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Tipos de Consulta</Text>
          <View style={styles.consultationGrid}>
            {consultationTypes.map((type) => (
              <TouchableOpacity
                key={type.id}
                style={[
                  styles.consultationCard,
                  selectedConsultationType === type.id && styles.consultationCardSelected,
                  !lawyer.consultation_types.includes(type.id) && styles.consultationCardDisabled
                ]}
                onPress={() => lawyer.consultation_types.includes(type.id) && setSelectedConsultationType(type.id as any)}
                disabled={!lawyer.consultation_types.includes(type.id)}
              >
                <type.icon 
                  size={24} 
                  color={lawyer.consultation_types.includes(type.id) ? type.color : '#9CA3AF'} 
                />
                <Text style={[
                  styles.consultationLabel,
                  !lawyer.consultation_types.includes(type.id) && styles.consultationLabelDisabled
                ]}>
                  {type.label}
                </Text>
                <Text style={[
                  styles.consultationPrice,
                  !lawyer.consultation_types.includes(type.id) && styles.consultationPriceDisabled
                ]}>
                  R$ {type.price.toFixed(2)}
                </Text>
                {lawyer.consultation_types.includes(type.id) && (
                  <CheckCircle size={16} color={type.color} />
                )}
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Disponibilidade */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Disponibilidade</Text>
          <View style={styles.availabilityCard}>
            {lawyer.is_available ? (
              <>
                <View style={styles.availableIndicator}>
                  <CheckCircle size={20} color="#10B981" />
                  <Text style={styles.availableText}>Disponível agora</Text>
                </View>
                <Text style={styles.availableSubtext}>Responde em até {lawyer.response_time}</Text>
              </>
            ) : (
              <>
                <View style={styles.unavailableIndicator}>
                  <Clock size={20} color="#F59E0B" />
                  <Text style={styles.unavailableText}>Ocupado</Text>
                </View>
                <Text style={styles.unavailableSubtext}>
                  Próxima disponibilidade: {lawyer.next_availability}
                </Text>
              </>
            )}
          </View>
        </View>

        {/* Botões de Contato */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Contato Direto</Text>
          <View style={styles.contactButtons}>
            <TouchableOpacity style={styles.contactButton} onPress={() => handleContact('phone')}>
              <Phone size={20} color="#1E40AF" />
              <Text style={styles.contactButtonText}>Telefone</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={[styles.contactButton, isCreatingChat && styles.contactButtonDisabled]} 
              onPress={handleStartPreHiringChat}
              disabled={isCreatingChat}
            >
              <MessageCircle size={20} color={isCreatingChat ? '#9CA3AF' : '#3B82F6'} />
              <Text style={styles.contactButtonText}>{isCreatingChat ? 'Abrindo...' : 'Conversar'}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.contactButton} onPress={() => handleContact('email')}>
              <Mail size={20} color="#059669" />
              <Text style={styles.contactButtonText}>E-mail</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>

      {/* Botão de Ação Principal */}
      <View style={styles.actionContainer}>
        <View style={styles.priceInfo}>
          <Text style={styles.priceLabel}>
            {selectedConsultationType === 'chat' ? 'Consulta' : 
             selectedConsultationType === 'video' ? 'Videochamada' : 'Presencial'}
          </Text>
          <Text style={styles.priceValue}>
            R$ {(selectedConsultationType === 'presential' ? lawyer.hourly_rate : 
                 selectedConsultationType === 'video' ? lawyer.consultation_fee * 1.5 : 
                 lawyer.consultation_fee).toFixed(2)}
          </Text>
        </View>
        <TouchableOpacity 
          style={[styles.actionButton, !lawyer.is_available && styles.actionButtonDisabled]} 
          onPress={handleStartConsultation}
          disabled={!lawyer.is_available}
        >
          <LinearGradient
            colors={lawyer.is_available ? ['#1E40AF', '#3B82F6'] : ['#9CA3AF', '#6B7280']}
            style={styles.actionButtonGradient}
          >
            <Text style={styles.actionButtonText}>
              {lawyer.is_available ? 'Iniciar Consulta' : 'Agendar Consulta'}
            </Text>
          </LinearGradient>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontFamily: 'Inter-Medium',
    fontSize: 16,
    color: '#6B7280',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  errorText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#EF4444',
    marginBottom: 16,
  },
  backButton: {
    backgroundColor: '#1E40AF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  backButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#FFFFFF',
  },
  header: {
    paddingTop: 60,
    paddingBottom: 40,
    alignItems: 'center',
    position: 'relative',
  },
  backIcon: {
    position: 'absolute',
    top: 60,
    left: 20,
    padding: 8,
  },
  shareIcon: {
    position: 'absolute',
    top: 60,
    right: 20,
    padding: 8,
  },
  profileSection: {
    alignItems: 'center',
    marginTop: 20,
  },
  avatar: {
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 4,
    borderColor: '#FFFFFF',
    marginBottom: 16,
  },
  onlineIndicator: {
    position: 'absolute',
    top: 90,
    right: '35%',
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#10B981',
    borderWidth: 4,
    borderColor: '#FFFFFF',
  },
  lawyerName: {
    fontFamily: 'Inter-Bold',
    fontSize: 24,
    color: '#FFFFFF',
    marginBottom: 4,
  },
  oabNumber: {
    fontFamily: 'Inter-Medium',
    fontSize: 16,
    color: '#E5E7EB',
    marginBottom: 12,
  },
  ratingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  rating: {
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    color: '#FFFFFF',
  },
  reviewCount: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#E5E7EB',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  metricsSection: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 24,
  },
  metricCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginHorizontal: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  metricValue: {
    fontFamily: 'Inter-Bold',
    fontSize: 20,
    color: '#1F2937',
    marginTop: 8,
    marginBottom: 4,
  },
  metricLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
  badgeBase: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 12,
    marginLeft: 4,
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 10,
    fontFamily: 'Inter-Bold',
    marginLeft: 4,
  },
  section: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  sectionTitle: {
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 16,
  },
  specialtyContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  primarySpecialty: {
    backgroundColor: '#EFF6FF',
    color: '#1E40AF',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
  },
  languagesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  languageTag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 16,
    gap: 6,
  },
  languageText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#374151',
  },
  bioText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#374151',
    lineHeight: 24,
  },
  consultationGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  consultationCard: {
    flex: 1,
    backgroundColor: '#F9FAFB',
    borderWidth: 2,
    borderColor: '#E5E7EB',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    gap: 8,
  },
  consultationCardSelected: {
    backgroundColor: '#EFF6FF',
    borderColor: '#3B82F6',
  },
  consultationCardDisabled: {
    backgroundColor: '#F3F4F6',
    opacity: 0.5,
  },
  consultationLabel: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#1F2937',
  },
  consultationLabelDisabled: {
    color: '#9CA3AF',
  },
  consultationPrice: {
    fontFamily: 'Inter-Bold',
    fontSize: 16,
    color: '#059669',
  },
  consultationPriceDisabled: {
    color: '#9CA3AF',
  },
  availabilityCard: {
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
  },
  availableIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  availableText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#10B981',
  },
  availableSubtext: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  unavailableIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  unavailableText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#F59E0B',
  },
  unavailableSubtext: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  contactButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  contactButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#F3F4F6',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 8,
    flex: 1,
    justifyContent: 'center',
  },
  contactButtonDisabled: {
    backgroundColor: '#E5E7EB',
  },
  contactButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#374151',
  },
  actionContainer: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  priceInfo: {
    flex: 1,
  },
  priceLabel: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  priceValue: {
    fontFamily: 'Inter-Bold',
    fontSize: 20,
    color: '#1F2937',
  },
  actionButton: {
    borderRadius: 12,
    overflow: 'hidden',
  },
  actionButtonDisabled: {
    opacity: 0.6,
  },
  actionButtonGradient: {
    paddingHorizontal: 32,
    paddingVertical: 16,
    alignItems: 'center',
  },
  actionButtonText: {
    fontFamily: 'Inter-Bold',
    fontSize: 16,
    color: '#FFFFFF',
  },
}); 