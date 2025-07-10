import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

type Intent = 'primary' | 'secondary' | 'success' | 'warning' | 'danger' | 'info' | 'neutral';

interface BadgeProps {
  label: string;
  intent?: Intent;
  size?: 'small' | 'medium';
}

const intentColors = {
  primary: { bg: '#DBEAFE', text: '#1E40AF' },
  secondary: { bg: '#E5E7EB', text: '#4B5563' },
  success: { bg: '#D1FAE5', text: '#065F46' },
  warning: { bg: '#FEF3C7', text: '#92400E' },
  danger: { bg: '#FEE2E2', text: '#991B1B' },
  info: { bg: '#DBEAFE', text: '#1E40AF' },
  neutral: { bg: '#F3F4F6', text: '#4B5563' },
};

export default function Badge({ 
  label, 
  intent = 'neutral', 
  size = 'medium'
}: BadgeProps) {
  
  const colors = intentColors[intent] || intentColors.neutral;

  const sizeStyles = {
    small: {
      paddingHorizontal: 8,
      paddingVertical: 2,
      fontSize: 10,
    },
    medium: {
      paddingHorizontal: 12,
      paddingVertical: 4,
      fontSize: 12,
    },
  };

  const selectedSize = sizeStyles[size];

  return (
    <View style={[
      styles.container,
      { 
        backgroundColor: colors.bg,
        paddingHorizontal: selectedSize.paddingHorizontal,
        paddingVertical: selectedSize.paddingVertical,
      }
    ]}>
      <Text style={[
        styles.text,
        { 
          color: colors.text,
          fontSize: selectedSize.fontSize,
        }
      ]}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 20,
    alignSelf: 'flex-start',
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    fontFamily: 'Inter-Medium',
  },
});
