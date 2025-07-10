import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput, Alert } from 'react-native';
import { useState } from 'react';
import { LinearGradient } from 'expo-linear-gradient';
import { User, Building2, Mail, Phone, MapPin, FileText, Shield, CircleCheck as CheckCircle, ArrowRight, Camera, Calendar } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { router, useLocalSearchParams } from 'expo-router';

export default function OnboardingScreen() {
  const { type } = useLocalSearchParams<{ type: 'PF' | 'PJ' }>();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    clientType: type || 'PF',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
    // PF fields
    fullName: '',
    cpf: '',
    birthDate: '',
    // PJ fields
    companyName: '',
    cnpj: '',
    tradeName: '',
    representativeName: '',
    representativeCpf: '',
    // Address
    zipCode: '',
    address: '',
    city: '',
    state: '',
    // Terms
    acceptedTerms: false,
    acceptedLGPD: false,
    allowLocation: false,
  });

  const totalSteps = 4;

  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      handleSubmit();
    }
  };

  const handleSubmit = () => {
    Alert.alert(
      'Cadastro Realizado',
      'Sua conta foi criada com sucesso! Agora você pode iniciar uma consulta jurídica.',
      [
        { text: 'Continuar', onPress: () => router.replace('/(tabs)') }
      ]
    );
  };

  const renderStepContent = () => {
    switch (step) {
      case 1:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Tipo de Cliente</Text>
            <Text style={styles.stepDescription}>
              Selecione o tipo de atendimento que você precisa
            </Text>

            <View style={styles.clientTypeContainer}>
              <TouchableOpacity
                style={[
                  styles.clientTypeCard,
                  formData.clientType === 'PF' && styles.clientTypeCardActive
                ]}
                onPress={() => setFormData({ ...formData, clientType: 'PF' })}
              >
                <User size={32} color={formData.clientType === 'PF' ? '#FFFFFF' : '#1E40AF'} />
                <Text style={[
                  styles.clientTypeTitle,
                  formData.clientType === 'PF' && styles.clientTypeTextActive
                ]}>
                  Pessoa Física
                </Text>
                <Text style={[
                  styles.clientTypeDescription,
                  formData.clientType === 'PF' && styles.clientTypeTextActive
                ]}>
                  Consultas individuais e questões pessoais
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.clientTypeCard,
                  formData.clientType === 'PJ' && styles.clientTypeCardActive
                ]}
                onPress={() => setFormData({ ...formData, clientType: 'PJ' })}
              >
                <Building2 size={32} color={formData.clientType === 'PJ' ? '#FFFFFF' : '#1E40AF'} />
                <Text style={[
                  styles.clientTypeTitle,
                  formData.clientType === 'PJ' && styles.clientTypeTextActive
                ]}>
                  Pessoa Jurídica
                </Text>
                <Text style={[
                  styles.clientTypeDescription,
                  formData.clientType === 'PJ' && styles.clientTypeTextActive
                ]}>
                  Consultas empresariais e corporativas
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        );

      case 2:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Dados de Acesso</Text>
            <Text style={styles.stepDescription}>
              Crie sua conta para acessar a plataforma
            </Text>

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

      case 3:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>
              {formData.clientType === 'PF' ? 'Dados Pessoais' : 'Dados da Empresa'}
            </Text>
            <Text style={styles.stepDescription}>
              {formData.clientType === 'PF' 
                ? 'Informe seus dados pessoais' 
                : 'Informe os dados da sua empresa'}
            </Text>

            {formData.clientType === 'PF' ? (
              <>
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
                  <Calendar size={20} color="#6B7280" />
                  <TextInput
                    style={styles.input}
                    placeholder="Data de Nascimento"
                    value={formData.birthDate}
                    onChangeText={(text) => setFormData({ ...formData, birthDate: text })}
                  />
                </View>
              </>
            ) : (
              <>
                <View style={styles.inputContainer}>
                  <Building2 size={20} color="#6B7280" />
                  <TextInput
                    style={styles.input}
                    placeholder="Razão Social"
                    value={formData.companyName}
                    onChangeText={(text) => setFormData({ ...formData, companyName: text })}
                  />
                </View>

                <View style={styles.inputContainer}>
                  <FileText size={20} color="#6B7280" />
                  <TextInput
                    style={styles.input}
                    placeholder="CNPJ"
                    value={formData.cnpj}
                    onChangeText={(text) => setFormData({ ...formData, cnpj: text })}
                    keyboardType="numeric"
                  />
                </View>

                <View style={styles.inputContainer}>
                  <Building2 size={20} color="#6B7280" />
                  <TextInput
                    style={styles.input}
                    placeholder="Nome Fantasia"
                    value={formData.tradeName}
                    onChangeText={(text) => setFormData({ ...formData, tradeName: text })}
                  />
                </View>

                <View style={styles.inputContainer}>
                  <User size={20} color="#6B7280" />
                  <TextInput
                    style={styles.input}
                    placeholder="Nome do Representante Legal"
                    value={formData.representativeName}
                    onChangeText={(text) => setFormData({ ...formData, representativeName: text })}
                  />
                </View>

                <View style={styles.inputContainer}>
                  <FileText size={20} color="#6B7280" />
                  <TextInput
                    style={styles.input}
                    placeholder="CPF do Representante"
                    value={formData.representativeCpf}
                    onChangeText={(text) => setFormData({ ...formData, representativeCpf: text })}
                    keyboardType="numeric"
                  />
                </View>
              </>
            )}

            {/* Document Upload Section */}
            <View style={styles.documentSection}>
              <Text style={styles.documentTitle}>Documentos Necessários</Text>
              <TouchableOpacity style={styles.documentUpload}>
                <Camera size={24} color="#1E40AF" />
                <Text style={styles.documentUploadText}>
                  {formData.clientType === 'PF' 
                    ? 'Anexar RG ou CNH' 
                    : 'Anexar Contrato Social'}
                </Text>
              </TouchableOpacity>
              
              {formData.clientType === 'PJ' && (
                <TouchableOpacity style={styles.documentUpload}>
                  <Camera size={24} color="#1E40AF" />
                  <Text style={styles.documentUploadText}>
                    Anexar RG do Representante
                  </Text>
                </TouchableOpacity>
              )}
            </View>
          </View>
        );

      case 4:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Termos e Condições</Text>
            <Text style={styles.stepDescription}>
              Leia e aceite nossos termos para finalizar o cadastro
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
                  Aceito os <Text style={styles.termLink}>Termos de Uso</Text> e 
                  <Text style={styles.termLink}> Política de Privacidade</Text>
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.termItem}
                onPress={() => setFormData({ ...formData, acceptedLGPD: !formData.acceptedLGPD })}
              >
                <View style={[styles.checkbox, formData.acceptedLGPD && styles.checkboxActive]}>
                  {formData.acceptedLGPD && <CheckCircle size={16} color="#FFFFFF" />}
                </View>
                <Text style={styles.termText}>
                  Autorizo o tratamento dos meus dados pessoais conforme a 
                  <Text style={styles.termLink}> LGPD</Text>
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.termItem}
                onPress={() => setFormData({ ...formData, allowLocation: !formData.allowLocation })}
              >
                <View style={[styles.checkbox, formData.allowLocation && styles.checkboxActive]}>
                  {formData.allowLocation && <CheckCircle size={16} color="#FFFFFF" />}
                </View>
                <Text style={styles.termText}>
                  Permitir acesso à localização para encontrar advogados próximos (opcional)
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.complianceInfo}>
              <Shield size={24} color="#059669" />
              <View style={styles.complianceContent}>
                <Text style={styles.complianceTitle}>Segurança e Compliance</Text>
                <Text style={styles.complianceText}>
                  Seus dados são protegidos por criptografia de ponta e nossa plataforma 
                  é totalmente aderente às normas da OAB e LGPD.
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
        colors={['#1E40AF', '#3B82F6']}
        style={styles.header}
      >
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle}>Criar Conta</Text>
          <Text style={styles.headerSubtitle}>
            {formData.clientType === 'PF' ? 'Pessoa Física' : 'Pessoa Jurídica'}
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
            (step === 4 && (!formData.acceptedTerms || !formData.acceptedLGPD)) && styles.nextButtonDisabled
          ]}
          onPress={handleNext}
          disabled={step === 4 && (!formData.acceptedTerms || !formData.acceptedLGPD)}
        >
          <LinearGradient
            colors={['#1E40AF', '#3B82F6']}
            style={styles.nextButtonGradient}
          >
            <Text style={styles.nextButtonText}>
              {step === totalSteps ? 'Finalizar Cadastro' : 'Continuar'}
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
  clientTypeContainer: {
    gap: 16,
  },
  clientTypeCard: {
    backgroundColor: '#FFFFFF',
    padding: 24,
    borderRadius: 16,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#E5E7EB',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  clientTypeCardActive: {
    borderColor: '#1E40AF',
    backgroundColor: '#1E40AF',
  },
  clientTypeTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginTop: 12,
    marginBottom: 4,
  },
  clientTypeDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
  clientTypeTextActive: {
    color: '#FFFFFF',
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
  input: {
    flex: 1,
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    marginLeft: 12,
  },
  documentSection: {
    marginTop: 24,
  },
  documentTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 12,
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
    marginBottom: 12,
  },
  documentUploadText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#1E40AF',
    marginLeft: 12,
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
    backgroundColor: '#1E40AF',
    borderColor: '#1E40AF',
  },
  termText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    flex: 1,
  },
  termLink: {
    color: '#1E40AF',
    fontFamily: 'Inter-SemiBold',
  },
  complianceInfo: {
    flexDirection: 'row',
    backgroundColor: '#F0FDF4',
    padding: 16,
    borderRadius: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#059669',
  },
  complianceContent: {
    marginLeft: 12,
    flex: 1,
  },
  complianceTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#059669',
    marginBottom: 4,
  },
  complianceText: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#065F46',
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