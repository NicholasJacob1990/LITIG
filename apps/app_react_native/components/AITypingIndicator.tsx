import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';

export default function AITypingIndicator() {
  const dot1Opacity = useRef(new Animated.Value(0.4)).current;
  const dot2Opacity = useRef(new Animated.Value(0.4)).current;
  const dot3Opacity = useRef(new Animated.Value(0.4)).current;

  useEffect(() => {
    const animateDots = () => {
      const animationSequence = Animated.sequence([
        Animated.timing(dot1Opacity, { toValue: 1, duration: 400, useNativeDriver: true }),
        Animated.timing(dot1Opacity, { toValue: 0.4, duration: 400, useNativeDriver: true }),
        Animated.timing(dot2Opacity, { toValue: 1, duration: 400, useNativeDriver: true }),
        Animated.timing(dot2Opacity, { toValue: 0.4, duration: 400, useNativeDriver: true }),
        Animated.timing(dot3Opacity, { toValue: 1, duration: 400, useNativeDriver: true }),
        Animated.timing(dot3Opacity, { toValue: 0.4, duration: 400, useNativeDriver: true }),
      ]);

      Animated.loop(animationSequence).start();
    };

    animateDots();
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.text}>LEX-9000 está analisando</Text>
      <View style={styles.dotsContainer}>
        <Animated.View style={[styles.dot, { opacity: dot1Opacity }]} />
        <Animated.View style={[styles.dot, { opacity: dot2Opacity }]} />
        <Animated.View style={[styles.dot, { opacity: dot3Opacity }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  text: {
    fontSize: 14,
    color: '#6B7280',
    marginRight: 8,
  },
  dotsContainer: {
    flexDirection: 'row',
    gap: 4,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#9CA3AF',
  },
});