import React from 'react';
import { View, Text, StyleSheet, SafeAreaView, FlatList, TouchableOpacity } from 'react-native';
import { Briefcase, Clock, Check, X } from 'lucide-react-native';

const mockOffers = [
  { id: '1', caseTitle: 'Disputa Contratual - Inadimplência', area: 'Cível', expires_at: '22h restantes' },
  { id: '2', caseTitle: 'Questão Trabalhista - Verbas Rescisórias', area: 'Trabalhista', expires_at: '1 dia restante' },
  { id: '3', caseTitle: 'Defesa em Processo Administrativo', area: 'Administrativo', expires_at: '2 dias restantes' },
];

const OfferCard = ({ offer }: { offer: (typeof mockOffers)[0] }) => (
  <View style={styles.card}>
    <View style={styles.cardHeader}>
      <Briefcase size={20} color="#1E40AF" />
      <Text style={styles.cardArea}>{offer.area}</Text>
    </View>
    <Text style={styles.cardTitle}>{offer.caseTitle}</Text>
    <View style={styles.cardFooter}>
      <View style={styles.expiresContainer}>
        <Clock size={14} color="#6B7280" />
        <Text style={styles.expiresText}>{offer.expires_at}</Text>
      </View>
      <View style={styles.actions}>
        <TouchableOpacity style={[styles.actionButton, styles.declineButton]}>
          <X size={16} color="#EF4444" />
        </TouchableOpacity>
        <TouchableOpacity style={[styles.actionButton, styles.acceptButton]}>
          <Check size={16} color="#10B981" />
        </TouchableOpacity>
      </View>
    </View>
  </View>
);

const OffersScreen = () => {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Ofertas de Casos</Text>
        <Text style={styles.subtitle}>Casos compatíveis com seu perfil. Responda antes que expirem.</Text>
      </View>
      <FlatList
        data={mockOffers}
        renderItem={({ item }) => <OfferCard offer={item} />}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.listContent}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F4F6',
  },
  header: {
    padding: 24,
    backgroundColor: '#1E3A8A',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  subtitle: {
    fontSize: 16,
    color: '#D1D5DB',
    marginTop: 4,
  },
  listContent: {
    padding: 16,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  cardArea: {
    marginLeft: 8,
    fontSize: 12,
    fontWeight: '600',
    color: '#1E40AF',
    textTransform: 'uppercase',
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 16,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  expiresContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  expiresText: {
    marginLeft: 4,
    fontSize: 14,
    color: '#6B7280',
  },
  actions: {
    flexDirection: 'row',
  },
  actionButton: {
    padding: 8,
    borderRadius: 20,
    marginLeft: 8,
  },
  declineButton: {
    backgroundColor: '#FEF2F2',
  },
  acceptButton: {
    backgroundColor: '#D1FAE5',
  },
});

export default OffersScreen; 