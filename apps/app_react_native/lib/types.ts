/**
 * Tipos globais para o projeto LITGO5
 */

// ============================================================================
// TIPOS DE USUÁRIO E AUTENTICAÇÃO
// ============================================================================

export interface User {
  id: string;
  email: string;
  name: string;
  role: 'client' | 'lawyer' | 'admin';
  phone?: string;
  avatar_url?: string;
  created_at: string;
  updated_at: string;
}

export interface Profile {
  id: string;
  user_id: string;
  full_name: string;
  phone?: string;
  cpf?: string;
  birth_date?: string;
  address?: Address;
  professional_info?: ProfessionalInfo;
  preferences?: UserPreferences;
  created_at: string;
  updated_at: string;
}

export interface Address {
  street: string;
  number: string;
  complement?: string;
  neighborhood: string;
  city: string;
  state: string;
  zip_code: string;
  country: string;
  latitude?: number;
  longitude?: number;
}

export interface ProfessionalInfo {
  oab_number?: string;
  oab_state?: string;
  specializations: string[];
  experience_years: number;
  law_school?: string;
  graduation_year?: number;
  certifications?: string[];
}

export interface UserPreferences {
  notifications: {
    email: boolean;
    push: boolean;
    sms: boolean;
  };
  privacy: {
    profile_visible: boolean;
    contact_visible: boolean;
  };
  language: string;
  timezone: string;
}

// ============================================================================
// TIPOS DE CASO JURÍDICO
// ============================================================================

export interface Case {
  id: string;
  client_id: string;
  title: string;
  description: string;
  area: LegalArea;
  subarea: string;
  status: CaseStatus;
  priority: CasePriority;
  complexity: CaseComplexity;
  estimated_value?: number;
  coordinates?: {
    latitude: number;
    longitude: number;
  };
  deadline?: string;
  created_at: string;
  updated_at: string;
  documents?: Document[];
  timeline?: CaseEvent[];
  assigned_lawyer_id?: string;
  contract_id?: string;
}

export type LegalArea = 
  | 'Trabalhista'
  | 'Civil'
  | 'Criminal'
  | 'Tributário'
  | 'Previdenciário'
  | 'Consumidor'
  | 'Família'
  | 'Empresarial'
  | 'Imobiliário'
  | 'Administrativo';

export type CaseStatus = 
  | 'draft'
  | 'open'
  | 'in_progress'
  | 'waiting_documents'
  | 'in_court'
  | 'settled'
  | 'closed'
  | 'cancelled';

export type CasePriority = 'low' | 'medium' | 'high' | 'urgent';

export type CaseComplexity = 'simple' | 'medium' | 'complex';

export interface CaseEvent {
  id: string;
  case_id: string;
  type: EventType;
  title: string;
  description: string;
  date: string;
  created_by: string;
  metadata?: Record<string, any>;
  created_at: string;
}

export type EventType = 
  | 'created'
  | 'updated'
  | 'document_added'
  | 'document_removed'
  | 'lawyer_assigned'
  | 'contract_signed'
  | 'hearing_scheduled'
  | 'deadline_set'
  | 'status_changed'
  | 'comment_added'
  | 'payment_received'
  | 'closed';

// ============================================================================
// TIPOS DE DOCUMENTO
// ============================================================================

export interface Document {
  id: string;
  case_id: string;
  name: string;
  type: DocumentType;
  file_url: string;
  file_size: number;
  mime_type: string;
  uploaded_by: string;
  uploaded_at: string;
  version: number;
  status: DocumentStatus;
  metadata?: DocumentMetadata;
  preview_url?: string;
  thumbnail_url?: string;
}

export type DocumentType = 
  | 'contract'
  | 'petition'
  | 'evidence'
  | 'court_decision'
  | 'correspondence'
  | 'invoice'
  | 'receipt'
  | 'identity'
  | 'other';

export type DocumentStatus = 
  | 'uploading'
  | 'processing'
  | 'ready'
  | 'error'
  | 'deleted';

export interface DocumentMetadata {
  pages?: number;
  extracted_text?: string;
  keywords?: string[];
  confidence_score?: number;
  language?: string;
  created_date?: string;
  modified_date?: string;
}

// ============================================================================
// TIPOS DE ADVOGADO
// ============================================================================

export interface Lawyer {
  id: string;
  user_id: string;
  name: string;
  oab_number: string;
  oab_state: string;
  specializations: string[];
  experience_years: number;
  rating: number;
  total_cases: number;
  success_rate: number;
  response_time_hours: number;
  hourly_rate?: number;
  coordinates?: {
    latitude: number;
    longitude: number;
  };
  availability: LawyerAvailability;
  verification_status: VerificationStatus;
  created_at: string;
  updated_at: string;
}

export interface LawyerAvailability {
  status: 'available' | 'busy' | 'unavailable';
  capacity: number;
  current_cases: number;
  next_available_date?: string;
}

export type VerificationStatus = 'pending' | 'verified' | 'rejected';

export interface LawyerStats {
  total_cases: number;
  won_cases: number;
  lost_cases: number;
  ongoing_cases: number;
  success_rate: number;
  average_case_duration: number;
  client_satisfaction: number;
  areas_of_expertise: Record<string, number>;
}

// ============================================================================
// TIPOS DE CONTRATO
// ============================================================================

export interface Contract {
  id: string;
  case_id: string;
  client_id: string;
  lawyer_id: string;
  status: ContractStatus;
  fee_model: FeeModel;
  terms: string;
  signed_by_client?: string;
  signed_by_lawyer?: string;
  client_signature_date?: string;
  lawyer_signature_date?: string;
  docusign_envelope_id?: string;
  created_at: string;
  updated_at: string;
}

export type ContractStatus = 
  | 'draft'
  | 'pending_signature'
  | 'active'
  | 'completed'
  | 'cancelled'
  | 'disputed';

export interface FeeModel {
  type: 'success' | 'fixed' | 'hourly' | 'hybrid';
  success_percentage?: number;
  fixed_amount?: number;
  hourly_rate?: number;
  advance_payment?: number;
  payment_schedule?: PaymentSchedule[];
}

export interface PaymentSchedule {
  due_date: string;
  amount: number;
  description: string;
  status: 'pending' | 'paid' | 'overdue';
}

// ============================================================================
// TIPOS DE MATCHING
// ============================================================================

export interface MatchRequest {
  case: Case;
  preferences: MatchPreferences;
  top_n: number;
}

export interface MatchPreferences {
  max_distance_km?: number;
  min_rating?: number;
  max_hourly_rate?: number;
  preferred_experience_years?: number;
  required_specializations?: string[];
  availability_required?: boolean;
}

export interface MatchedLawyer {
  lawyer: Lawyer;
  match_score: number;
  distance_km: number;
  estimated_cost: number;
  availability_status: string;
  match_reasons: string[];
}

export interface MatchResponse {
  success: boolean;
  case_id: string;
  lawyers: MatchedLawyer[];
  total_evaluated: number;
  algorithm_version: string;
  execution_time_ms: number;
}

// ============================================================================
// TIPOS DE NOTIFICAÇÃO
// ============================================================================

export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  message: string;
  data?: Record<string, any>;
  read: boolean;
  action_url?: string;
  created_at: string;
  expires_at?: string;
}

export type NotificationType = 
  | 'case_update'
  | 'new_message'
  | 'contract_signed'
  | 'payment_due'
  | 'hearing_reminder'
  | 'document_shared'
  | 'lawyer_assigned'
  | 'system_announcement';

// ============================================================================
// TIPOS DE SUPORTE
// ============================================================================

export interface SupportTicket {
  id: string;
  user_id: string;
  subject: string;
  description: string;
  category: SupportCategory;
  priority: SupportPriority;
  status: SupportStatus;
  assigned_to?: string;
  resolution?: string;
  created_at: string;
  updated_at: string;
  resolved_at?: string;
}

export type SupportCategory = 
  | 'technical'
  | 'billing'
  | 'legal'
  | 'account'
  | 'feature_request'
  | 'bug_report'
  | 'other';

export type SupportPriority = 'low' | 'medium' | 'high' | 'critical';

export type SupportStatus = 
  | 'open'
  | 'in_progress'
  | 'waiting_response'
  | 'resolved'
  | 'closed';

// ============================================================================
// TIPOS DE API
// ============================================================================

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  timestamp: string;
}

export interface PaginatedResponse<T = any> {
  data: T[];
  pagination: {
    page: number;
    per_page: number;
    total: number;
    total_pages: number;
  };
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, any>;
  timestamp: string;
}

// ============================================================================
// TIPOS DE FORMULÁRIO
// ============================================================================

export interface FormField {
  name: string;
  type: 'text' | 'email' | 'password' | 'number' | 'select' | 'textarea' | 'checkbox' | 'radio' | 'date' | 'file';
  label: string;
  placeholder?: string;
  required?: boolean;
  validation?: ValidationRule[];
  options?: SelectOption[];
  multiple?: boolean;
}

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface ValidationRule {
  type: 'required' | 'email' | 'min' | 'max' | 'pattern' | 'custom';
  value?: any;
  message: string;
}

export interface FormState {
  values: Record<string, any>;
  errors: Record<string, string>;
  touched: Record<string, boolean>;
  isSubmitting: boolean;
  isValid: boolean;
}

// ============================================================================
// TIPOS DE CHAT
// ============================================================================

export interface ChatMessage {
  id: string;
  chat_id: string;
  sender_id: string;
  sender_type: 'user' | 'ai' | 'system';
  content: string;
  type: 'text' | 'image' | 'file' | 'system';
  metadata?: Record<string, any>;
  created_at: string;
  updated_at?: string;
}

export interface Chat {
  id: string;
  case_id?: string;
  participants: string[];
  title: string;
  type: 'support' | 'case' | 'consultation';
  status: 'active' | 'closed' | 'archived';
  last_message?: ChatMessage;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// TIPOS DE UTILIDADE
// ============================================================================

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface DateRange {
  start: string;
  end: string;
}

export interface FileUpload {
  file: File;
  name: string;
  type: string;
  size: number;
  progress: number;
  status: 'pending' | 'uploading' | 'completed' | 'error';
  error?: string;
}

export interface SearchFilters {
  query?: string;
  category?: string;
  status?: string;
  date_range?: DateRange;
  location?: Coordinates;
  radius_km?: number;
  sort_by?: string;
  sort_order?: 'asc' | 'desc';
}

// ============================================================================
// TIPOS DE CONFIGURAÇÃO
// ============================================================================

export interface AppConfig {
  api_url: string;
  app_name: string;
  version: string;
  environment: 'development' | 'staging' | 'production';
  features: {
    chat_enabled: boolean;
    video_calls_enabled: boolean;
    payments_enabled: boolean;
    ai_matching_enabled: boolean;
  };
  limits: {
    max_file_size_mb: number;
    max_files_per_case: number;
    max_cases_per_user: number;
  };
}

export interface Theme {
  colors: {
    primary: string;
    secondary: string;
    background: string;
    surface: string;
    text: string;
    error: string;
    warning: string;
    success: string;
    info: string;
  };
  fonts: {
    regular: string;
    medium: string;
    bold: string;
  };
  spacing: {
    xs: number;
    sm: number;
    md: number;
    lg: number;
    xl: number;
  };
} 