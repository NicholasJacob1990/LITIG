import React, { useEffect, useMemo, useState, useCallback } from 'react';
import { View, Text, StyleSheet, Button, ActivityIndicator, TouchableOpacity, Alert, RefreshControl } from 'react-native';
import { Agenda, LocaleConfig } from 'react-native-calendars';
import { Calendar as CalendarIcon, Wifi, WifiOff, RefreshCw } from 'lucide-react-native';
import { useCalendar } from '@/lib/contexts/CalendarContext';
import { useAuth } from '@/lib/contexts/AuthContext';
import { 
  useGoogleAuth, 
  exchangeCodeForTokens,
  saveCalendarCredentials, 
} from '@/lib/services/calendar';
import * as WebBrowser from 'expo-web-browser';
import { AuthSessionResult } from 'expo-auth-session';

// Configuração de localidade para português
LocaleConfig.locales['pt-br'] = {
  monthNames: ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'],
  monthNamesShort: ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'],
  dayNames: ['Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado'],
  dayNamesShort: ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'],
  today: 'Hoje'
};
LocaleConfig.defaultLocale = 'pt-br';

WebBrowser.maybeCompleteAuthSession();

export default function AgendaScreen() {
  const { user } = useAuth();
  const { events, isLoading, refetchEvents, error: calendarError } = useCalendar();
  const [isSyncing, setIsSyncing] = useState(false);

  const handleSync = useCallback(async () => {
    Alert.alert(
      'Em Desenvolvimento',
      'A sincronização com o Google Calendar está sendo aprimorada e será reativada em breve.'
    );
  }, []);

  const onRefresh = useCallback(async () => {
    setIsSyncing(true);
    await refetchEvents();
    setIsSyncing(false);
  }, [refetchEvents]);

  const formattedEvents = useMemo(() => {
    const items: { [key: string]: any[] } = {};

    events.forEach(event => {
      const dateStr = new Date(event.start_time).toISOString().split('T')[0];
      if (!items[dateStr]) {
        items[dateStr] = [];
      }
      items[dateStr].push({
        name: event.title,
        description: event.description,
        startTime: new Date(event.start_time).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
        endTime: new Date(event.end_time).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
        provider: event.provider,
      });
    });
    return items;
  }, [events]);

  const renderItem = useCallback((item: any) => {
    return (
      <TouchableOpacity style={styles.eventItem}>
        <View style={styles.itemHeader}>
          <Text style={styles.eventTitle}>{item.name}</Text>
          {item.provider === 'google' && (
            <View style={styles.providerBadge}>
              <Text style={styles.providerBadgeText}>Google</Text>
            </View>
          )}
        </View>
        <Text style={styles.eventTime}>{item.startTime} - {item.endTime}</Text>
        {item.description && <Text style={styles.eventDescription}>{item.description}</Text>}
      </TouchableOpacity>
    );
  }, []);

  const renderEmptyDate = useCallback(() => {
    return (
      <View style={styles.emptyDate}>
        <Text style={styles.emptyDateText}>Nenhum evento para este dia.</Text>
      </View>
    );
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Agenda</Text>
        <TouchableOpacity 
          style={styles.syncButton}
          onPress={handleSync}
          disabled={isSyncing}
        >
          <RefreshCw size={20} color="#64748B" />
          <Text style={styles.syncButtonText}>
            {isSyncing ? 'Sincronizando...' : 'Sincronizar'}
          </Text>
        </TouchableOpacity>
      </View>

      {(isLoading || isSyncing) && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#0F172A" />
          <Text style={styles.loadingText}>
            {isSyncing ? 'Sincronizando eventos...' : 'Carregando agenda...'}
          </Text>
        </View>
      )}

      {calendarError && (
        <View style={styles.errorContainer}>
          <WifiOff size={24} color="#EF4444" />
          <Text style={styles.errorText}>
            Erro ao carregar eventos
          </Text>
          <TouchableOpacity style={styles.retryButton} onPress={handleSync}>
            <Text style={styles.retryButtonText}>Tentar novamente</Text>
          </TouchableOpacity>
        </View>
      )}

      {!isLoading && !isSyncing && !calendarError && (
        <Agenda
          items={formattedEvents}
          renderItem={renderItem}
          renderEmptyDate={renderEmptyDate}
          showClosingKnob={true}
          refreshControl={
            <RefreshControl
              refreshing={isSyncing}
              onRefresh={onRefresh}
              colors={['#0F172A']}
            />
          }
          theme={{
            agendaDayTextColor: '#0F172A',
            agendaDayNumColor: '#0F172A',
            agendaTodayColor: '#3B82F6',
            dotColor: '#3B82F6',
            selectedDayBackgroundColor: '#3B82F6',
            backgroundColor: '#F8FAFC',
            calendarBackground: '#FFFFFF',
            textSectionTitleColor: '#1E293B',
            selectedDayTextColor: '#FFFFFF',
            todayTextColor: '#3B82F6',
            dayTextColor: '#1E293B',
            textDisabledColor: '#94A3B8',
            monthTextColor: '#1E293B',
            indicatorColor: '#3B82F6',
            textDayFontWeight: '500',
            textMonthFontWeight: 'bold',
            textDayHeaderFontWeight: '500',
            textDayFontSize: 16,
            textMonthFontSize: 18,
            textDayHeaderFontSize: 14,
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
    paddingTop: 50,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingBottom: 15,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  syncButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#F1F5F9',
    borderRadius: 8,
  },
  syncButtonText: {
    fontSize: 14,
    color: '#64748B',
    marginLeft: 6,
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    color: '#64748B',
  },
  errorContainer: {
    alignItems: 'center',
    paddingVertical: 40,
    paddingHorizontal: 20,
  },
  errorText: {
    color: '#EF4444',
    textAlign: 'center',
    marginTop: 12,
    marginBottom: 16,
  },
  retryButton: {
    backgroundColor: '#EF4444',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 6,
  },
  retryButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  eventItem: {
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 15,
    marginRight: 10,
    marginTop: 17,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  providerBadge: {
    backgroundColor: '#E0E7FF',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
  },
  providerBadgeText: {
    color: '#3730A3',
    fontSize: 10,
    fontWeight: 'bold',
  },
  eventTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
    flex: 1,
  },
  eventTime: {
    fontSize: 14,
    color: '#64748B',
    marginTop: 4,
  },
  eventDescription: {
    fontSize: 14,
    color: '#475569',
    marginTop: 8,
  },
  emptyDate: {
    height: 15,
    flex: 1,
    paddingTop: 30,
    alignItems: 'center',
  },
  emptyDateText: {
    color: '#94A3B8',
    fontSize: 14,
  },
}); 