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
    PostgrestVersion: "14.5"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
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
  public: {
    Tables: {
      activity_log: {
        Row: {
          created_at: string
          dettagli: Json | null
          id: string
          target_team_id: string | null
          team_id: string | null
          tipo_evento: string
        }
        Insert: {
          created_at?: string
          dettagli?: Json | null
          id?: string
          target_team_id?: string | null
          team_id?: string | null
          tipo_evento: string
        }
        Update: {
          created_at?: string
          dettagli?: Json | null
          id?: string
          target_team_id?: string | null
          team_id?: string | null
          tipo_evento?: string
        }
        Relationships: [
          {
            foreignKeyName: "activity_log_target_team_id_fkey"
            columns: ["target_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activity_log_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      boxe_matches: {
        Row: {
          challenge_id: string
          completed_at: string | null
          id: string
          is_special_bye: boolean
          match_index: number
          round: number
          stage_id: string | null
          status: string
          team1_id: string | null
          team2_id: string | null
          winner_id: string | null
        }
        Insert: {
          challenge_id: string
          completed_at?: string | null
          id?: string
          is_special_bye?: boolean
          match_index: number
          round: number
          stage_id?: string | null
          status?: string
          team1_id?: string | null
          team2_id?: string | null
          winner_id?: string | null
        }
        Update: {
          challenge_id?: string
          completed_at?: string | null
          id?: string
          is_special_bye?: boolean
          match_index?: number
          round?: number
          stage_id?: string | null
          status?: string
          team1_id?: string | null
          team2_id?: string | null
          winner_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "boxe_matches_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "boxe_matches_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "boxe_matches_team1_id_fkey"
            columns: ["team1_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "boxe_matches_team2_id_fkey"
            columns: ["team2_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "boxe_matches_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      cattiveria_ledger: {
        Row: {
          id: string
          marketplace_item_id: string | null
          motivo: string
          punti: number
          riferimento_transazione: string | null
          stage_id: string | null
          team_id: string
          timestamp: string
          tipo: string
        }
        Insert: {
          id?: string
          marketplace_item_id?: string | null
          motivo: string
          punti: number
          riferimento_transazione?: string | null
          stage_id?: string | null
          team_id: string
          timestamp?: string
          tipo: string
        }
        Update: {
          id?: string
          marketplace_item_id?: string | null
          motivo?: string
          punti?: number
          riferimento_transazione?: string | null
          stage_id?: string | null
          team_id?: string
          timestamp?: string
          tipo?: string
        }
        Relationships: [
          {
            foreignKeyName: "cattiveria_ledger_marketplace_item_id_fkey"
            columns: ["marketplace_item_id"]
            isOneToOne: false
            referencedRelation: "marketplace_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cattiveria_ledger_riferimento_transazione_fkey"
            columns: ["riferimento_transazione"]
            isOneToOne: false
            referencedRelation: "marketplace_transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cattiveria_ledger_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cattiveria_ledger_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      challenges: {
        Row: {
          configurazione: Json | null
          created_at: string
          descrizione: string | null
          id: string
          ordine_sfida: number
          punteggio_massimo: number
          stage_id: string
          tipo_sfida: string
          titolo: string
        }
        Insert: {
          configurazione?: Json | null
          created_at?: string
          descrizione?: string | null
          id?: string
          ordine_sfida: number
          punteggio_massimo?: number
          stage_id: string
          tipo_sfida: string
          titolo: string
        }
        Update: {
          configurazione?: Json | null
          created_at?: string
          descrizione?: string | null
          id?: string
          ordine_sfida?: number
          punteggio_massimo?: number
          stage_id?: string
          tipo_sfida?: string
          titolo?: string
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
      code_purchase_transactions: {
        Row: {
          buyer_team_id: string
          created_at: string
          digits_received: string
          id: string
          seller_team_id: string
          token_cost: number
        }
        Insert: {
          buyer_team_id: string
          created_at?: string
          digits_received: string
          id?: string
          seller_team_id: string
          token_cost: number
        }
        Update: {
          buyer_team_id?: string
          created_at?: string
          digits_received?: string
          id?: string
          seller_team_id?: string
          token_cost?: number
        }
        Relationships: [
          {
            foreignKeyName: "code_purchase_transactions_buyer_team_id_fkey"
            columns: ["buyer_team_id"]
            isOneToOne: true
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "code_purchase_transactions_seller_team_id_fkey"
            columns: ["seller_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      cornhole_matches: {
        Row: {
          challenge_id: string
          completed_at: string | null
          id: string
          is_special_bye: boolean
          match_index: number
          round: number
          stage_id: string | null
          status: string
          team1_id: string | null
          team2_id: string | null
          winner_id: string | null
        }
        Insert: {
          challenge_id: string
          completed_at?: string | null
          id?: string
          is_special_bye?: boolean
          match_index: number
          round: number
          stage_id?: string | null
          status?: string
          team1_id?: string | null
          team2_id?: string | null
          winner_id?: string | null
        }
        Update: {
          challenge_id?: string
          completed_at?: string | null
          id?: string
          is_special_bye?: boolean
          match_index?: number
          round?: number
          stage_id?: string | null
          status?: string
          team1_id?: string | null
          team2_id?: string | null
          winner_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "cornhole_matches_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cornhole_matches_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cornhole_matches_team1_id_fkey"
            columns: ["team1_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cornhole_matches_team2_id_fkey"
            columns: ["team2_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cornhole_matches_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      enigma_attempts: {
        Row: {
          answer: Json
          attempt_number: number
          challenge_id: string
          id: string
          is_correct: boolean
          submitted_at: string | null
          team_id: string
        }
        Insert: {
          answer: Json
          attempt_number: number
          challenge_id: string
          id?: string
          is_correct: boolean
          submitted_at?: string | null
          team_id: string
        }
        Update: {
          answer?: Json
          attempt_number?: number
          challenge_id?: string
          id?: string
          is_correct?: boolean
          submitted_at?: string | null
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "enigma_attempts_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "enigma_attempts_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      enigma_solutions: {
        Row: {
          challenge_id: string
          created_at: string | null
          id: string
          punteggio: number
          solution: Json
          solution_type: string
        }
        Insert: {
          challenge_id: string
          created_at?: string | null
          id?: string
          punteggio?: number
          solution: Json
          solution_type: string
        }
        Update: {
          challenge_id?: string
          created_at?: string | null
          id?: string
          punteggio?: number
          solution?: Json
          solution_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "enigma_solutions_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: true
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
        ]
      }
      game_final_code: {
        Row: {
          full_code: string
          id: string
          next_stage_destination: string
        }
        Insert: {
          full_code?: string
          id?: string
          next_stage_destination?: string
        }
        Update: {
          full_code?: string
          id?: string
          next_stage_destination?: string
        }
        Relationships: []
      }
      game_report: {
        Row: {
          calculated_at: string | null
          calculated_by: string | null
          calculated_snapshot: Json | null
          id: string
          published_at: string | null
          published_by: string | null
          snapshot: Json | null
          state: string
          status: string
          updated_at: string
        }
        Insert: {
          calculated_at?: string | null
          calculated_by?: string | null
          calculated_snapshot?: Json | null
          id?: string
          published_at?: string | null
          published_by?: string | null
          snapshot?: Json | null
          state?: string
          status?: string
          updated_at?: string
        }
        Update: {
          calculated_at?: string | null
          calculated_by?: string | null
          calculated_snapshot?: Json | null
          id?: string
          published_at?: string | null
          published_by?: string | null
          snapshot?: Json | null
          state?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      game_settings: {
        Row: {
          activated_at: string | null
          activated_by: string | null
          boxe_special_bye_team_id: string | null
          cornhole_special_bye_team_id: string | null
          id: string
          marketplace_active: boolean
          marketplace_visible: boolean
          race_ended_at: string | null
          race_started_at: string | null
          race_status: string | null
        }
        Insert: {
          activated_at?: string | null
          activated_by?: string | null
          boxe_special_bye_team_id?: string | null
          cornhole_special_bye_team_id?: string | null
          id?: string
          marketplace_active?: boolean
          marketplace_visible?: boolean
          race_ended_at?: string | null
          race_started_at?: string | null
          race_status?: string | null
        }
        Update: {
          activated_at?: string | null
          activated_by?: string | null
          boxe_special_bye_team_id?: string | null
          cornhole_special_bye_team_id?: string | null
          id?: string
          marketplace_active?: boolean
          marketplace_visible?: boolean
          race_ended_at?: string | null
          race_started_at?: string | null
          race_status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "game_settings_boxe_special_bye_team_id_fkey"
            columns: ["boxe_special_bye_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_settings_cornhole_special_bye_team_id_fkey"
            columns: ["cornhole_special_bye_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      jackpot_plays: {
        Row: {
          challenge_id: string | null
          delta_punti: number | null
          esito_moltiplicatore: number | null
          id: string
          puntata: number | null
          puntata_punti: number | null
          punteggio_attuale: number | null
          punteggio_precedente: number | null
          risultato: string | null
          simboli: string | null
          team_id: string
          timestamp: string
          variazione: number | null
        }
        Insert: {
          challenge_id?: string | null
          delta_punti?: number | null
          esito_moltiplicatore?: number | null
          id?: string
          puntata?: number | null
          puntata_punti?: number | null
          punteggio_attuale?: number | null
          punteggio_precedente?: number | null
          risultato?: string | null
          simboli?: string | null
          team_id: string
          timestamp?: string
          variazione?: number | null
        }
        Update: {
          challenge_id?: string | null
          delta_punti?: number | null
          esito_moltiplicatore?: number | null
          id?: string
          puntata?: number | null
          puntata_punti?: number | null
          punteggio_attuale?: number | null
          punteggio_precedente?: number | null
          risultato?: string | null
          simboli?: string | null
          team_id?: string
          timestamp?: string
          variazione?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "jackpot_plays_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "jackpot_plays_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      marketplace_items: {
        Row: {
          costo_token: number
          descrizione: string | null
          disponibile: boolean
          effetto: string | null
          icona: string | null
          id: string
          nome: string
          regole: Json | null
          tipo: string
        }
        Insert: {
          costo_token: number
          descrizione?: string | null
          disponibile?: boolean
          effetto?: string | null
          icona?: string | null
          id: string
          nome: string
          regole?: Json | null
          tipo: string
        }
        Update: {
          costo_token?: number
          descrizione?: string | null
          disponibile?: boolean
          effetto?: string | null
          icona?: string | null
          id?: string
          nome?: string
          regole?: Json | null
          tipo?: string
        }
        Relationships: []
      }
      marketplace_transactions: {
        Row: {
          challenge_id: string | null
          costo_token: number
          data_acquisto: string
          data_utilizzo: string | null
          dettagli: Json | null
          id: string
          marketplace_item_id: string
          stage_id: string | null
          stato: string
          target_team_id: string | null
          team_id: string
        }
        Insert: {
          challenge_id?: string | null
          costo_token: number
          data_acquisto?: string
          data_utilizzo?: string | null
          dettagli?: Json | null
          id?: string
          marketplace_item_id: string
          stage_id?: string | null
          stato?: string
          target_team_id?: string | null
          team_id: string
        }
        Update: {
          challenge_id?: string | null
          costo_token?: number
          data_acquisto?: string
          data_utilizzo?: string | null
          dettagli?: Json | null
          id?: string
          marketplace_item_id?: string
          stage_id?: string | null
          stato?: string
          target_team_id?: string | null
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "marketplace_transactions_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "marketplace_transactions_marketplace_item_id_fkey"
            columns: ["marketplace_item_id"]
            isOneToOne: false
            referencedRelation: "marketplace_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "marketplace_transactions_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "marketplace_transactions_target_team_id_fkey"
            columns: ["target_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "marketplace_transactions_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      posters: {
        Row: {
          active: boolean
          file_name: string
          id: string
          titolo: string
        }
        Insert: {
          active?: boolean
          file_name: string
          id: string
          titolo: string
        }
        Update: {
          active?: boolean
          file_name?: string
          id?: string
          titolo?: string
        }
        Relationships: []
      }
      quiz_questions: {
        Row: {
          challenge_id: string
          correct_answer_index: number
          created_at: string | null
          id: string
          options: Json
          order_index: number
          points: number
          question: string
        }
        Insert: {
          challenge_id: string
          correct_answer_index: number
          created_at?: string | null
          id?: string
          options: Json
          order_index: number
          points?: number
          question: string
        }
        Update: {
          challenge_id?: string
          correct_answer_index?: number
          created_at?: string | null
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
          start_time: string
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
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      scores: {
        Row: {
          challenge_id: string | null
          created_at: string
          id: string
          motivo: string | null
          punti: number
          stage_id: string | null
          team_id: string
          tipo_modificatore: string | null
        }
        Insert: {
          challenge_id?: string | null
          created_at?: string
          id?: string
          motivo?: string | null
          punti: number
          stage_id?: string | null
          team_id: string
          tipo_modificatore?: string | null
        }
        Update: {
          challenge_id?: string | null
          created_at?: string
          id?: string
          motivo?: string | null
          punti?: number
          stage_id?: string | null
          team_id?: string
          tipo_modificatore?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "scores_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "scores_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "scores_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      settings: {
        Row: {
          id: string
          updated_at: string | null
          value: string
        }
        Insert: {
          id: string
          updated_at?: string | null
          value: string
        }
        Update: {
          id?: string
          updated_at?: string | null
          value?: string
        }
        Relationships: []
      }
      stages: {
        Row: {
          created_at: string
          descrizione: string | null
          id: string
          latitude: number | null
          longitude: number | null
          numero_tappa: number
          outcome: Json | null
          stato: string
          titolo: string
        }
        Insert: {
          created_at?: string
          descrizione?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          numero_tappa: number
          outcome?: Json | null
          stato?: string
          titolo: string
        }
        Update: {
          created_at?: string
          descrizione?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          numero_tappa?: number
          outcome?: Json | null
          stato?: string
          titolo?: string
        }
        Relationships: []
      }
      submissions: {
        Row: {
          challenge_id: string
          created_at: string
          id: string
          latitude: number | null
          longitude: number | null
          note: string | null
          stato_approvazione: string
          team_id: string
          tipo: string
          url: string
          voto: number | null
        }
        Insert: {
          challenge_id: string
          created_at?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          note?: string | null
          stato_approvazione?: string
          team_id: string
          tipo: string
          url: string
          voto?: number | null
        }
        Update: {
          challenge_id?: string
          created_at?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          note?: string | null
          stato_approvazione?: string
          team_id?: string
          tipo?: string
          url?: string
          voto?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "submissions_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "submissions_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_answers: {
        Row: {
          correct: boolean
          created_at: string | null
          id: string
          question_id: string
          selected_answer: number
          team_id: string
        }
        Insert: {
          correct: boolean
          created_at?: string | null
          id?: string
          question_id: string
          selected_answer: number
          team_id: string
        }
        Update: {
          correct?: boolean
          created_at?: string | null
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
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_bank_answers: {
        Row: {
          answer: string
          created_at: string
          extracted_letter: string
          id: string
          question_number: number
          team_id: string
        }
        Insert: {
          answer: string
          created_at?: string
          extracted_letter: string
          id?: string
          question_number: number
          team_id: string
        }
        Update: {
          answer?: string
          created_at?: string
          extracted_letter?: string
          id?: string
          question_number?: number
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "team_bank_answers_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_code_matches: {
        Row: {
          buyer_team_id: string
          created_at: string
          id: string
          required_part: string
          seller_team_id: string
          token_cost: number
        }
        Insert: {
          buyer_team_id: string
          created_at?: string
          id?: string
          required_part: string
          seller_team_id: string
          token_cost?: number
        }
        Update: {
          buyer_team_id?: string
          created_at?: string
          id?: string
          required_part?: string
          seller_team_id?: string
          token_cost?: number
        }
        Relationships: [
          {
            foreignKeyName: "team_code_matches_buyer_team_id_fkey"
            columns: ["buyer_team_id"]
            isOneToOne: true
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "team_code_matches_seller_team_id_fkey"
            columns: ["seller_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_code_parts: {
        Row: {
          assigned_at: string
          code_part: string
          id: string
          part_type: string
          team_id: string
        }
        Insert: {
          assigned_at?: string
          code_part: string
          id?: string
          part_type: string
          team_id: string
        }
        Update: {
          assigned_at?: string
          code_part?: string
          id?: string
          part_type?: string
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "team_code_parts_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: true
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_emoji_movies: {
        Row: {
          attempts: number
          created_at: string
          id: string
          is_correct: boolean
          last_answer: string | null
          letter: string | null
          movie_index: number
          points: number
          team_id: string
          timestamp: string | null
        }
        Insert: {
          attempts?: number
          created_at?: string
          id?: string
          is_correct?: boolean
          last_answer?: string | null
          letter?: string | null
          movie_index: number
          points?: number
          team_id: string
          timestamp?: string | null
        }
        Update: {
          attempts?: number
          created_at?: string
          id?: string
          is_correct?: boolean
          last_answer?: string | null
          letter?: string | null
          movie_index?: number
          points?: number
          team_id?: string
          timestamp?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "team_emoji_movies_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_members: {
        Row: {
          created_at: string | null
          id: string
          name: string
          team_id: string
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          name: string
          team_id: string
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
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
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_posters: {
        Row: {
          assigned_at: string
          id: string
          poster_id: string
          team_id: string
        }
        Insert: {
          assigned_at?: string
          id?: string
          poster_id: string
          team_id: string
        }
        Update: {
          assigned_at?: string
          id?: string
          poster_id?: string
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "team_posters_poster_id_fkey"
            columns: ["poster_id"]
            isOneToOne: false
            referencedRelation: "posters"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "team_posters_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: true
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_progress: {
        Row: {
          challenge_id: string
          completata_il: string | null
          created_at: string
          id: string
          metadata: Json | null
          stato: string
          team_id: string
        }
        Insert: {
          challenge_id: string
          completata_il?: string | null
          created_at?: string
          id?: string
          metadata?: Json | null
          stato?: string
          team_id: string
        }
        Update: {
          challenge_id?: string
          completata_il?: string | null
          created_at?: string
          id?: string
          metadata?: Json | null
          stato?: string
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
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      team_social_submissions: {
        Row: {
          admin_score: number | null
          challenge_id: string
          created_at: string | null
          id: string
          image_1_url: string | null
          image_2_url: string | null
          note: string | null
          social_url: string
          stato_approvazione: string
          status: string | null
          team_id: string
          uploaded_at: string | null
        }
        Insert: {
          admin_score?: number | null
          challenge_id: string
          created_at?: string | null
          id?: string
          image_1_url?: string | null
          image_2_url?: string | null
          note?: string | null
          social_url: string
          stato_approvazione?: string
          status?: string | null
          team_id: string
          uploaded_at?: string | null
        }
        Update: {
          admin_score?: number | null
          challenge_id?: string
          created_at?: string | null
          id?: string
          image_1_url?: string | null
          image_2_url?: string | null
          note?: string | null
          social_url?: string
          stato_approvazione?: string
          status?: string | null
          team_id?: string
          uploaded_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "team_social_submissions_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "team_social_submissions_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      teams: {
        Row: {
          active: boolean
          avatar_url: string | null
          color: string | null
          colore: string
          created_at: string
          freeze_duration_seconds: number | null
          freeze_expires_at: string | null
          freeze_started_at: string | null
          id: string
          motto: string | null
          nome_squadra: string
          owner_id: string | null
          password_plain: string | null
          token_balance: number
          username: string | null
        }
        Insert: {
          active?: boolean
          avatar_url?: string | null
          color?: string | null
          colore?: string
          created_at?: string
          freeze_duration_seconds?: number | null
          freeze_expires_at?: string | null
          freeze_started_at?: string | null
          id?: string
          motto?: string | null
          nome_squadra: string
          owner_id?: string | null
          password_plain?: string | null
          token_balance?: number
          username?: string | null
        }
        Update: {
          active?: boolean
          avatar_url?: string | null
          color?: string | null
          colore?: string
          created_at?: string
          freeze_duration_seconds?: number | null
          freeze_expires_at?: string | null
          freeze_started_at?: string | null
          id?: string
          motto?: string | null
          nome_squadra?: string
          owner_id?: string | null
          password_plain?: string | null
          token_balance?: number
          username?: string | null
        }
        Relationships: []
      }
      time_penalties: {
        Row: {
          created_at: string
          id: string
          minuti_penalita: number
          motivo: string | null
          stage_id: string | null
          team_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          minuti_penalita?: number
          motivo?: string | null
          stage_id?: string | null
          team_id: string
        }
        Update: {
          created_at?: string
          id?: string
          minuti_penalita?: number
          motivo?: string | null
          stage_id?: string | null
          team_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "time_penalties_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "time_penalties_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: string
          team_id: string | null
          user_id: string
          username: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          role: string
          team_id?: string | null
          user_id: string
          username?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          role?: string
          team_id?: string | null
          user_id?: string
          username?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_team_id_fkey"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      quiz_questions_public: {
        Row: {
          challenge_id: string | null
          created_at: string | null
          id: string | null
          options: Json | null
          order_index: number | null
          points: number | null
          question: string | null
        }
        Insert: {
          challenge_id?: string | null
          created_at?: string | null
          id?: string | null
          options?: Json | null
          order_index?: number | null
          points?: number | null
          question?: string | null
        }
        Update: {
          challenge_id?: string | null
          created_at?: string | null
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
      _get_time_bonus_points: { Args: { p_rank: number }; Returns: number }
      admin_add_points: {
        Args: {
          p_points: number
          p_reason: string
          p_stage_id: string
          p_team_id: string
        }
        Returns: undefined
      }
      admin_add_tokens: {
        Args: { p_team_id: string; p_tokens: number }
        Returns: undefined
      }
      admin_adjust_team_score: {
        Args: {
          p_admin_id: string
          p_motivo: string
          p_punti: number
          p_team_id: string
        }
        Returns: Json
      }
      admin_adjust_team_tokens: {
        Args: {
          p_admin_id: string
          p_amount: number
          p_reason: string
          p_team_id: string
        }
        Returns: Json
      }
      admin_delete_team_score: {
        Args: { p_admin_id: string; p_score_id: string }
        Returns: Json
      }
      admin_edit_bank_answer: {
        Args: {
          p_admin_id: string
          p_answer: string
          p_correct: boolean
          p_question_id: number
          p_team_id: string
        }
        Returns: undefined
      }
      admin_edit_secret_code_match: {
        Args: { p_admin_id: string; p_partner_id: string; p_team_id: string }
        Returns: undefined
      }
      admin_edit_secret_code_settings: {
        Args: { p_admin_id: string; p_destination: string; p_full_code: string }
        Returns: undefined
      }
      admin_force_complete_bank: {
        Args: { p_admin_id: string; p_team_id: string }
        Returns: undefined
      }
      admin_force_complete_secret_code: {
        Args: { p_admin_id: string; p_team_id: string }
        Returns: undefined
      }
      admin_get_enigma_dashboard: {
        Args: { p_admin_id: string }
        Returns: Json
      }
      admin_get_posters_overview: { Args: never; Returns: Json }
      admin_get_secret_code_dashboard: { Args: never; Returns: Json }
      admin_remove_points: {
        Args: {
          p_points: number
          p_reason: string
          p_stage_id: string
          p_team_id: string
        }
        Returns: undefined
      }
      admin_remove_tokens: {
        Args: { p_team_id: string; p_tokens: number }
        Returns: undefined
      }
      admin_reopen_game_results: { Args: { p_admin_id: string }; Returns: Json }
      admin_reset_bank: {
        Args: { p_admin_id: string; p_team_id: string }
        Returns: undefined
      }
      admin_update_enigma_solution: {
        Args: { p_admin_id: string; p_challenge_id: string; p_solution: Json }
        Returns: undefined
      }
      buy_marketplace_item: {
        Args: {
          p_item_id: string
          p_target_stage_id?: string
          p_target_team_id?: string
        }
        Returns: Json
      }
      buy_secret_code_part: { Args: never; Returns: Json }
      calculate_final_game_results: {
        Args: { p_admin_id: string }
        Returns: Json
      }
      close_stage: {
        Args: { p_admin_id?: string; p_stage_id: string }
        Returns: Json
      }
      complete_challenge: { Args: { p_challenge: string }; Returns: Json }
      confirm_photo_score: {
        Args: { p_admin_id?: string; p_points: number; p_submission_id: string }
        Returns: Json
      }
      consume_marketplace_transaction: {
        Args: { p_transaction_id: string }
        Returns: Json
      }
      current_team_id: { Args: never; Returns: string }
      end_global_race: { Args: { p_admin_id?: string }; Returns: Json }
      evaluate_poster: {
        Args: { p_admin_id?: string; p_submission_id: string; p_voto: number }
        Returns: Json
      }
      evaluate_social_challenge: {
        Args: { p_admin_id?: string; p_submission_id: string; p_voto: number }
        Returns: Json
      }
      generate_boxe_tournament: {
        Args: { p_admin_id?: string; p_special_bye_team_id?: string }
        Returns: Json
      }
      generate_cornhole_tournament: {
        Args: { p_admin_id?: string; p_special_bye_team_id?: string }
        Returns: Json
      }
      get_auth_context_by_username: {
        Args: { p_username: string }
        Returns: Json
      }
      get_bank_state: { Args: { p_team_id: string }; Returns: Json }
      get_boxe_settings: { Args: never; Returns: Json }
      get_boxe_tournament: { Args: never; Returns: Json }
      get_cornhole_settings: { Args: never; Returns: Json }
      get_cornhole_tournament: { Args: never; Returns: Json }
      get_enigma_state: {
        Args: { p_challenge_id: string; p_team_id?: string }
        Returns: Json
      }
      get_game_report: { Args: { p_user_id?: string }; Returns: Json }
      get_jackpot_plays: { Args: { p_admin_id?: string }; Returns: Json }
      get_jackpot_state: { Args: { p_team_id?: string }; Returns: Json }
      get_or_assign_poster: { Args: { p_team_id: string }; Returns: Json }
      get_report_status: { Args: never; Returns: Json }
      get_secret_code_state: { Args: { p_team_id: string }; Returns: Json }
      get_secure_leaderboard: {
        Args: never
        Returns: {
          active: boolean
          avatar_url: string
          cattiveria_points: number
          challenges_points: number
          color: string
          completed_challenges: number
          freeze_expires_at: string
          freeze_started_at: string
          last_completion: string
          modifier_points: number
          motto: string
          name: string
          rank: number
          team_id: string
          total_duration_seconds: number
          total_points: number
        }[]
      }
      get_social_submission: { Args: never; Returns: Json }
      has_role: { Args: { _role: string; _user_id: string }; Returns: boolean }
      initialize_secret_code_challenge: { Args: never; Returns: Json }
      mark_partenza_used: {
        Args: { p_admin_id?: string; p_transaction_id: string }
        Returns: Json
      }
      open_classifica_bonus: {
        Args: { p_transaction_id: string }
        Returns: undefined
      }
      play_jackpot: {
        Args: { p_puntata?: number; p_team_id?: string }
        Returns: Json
      }
      publish_game_report: { Args: { p_admin_id?: string }; Returns: Json }
      reopen_stage: { Args: { p_stage_id: string }; Returns: undefined }
      reset_boxe_tournament: { Args: { p_admin_id?: string }; Returns: Json }
      reset_cornhole_tournament: {
        Args: { p_admin_id?: string }
        Returns: Json
      }
      reset_global_race: { Args: { p_admin_id?: string }; Returns: Json }
      respond_passaparola_request: {
        Args: {
          p_admin_id?: string
          p_nota_interna?: string
          p_response: string
          p_transaction_id: string
        }
        Returns: Json
      }
      rollback_boxe_match_result: {
        Args: { p_admin_id?: string; p_match_id: string }
        Returns: Json
      }
      rollback_cornhole_match_result: {
        Args: { p_admin_id?: string; p_match_id: string }
        Returns: Json
      }
      set_boxe_special_bye: {
        Args: { p_admin_id?: string; p_team_id: string }
        Returns: Json
      }
      set_cornhole_special_bye: {
        Args: { p_admin_id?: string; p_team_id: string }
        Returns: Json
      }
      spin_unlucky_wheel: { Args: { p_transaction_id?: string }; Returns: Json }
      start_challenge: { Args: { p_challenge: string }; Returns: undefined }
      start_global_race: { Args: { p_admin_id?: string }; Returns: Json }
      submit_bank_answer: {
        Args: { p_answer: string; p_question_number: number }
        Returns: Json
      }
      submit_boxe_match_result: {
        Args: { p_admin_id?: string; p_match_id: string; p_winner_id: string }
        Returns: Json
      }
      submit_cornhole_match_result: {
        Args: { p_admin_id?: string; p_match_id: string; p_winner_id: string }
        Returns: Json
      }
      submit_enigma_answer: {
        Args: { p_answer: Json; p_challenge_id: string }
        Returns: Json
      }
      submit_enigma_extra_answer: { Args: { p_answer: string }; Returns: Json }
      submit_passaparola_request: {
        Args: { p_request_text: string; p_transaction_id: string }
        Returns: Json
      }
      submit_quiz_answer: {
        Args: { p_question: string; p_selected: number }
        Returns: Json
      }
      submit_secret_code_pin: {
        Args: { p_inserted_code: string }
        Returns: Json
      }
      submit_social_challenge: {
        Args: { p_image_1_path: string; p_image_2_path: string }
        Returns: Json
      }
      toggle_marketplace: {
        Args: { p_active: boolean; p_admin_id: string }
        Returns: undefined
      }
      update_team_profile: {
        Args: { p_avatar_url?: string; p_color?: string; p_motto?: string }
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
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
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
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
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
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
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
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
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
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const
