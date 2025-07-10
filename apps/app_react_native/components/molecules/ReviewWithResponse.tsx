import React, { useState } from 'react';
import { View, Text, TouchableOpacity, TextInput, Alert, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Review } from '@/lib/services/api';
import ReviewsService from '@/lib/services/reviews';

interface ReviewWithResponseProps {
  review: Review;
  canRespond?: boolean;
  onResponseUpdate?: (updatedReview: Review) => void;
}

export function ReviewWithResponse({ review, canRespond = false, onResponseUpdate }: ReviewWithResponseProps) {
  const [isResponding, setIsResponding] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [responseText, setResponseText] = useState(review.lawyer_response || '');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmitResponse = async () => {
    if (!responseText.trim()) {
      Alert.alert('Erro', 'Por favor, digite sua resposta.');
      return;
    }

    setIsLoading(true);
    try {
      const updatedReview = await ReviewsService.respondToReview(review.id, {
        message: responseText.trim()
      });
      
      setIsResponding(false);
      onResponseUpdate?.(updatedReview);
      Alert.alert('Sucesso', 'Resposta enviada com sucesso!');
    } catch (error) {
      console.error('Erro ao enviar resposta:', error);
      Alert.alert('Erro', 'Não foi possível enviar a resposta. Tente novamente.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateResponse = async () => {
    if (!responseText.trim()) {
      Alert.alert('Erro', 'Por favor, digite sua resposta.');
      return;
    }

    setIsLoading(true);
    try {
      const updatedReview = await ReviewsService.updateReviewResponse(review.id, {
        message: responseText.trim()
      });
      
      setIsEditing(false);
      onResponseUpdate?.(updatedReview);
      Alert.alert('Sucesso', 'Resposta atualizada com sucesso!');
    } catch (error) {
      console.error('Erro ao atualizar resposta:', error);
      Alert.alert('Erro', 'Não foi possível atualizar a resposta. Tente novamente.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDeleteResponse = async () => {
    Alert.alert(
      'Confirmar exclusão',
      'Tem certeza que deseja remover sua resposta? Esta ação não pode ser desfeita.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Remover',
          style: 'destructive',
          onPress: async () => {
            setIsLoading(true);
            try {
              await ReviewsService.deleteReviewResponse(review.id);
              
              const updatedReview = {
                ...review,
                lawyer_response: undefined,
                lawyer_responded_at: undefined,
                response_edited_at: undefined,
                response_edit_count: 0
              };
              
              onResponseUpdate?.(updatedReview);
              Alert.alert('Sucesso', 'Resposta removida com sucesso!');
            } catch (error) {
              console.error('Erro ao remover resposta:', error);
              Alert.alert('Erro', 'Não foi possível remover a resposta. Tente novamente.');
            } finally {
              setIsLoading(false);
            }
          }
        }
      ]
    );
  };

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, index) => (
      <Ionicons
        key={index}
        name={index < rating ? 'star' : 'star-outline'}
        size={16}
        color="#FFD700"
      />
    ));
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  return (
    <View className="bg-white rounded-lg p-4 mb-4 shadow-sm border border-gray-200">
      {/* Cabeçalho da avaliação */}
      <View className="flex-row items-center justify-between mb-3">
        <View className="flex-row items-center">
          {renderStars(review.rating)}
          <Text className="ml-2 text-sm text-gray-600">
            {formatDate(review.created_at)}
          </Text>
        </View>
      </View>

      {/* Comentário do cliente */}
      {review.comment && (
        <Text className="text-gray-800 mb-3 leading-5">
          {review.comment}
        </Text>
      )}

      {/* Resposta do advogado */}
      {review.lawyer_response && !isEditing && (
        <View className="bg-blue-50 rounded-lg p-3 mt-3 border-l-4 border-blue-500">
          <View className="flex-row items-center mb-2">
            <Ionicons name="person" size={16} color="#3B82F6" />
            <Text className="text-sm font-medium text-blue-800 ml-1">
              Resposta do Advogado
            </Text>
            <Text className="text-xs text-blue-600 ml-2">
              {review.lawyer_responded_at && formatDate(review.lawyer_responded_at)}
            </Text>
          </View>
          
          <Text className="text-gray-800 leading-5">
            {review.lawyer_response}
          </Text>

          {/* Ações da resposta */}
          {canRespond && (
            <View className="flex-row justify-end mt-3 space-x-2">
              {ReviewsService.canEditResponse(review) && (
                <TouchableOpacity
                  onPress={() => {
                    setResponseText(review.lawyer_response || '');
                    setIsEditing(true);
                  }}
                  className="flex-row items-center px-3 py-1 bg-blue-100 rounded-full"
                >
                  <Ionicons name="pencil" size={14} color="#3B82F6" />
                  <Text className="text-blue-600 text-sm ml-1">Editar</Text>
                </TouchableOpacity>
              )}

              {ReviewsService.canDeleteResponse(review) && (
                <TouchableOpacity
                  onPress={handleDeleteResponse}
                  className="flex-row items-center px-3 py-1 bg-red-100 rounded-full"
                >
                  <Ionicons name="trash" size={14} color="#EF4444" />
                  <Text className="text-red-600 text-sm ml-1">Remover</Text>
                </TouchableOpacity>
              )}
            </View>
          )}
        </View>
      )}

      {/* Formulário de resposta */}
      {(isResponding || isEditing) && (
        <View className="mt-3 border-t border-gray-200 pt-3">
          <Text className="text-sm font-medium text-gray-700 mb-2">
            {isEditing ? 'Editar resposta' : 'Sua resposta'}
          </Text>
          
          <TextInput
            multiline
            numberOfLines={4}
            value={responseText}
            onChangeText={setResponseText}
            placeholder="Digite sua resposta profissional..."
            className="border border-gray-300 rounded-lg p-3 text-gray-800 min-h-[100px]"
            maxLength={1000}
          />
          
          <View className="flex-row justify-between items-center mt-2">
            <Text className="text-xs text-gray-500">
              {responseText.length}/1000 caracteres
            </Text>
            
            <View className="flex-row space-x-2">
              <TouchableOpacity
                onPress={() => {
                  setIsResponding(false);
                  setIsEditing(false);
                  setResponseText(review.lawyer_response || '');
                }}
                className="px-4 py-2 bg-gray-100 rounded-lg"
              >
                <Text className="text-gray-600">Cancelar</Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                onPress={isEditing ? handleUpdateResponse : handleSubmitResponse}
                disabled={isLoading || !responseText.trim()}
                className={`px-4 py-2 rounded-lg flex-row items-center ${
                  isLoading || !responseText.trim() 
                    ? 'bg-gray-300' 
                    : 'bg-blue-600'
                }`}
              >
                {isLoading ? (
                  <ActivityIndicator size="small" color="white" />
                ) : (
                  <Text className="text-white font-medium">
                    {isEditing ? 'Atualizar' : 'Enviar'}
                  </Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}

      {/* Botão para responder */}
      {canRespond && ReviewsService.canRespondToReview(review) && !isResponding && (
        <TouchableOpacity
          onPress={() => setIsResponding(true)}
          className="mt-3 flex-row items-center justify-center py-2 px-4 bg-blue-600 rounded-lg"
        >
          <Ionicons name="chatbubble" size={16} color="white" />
          <Text className="text-white font-medium ml-2">Responder</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

export default ReviewWithResponse; 