import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';

interface EmptyStateProps {
  icon?: React.ComponentType<{ size: number; color: string }>;
  title: string;
  description?: string;
  actionText?: string;
  onAction?: () => void;
  size?: 'small' | 'medium' | 'large';
  variant?: 'default' | 'error' | 'info';
}

export default function EmptyState({
  icon: Icon,
  title,
  description,
  actionText,
  onAction,
  size = 'medium',
  variant = 'default'
}: EmptyStateProps) {
  const iconSize = {
    small: 32,
    medium: 48,
    large: 64
  }[size];

  const iconColor = {
    default: '#9CA3AF',
    error: '#EF4444',
    info: '#3B82F6'
  }[variant];

  return (
    <View style={[styles.container, styles[size]]}>
      {Icon && (
        <View style={[styles.iconContainer, styles[`iconContainer${variant.charAt(0).toUpperCase() + variant.slice(1)}` as keyof typeof styles]]}>
          <Icon size={iconSize} color={iconColor} />
        </View>
      )}
      
      <Text style={[styles.title, styles[`title${size.charAt(0).toUpperCase() + size.slice(1)}` as keyof typeof styles]]}>
        {title}
      </Text>
      
      {description && (
        <Text style={[styles.description, styles[`description${size.charAt(0).toUpperCase() + size.slice(1)}` as keyof typeof styles]]}>
          {description}
        </Text>
      )}
      
      {actionText && onAction && (
        <TouchableOpacity 
          style={[styles.actionButton, styles[`actionButton${variant.charAt(0).toUpperCase() + variant.slice(1)}` as keyof typeof styles]]}
          onPress={onAction}
        >
          <Text style={[styles.actionButtonText, styles[`actionButtonText${variant.charAt(0).toUpperCase() + variant.slice(1)}` as keyof typeof styles]]}>
            {actionText}
          </Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  small: {
    paddingVertical: 24,
  },
  medium: {
    paddingVertical: 48,
  },
  large: {
    paddingVertical: 64,
  },
  iconContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  iconContainerDefault: {
    backgroundColor: '#F3F4F6',
  },
  iconContainerError: {
    backgroundColor: '#FEF2F2',
  },
  iconContainerInfo: {
    backgroundColor: '#EFF6FF',
  },
  title: {
    fontFamily: 'Inter-SemiBold',
    color: '#1F2937',
    textAlign: 'center',
    marginBottom: 8,
  },
  titleSmall: {
    fontSize: 16,
  },
  titleMedium: {
    fontSize: 18,
  },
  titleLarge: {
    fontSize: 20,
  },
  description: {
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 24,
  },
  descriptionSmall: {
    fontSize: 13,
  },
  descriptionMedium: {
    fontSize: 14,
  },
  descriptionLarge: {
    fontSize: 16,
  },
  actionButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
  },
  actionButtonDefault: {
    backgroundColor: '#006CFF',
    borderColor: '#006CFF',
  },
  actionButtonError: {
    backgroundColor: '#EF4444',
    borderColor: '#EF4444',
  },
  actionButtonInfo: {
    backgroundColor: '#3B82F6',
    borderColor: '#3B82F6',
  },
  actionButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
  },
  actionButtonTextDefault: {
    color: '#FFFFFF',
  },
  actionButtonTextError: {
    color: '#FFFFFF',
  },
  actionButtonTextInfo: {
    color: '#FFFFFF',
  },
});
