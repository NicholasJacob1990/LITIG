import React from 'react';
import { View } from 'react-native';
import { Svg, G, Line, Polygon, Text as SvgText } from 'react-native-svg';

interface RadarChartProps {
  data: {
    A: number; S: number; T: number; G: number;
    Q: number; U: number; R: number; C: number;
  };
  size: number;
}

const RadarChart: React.FC<RadarChartProps> = ({ data, size }) => {
  const labels = ['A', 'S', 'T', 'G', 'Q', 'U', 'R', 'C'];
  const numAxes = labels.length;
  const angleSlice = (Math.PI * 2) / numAxes;
  const radius = size / 2.5;
  const center = size / 2;

  const getPoint = (value: number, index: number) => {
    const angle = angleSlice * index - Math.PI / 2;
    const x = center + radius * value * Math.cos(angle);
    const y = center + radius * value * Math.sin(angle);
    return { x, y };
  };

  const points = labels.map((label, i) => getPoint(data[label as keyof typeof data] * 10, i));

  return (
    <View style={{ alignItems: 'center', justifyContent: 'center' }}>
      <Svg height={size} width={size}>
        <G>
          {/* Web */}
          {[...Array(5)].map((_, i) => (
            <Polygon
              key={`web-${i}`}
              points={[...Array(numAxes)].map((_, j) => {
                const p = getPoint((i + 1) / 5, j);
                return `${p.x},${p.y}`;
              }).join(' ')}
              fill="none"
              stroke="#D1D5DB"
              strokeWidth="0.5"
            />
          ))}

          {/* Axes */}
          {[...Array(numAxes)].map((_, i) => {
            const p = getPoint(1, i);
            return <Line key={`axis-${i}`} x1={center} y1={center} x2={p.x} y2={p.y} stroke="#D1D5DB" strokeWidth="0.5" />;
          })}

          {/* Data Shape */}
          <Polygon
            points={points.map(p => `${p.x},${p.y}`).join(' ')}
            fill="#3B82F6"
            fillOpacity="0.4"
            stroke="#1D4ED8"
            strokeWidth="1"
          />

          {/* Labels */}
          {labels.map((label, i) => {
            const p = getPoint(1.2, i);
            return (
              <SvgText
                key={`label-${i}`}
                x={p.x}
                y={p.y}
                fontSize="12"
                fill="#374151"
                fontWeight="bold"
                textAnchor="middle"
                alignmentBaseline="middle"
              >
                {label}
              </SvgText>
            );
          })}
        </G>
      </Svg>
    </View>
  );
};

export default RadarChart; 