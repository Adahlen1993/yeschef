// app/typeahead-demo.tsx
import React, { useEffect, useState } from "react";
import { SafeAreaView, StyleSheet, Text, View } from "react-native";
import Typeahead from "../components/Typeahead";
import { supabase } from "../lib/supabase";
import type { Suggestion } from "../lib/types";

async function searchIngredients(query: string, uid: string | null): Promise<Suggestion[]> {
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

export default function TypeaheadDemo() {
  const [uid, setUid] = useState<string | null>(null);

  // Get the Supabase auth user id (works if you’re logged in via Supabase)
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      setUid(data.user?.id ?? null);
    });
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Typeahead Demo</Text>
        <Text style={styles.subtitle}>Global + your personal items</Text>
      </View>

      <Typeahead
        search={(q) => searchIngredients(q, uid)}
        onSelect={(item) => console.log("Selected:", item)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#f9f9f9", paddingHorizontal: 16, paddingTop: 50 },
  header: { marginBottom: 20 },
  title: { fontSize: 22, fontWeight: "bold" },
  subtitle: { fontSize: 14, color: "#666" },
});
