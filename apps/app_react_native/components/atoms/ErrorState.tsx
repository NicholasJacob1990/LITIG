import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { AlertTriangle, RefreshCw, Wifi, WifiOff } from 'lucide-react-native';

interface ErrorStateProps {
  title?: string;
  description?: string;
  type?: 'generic' | 'network' | 'server' | 'notFound';
  onRetry?: () => void;
  retryText?: string;
  size?: 'small' | 'medium' | 'large';
}

export default function ErrorState({
  title,
  description,
  type = 'generic',
  onRetry,
  retryText = 'Tentar novamente',
  size = 'medium'
}: ErrorStateProps) {
  const getErrorConfig = () => {
    switch (type) {
      case 'network':
        return {
          icon: WifiOff,
          defaultTitle: 'Sem conexão',
          defaultDescription: 'Verifique sua conexão com a internet e tente novamente.'
        };
      case 'server':
        return {
          icon: AlertTriangle,
          defaultTitle: 'Erro no servidor',
          defaultDescription: 'Ocorreu um erro em nossos servidores. Tente novamente em alguns instantes.'
        };
      case 'notFound':
        return {
          icon: AlertTriangle,
          defaultTitle: 'Não encontrado',
          defaultDescription: 'O conteúdo que você está procurando não foi encontrado.'
        };
      default:
        return {
          icon: AlertTriangle,
          defaultTitle: 'Algo deu errado',
          defaultDescription: 'Ocorreu um erro inesperado. Tente novamente.'
        };
    }
  };

  const config = getErrorConfig();
  const Icon = config.icon;
  
  const iconSize = {
    small: 32,
    medium: 48,
    large: 64
  }[size];

  return (
    <View style={[styles.container, styles[size]]}>
      <View style={styles.iconContainer}>
        <Icon size={iconSize} color="#EF4444" />
      </View>
      
      <Text style={[styles.title, styles[`title${size.charAt(0).toUpperCase() + size.slice(1)}`]]}>
        {title || config.defaultTitle}
      </Text>
      
      <Text style={[styles.description, styles[`description${size.charAt(0).toUpperCase() + size.slice(1)}`]]}>
        {description || config.defaultDescription}
      </Text>
      
      {onRetry && (
        <TouchableOpacity style={styles.retryButton} onPress={onRetry}>
          <RefreshCw size={16} color="#FFFFFF" />
          <Text style={styles.retryButtonText}>{retryText}</Text>
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
    backgroundColor: '#FEF2F2',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
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
  retryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EF4444',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    gap: 8,
  },
  retryButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#FFFFFF',
  },
}); 