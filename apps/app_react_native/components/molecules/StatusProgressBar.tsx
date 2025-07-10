import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface StatusProgressBarProps {
  statuses: {
    key: string;
    label: string;
    count: number;
    color: string;
  }[];
  total: number;
}

export default function StatusProgressBar({ statuses, total }: StatusProgressBarProps) {
  const getPercentage = (count: number) => {
    return total > 0 ? (count / total) * 100 : 0;
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Distribuição de Casos</Text>
      
      <View style={styles.progressContainer}>
        <View style={styles.progressBar}>
          {statuses.map((status) => {
            const percentage = getPercentage(status.count);
            if (percentage === 0) return null;
            
            return (
              <View
                key={status.key}
                style={[
                  styles.progressSegment,
                  {
                    backgroundColor: status.color,
                    flex: percentage,
                  },
                ]}
              />
            );
          })}
        </View>
        
        <View style={styles.progressLabels}>
          {statuses.map((status) => {
            const percentage = getPercentage(status.count);
            if (percentage === 0) return null;
            
            return (
              <View key={status.key} style={styles.progressLabel}>
                <View
                  style={[
                    styles.progressDot,
                    { backgroundColor: status.color },
                  ]}
                />
                <Text style={styles.progressText}>
                  {status.label}: {status.count}
                </Text>
              </View>
            );
          })}
        </View>
      </View>
      
      <Text style={styles.totalText}>Total: {total} casos</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    padding: 16,
    marginTop: 16,
  },
  title: {
    color: '#fff',
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    marginBottom: 12,
  },
  progressContainer: {
    marginBottom: 12,
  },
  progressBar: {
    flexDirection: 'row',
    height: 8,
    borderRadius: 4,
    overflow: 'hidden',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    marginBottom: 8,
  },
  progressSegment: {
    minWidth: 2,
  },
  progressLabels: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  progressLabel: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  progressDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 6,
  },
  progressText: {
    color: '#E5E7EB',
    fontFamily: 'Inter-Regular',
    fontSize: 12,
  },
  totalText: {
    color: '#fff',
    fontFamily: 'Inter-Medium',
    fontSize: 13,
    textAlign: 'center',
  },
}); 