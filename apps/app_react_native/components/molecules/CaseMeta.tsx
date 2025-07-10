import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Calendar, MessageSquare } from 'lucide-react-native';
import Avatar from '../atoms/Avatar';

export default function CaseMeta({
  advogado,
  dataInicio,
  mensagens,
}: {
  advogado?: { nome: string; avatar: string };
  dataInicio: string;
  mensagens?: number;
}) {
  return (
    <View style={styles.wrapper}>
      {advogado && advogado.nome && (
        <View style={styles.row}>
          <Avatar src={advogado.avatar} name={advogado.nome} size="small" />
          <Text style={styles.metaText}>{advogado.nome}</Text>
          {mensagens ? (
            <View style={styles.unreadContainer}>
              <MessageSquare size={12} color="#1E40AF" />
              <Text style={styles.unreadText}>{mensagens}</Text>
            </View>
          ) : null}
        </View>
      )}
      <View style={styles.row}>
        <Calendar size={14} color="#64748B" />
        <Text style={styles.metaText}>Início: {dataInicio}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: { 
    gap: 8,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#E5E7EB',
    paddingVertical: 12,
  },
  row: { 
    flexDirection: 'row', 
    alignItems: 'center',
    gap: 6,
  },
  metaText: { 
    fontFamily: 'Inter-Medium',
    fontSize: 13, 
    color: '#4B5563', 
  },
  unreadContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#DBEAFE',
    borderRadius: 12,
    paddingHorizontal: 6,
    paddingVertical: 2,
    marginLeft: 'auto',
    gap: 4,
  },
  unreadText: { 
    fontFamily: 'Inter-SemiBold',
    color: '#1E40AF', 
    fontSize: 12,
  },
});