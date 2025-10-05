// components/Typeahead.tsx
import React, { useEffect, useRef, useState } from "react";
import { ActivityIndicator, FlatList, Keyboard, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { useDebouncedValue } from "../hooks/useDebouncedValue";
import type { Suggestion } from "../lib/types";

type Props = {
  placeholder?: string;
  initialQuery?: string;
  debounceMs?: number;
  maxResults?: number;
  search: (query: string) => Promise<Suggestion[]>;
  onSelect: (item: Suggestion) => void;
};

export default function Typeahead({
  placeholder = "Search...",
  initialQuery = "",
  debounceMs = 300,
  maxResults = 10,
  search,
  onSelect,
}: Props) {
  const [query, setQuery] = useState(initialQuery);
  const [results, setResults] = useState<Suggestion[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const debouncedQuery = useDebouncedValue(query, debounceMs);
  const mountedRef = useRef(true);

  useEffect(() => {
    return () => { mountedRef.current = false; };
  }, []);

  useEffect(() => {
    // no query → clear results
    if (!debouncedQuery.trim()) {
      setResults([]);
      setOpen(false);
      setErrorMsg(null);
      return;
    }

    let cancelled = false;
    setLoading(true);
    setErrorMsg(null);

    search(debouncedQuery)
      .then((items) => {
        if (cancelled || !mountedRef.current) return;
        setResults(items.slice(0, maxResults));
        setOpen(true);
      })
      .catch((err) => {
        if (cancelled || !mountedRef.current) return;
        setErrorMsg(err?.message || "Search failed");
        setResults([]);
        setOpen(true);
      })
      .finally(() => {
        if (cancelled || !mountedRef.current) return;
        setLoading(false);
      });

    return () => { cancelled = true; };
  }, [debouncedQuery, maxResults, search]);

  // Close the list when user taps outside
  useEffect(() => {
    const sub = Keyboard.addListener("keyboardDidHide", () => setOpen(false));
    return () => sub.remove();
  }, []);

  const showSpinner = loading;
  const showNoResults = !loading && open && results.length === 0 && !errorMsg;

  return (
    <View style={styles.container}>
      <TextInput
        value={query}
        onChangeText={(t) => {
          setQuery(t);
          if (!open) setOpen(true);
        }}
        placeholder={placeholder}
        style={styles.input}
        onFocus={() => setOpen(true)}
        autoCorrect={false}
        autoCapitalize="none"
      />

      {open && (
        <View style={styles.dropdown}>
          {showSpinner && (
            <View style={styles.rowCenter}>
              <ActivityIndicator />
            </View>
          )}

          {!!errorMsg && (
            <View style={styles.rowCenter}>
              <Text style={styles.errorText}>{errorMsg}</Text>
            </View>
          )}

          {showNoResults && (
            <View style={styles.rowCenter}>
              <Text style={styles.muted}>No results</Text>
            </View>
          )}

          {!showSpinner && !errorMsg && results.length > 0 && (
            <FlatList
              keyboardShouldPersistTaps="handled"
              data={results}
              keyExtractor={(item) => String(item.id)}
              renderItem={({ item }) => (
                <Pressable
                  onPress={() => {
                    onSelect(item);
                    setOpen(false);
                    // Optionally fill the input with the selection
                    setQuery(item.label);
                    Keyboard.dismiss();
                  }}
                  style={({ pressed }) => [styles.row, pressed && styles.rowPressed]}
                >
                  <Text style={styles.label}>{item.label}</Text>
                  {item.note ? <Text style={styles.note}>{item.note}</Text> : null}
                </Pressable>
              )}
              ItemSeparatorComponent={() => <View style={styles.sep} />}
            />
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { width: "100%" },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
    backgroundColor: "white",
  },
  dropdown: {
    marginTop: 6,
    borderWidth: 1,
    borderColor: "#e3e3e3",
    borderRadius: 8,
    overflow: "hidden",
    backgroundColor: "white",
    maxHeight: 280,
  },
  row: {
    paddingVertical: 10,
    paddingHorizontal: 12,
  },
  rowPressed: { backgroundColor: "#f2f2f2" },
  rowCenter: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 12,
  },
  sep: { height: StyleSheet.hairlineWidth, backgroundColor: "#eee" },
  label: { fontSize: 16 },
  note: { fontSize: 12, color: "#666" },
  errorText: { color: "#b00020" },
  muted: { color: "#666" },
});
