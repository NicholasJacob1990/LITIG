import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { ArrowLeft, Share , LucideIcon, Share2, FileDown } from 'lucide-react-native';
import { useNavigation } from '@react-navigation/native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

interface ActionButtonProps {
  icon: LucideIcon;
  onPress: () => void;
}

interface TopBarProps {
  title: string;
  subtitle?: string;
  showBack?: boolean;
  showShare?: boolean;
  rightActions?: ActionButtonProps[];
  onShare?: () => void;
  onExportPdf?: () => void;
}

export default function TopBar({ title, subtitle, showBack = false, showShare = false, rightActions, onShare, onExportPdf }: TopBarProps) {
  const navigation = useNavigation();
  const insets = useSafeAreaInsets();

  const handleBack = () => {
    navigation.goBack();
  };

  return (
    <LinearGradient
      colors={['#006CFF', '#4EA2FF']}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 0 }}
      style={styles.gradient}
    >
      <SafeAreaView>
        <View style={[styles.container, { paddingTop: insets.top + 12 }]}>
          <View style={styles.left}>
            {showBack && (
              <TouchableOpacity onPress={() => navigation.goBack()} style={styles.iconButton}>
                <ArrowLeft size={24} color="#FFFFFF" />
              </TouchableOpacity>
            )}
          </View>
          <View style={styles.center}>
            <Text style={styles.title} numberOfLines={1}>{title}</Text>
            {subtitle && <Text style={styles.subtitle} numberOfLines={1}>{subtitle}</Text>}
          </View>
          <View style={styles.right}>
            {onExportPdf && (
              <TouchableOpacity onPress={onExportPdf} style={styles.iconButton}>
                <FileDown size={22} color="#FFFFFF" />
              </TouchableOpacity>
            )}
            {onShare && (
              <TouchableOpacity onPress={onShare} style={styles.iconButton}>
                <Share2 size={22} color="#FFFFFF" />
              </TouchableOpacity>
            )}
          </View>
        </View>
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  gradient: {
    paddingTop: 32, // Account for status bar
  },
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    height: 60,
  },
  left: {
    width: 44,
    alignItems: 'flex-start',
  },
  center: {
    flex: 1,
    alignItems: 'center',
  },
  right: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    minWidth: 50,
  },
  title: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#FFFFFF',
    textAlign: 'center',
  },
  subtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'center',
    marginTop: 2,
  },
  iconButton: {
    padding: 8,
    borderRadius: 8,
  },
}); 
