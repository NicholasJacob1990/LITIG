/**
 * LawyerOffersPage.tsx
 * Componente para advogados visualizarem e responderem às ofertas recebidas.
 * Implementa a Fase 4 do fluxo de match: Sinal de Interesse.
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
import { router } from 'expo-router';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/lib/contexts/AuthContext';

interface Offer {
  id: string;
  case_id: string;
  status: 'pending' | 'interested' | 'declined' | 'expired';
  sent_at: string;
  expires_at: string;
  fair_score: number;
  case: {
    area: string;
    subarea: string;
    urgency_h: number;
    texto_cliente: string;
  };
}

export default function LawyerOffersPage() {
  const { user } = useAuth();
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [respondingTo, setRespondingTo] = useState<string | null>(null);

  const fetchOffers = async () => {
    try {
      const { data, error } = await supabase.functions.invoke('api/offers/lawyer/my-offers', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${user?.access_token}`,
        },
      });

      if (error) throw error;
      setOffers(data || []);
    } catch (error) {
      console.error('Erro ao buscar ofertas:', error);
      Alert.alert('Erro', 'Não foi possível carregar suas ofertas.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const respondToOffer = async (offerId: string, status: 'interested' | 'declined') => {
    setRespondingTo(offerId);
    
    try {
      const { error } = await supabase.functions.invoke(`api/offers/${offerId}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${user?.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status }),
      });

      if (error) throw error;

      // Atualiza a lista local
      setOffers(prev => 
        prev.map(offer => 
          offer.id === offerId 
            ? { ...offer, status, responded_at: new Date().toISOString() }
            : offer
        )
      );

      Alert.alert(
        'Sucesso',
        status === 'interested' 
          ? 'Interesse confirmado! O cliente será notificado.'
          : 'Oferta recusada.'
      );
    } catch (error) {
      console.error('Erro ao responder oferta:', error);
      Alert.alert('Erro', 'Não foi possível responder à oferta.');
    } finally {
      setRespondingTo(null);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    fetchOffers();
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

  const getUrgencyColor = (urgencyH: number) => {
    if (urgencyH <= 24) return '#EF4444'; // red - muito urgente
    if (urgencyH <= 72) return '#F59E0B'; // yellow - urgente
    return '#10B981'; // green - normal
  };

  const getUrgencyText = (urgencyH: number) => {
    if (urgencyH <= 24) return 'Muito Urgente';
    if (urgencyH <= 72) return 'Urgente';
    return 'Normal';
  };

  useEffect(() => {
    fetchOffers();
  }, []);

  if (loading) {
    return (
      <View className="flex-1 justify-center items-center bg-gray-50">
        <ActivityIndicator size="large" color="#2563EB" />
        <Text className="mt-2 text-gray-600">Carregando ofertas...</Text>
      </View>
    );
  }

  const pendingOffers = offers.filter(offer => offer.status === 'pending');
  const respondedOffers = offers.filter(offer => offer.status !== 'pending');

  return (
    <View className="flex-1 bg-gray-50">
      {/* Header */}
      <View className="bg-white p-4 border-b border-gray-200">
        <Text className="text-lg font-bold text-gray-900">
          Minhas Ofertas
        </Text>
        <Text className="text-sm text-gray-600">
          {pendingOffers.length} pendentes • {respondedOffers.length} respondidas
        </Text>
      </View>

      <ScrollView
        className="flex-1"
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Ofertas Pendentes */}
        {pendingOffers.length > 0 && (
          <View className="p-4">
            <Text className="text-lg font-semibold text-gray-900 mb-3">
              Aguardando Resposta ({pendingOffers.length})
            </Text>
            {pendingOffers.map((offer) => (
              <View
                key={offer.id}
                className="bg-white rounded-lg p-4 mb-4 shadow-sm border border-gray-200"
              >
                {/* Header do caso */}
                <View className="flex-row justify-between items-start mb-3">
                  <View className="flex-1">
                    <Text className="font-semibold text-gray-900">
                      {offer.case.area} - {offer.case.subarea}
                    </Text>
                    <Text className="text-sm text-gray-600 mt-1">
                      Score: {Math.round(offer.fair_score * 100)}%
                    </Text>
                  </View>
                  <View
                    className="px-2 py-1 rounded"
                    style={{ backgroundColor: getUrgencyColor(offer.case.urgency_h) + '20' }}
                  >
                    <Text
                      className="text-xs font-medium"
                      style={{ color: getUrgencyColor(offer.case.urgency_h) }}
                    >
                      {getUrgencyText(offer.case.urgency_h)}
                    </Text>
                  </View>
                </View>

                {/* Descrição do caso */}
                <Text className="text-sm text-gray-700 mb-3" numberOfLines={3}>
                  {offer.case.texto_cliente}
                </Text>

                {/* Tempo restante */}
                <Text className="text-sm text-orange-600 mb-4">
                  ⏰ {formatTimeRemaining(offer.expires_at)}
                </Text>

                {/* Ações */}
                <View className="flex-row space-x-3">
                  <TouchableOpacity
                    onPress={() => respondToOffer(offer.id, 'interested')}
                    disabled={respondingTo === offer.id}
                    className="flex-1 bg-green-600 py-3 rounded-lg items-center"
                    style={{
                      opacity: respondingTo === offer.id ? 0.6 : 1
                    }}
                  >
                    {respondingTo === offer.id ? (
                      <ActivityIndicator size="small" color="white" />
                    ) : (
                      <Text className="text-white font-medium">
                        Tenho Interesse
                      </Text>
                    )}
                  </TouchableOpacity>
                  
                  <TouchableOpacity
                    onPress={() => respondToOffer(offer.id, 'declined')}
                    disabled={respondingTo === offer.id}
                    className="flex-1 bg-gray-600 py-3 rounded-lg items-center"
                    style={{
                      opacity: respondingTo === offer.id ? 0.6 : 1
                    }}
                  >
                    <Text className="text-white font-medium">
                      Recusar
                    </Text>
                  </TouchableOpacity>
                  
                  <TouchableOpacity
                    onPress={() => {
                      router.push({
                        pathname: '/case-details',
                        params: { case_id: offer.case_id },
                      });
                    }}
                    className="bg-blue-600 px-4 py-3 rounded-lg items-center"
                  >
                    <Text className="text-white font-medium">
                      Ver Mais
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            ))}
          </View>
        )}

        {/* Ofertas Respondidas */}
        {respondedOffers.length > 0 && (
          <View className="p-4">
            <Text className="text-lg font-semibold text-gray-900 mb-3">
              Histórico ({respondedOffers.length})
            </Text>
            {respondedOffers.map((offer) => (
              <View
                key={offer.id}
                className="bg-white rounded-lg p-4 mb-4 shadow-sm border border-gray-200 opacity-75"
              >
                <View className="flex-row justify-between items-start">
                  <View className="flex-1">
                    <Text className="font-medium text-gray-900">
                      {offer.case.area} - {offer.case.subarea}
                    </Text>
                    <Text className="text-sm text-gray-600">
                      Score: {Math.round(offer.fair_score * 100)}%
                    </Text>
                  </View>
                  <View
                    className="px-2 py-1 rounded"
                    style={{
                      backgroundColor: offer.status === 'interested' ? '#10B981' : '#EF4444',
                      opacity: 0.2
                    }}
                  >
                    <Text
                      className="text-xs font-medium"
                      style={{
                        color: offer.status === 'interested' ? '#10B981' : '#EF4444'
                      }}
                    >
                      {offer.status === 'interested' ? 'Interessado' : 'Recusado'}
                    </Text>
                  </View>
                </View>
              </View>
            ))}
          </View>
        )}

        {/* Estado vazio */}
        {offers.length === 0 && (
          <View className="flex-1 justify-center items-center p-8">
            <Text className="text-gray-600 text-center">
              Você ainda não recebeu nenhuma oferta.
            </Text>
            <Text className="text-gray-500 text-center mt-2">
              Complete seu perfil para receber mais casos!
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}
