import React from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import CaseHeader from '../molecules/CaseHeader';
import CaseMeta from '../molecules/CaseMeta';
import { Ionicons } from '@expo/vector-icons';

export default function CaseCard({ caso, onPress }: { caso: any; onPress?: () => void }) {
  return (
    <TouchableOpacity style={styles.card} activeOpacity={0.9} onPress={onPress}>
      <CaseHeader
        titulo={caso.titulo}
        urgencia={caso.urgencia}
        status={caso.statusLabel}
      />

      <CaseMeta
        advogado={caso.advogado}
        dataInicio={caso.dataInicio}
        mensagens={caso.mensagensNaoLidas}
      />

      <View style={styles.ctaRow}>
        <Ionicons name="eye-outline" size={14} color="#3B82F6" />
        <View style={styles.ctaSpacer} />
        <Ionicons name="chevron-forward" size={16} color="#3B82F6" />
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: '#F1F5F9',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    gap: 12,
  },
  ctaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
  },
  ctaSpacer: { flex: 1 },
});