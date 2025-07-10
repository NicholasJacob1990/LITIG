import React, { useState, useEffect, useCallback } from 'react';
import { View, Text } from 'react-native';
import ImprovedCaseList from '@/components/organisms/ImprovedCaseList';
import { useAuth } from '@/lib/contexts/AuthContext';
import { getUserCases, getCaseStats, CaseData } from '@/lib/services/cases';

export default function ClientCasesScreen() {
  const { user } = useAuth();
  const [cases, setCases] = useState<CaseData[]>([]);
  const [caseStats, setCaseStats] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    setError(null);
    try {
      const [casesData, statsData] = await Promise.all([
        getUserCases(user.id),
        getCaseStats(user.id)
      ]);
      setCases(casesData);
      setCaseStats(statsData);
    } catch (e) {
      setError('Falha ao carregar seus casos.');
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  return (
    <ImprovedCaseList
      cases={cases}
      caseStats={caseStats}
      isLoading={isLoading}
      error={error}
      onRefresh={loadData}
    />
  );
} 