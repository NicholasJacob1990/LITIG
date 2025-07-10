import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { LawyerSearchResult } from '@/lib/supabase';

interface LawyerMapViewProps {
  lawyers: LawyerSearchResult[];
  userLocation: {
    latitude: number;
    longitude: number;
  } | null;
  onMarkerPress?: (lawyer: LawyerSearchResult) => void;
}

const LawyerMapView: React.FC<LawyerMapViewProps> = ({ lawyers }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Mapa não disponível na web</Text>
      <Text style={styles.subtitle}>
        {lawyers.length} advogado{lawyers.length !== 1 ? 's' : ''} encontrado{lawyers.length !== 1 ? 's' : ''}
      </Text>
      <Text style={styles.text}>
        Use o aplicativo móvel para visualizar o mapa interativo
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    padding: 20,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#4B5563',
    marginBottom: 16,
    textAlign: 'center',
  },
  text: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
  },
});

export default LawyerMapView; 