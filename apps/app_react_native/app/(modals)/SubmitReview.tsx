import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, Alert, KeyboardAvoidingView, Platform, ScrollView } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Star, X } from 'lucide-react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import ReviewsService, { ReviewCreatePayload } from '../../lib/services/reviews';

interface StarRatingProps {
  rating: number;
  setRating: (rating: number) => void;
}

const StarRating = ({ rating, setRating }: StarRatingProps) => {
  return (
    <View style={styles.starContainer}>
      {[1, 2, 3, 4, 5].map((star) => (
        <TouchableOpacity key={star} onPress={() => setRating(star)}>
          <Star size={36} color={star <= rating ? '#FFC107' : '#E0E0E0'} fill={star <= rating ? '#FFC107' : 'transparent'} />
        </TouchableOpacity>
      ))}
    </View>
  );
};

interface SubmitReviewParams extends Record<string, string> {
  contractId: string;
  caseId: string;
}

export default function SubmitReview() {
  const router = useRouter();
  const params = useLocalSearchParams<SubmitReviewParams>();
  const { contractId, caseId } = params;

  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState('');
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: (newReview: { contractId: string, payload: ReviewCreatePayload }) => 
      ReviewsService.createReview(newReview.contractId, newReview.payload),
    onSuccess: () => {
      Alert.alert('Sucesso', 'Sua avaliação foi enviada!');
      queryClient.invalidateQueries({ queryKey: ['reviews', contractId] });
      queryClient.invalidateQueries({ queryKey: ['cases', caseId] });
      router.back();
    },
    onError: (error: Error) => {
      Alert.alert('Erro', `Não foi possível enviar sua avaliação: ${error.message}`);
    }
  });

  const handleSubmit = () => {
    if (rating === 0) {
      Alert.alert('Avaliação Incompleta', 'Por favor, selecione uma nota de 1 a 5 estrelas.');
      return;
    }
    if (!contractId) {
      Alert.alert('Erro', 'ID do contrato não encontrado.');
      return;
    }

    mutation.mutate({ 
      contractId, 
      payload: { rating, comment } 
    });
  };

  return (
    <KeyboardAvoidingView 
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      style={styles.container}
    >
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <View style={styles.header}>
          <Text style={styles.title}>Avaliar Atendimento</Text>
          <TouchableOpacity onPress={() => router.back()}>
            <X size={24} color="#6B7280" />
          </TouchableOpacity>
        </View>

        <Text style={styles.label}>Sua nota para este caso:</Text>
        <StarRating rating={rating} setRating={setRating} />
        
        <Text style={styles.label}>Deixe um comentário (opcional):</Text>
        <TextInput
          style={styles.textArea}
          placeholder="Descreva sua experiência..."
          multiline
          numberOfLines={4}
          value={comment}
          onChangeText={setComment}
        />
        
        <TouchableOpacity 
          style={[styles.button, mutation.isPending && styles.buttonDisabled]} 
          onPress={handleSubmit} 
          disabled={mutation.isPending}
        >
          <Text style={styles.buttonText}>
            {mutation.isPending ? 'Enviando...' : 'Enviar Avaliação'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  scrollContainer: {
    flexGrow: 1,
    padding: 20,
    paddingTop: 60, // Aumentar padding para safe area
    justifyContent: 'center',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  label: {
    fontSize: 16,
    color: '#374151',
    marginBottom: 12,
    marginTop: 20,
  },
  starContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 20,
  },
  textArea: {
    height: 120,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    padding: 12,
    textAlignVertical: 'top',
    backgroundColor: '#FFF',
    fontSize: 16,
  },
  button: {
    backgroundColor: '#1E40AF',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 32,
  },
  buttonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  buttonText: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
  },
}); 