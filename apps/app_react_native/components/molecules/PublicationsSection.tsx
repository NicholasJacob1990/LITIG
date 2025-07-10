import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Award, BookText } from 'lucide-react-native';

interface PublicationsSectionProps {
  publications?: string[];
  certifications?: string[];
}

const PublicationsSection: React.FC<PublicationsSectionProps> = ({ publications, certifications }) => {
  const hasPublications = publications && publications.length > 0;
  const hasCertifications = certifications && certifications.length > 0;

  if (!hasPublications && !hasCertifications) {
    return null;
  }

  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>Publicações e Certificações</Text>
      <View style={styles.listContainer}>
        {hasPublications && publications.map((pub, index) => (
          <View key={`pub-${index}`} style={styles.item}>
            <BookText size={20} color="#6D28D9" style={styles.icon} />
            <View style={styles.itemContent}>
              <Text style={styles.itemTitle}>Publicação</Text>
              <Text style={styles.itemSubtitle}>{pub}</Text>
            </View>
          </View>
        ))}
        {hasCertifications && certifications.map((cert, index) => (
          <View key={`cert-${index}`} style={styles.item}>
            <Award size={20} color="#F59E0B" style={styles.icon} />
            <View style={styles.itemContent}>
              <Text style={styles.itemTitle}>Certificação</Text>
              <Text style={styles.itemSubtitle}>{cert}</Text>
            </View>
          </View>
        ))}
      </View>
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

export default PublicationsSection; 