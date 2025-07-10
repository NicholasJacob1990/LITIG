/**
 * OffersPage.tsx
 * Componente para exibir ofertas de advogados interessados em um caso.
 * Implementa a Fase 5 do fluxo de match: Exibição.
 */
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/lib/contexts/AuthContext';

interface Offer {
  id: string;
  case_id: string;
  lawyer_id: string;
  status: 'pending' | 'interested' | 'declined' | 'expired' | 'closed';
  sent_at: string;
  responded_at?: string;
  expires_at: string;
  fair_score: number;
  lawyer: {
    nome: string;
    avatar_url?: string;
    rating: number;
  };
}

interface OffersResponse {
  case_id: string;
  offers: Offer[];
  total: number;
  interested_count: number;
  pending_count: number;
}

export default function OffersPage() {
  const { case_id } = useLocalSearchParams<{ case_id: string }>();
  const { user } = useAuth();
  const [offers, setOffers] = useState<OffersResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchOffers = async () => {
    try {
      const { data, error } = await supabase.functions.invoke('api/offers/case/' + case_id, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${user?.access_token}`,
        },
      });

      if (error) throw error;
      setOffers(data);
    } catch (error) {
      console.error('Erro ao buscar ofertas:', error);
      Alert.alert('Erro', 'Não foi possível carregar as ofertas.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    fetchOffers();
  };

  const handleSelectLawyer = (offer: Offer) => {
    Alert.alert(
      'Contratar Advogado',
      `Deseja contratar ${offer.lawyer.nome}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Contratar',
          onPress: () => {
            // TODO: Implementar contratação (Fase 7)
            router.push({
              pathname: '/contract',
              params: {
                case_id: case_id,
                lawyer_id: offer.lawyer_id,
                offer_id: offer.id,
              },
            });
          },
        },
      ]
    );
  };

  const formatTimeRemaining = (expiresAt: string) => {
    const now = new Date();
    const expires = new Date(expiresAt);
    const diff = expires.getTime() - now.getTime();
    
    if (diff <= 0) return 'Expirado';
    
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    if (hours > 0) {
      return `${hours}h ${minutes}m restantes`;
    }
    return `${minutes}m restantes`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'interested':
        return '#10B981'; // green
      case 'pending':
        return '#F59E0B'; // yellow
      case 'declined':
        return '#EF4444'; // red
      case 'expired':
        return '#6B7280'; // gray
      default:
        return '#6B7280';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'interested':
        return 'Interessado';
      case 'pending':
        return 'Aguardando';
      case 'declined':
        return 'Recusou';
      case 'expired':
        return 'Expirado';
      default:
        return status;
    }
  };

  useEffect(() => {
    fetchOffers();
  }, [case_id]);

  if (loading) {
    return (
      <View className="flex-1 justify-center items-center bg-gray-50">
        <ActivityIndicator size="large" color="#2563EB" />
        <Text className="mt-2 text-gray-600">Carregando ofertas...</Text>
      </View>
    );
  }

  if (!offers) {
    return (
      <View className="flex-1 justify-center items-center bg-gray-50">
        <Text className="text-gray-600">Erro ao carregar ofertas</Text>
        <TouchableOpacity
          onPress={fetchOffers}
          className="mt-4 bg-blue-600 px-4 py-2 rounded-lg"
        >
          <Text className="text-white font-medium">Tentar novamente</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View className="flex-1 bg-gray-50">
      {/* Header com estatísticas */}
      <View className="bg-white p-4 border-b border-gray-200">
        <Text className="text-lg font-bold text-gray-900 mb-2">
          Ofertas Recebidas
        </Text>
        <View className="flex-row justify-between">
          <View className="items-center">
            <Text className="text-2xl font-bold text-blue-600">
              {offers.total}
            </Text>
            <Text className="text-sm text-gray-600">Total</Text>
          </View>
          <View className="items-center">
            <Text className="text-2xl font-bold text-green-600">
              {offers.interested_count}
            </Text>
            <Text className="text-sm text-gray-600">Interessados</Text>
          </View>
          <View className="items-center">
            <Text className="text-2xl font-bold text-yellow-600">
              {offers.pending_count}
            </Text>
            <Text className="text-sm text-gray-600">Pendentes</Text>
          </View>
        </View>
      </View>

      {/* Lista de ofertas */}
      <ScrollView
        className="flex-1"
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {offers.offers.length === 0 ? (
          <View className="flex-1 justify-center items-center p-8">
            <Text className="text-gray-600 text-center">
              Nenhuma oferta encontrada para este caso.
            </Text>
          </View>
        ) : (
          <View className="p-4 space-y-4">
            {offers.offers.map((offer) => (
              <View
                key={offer.id}
                className="bg-white rounded-lg p-4 shadow-sm border border-gray-200"
              >
                {/* Header do advogado */}
                <View className="flex-row items-center justify-between mb-3">
                  <View className="flex-row items-center flex-1">
                    <View className="w-12 h-12 bg-blue-100 rounded-full items-center justify-center mr-3">
                      <Text className="text-blue-600 font-bold text-lg">
                        {offer.lawyer.nome.charAt(0)}
                      </Text>
                    </View>
                    <View className="flex-1">
                      <Text className="font-semibold text-gray-900">
                        {offer.lawyer.nome}
                      </Text>
                      <Text className="text-sm text-gray-600">
                        ⭐ {offer.lawyer.rating.toFixed(1)} • Score {Math.round(offer.fair_score * 100)}%
                      </Text>
                    </View>
                  </View>
                  
                  {/* Status badge */}
                  <View
                    className="px-3 py-1 rounded-full"
                    style={{ backgroundColor: getStatusColor(offer.status) + '20' }}
                  >
                    <Text
                      className="text-sm font-medium"
                      style={{ color: getStatusColor(offer.status) }}
                    >
                      {getStatusText(offer.status)}
                    </Text>
                  </View>
                </View>

                {/* Informações da oferta */}
                <View className="mb-3">
                  <Text className="text-sm text-gray-600">
                    Enviado em: {new Date(offer.sent_at).toLocaleDateString('pt-BR')}
                  </Text>
                  {offer.status === 'pending' && (
                    <Text className="text-sm text-orange-600 mt-1">
                      ⏰ {formatTimeRemaining(offer.expires_at)}
                    </Text>
                  )}
                  {offer.responded_at && (
                    <Text className="text-sm text-gray-600 mt-1">
                      Respondido em: {new Date(offer.responded_at).toLocaleDateString('pt-BR')}
                    </Text>
                  )}
                </View>

                {/* Ações */}
                {offer.status === 'interested' && (
                  <View className="flex-row space-x-3">
                    <TouchableOpacity
                      onPress={() => handleSelectLawyer(offer)}
                      className="flex-1 bg-green-600 py-3 rounded-lg items-center"
                    >
                      <Text className="text-white font-medium">
                        Contratar
                      </Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      onPress={() => {
                        router.push({
                          pathname: '/chat',
                          params: { lawyer_id: offer.lawyer_id },
                        });
                      }}
                      className="flex-1 bg-blue-600 py-3 rounded-lg items-center"
                    >
                      <Text className="text-white font-medium">
                        Conversar
                      </Text>
                    </TouchableOpacity>
                  </View>
                )}
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </View>
  );
}
