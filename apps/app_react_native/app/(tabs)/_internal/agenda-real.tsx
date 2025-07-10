import React, { useCallback, useMemo, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, RefreshControl, ScrollView } from 'react-native';
import { Agenda, LocaleConfig } from 'react-native-calendars';
import { Calendar as CalendarIcon, Wifi, WifiOff, RefreshCw, Plus, Settings, Trash2 } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';

// Configuração de localidade para português
LocaleConfig.locales['pt-br'] = {
  monthNames: ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'],
  monthNamesShort: ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'],
  dayNames: ['Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado'],
  dayNamesShort: ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'],
  today: 'Hoje'
};
LocaleConfig.defaultLocale = 'pt-br';

export default function RealAgendaScreen() {
  const { user } = useAuth();
  
  // Estado local temporário
  const [events, setEvents] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * Formatar eventos para o componente Agenda
   */
  const formattedEvents = useMemo(() => {
    const items: { [key: string]: any[] } = {};

    events.forEach(event => {
      const dateStr = new Date(event.start_time).toISOString().split('T')[0];
      if (!items[dateStr]) {
        items[dateStr] = [];
      }
      items[dateStr].push({
        id: event.id,
        name: event.title,
        description: event.description,
        startTime: new Date(event.start_time).toLocaleTimeString('pt-BR', { 
          hour: '2-digit', 
          minute: '2-digit' 
        }),
        endTime: new Date(event.end_time).toLocaleTimeString('pt-BR', { 
          hour: '2-digit', 
          minute: '2-digit' 
        }),
        provider: event.provider,
        isVirtual: event.is_virtual,
        videoLink: event.video_link,
        status: event.status,
      });
    });

    return items;
  }, [events]);

  /**
   * Renderizar item da agenda
   */
  const renderItem = useCallback((item: any) => {
    const getStatusColor = (status: string) => {
      switch (status) {
        case 'confirmed': return '#10B981';
        case 'tentative': return '#F59E0B';
        case 'cancelled': return '#EF4444';
        default: return '#6B7280';
      }
    };

    return (
      <TouchableOpacity 
        style={[styles.eventItem, { borderLeftColor: getStatusColor(item.status) }]}
        onPress={() => handleEventPress(item)}
      >
        <View style={styles.itemHeader}>
          <Text style={styles.eventTitle}>{item.name}</Text>
          <View style={styles.badgeContainer}>
            {item.provider === 'google' && (
              <View style={[styles.providerBadge, { backgroundColor: '#4285F4' }]}>
                <Text style={styles.providerBadgeText}>Google</Text>
              </View>
            )}
            {item.isVirtual && (
              <View style={[styles.providerBadge, { backgroundColor: '#10B981' }]}>
                <Text style={styles.providerBadgeText}>Virtual</Text>
              </View>
            )}
          </View>
        </View>
        
        <Text style={styles.eventTime}>
          {item.startTime} - {item.endTime}
        </Text>
        
        {item.description && (
          <Text style={styles.eventDescription} numberOfLines={2}>
            {item.description}
          </Text>
        )}

        {item.status === 'cancelled' && (
          <Text style={styles.cancelledText}>Evento Cancelado</Text>
        )}
      </TouchableOpacity>
    );
  }, []);

  /**
   * Lidar com pressionar evento
   */
  const handleEventPress = (item: any) => {
    const actions = [];

    if (item.videoLink) {
      actions.push({
        text: 'Entrar na Videochamada',
        onPress: () => {
          // Aqui você pode abrir o link da videochamada
          Alert.alert('Link da Videochamada', item.videoLink);
        }
      });
    }

    actions.push(
      { text: 'Cancelar', style: 'cancel' as const }
    );

    Alert.alert(
      item.name,
      `${item.startTime} - ${item.endTime}\n\n${item.description || 'Sem descrição'}`,
      actions
    );
  };

  /**
   * Lidar com sincronização
   */
  const handleSync = useCallback(async () => {
    try {
      setIsLoading(true);
      // TODO: Implementar sincronização quando necessário
      Alert.alert('Funcionalidade em desenvolvimento', 'A integração com Google Calendar será implementada em breve.');
    } catch (error) {
      console.error('Erro na sincronização:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  /**
   * Lidar com refresh
   */
  const onRefresh = useCallback(async () => {
    if (isConnected) {
      // TODO: Implementar refresh quando necessário
    }
  }, [isConnected]);

  /**
   * Criar novo evento
   */
  const handleCreateEvent = useCallback(() => {
    Alert.alert('Funcionalidade em desenvolvimento', 'A criação de eventos será implementada em breve.');
  }, []);

  /**
   * Mostrar configurações
   */
  const handleSettings = useCallback(() => {
    const actions = [];

    if (isConnected) {
      actions.push({
        text: 'Desconectar Google Calendar',
        style: 'destructive' as const,
        onPress: () => {
          Alert.alert(
            'Desconectar',
            'Tem certeza que deseja desconectar do Google Calendar?',
            [
              { text: 'Cancelar', style: 'cancel' },
              { text: 'Desconectar', style: 'destructive', onPress: () => setIsConnected(false) }
            ]
          );
        }
      });
    }

    actions.push(
      { text: 'Cancelar', style: 'cancel' as const }
    );

    Alert.alert('Configurações da Agenda', '', actions);
  }, [isConnected]);

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <CalendarIcon size={24} color="#1F2937" />
          <Text style={styles.headerTitle}>Agenda Real</Text>
        </View>
        
        <View style={styles.headerRight}>
          {/* Status de Conexão */}
          <View style={styles.connectionStatus}>
            {isConnected ? (
              <Wifi size={16} color="#10B981" />
            ) : (
              <WifiOff size={16} color="#EF4444" />
            )}
            <Text style={[
              styles.connectionText,
              { color: isConnected ? '#10B981' : '#EF4444' }
            ]}>
              {isConnected ? 'Conectado' : 'Desconectado'}
            </Text>
          </View>

          {/* Botões de Ação */}
          <TouchableOpacity
            style={styles.actionButton}
            onPress={handleCreateEvent}
            disabled={!isConnected}
          >
            <Plus size={20} color={isConnected ? "#4285F4" : "#9CA3AF"} />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionButton}
            onPress={handleSettings}
          >
            <Settings size={20} color="#6B7280" />
          </TouchableOpacity>
        </View>
      </View>

      {/* Botão de Sincronização */}
      {!isConnected && (
        <TouchableOpacity
          style={styles.syncButton}
          onPress={handleSync}
          disabled={isLoading}
        >
          <RefreshCw 
            size={20} 
            color="white" 
            style={isLoading ? { opacity: 0.5 } : {}} 
          />
          <Text style={styles.syncButtonText}>
            {isLoading ? 'Conectando...' : 'Conectar ao Google Calendar'}
          </Text>
        </TouchableOpacity>
      )}

      {/* Mensagem de Erro */}
      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity onPress={() => setError(null)}>
            <Text style={styles.errorDismiss}>Dispensar</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Agenda */}
      <Agenda
        items={formattedEvents}
        loadItemsForMonth={() => {}}
        renderItem={renderItem}
        renderEmptyDate={() => (
          <View style={styles.emptyDate}>
            <Text style={styles.emptyDateText}>Nenhum evento</Text>
          </View>
        )}
        refreshControl={
          <RefreshControl
            refreshing={isLoading}
            onRefresh={onRefresh}
          />
        }
        theme={{
          selectedDayBackgroundColor: '#4285F4',
          todayTextColor: '#4285F4',
          dayTextColor: '#1F2937',
          textDisabledColor: '#9CA3AF',
          dotColor: '#4285F4',
          selectedDotColor: '#ffffff',
          arrowColor: '#4285F4',
          disabledArrowColor: '#d9e1e8',
          monthTextColor: '#1F2937',
          indicatorColor: '#4285F4',
          textDayFontFamily: 'System',
          textMonthFontFamily: 'System',
          textDayHeaderFontFamily: 'System',
          textDayFontWeight: '400',
          textMonthFontWeight: '600',
          textDayHeaderFontWeight: '600',
          textDayFontSize: 16,
          textMonthFontSize: 18,
          textDayHeaderFontSize: 14,
        }}
        style={styles.agenda}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#F9FAFB',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  connectionStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  connectionText: {
    fontSize: 12,
    fontWeight: '500',
  },
  actionButton: {
    padding: 8,
  },
  syncButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#4285F4',
    marginHorizontal: 16,
    marginVertical: 12,
    paddingVertical: 12,
    borderRadius: 8,
  },
  syncButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '500',
  },
  errorContainer: {
    backgroundColor: '#FEF2F2',
    borderColor: '#FECACA',
    borderWidth: 1,
    marginHorizontal: 16,
    marginBottom: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 8,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  errorText: {
    color: '#DC2626',
    fontSize: 14,
    flex: 1,
  },
  errorDismiss: {
    color: '#DC2626',
    fontSize: 14,
    fontWeight: '500',
  },
  agenda: {
    flex: 1,
  },
  eventItem: {
    backgroundColor: 'white',
    padding: 16,
    marginHorizontal: 16,
    marginVertical: 4,
    borderRadius: 8,
    borderLeftWidth: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 4,
  },
  eventTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    flex: 1,
    marginRight: 8,
  },
  badgeContainer: {
    flexDirection: 'row',
    gap: 4,
  },
  providerBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  providerBadgeText: {
    color: 'white',
    fontSize: 10,
    fontWeight: '500',
  },
  eventTime: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  eventDescription: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  cancelledText: {
    fontSize: 12,
    color: '#EF4444',
    fontWeight: '500',
    marginTop: 4,
  },
  emptyDate: {
    height: 60,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyDateText: {
    color: '#9CA3AF',
    fontSize: 14,
  },
}); 