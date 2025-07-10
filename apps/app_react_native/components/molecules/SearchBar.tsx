import React, { useState, useRef } from 'react';
import { 
  View, 
  TextInput, 
  TouchableOpacity, 
  StyleSheet, 
  Animated,
  Keyboard
} from 'react-native';
import { Search, X, Filter } from 'lucide-react-native';

interface SearchBarProps {
  placeholder?: string;
  value?: string;
  onChangeText?: (text: string) => void;
  onSearch?: (text: string) => void;
  onClear?: () => void;
  onFilterPress?: () => void;
  showFilter?: boolean;
  autoFocus?: boolean;
  variant?: 'default' | 'rounded' | 'minimal';
}

export default function SearchBar({
  placeholder = 'Buscar...',
  value = '',
  onChangeText,
  onSearch,
  onClear,
  onFilterPress,
  showFilter = false,
  autoFocus = false,
  variant = 'default'
}: SearchBarProps) {
  const [isFocused, setIsFocused] = useState(false);
  const [internalValue, setInternalValue] = useState(value);
  const focusAnimation = useRef(new Animated.Value(0)).current;
  const inputRef = useRef<TextInput>(null);

  const handleFocus = () => {
    setIsFocused(true);
    Animated.timing(focusAnimation, {
      toValue: 1,
      duration: 200,
      useNativeDriver: false,
    }).start();
  };

  const handleBlur = () => {
    setIsFocused(false);
    Animated.timing(focusAnimation, {
      toValue: 0,
      duration: 200,
      useNativeDriver: false,
    }).start();
  };

  const handleChangeText = (text: string) => {
    setInternalValue(text);
    onChangeText?.(text);
  };

  const handleSubmit = () => {
    onSearch?.(internalValue);
    Keyboard.dismiss();
  };

  const handleClear = () => {
    setInternalValue('');
    onChangeText?.('');
    onClear?.();
    inputRef.current?.focus();
  };

  const borderColor = focusAnimation.interpolate({
    inputRange: [0, 1],
    outputRange: ['#E5E7EB', '#006CFF'],
  });

  const getContainerStyle = () => {
    const baseStyle = [styles.container];
    
    switch (variant) {
      case 'rounded':
        baseStyle.push(styles.containerRounded);
        break;
      case 'minimal':
        baseStyle.push(styles.containerMinimal);
        break;
      default:
        baseStyle.push(styles.containerDefault);
    }
    
    return baseStyle;
  };

  return (
    <Animated.View style={[getContainerStyle(), { borderColor }]}>
      <View style={styles.searchIconContainer}>
        <Search size={20} color={isFocused ? '#006CFF' : '#9CA3AF'} />
      </View>
      
      <TextInput
        ref={inputRef}
        style={styles.input}
        placeholder={placeholder}
        placeholderTextColor="#9CA3AF"
        value={internalValue}
        onChangeText={handleChangeText}
        onFocus={handleFocus}
        onBlur={handleBlur}
        onSubmitEditing={handleSubmit}
        returnKeyType="search"
        autoFocus={autoFocus}
        clearButtonMode="never"
      />
      
      {internalValue.length > 0 && (
        <TouchableOpacity 
          style={styles.clearButton}
          onPress={handleClear}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <X size={18} color="#9CA3AF" />
        </TouchableOpacity>
      )}
      
      {showFilter && (
        <TouchableOpacity 
          style={styles.filterButton}
          onPress={onFilterPress}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <Filter size={20} color="#006CFF" />
        </TouchableOpacity>
      )}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  containerDefault: {
    borderRadius: 12,
  },
  containerRounded: {
    borderRadius: 25,
  },
  containerMinimal: {
    borderRadius: 8,
    backgroundColor: '#F9FAFB',
    borderColor: 'transparent',
  },
  searchIconContainer: {
    marginRight: 12,
  },
  input: {
    flex: 1,
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    paddingVertical: 0,
  },
  clearButton: {
    marginLeft: 8,
    padding: 4,
  },
  filterButton: {
    marginLeft: 12,
    padding: 4,
  },
}); 