import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface MetricCardProps {
  title: string;
  value: string;
  icon: React.ComponentType<any>;
  color: string;
}

const MetricCard: React.FC<MetricCardProps> = ({ title, value, icon: Icon, color }) => (
  <View style={styles.card}>
    <View style={[styles.iconContainer, { backgroundColor: `${color}20` }]}>
      <Icon size={24} color={color} />
    </View>
    <Text style={styles.value}>{value}</Text>
    <Text style={styles.title}>{title}</Text>
  </View>
);

const styles = StyleSheet.create({
  card: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    flex: 1,
    margin: 4,
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  value: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  title: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 4,
  },
});

export default MetricCard; 