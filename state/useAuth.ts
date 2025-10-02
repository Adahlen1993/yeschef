import { create } from "zustand";

type AuthState = {
  userId?: string;
  setUserId: (id?: string) => void;
  signOut: () => void;
};

export const useAuth = create<AuthState>((set) => ({
  userId: undefined,
  setUserId: (id) => set({ userId: id }),
  signOut: () => set({ userId: undefined }),
}));
