import React from 'react';
import { StyleSheet } from 'react-native';
import MapView, { Marker, PROVIDER_GOOGLE } from 'react-native-maps';
import { LawyerSearchResult } from '@/lib/supabase';

interface LawyerMapViewProps {
  lawyers: LawyerSearchResult[];
  userLocation: {
    latitude: number;
    longitude: number;
  } | null;
  onMarkerPress?: (lawyer: LawyerSearchResult) => void;
}

const LawyerMapView: React.FC<LawyerMapViewProps> = ({ lawyers, userLocation, onMarkerPress }) => {
  const defaultLocation = {
    latitude: -23.5505,
    longitude: -46.6333,
    latitudeDelta: 0.15,
    longitudeDelta: 0.05,
  };

  const mapRegion = userLocation?.latitude && userLocation?.longitude ? {
    latitude: userLocation.latitude,
    longitude: userLocation.longitude,
    latitudeDelta: 0.15,
    longitudeDelta: 0.05,
  } : defaultLocation;

  return (
    <MapView
      style={StyleSheet.absoluteFill}
      provider={PROVIDER_GOOGLE}
      initialRegion={mapRegion}
      showsUserLocation
      showsMyLocationButton
    >
      {lawyers.map((lawyer) => (
        <Marker
          key={lawyer.id}
          coordinate={{
            latitude: lawyer.lat ?? 0,
            longitude: lawyer.lng ?? 0,
          }}
          title={lawyer.name}
          description={lawyer.primary_area}
          onPress={() => onMarkerPress && onMarkerPress(lawyer)}
        />
      ))}
    </MapView>
  );
};

export default LawyerMapView; 