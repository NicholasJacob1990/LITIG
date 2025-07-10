import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
  Switch
} from 'react-native';
import { X, Check } from 'lucide-react-native';

interface FilterOption {
  id: string;
  label: string;
  value?: any;
}

interface FilterSection {
  id: string;
  title: string;
  type: 'single' | 'multiple' | 'toggle' | 'range';
  options?: FilterOption[];
  value?: any;
}

interface FilterModalProps {
  visible: boolean;
  onClose: () => void;
  onApply: (filters: Record<string, any>) => void;
  onClear: () => void;
  sections: FilterSection[];
  title?: string;
}

export default function FilterModal({
  visible,
  onClose,
  onApply,
  onClear,
  sections,
  title = 'Filtros'
}: FilterModalProps) {
  const [filters, setFilters] = useState<Record<string, any>>({});

  const handleSingleSelect = (sectionId: string, optionId: string) => {
    setFilters(prev => ({
      ...prev,
      [sectionId]: optionId
    }));
  };

  const handleMultipleSelect = (sectionId: string, optionId: string) => {
    setFilters(prev => {
      const currentValues = prev[sectionId] || [];
      const isSelected = currentValues.includes(optionId);
      
      return {
        ...prev,
        [sectionId]: isSelected
          ? currentValues.filter((id: string) => id !== optionId)
          : [...currentValues, optionId]
      };
    });
  };

  const handleToggle = (sectionId: string, value: boolean) => {
    setFilters(prev => ({
      ...prev,
      [sectionId]: value
    }));
  };

  const handleClear = () => {
    setFilters({});
    onClear();
  };

  const handleApply = () => {
    onApply(filters);
    onClose();
  };

  const renderSection = (section: FilterSection) => {
    switch (section.type) {
      case 'single':
        return (
          <View key={section.id} style={styles.section}>
            <Text style={styles.sectionTitle}>{section.title}</Text>
            {section.options?.map((option) => (
              <TouchableOpacity
                key={option.id}
                style={styles.option}
                onPress={() => handleSingleSelect(section.id, option.id)}
              >
                <Text style={styles.optionText}>{option.label}</Text>
                {filters[section.id] === option.id && (
                  <Check size={20} color="#006CFF" />
                )}
              </TouchableOpacity>
            ))}
          </View>
        );

      case 'multiple':
        return (
          <View key={section.id} style={styles.section}>
            <Text style={styles.sectionTitle}>{section.title}</Text>
            {section.options?.map((option) => {
              const isSelected = (filters[section.id] || []).includes(option.id);
              return (
                <TouchableOpacity
                  key={option.id}
                  style={styles.option}
                  onPress={() => handleMultipleSelect(section.id, option.id)}
                >
                  <Text style={styles.optionText}>{option.label}</Text>
                  {isSelected && (
                    <Check size={20} color="#006CFF" />
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        );

      case 'toggle':
        return (
          <View key={section.id} style={styles.section}>
            <View style={styles.toggleOption}>
              <Text style={styles.sectionTitle}>{section.title}</Text>
              <Switch
                value={filters[section.id] || false}
                onValueChange={(value) => handleToggle(section.id, value)}
                trackColor={{ false: '#E5E7EB', true: '#006CFF' }}
                thumbColor="#FFFFFF"
              />
            </View>
          </View>
        );

      default:
        return null;
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <X size={24} color="#1F2937" />
          </TouchableOpacity>
          <Text style={styles.title}>{title}</Text>
          <TouchableOpacity onPress={handleClear} style={styles.clearButton}>
            <Text style={styles.clearButtonText}>Limpar</Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {sections.map(renderSection)}
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.applyButton} onPress={handleApply}>
            <Text style={styles.applyButtonText}>Aplicar Filtros</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  closeButton: {
    padding: 4,
  },
  title: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
  },
  clearButton: {
    padding: 4,
  },
  clearButtonText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#006CFF',
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  section: {
    marginTop: 24,
  },
  sectionTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 12,
  },
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
    marginBottom: 8,
  },
  optionText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#1F2937',
  },
  toggleOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 8,
  },
  footer: {
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  applyButton: {
    backgroundColor: '#006CFF',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  applyButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#FFFFFF',
  },
}); 