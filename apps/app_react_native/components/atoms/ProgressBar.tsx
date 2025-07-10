import React from 'react';
import { View, StyleSheet, Text } from 'react-native';

type ProgressBarProps = {
  progress?: number;
  color?: string;
  height?: number;
  showPercentage?: boolean;
};

export default function ProgressBar({
  progress = 0,
  color = '#3B82F6',
  height = 6,
  showPercentage = false,
}: ProgressBarProps) {
  const percentage = Math.min(100, Math.max(0, progress));

  return (
    <View style={styles.container}>
    <View style={[styles.track, { height }]}>
      <View style={[styles.fill, { width: `${percentage}%`, backgroundColor: color }]} />
      </View>
      {showPercentage && (
        <Text style={[styles.percentageText, { color: color }]}>{`${Math.round(percentage)}%`}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  track: {
    backgroundColor: '#E5E7EB',
    borderRadius: 8,
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    borderRadius: 8,
  },
  percentageText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 12,
    position: 'absolute',
    right: 0,
    top: -18,
  },
});
