export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.4"
  }
  public: {
    Tables: {
      admin_notifications: {
        Row: {
          admin_id: string | null
          created_at: string
          id: string
          message: string
          metadata: Json | null
          priority: string
          read_at: string | null
          status: string
          title: string
          type: string
        }
        Insert: {
          admin_id?: string | null
          created_at?: string
          id?: string
          message: string
          metadata?: Json | null
          priority?: string
          read_at?: string | null
          status?: string
          title: string
          type?: string
        }
        Update: {
          admin_id?: string | null
          created_at?: string
          id?: string
          message?: string
          metadata?: Json | null
          priority?: string
          read_at?: string | null
          status?: string
          title?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_notifications_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_roles: {
        Row: {
          created_at: string
          created_by: string | null
          description: string | null
          display_name: string
          id: string
          is_active: boolean
          is_system_role: boolean
          permissions: Json
          role_name: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          display_name: string
          id?: string
          is_active?: boolean
          is_system_role?: boolean
          permissions?: Json
          role_name: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          display_name?: string
          id?: string
          is_active?: boolean
          is_system_role?: boolean
          permissions?: Json
          role_name?: string
          updated_at?: string
        }
        Relationships: []
      }
      admin_sessions: {
        Row: {
          admin_id: string
          created_at: string
          expires_at: string
          id: string
          ip_address: unknown | null
          session_token: string
          user_agent: string | null
        }
        Insert: {
          admin_id: string
          created_at?: string
          expires_at: string
          id?: string
          ip_address?: unknown | null
          session_token: string
          user_agent?: string | null
        }
        Update: {
          admin_id?: string
          created_at?: string
          expires_at?: string
          id?: string
          ip_address?: unknown | null
          session_token?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_sessions_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_users: {
        Row: {
          avatar_url: string | null
          created_at: string
          email: string
          full_name: string | null
          id: string
          is_active: boolean
          last_login: string | null
          password_hash: string
          role: string
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          email: string
          full_name?: string | null
          id?: string
          is_active?: boolean
          last_login?: string | null
          password_hash: string
          role?: string
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          email?: string
          full_name?: string | null
          id?: string
          is_active?: boolean
          last_login?: string | null
          password_hash?: string
          role?: string
          updated_at?: string
        }
        Relationships: []
      }
      api_configurations: {
        Row: {
          api_key_encrypted: string | null
          configuration_name: string
          created_at: string
          created_by: string | null
          endpoint_url: string | null
          id: string
          is_active: boolean
          is_sandbox: boolean
          last_tested_at: string | null
          service_name: string
          settings: Json | null
          test_status: string | null
          updated_at: string
        }
        Insert: {
          api_key_encrypted?: string | null
          configuration_name: string
          created_at?: string
          created_by?: string | null
          endpoint_url?: string | null
          id?: string
          is_active?: boolean
          is_sandbox?: boolean
          last_tested_at?: string | null
          service_name: string
          settings?: Json | null
          test_status?: string | null
          updated_at?: string
        }
        Update: {
          api_key_encrypted?: string | null
          configuration_name?: string
          created_at?: string
          created_by?: string | null
          endpoint_url?: string | null
          id?: string
          is_active?: boolean
          is_sandbox?: boolean
          last_tested_at?: string | null
          service_name?: string
          settings?: Json | null
          test_status?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      audit_logs: {
        Row: {
          action_type: string
          additional_data: Json | null
          admin_id: string
          created_at: string
          error_message: string | null
          id: string
          ip_address: unknown | null
          new_values: Json | null
          old_values: Json | null
          resource_id: string | null
          resource_type: string
          session_id: string | null
          success: boolean
          user_agent: string | null
        }
        Insert: {
          action_type: string
          additional_data?: Json | null
          admin_id: string
          created_at?: string
          error_message?: string | null
          id?: string
          ip_address?: unknown | null
          new_values?: Json | null
          old_values?: Json | null
          resource_id?: string | null
          resource_type: string
          session_id?: string | null
          success?: boolean
          user_agent?: string | null
        }
        Update: {
          action_type?: string
          additional_data?: Json | null
          admin_id?: string
          created_at?: string
          error_message?: string | null
          id?: string
          ip_address?: unknown | null
          new_values?: Json | null
          old_values?: Json | null
          resource_id?: string | null
          resource_type?: string
          session_id?: string | null
          success?: boolean
          user_agent?: string | null
        }
        Relationships: []
      }
      auto_moderation_rules: {
        Row: {
          action: string
          confidence_threshold: number | null
          content_types: Json
          created_at: string
          created_by: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          rule_config: Json
          rule_type: string
          updated_at: string
        }
        Insert: {
          action?: string
          confidence_threshold?: number | null
          content_types?: Json
          created_at?: string
          created_by: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          rule_config?: Json
          rule_type: string
          updated_at?: string
        }
        Update: {
          action?: string
          confidence_threshold?: number | null
          content_types?: Json
          created_at?: string
          created_by?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          rule_config?: Json
          rule_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "auto_moderation_rules_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      banned_users: {
        Row: {
          appeal_notes: string | null
          ban_type: string
          banned_by: string
          created_at: string
          description: string | null
          expires_at: string | null
          id: string
          is_active: boolean
          reason: string
          updated_at: string
          user_id: string
        }
        Insert: {
          appeal_notes?: string | null
          ban_type?: string
          banned_by: string
          created_at?: string
          description?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          reason: string
          updated_at?: string
          user_id: string
        }
        Update: {
          appeal_notes?: string | null
          ban_type?: string
          banned_by?: string
          created_at?: string
          description?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          reason?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "banned_users_banned_by_fkey"
            columns: ["banned_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "banned_users_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_extensions: {
        Row: {
          extended_at: string | null
          match_id: string
        }
        Insert: {
          extended_at?: string | null
          match_id: string
        }
        Update: {
          extended_at?: string | null
          match_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_extensions_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: true
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
        ]
      }
      content_analytics: {
        Row: {
          avg_conversation_length: unknown | null
          avg_messages_per_conversation: number | null
          created_at: string
          date: string
          id: string
          image_messages: number
          peak_activity_hour: number | null
          popular_features: Json | null
          stories_posted: number
          stories_viewed: number
          text_messages: number
          total_messages: number
          video_messages: number
        }
        Insert: {
          avg_conversation_length?: unknown | null
          avg_messages_per_conversation?: number | null
          created_at?: string
          date: string
          id?: string
          image_messages?: number
          peak_activity_hour?: number | null
          popular_features?: Json | null
          stories_posted?: number
          stories_viewed?: number
          text_messages?: number
          total_messages?: number
          video_messages?: number
        }
        Update: {
          avg_conversation_length?: unknown | null
          avg_messages_per_conversation?: number | null
          created_at?: string
          date?: string
          id?: string
          image_messages?: number
          peak_activity_hour?: number | null
          popular_features?: Json | null
          stories_posted?: number
          stories_viewed?: number
          text_messages?: number
          total_messages?: number
          video_messages?: number
        }
        Relationships: []
      }
      content_moderation_queue: {
        Row: {
          auto_flagged: boolean
          confidence_score: number | null
          content_id: string
          content_type: string
          created_at: string
          description: string | null
          id: string
          priority: string
          reason: string
          report_id: string | null
          reported_user_id: string
          reporter_user_id: string
          resolution_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
        }
        Insert: {
          auto_flagged?: boolean
          confidence_score?: number | null
          content_id: string
          content_type: string
          created_at?: string
          description?: string | null
          id?: string
          priority?: string
          reason: string
          report_id?: string | null
          reported_user_id: string
          reporter_user_id: string
          resolution_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          auto_flagged?: boolean
          confidence_score?: number | null
          content_id?: string
          content_type?: string
          created_at?: string
          description?: string | null
          id?: string
          priority?: string
          reason?: string
          report_id?: string | null
          reported_user_id?: string
          reporter_user_id?: string
          resolution_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "content_moderation_queue_report_id_fkey"
            columns: ["report_id"]
            isOneToOne: false
            referencedRelation: "reports"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "content_moderation_queue_reported_user_id_fkey"
            columns: ["reported_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "content_moderation_queue_reporter_user_id_fkey"
            columns: ["reporter_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "content_moderation_queue_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_metadata: {
        Row: {
          avg_response_time: unknown | null
          created_at: string
          flagged_at: string | null
          flagged_by: string | null
          flagged_reason: string | null
          id: string
          is_flagged: boolean
          last_activity: string | null
          match_id: string
          message_count: number
          risk_score: number
          sentiment_score: number | null
          updated_at: string
        }
        Insert: {
          avg_response_time?: unknown | null
          created_at?: string
          flagged_at?: string | null
          flagged_by?: string | null
          flagged_reason?: string | null
          id?: string
          is_flagged?: boolean
          last_activity?: string | null
          match_id: string
          message_count?: number
          risk_score?: number
          sentiment_score?: number | null
          updated_at?: string
        }
        Update: {
          avg_response_time?: unknown | null
          created_at?: string
          flagged_at?: string | null
          flagged_by?: string | null
          flagged_reason?: string | null
          id?: string
          is_flagged?: boolean
          last_activity?: string | null
          match_id?: string
          message_count?: number
          risk_score?: number
          sentiment_score?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_metadata_flagged_by_fkey"
            columns: ["flagged_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversation_metadata_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: true
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
        ]
      }
      feature_flags: {
        Row: {
          created_at: string
          created_by: string | null
          description: string | null
          end_date: string | null
          flag_key: string
          flag_name: string
          id: string
          is_enabled: boolean
          rollout_percentage: number | null
          start_date: string | null
          target_audience: Json | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          end_date?: string | null
          flag_key: string
          flag_name: string
          id?: string
          is_enabled?: boolean
          rollout_percentage?: number | null
          start_date?: string | null
          target_audience?: Json | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          end_date?: string | null
          flag_key?: string
          flag_name?: string
          id?: string
          is_enabled?: boolean
          rollout_percentage?: number | null
          start_date?: string | null
          target_audience?: Json | null
          updated_at?: string
        }
        Relationships: []
      }
      maintenance_schedules: {
        Row: {
          affected_services: Json | null
          created_at: string
          created_by: string
          description: string | null
          end_time: string
          id: string
          maintenance_type: string
          notification_sent: boolean
          severity_level: string
          start_time: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          affected_services?: Json | null
          created_at?: string
          created_by: string
          description?: string | null
          end_time: string
          id?: string
          maintenance_type: string
          notification_sent?: boolean
          severity_level: string
          start_time: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          affected_services?: Json | null
          created_at?: string
          created_by?: string
          description?: string | null
          end_time?: string
          id?: string
          maintenance_type?: string
          notification_sent?: boolean
          severity_level?: string
          start_time?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      matches: {
        Row: {
          created_at: string | null
          id: string
          initiator_id: string | null
          matched_at: string | null
          status: string | null
          unmatched_at: string | null
          user_id_1: string
          user_id_2: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          initiator_id?: string | null
          matched_at?: string | null
          status?: string | null
          unmatched_at?: string | null
          user_id_1: string
          user_id_2: string
        }
        Update: {
          created_at?: string | null
          id?: string
          initiator_id?: string | null
          matched_at?: string | null
          status?: string | null
          unmatched_at?: string | null
          user_id_1?: string
          user_id_2?: string
        }
        Relationships: []
      }
      message_analytics: {
        Row: {
          average_response_time: unknown | null
          created_at: string
          date: string
          flagged_messages: number
          id: string
          total_messages: number
          unique_conversations: number
        }
        Insert: {
          average_response_time?: unknown | null
          created_at?: string
          date: string
          flagged_messages?: number
          id?: string
          total_messages?: number
          unique_conversations?: number
        }
        Update: {
          average_response_time?: unknown | null
          created_at?: string
          date?: string
          flagged_messages?: number
          id?: string
          total_messages?: number
          unique_conversations?: number
        }
        Relationships: []
      }
      message_flags: {
        Row: {
          auto_detected: boolean
          confidence_score: number | null
          created_at: string
          flag_type: string
          flagged_by: string | null
          id: string
          message_id: string
          reason: string
          resolution_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          severity: string
          status: string
          updated_at: string
        }
        Insert: {
          auto_detected?: boolean
          confidence_score?: number | null
          created_at?: string
          flag_type: string
          flagged_by?: string | null
          id?: string
          message_id: string
          reason: string
          resolution_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          severity?: string
          status?: string
          updated_at?: string
        }
        Update: {
          auto_detected?: boolean
          confidence_score?: number | null
          created_at?: string
          flag_type?: string
          flagged_by?: string | null
          id?: string
          message_id?: string
          reason?: string
          resolution_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          severity?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_flags_flagged_by_fkey"
            columns: ["flagged_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_flags_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_flags_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          content: string
          created_at: string | null
          id: string
          is_read: boolean | null
          is_story_reply: boolean | null
          match_id: string
          message_type: string | null
          sender_id: string
          story_id: string | null
          story_user_name: string | null
        }
        Insert: {
          content: string
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          is_story_reply?: boolean | null
          match_id: string
          message_type?: string | null
          sender_id: string
          story_id?: string | null
          story_user_name?: string | null
        }
        Update: {
          content?: string
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          is_story_reply?: boolean | null
          match_id?: string
          message_type?: string | null
          sender_id?: string
          story_id?: string | null
          story_user_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_messages_story_id"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "stories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_match_fk"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
        ]
      }
      moderation_actions: {
        Row: {
          action_type: string
          admin_id: string
          created_at: string
          duration_hours: number | null
          id: string
          notes: string | null
          queue_item_id: string
          reason: string
          target_user_id: string
        }
        Insert: {
          action_type: string
          admin_id: string
          created_at?: string
          duration_hours?: number | null
          id?: string
          notes?: string | null
          queue_item_id: string
          reason: string
          target_user_id: string
        }
        Update: {
          action_type?: string
          admin_id?: string
          created_at?: string
          duration_hours?: number | null
          id?: string
          notes?: string | null
          queue_item_id?: string
          reason?: string
          target_user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "moderation_actions_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderation_actions_queue_item_id_fkey"
            columns: ["queue_item_id"]
            isOneToOne: false
            referencedRelation: "content_moderation_queue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderation_actions_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      moderation_logs: {
        Row: {
          action_type: string
          admin_id: string
          created_at: string
          details: Json | null
          id: string
          ip_address: unknown | null
          target_id: string
          target_type: string
          user_agent: string | null
        }
        Insert: {
          action_type: string
          admin_id: string
          created_at?: string
          details?: Json | null
          id?: string
          ip_address?: unknown | null
          target_id: string
          target_type: string
          user_agent?: string | null
        }
        Update: {
          action_type?: string
          admin_id?: string
          created_at?: string
          details?: Json | null
          id?: string
          ip_address?: unknown | null
          target_id?: string
          target_type?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "moderation_logs_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_templates: {
        Row: {
          category: string
          content: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          language_code: string | null
          subject: string | null
          template_name: string
          template_type: string
          updated_at: string
          variables: Json | null
        }
        Insert: {
          category: string
          content: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          language_code?: string | null
          subject?: string | null
          template_name: string
          template_type: string
          updated_at?: string
          variables?: Json | null
        }
        Update: {
          category?: string
          content?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          language_code?: string | null
          subject?: string | null
          template_name?: string
          template_type?: string
          updated_at?: string
          variables?: Json | null
        }
        Relationships: []
      }
      payment_methods: {
        Row: {
          card_brand: string | null
          card_last4: string | null
          created_at: string
          expiry_month: number | null
          expiry_year: number | null
          id: string
          is_default: boolean
          metadata: Json | null
          provider: string
          provider_payment_method_id: string | null
          type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          card_brand?: string | null
          card_last4?: string | null
          created_at?: string
          expiry_month?: number | null
          expiry_year?: number | null
          id?: string
          is_default?: boolean
          metadata?: Json | null
          provider?: string
          provider_payment_method_id?: string | null
          type?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          card_brand?: string | null
          card_last4?: string | null
          created_at?: string
          expiry_month?: number | null
          expiry_year?: number | null
          id?: string
          is_default?: boolean
          metadata?: Json | null
          provider?: string
          provider_payment_method_id?: string | null
          type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      payment_transactions: {
        Row: {
          amount: number
          created_at: string
          currency: string
          failure_reason: string | null
          id: string
          metadata: Json | null
          payment_method: string
          razorpay_order_id: string | null
          razorpay_payment_id: string | null
          status: string
          subscription_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          failure_reason?: string | null
          id?: string
          metadata?: Json | null
          payment_method?: string
          razorpay_order_id?: string | null
          razorpay_payment_id?: string | null
          status?: string
          subscription_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          failure_reason?: string | null
          id?: string
          metadata?: Json | null
          payment_method?: string
          razorpay_order_id?: string | null
          razorpay_payment_id?: string | null
          status?: string
          subscription_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_transactions_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "user_subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_analytics: {
        Row: {
          active_users: number
          avg_session_duration: unknown | null
          bounce_rate: number | null
          created_at: string
          daily_active_users: number
          date: string
          id: string
          monthly_active_users: number
          new_users: number
          total_users: number
          user_retention_rate: number | null
          weekly_active_users: number
        }
        Insert: {
          active_users?: number
          avg_session_duration?: unknown | null
          bounce_rate?: number | null
          created_at?: string
          daily_active_users?: number
          date: string
          id?: string
          monthly_active_users?: number
          new_users?: number
          total_users?: number
          user_retention_rate?: number | null
          weekly_active_users?: number
        }
        Update: {
          active_users?: number
          avg_session_duration?: unknown | null
          bounce_rate?: number | null
          created_at?: string
          daily_active_users?: number
          date?: string
          id?: string
          monthly_active_users?: number
          new_users?: number
          total_users?: number
          user_retention_rate?: number | null
          weekly_active_users?: number
        }
        Relationships: []
      }
      profiles: {
        Row: {
          age: number
          created_at: string | null
          description: string | null
          distance: string | null
          gender: string | null
          hobbies: Json | null
          id: string
          image_urls: Json | null
          is_active: boolean | null
          last_seen: string | null
          location: string | null
          name: string
          photos: Json | null
        }
        Insert: {
          age: number
          created_at?: string | null
          description?: string | null
          distance?: string | null
          gender?: string | null
          hobbies?: Json | null
          id?: string
          image_urls?: Json | null
          is_active?: boolean | null
          last_seen?: string | null
          location?: string | null
          name: string
          photos?: Json | null
        }
        Update: {
          age?: number
          created_at?: string | null
          description?: string | null
          distance?: string | null
          gender?: string | null
          hobbies?: Json | null
          id?: string
          image_urls?: Json | null
          is_active?: boolean | null
          last_seen?: string | null
          location?: string | null
          name?: string
          photos?: Json | null
        }
        Relationships: []
      }
      real_time_metrics: {
        Row: {
          id: string
          metadata: Json | null
          metric_type: string
          metric_value: number
          timestamp: string
        }
        Insert: {
          id?: string
          metadata?: Json | null
          metric_type: string
          metric_value: number
          timestamp?: string
        }
        Update: {
          id?: string
          metadata?: Json | null
          metric_type?: string
          metric_value?: number
          timestamp?: string
        }
        Relationships: []
      }
      report_exports: {
        Row: {
          admin_id: string
          completed_at: string | null
          created_at: string
          date_range_end: string
          date_range_start: string
          export_format: string
          file_url: string | null
          id: string
          parameters: Json | null
          report_type: string
          status: string
        }
        Insert: {
          admin_id: string
          completed_at?: string | null
          created_at?: string
          date_range_end: string
          date_range_start: string
          export_format: string
          file_url?: string | null
          id?: string
          parameters?: Json | null
          report_type: string
          status?: string
        }
        Update: {
          admin_id?: string
          completed_at?: string | null
          created_at?: string
          date_range_end?: string
          date_range_start?: string
          export_format?: string
          file_url?: string | null
          id?: string
          parameters?: Json | null
          report_type?: string
          status?: string
        }
        Relationships: []
      }
      reports: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          reason: string
          reported_id: string
          reporter_id: string
          status: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          reason: string
          reported_id: string
          reporter_id: string
          status?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          reason?: string
          reported_id?: string
          reporter_id?: string
          status?: string | null
        }
        Relationships: []
      }
      revenue_analytics: {
        Row: {
          active_subscriptions: number
          cancelled_subscriptions: number
          churn_rate: number | null
          created_at: string
          date: string
          id: string
          mrr: number
          new_subscriptions: number
          subscription_revenue: number
          total_revenue: number
        }
        Insert: {
          active_subscriptions?: number
          cancelled_subscriptions?: number
          churn_rate?: number | null
          created_at?: string
          date: string
          id?: string
          mrr?: number
          new_subscriptions?: number
          subscription_revenue?: number
          total_revenue?: number
        }
        Update: {
          active_subscriptions?: number
          cancelled_subscriptions?: number
          churn_rate?: number | null
          created_at?: string
          date?: string
          id?: string
          mrr?: number
          new_subscriptions?: number
          subscription_revenue?: number
          total_revenue?: number
        }
        Relationships: []
      }
      stories: {
        Row: {
          content: string | null
          created_at: string | null
          expires_at: string
          id: string
          media_type: string | null
          media_url: string | null
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string | null
          expires_at: string
          id?: string
          media_type?: string | null
          media_url?: string | null
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string | null
          expires_at?: string
          id?: string
          media_type?: string | null
          media_url?: string | null
          user_id?: string
        }
        Relationships: []
      }
      subscription_events: {
        Row: {
          created_at: string
          event_data: Json | null
          event_type: string
          id: string
          subscription_id: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          event_data?: Json | null
          event_type: string
          id?: string
          subscription_id?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          event_data?: Json | null
          event_type?: string
          id?: string
          subscription_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscription_events_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "user_subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
      subscription_plans: {
        Row: {
          created_at: string
          description: string | null
          features: Json
          id: string
          is_active: boolean
          name: string
          price_monthly: number
          price_yearly: number | null
          sort_order: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          features?: Json
          id?: string
          is_active?: boolean
          name: string
          price_monthly: number
          price_yearly?: number | null
          sort_order?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          features?: Json
          id?: string
          is_active?: boolean
          name?: string
          price_monthly?: number
          price_yearly?: number | null
          sort_order?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      swipes: {
        Row: {
          action: string
          created_at: string | null
          id: string
          swiped_id: string
          swiper_id: string
        }
        Insert: {
          action: string
          created_at?: string | null
          id?: string
          swiped_id: string
          swiper_id: string
        }
        Update: {
          action?: string
          created_at?: string | null
          id?: string
          swiped_id?: string
          swiper_id?: string
        }
        Relationships: []
      }
      system_settings: {
        Row: {
          category: string
          created_at: string
          data_type: string
          description: string | null
          id: string
          is_encrypted: boolean
          is_public: boolean
          last_modified_by: string | null
          setting_key: string
          setting_value: Json
          updated_at: string
          validation_rules: Json | null
        }
        Insert: {
          category: string
          created_at?: string
          data_type: string
          description?: string | null
          id?: string
          is_encrypted?: boolean
          is_public?: boolean
          last_modified_by?: string | null
          setting_key: string
          setting_value: Json
          updated_at?: string
          validation_rules?: Json | null
        }
        Update: {
          category?: string
          created_at?: string
          data_type?: string
          description?: string | null
          id?: string
          is_encrypted?: boolean
          is_public?: boolean
          last_modified_by?: string | null
          setting_key?: string
          setting_value?: Json
          updated_at?: string
          validation_rules?: Json | null
        }
        Relationships: []
      }
      user_analytics: {
        Row: {
          active_users: number
          created_at: string
          date: string
          id: string
          matches_created: number
          messages_sent: number
          new_signups: number
          premium_users: number
          revenue: number
          total_users: number
        }
        Insert: {
          active_users?: number
          created_at?: string
          date: string
          id?: string
          matches_created?: number
          messages_sent?: number
          new_signups?: number
          premium_users?: number
          revenue?: number
          total_users?: number
        }
        Update: {
          active_users?: number
          created_at?: string
          date?: string
          id?: string
          matches_created?: number
          messages_sent?: number
          new_signups?: number
          premium_users?: number
          revenue?: number
          total_users?: number
        }
        Relationships: []
      }
      user_engagement_metrics: {
        Row: {
          actions_taken: number
          created_at: string
          date: string
          id: string
          last_active: string | null
          matches_made: number
          messages_sent: number
          pages_viewed: number
          profiles_viewed: number
          sessions_count: number
          swipes_made: number
          total_session_time: unknown | null
          user_id: string
        }
        Insert: {
          actions_taken?: number
          created_at?: string
          date: string
          id?: string
          last_active?: string | null
          matches_made?: number
          messages_sent?: number
          pages_viewed?: number
          profiles_viewed?: number
          sessions_count?: number
          swipes_made?: number
          total_session_time?: unknown | null
          user_id: string
        }
        Update: {
          actions_taken?: number
          created_at?: string
          date?: string
          id?: string
          last_active?: string | null
          matches_made?: number
          messages_sent?: number
          pages_viewed?: number
          profiles_viewed?: number
          sessions_count?: number
          swipes_made?: number
          total_session_time?: unknown | null
          user_id?: string
        }
        Relationships: []
      }
      user_subscriptions: {
        Row: {
          canceled_at: string | null
          created_at: string
          current_period_end: string
          current_period_start: string
          id: string
          plan_id: string
          status: string
          stripe_subscription_id: string | null
          trial_end: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          canceled_at?: string | null
          created_at?: string
          current_period_end: string
          current_period_start: string
          id?: string
          plan_id: string
          status?: string
          stripe_subscription_id?: string | null
          trial_end?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          canceled_at?: string | null
          created_at?: string
          current_period_end?: string
          current_period_start?: string
          id?: string
          plan_id?: string
          status?: string
          stripe_subscription_id?: string | null
          trial_end?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_subscriptions_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "subscription_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_subscriptions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      calculate_distance: {
        Args: { lat1: number; lat2: number; lon1: number; lon2: number }
        Returns: number
      }
      extend_chat: {
        Args: { p_match_id: string }
        Returns: undefined
      }
      handle_swipe: {
        Args: { p_action: string; p_swiped_id: string }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
