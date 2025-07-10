import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { Link } from 'expo-router';
import { ChevronRight, LifeBuoy } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function SettingsScreen() {
  const insets = useSafeAreaInsets();

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingTop: insets.top + 20, paddingBottom: insets.bottom }}>
      <Text style={styles.header}>Configurações</Text>
      
      <View style={styles.menuSection}>
        <Text style={styles.sectionTitle}>Ajuda</Text>
        <Link href="/support" asChild>
          <TouchableOpacity style={styles.menuItem}>
            <View style={styles.menuItemContent}>
              <LifeBuoy size={22} color="#4B5563" />
              <Text style={styles.menuItemText}>Central de Suporte</Text>
            </View>
            <ChevronRight size={20} color="#9CA3AF" />
          </TouchableOpacity>
        </Link>
      </View>

    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F4F6',
  },
  header: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#111827',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  menuSection: {
    backgroundColor: 'white',
    borderRadius: 12,
    marginHorizontal: 20,
    paddingVertical: 10,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6B7280',
    paddingHorizontal: 15,
    paddingTop: 5,
    paddingBottom: 10,
    textTransform: 'uppercase',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 15,
    paddingHorizontal: 15,
    backgroundColor: 'white',
  },
  menuItemContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  menuItemText: {
    fontSize: 16,
    color: '#1F2937',
    marginLeft: 15,
  },
}); 