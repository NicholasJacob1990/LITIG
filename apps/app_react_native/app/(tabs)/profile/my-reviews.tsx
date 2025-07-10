import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, RefreshControl, TouchableOpacity, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Review } from '@/lib/services/api';
import ReviewsService from '@/lib/services/reviews';
import ReviewWithResponse from '@/components/molecules/ReviewWithResponse';

export default function MyReviewsScreen() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'needs_response'>('all');

  const loadReviews = async (refresh = false) => {
    try {
      if (refresh) {
        setIsRefreshing(true);
      } else {
        setIsLoading(true);
      }

      const data = await ReviewsService.getMyLawyerReviews({
        limit: 50,
        needsResponse: filter === 'needs_response'
      });

      setReviews(data);
    } catch (error) {
      console.error('Erro ao carregar avaliações:', error);
      Alert.alert('Erro', 'Não foi possível carregar suas avaliações. Tente novamente.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    loadReviews();
  }, [filter]);

  const handleResponseUpdate = (updatedReview: Review) => {
    setReviews(prevReviews => 
      prevReviews.map(review => 
        review.id === updatedReview.id ? updatedReview : review
      )
    );
  };

  const getFilteredReviews = () => {
    if (filter === 'needs_response') {
      return reviews.filter(review => !review.lawyer_response);
    }
    return reviews;
  };

  const filteredReviews = getFilteredReviews();
  const pendingResponsesCount = reviews.filter(review => !review.lawyer_response).length;

  if (isLoading) {
    return (
      <SafeAreaView className="flex-1 bg-gray-50">
        <View className="flex-1 justify-center items-center">
          <Text className="text-gray-600">Carregando avaliações...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView className="flex-1 bg-gray-50">
      {/* Header */}
      <View className="bg-white px-4 py-3 border-b border-gray-200">
        <Text className="text-xl font-bold text-gray-900">Minhas Avaliações</Text>
        <Text className="text-sm text-gray-600 mt-1">
          {reviews.length} avaliações recebidas
        </Text>
      </View>

      {/* Filtros */}
      <View className="bg-white px-4 py-3 border-b border-gray-200">
        <View className="flex-row space-x-3">
          <TouchableOpacity
            onPress={() => setFilter('all')}
            className={`px-4 py-2 rounded-full ${
              filter === 'all' 
                ? 'bg-blue-600' 
                : 'bg-gray-100'
            }`}
          >
            <Text className={`text-sm font-medium ${
              filter === 'all' 
                ? 'text-white' 
                : 'text-gray-700'
            }`}>
              Todas ({reviews.length})
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setFilter('needs_response')}
            className={`px-4 py-2 rounded-full ${
              filter === 'needs_response' 
                ? 'bg-orange-600' 
                : 'bg-gray-100'
            }`}
          >
            <Text className={`text-sm font-medium ${
              filter === 'needs_response' 
                ? 'text-white' 
                : 'text-gray-700'
            }`}>
              Aguardando Resposta ({pendingResponsesCount})
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Lista de avaliações */}
      <ScrollView
        className="flex-1"
        contentContainerStyle={{ padding: 16 }}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => loadReviews(true)}
          />
        }
      >
        {filteredReviews.length === 0 ? (
          <View className="flex-1 justify-center items-center py-20">
            <Ionicons name="star-outline" size={48} color="#9CA3AF" />
            <Text className="text-gray-500 text-center mt-4">
              {filter === 'needs_response' 
                ? 'Nenhuma avaliação aguardando resposta'
                : 'Você ainda não recebeu avaliações'
              }
            </Text>
            <Text className="text-gray-400 text-center mt-2 text-sm">
              {filter === 'needs_response' 
                ? 'Todas as suas avaliações já foram respondidas!'
                : 'Suas avaliações aparecerão aqui após os casos serem concluídos'
              }
            </Text>
          </View>
        ) : (
          <View>
            {/* Estatísticas rápidas */}
            <View className="bg-white rounded-lg p-4 mb-4 shadow-sm">
              <Text className="text-lg font-semibold text-gray-900 mb-3">
                Resumo das Avaliações
              </Text>
              
              <View className="flex-row justify-between">
                <View className="items-center">
                  <Text className="text-2xl font-bold text-blue-600">
                    {(reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length).toFixed(1)}
                  </Text>
                  <Text className="text-sm text-gray-600">Média</Text>
                </View>
                
                <View className="items-center">
                  <Text className="text-2xl font-bold text-green-600">
                    {reviews.filter(r => r.lawyer_response).length}
                  </Text>
                  <Text className="text-sm text-gray-600">Respondidas</Text>
                </View>
                
                <View className="items-center">
                  <Text className="text-2xl font-bold text-orange-600">
                    {pendingResponsesCount}
                  </Text>
                  <Text className="text-sm text-gray-600">Pendentes</Text>
                </View>
              </View>
            </View>

            {/* Lista de avaliações */}
            {filteredReviews.map((review) => (
              <ReviewWithResponse
                key={review.id}
                review={review}
                canRespond={true}
                onResponseUpdate={handleResponseUpdate}
              />
            ))}
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
} 