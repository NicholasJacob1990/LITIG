import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Badge from '../atoms/Badge';

export default function CaseHeader({
  caseStats,
  totalCases,
}: {
  caseStats: { key: string; label: string; count: number }[];
  totalCases: number;
}) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Meus Casos</Text>
      <Text style={styles.subtitle}>
        Acompanhe todos os seus casos em um só lugar
      </Text>
      </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 24,
    paddingTop: 64, 
    paddingBottom: 24,
    backgroundColor: '#006CFF', 
  },
  title: {
    fontFamily: 'Inter-Bold',
    fontSize: 28,
    color: '#FFFFFF',
  },
  subtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    marginTop: 8,
  },
}); 