import React from 'react';
import { Text, View, StyleSheet } from 'react-native';

type Intent = 'primary' | 'warning' | 'danger' | 'success' | 'info';

export default function Badge({
  children,
  intent = 'info',
  outline = false,
}: {
  children: React.ReactNode;
  intent?: Intent;
  outline?: boolean;
}) {
  return (
    <View
      style={[
        styles.base,
        outline ? styles.outline(intent) : styles.filled(intent),
      ]}
    >
      <Text
        style={[
          styles.text,
          outline ? { color: styles.filled(intent).backgroundColor } : null,
        ]}
      >
        {children}
      </Text>
    </View>
  );
}

const intentColors: Record<Intent, string> = {
  primary: '#667EEA',
  warning: '#F59E0B',
  danger: '#EF4444',
  success: '#10B981',
  info: '#3B82F6',
};

const styles = StyleSheet.create({
  base: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
  },
  text: {
    fontSize: 11,
    fontWeight: '700',
    color: '#fff',
  },
  filled: (intent: Intent) => ({
    backgroundColor: intentColors[intent],
  }),
  outline: (intent: Intent) => ({
    borderWidth: 1,
    borderColor: intentColors[intent],
    backgroundColor: 'transparent',
  }),
});