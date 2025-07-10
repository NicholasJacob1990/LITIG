import supabase from '@/lib/supabase';

// Tipos para os dados de tarefas
export interface Task {
  id?: string;
  case_id?: string;
  assigned_to?: string;
  title: string;
  description?: string;
  priority?: number;
  due_date?: string;
  status?: 'pending' | 'in_progress' | 'completed' | 'overdue';
  created_by?: string;
}

/**
 * Busca todas as tarefas atribuídas a um usuário ou relacionadas aos seus casos.
 * @param userId - O ID do usuário (advogado ou cliente).
 */
export const getTasks = async (userId: string) => {
  // Esta chamada de RPC precisaria ser criada no Supabase
  // para abstrair a lógica de permissão complexa.
  // Por enquanto, faremos uma consulta mais simples.
  const { data, error } = await supabase
    .from('tasks')
    .select(`
      *,
      case:cases (id, ai_analysis),
      assignee:profiles!assigned_to (id, full_name, avatar_url)
    `)
    .or(`assigned_to.eq.${userId},created_by.eq.${userId}`) // Simplificação
    .order('due_date', { ascending: true, nullsFirst: false });

  if (error) {
    console.error('Error fetching tasks:', error);
    throw error;
  }
  return data;
};

/**
 * Cria uma nova tarefa.
 * @param taskData - Os dados da tarefa.
 */
export const createTask = async (taskData: Task) => {
  const { data, error } = await supabase
    .from('tasks')
    .insert([taskData])
    .select()
    .single();

  if (error) {
    console.error('Error creating task:', error);
    throw error;
  }
  return data;
};

/**
 * Atualiza uma tarefa existente.
 * @param taskId - O ID da tarefa.
 * @param taskData - Os dados atualizados da tarefa.
 */
export const updateTask = async (taskId: string, taskData: Partial<Task>) => {
  const { data, error } = await supabase
    .from('tasks')
    .update(taskData)
    .eq('id', taskId)
    .select()
    .single();

  if (error) {
    console.error('Error updating task:', error);
    throw error;
  }
  return data;
};

/**
 * Atualiza o status de uma tarefa.
 * @param taskId - O ID da tarefa.
 * @param status - O novo status.
 */
export const updateTaskStatus = async (taskId: string, status: Task['status']) => {
  const { data, error } = await supabase
    .from('tasks')
    .update({ status })
    .eq('id', taskId)
    .select()
    .single();

  if (error) {
    console.error('Error updating task status:', error);
    throw error;
  }
  return data;
};

/**
 * Busca todas as tarefas de um caso específico.
 * @param caseId - O ID do caso.
 */
export const getCaseTasks = async (caseId: string) => {
  const { data, error } = await supabase
    .from('tasks')
    .select(`
      *,
      assignee:profiles!assigned_to (id, full_name, avatar_url)
    `)
    .eq('case_id', caseId)
    .order('due_date', { ascending: true, nullsFirst: false });

  if (error) {
    console.error('Error fetching case tasks:', error);
    throw error;
  }
  return data;
};

/**
 * Exclui uma tarefa.
 * @param taskId - O ID da tarefa.
 */
export const deleteTask = async (taskId: string) => {
  const { error } = await supabase
    .from('tasks')
    .delete()
    .eq('id', taskId);

  if (error) {
    console.error('Error deleting task:', error);
    throw error;
  }
}; 