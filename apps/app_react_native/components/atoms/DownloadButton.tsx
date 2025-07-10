import React from 'react';
import { TouchableOpacity, StyleSheet } from 'react-native';
import { Download } from 'lucide-react-native';

interface DownloadButtonProps {
  onPress: () => void;
}

export default function DownloadButton({ onPress }: DownloadButtonProps) {
  return (
    <TouchableOpacity
      style={styles.button}
      onPress={onPress}
      activeOpacity={0.7}
    >
      <Download size={20} color="#1DB57C" />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
}); 