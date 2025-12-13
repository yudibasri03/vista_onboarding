export type ClientStatus = 'pending' | 'verified' | 'approved' | 'rejected' | 'active';
export type OnboardingStatus = 'not_started' | 'in_progress' | 'completed' | 'skipped';
export type DocumentStatus = 'pending' | 'verified' | 'rejected';
export type NotificationType = 'info' | 'success' | 'warning' | 'error';

export interface Client {
  id: string;
  user_id: string | null;
  company_name: string;
  pic_name: string;
  email: string;
  phone: string;
  address: string;
  business_type: string;
  status: ClientStatus;
  created_at: string;
  updated_at: string;
}

export interface OnboardingStep {
  id: string;
  step_number: number;
  title: string;
  description: string;
  is_required: boolean;
  created_at: string;
}

export interface OnboardingProgress {
  id: string;
  client_id: string;
  step_id: string;
  status: OnboardingStatus;
  notes: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
  step?: OnboardingStep;
}

export interface Document {
  id: string;
  client_id: string;
  document_type: string;
  file_name: string;
  file_url: string;
  status: DocumentStatus;
  uploaded_at: string;
  verified_at: string | null;
  verified_by: string | null;
}

export interface Notification {
  id: string;
  user_id: string;
  title: string;
  message: string;
  type: NotificationType;
  is_read: boolean;
  created_at: string;
}
