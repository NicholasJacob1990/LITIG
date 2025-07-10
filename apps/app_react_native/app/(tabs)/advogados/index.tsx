import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image, Alert, TextInput, ActivityIndicator, Animated, FlatList, Pressable , Switch } from 'react-native';
import { useState, useEffect, useRef } from 'react';
import { LinearGradient } from 'expo-linear-gradient';
import { MapPin, Star, Clock, Video, MessageCircle, Users, Filter, Sliders, Map, List, CheckCircle, Navigation, Search, X, ChevronLeft } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { useRouter, useLocalSearchParams , Stack } from 'expo-router';
import LawyerCard from '@/components/LawyerCard';
import MapComponent from '@/components/MapComponent';
import { useLawyers } from '@/lib/hooks/useLawyers';
import { LawyerMatch } from '@/lib/services/api';
import { assignLawyerToCase } from '@/lib/supabase';
import LocationService, { UserLocation } from '@/components/LocationService';
import Slider from '@react-native-community/slider';

// Adicionando dados mockados para visualização - SERÁ REMOVIDO
// const mockLawyers: LawyerSearchResult[] = [
//     {
//         id: 'mock-1', name: 'Dr. Ana Silva', oab_number: 'OAB/SP 123.456', primary_area: 'Direito Civil',
//         rating: 4.8, review_count: 127, experience: 8, avatar_url: 'https://i.pravatar.cc/150?u=a01',
//         distance_km: 0.5, is_available: true, lat: 0, lng: 0,
//         consultation_types: ['chat', 'video', 'presential'], consultation_fee: 150,
//         response_time: '10min', success_rate: 98, hourly_rate: 300, next_availability: 'Amanhã', languages: ['Português', 'Inglês']
//     },
//     {
//         id: 'mock-2', name: 'Dra. Maria Santos', oab_number: 'OAB/SP 345.678', primary_area: 'Direito do Consumidor',
//         rating: 4.9, review_count: 203, experience: 15, avatar_url: 'https://i.pravatar.cc/150?u=a02',
//         distance_km: 2.1, is_available: true, lat: 0, lng: 0,
//         consultation_types: ['chat', 'video'], consultation_fee: 200,
//         response_time: '30min', success_rate: 95, hourly_rate: 400, next_availability: 'Hoje', languages: ['Português']
//     },
// ];

function LawyerSelectionScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const [caseId, setCaseId] = useState<string | null>(null);
  const [preset, setPreset] = useState<'balanced' | 'fast' | 'expert' | 'economic'>('balanced');
  const [complexity, setComplexity] = useState<'LOW' | 'MEDIUM' | 'HIGH'>('MEDIUM');
  const [selectedRadius, setSelectedRadius] = useState(20);
  const [selectedAreas, setSelectedAreas] = useState<string[]>([]);
  const [selectedLanguages, setSelectedLanguages] = useState<string[]>([]);
  const [availableNow, setAvailableNow] = useState(false);
  const [minRating, setMinRating] = useState(3);
  
  // Estados para filtros por tier
  const [selectedTiers, setSelectedTiers] = useState<string[]>([]);

  const [consultationType, setConsultationType] = useState<'chat' | 'video' | 'presential'>('chat');
  const [showFilters, setShowFilters] = useState(false);
  const [viewMode, setViewMode] = useState<'list' | 'map'>('list');
  const [selectedLawyer, setSelectedLawyer] = useState<LawyerMatch | null>(null);
  const [mapRegion, setMapRegion] = useState<{
    latitude: number;
    longitude: number;
    latitudeDelta: number;
    longitudeDelta: number;
  } | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [lawyers, setLawyers] = useState<LawyerMatch[]>([]);
  const [filteredLawyers, setFilteredLawyers] = useState<LawyerMatch[]>([]);
  const [userLocation, setUserLocation] = useState<UserLocation | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [isAssigning, setIsAssigning] = useState(false);
  const filterAnimation = useRef(new Animated.Value(0)).current;

  // Novo estado para o loading inicial
  const [isInitialLoading, setIsInitialLoading] = useState(true);

  // Integração com o hook useLawyers (T-1.1.2)
  const { 
    data: fetchedLawyers, 
    isLoading: isLoadingLawyers, 
    error: lawyersError,
    refetch: refetchLawyers
  } = useLawyers({
    area: selectedAreas.length > 0 ? selectedAreas[0] : undefined,
    preset: preset,
    complexity: complexity,
    coordinates: userLocation ? {
      latitude: userLocation.latitude,
      longitude: userLocation.longitude,
    } : {
      latitude: -23.5505,
      longitude: -46.6333
    },
          name: searchQuery || undefined,
      tiers: selectedTiers,
  });

  const legalAreas = [
    'Direito Trabalhista',
    'Direito Civil',
    'Direito Empresarial',
    'Direito do Consumidor',
    'Direito Previdenciário',
    'Direito Criminal',
    'Direito de Família',
    'Direito Tributário'
  ];

  const languages = [
    'Português',
    'Inglês',
    'Espanhol',
    'Francês',
    'Alemão'
  ];

  const consultationTypes = [
    { id: 'chat', label: 'Chat', icon: MessageCircle, color: '#1E40AF' },
    { id: 'video', label: 'Vídeo', icon: Video, color: '#059669' },
    { id: 'presential', label: 'Presencial', icon: Users, color: '#7C3AED' }
  ];

  useEffect(() => {
    if (params.caseId && typeof params.caseId === 'string') {
      setCaseId(params.caseId);
    }
    // Busca inicial de advogados
    refetchLawyers();
    const handler = setTimeout(() => {
      fetchLawyers();
    }, 500); // Debounce para filtros
    return () => clearTimeout(handler);
  }, [selectedRadius, selectedAreas, availableNow, minRating, searchQuery, refetchLawyers, selectedTiers]);

  useEffect(() => {
    if (fetchedLawyers) {
      setLawyers(fetchedLawyers);
      setIsInitialLoading(false);
      setIsLoading(false);
    }
  }, [fetchedLawyers]);

  useEffect(() => {
    if (lawyersError) {
        setLocationError(lawyersError.message);
        setIsInitialLoading(false);
        setIsLoading(false);
    }
  }, [lawyersError]);

  useEffect(() => {
    setFilteredLawyers(lawyers);
  }, [lawyers]);

  const fetchLawyers = () => {
    refetchLawyers();
  };

  const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number): number => {
    const R = 6371; // Raio da Terra em km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(deg2rad(lat1)) *
        Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  };

  const deg2rad = (deg: number): number => {
    return deg * (Math.PI / 180);
  };

  const applyFilters = () => {
    // This function is now mostly handled by the backend.
    // Kept for potential future client-side logic.
  };

  const handleLawyerSelect = (lawyer: LawyerMatch) => {
    setSelectedLawyer(lawyer);
  };

  const handleLawyerPress = (lawyer: LawyerMatch) => {
    // Navegar para tela de detalhes do advogado
    router.push({
      pathname: '/(tabs)/lawyer-details',
      params: { lawyerId: lawyer.id }
    });
  };

  const handleContinue = async () => {
    if (!selectedLawyer || !caseId) {
      Alert.alert('Erro', 'Por favor, selecione um advogado para continuar.');
      return;
    }

    setIsAssigning(true);
    try {
      await assignLawyerToCase(caseId, selectedLawyer.id);
      Alert.alert(
        "Advogado Atribuído!",
        `${selectedLawyer.nome} foi atribuído ao seu caso. Você será notificado quando ele(a) enviar a primeira mensagem.`,
        [
          { text: "OK", onPress: () => router.replace('../cases') }
        ]
      );
    } catch (error) {
      console.error("Erro ao atribuir advogado:", error);
      Alert.alert("Erro de Atribuição", "Não foi possível atribuir o advogado ao seu caso. Tente novamente.");
    } finally {
      setIsAssigning(false);
    }
  };

  const clearFilters = () => {
    setSelectedAreas([]);
    setSelectedLanguages([]);
    setAvailableNow(false);
    setMinRating(3);
    setConsultationType('chat');
    setSelectedRadius(20);
    setSearchQuery('');
    // Limpar filtros de tier
    setSelectedTiers([]);
  };

  const toggleFilters = () => {
    Animated.timing(filterAnimation, {
      toValue: showFilters ? 0 : 1,
      duration: 300,
      useNativeDriver: true,
    }).start();
    setShowFilters(!showFilters);
  };

  const renderLawyerCard = ({ item }: { item: LawyerMatch }) => (
    <LawyerCard 
      lawyer={item}
      onPress={() => handleLawyerPress(item)}
    />
  );

  const renderHeader = () => (
    <View style={styles.header}>
      <View style={styles.headerContent}>
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar por nome ou especialidade..."
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
        <TouchableOpacity onPress={() => setSearchQuery('')} style={styles.clearSearchButton}>
          {searchQuery ? <X size={20} color="#6B7280" /> : <Search size={20} color="#6B7280" />}
        </TouchableOpacity>
        <TouchableOpacity onPress={toggleFilters} style={styles.filterButton}>
          <Filter size={24} color="#1E40AF" />
        </TouchableOpacity>
        <View style={styles.viewModeToggle}>
          <TouchableOpacity onPress={() => setViewMode('map')} style={[styles.toggleButton, viewMode === 'map' && styles.toggleButtonActive]}>
            <Map size={20} color={viewMode === 'map' ? '#FFFFFF' : '#1E40AF'} />
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setViewMode('list')} style={[styles.toggleButton, viewMode === 'list' && styles.toggleButtonActive]}>
            <List size={20} color={viewMode === 'list' ? '#FFFFFF' : '#1E40AF'} />
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );

  const renderEmptyList = () => {
    if (isLoadingLawyers) {
      return <ActivityIndicator size="large" color="#1E40AF" style={{ marginTop: 50 }} />;
    }
    if (locationError) {
      return (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{locationError}</Text>
        </View>
      );
    }
    return (
        <View style={styles.emptyListContainer}>
            <Text style={styles.emptyListText}>Nenhum advogado encontrado com os filtros atuais. Tente ampliar sua busca.</Text>
        </View>
    );
  };

  const renderFilterPanel = () => {
    if (!showFilters) return null;

    const filterTranslateY = filterAnimation.interpolate({
      inputRange: [0, 1],
      outputRange: [-300, 0],
    });

    return (
      <Animated.View style={[styles.filtersContainer, { transform: [{ translateY: filterTranslateY }] }]}>
        <ScrollView>
            <Text style={styles.filterTitle}>Filtros Avançados</Text>
            
            <Text style={styles.label}>Critério de Busca</Text>
            <View style={styles.segmentedControl}>
              {['balanced', 'expert', 'fast', 'economic'].map((p) => (
                <TouchableOpacity
                  key={p}
                  style={[styles.segmentedButton, preset === p && styles.segmentedButtonActive]}
                  onPress={() => setPreset(p as any)}
                >
                  <Text style={[styles.segmentedButtonText, preset === p && styles.segmentedButtonTextActive]}>
                    {p.charAt(0).toUpperCase() + p.slice(1)}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.label}>Complexidade do Caso</Text>
            <View style={styles.segmentedControl}>
              {['LOW', 'MEDIUM', 'HIGH'].map((c) => (
                <TouchableOpacity
                  key={c}
                  style={[styles.segmentedButton, complexity === c && styles.segmentedButtonActive]}
                  onPress={() => setComplexity(c as any)}
                >
                  <Text style={[styles.segmentedButtonText, complexity === c && styles.segmentedButtonTextActive]}>
                    {c.charAt(0).toUpperCase() + c.slice(1).toLowerCase()}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            
            <Text style={styles.label}>Raio de Distância: {selectedRadius} km</Text>
            <Slider
              style={{ width: '100%', height: 40 }}
              minimumValue={1}
              maximumValue={100}
              step={1}
              value={selectedRadius}
              onValueChange={setSelectedRadius}
              minimumTrackTintColor="#1E40AF"
              maximumTrackTintColor="#D1D5DB"
              thumbTintColor="#1E40AF"
            />

            <Text style={styles.label}>Áreas de Atuação</Text>
            <View style={styles.tagContainer}>
              {legalAreas.map(area => (
                <TouchableOpacity 
                  key={area}
                  style={[styles.tag, selectedAreas.includes(area) && styles.tagSelected]}
                  onPress={() => {
                    setSelectedAreas(prev => 
                      prev.includes(area) ? prev.filter(a => a !== area) : [...prev, area]
                    )
                  }}>
                  <Text style={[styles.tagText, selectedAreas.includes(area) && styles.tagTextSelected]}>{area}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.label}>Avaliação Mínima: {minRating.toFixed(1)}</Text>
            <Slider
                style={{ width: '100%', height: 40 }}
                minimumValue={1}
                maximumValue={5}
                step={0.5}
                value={minRating}
                onValueChange={setMinRating}
                minimumTrackTintColor="#1E40AF"
                maximumTrackTintColor="#D1D5DB"
                thumbTintColor="#1E40AF"
            />

            <Text style={styles.label}>Nível de Advogado</Text>
            <View style={styles.tagContainer}>
              {[
                { key: 'junior', label: 'Júnior (R$ 150 - R$ 200/h)', description: 'Até 3 anos de experiência' },
                { key: 'pleno', label: 'Pleno (R$ 300 - R$ 400/h)', description: '4 a 10 anos de experiência' },
                { key: 'senior', label: 'Sênior (R$ 500 - R$ 600/h)', description: 'Mais de 10 anos de experiência' },
                { key: 'especialista', label: 'Especialista (R$ 800 - R$ 1000/h)', description: 'Altamente especializado' }
              ].map(tier => (
                <TouchableOpacity 
                  key={tier.key}
                  style={[styles.tierTag, selectedTiers.includes(tier.key) && styles.tierTagSelected]}
                  onPress={() => {
                    setSelectedTiers(prev => 
                      prev.includes(tier.key) ? prev.filter(t => t !== tier.key) : [...prev, tier.key]
                    )
                  }}>
                  <Text style={[styles.tierTagText, selectedTiers.includes(tier.key) && styles.tierTagTextSelected]}>
                    {tier.label}
                  </Text>
                  <Text style={[styles.tierTagDescription, selectedTiers.includes(tier.key) && styles.tierTagDescriptionSelected]}>
                    {tier.description}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            
            <View style={styles.switchContainer}>
                <Text style={styles.label}>Disponível Agora</Text>
                <Switch
                    trackColor={{ false: "#D1D5DB", true: "#818CF8" }}
                    thumbColor={availableNow ? "#1E40AF" : "#f4f3f4"}
                    ios_backgroundColor="#3e3e3e"
                    onValueChange={setAvailableNow}
                    value={availableNow}
                />
            </View>
            
            <TouchableOpacity style={styles.clearFiltersButton} onPress={clearFilters}>
              <Text style={styles.clearFiltersButtonText}>Limpar Filtros</Text>
            </TouchableOpacity>

        </ScrollView>
      </Animated.View>
    );
  };


  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <Stack.Screen options={{ headerShown: false }} />
      
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.headerIcon}>
          <ChevronLeft size={24} color="#FFFFFF" />
        </TouchableOpacity>
        <View>
          <Text style={styles.headerTitle}>Escolha seu Advogado</Text>
          <Text style={styles.headerSubtitle}>{lawyers.length} profissionais encontrados no raio de 20km</Text>
        </View>
        <View style={styles.headerActions}>
          <TouchableOpacity onPress={() => setViewMode(viewMode === 'list' ? 'map' : 'list')} style={styles.headerIcon}>
            {viewMode === 'list' ? <Map size={24} color="#FFFFFF" /> : <List size={24} color="#FFFFFF" />}
          </TouchableOpacity>
          <TouchableOpacity style={styles.headerIcon}><Filter size={24} color="#FFFFFF" /></TouchableOpacity>
        </View>
      </View>

      <View style={styles.searchAndFilter}>
        <View style={styles.searchInputContainer}>
          <Search size={20} color="#6B7280" style={styles.searchIcon} />
          <TextInput
            style={styles.searchInput}
            placeholder="Buscar por nome ou especialidade..."
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
          {searchQuery ? <TouchableOpacity onPress={() => setSearchQuery('')}><X size={20} color="#6B7280" /></TouchableOpacity> : null}
        </View>
        <TouchableOpacity onPress={() => setShowFilters(!showFilters)} style={styles.filterButton}>
          <Filter size={24} color="#1E40AF" />
        </TouchableOpacity>
      </View>

      {showFilters && renderFilterPanel()}
      
      {isInitialLoading ? (
        <View style={styles.fullScreenLoader}>
          <ActivityIndicator size="large" color="#1E40AF" />
          <Text style={styles.loaderText}>Buscando advogados...</Text>
        </View>
      ) : (
        <>
          {isLoadingLawyers && (
            <View style={styles.listLoaderOverlay}>
              <ActivityIndicator size="large" color="#1E40AF" />
            </View>
          )}
          {locationError ? (
            <View style={styles.emptyContainer}><Text>{locationError}</Text></View>
          ) : lawyers.length === 0 ? (
            <View style={styles.emptyContainer}><Text>Nenhum advogado encontrado.</Text></View>
          ) : (
            viewMode === 'list' ? (
              <FlatList
                ListHeaderComponent={() => <Text style={styles.infoText}>{lawyers.length} advogados encontrados.</Text>}
                data={lawyers}
                renderItem={({ item }) => (
                  <LawyerCard 
                    lawyer={item}
                    onPress={() => handleLawyerPress(item)}
                    showExplainability={true}
                    showCurriculum={true}
                  />
                )}
                keyExtractor={item => item.id}
                contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16 }}
              />
            ) : (
              mapRegion && <MapComponent 
                lawyers={lawyers}
                region={mapRegion}
                onSelectLawyer={() => {}}
                onRegionChange={() => {}}
                selectedLawyer={null}
              />
            )
          )}
        </>
      )}
      
      {selectedLawyer && (
        <View style={styles.footer}>
          <TouchableOpacity style={styles.detailsButton} onPress={() => handleLawyerPress(selectedLawyer)}>
            <Text style={styles.detailsButtonText}>Ver Detalhes</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.continueButton} onPress={handleContinue} disabled={isAssigning}>
            {isAssigning ? (
              <ActivityIndicator color="#FFFFFF" />
            ) : (
              <>
                <Text style={styles.continueButtonText}>Atribuir a este Caso</Text>
                <CheckCircle size={20} color="#FFFFFF" />
              </>
            )}
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F4F6', // Cor de fundo mais suave
  },
  header: {
    backgroundColor: '#3B82F6', // Azul do design
    paddingTop: 60,
    paddingBottom: 20,
    paddingHorizontal: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 22,
    fontFamily: 'Inter-Bold',
    color: '#FFFFFF',
    textAlign: 'center',
  },
  headerSubtitle: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#D1E0FF',
    textAlign: 'center',
    marginTop: 4,
  },
  headerActions: {
    flexDirection: 'row',
    gap: 16,
  },
  headerIcon: {
    padding: 4,
  },
  headerContent: {
    flex: 1,
  },
  searchAndFilter: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#FFFFFF',
  },
  searchInputContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    borderRadius: 12,
    paddingHorizontal: 12,
  },
  searchIcon: {
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    height: 44,
    fontSize: 16,
  },
  clearSearchButton: {
    padding: 4,
  },
  filterButton: {
    marginLeft: 12,
    padding: 10,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  filtersContainer: {
    padding: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  filterTitle: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  label: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#374151',
    marginBottom: 10,
    marginTop: 15,
  },
  tagContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginBottom: 15,
  },
  tag: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#E5E7EB',
  },
  tagSelected: {
    backgroundColor: '#1E40AF',
  },
  tagText: {
    color: '#374151',
    fontFamily: 'Inter-Medium',
  },
  tagTextSelected: {
    color: '#FFFFFF',
  },
  switchContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 10,
  },
  clearFiltersButton: {
    backgroundColor: '#FECACA',
    paddingVertical: 12,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 20,
  },
  clearFiltersButtonText: {
    color: '#DC2626',
    fontFamily: 'Inter-Bold',
  },
  footer: {
    flexDirection: 'row',
    padding: 15,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    backgroundColor: 'white',
  },
  detailsButton: {
    flex: 1,
    padding: 15,
    borderRadius: 12,
    backgroundColor: '#E5E7EB',
    alignItems: 'center',
    marginRight: 10,
  },
  detailsButtonText: {
    color: '#1F2937',
    fontFamily: 'Inter-Bold',
    fontSize: 16,
  },
  continueButton: {
    flex: 2,
    flexDirection: 'row',
    padding: 15,
    borderRadius: 12,
    backgroundColor: '#1E40AF',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
  },
  continueButtonText: {
    color: 'white',
    fontFamily: 'Inter-Bold',
    fontSize: 16,
  },
  viewModeToggle: {
    flexDirection: 'row',
    backgroundColor: '#E5E7EB',
    borderRadius: 20,
    padding: 4,
  },
  toggleButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  toggleButtonActive: {
    backgroundColor: '#1E40AF',
  },
  errorContainer: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      padding: 20,
  },
  errorText: {
      textAlign: 'center',
      color: '#EF4444',
      fontFamily: 'Inter-SemiBold',
  },
  emptyListContainer: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      padding: 20,
  },
  emptyListText: {
      fontFamily: 'Inter-SemiBold',
      fontSize: 16,
      color: '#6B7280',
      textAlign: 'center',
  },
  selectedCard: {
      borderWidth: 2,
      borderColor: '#1E40AF',
  },
  infoText: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
    textAlign: 'center',
    paddingVertical: 24,
    paddingHorizontal: 16,
  },
  fullScreenLoader: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
  },
  listLoaderOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(243, 244, 246, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  loaderText: {
    marginTop: 10,
    fontSize: 16,
    color: '#374151',
    fontFamily: 'Inter-SemiBold',
  },
  segmentedControl: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: '#E5E7EB',
    borderRadius: 12,
    padding: 4,
    marginBottom: 20,
  },
  segmentedButton: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 8,
    alignItems: 'center',
  },
  segmentedButtonActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 1.41,
    elevation: 2,
  },
  segmentedButtonText: {
    fontFamily: 'Inter-SemiBold',
    color: '#374151',
  },
  segmentedButtonTextActive: {
    color: '#1E40AF',
  },
  tierTag: {
    padding: 16,
    borderRadius: 12,
    backgroundColor: '#F3F4F6',
    marginBottom: 10,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  tierTagSelected: {
    backgroundColor: '#EBF4FF',
    borderColor: '#1E40AF',
  },
  tierTagText: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#374151',
    marginBottom: 4,
  },
  tierTagTextSelected: {
    color: '#1E40AF',
  },
  tierTagDescription: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
  },
  tierTagDescriptionSelected: {
    color: '#1E40AF',
  },
});

export default LawyerSelectionScreen; 