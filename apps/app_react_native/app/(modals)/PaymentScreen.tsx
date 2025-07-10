import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, Platform } from 'react-native';
import { useRouter } from 'expo-router';

// Importação condicional do Stripe
let useStripe: any = null;
try {
  const stripe = require('@stripe/stripe-react-native');
  useStripe = stripe.useStripe;
} catch (error) {
  console.log('Stripe not available in development build');
}

export default function PaymentScreen() {
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  
  // Usar Stripe apenas se disponível
  const stripeHook = useStripe ? useStripe() : { initPaymentSheet: null, presentPaymentSheet: null };
  const { initPaymentSheet, presentPaymentSheet } = stripeHook;

  useEffect(() => {
    if (initPaymentSheet) {
      initializePaymentSheet();
    }
  }, [initPaymentSheet]);

  const fetchPaymentSheetParams = async () => {
    console.log("Fetching mock payment sheet params");
    return {
      paymentIntent: 'pi_3Jexs22eZvKYlo2C0X3g7yD4_secret_O3e9xW9qP8j2Z3sX4c5V6b7A8',
      ephemeralKey: 'ek_test_YWNjdF8xMDMyRzZyR2dOTSRUNDg0TElhY1ZhaUR2Z3p1cFB1Z1lqSFI2RFRz',
      customer: 'cus_K3f5d3gS2b1j4H',
    };
  };

  const initializePaymentSheet = async () => {
    if (!initPaymentSheet) return;
    
    setLoading(true);
    const {
      paymentIntent,
      ephemeralKey,
      customer,
    } = await fetchPaymentSheetParams();

    const { error } = await initPaymentSheet({
      merchantDisplayName: "LITGO5, Inc.",
      customerId: customer,
      customerEphemeralKeySecret: ephemeralKey,
      paymentIntentClientSecret: paymentIntent,
      allowsDelayedPaymentMethods: true,
      returnURL: 'litgo5://stripe-redirect',
    });

    if (error) {
      Alert.alert(`Error code: ${error.code}`, error.message);
    }
    setLoading(false);
  };

  const openPaymentSheet = async () => {
    if (!presentPaymentSheet) {
      Alert.alert('Pagamento Indisponível', 'O sistema de pagamento não está configurado neste build de desenvolvimento.');
      return;
    }

    const { error } = await presentPaymentSheet();

    if (error) {
      Alert.alert(`Error code: ${error.code}`, error.message);
    } else {
      Alert.alert('Success', 'Your payment was successful!');
      router.back();
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Finalize seu Pagamento</Text>
      
      {!useStripe && (
        <View style={styles.warningContainer}>
          <Text style={styles.warningText}>
            ⚠️ Sistema de pagamento disponível apenas no build de produção
          </Text>
        </View>
      )}
      
      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        disabled={loading}
        onPress={openPaymentSheet}
      >
        <Text style={styles.buttonText}>
          {useStripe ? 'Pagar Agora' : 'Simular Pagamento'}
        </Text>
      </TouchableOpacity>
       <TouchableOpacity style={styles.cancelButton} onPress={() => router.back()}>
        <Text style={styles.cancelButtonText}>Cancelar</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#F9FAFB',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    color: '#1F2937',
  },
  button: {
    width: '100%',
    padding: 16,
    borderRadius: 12,
    backgroundColor: '#1E40AF',
    alignItems: 'center',
    marginBottom: 16,
  },
  buttonDisabled: {
    backgroundColor: '#9DB2BF',
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  cancelButton: {
    width: '100%',
    padding: 16,
    borderRadius: 12,
    backgroundColor: 'transparent',
    alignItems: 'center',
  },
  cancelButtonText: {
    color: '#6B7280',
    fontSize: 16,
  },
  warningContainer: {
    backgroundColor: '#FEE2E2',
    padding: 12,
    borderRadius: 8,
    marginBottom: 20,
    alignItems: 'center',
  },
  warningText: {
    color: '#991B1B',
    fontSize: 14,
    fontWeight: 'bold',
  },
}); 