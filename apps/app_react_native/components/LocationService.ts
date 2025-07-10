import * as Location from 'expo-location';

export interface UserLocation {
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp?: number;
}

export interface AddressDetails {
  street?: string;
  streetNumber?: string;
  city?: string;
  subregion?: string;
  postalCode?: string;
}

export interface LocationPermission {
  granted: boolean;
  canAskAgain: boolean;
  status: Location.PermissionStatus;
}

class LocationService {
  private currentLocation: UserLocation | null = null;
  private permissionStatus: LocationPermission | null = null;

  /**
   * Solicita permissão de localização e obtém a posição atual
   * Conforme especificado no GPS.md
   */
  async getCurrentLocation(): Promise<UserLocation | null> {
    try {
      // Verificar permissão
      const permission = await this.requestLocationPermission();
      
      if (!permission.granted) {
        console.log('Permissão de localização negada');
        return null;
      }

      // Obter posição com alta precisão
      const position = await Location.getCurrentPositionAsync({
        accuracy: Location.Accuracy.High,
        timeInterval: 5000,
        distanceInterval: 10,
      });

      this.currentLocation = {
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
        accuracy: position.coords.accuracy ?? undefined,
        timestamp: position.timestamp,
      };

      return this.currentLocation;
    } catch (error) {
      console.error('Erro ao obter localização:', error);
      return null;
    }
  }

  /**
   * Solicita permissão de localização
   */
  async requestLocationPermission(): Promise<LocationPermission> {
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      
      this.permissionStatus = {
        granted: status === Location.PermissionStatus.GRANTED,
        canAskAgain: status !== Location.PermissionStatus.DENIED,
        status,
      };

      return this.permissionStatus;
    } catch (error) {
      console.error('Erro ao solicitar permissão:', error);
      return {
        granted: false,
        canAskAgain: false,
        status: Location.PermissionStatus.DENIED,
      };
    }
  }

  /**
   * Verifica se a permissão já foi concedida
   */
  async checkLocationPermission(): Promise<LocationPermission> {
    try {
      const { status } = await Location.getForegroundPermissionsAsync();
      
      this.permissionStatus = {
        granted: status === Location.PermissionStatus.GRANTED,
        canAskAgain: status !== Location.PermissionStatus.DENIED,
        status,
      };

      return this.permissionStatus;
    } catch (error) {
      console.error('Erro ao verificar permissão:', error);
      return {
        granted: false,
        canAskAgain: false,
        status: Location.PermissionStatus.DENIED,
      };
    }
  }

  /**
   * Geocodifica CEP para coordenadas (fallback quando GPS não disponível)
   * Conforme especificado no GPS.md
   */
  async geocodeCEP(cep: string): Promise<UserLocation | null> {
    try {
      // Em produção, usar OpenStreetMap ou serviço similar
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?postalcode=${cep}&country=BR&format=json&limit=1`
      );
      
      const data = await response.json();
      
      if (data && data.length > 0) {
        const location = data[0];
        return {
          latitude: parseFloat(location.lat),
          longitude: parseFloat(location.lon),
          timestamp: Date.now(),
        };
      }
      
      return null;
    } catch (error) {
      console.error('Erro ao geocodificar CEP:', error);
      return null;
    }
  }

  /**
   * Geocodifica um endereço completo para coordenadas.
   */
  async geocodeAddress(address: string): Promise<UserLocation | null> {
    try {
      const geocodedLocations = await Location.geocodeAsync(address);
      if (geocodedLocations && geocodedLocations.length > 0) {
        const { latitude, longitude, accuracy } = geocodedLocations[0];
        return {
          latitude,
          longitude,
          accuracy: accuracy ?? undefined,
          timestamp: Date.now(),
        };
      }
      return null;
    } catch (error) {
      console.error('Erro ao geocodificar endereço:', error);
      return null;
    }
  }

  /**
   * Calcula distância entre duas coordenadas (Haversine)
   */
  calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number {
    const R = 6371; // Raio da Terra em km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) *
        Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // Distância em km
    return distance;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  /**
   * Obtém localização atual (cached ou nova)
   */
  getCurrentLocationCached(): UserLocation | null {
    return this.currentLocation;
  }

  /**
   * Limpa cache de localização
   */
  clearLocationCache(): void {
    this.currentLocation = null;
  }

  /**
   * Verifica se o GPS está habilitado
   */
  async isLocationEnabled(): Promise<boolean> {
    try {
      const enabled = await Location.hasServicesEnabledAsync();
      return enabled;
    } catch (error) {
      console.error('Erro ao verificar se localização está habilitada:', error);
      return false;
    }
  }

  /**
   * Abre configurações de localização
   */
  async openLocationSettings(): Promise<void> {
    try {
      await Location.enableNetworkProviderAsync();
    } catch (error) {
      console.error('Erro ao abrir configurações de localização:', error);
    }
  }

  /**
   * Obtém endereço a partir de coordenadas (reverse geocoding)
   */
  async getAddressFromCoordinates(
    latitude: number,
    longitude: number
  ): Promise<string | null> {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json`
      );
      
      const data = await response.json();
      
      if (data && data.display_name) {
        return data.display_name;
      }
      
      return null;
    } catch (error) {
      console.error('Erro ao obter endereço:', error);
      return null;
    }
  }

  /**
   * Formata distância para exibição
   */
  formatDistance(distance: number): string {
    if (distance < 1) {
      return `${Math.round(distance * 1000)}m`;
    }
    return `${distance.toFixed(1)}km`;
  }

  /**
   * Valida se coordenadas são válidas
   */
  isValidCoordinates(latitude: number, longitude: number): boolean {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }
}

const locationService = new LocationService();
export default locationService; 