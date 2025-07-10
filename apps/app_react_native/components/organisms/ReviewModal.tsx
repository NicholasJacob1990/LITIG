/**
 * Modal para avaliar advogados após conclusão de contratos
 */
import React, { useState } from 'react';
import { View, Text, Modal, TouchableOpacity, TextInput, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

interface ReviewModalProps {
  visible: boolean;
  onClose: () => void;
  contractId: string;
  lawyerName: string;
  onReviewSubmitted: () => void;
}

interface ReviewData {
  rating: number;
  comment: string;
  outcome?: 'won' | 'lost' | 'settled' | 'ongoing';
  communication_rating?: number;
  expertise_rating?: number;
  timeliness_rating?: number;
  would_recommend?: boolean;
}

export function ReviewModal({ 
  visible, 
  onClose, 
  contractId, 
  lawyerName, 
  onReviewSubmitted 
}: ReviewModalProps) {
  const [reviewData, setReviewData] = useState<ReviewData>({
    rating: 0,
    comment: '',
  });
  const [loading, setLoading] = useState(false);

  const StarRating = ({ 
    rating, 
    onRatingChange, 
    label 
  }: { 
    rating: number; 
    onRatingChange: (rating: number) => void;
    label: string;
  }) => (
    <View className="mb-4">
      <Text className="text-gray-700 mb-2 font-medium">{label}</Text>
      <View className="flex-row">
        {[1, 2, 3, 4, 5].map((star) => (
          <TouchableOpacity
            key={star}
            onPress={() => onRatingChange(star)}
            className="mr-1"
          >
            <Ionicons
              name={star <= rating ? "star" : "star-outline"}
              size={32}
              color={star <= rating ? "#fbbf24" : "#d1d5db"}
            />
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );

  const OutcomeSelector = () => (
    <View className="mb-4">
      <Text className="text-gray-700 mb-2 font-medium">Como foi o resultado?</Text>
      <View className="flex-row flex-wrap gap-2">
        {[
          { value: 'won', label: 'Ganhei', color: 'bg-green-100 border-green-300' },
          { value: 'lost', label: 'Perdi', color: 'bg-red-100 border-red-300' },
          { value: 'settled', label: 'Acordo', color: 'bg-blue-100 border-blue-300' },
          { value: 'ongoing', label: 'Em andamento', color: 'bg-yellow-100 border-yellow-300' },
        ].map((outcome) => (
          <TouchableOpacity
            key={outcome.value}
            onPress={() => setReviewData(prev => ({ 
              ...prev, 
              outcome: outcome.value as any 
            }))}
            className={`px-3 py-2 rounded-lg border ${
              reviewData.outcome === outcome.value 
                ? outcome.color 
                : 'bg-gray-100 border-gray-300'
            }`}
          >
            <Text className={`text-sm ${
              reviewData.outcome === outcome.value 
                ? 'text-gray-800 font-medium' 
                : 'text-gray-600'
            }`}>
              {outcome.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );

  const RecommendationSelector = () => (
    <View className="mb-4">
      <Text className="text-gray-700 mb-2 font-medium">
        Recomendaria este advogado?
      </Text>
      <View className="flex-row gap-4">
        <TouchableOpacity
          onPress={() => setReviewData(prev => ({ ...prev, would_recommend: true }))}
          className={`flex-1 py-3 px-4 rounded-lg border ${
            reviewData.would_recommend === true
              ? 'bg-green-100 border-green-300'
              : 'bg-gray-100 border-gray-300'
          }`}
        >
          <Text className={`text-center ${
            reviewData.would_recommend === true
              ? 'text-green-800 font-medium'
              : 'text-gray-600'
          }`}>
            Sim
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          onPress={() => setReviewData(prev => ({ ...prev, would_recommend: false }))}
          className={`flex-1 py-3 px-4 rounded-lg border ${
            reviewData.would_recommend === false
              ? 'bg-red-100 border-red-300'
              : 'bg-gray-100 border-gray-300'
          }`}
        >
          <Text className={`text-center ${
            reviewData.would_recommend === false
              ? 'text-red-800 font-medium'
              : 'text-gray-600'
          }`}>
            Não
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  const handleSubmit = async () => {
    if (reviewData.rating === 0) {
      Alert.alert('Erro', 'Por favor, dê uma nota de 1 a 5 estrelas');
      return;
    }

    setLoading(true);
    
    try {
      const response = await fetch(`/api/reviews/contracts/${contractId}/review`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // TODO: Adicionar token de autorização
        },
        body: JSON.stringify(reviewData),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || 'Erro ao enviar avaliação');
      }

      Alert.alert(
        'Sucesso!', 
        'Sua avaliação foi enviada com sucesso',
        [{ text: 'OK', onPress: () => {
          onReviewSubmitted();
          onClose();
        }}]
      );
      
    } catch (error) {
      Alert.alert('Erro', error instanceof Error ? error.message : 'Erro desconhecido');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View className="flex-1 bg-white">
        {/* Header */}
        <View className="flex-row items-center justify-between p-4 border-b border-gray-200">
          <TouchableOpacity onPress={onClose}>
            <Ionicons name="close" size={24} color="#6b7280" />
          </TouchableOpacity>
          
          <Text className="text-lg font-semibold text-gray-900">
            Avaliar Advogado
          </Text>
          
          <TouchableOpacity 
            onPress={handleSubmit}
            disabled={loading || reviewData.rating === 0}
            className={`px-4 py-2 rounded-lg ${
              loading || reviewData.rating === 0
                ? 'bg-gray-300'
                : 'bg-blue-600'
            }`}
          >
            <Text className={`font-medium ${
              loading || reviewData.rating === 0
                ? 'text-gray-500'
                : 'text-white'
            }`}>
              {loading ? 'Enviando...' : 'Enviar'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Content */}
        <View className="flex-1 p-4">
          {/* Lawyer Info */}
          <View className="bg-gray-50 p-4 rounded-lg mb-6">
            <Text className="text-lg font-semibold text-gray-900 mb-1">
              {lawyerName}
            </Text>
            <Text className="text-gray-600">
              Como foi sua experiência com este advogado?
            </Text>
          </View>

          {/* Rating Geral */}
          <StarRating
            rating={reviewData.rating}
            onRatingChange={(rating) => setReviewData(prev => ({ ...prev, rating }))}
            label="Avaliação geral *"
          />

          {/* Ratings Específicos */}
          <StarRating
            rating={reviewData.communication_rating || 0}
            onRatingChange={(rating) => setReviewData(prev => ({ 
              ...prev, 
              communication_rating: rating 
            }))}
            label="Comunicação"
          />

          <StarRating
            rating={reviewData.expertise_rating || 0}
            onRatingChange={(rating) => setReviewData(prev => ({ 
              ...prev, 
              expertise_rating: rating 
            }))}
            label="Conhecimento jurídico"
          />

          <StarRating
            rating={reviewData.timeliness_rating || 0}
            onRatingChange={(rating) => setReviewData(prev => ({ 
              ...prev, 
              timeliness_rating: rating 
            }))}
            label="Pontualidade"
          />

          {/* Outcome */}
          <OutcomeSelector />

          {/* Recommendation */}
          <RecommendationSelector />

          {/* Comment */}
          <View className="mb-6">
            <Text className="text-gray-700 mb-2 font-medium">
              Comentário (opcional)
            </Text>
            <TextInput
              multiline
              numberOfLines={4}
              value={reviewData.comment}
              onChangeText={(comment) => setReviewData(prev => ({ ...prev, comment }))}
              placeholder="Conte como foi sua experiência..."
              className="border border-gray-300 rounded-lg p-3 text-gray-900"
              style={{ textAlignVertical: 'top' }}
              maxLength={1000}
            />
            <Text className="text-xs text-gray-500 mt-1">
              {reviewData.comment.length}/1000 caracteres
            </Text>
          </View>
        </View>
      </View>
    </Modal>
  );
} 