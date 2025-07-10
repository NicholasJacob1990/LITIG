import React from 'react';
import { View, Text, StyleSheet, Image } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

export default function CaseMeta({
  advogado,
  dataInicio,
  mensagens,
}: {
  advogado?: { nome: string; avatar: string };
  dataInicio: string;
  mensagens?: number;
}) {
  return (
    <View style={styles.wrapper}>
      {advogado && (
        <View style={styles.row}>
          <Image source={{ uri: advogado.avatar }} style={styles.avatar} />
          <Text style={styles.metaText}>{advogado.nome}</Text>
          {mensagens ? (
            <View style={styles.badge}>
              <Text style={styles.badgeText}>{mensagens}</Text>
            </View>
          ) : null}
        </View>
      )}
      <View style={styles.row}>
        <Ionicons name="calendar-outline" size={14} color="#94A3B8" />
        <Text style={styles.metaText}>Início: {dataInicio}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: { gap: 6 },
  row: { flexDirection: 'row', alignItems: 'center' },
  avatar: { width: 20, height: 20, borderRadius: 10, marginRight: 6 },
  metaText: { fontSize: 13, color: '#64748B', marginLeft: 4 },
  badge: {
    marginLeft: 6,
    backgroundColor: '#EF4444',
    borderRadius: 8,
    paddingHorizontal: 4,
  },
  badgeText: { color: '#fff', fontSize: 10, fontWeight: '700' },
});