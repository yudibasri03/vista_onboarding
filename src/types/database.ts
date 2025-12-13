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
        }
        Insert: {
          user_id: string
          role?: 'admin' | 'client'
          created_at?: string
        }
        Update: {
          user_id?: string
          role?: 'admin' | 'client'
          created_at?: string
        }
      }
    }
  }
}
