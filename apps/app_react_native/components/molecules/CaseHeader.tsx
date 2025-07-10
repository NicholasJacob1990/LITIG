import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Badge from '../atoms/Badge';

export default function CaseHeader({
  titulo,
  urgencia,
  status,
}: {
  titulo: string;
  urgencia: 'alta' | 'media' | 'baixa';
  status: string;
}) {
  const urgMap = { alta: 'danger', media: 'warning', baixa: 'success' } as const;

  return (
    <View style={styles.wrapper}>
      <Text style={styles.title}>{titulo}</Text>

      <View style={styles.badges}>
        <Badge label={urgencia.toUpperCase()} intent={urgMap[urgencia]} outline />
        <Badge label={status} intent="warning" />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: { marginBottom: 12 },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 8,
    lineHeight: 24,
  },
  badges: { flexDirection: 'row', gap: 8 },
}); 