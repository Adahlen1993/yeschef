// hooks/usePantry.ts
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { useAuth } from "../state/useAuth";

type IngredientRef = { name: string | null } | null;

export type PantryItem = {
  id: string;
  ingredient_id: string | null;
  name_override: string | null;
  quantity: number;
  unit: string;
  updated_at: string;
  ingredient: IngredientRef; // joined ingredient name (if linked)
};

export function usePantry() {
  const { userId } = useAuth();
  const qc = useQueryClient();

  const pantry = useQuery({
    queryKey: ["pantry", userId],
    enabled: !!userId,
    queryFn: async (): Promise<PantryItem[]> => {
      const { data, error } = await supabase
        .from("pantry_items")
        .select(
          "id, ingredient_id, name_override, quantity, unit, updated_at, ingredient:ingredients(name)"
        )
        .eq("user_id", userId!)
        .order("updated_at", { ascending: false });
      if (error) throw error;
      return data as unknown as PantryItem[];
    },
  });

  const addItem = useMutation({
    mutationFn: async (payload: {
      // either provide ingredient_id or a manual name_override
      ingredient_id?: string;
      name_override?: string;
      quantity: number;
      unit: string;
    }) => {
      const { data, error } = await supabase
        .from("pantry_items")
        .insert([{ ...payload, user_id: userId }])
        .select(
          "id, ingredient_id, name_override, quantity, unit, updated_at, ingredient:ingredients(name)"
        )
        .single();
      if (error) throw error;
      return data as PantryItem;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["pantry", userId] }),
  });

  const updateItem = useMutation({
    mutationFn: async (args: {
      id: string;
      patch: Partial<Pick<PantryItem, "quantity" | "unit" | "name_override" | "ingredient_id">>;
    }) => {
      const { id, patch } = args;
      const { data, error } = await supabase
        .from("pantry_items")
        .update(patch)
        .eq("id", id)
        .select(
          "id, ingredient_id, name_override, quantity, unit, updated_at, ingredient:ingredients(name)"
        )
        .single();
      if (error) throw error;
      return data as PantryItem;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["pantry", userId] }),
  });

  const deleteItem = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("pantry_items").delete().eq("id", id);
      if (error) throw error;
      return id;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["pantry", userId] }),
  });

  return { pantry, addItem, updateItem, deleteItem };
}
