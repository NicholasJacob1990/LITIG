import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Switch, Alert } from 'react-native';
import { Bell, Shield, User, Globe, Moon, Smartphone, Mail, Lock, Trash2, LogOut, ChevronRight } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';

interface SettingItem {
  id: string;
  title: string;
  subtitle?: string;
  type: 'toggle' | 'navigation' | 'action';
  value?: boolean;
  onPress?: () => void;
  onToggle?: (value: boolean) => void;
  icon: React.ReactNode;
  destructive?: boolean;
}

const SettingSection = ({ title, items }: { title: string, items: SettingItem[] }) => (
  <View style={styles.section}>
    <Text style={styles.sectionTitle}>{title}</Text>
    <View style={styles.sectionContent}>
      {items.map((item, index) => (
        <TouchableOpacity
          key={item.id}
          style={[
            styles.settingItem,
            index === items.length - 1 && styles.settingItemLast
          ]}
          onPress={item.onPress}
          disabled={item.type === 'toggle'}
        >
          <View style={styles.settingLeft}>
            <View style={[styles.settingIcon, item.destructive && styles.destructiveIcon]}>
              {item.icon}
            </View>
            <View style={styles.settingContent}>
              <Text style={[styles.settingTitle, item.destructive && styles.destructiveText]}>
                {item.title}
              </Text>
              {item.subtitle && (
                <Text style={styles.settingSubtitle}>{item.subtitle}</Text>
              )}
            </View>
          </View>
          
          <View style={styles.settingRight}>
            {item.type === 'toggle' && (
              <Switch
                value={item.value}
                onValueChange={item.onToggle}
                trackColor={{ false: '#E5E7EB', true: '#006CFF' }}
                thumbColor={item.value ? '#FFFFFF' : '#F3F4F6'}
              />
            )}
            {item.type === 'navigation' && (
              <ChevronRight size={20} color="#9CA3AF" />
            )}
          </View>
        </TouchableOpacity>
      ))}
    </View>
  </View>
);

export default function SettingsScreen() {
  const { user, signOut } = useAuth();
  
  // Estados para as configurações
  const [pushNotifications, setPushNotifications] = useState(true);
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [caseUpdates, setCaseUpdates] = useState(true);
  const [marketingEmails, setMarketingEmails] = useState(false);
  const [biometricAuth, setBiometricAuth] = useState(false);
  const [darkMode, setDarkMode] = useState(false);

  const handleDeleteAccount = () => {
    Alert.alert(
      'Excluir Conta',
      'Esta ação é irreversível. Todos os seus dados serão permanentemente removidos.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Excluir',
          style: 'destructive',
          onPress: () => {
            Alert.alert('Funcionalidade', 'Exclusão de conta será implementada em breve.');
          }
        }
      ]
    );
  };

  const handleLogout = () => {
    Alert.alert(
      'Sair da Conta',
      'Tem certeza que deseja sair?',
      [
        { text: 'Cancelar', style: 'cancel' },
        { text: 'Sair', onPress: signOut }
      ]
    );
  };

  const handleExportData = () => {
    Alert.alert(
      'Exportar Dados',
      'Seus dados serão preparados e enviados por email em até 48 horas.',
      [{ text: 'OK' }]
    );
  };

  const handleChangePassword = () => {
    Alert.alert('Alterar Senha', 'Funcionalidade será implementada em breve.');
  };

  const handlePrivacySettings = () => {
    Alert.alert('Configurações de Privacidade', 'Funcionalidade será implementada em breve.');
  };

  const handleLanguageSettings = () => {
    Alert.alert('Idioma', 'Funcionalidade será implementada em breve.');
  };

  const notificationSettings: SettingItem[] = [
    {
      id: 'push',
      title: 'Notificações Push',
      subtitle: 'Receber notificações no dispositivo',
      type: 'toggle',
      value: pushNotifications,
      onToggle: setPushNotifications,
      icon: <Smartphone size={20} color="#006CFF" />
    },
    {
      id: 'email',
      title: 'Notificações por Email',
      subtitle: 'Receber atualizações por email',
      type: 'toggle',
      value: emailNotifications,
      onToggle: setEmailNotifications,
      icon: <Mail size={20} color="#006CFF" />
    },
    {
      id: 'cases',
      title: 'Atualizações de Casos',
      subtitle: 'Notificar sobre mudanças nos casos',
      type: 'toggle',
      value: caseUpdates,
      onToggle: setCaseUpdates,
      icon: <Bell size={20} color="#006CFF" />
    },
    {
      id: 'marketing',
      title: 'Emails Promocionais',
      subtitle: 'Receber ofertas e novidades',
      type: 'toggle',
      value: marketingEmails,
      onToggle: setMarketingEmails,
      icon: <Mail size={20} color="#006CFF" />
    }
  ];

  const privacySettings: SettingItem[] = [
    {
      id: 'biometric',
      title: 'Autenticação Biométrica',
      subtitle: 'Usar impressão digital ou Face ID',
      type: 'toggle',
      value: biometricAuth,
      onToggle: setBiometricAuth,
      icon: <Lock size={20} color="#10B981" />
    },
    {
      id: 'privacy',
      title: 'Configurações de Privacidade',
      subtitle: 'Controlar quem pode ver suas informações',
      type: 'navigation',
      onPress: handlePrivacySettings,
      icon: <Shield size={20} color="#10B981" />
    },
    {
      id: 'password',
      title: 'Alterar Senha',
      subtitle: 'Atualizar sua senha de acesso',
      type: 'navigation',
      onPress: handleChangePassword,
      icon: <Lock size={20} color="#10B981" />
    },
    {
      id: 'export',
      title: 'Exportar Meus Dados',
      subtitle: 'Baixar uma cópia dos seus dados',
      type: 'navigation',
      onPress: handleExportData,
      icon: <User size={20} color="#10B981" />
    }
  ];

  const appSettings: SettingItem[] = [
    {
      id: 'dark',
      title: 'Modo Escuro',
      subtitle: 'Usar tema escuro no aplicativo',
      type: 'toggle',
      value: darkMode,
      onToggle: setDarkMode,
      icon: <Moon size={20} color="#8B5CF6" />
    },
    {
      id: 'language',
      title: 'Idioma',
      subtitle: 'Português (Brasil)',
      type: 'navigation',
      onPress: handleLanguageSettings,
      icon: <Globe size={20} color="#8B5CF6" />
    }
  ];

  const accountSettings: SettingItem[] = [
    {
      id: 'logout',
      title: 'Sair da Conta',
      subtitle: 'Fazer logout do aplicativo',
      type: 'action',
      onPress: handleLogout,
      icon: <LogOut size={20} color="#EF4444" />,
      destructive: true
    },
    {
      id: 'delete',
      title: 'Excluir Conta',
      subtitle: 'Remover permanentemente sua conta',
      type: 'action',
      onPress: handleDeleteAccount,
      icon: <Trash2 size={20} color="#EF4444" />,
      destructive: true
    }
  ];

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Configurações</Text>
        {user && (
          <Text style={styles.subtitle}>
            {user.user_metadata?.full_name || user.email}
          </Text>
        )}
      </View>

      <SettingSection title="Notificações" items={notificationSettings} />
      <SettingSection title="Privacidade e Segurança" items={privacySettings} />
      <SettingSection title="Aplicativo" items={appSettings} />
      <SettingSection title="Conta" items={accountSettings} />

      <View style={styles.footer}>
        <Text style={styles.footerText}>LITGO v1.0.0</Text>
        <Text style={styles.footerText}>© 2025 JACOBS Advogados Associados</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    padding: 20,
    paddingTop: 60,
    paddingBottom: 32,
  },
  title: {
    fontSize: 32,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
  },
  section: {
    marginBottom: 32,
    paddingHorizontal: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontFamily: 'Inter-SemiBold',
    color: '#1F2937',
    marginBottom: 12,
  },
  sectionContent: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  settingItemLast: {
    borderBottomWidth: 0,
  },
  settingLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  settingIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F0F9FF',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  destructiveIcon: {
    backgroundColor: '#FEF2F2',
  },
  settingContent: {
    flex: 1,
  },
  settingTitle: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#1F2937',
    marginBottom: 2,
  },
  destructiveText: {
    color: '#EF4444',
  },
  settingSubtitle: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
  },
  settingRight: {
    marginLeft: 16,
  },
  footer: {
    padding: 20,
    paddingTop: 40,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#9CA3AF',
    marginBottom: 4,
  },
}); 