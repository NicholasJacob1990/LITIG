import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { ChevronDown, ChevronUp, GraduationCap, Award, BookOpen, Briefcase, Calendar } from 'lucide-react-native';

interface LawyerCurriculumCardProps {
  curriculo: {
    anos_experiencia?: number;
    pos_graduacoes?: Array<{
      titulo: string;
      instituicao: string;
      ano: number;
    }>;
    num_publicacoes?: number;
    formacao?: string;
    certificacoes?: string[];
    experiencia_profissional?: string[];
    resumo_profissional?: string;
  };
  lawyerName: string;
}

const LawyerCurriculumCard: React.FC<LawyerCurriculumCardProps> = ({ curriculo, lawyerName }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  if (!curriculo || Object.keys(curriculo).length === 0) {
    return null;
  }

  const handleToggle = () => {
    setIsExpanded(!isExpanded);
  };

  return (
    <View style={styles.container}>
      <TouchableOpacity style={styles.header} onPress={handleToggle}>
        <View style={styles.headerContent}>
          <GraduationCap size={20} color="#3B82F6" />
          <Text style={styles.title}>Currículo Profissional</Text>
        </View>
        <View style={styles.headerRight}>
          {curriculo.anos_experiencia && (
            <Text style={styles.experienceText}>
              {curriculo.anos_experiencia} anos
            </Text>
          )}
          {isExpanded ? (
            <ChevronUp size={20} color="#6B7280" />
          ) : (
            <ChevronDown size={20} color="#6B7280" />
          )}
        </View>
      </TouchableOpacity>

      {isExpanded && (
        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {curriculo.resumo_profissional && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Resumo Profissional</Text>
              <Text style={styles.sectionContent}>{curriculo.resumo_profissional}</Text>
            </View>
          )}

          {curriculo.formacao && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <GraduationCap size={16} color="#3B82F6" />
                <Text style={styles.sectionTitle}>Formação</Text>
              </View>
              <Text style={styles.sectionContent}>{curriculo.formacao}</Text>
            </View>
          )}

          {curriculo.pos_graduacoes && curriculo.pos_graduacoes.length > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Award size={16} color="#10B981" />
                <Text style={styles.sectionTitle}>Pós-Graduações</Text>
              </View>
              {curriculo.pos_graduacoes.map((pos, index) => (
                <View key={index} style={styles.itemContainer}>
                  <View style={styles.itemHeader}>
                    <Text style={styles.itemTitle}>{pos.titulo}</Text>
                    <View style={styles.yearBadge}>
                      <Calendar size={12} color="#6B7280" />
                      <Text style={styles.yearText}>{pos.ano}</Text>
                    </View>
                  </View>
                  <Text style={styles.itemSubtitle}>{pos.instituicao}</Text>
                </View>
              ))}
            </View>
          )}

          {curriculo.experiencia_profissional && curriculo.experiencia_profissional.length > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Briefcase size={16} color="#F59E0B" />
                <Text style={styles.sectionTitle}>Experiência Profissional</Text>
              </View>
              {curriculo.experiencia_profissional.map((exp, index) => (
                <View key={index} style={styles.itemContainer}>
                  <Text style={styles.itemContent}>{exp}</Text>
                </View>
              ))}
            </View>
          )}

          {curriculo.certificacoes && curriculo.certificacoes.length > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Award size={16} color="#8B5CF6" />
                <Text style={styles.sectionTitle}>Certificações</Text>
              </View>
              {curriculo.certificacoes.map((cert, index) => (
                <View key={index} style={styles.certificationItem}>
                  <View style={styles.certificationDot} />
                  <Text style={styles.certificationText}>{cert}</Text>
                </View>
              ))}
            </View>
          )}

          {curriculo.num_publicacoes && curriculo.num_publicacoes > 0 && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <BookOpen size={16} color="#EF4444" />
                <Text style={styles.sectionTitle}>Publicações</Text>
              </View>
              <View style={styles.publicationContainer}>
                <Text style={styles.publicationCount}>
                  {curriculo.num_publicacoes} publicação{curriculo.num_publicacoes > 1 ? 'ões' : ''} acadêmica{curriculo.num_publicacoes > 1 ? 's' : ''}
                </Text>
                <Text style={styles.publicationNote}>
                  Artigos, livros e trabalhos científicos na área jurídica
                </Text>
              </View>
            </View>
          )}
        </ScrollView>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#F8FAFC',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginLeft: 8,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  experienceText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#3B82F6',
  },
  content: {
    padding: 16,
    maxHeight: 400,
  },
  section: {
    marginBottom: 20,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginLeft: 8,
  },
  sectionContent: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  itemContainer: {
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#3B82F6',
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  itemTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    flex: 1,
  },
  yearBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#E5E7EB',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    gap: 4,
  },
  yearText: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '500',
  },
  itemSubtitle: {
    fontSize: 13,
    color: '#6B7280',
    fontStyle: 'italic',
  },
  itemContent: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 18,
  },
  certificationItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  certificationDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#8B5CF6',
    marginRight: 12,
  },
  certificationText: {
    fontSize: 14,
    color: '#4B5563',
    flex: 1,
  },
  publicationContainer: {
    backgroundColor: '#FEF3C7',
    borderRadius: 8,
    padding: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#F59E0B',
  },
  publicationCount: {
    fontSize: 16,
    fontWeight: '600',
    color: '#92400E',
    marginBottom: 4,
  },
  publicationNote: {
    fontSize: 13,
    color: '#A16207',
    lineHeight: 16,
  },
});

export default LawyerCurriculumCard; 