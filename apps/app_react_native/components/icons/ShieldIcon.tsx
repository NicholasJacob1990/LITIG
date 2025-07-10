import React from 'react';
import Svg, { Path } from 'react-native-svg';

interface ShieldIconProps {
  size?: number;
  color?: string;
}

export default function ShieldIcon({ size = 40, color = '#FFFFFF' }: ShieldIconProps) {
  return (
    <Svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke={color}
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {/* Shield */}
      <Path d="M12 2L4 5v6c0 5.55 3.84 10.74 8 11 4.16-.26 8-5.45 8-11V5l-8-3z" />
      {/* Letter J */}
      <Path d="M10 16v-6h2.5M12.5 16H10" />
    </Svg>
  );
} 