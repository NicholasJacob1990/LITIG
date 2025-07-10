import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, ScrollView, KeyboardAvoidingView, Platform, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Eye, EyeOff } from 'lucide-react-native';
import supabase from '../../lib/supabase'; // Import Supabase client
import { isValidCPF, isValidCNPJ } from '../../lib/utils/validation';
import { Switch } from 'react-native-gesture-handler';

type UserType = 'PF' | 'PJ';

export default function RegisterClient() {
  const router = useRouter();
  const [userType, setUserType] = useState<UserType>('PF');
  const [formData, setFormData] = useState({
    // PF
    fullName: '',
    cpf: '',
    // PJ
    companyName: '',
    cnpj: '',
    // Common
    email: '',
    phone: '',
    password: '',
  });
  const [isPasswordVisible, setIsPasswordVisible] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [termsAccepted, setTermsAccepted] = useState(false);

  // Função para extrair apenas números de uma string
  const extractNumbers = (value: string) => value.replace(/[^\d]/g, '');
  
  // Funções de formatação
  const formatCPF = (value: string) => {
    const numbers = extractNumbers(value);
    return numbers.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
  };
  
  const formatCNPJ = (value: string) => {
    const numbers = extractNumbers(value);
    return numbers.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
  };
  
  const formatPhone = (value: string) => {
    const numbers = extractNumbers(value);
    if (numbers.length <= 10) {
      return numbers.replace(/(\d{2})(\d{4})(\d{4})/, '($1)$2-$3');
    } else {
      return numbers.replace(/(\d{2})(\d{5})(\d{4})/, '($1)$2-$3');
    }
  };

  const handleInputChange = (name: string, value: string) => {
    let formattedValue = value;
    
    // Aplicar formatação baseada no campo
    if (name === 'cpf') {
      formattedValue = formatCPF(value);
    } else if (name === 'cnpj') {
      formattedValue = formatCNPJ(value);
    } else if (name === 'phone') {
      formattedValue = formatPhone(value);
    }
    
    setFormData(prev => ({ ...prev, [name]: formattedValue }));
    // Clear error for the field being edited
    if (errors[name]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[name];
        return newErrors;
      });
    }
  };
  
  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    const { email, password, fullName, cpf, companyName, cnpj, phone } = formData;

    // Common fields validation
    if (!email.trim()) {
      newErrors.email = 'E-mail é obrigatório.';
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      newErrors.email = 'Formato de e-mail inválido.';
    }
    
    if (!password) {
      newErrors.password = 'Senha é obrigatória.';
    } else if (password.length < 8) {
      newErrors.password = 'A senha deve ter pelo menos 8 caracteres.';
    }
    
    if (!phone.trim()) {
      newErrors.phone = 'Telefone é obrigatório.';
    } else {
      const phoneNumbers = extractNumbers(phone);
      if (phoneNumbers.length < 10 || phoneNumbers.length > 11) {
        newErrors.phone = 'Formato de telefone inválido (DDD + número).';
      }
    }

    // Conditional fields validation
    if (userType === 'PF') {
        if (!fullName.trim()) {
          newErrors.fullName = 'Nome Completo é obrigatório.';
        }
        if (!cpf.trim()) {
          newErrors.cpf = 'CPF é obrigatório.';
        } else if (!isValidCPF(cpf)) {
          newErrors.cpf = 'CPF inválido.';
        }
    } else { // PJ
        if (!companyName.trim()) {
          newErrors.companyName = 'Razão Social é obrigatória.';
        }
        if (!cnpj.trim()) {
          newErrors.cnpj = 'CNPJ é obrigatório.';
        } else if (!isValidCNPJ(cnpj)) {
          newErrors.cnpj = 'CNPJ inválido.';
        }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleRegister = async () => {
    if (!validateForm()) return;
    
    setLoading(true);
    const { email, password, fullName, cpf, companyName, cnpj, phone } = formData;
    
    const { data: { user }, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: userType === 'PF' ? fullName : companyName,
          cpf: userType === 'PF' ? cpf : undefined,
          cnpj: userType === 'PJ' ? cnpj : undefined,
          phone: phone,
          user_type: userType, // PF or PJ
          role: 'client' // Custom claim
        }
      }
    });

    if (signUpError) {
      let errorMessage = 'Ocorreu um erro desconhecido. Tente novamente.';
      if (signUpError.message.includes('unique constraint')) {
        errorMessage = 'Este e-mail já está em uso.';
        setErrors({ email: errorMessage });
      } else if (signUpError.message.toLowerCase().includes('password should be at least')) {
        errorMessage = 'A senha é muito fraca. Tente uma mais longa ou complexa.';
        setErrors({ password: errorMessage });
      } else {
        setErrors({ form: errorMessage }); // General form error
      }
    } else if (user) {
      Alert.alert(
        'Cadastro Quase Completo', 
        'Enviamos um link de confirmação para o seu e-mail. Por favor, verifique sua caixa de entrada para ativar sua conta.'
      );
      router.replace('/(auth)'); // Go back to login/welcome screen
    }
    setLoading(false);
  };

  const renderInput = (
    name: keyof typeof formData, 
    placeholder: string, 
    options: { keyboardType?: any, maxLength?: number, autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters' } = {}
  ) => (
    <View style={styles.inputContainer}>
      <TextInput
        style={[styles.input, errors[name] && styles.inputError]}
        placeholder={placeholder}
        value={formData[name]}
        onChangeText={(val) => handleInputChange(name, val)}
        keyboardType={options.keyboardType || 'default'}
        maxLength={options.maxLength}
        autoCapitalize={options.autoCapitalize || 'sentences'}
        placeholderTextColor="#9CA3AF"
      />
      {errors[name] && <Text style={styles.errorText}>{errors[name]}</Text>}
    </View>
  );

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <KeyboardAvoidingView 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={{ flex: 1 }}
      >
        <ScrollView contentContainerStyle={styles.scrollContainer} keyboardShouldPersistTaps="handled">
          <Text style={styles.title}>Crie sua Conta de Cliente</Text>
          <Text style={styles.subtitle}>Preencha os dados abaixo para começar.</Text>

          {/* Seletor PF/PJ */}
          <View style={styles.selectorContainer}>
            <TouchableOpacity 
              style={[styles.selectorButton, userType === 'PF' && styles.selectorActive]} 
              onPress={() => setUserType('PF')}>
              <Text style={[styles.selectorText, userType === 'PF' && styles.selectorTextActive]}>Pessoa Física</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={[styles.selectorButton, userType === 'PJ' && styles.selectorActive]} 
              onPress={() => setUserType('PJ')}>
              <Text style={[styles.selectorText, userType === 'PJ' && styles.selectorTextActive]}>Pessoa Jurídica</Text>
            </TouchableOpacity>
          </View>

          {/* Formulário Condicional */}
          {userType === 'PF' ? (
            <>
              {renderInput('fullName', 'Nome Completo', { autoCapitalize: 'words' })}
              {renderInput('cpf', 'CPF (000.000.000-00)', { keyboardType: 'numeric', maxLength: 14 })}
            </>
          ) : (
            <>
              {renderInput('companyName', 'Razão Social', { autoCapitalize: 'words' })}
              {renderInput('cnpj', 'CNPJ (00.000.000/0000-00)', { keyboardType: 'numeric', maxLength: 18 })}
            </>
          )}

          {/* Campos Comuns */}
          {renderInput('email', 'E-mail', { keyboardType: 'email-address', autoCapitalize: 'none' })}
          {renderInput('phone', 'Telefone (11)99999-9999', { keyboardType: 'phone-pad', maxLength: 15 })}

          <View style={styles.inputContainer}>
            <View style={[styles.passwordWrapper, errors.password && styles.inputError]}>
              <TextInput
                style={styles.passwordInput}
                placeholder="Senha"
                value={formData.password}
                onChangeText={(val) => handleInputChange('password', val)}
                secureTextEntry={!isPasswordVisible}
                placeholderTextColor="#9CA3AF"
                autoCapitalize="none"
              />
              <TouchableOpacity onPress={() => setIsPasswordVisible(!isPasswordVisible)} style={styles.eyeIcon}>
                {isPasswordVisible ? <EyeOff size={20} color="#6B7280" /> : <Eye size={20} color="#6B7280" />}
              </TouchableOpacity>
            </View>
            {errors.password && <Text style={styles.errorText}>{errors.password}</Text>}
          </View>
          
          <View style={styles.switchContainer}>
            <Text style={styles.switchLabel}>Li e concordo com os Termos de Uso e a Política de Privacidade.</Text>
            <Switch
              trackColor={{ false: "#E5E7EB", true: "#3B82F6" }}
              thumbColor={termsAccepted ? "#FFFFFF" : "#f4f3f4"}
              ios_backgroundColor="#E5E7EB"
              onValueChange={setTermsAccepted}
              value={termsAccepted}
            />
          </View>

          {errors.form && <Text style={styles.formErrorText}>{errors.form}</Text>}

          <TouchableOpacity 
            style={[styles.registerButton, (loading || !termsAccepted) && styles.registerButtonDisabled]} 
            onPress={handleRegister} 
            disabled={loading || !termsAccepted}
          >
            {loading ? <ActivityIndicator color="#FFFFFF" /> : <Text style={styles.registerButtonText}>Criar Conta</Text>}
          </TouchableOpacity>
          
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F9FAFB',
    },
    scrollContainer: {
        flexGrow: 1,
        padding: 24,
        justifyContent: 'center',
    },
    title: {
        fontSize: 28,
        fontFamily: 'Inter-Bold',
        color: '#1F2937',
        textAlign: 'center',
        marginBottom: 8,
    },
    subtitle: {
        fontSize: 16,
        fontFamily: 'Inter-Regular',
        color: '#6B7280',
        textAlign: 'center',
        marginBottom: 32,
    },
    selectorContainer: {
        flexDirection: 'row',
        backgroundColor: '#E5E7EB',
        borderRadius: 8,
        padding: 4,
        marginBottom: 24,
    },
    selectorButton: {
        flex: 1,
        paddingVertical: 10,
        borderRadius: 6,
    },
    selectorActive: {
        backgroundColor: '#FFFFFF',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.1,
        shadowRadius: 2,
        elevation: 2,
    },
    selectorText: {
        textAlign: 'center',
        fontFamily: 'Inter-SemiBold',
        fontSize: 14,
        color: '#4B5563',
    },
    selectorTextActive: {
        color: '#1E40AF',
    },
    inputContainer: {
        marginBottom: 16,
    },
    input: {
        backgroundColor: '#FFFFFF',
        paddingHorizontal: 16,
        paddingVertical: 14,
        borderRadius: 8,
        fontSize: 16,
        fontFamily: 'Inter-Regular',
        color: '#1F2937',
        borderWidth: 1,
        borderColor: '#D1D5DB',
    },
    inputError: {
      borderColor: '#DC2626',
    },
    passwordWrapper: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#FFFFFF',
        borderRadius: 8,
        borderWidth: 1,
        borderColor: '#D1D5DB',
    },
    passwordInput: {
        flex: 1,
        paddingHorizontal: 16,
        paddingVertical: 14,
        fontSize: 16,
        fontFamily: 'Inter-Regular',
        color: '#1F2937',
    },
    eyeIcon: {
        padding: 12,
    },
    registerButton: {
        backgroundColor: '#1E40AF',
        paddingVertical: 16,
        borderRadius: 12,
        alignItems: 'center',
        marginTop: 8,
    },
    registerButtonDisabled: {
        backgroundColor: '#9DB2BF',
    },
    registerButtonText: {
        fontSize: 18,
        fontFamily: 'Inter-Bold',
        color: '#FFFFFF',
    },
    errorText: {
        color: '#DC2626',
        fontFamily: 'Inter-Regular',
        marginTop: 4,
        marginLeft: 4,
        fontSize: 12,
    },
    formErrorText: {
        color: '#DC2626',
        fontFamily: 'Inter-Regular',
        textAlign: 'center',
        marginBottom: 16,
    },
    switchContainer: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      backgroundColor: '#FFFFFF',
      borderRadius: 8,
      borderWidth: 1,
      borderColor: '#D1D5DB',
      paddingVertical: 8,
      paddingHorizontal: 16,
      marginVertical: 16,
    },
    switchLabel: {
      flex: 1,
      fontSize: 14,
      color: '#374151',
      marginRight: 8,
    }
}); 