import React from 'react';
import { Text, StyleSheet } from 'react-native';

interface FileSizeProps {
  size: number; // in bytes
}

export default function FileSize({ size }: FileSizeProps) {
  const formatSize = (bytes: number): string => {
    const mb = bytes / (1024 * 1024);
    return `${mb.toFixed(1)} MB`;
  };

  return (
    <Text style={styles.text}>
      {formatSize(size)}
    </Text>
  );
}

const styles = StyleSheet.create({
  text: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#9CA3AF',
  },
}); 