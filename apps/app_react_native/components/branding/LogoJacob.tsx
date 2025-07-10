import React from 'react';
import { View, Image, StyleSheet } from 'react-native';

interface LogoJacobProps {
  size?: 'small' | 'medium' | 'large';
  color?: string; // Optional tint color
}

export default function LogoJacob({ size = 'medium', color = '#FFFFFF' }: LogoJacobProps) {
  const sizes = {
    small: { width: 150, height: 150 },
    medium: { width: 220, height: 220 },
    large: { width: 300, height: 300 },
  } as const;

  const cfg = sizes[size] || sizes.medium;

  return (
    <View style={styles.container}>
      <Image
        source={require('../../assets/images/jacob_logo.png')}
        style={[styles.logo, { width: cfg.width, height: cfg.height, tintColor: color }]}
        resizeMode="contain"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  logo: {
    // Size and tint handled dynamically
  },
}); 