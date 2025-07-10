import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import ShieldIcon from '../icons/ShieldIcon';

interface Props {
  color?: string;
}

export default function LogoJacobCompact({ color = '#FFFFFF' }: Props) {
  return (
    <View style={styles.row}>
      <ShieldIcon size={24} color={color} />
      <Text style={[styles.text, { color }]}>JACOB</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  text: {
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    fontWeight: '700',
    letterSpacing: 1,
  },
}); 