-- Habilitar a extensão moddatetime para gerenciamento de `updated_at`
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "moddatetime";
 
-- Habilitar a extensão pg_cron para agendamento de tarefas
-- CREATE EXTENSION IF NOT EXISTS "pg_cron"; 