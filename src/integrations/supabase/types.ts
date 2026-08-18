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
    PostgrestVersion: "14.15"
  }
  public: {
    Tables: {
      challenges: {
        Row: {
          created_at: string
          description: string | null
          id: string
          order_index: number
          points: number
          stage_id: string
          title: string
          type: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          order_index?: number
          points?: number
          stage_id: string
          title: string
          type?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          order_index?: number
          points?: number
          stage_id?: string
          title?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "challenges_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          display_name: string | null
          id: string
        }
        Insert: {
          created_at?: string
          display_name?: string | null
          id: string
        }
        Update: {
          created_at?: string
          display_name?: string | null
          id?: string
        }
        Relationships: []
      }
      quiz_questions: {
        Row: {
          challenge_id: string
          correct_answer: number
          id: string
          options: Json
          order_index: number
          points: number
          question: string
        }
        Insert: {
          challenge_id: string
          correct_answer: number
          id?: string
          options: Json
          order_index?: number
          points?: number
          question: string
        }
        Update: {
          challenge_id?: string
          correct_answer?: number
          id?: string
          options?: Json
          order_index?: number
          points?: number
          question?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_questions_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
        ]
      }
      race_sessions: {
        Row: {
          duration_seconds: number | null
          end_time: string | null
          id: string
          stage_id: string | null
          start_time: string
          team_id: string
        }
        Insert: {
          duration_seconds?: number | null
          end_time?: string | null
          id?: string
          stage_id?: string | null
          start_time?: string
          team_id: string
        }
        Update: {
          duration_seconds?: number | null
          end_time?: string | null
          id?: string
          stage_id?: string | null
          start_time?: string
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "race_sessions_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "race_sessions_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "leaderboard"
            referencedColumns: ["team_id"]
          },
          {
            foreignKeyName: "race_sessions_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      score_events: {
        Row: {
          created_at: string
          id: string
          points: number
          reason: string
          team_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          points: number
          reason: string
          team_id: string
        }
        Update: {
          created_at?: string
          id?: string
          points?: number
          reason?: string
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "score_events_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "leaderboard"
            referencedColumns: ["team_id"]
          },
          {
            foreignKeyName: "score_events_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      stages: {
        Row: {
          created_at: string
          description: string | null
          id: string
          location: string | null
          order_index: number
          status: string
          title: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          location?: string | null
          order_index?: number
          status?: string
          title: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          location?: string | null
          order_index?: number
          status?: string
          title?: string
        }
        Relationships: []
      }
      team_answers: {
        Row: {
          correct: boolean
          created_at: string
          id: string
          question_id: string
          selected_answer: number
          team_id: string
        }
        Insert: {
          correct: boolean
          created_at?: string
          id?: string
          question_id: string
          selected_answer: number
          team_id: string
        }
        Update: {
          correct?: boolean
          created_at?: string
          id?: string
          question_id?: string
          selected_answer?: number
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "team_answers_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "quiz_questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "team_answers_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "quiz_questions_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "team_answers_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "leaderboard"
            referencedColumns: ["team_id"]
          },
          {
            foreignKeyName: "team_answers_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_media: {
        Row: {
          challenge_id: string | null
          created_at: string
          id: string
          latitude: number | null
          longitude: number | null
          team_id: string
          type: string
          url: string
        }
        Insert: {
          challenge_id?: string | null
          created_at?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          team_id: string
          type?: string
          url: string
        }
        Update: {
          challenge_id?: string | null
          created_at?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          team_id?: string
          type?: string
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "team_media_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "team_media_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "leaderboard"
            referencedColumns: ["team_id"]
          },
          {
            foreignKeyName: "team_media_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_members: {
        Row: {
          created_at: string
          id: string
          name: string
          team_id: string
          user_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          team_id: string
          user_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          team_id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "team_members_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "leaderboard"
            referencedColumns: ["team_id"]
          },
          {
            foreignKeyName: "team_members_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_progress: {
        Row: {
          challenge_id: string
          completed_at: string | null
          id: string
          started_at: string
          status: string
          team_id: string
        }
        Insert: {
          challenge_id: string
          completed_at?: string | null
          id?: string
          started_at?: string
          status?: string
          team_id: string
        }
        Update: {
          challenge_id?: string
          completed_at?: string | null
          id?: string
          started_at?: string
          status?: string
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "team_progress_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "team_progress_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "leaderboard"
            referencedColumns: ["team_id"]
          },
          {
            foreignKeyName: "team_progress_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      teams: {
        Row: {
          avatar_url: string | null
          color: string
          created_at: string
          id: string
          motto: string | null
          nome_squadra: string
          name?: string
          owner_id: string
        }
        Insert: {
          avatar_url?: string | null
          color?: string
          created_at?: string
          id?: string
          motto?: string | null
          nome_squadra: string
          name?: string
          owner_id?: string
        }
        Update: {
          avatar_url?: string | null
          color?: string
          created_at?: string
          id?: string
          motto?: string | null
          nome_squadra?: string
          name?: string
          owner_id?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      leaderboard: {
        Row: {
          avatar_url: string | null
          color: string | null
          completed_challenges: number | null
          last_completion: string | null
          motto: string | null
          name: string | null
          team_id: string | null
          total_duration_seconds: number | null
          total_points: number | null
        }
        Insert: {
          avatar_url?: string | null
          color?: string | null
          completed_challenges?: never
          last_completion?: never
          motto?: string | null
          name?: string | null
          team_id?: string | null
          total_duration_seconds?: never
          total_points?: never
        }
        Update: {
          avatar_url?: string | null
          color?: string | null
          completed_challenges?: never
          last_completion?: never
          motto?: string | null
          name?: string | null
          team_id?: string | null
          total_duration_seconds?: never
          total_points?: never
        }
        Relationships: []
      }
      quiz_questions_public: {
        Row: {
          challenge_id: string | null
          id: string | null
          options: Json | null
          order_index: number | null
          points: number | null
          question: string | null
        }
        Insert: {
          challenge_id?: string | null
          id?: string | null
          options?: Json | null
          order_index?: number | null
          points?: number | null
          question?: string | null
        }
        Update: {
          challenge_id?: string | null
          id?: string | null
          options?: Json | null
          order_index?: number | null
          points?: number | null
          question?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quiz_questions_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      complete_challenge: { Args: { p_challenge: string }; Returns: Json }
      current_team_id: { Args: never; Returns: string }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_my_team: { Args: { _team_id: string }; Returns: boolean }
      start_challenge: { Args: { p_challenge: string }; Returns: undefined }
      submit_quiz_answer: {
        Args: { p_question: string; p_selected: number }
        Returns: Json
      }
    }
    Enums: {
      app_role: "admin" | "player"
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
    Enums: {
      app_role: ["admin", "player"],
    },
  },
} as const
