import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface MoneyTileProps {
  value: number;
  currency?: string;
  label?: string;
  size?: 'small' | 'medium' | 'large';
  variant?: 'primary' | 'secondary' | 'success' | 'warning';
}

export default function MoneyTile({ 
  value, 
  currency = 'R$', 
  label, 
  size = 'medium',
  variant = 'primary'
}: MoneyTileProps) {
  const formatValue = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value);
  };

  const getContainerStyle = () => {
    return [
      styles.container,
      variant === 'secondary' && styles.secondary,
      variant === 'success' && styles.success,
      variant === 'warning' && styles.warning,
      variant === 'primary' && styles.primary,
      size === 'small' && styles.small,
      size === 'large' && styles.large,
      size === 'medium' && styles.medium,
    ].filter(Boolean);
  };

  const getValueStyle = () => {
    return [
      styles.value,
      size === 'small' && styles.smallValue,
      size === 'large' && styles.largeValue,
      size === 'medium' && styles.mediumValue,
    ].filter(Boolean);
  };

  const getLabelStyle = () => {
    return [
      styles.label,
      size === 'small' && styles.smallLabel,
      size === 'large' && styles.largeLabel,
      size === 'medium' && styles.mediumLabel,
    ].filter(Boolean);
  };

  return (
    <View style={getContainerStyle()}>
      <Text style={getValueStyle()}>
        {currency} {formatValue(value)}
      </Text>
      {label && (
        <Text style={getLabelStyle()}>{label}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  value: {
    fontFamily: 'Inter-Bold',
    color: '#FFFFFF',
  },
  label: {
    fontFamily: 'Inter-Medium',
    color: '#FFFFFF',
    opacity: 0.8,
  },
  // Sizes
  small: {
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  medium: {
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  large: {
    paddingHorizontal: 20,
    paddingVertical: 12,
  },
  // Variants
  primary: {
    backgroundColor: '#006CFF',
  },
  secondary: {
    backgroundColor: '#6B7280',
  },
  success: {
    backgroundColor: '#1DB57C',
  },
  warning: {
    backgroundColor: '#F5A623',
  },
  // Value sizes
  smallValue: {
    fontSize: 14,
  },
  mediumValue: {
    fontSize: 16,
  },
  largeValue: {
    fontSize: 20,
  },
  // Label sizes
  smallLabel: {
    fontSize: 10,
    marginTop: 2,
  },
  mediumLabel: {
    fontSize: 12,
    marginTop: 4,
  },
  largeLabel: {
    fontSize: 14,
    marginTop: 4,
  },
}); 