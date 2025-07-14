import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Award } from 'lucide-react-native';
import Animated, { useAnimatedProps, useSharedValue, withTiming } from 'react-native-reanimated';
import Svg, { Circle } from 'react-native-svg';

const AnimatedCircle = Animated.createAnimatedComponent(Circle);

interface ProfileStrengthProps {
  score: number; // 0-100
  grade: string;
  trend: 'Melhorando' | 'Estável' | 'Declinando';
}

const CIRCLE_LENGTH = 300; // 2 * Math.PI * 50
const R = CIRCLE_LENGTH / (2 * Math.PI);

const ProfileStrength: React.FC<ProfileStrengthProps> = ({ score, grade, trend }) => {
  const progress = useSharedValue(0);

  React.useEffect(() => {
    progress.value = withTiming(score / 100, { duration: 1000 });
  }, [score]);

  const animatedProps = useAnimatedProps(() => ({
    strokeDashoffset: CIRCLE_LENGTH * (1 - progress.value),
  }));

  const getTrendColor = () => {
    if (trend === 'Melhorando') return '#10B981';
    if (trend === 'Declinando') return '#EF4444';
    return '#6B7280';
  };
  
  const getScoreColor = () => {
    if (score >= 85) return '#10B981';
    if (score >= 70) return '#F59E0B';
    return '#EF4444';
  }

  return (
    <View style={styles.container}>
      <View style={styles.chartContainer}>
        <Svg width="120" height="120" viewBox="0 0 120 120">
          <Circle cx="60" cy="60" r={R} stroke="#E5E7EB" strokeWidth="10" />
          <AnimatedCircle
            cx="60"
            cy="60"
            r={R}
            stroke={getScoreColor()}
            strokeWidth="10"
            strokeDasharray={CIRCLE_LENGTH}
            animatedProps={animatedProps}
            strokeLinecap="round"
            transform="rotate(-90 60 60)"
          />
        </Svg>
        <View style={styles.scoreTextContainer}>
          <Text style={[styles.score, { color: getScoreColor() }]}>{score}</Text>
          <Text style={styles.scoreLabel}>de 100</Text>
        </View>
      </View>
      <Text style={styles.grade}>{grade}</Text>
      <View style={styles.trendContainer}>
        <Text style={[styles.trendText, { color: getTrendColor() }]}>{trend}</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#FFF',
    borderRadius: 20,
    margin: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 5,
  },
  chartContainer: {
    width: 120,
    height: 120,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scoreTextContainer: {
    position: 'absolute',
    alignItems: 'center',
  },
  score: {
    fontSize: 32,
    fontWeight: 'bold',
  },
  scoreLabel: {
    fontSize: 14,
    color: '#6B7280',
  },
  grade: {
    fontSize: 22,
    fontWeight: '600',
    marginTop: 16,
  },
  trendContainer: {
    marginTop: 8,
    paddingVertical: 4,
    paddingHorizontal: 12,
    backgroundColor: '#F3F4F6',
    borderRadius: 12,
  },
  trendText: {
    fontSize: 14,
    fontWeight: '500',
  },
});

export default ProfileStrength; 