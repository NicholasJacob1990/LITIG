import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, Text, Animated } from 'react-native';
import { Plus, Calendar, FileText, CheckSquare } from 'lucide-react-native';

interface QuickActionFABProps {
  onNewConsultation: () => void;
  onNewProcessEvent: () => void;
  onNewTask: () => void;
}

export default function QuickActionFAB({ onNewConsultation, onNewProcessEvent, onNewTask }: QuickActionFABProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [animation] = useState(new Animated.Value(0));

  const toggleExpansion = () => {
    const toValue = isExpanded ? 0 : 1;
    
    Animated.spring(animation, {
      toValue,
      useNativeDriver: true,
      tension: 100,
      friction: 8,
    }).start();
    
    setIsExpanded(!isExpanded);
  };

  const handleAction = (action: () => void) => {
    action();
    toggleExpansion();
  };

  const actionButtonStyle = {
    transform: [
      {
        scale: animation.interpolate({
          inputRange: [0, 1],
          outputRange: [0, 1],
        }),
      },
      {
        translateY: animation.interpolate({
          inputRange: [0, 1],
          outputRange: [0, -10],
        }),
      },
    ],
    opacity: animation,
  };

  const mainButtonRotation = {
    transform: [
      {
        rotate: animation.interpolate({
          inputRange: [0, 1],
          outputRange: ['0deg', '45deg'],
        }),
      },
    ],
  };

  return (
    <View style={styles.container}>
      {/* Overlay para fechar quando expandido */}
      {isExpanded && (
        <TouchableOpacity 
          style={styles.overlay} 
          onPress={toggleExpansion}
          activeOpacity={1}
        />
      )}

      {/* Botões de ação */}
      <Animated.View style={[styles.actionButton, actionButtonStyle, { bottom: 140 }]}>
        <TouchableOpacity 
          style={styles.actionButtonInner}
          onPress={() => handleAction(onNewConsultation)}
        >
          <Calendar size={20} color="white" />
        </TouchableOpacity>
        <Text style={styles.actionLabel}>Nova Consulta</Text>
      </Animated.View>

      <Animated.View style={[styles.actionButton, actionButtonStyle, { bottom: 100 }]}>
        <TouchableOpacity 
          style={styles.actionButtonInner}
          onPress={() => handleAction(onNewProcessEvent)}
        >
          <FileText size={20} color="white" />
        </TouchableOpacity>
        <Text style={styles.actionLabel}>Novo Evento</Text>
      </Animated.View>

      <Animated.View style={[styles.actionButton, actionButtonStyle, { bottom: 60 }]}>
        <TouchableOpacity 
          style={styles.actionButtonInner}
          onPress={() => handleAction(onNewTask)}
        >
          <CheckSquare size={20} color="white" />
        </TouchableOpacity>
        <Text style={styles.actionLabel}>Nova Tarefa</Text>
      </Animated.View>

      {/* Botão principal */}
      <TouchableOpacity style={styles.mainButton} onPress={toggleExpansion}>
        <Animated.View style={mainButtonRotation}>
          <Plus size={28} color="white" />
        </Animated.View>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 30,
    right: 30,
    alignItems: 'center',
  },
  overlay: {
    position: 'absolute',
    top: -1000,
    left: -1000,
    right: -1000,
    bottom: -1000,
    backgroundColor: 'transparent',
  },
  mainButton: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#0F172A',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5,
  },
  actionButton: {
    position: 'absolute',
    right: 0,
    flexDirection: 'row',
    alignItems: 'center',
  },
  actionButtonInner: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#1E293B',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 3,
    elevation: 3,
  },
  actionLabel: {
    marginRight: 12,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    color: 'white',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
    fontSize: 12,
    fontWeight: '500',
  },
}); 