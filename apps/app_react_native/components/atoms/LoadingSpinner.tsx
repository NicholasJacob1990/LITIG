import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';

interface LoadingSpinnerProps {
  size?: 'small' | 'medium' | 'large';
  text?: string;
  color?: string;
  overlay?: boolean;
  fullScreen?: boolean;
}

export default function LoadingSpinner({
  size = 'medium',
  text,
  color = '#006CFF',
  overlay = false,
  fullScreen = false
}: LoadingSpinnerProps) {
  const spinnerSize = {
    small: 'small' as const,
    medium: 'large' as const,
    large: 'large' as const
  }[size];

  const containerStyle = [
    styles.container,
    fullScreen && styles.fullScreen,
    overlay && styles.overlay
  ];

  return (
    <View style={containerStyle}>
      <View style={styles.content}>
        <ActivityIndicator size={spinnerSize} color={color} />
        {text && (
          <Text style={[styles.text, { color }]}>
            {text}
          </Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  fullScreen: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 9999,
  },
  overlay: {
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
  },
  content: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    marginTop: 12,
    textAlign: 'center',
  },
}); 