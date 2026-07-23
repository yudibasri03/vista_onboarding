export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      clients: {
        Row: {
          id: string
          user_id: string | null
          company_name: string
          pic_name: string
          email: string
          phone: string
          address: string
          business_type: string
          status: string
          created_at: string
          updated_at: string
          full_name: string | null
          whatsapp: string | null
          occupation: string | null
          position: string | null
          ktp_url: string | null
          product_type: 'ea_trading' | 'bimbel_prop' | 'bimbel_only' | 'vip_membership' | 'vip_plus_membership' | null
          product_config: Json | null
          risk_profile: 'aggressive' | 'moderate' | 'conservative' | null
          consent_data_accuracy: boolean
          consent_risk_understanding: boolean
          consent_verification_process: boolean
          registration_completed_at: string | null
        }
        Insert: {
          id?: string
          user_id?: string | null
          company_name: string
          pic_name: string
          email: string
          phone: string
          address: string
          business_type: string
          status?: string
          created_at?: string
          updated_at?: string
          full_name?: string | null
          whatsapp?: string | null
          occupation?: string | null
          position?: string | null
          ktp_url?: string | null
          product_type?: 'ea_trading' | 'bimbel_prop' | 'bimbel_only' | 'vip_membership' | 'vip_plus_membership' | null
          product_config?: Json | null
          risk_profile?: 'aggressive' | 'moderate' | 'conservative' | null
          consent_data_accuracy?: boolean
          consent_risk_understanding?: boolean
          consent_verification_process?: boolean
          registration_completed_at?: string | null
        }
        Update: {
          id?: string
          user_id?: string | null
          company_name?: string
          pic_name?: string
          email?: string
          phone?: string
          address?: string
          business_type?: string
          status?: string
          created_at?: string
          updated_at?: string
          full_name?: string | null
          whatsapp?: string | null
          occupation?: string | null
          position?: string | null
          ktp_url?: string | null
          product_type?: 'ea_trading' | 'bimbel_prop' | 'bimbel_only' | 'vip_membership' | 'vip_plus_membership' | null
          product_config?: Json | null
          risk_profile?: 'aggressive' | 'moderate' | 'conservative' | null
          consent_data_accuracy?: boolean
          consent_risk_understanding?: boolean
          consent_verification_process?: boolean
          registration_completed_at?: string | null
        }
      }
      onboarding_steps: {
        Row: {
          id: string
          step_number: number
          title: string
          description: string
          is_required: boolean
          created_at: string
        }
        Insert: {
          id?: string
          step_number: number
          title: string
          description: string
          is_required?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          step_number?: number
          title?: string
          description?: string
          is_required?: boolean
          created_at?: string
        }
      }
      client_onboarding_progress: {
        Row: {
          id: string
          client_id: string
          step_id: string
          status: string
          notes: string | null
          completed_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          client_id: string
          step_id: string
          status?: string
          notes?: string | null
          completed_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          client_id?: string
          step_id?: string
          status?: string
          notes?: string | null
          completed_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      documents: {
        Row: {
          id: string
          client_id: string
          document_type: string
          file_name: string
          file_url: string
          status: string
          uploaded_at: string
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          id?: string
          client_id: string
          document_type: string
          file_name: string
          file_url: string
          status?: string
          uploaded_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          id?: string
          client_id?: string
          document_type?: string
          file_name?: string
          file_url?: string
          status?: string
          uploaded_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
      }
      notifications: {
        Row: {
          id: string
          user_id: string
          title: string
          message: string
          type: string
          is_read: boolean
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          message: string
          type?: string
          is_read?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          message?: string
          type?: string
          is_read?: boolean
          created_at?: string
        }
      }
      user_roles: {
        Row: {
          user_id: string
          role: 'admin' | 'client'
          created_at: string
          must_change_password: boolean
          last_password_change: string | null
        }
        Insert: {
          user_id: string
          role?: 'admin' | 'client'
          created_at?: string
          must_change_password?: boolean
          last_password_change?: string | null
        }
        Update: {
          user_id?: string
          role?: 'admin' | 'client'
          created_at?: string
          must_change_password?: boolean
          last_password_change?: string | null
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}
