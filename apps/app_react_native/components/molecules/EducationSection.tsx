import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { BookOpen, Briefcase } from 'lucide-react-native';

interface EducationItem {
  tipo: string;
  curso: string;
  instituicao: string;
}

interface ExperienceItem {
  cargo: string;
  empresa: string;
  periodo: string;
  descricao: string;
}

interface EducationSectionProps {
  education?: EducationItem[];
  experience?: ExperienceItem[];
}

const EducationSection: React.FC<EducationSectionProps> = ({ education, experience }) => {
  const hasEducation = education && education.length > 0;
  const hasExperience = experience && experience.length > 0;

  if (!hasEducation && !hasExperience) {
    return null;
  }

  return (
    <View style={styles.section}>
      {hasEducation && (
        <>
          <Text style={styles.sectionTitle}>Formação Acadêmica</Text>
          <View style={styles.listContainer}>
            {education.map((edu, index) => (
              <View key={`edu-${index}`} style={styles.item}>
                <BookOpen size={20} color="#3B82F6" style={styles.icon} />
                <View style={styles.itemContent}>
                  <Text style={styles.itemTitle}>{edu.curso}</Text>
                  <Text style={styles.itemSubtitle}>{edu.instituicao} - {edu.tipo}</Text>
                </View>
              </View>
            ))}
          </View>
        </>
      )}
      
      {hasExperience && (
        <>
          <Text style={[styles.sectionTitle, hasEducation && { marginTop: 24 }]}>Experiência Profissional</Text>
          <View style={styles.listContainer}>
            {experience.map((exp, index) => (
              <View key={`exp-${index}`} style={styles.item}>
                <Briefcase size={20} color="#10B981" style={styles.icon} />
                <View style={styles.itemContent}>
                  <Text style={styles.itemTitle}>{exp.cargo} em {exp.empresa}</Text>
                  <Text style={styles.itemSubtitle}>{exp.periodo}</Text>
                </View>
              </View>
            ))}
          </View>
        </>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  section: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    marginBottom: 16,
  },
  sectionTitle: {
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 16,
  },
  listContainer: {
    gap: 16,
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  icon: {
    marginRight: 16,
  },
  itemContent: {
    flex: 1,
  },
  itemTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#374151',
  },
  itemSubtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
});

export default EducationSection; 