import { useState, useEffect, useRef } from 'react';
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import supabase from '@/lib/supabase';
import { useAuth } from '@/lib/contexts/AuthContext';

// Configurar o handler apenas quando necessário
let handlerConfigured = false;

const configureNotificationHandler = () => {
  if (!handlerConfigured) {
    Notifications.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: false, // Badge deve ser controlado pelo servidor
        shouldShowBanner: true,
        shouldShowList: true,
      }),
    });
    handlerConfigured = true;
  }
};

export const usePushNotifications = () => {
  const { user } = useAuth();
  const [expoPushToken, setExpoPushToken] = useState<string | undefined>();

  useEffect(() => {
    // Configurar handler apenas quando o hook é usado
    configureNotificationHandler();
    const registerForPushNotificationsAsync = async () => {
      let token;
      if (Platform.OS === 'android') {
        await Notifications.setNotificationChannelAsync('default', {
          name: 'default',
          importance: Notifications.AndroidImportance.MAX,
          vibrationPattern: [0, 250, 250, 250],
          lightColor: '#FF231F7C',
        });
      }

      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;
      if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }
      if (finalStatus !== 'granted') {
        alert('Falha ao obter token para notificações push!');
        return;
      }
      
      // Use seu Project ID do EAS
      token = (await Notifications.getExpoPushTokenAsync({ projectId: '2ec83ef1-3235-4926-98c2-107ef29fde7d' })).data;
      setExpoPushToken(token);
      return token;
    };

    const saveTokenToProfile = async (token: string) => {
        if (!user) return;
        
        const { error } = await supabase
          .from('profiles')
          .update({ expo_push_token: token })
          .eq('id', user.id);
          
        if (error) {
            console.error('Failed to save push token:', error);
        } else {
            console.log('Push token saved successfully!');
        }
    };

    registerForPushNotificationsAsync().then(token => {
      if (token) {
        saveTokenToProfile(token);
      }
    });

    const notificationListener = Notifications.addNotificationReceivedListener(notification => {
      console.log('Notification received:', notification);
    });

    const responseListener = Notifications.addNotificationResponseReceivedListener(response => {
      console.log('Notification response received:', response);
    });

    return () => {
      Notifications.removeNotificationSubscription(notificationListener);
      Notifications.removeNotificationSubscription(responseListener);
    };
  }, [user]);

  return { expoPushToken };
}; 