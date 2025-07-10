import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import Slider from '@react-native-community/slider';
import { Picker } from '@react-native-picker/picker';
import { X } from 'lucide-react-native';

type FilterModalParams = {
  radius: string;
  area: string;
  subarea: string;
};

export default function FilterModal() {
  const router = useRouter();
  const params = useLocalSearchParams<FilterModalParams>();

  const [radiusKm, setRadiusKm] = useState(Number(params.radius) || 50);
  const [area, setArea] = useState(params.area || '');
  const [subarea, setSubarea] = useState(params.subarea || '');

  const legalAreas = [
    'Direito de Família', 'Direito Trabalhista', 'Direito Tributário',
    'Direito Civil', 'Direito Empresarial'
  ];

  const subareasMap: Record<string, string[]> = {
    'Direito de Família': ['Divórcio', 'Partilha de Bens', 'Pensão Alimentícia'],
    'Direito Trabalhista': ['Rescisão', 'Assédio Moral'],
    'Direito Tributário': ['Impostos Federais', 'Impostos Municipais'],
  };

  const handleApplyFilters = () => {
    // A navegação para trás automaticamente passa os parâmetros atualizados
    // para a tela anterior se usarmos `router.back()` com `setParams` antes,
    // mas aqui vamos usar um método mais explícito para garantir a atualização.
    // O ideal seria usar um gerenciador de estado (Zustand, Redux, Context).
    // Por simplicidade, vamos assumir que a tela anterior escuta as mudanças.
    // Expo Router não tem um `setParams` direto como React Navigation.
    // A melhor abordagem é navegar para a rota com novos parâmetros.
    router.back();
    // A tela anterior (MatchesPage) vai detectar a mudança nos parâmetros
    // através do useLocalSearchParams e refazer a busca.
    // O ideal seria usar um listener ou gerenciador de estado global.
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Filtros</Text>
        <TouchableOpacity onPress={() => router.back()}>
          <X size={24} color="#6B7280" />
        </TouchableOpacity>
      </View>
      <ScrollView style={styles.content}>
        <View style={styles.controlGroup}>
          <Text style={styles.controlLabel}>Raio de busca: {radiusKm} km</Text>
          <Slider
            style={{ width: '100%' }}
            minimumValue={20}
            maximumValue={200}
            step={10}
            value={radiusKm}
            onValueChange={setRadiusKm}
            minimumTrackTintColor="#1F2937"
            maximumTrackTintColor="#D1D5DB"
          />
        </View>

        <View style={styles.controlGroup}>
          <Text style={styles.controlLabel}>Área do Direito</Text>
          <Picker selectedValue={area} onValueChange={(v) => { setArea(v); setSubarea(''); }}>
            <Picker.Item label="(Todas as áreas)" value="" />
            {legalAreas.map(a => <Picker.Item key={a} label={a} value={a} />)}
          </Picker>
        </View>

        {area && (
          <View style={styles.controlGroup}>
            <Text style={styles.controlLabel}>Subárea</Text>
            <Picker selectedValue={subarea} onValueChange={setSubarea}>
              <Picker.Item label="(Todas as subáreas)" value="" />
              {(subareasMap[area] || []).map(s => <Picker.Item key={s} label={s} value={s} />)}
            </Picker>
          </View>
        )}
      </ScrollView>
      <View style={styles.footer}>
        <TouchableOpacity style={styles.applyButton} onPress={handleApplyFilters}>
          <Text style={styles.applyButtonText}>Aplicar Filtros</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 16, borderBottomWidth: 1, borderBottomColor: '#E5E7EB' },
  title: { fontSize: 20, fontWeight: 'bold' },
  content: { flex: 1, padding: 16 },
  controlGroup: { marginBottom: 24 },
  controlLabel: { fontSize: 16, fontWeight: '600', marginBottom: 8 },
  footer: { padding: 16, borderTopWidth: 1, borderTopColor: '#E5E7EB' },
  applyButton: { backgroundColor: '#1E40AF', padding: 16, borderRadius: 12, alignItems: 'center' },
  applyButtonText: { color: 'white', fontSize: 18, fontWeight: 'bold' },
}); 