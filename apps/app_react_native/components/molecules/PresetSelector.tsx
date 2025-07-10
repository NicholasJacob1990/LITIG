import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Zap, Scale, Star, DollarSign } from 'lucide-react-native';

type Preset = 'balanced' | 'fast' | 'expert' | 'economic';

interface PresetSelectorProps {
  selectedPreset: Preset;
  onSelectPreset: (preset: Preset) => void;
}

const presets: { id: Preset; label: string; icon: React.FC<any> }[] = [
  { id: 'balanced', label: 'Balanceado', icon: Scale },
  { id: 'fast', label: 'Mais Rápido', icon: Zap },
  { id: 'expert', label: 'Mais Experiente', icon: Star },
  { id: 'economic', label: 'Econômico', icon: DollarSign },
];

const PresetSelector: React.FC<PresetSelectorProps> = ({ selectedPreset, onSelectPreset }) => {
  return (
    <View style={styles.container}>
      {presets.map((preset) => {
        const isSelected = selectedPreset === preset.id;
        const Icon = preset.icon;
        return (
          <TouchableOpacity
            key={preset.id}
            style={[styles.button, isSelected && styles.buttonSelected]}
            onPress={() => onSelectPreset(preset.id)}
          >
            <Icon color={isSelected ? '#FFFFFF' : '#3B82F6'} size={18} />
            <Text style={[styles.label, isSelected && styles.labelSelected]}>
              {preset.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: '#F0F9FF',
    borderRadius: 12,
    padding: 6,
  },
  button: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderRadius: 8,
    gap: 8,
  },
  buttonSelected: {
    backgroundColor: '#3B82F6',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 3,
  },
  label: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#3B82F6',
  },
  labelSelected: {
    color: '#FFFFFF',
    fontFamily: 'Inter-SemiBold',
  },
});

export default PresetSelector; 