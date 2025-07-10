import React from 'react';
import { Platform, View, Text, Image, TouchableOpacity, StyleSheet, Dimensions } from 'react-native';

interface GoogleMapProps {
  lawyers: any[];
  center: { latitude: number; longitude: number };
  selectedLawyer?: any;
  onLawyerSelect: (lawyer: any) => void;
  onLawyerPress: (lawyer: any) => void;
}

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

export default function GoogleMap(props: GoogleMapProps) {
  // Fallback para web, Expo Go ou quando react-native-maps não estiver disponível
  if (Platform.OS === 'web' || (global as any).ExpoGo) {
    return (
      <View style={styles.fallbackContainer}>
        <Text style={styles.fallbackText}>
          🗺️ Mapa disponível apenas no app instalado
        </Text>
        <Text style={styles.fallbackSubtext}>
          EAS Build ou Dev Client necessário
        </Text>
      </View>
    );
  }

  // Tentar importar react-native-maps de forma segura
  try {
     
    const { default: MapView, Marker } = require('react-native-maps');
    
    const { lawyers, center, selectedLawyer, onLawyerSelect, onLawyerPress } = props;

    return (
      <View style={styles.container}>
        <MapView
          style={styles.map}
          initialRegion={{
            latitude: center.latitude,
            longitude: center.longitude,
            latitudeDelta: 0.0922,
            longitudeDelta: 0.0421,
          }}
          showsUserLocation={true}
          showsMyLocationButton={true}
          showsCompass={true}
          showsScale={true}
        >
          {lawyers.map((lawyer) => (
            <Marker
              key={lawyer.id}
              coordinate={{ latitude: lawyer.lat, longitude: lawyer.lng }}
              title={lawyer.name}
              description={`${lawyer.primary_area} • ${lawyer.rating}⭐`}
              onPress={() => onLawyerPress(lawyer)}
            >
              <TouchableOpacity
                style={[
                  styles.markerContainer,
                  selectedLawyer?.id === lawyer.id && styles.markerContainerSelected
                ]}
                onPress={() => onLawyerSelect(lawyer)}
              >
                <Image source={{ uri: lawyer.avatar_url }} style={styles.markerAvatar} />
                <View style={styles.markerBadge}>
                  <Text style={styles.markerRating}>{lawyer.rating}</Text>
                </View>
                {lawyer.is_available && <View style={styles.onlineIndicator} />}
              </TouchableOpacity>
            </Marker>
          ))}
        </MapView>
      </View>
    );
  } catch (error) {
    // Se react-native-maps não estiver disponível, mostrar fallback
    return (
      <View style={styles.fallbackContainer}>
        <Text style={styles.fallbackText}>
          🗺️ Mapa indisponível no Expo Go
        </Text>
        <Text style={styles.fallbackSubtext}>
          Use um build nativo para visualizar o mapa
        </Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    width: '100%',
    height: '100%',
  },
  fallbackContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    padding: 40,
  },
  fallbackText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#374151',
    textAlign: 'center',
    marginBottom: 8,
  },
  fallbackSubtext: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
  markerContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#FFFFFF',
    borderWidth: 2,
    borderColor: '#1E40AF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
  },
  markerContainerSelected: {
    borderColor: '#F59E0B',
    backgroundColor: '#FEF3C7',
  },
  markerAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  markerBadge: {
    position: 'absolute',
    top: -5,
    right: -5,
    backgroundColor: '#1E40AF',
    borderRadius: 10,
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  markerRating: {
    color: '#FFFFFF',
    fontSize: 10,
    fontFamily: 'Inter-Bold',
  },
  onlineIndicator: {
    position: 'absolute',
    bottom: -2,
    right: -2,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#10B981',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
}); 