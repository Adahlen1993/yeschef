import { create } from "zustand";
import { supabase } from "../lib/supabase"; // if this path errors, use "../../lib/supabase" based on your folder layout

type AuthState = {
  userId?: string;
  initialized: boolean;
  setUserId: (id?: string) => void;
  setInitialized: (v: boolean) => void;
  // real sign-out (optional, nice to have)
  signOut: () => Promise<void>;
};

export const useAuth = create<AuthState>((set) => ({
  userId: undefined,
  initialized: false,
  setUserId: (id) => set({ userId: id }),
  setInitialized: (v) => set({ initialized: v }),
  signOut: async () => {
    await supabase.auth.signOut();
    set({ userId: undefined });
  },
}));
