// app/pantry.tsx
import React, { useEffect, useState } from "react";
import { FlatList, SafeAreaView, StyleSheet, Text, View } from "react-native";
import Typeahead from "../../components/Typeahead";
import { supabase } from "../../lib/supabase";
import type { Suggestion } from "../../lib/types";

export default function PantryPage() {
  const [uid, setUid] = useState<string | null>(null);
  const [pantryItems, setPantryItems] = useState<Suggestion[]>([]);

  // Get user ID on mount
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      setUid(data.user?.id ?? null);
    });
  }, []);

  // Load existing pantry items for this user
  useEffect(() => {
    if (!uid) return;
    supabase
      .from("user_ingredients")
      .select("id, name")
      .eq("user_id", uid)
      .then(({ data, error }) => {
        if (!error && data) {
          setPantryItems(data.map((r) => ({ id: r.id, label: r.name })));
        }
      });
  }, [uid]);

  // Search ingredients (global + personal)
  async function searchIngredients(query: string): Promise<Suggestion[]> {
    if (!query.trim()) return [];
    const { data, error } = await supabase.rpc("search_ingredients", {
      q: query,
      uid,
      lim: 20,
    });
    if (error) throw error;
    return (data ?? []).map((row: { row_key: string; label: string; source: string }) => ({
      id: `${row.source}:${row.row_key}`,
      label: row.label,
      note: row.source === "personal" ? "(yours)" : undefined,
    }));
  }

  // Add an ingredient to the user's pantry
  async function addToPantry(item: Suggestion) {
    if (!uid) return;

    // Check if it's already there
    if (pantryItems.some((p) => p.label.toLowerCase() === item.label.toLowerCase())) return;

    const { error } = await supabase
      .from("user_ingredients")
      .insert({ name: item.label, user_id: uid });

    if (!error) {
      setPantryItems((prev) => [...prev, item]);
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>My Pantry</Text>

      <Typeahead search={searchIngredients} onSelect={addToPantry} />

      <FlatList
        data={pantryItems}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <View style={styles.pantryItem}>
            <Text style={styles.pantryText}>{item.label}</Text>
          </View>
        )}
        style={styles.list}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    paddingHorizontal: 16,
    paddingTop: 50,
  },
  title: {
    fontSize: 22,
    fontWeight: "bold",
    marginBottom: 12,
  },
  list: {
    marginTop: 20,
  },
  pantryItem: {
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderColor: "#eee",
  },
  pantryText: {
    fontSize: 16,
  },
});
