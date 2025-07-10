import React from 'react';
import { View, StyleSheet } from 'react-native';

interface StatusDotProps {
  status: 'active' | 'pending' | 'completed' | 'summary_generated' | 'warning';
  size?: 'small' | 'medium' | 'large';
}

export default function StatusDot({ status, size = 'medium' }: StatusDotProps) {
  const getColor = () => {
    switch (status) {
      case 'active':
        return '#006CFF';
      case 'pending':
        return '#E44C2E';
      case 'completed':
        return '#1DB57C';
      case 'summary_generated':
        return '#6C4DFF';
      case 'warning':
        return '#F5A623';
      default:
        return '#6B7280';
    }
  };

  const getSize = () => {
    switch (size) {
      case 'small':
        return 6;
      case 'large':
        return 12;
      default:
        return 8;
    }
  };

  const dotSize = getSize();

  return (
    <View
      style={[
        styles.dot,
        {
          width: dotSize,
          height: dotSize,
          borderRadius: dotSize / 2,
          backgroundColor: getColor(),
        },
      ]}
    />
  );
}

const styles = StyleSheet.create({
  dot: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 1,
    elevation: 1,
  },
}); 