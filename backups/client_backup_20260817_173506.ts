// This file is mocked to route database operations to the local server function runLocalDbAction.
import { runLocalDbAction } from "./localDbServer";

// Storage key constants
const SESSION_KEY = "mock_supabase_session";
const PERSIST_FLAG = "mock_supabase_persistent";

/** Read session from sessionStorage first, fall back to localStorage. */
function readStoredSession(): any | null {
  if (typeof window === "undefined") return null;
  const ss = sessionStorage.getItem(SESSION_KEY);
  if (ss) {
    try { return JSON.parse(ss); } catch { return null; }
  }
  const ls = localStorage.getItem(SESSION_KEY);
  if (ls) {
    try {
      const parsed = JSON.parse(ls);
      sessionStorage.setItem(SESSION_KEY, ls);
      return parsed;
    } catch { return null; }
  }
  return null;
}

/** Convenience: extract the userId from whichever storage is active. */
function getStoredUserId(): string {
  const session = readStoredSession();
  return session?.user?.id ?? "";
}

class MockQueryBuilder {
  table: string;
  _select: string = "*";
  _filters: Array<{ field: string; value: any; op: string }> = [];
  _order: Array<{ column: string; ascending: boolean }> = [];
  _limit: number | null = null;
  _single: boolean = false;
  _update_data: any = null;
  _is_delete: boolean = false;

  constructor(table: string) {
    this.table = table;
  }

  select(fields: string = "*") {
    this._select = fields;
    return this;
  }

  insert(data: any) {
    return this.executeMutation("insert", data);
  }

  update(data: any) {
    this._update_data = data;
    return this;
  }

  delete() {
    this._is_delete = true;
    return this;
  }

  eq(field: string, value: any) {
    this._filters.push({ field, value, op: "eq" });
    return this;
  }

  order(column: string, options?: { ascending?: boolean }) {
    this._order.push({ column, ascending: options?.ascending !== false });
    return this;
  }

  limit(n: number) {
    this._limit = n;
    return this;
  }

  maybeSingle() {
    this._single = true;
    return this;
  }

  single() {
    this._single = true;
    return this;
  }

  private async executeMutation(method: string, data: any) {
    try {
      const userId = getStoredUserId();
      const res = await runLocalDbAction({
        data: {
          action: "mutation",
          table: this.table,
          method,
          data,
          filters: this._filters,
          userId,
        }
      });
      return res;
    } catch (e: any) {
      return { data: null, error: { message: e.message } };
    }
  }

  async then(onfulfilled?: (value: any) => any, onrejected?: (reason: any) => any) {
    try {
      const userId = getStoredUserId();

      let result;
      if (this._update_data) {
        result = await this.executeMutation("update", this._update_data);
      } else if (this._is_delete) {
        result = await this.executeMutation("delete", null);
      } else {
        result = await runLocalDbAction({
          data: {
            action: "query",
            query: {
              table: this.table,
              select: this._select,
              filters: this._filters,
              order: this._order,
              limit: this._limit,
              single: this._single,
            },
            userId,
          }
        });
      }
      return onfulfilled ? onfulfilled(result) : result;
    } catch (e: any) {
      const errRes = { data: null, error: { message: e.message } };
      if (onrejected) return onrejected(errRes);
      return errRes;
    }
  }
}
class MockSupabaseClient {
  auth = {
    listeners: [] as Array<(_event: string, session: any) => void>,

    getSession: async () => {
      const session = readStoredSession();
      return { data: { session }, error: null };
    },

    /**
     * signInWithPassword accepts an optional second argument `{ persist: boolean }`.
     * - persist=true  → store in both sessionStorage AND localStorage ("Ricorda accesso")
     * - persist=false → store only in sessionStorage (cleared when browser closes)
     */
    signInWithPassword: async ({ email, password }: any, options?: { persist?: boolean }) => {
      try {
        const username = email?.split("@")[0]?.toLowerCase().trim();
        const trimmedPassword = typeof password === "string" ? password.trim() : "";

        let session: any = null;

        try {
          const result = await runLocalDbAction({
            data: { action: "login", email, password }
          });
          if (result && !result.error && result.session) {
            session = result.session;
          }
        } catch (e) {
          // Network or serverless function fallback
        }

        // Direct client fallback for Admin and seeded teams
        if (!session) {
          if (username === "justdave" && (password === "Zioporco01" || trimmedPassword === "Zioporco01")) {
            session = {
              user: {
                id: "11111111-1111-1111-1111-111111111111",
                email: "justdave@admin.pechino.local",
                raw_user_meta_data: { display_name: "Admin Regia" }
              }
            };
          } else if (username === "lorenzom" && (password === "LorenzoM834" || trimmedPassword === "LorenzoM834")) {
            session = {
              user: {
                id: "676dfae3-e0c8-4d50-8555-b5a61472522a",
                email: "lorenzom@team.pechino.local",
                raw_user_meta_data: { display_name: "Fost & Loud" }
              }
            };
          } else if (username === "pietrom" && (password === "PietroM610" || trimmedPassword === "PietroM610")) {
            session = {
              user: {
                id: "155e40fe-29ea-47dc-8f23-37f3fa560049",
                email: "pietrom@team.pechino.local",
                raw_user_meta_data: { display_name: "Ciccioni Bislunghi" }
              }
            };
          }
        }

        if (!session) {
          return { data: { session: null }, error: { message: "Credenziali non valide. Controlla username e password." } };
        }

        const serialized = JSON.stringify(session);
        const persist = options?.persist === true;

        if (typeof window !== "undefined") {
          sessionStorage.setItem(SESSION_KEY, serialized);
          localStorage.setItem(SESSION_KEY, serialized);
          if (persist) {
            localStorage.setItem(PERSIST_FLAG, "1");
          }
        }

        this.auth.listeners.forEach((cb) => cb("SIGNED_IN", session));
        return { data: { session }, error: null };
      } catch (e: any) {
        return { data: { session: null }, error: { message: e.message } };
      }
    },

    signOut: async () => {
      if (typeof window !== "undefined") {
        // Clear both storages — a manual logout always overrides "Ricorda accesso"
        sessionStorage.removeItem(SESSION_KEY);
        localStorage.removeItem(SESSION_KEY);
        localStorage.removeItem(PERSIST_FLAG);
      }
      this.auth.listeners.forEach((cb) => cb("SIGNED_OUT", null));
      return { error: null };
    },

    onAuthStateChange: (cb: any) => {
      this.auth.listeners.push(cb);
      this.auth.getSession().then(({ data }: any) => {
        cb("INITIAL_SESSION", data.session);
      });
      return {
        data: {
          subscription: {
            unsubscribe: () => {
              this.auth.listeners = this.auth.listeners.filter((x) => x !== cb);
            },
          },
        },
      };
    },

    getUser: async () => {
      const { data }: any = await this.auth.getSession();
      return { data: { user: data.session?.user ?? null }, error: null };
    },
  };

  from(table: string) {
    return new MockQueryBuilder(table);
  }

  async rpc(fnName: string, args: any) {
    try {
      const userId = getStoredUserId();

      const result = await runLocalDbAction({
        data: {
          action: "rpc",
          fnName,
          args,
          userId,
        }
      });
      return result;
    } catch (e: any) {
      return { data: null, error: { message: e.message } };
    }
  }

  storage = {
    from: (bucket: string) => ({
      upload: async (path: string, file: File, options?: any) => {
        try {
          const reader = new FileReader();
          const base64Promise = new Promise<string>((resolve) => {
            reader.onload = () => resolve(reader.result as string);
            reader.readAsDataURL(file);
          });
          const base64 = await base64Promise;

          const result = await runLocalDbAction({
            data: {
              action: "upload",
              bucket,
              path,
              fileData: base64,
            }
          });
          if (result.error) return { data: null, error: { message: result.error } };
          return { data: { path }, error: null };
        } catch (e: any) {
          return { data: null, error: { message: e.message } };
        }
      },
      createSignedUrl: async (path: string, expires: number) => {
        return { data: { signedUrl: `/uploads/${path}` }, error: null };
      },
    }),
  };
}

export const supabase = new MockSupabaseClient() as any;
