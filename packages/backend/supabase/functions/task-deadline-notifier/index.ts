import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Expo } from 'npm:expo-server-sdk@3';

console.log('Task Deadline Notifier function starting up...');

const expo = new Expo();

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!}` } } }
    );

    // Encontra tarefas com prazo nas próximas 24 horas que ainda não foram concluídas
    const now = new Date();
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const { data: tasks, error } = await supabaseClient
      .from('tasks')
      .select(`
        id,
        title,
        due_date,
        assignee:profiles (
          id,
          full_name,
          expo_push_token
        )
      `)
      .neq('status', 'completed')
      .gte('due_date', now.toISOString())
      .lte('due_date', tomorrow.toISOString());

    if (error) throw error;
    if (!tasks || tasks.length === 0) {
      console.log('No tasks due soon.');
      return new Response(JSON.stringify({ message: 'No tasks due soon.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const notifications = [];
    for (const task of tasks) {
      if (task.assignee && Expo.isExpoPushToken(task.assignee.expo_push_token)) {
        notifications.push({
          to: task.assignee.expo_push_token,
          sound: 'default',
          title: 'Lembrete de Prazo',
          body: `A tarefa "${task.title}" vence em menos de 24 horas!`,
          data: { withSome: 'data' },
        });
      }
    }

    if (notifications.length > 0) {
      const chunks = expo.chunkPushNotifications(notifications);
      for (const chunk of chunks) {
        await expo.sendPushNotificationsAsync(chunk);
      }
      console.log(`Sent ${notifications.length} notifications.`);
    }

    return new Response(JSON.stringify({ message: `Sent ${notifications.length} notifications.` }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error(err);
    return new Response(String(err?.message ?? err), { status: 500 });
  }
}); 