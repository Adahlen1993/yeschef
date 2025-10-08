// app/(tabs)/pantry.tsx
import React, { useEffect, useState } from "react";
import { Alert, FlatList, Pressable, SafeAreaView, StyleSheet, Text, View } from "react-native";
import Typeahead from "../../components/Typeahead";
import { supabase } from "../../lib/supabase";
import type { Suggestion } from "../../lib/types";

type PantryRow = { id: string; label: string }; // user_ingredients.id is uuid

export default function PantryPage() {
  const [uid, setUid] = useState<string | null>(null);
  const [pantryItems, setPantryItems] = useState<PantryRow[]>([]);

  // Get user ID on mount
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => setUid(data.user?.id ?? null));
  }, []);

  // Load existing pantry items
  useEffect(() => {
    if (!uid) return;
    supabase
      .from("user_ingredients")
      .select("id, name")
      .eq("user_id", uid)
      .order("name", { ascending: true })
      .then(({ data, error }) => {
        if (error) {
          console.warn(error.message);
          return;
        }
        setPantryItems((data ?? []).map((r) => ({ id: String(r.id), label: r.name })));
      });
  }, [uid]);

  // Search ingredients (global + personal)
  async function searchIngredients(query: string): Promise<Suggestion[]> {
    if (!query.trim()) return [];
    const { data, error } = await supabase.rpc("search_ingredients", { q: query, uid, lim: 20 });
    if (error) throw error;
    return (data ?? []).map(
      (row: { row_key: string; label: string; source: string }) => ({
        id: `${row.source}:${row.row_key}`,
        label: row.label,
        note: row.source === "personal" ? "(yours)" : undefined,
      })
    );
  }

  // Add an ingredient to the user's pantry
  async function addToPantry(item: Suggestion) {
    if (!uid) {
      Alert.alert("Sign in required", "Please sign in to manage your pantry.");
      return;
    }
    // Avoid duplicates by label (case-insensitive)
    if (pantryItems.some((p) => p.label.toLowerCase() === item.label.toLowerCase())) return;

    const { data, error } = await supabase
      .from("user_ingredients")
      .insert({ name: item.label, user_id: uid })
      .select("id, name")
      .single(); // get the inserted row back

    if (error) {
      Alert.alert("Error adding", error.message);
      return;
    }
    setPantryItems((prev) => [...prev, { id: String(data!.id), label: data!.name }]);
  }

  // Remove from pantry by id
  async function removeFromPantry(id: string) {
    if (!uid) return;
    const { error } = await supabase.from("user_ingredients").delete().eq("id", id).eq("user_id", uid);
    if (error) {
      Alert.alert("Error removing", error.message);
      return;
    }
    setPantryItems((prev) => prev.filter((p) => p.id !== id));
  }

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>My Pantry</Text>

      <Typeahead search={searchIngredients} onSelect={addToPantry} />

      <FlatList
        data={[...pantryItems].sort((a, b) => a.label.localeCompare(b.label))}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ paddingTop: 12 }}
        renderItem={({ item }) => (
          <View style={styles.row}>
            <Text style={styles.rowText}>{item.label}</Text>
            <Pressable onPress={() => removeFromPantry(item.id)} style={({ pressed }) => [styles.removeBtn, pressed && { opacity: 0.7 }]}>
              <Text style={styles.removeText}>Remove</Text>
            </Pressable>
          </View>
        )}
        ItemSeparatorComponent={() => <View style={styles.sep} />}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff", paddingHorizontal: 16, paddingTop: 50 },
  title: { fontSize: 22, fontWeight: "bold" },
  row: {
    paddingVertical: 10,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  rowText: { fontSize: 16 },
  sep: { height: StyleSheet.hairlineWidth, backgroundColor: "#eee" },
  removeBtn: {
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 6,
    backgroundColor: "#ffecec",
    borderWidth: 1,
    borderColor: "#ffd0d0",
  },
  removeText: { color: "#b00020", fontWeight: "600" },
});
