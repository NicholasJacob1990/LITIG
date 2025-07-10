import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Expo } from "npm:expo-server-sdk@3.7.0";

// Inicializa o cliente da Expo
const expo = new Expo();

// Estrutura do payload esperado pelo webhook
interface NewMessagePayload {
  type: "INSERT";
  table: string;
  record: {
    id: string;
    ticket_id: string;
    sender_id: string;
    content: string;
    created_at: string;
  };
  schema: string;
  old_record: null;
}

serve(async (req) => {
  try {
    // 1. Validação do Webhook
    const payload: NewMessagePayload = await req.json();

    // 2. Criação do cliente Supabase com privilégios de serviço
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { record: message } = payload;

    // 3. Buscar informações do ticket e do destinatário
    const { data: ticketData, error: ticketError } = await supabaseAdmin
      .from("support_tickets")
      .select(`
        subject,
        creator_id,
        creator:profiles!creator_id ( push_token ),
        assignee:profiles!assigned_to ( push_token )
      `)
      .eq("id", message.ticket_id)
      .single();

    if (ticketError) throw ticketError;

    // 4. Determinar o destinatário da notificação
    // A notificação deve ser enviada para a outra parte da conversa.
    let recipientId = null;
    if (message.sender_id === ticketData.creator_id) {
      // Se quem enviou foi o criador, notificar o responsável (se houver)
      // Futuramente, notificar o grupo de suporte
    } else {
      // Se quem enviou foi o suporte, notificar o criador
      recipientId = ticketData.creator_id;
    }

    if (!recipientId) {
      console.log("Nenhum destinatário para a notificação.");
      return new Response(JSON.stringify({ message: "Nenhum destinatário" }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      });
    }
    
    // 5. Obter o push token do destinatário
    const { data: profileData, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("push_token, full_name")
      .eq("id", recipientId)
      .single();

    if (profileError || !profileData || !profileData.push_token) {
        throw new Error(`Token não encontrado para o usuário: ${recipientId}`);
    }

    const { push_token, full_name } = profileData;
    
    // 6. Validar se o token é um token da Expo
    if (!Expo.isExpoPushToken(push_token)) {
      throw new Error(`Token inválido: ${push_token}`);
    }

    // 7. Construir e enviar a notificação
    await expo.sendPushNotificationsAsync([
      {
        to: push_token,
        sound: "default",
        title: `Nova mensagem em "${ticketData.subject}"`,
        body: message.content.substring(0, 200), // Limita o corpo da mensagem
        data: { ticketId: message.ticket_id },
      },
    ]);

    // 8. Retornar sucesso
    return new Response(JSON.stringify({ message: "Notificação enviada com sucesso!" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Erro ao processar notificação:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
}); 