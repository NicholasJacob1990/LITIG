import React, { useState, useEffect, useCallback } from 'react';
import { View, StyleSheet, SafeAreaView, Text, FlatList, TouchableOpacity, ActivityIndicator, Dimensions } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { ArrowLeft, RefreshCw, List, Map, Filter } from 'lucide-react-native';
import MapView, { Marker, PROVIDER_GOOGLE } from 'react-native-maps';

import LawyerMatchCard from '@/components/LawyerMatchCard';
import PresetSelector from '@/components/molecules/PresetSelector';
import { Match, getMatchesForCase, getPersistedMatches } from '@/lib/services/api';
import { LawyerSearchResult } from '@/lib/supabase';
import { useAuth } from '@/lib/contexts/AuthContext';

type Preset = 'balanced' | 'fast' | 'expert' | 'economic';
type ViewMode = 'list' | 'map';

const { width, height } = Dimensions.get('window');
const ASPECT_RATIO = width / height;
const LATITUDE_DELTA = 0.5;
const LONGITUDE_DELTA = LATITUDE_DELTA * ASPECT_RATIO;

const MatchesPage = () => {
  const router = useRouter();
  const params = useLocalSearchParams<{ 
    caseId?: string, 
    fromRecs?: string,
    radiusKm?: string,
    area?: string,
    subarea?: string,
    filtersApplied?: string,
  }>();
  
  const { caseId, fromRecs } = params;
  const { session } = useAuth();

  const [matches, setMatches] = useState<Match[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedPreset, setSelectedPreset] = useState<Preset>('balanced');
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  
  // Filtros agora vêm dos parâmetros da rota
  const radiusKm = params.radiusKm ? Number(params.radiusKm) : 50;
  const area = params.area || '';
  const subarea = params.subarea || '';

  const isFromRecs = fromRecs === 'true';

  const fetchMatches = useCallback(async (preset: Preset, options: { exclude_ids?: string[] } = {}) => {
    if (!caseId) {
      setError('ID do caso não encontrado.');
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      let response: any;
      if (isFromRecs) {
        response = await getPersistedMatches(caseId as string);
      } else {
        response = await getMatchesForCase(
          caseId as string,
          {
            preset: preset,
            k: 5,
          }
        );
      }
      
      const arr = response?.matches ?? response?.lawyers ?? [];
      setMatches(arr);
    } catch (e) {
      setError('Falha ao buscar os advogados recomendados. Tente novamente.');
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  }, [caseId, isFromRecs, area, subarea, radiusKm]);

  useEffect(() => {
    fetchMatches(selectedPreset);
  }, [fetchMatches, selectedPreset, params.filtersApplied]); // Re-fetch when filters are applied

  const handleSelectLawyer = (lawyerId: string, matchData: Match) => {
    router.push({
      pathname: '/(tabs)/lawyer-details' as any,
      params: { 
        lawyerId: lawyerId,
        matchData: JSON.stringify(matchData)
      },
    });
  };

  const handleRefresh = () => {
    if (matches.length === 0) return;
    const currentIds = matches.map(m => m.lawyer_id);
    fetchMatches(selectedPreset, { exclude_ids: currentIds });
  };

  const renderMatchCard = ({ item }: { item: Match }) => {
    const lawyerForCard: LawyerSearchResult = {
      id: item.lawyer_id,
      name: item.nome,
      avatar_url: item.avatar_url || '',
      is_available: item.is_available,
      primary_area: item.primary_area,
      rating: item.rating || 0,
      distance_km: item.distance_km || 0,
      oab_number: 'N/A',
      specialties: [],
      is_approved: true,
      review_count: 0,
      experience: 0,
      lat: 0,
      lng: 0,
      response_time: 'N/A',
      success_rate: 0,
      hourly_rate: 0,
      consultation_fee: 0,
      next_availability: 'N/A',
      languages: [],
      consultation_types: [],
    };
  
    return (
      <LawyerMatchCard 
        lawyer={lawyerForCard} 
        onSelect={() => handleSelectLawyer(item.lawyer_id, item)} 
        caseId={caseId as string} 
        matchData={item} 
        caseTitle="" 
        authToken={session?.access_token}
      />
    );
  };

  const renderContent = () => {
    if (isLoading) {
      return <ActivityIndicator size="large" color="#1F2937" style={styles.centered} />;
    }

    if (error) {
      return (
        <View style={styles.centered}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity onPress={() => fetchMatches(selectedPreset)} style={styles.retryButton}>
            <Text style={styles.retryButtonText}>Tentar Novamente</Text>
          </TouchableOpacity>
        </View>
      );
    }
    
    if (viewMode === 'map') {
      const initialRegion = matches.length > 0 && matches[0].lat && matches[0].lng
        ? {
            latitude: matches[0].lat,
            longitude: matches[0].lng,
            latitudeDelta: LATITUDE_DELTA,
            longitudeDelta: LONGITUDE_DELTA,
          }
        : undefined;

      return (
        <MapView
          provider={PROVIDER_GOOGLE}
          style={styles.map}
          initialRegion={initialRegion}
          showsUserLocation
        >
          {matches.map(match => (
            match.lat && match.lng && (
              <Marker
                key={match.lawyer_id}
                coordinate={{ latitude: match.lat, longitude: match.lng }}
                title={match.nome}
                description={match.primary_area}
                onCalloutPress={() => handleSelectLawyer(match.lawyer_id, match)}
              />
            )
          ))}
        </MapView>
      );
    }

    return (
      <FlatList
        data={matches}
        keyExtractor={(item) => item.lawyer_id}
        renderItem={renderMatchCard}
        contentContainerStyle={styles.listContent}
        ListFooterComponent={
          !isLoading && matches.length > 0 ? (
            <TouchableOpacity onPress={handleRefresh} style={styles.refreshButton}>
              <RefreshCw size={18} color="#1F2937" />
              <Text style={styles.refreshButtonText}>Ver outras opções</Text>
            </TouchableOpacity>
          ) : null
        }
        ListEmptyComponent={
          <View style={styles.centered}>
            <Text style={styles.emptyText}>Nenhum advogado compatível encontrado.</Text>
          </View>
        }
      />
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <ArrowLeft size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.title}>Advogados Recomendados</Text>
        <View style={styles.rightHeader}>
          {!isFromRecs && (
            <TouchableOpacity 
              onPress={() => router.push({ pathname: '/(modals)/FilterModal' as any, params: { radius: radiusKm, area, subarea } })} 
              style={styles.toggleButton}
              accessibilityLabel="Abrir filtros"
            >
              <Filter size={24} color="#1F2937" />
            </TouchableOpacity>
          )}
          <TouchableOpacity 
            onPress={() => setViewMode(prev => prev === 'list' ? 'map' : 'list')} 
            style={styles.toggleButton}
            accessibilityLabel={viewMode === 'list' ? "Ver no mapa" : "Ver em lista"}
          >
            {viewMode === 'list' ? <Map size={24} color="#1F2937" /> : <List size={24} color="#1F2937" />}
          </TouchableOpacity>
        </View>
      </View>
      
      {!isFromRecs && (
        <View style={styles.selectorContainer}>
          <PresetSelector selectedPreset={selectedPreset} onSelectPreset={setSelectedPreset} />
        </View>
      )}
      
      {renderContent()}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    backgroundColor: 'white',
  },
  backButton: {
    padding: 8,
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  rightHeader: {
    flexDirection: 'row',
  },
  toggleButton: {
    padding: 8,
    marginLeft: 8,
  },
  selectorContainer: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    backgroundColor: 'white',
  },
  listContent: {
    padding: 16,
  },
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1F2937',
    textAlign: 'center',
  },
  errorText: {
    fontSize: 16,
    color: '#EF4444',
    textAlign: 'center',
    marginBottom: 16,
  },
  retryButton: {
    backgroundColor: '#1F2937',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  retryButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  controlGroup: { marginTop: 16 },
  controlLabel: { fontSize: 14, fontWeight: '600', marginBottom: 4, color: '#374151' },
  refreshButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    marginTop: 16,
    backgroundColor: '#F3F4F6',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  refreshButtonText: {
    marginLeft: 8,
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  map: {
    ...StyleSheet.absoluteFillObject,
  },
});

export default MatchesPage; 