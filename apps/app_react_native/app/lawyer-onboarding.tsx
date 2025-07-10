import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput, Alert } from 'react-native';
import { useState } from 'react';
import { LinearGradient } from 'expo-linear-gradient';
import { User, Scale, FileText, Shield, CircleCheck as CheckCircle, ArrowRight, Camera, MapPin, Award, Briefcase, Mail, Phone, Calendar, Building2, DollarSign } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';

export default function LawyerOnboardingScreen() {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    // Personal Data
    fullName: '',
    cpf: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
    // Professional Data
    oabNumber: '',
    oabState: '',
    specialties: [] as string[],
    experience: '',
    university: '',
    graduationYear: '',
    // Address
    zipCode: '',
    address: '',
    city: '',
    state: '',
    // Professional Info
    currentFirm: '',
    hourlyRate: '',
    consultationFee: '',
    bio: '',
    // Ethics & Compliance
    hasEthicsViolations: false,
    hasCriminalRecord: false,
    isPEP: false,
    hasConflicts: false,
    // Terms
    acceptedTerms: false,
    acceptedContract: false,
    acceptedEthics: false,
  });

  const totalSteps = 6;

  const specialtyOptions = [
    'Direito Trabalhista',
    'Direito Civil',
    'Direito Empresarial',
    'Direito do Consumidor',
    'Direito Previdenciário',
    'Direito Criminal',
    'Direito de Família',
    'Direito Tributário',
    'Direito Imobiliário',
    'Direito Digital',
  ];

  const stateOptions = [
    'SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'GO', 'PE', 'CE',
    'PA', 'MA', 'PB', 'ES', 'PI', 'AL', 'RN', 'MT', 'MS', 'DF',
    'SE', 'RO', 'AC', 'AM', 'RR', 'AP', 'TO'
  ];

  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      handleSubmit();
    }
  };

  const handleSubmit = () => {
    Alert.alert(
      'Solicitação Enviada',
      'Sua solicitação de cadastro foi enviada para análise. Você receberá um e-mail com o resultado em até 48 horas.',
      [
        { text: 'Entendi', onPress: () => router.replace('/(tabs)') }
      ]
    );
  };

  const toggleSpecialty = (specialty: string) => {
    const newSpecialties = formData.specialties.includes(specialty)
      ? formData.specialties.filter(s => s !== specialty)
      : [...formData.specialties, specialty];
    setFormData({ ...formData, specialties: newSpecialties });
  };

  const renderStepContent = () => {
    switch (step) {
      case 1:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Dados Pessoais</Text>
            <Text style={styles.stepDescription}>
              Informe seus dados pessoais para iniciar o cadastro
            </Text>

            <View style={styles.inputContainer}>
              <User size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Nome Completo"
                value={formData.fullName}
                onChangeText={(text) => setFormData({ ...formData, fullName: text })}
              />
            </View>

            <View style={styles.inputContainer}>
              <FileText size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="CPF"
                value={formData.cpf}
                onChangeText={(text) => setFormData({ ...formData, cpf: text })}
                keyboardType="numeric"
              />
            </View>

            <View style={styles.inputContainer}>
              <Mail size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="E-mail"
                value={formData.email}
                onChangeText={(text) => setFormData({ ...formData, email: text })}
                keyboardType="email-address"
                autoCapitalize="none"
              />
            </View>

            <View style={styles.inputContainer}>
              <Phone size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Telefone"
                value={formData.phone}
                onChangeText={(text) => setFormData({ ...formData, phone: text })}
                keyboardType="phone-pad"
              />
            </View>

            <View style={styles.inputContainer}>
              <Shield size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Senha"
                value={formData.password}
                onChangeText={(text) => setFormData({ ...formData, password: text })}
                secureTextEntry
              />
            </View>

            <View style={styles.inputContainer}>
              <Shield size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Confirmar Senha"
                value={formData.confirmPassword}
                onChangeText={(text) => setFormData({ ...formData, confirmPassword: text })}
                secureTextEntry
              />
            </View>
          </View>
        );

      case 2:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Dados Profissionais</Text>
            <Text style={styles.stepDescription}>
              Informe seus dados de registro na OAB
            </Text>

            <View style={styles.inputContainer}>
              <Scale size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Número da OAB"
                value={formData.oabNumber}
                onChangeText={(text) => setFormData({ ...formData, oabNumber: text })}
                keyboardType="numeric"
              />
            </View>

            <View style={styles.inputContainer}>
              <MapPin size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Seccional OAB (ex: SP)"
                value={formData.oabState}
                onChangeText={(text) => setFormData({ ...formData, oabState: text.toUpperCase() })}
                maxLength={2}
              />
            </View>

            <View style={styles.inputContainer}>
              <Award size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Anos de Experiência"
                value={formData.experience}
                onChangeText={(text) => setFormData({ ...formData, experience: text })}
                keyboardType="numeric"
              />
            </View>

            <View style={styles.inputContainer}>
              <Briefcase size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Universidade de Formação"
                value={formData.university}
                onChangeText={(text) => setFormData({ ...formData, university: text })}
              />
            </View>

            <View style={styles.inputContainer}>
              <Calendar size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Ano de Formatura"
                value={formData.graduationYear}
                onChangeText={(text) => setFormData({ ...formData, graduationYear: text })}
                keyboardType="numeric"
              />
            </View>

            <View style={styles.inputContainer}>
              <Building2 size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Escritório Atual (opcional)"
                value={formData.currentFirm}
                onChangeText={(text) => setFormData({ ...formData, currentFirm: text })}
              />
            </View>
          </View>
        );

      case 3:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Especialidades</Text>
            <Text style={styles.stepDescription}>
              Selecione suas áreas de especialização (máximo 5)
            </Text>

            <View style={styles.specialtiesGrid}>
              {specialtyOptions.map((specialty) => (
                <TouchableOpacity
                  key={specialty}
                  style={[
                    styles.specialtyCard,
                    formData.specialties.includes(specialty) && styles.specialtyCardActive
                  ]}
                  onPress={() => toggleSpecialty(specialty)}
                  disabled={!formData.specialties.includes(specialty) && formData.specialties.length >= 5}
                >
                  <Text style={[
                    styles.specialtyText,
                    formData.specialties.includes(specialty) && styles.specialtyTextActive
                  ]}>
                    {specialty}
                  </Text>
                  {formData.specialties.includes(specialty) && (
                    <CheckCircle size={16} color="#FFFFFF" />
                  )}
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.specialtyCount}>
              {formData.specialties.length}/5 especialidades selecionadas
            </Text>
          </View>
        );

      case 4:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Valores e Localização</Text>
            <Text style={styles.stepDescription}>
              Defina seus honorários e endereço profissional
            </Text>

            <View style={styles.inputContainer}>
              <DollarSign size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Valor da Consulta (R$)"
                value={formData.consultationFee}
                onChangeText={(text) => setFormData({ ...formData, consultationFee: text })}
                keyboardType="numeric"
              />
            </View>

            <View style={styles.inputContainer}>
              <DollarSign size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Valor por Hora (R$)"
                value={formData.hourlyRate}
                onChangeText={(text) => setFormData({ ...formData, hourlyRate: text })}
                keyboardType="numeric"
              />
            </View>

            <View style={styles.inputContainer}>
              <MapPin size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="CEP"
                value={formData.zipCode}
                onChangeText={(text) => setFormData({ ...formData, zipCode: text })}
                keyboardType="numeric"
              />
            </View>

            <View style={styles.inputContainer}>
              <MapPin size={20} color="#6B7280" />
              <TextInput
                style={styles.input}
                placeholder="Endereço Completo"
                value={formData.address}
                onChangeText={(text) => setFormData({ ...formData, address: text })}
              />
            </View>

            <View style={styles.inputRow}>
              <View style={[styles.inputContainer, { flex: 2, marginRight: 8 }]}>
                <MapPin size={20} color="#6B7280" />
                <TextInput
                  style={styles.input}
                  placeholder="Cidade"
                  value={formData.city}
                  onChangeText={(text) => setFormData({ ...formData, city: text })}
                />
              </View>
              <View style={[styles.inputContainer, { flex: 1, marginLeft: 8 }]}>
                <MapPin size={20} color="#6B7280" />
                <TextInput
                  style={styles.input}
                  placeholder="UF"
                  value={formData.state}
                  onChangeText={(text) => setFormData({ ...formData, state: text.toUpperCase() })}
                  maxLength={2}
                />
              </View>
            </View>

            <View style={styles.inputContainer}>
              <FileText size={20} color="#6B7280" />
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Biografia Profissional (opcional)"
                value={formData.bio}
                onChangeText={(text) => setFormData({ ...formData, bio: text })}
                multiline
                numberOfLines={4}
              />
            </View>
          </View>
        );

      case 5:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Documentos</Text>
            <Text style={styles.stepDescription}>
              Anexe os documentos necessários para validação
            </Text>

            <View style={styles.documentSection}>
              <TouchableOpacity style={styles.documentUpload}>
                <Camera size={24} color="#1E40AF" />
                <Text style={styles.documentUploadText}>
                  Carteira da OAB (frente e verso)
                </Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.documentUpload}>
                <Camera size={24} color="#1E40AF" />
                <Text style={styles.documentUploadText}>
                  RG ou CNH
                </Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.documentUpload}>
                <Camera size={24} color="#1E40AF" />
                <Text style={styles.documentUploadText}>
                  Comprovante de Residência
                </Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.documentUpload}>
                <Camera size={24} color="#1E40AF" />
                <Text style={styles.documentUploadText}>
                  Currículo Profissional (PDF)
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.ethicsSection}>
              <Text style={styles.ethicsTitle}>Questionário de Ética</Text>
              
              <View style={styles.ethicsQuestion}>
                <Text style={styles.questionText}>
                  Possui alguma violação ética registrada na OAB?
                </Text>
                <View style={styles.radioGroup}>
                  <TouchableOpacity
                    style={styles.radioOption}
                    onPress={() => setFormData({ ...formData, hasEthicsViolations: false })}
                  >
                    <View style={[styles.radio, !formData.hasEthicsViolations && styles.radioActive]} />
                    <Text style={styles.radioText}>Não</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.radioOption}
                    onPress={() => setFormData({ ...formData, hasEthicsViolations: true })}
                  >
                    <View style={[styles.radio, formData.hasEthicsViolations && styles.radioActive]} />
                    <Text style={styles.radioText}>Sim</Text>
                  </TouchableOpacity>
                </View>
              </View>

              <View style={styles.ethicsQuestion}>
                <Text style={styles.questionText}>
                  Possui antecedentes criminais?
                </Text>
                <View style={styles.radioGroup}>
                  <TouchableOpacity
                    style={styles.radioOption}
                    onPress={() => setFormData({ ...formData, hasCriminalRecord: false })}
                  >
                    <View style={[styles.radio, !formData.hasCriminalRecord && styles.radioActive]} />
                    <Text style={styles.radioText}>Não</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.radioOption}
                    onPress={() => setFormData({ ...formData, hasCriminalRecord: true })}
                  >
                    <View style={[styles.radio, formData.hasCriminalRecord && styles.radioActive]} />
                    <Text style={styles.radioText}>Sim</Text>
                  </TouchableOpacity>
                </View>
              </View>

              <View style={styles.ethicsQuestion}>
                <Text style={styles.questionText}>
                  É Pessoa Politicamente Exposta (PEP)?
                </Text>
                <View style={styles.radioGroup}>
                  <TouchableOpacity
                    style={styles.radioOption}
                    onPress={() => setFormData({ ...formData, isPEP: false })}
                  >
                    <View style={[styles.radio, !formData.isPEP && styles.radioActive]} />
                    <Text style={styles.radioText}>Não</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.radioOption}
                    onPress={() => setFormData({ ...formData, isPEP: true })}
                  >
                    <View style={[styles.radio, formData.isPEP && styles.radioActive]} />
                    <Text style={styles.radioText}>Sim</Text>
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          </View>
        );

      case 6:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Termos e Contrato</Text>
            <Text style={styles.stepDescription}>
              Leia e aceite os termos para finalizar seu cadastro
            </Text>

            <View style={styles.termsContainer}>
              <TouchableOpacity
                style={styles.termItem}
                onPress={() => setFormData({ ...formData, acceptedTerms: !formData.acceptedTerms })}
              >
                <View style={[styles.checkbox, formData.acceptedTerms && styles.checkboxActive]}>
                  {formData.acceptedTerms && <CheckCircle size={16} color="#FFFFFF" />}
                </View>
                <Text style={styles.termText}>
                  Aceito os <Text style={styles.termLink}>Termos de Uso</Text> da plataforma
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.termItem}
                onPress={() => setFormData({ ...formData, acceptedContract: !formData.acceptedContract })}
              >
                <View style={[styles.checkbox, formData.acceptedContract && styles.checkboxActive]}>
                  {formData.acceptedContract && <CheckCircle size={16} color="#FFFFFF" />}
                </View>
                <Text style={styles.termText}>
                  Aceito o <Text style={styles.termLink}>Contrato de Associação</Text> e 
                  as condições de comissionamento
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.termItem}
                onPress={() => setFormData({ ...formData, acceptedEthics: !formData.acceptedEthics })}
              >
                <View style={[styles.checkbox, formData.acceptedEthics && styles.checkboxActive]}>
                  {formData.acceptedEthics && <CheckCircle size={16} color="#FFFFFF" />}
                </View>
                <Text style={styles.termText}>
                  Declaro estar ciente do <Text style={styles.termLink}>Código de Ética</Text> 
                  da OAB e me comprometo a respeitá-lo
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.reviewInfo}>
              <Shield size={24} color="#7C3AED" />
              <View style={styles.reviewContent}>
                <Text style={styles.reviewTitle}>Processo de Análise</Text>
                <Text style={styles.reviewText}>
                  Sua solicitação será analisada por nossa equipe jurídica em até 48 horas. 
                  Verificaremos sua situação na OAB e validaremos todos os documentos enviados.
                </Text>
              </View>
            </View>
          </View>
        );

      default:
        return null;
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <LinearGradient
        colors={['#7C3AED', '#8B5CF6']}
        style={styles.header}
      >
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle}>Cadastro de Advogado</Text>
          <Text style={styles.headerSubtitle}>
            Junte-se à nossa rede de profissionais
          </Text>
        </View>

        {/* Progress Bar */}
        <View style={styles.progressContainer}>
          <View style={styles.progressBar}>
            <View 
              style={[
                styles.progressFill, 
                { width: `${(step / totalSteps) * 100}%` }
              ]} 
            />
          </View>
          <Text style={styles.progressText}>
            Etapa {step} de {totalSteps}
          </Text>
        </View>
      </LinearGradient>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {renderStepContent()}
      </ScrollView>

      {/* Navigation Buttons */}
      <View style={styles.navigationContainer}>
        {step > 1 && (
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => setStep(step - 1)}
          >
            <Text style={styles.backButtonText}>Voltar</Text>
          </TouchableOpacity>
        )}
        
        <TouchableOpacity
          style={[
            styles.nextButton,
            step === 1 && styles.nextButtonFull,
            (step === 6 && (!formData.acceptedTerms || !formData.acceptedContract || !formData.acceptedEthics)) && styles.nextButtonDisabled
          ]}
          onPress={handleNext}
          disabled={step === 6 && (!formData.acceptedTerms || !formData.acceptedContract || !formData.acceptedEthics)}
        >
          <LinearGradient
            colors={['#7C3AED', '#8B5CF6']}
            style={styles.nextButtonGradient}
          >
            <Text style={styles.nextButtonText}>
              {step === totalSteps ? 'Enviar Solicitação' : 'Continuar'}
            </Text>
            <ArrowRight size={20} color="#FFFFFF" />
          </LinearGradient>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    paddingTop: 60,
    paddingBottom: 24,
    paddingHorizontal: 24,
  },
  headerContent: {
    alignItems: 'center',
    marginBottom: 24,
  },
  headerTitle: {
    fontFamily: 'Inter-Bold',
    fontSize: 28,
    color: '#FFFFFF',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#E0E7FF',
  },
  progressContainer: {
    alignItems: 'center',
  },
  progressBar: {
    width: '100%',
    height: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 2,
  },
  progressText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#E0E7FF',
    marginTop: 8,
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 24,
  },
  stepContent: {
    marginBottom: 100,
  },
  stepTitle: {
    fontFamily: 'Inter-Bold',
    fontSize: 24,
    color: '#1F2937',
    marginBottom: 8,
  },
  stepDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#6B7280',
    marginBottom: 32,
    lineHeight: 24,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  inputRow: {
    flexDirection: 'row',
  },
  input: {
    flex: 1,
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    marginLeft: 12,
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  specialtiesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginBottom: 16,
  },
  specialtyCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: '#E5E7EB',
    gap: 8,
  },
  specialtyCardActive: {
    backgroundColor: '#7C3AED',
    borderColor: '#7C3AED',
  },
  specialtyText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#4B5563',
  },
  specialtyTextActive: {
    color: '#FFFFFF',
  },
  specialtyCount: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
  documentSection: {
    gap: 16,
    marginBottom: 32,
  },
  documentUpload: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F0F9FF',
    padding: 16,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#1E40AF',
    borderStyle: 'dashed',
  },
  documentUploadText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#1E40AF',
    marginLeft: 12,
  },
  ethicsSection: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  ethicsTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 16,
  },
  ethicsQuestion: {
    marginBottom: 20,
  },
  questionText: {
    fontFamily: 'Inter-Medium',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 12,
  },
  radioGroup: {
    flexDirection: 'row',
    gap: 24,
  },
  radioOption: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  radio: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#D1D5DB',
  },
  radioActive: {
    borderColor: '#7C3AED',
    backgroundColor: '#7C3AED',
  },
  radioText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#4B5563',
  },
  termsContainer: {
    gap: 16,
    marginBottom: 24,
  },
  termItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: '#D1D5DB',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
    marginTop: 2,
  },
  checkboxActive: {
    backgroundColor: '#7C3AED',
    borderColor: '#7C3AED',
  },
  termText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    flex: 1,
  },
  termLink: {
    color: '#7C3AED',
    fontFamily: 'Inter-SemiBold',
  },
  reviewInfo: {
    flexDirection: 'row',
    backgroundColor: '#F3F4F6',
    padding: 16,
    borderRadius: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#7C3AED',
  },
  reviewContent: {
    marginLeft: 12,
    flex: 1,
  },
  reviewTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#7C3AED',
    marginBottom: 4,
  },
  reviewText: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#4B5563',
    lineHeight: 16,
  },
  navigationContainer: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    gap: 12,
  },
  backButton: {
    flex: 1,
    backgroundColor: '#F3F4F6',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  backButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#4B5563',
  },
  nextButton: {
    flex: 2,
    borderRadius: 12,
    overflow: 'hidden',
  },
  nextButtonFull: {
    flex: 1,
  },
  nextButtonDisabled: {
    opacity: 0.5,
  },
  nextButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    gap: 8,
  },
  nextButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#FFFFFF',
  },
});