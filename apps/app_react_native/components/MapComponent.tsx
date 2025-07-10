import React from 'react';
import { Platform } from 'react-native';

// Importação condicional por plataforma
const LawyerMapView = Platform.OS === 'web' 
  ? require('./LawyerMapView.web').default 
  : require('./LawyerMapView').default;

interface MapComponentProps {
  lawyers: any[];
  selectedLawyer: any;
  onSelectLawyer: (lawyer: any) => void;
  region: {
    latitude: number;
    longitude: number;
    latitudeDelta: number;
    longitudeDelta: number;
  };
  onRegionChange: (region: any) => void;
}

export default function MapComponent(props: MapComponentProps) {
  return <LawyerMapView {...props} />;
} 