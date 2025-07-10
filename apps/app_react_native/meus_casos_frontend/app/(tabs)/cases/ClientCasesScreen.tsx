import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import MyCasesList from './MyCasesList';
import CaseDetail from './CaseDetail';
import NewCase from '../../NewCase';
import CaseDocuments from './CaseDocuments';
import CaseChat from './CaseChat';
import AISummary from './AISummary';
import DetailedAnalysis from './DetailedAnalysis';
import ScheduleConsult from './ScheduleConsult';

const Stack = createStackNavigator();

export default function ClientCasesScreen() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <Stack.Screen name="MyCasesList" component={MyCasesList} />
      <Stack.Screen name="CaseDetail" component={CaseDetail} />
      <Stack.Screen name="CaseDocuments" component={CaseDocuments} />
      <Stack.Screen name="CaseChat" component={CaseChat} />
      <Stack.Screen name="AISummary" component={AISummary} />
      <Stack.Screen name="DetailedAnalysis" component={DetailedAnalysis} />
      <Stack.Screen name="ScheduleConsult" component={ScheduleConsult} />
      <Stack.Screen name="NewCase" component={NewCase} />
    </Stack.Navigator>
  );
} 