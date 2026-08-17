// This file is mocked to route database operations to the local server function runLocalDbAction.
import { runLocalDbAction } from "./localDbServer";

// Storage key constants
const SESSION_KEY = "mock_supabase_session";
const PERSIST_FLAG = "mock_supabase_persistent";

/** Read session from sessionStorage first, fall back to localStorage (persistent). */
function readStoredSession(): any | null {
  if (typeof window === "undefined") return null;
  const ss = sessionStorage.getItem(SESSION_KEY);
  if (ss) {
    try { return JSON.parse(ss); } catch { return null; }
  }
  // Only restore from localStorage if the user previously chose "persist"
  const isPersistent = localStorage.getItem(PERSIST_FLAG) === "1";
  if (isPersistent) {
    const ls = localStorage.getItem(SESSION_KEY);
    if (ls) {
      try {
        const parsed = JSON.parse(ls);
        // Mirror to sessionStorage so subsequent reads are fast
        sessionStorage.setItem(SESSION_KEY, ls);
        return parsed;
      } catch { return null; }
    }
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
        const result = await runLocalDbAction({
          data: { action: "login", email, password }
        });
        if (result.error) {
          return { data: { session: null }, error: { message: result.error } };
        }

        const session = result.session;
        const serialized = JSON.stringify(session);
        const persist = options?.persist === true;

        if (typeof window !== "undefined") {
          // Always store in sessionStorage (active tab/window)
          sessionStorage.setItem(SESSION_KEY, serialized);

          if (persist) {
            // Persist across browser restarts
            localStorage.setItem(SESSION_KEY, serialized);
            localStorage.setItem(PERSIST_FLAG, "1");
          } else {
            // Remove any previous persistent session so it does not survive
            localStorage.removeItem(SESSION_KEY);
            localStorage.removeItem(PERSIST_FLAG);
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
