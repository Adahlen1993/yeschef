import { useState } from "react";
import { ActivityIndicator, Button, FlatList, Text, TextInput, View } from "react-native";
import { PantryItem, usePantry } from "../../hooks/usePantry";

export default function PantryScreen() {
  const { pantry, addItem, deleteItem } = usePantry();

  // simple add form (manual quick-add using name_override)
  const [name, setName] = useState("");
  const [qty, setQty] = useState("1");
  const [unit, setUnit] = useState("item"); // e.g., item | g | oz | ml | cup

  function onAdd() {
    if (!name.trim()) return;
    addItem.mutate({ name_override: name.trim(), quantity: Number(qty) || 1, unit });
    setName("");
    setQty("1");
    setUnit("item");
  }

  if (pantry.isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator />
        <Text style={{ marginTop: 8 }}>Loading pantry…</Text>
      </View>
    );
  }

  if (pantry.isError) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center", padding: 16 }}>
        <Text style={{ color: "red", textAlign: "center" }}>
          Failed to load pantry: {(pantry.error as Error).message}
        </Text>
      </View>
    );
  }

  const data = pantry.data ?? [];

  const renderItem = ({ item }: { item: PantryItem }) => {
    const label = item.name_override || item.ingredient?.name || "(unnamed)";
    return (
      <View
        style={{
          padding: 12,
          borderBottomWidth: 1,
          borderColor: "#e5e5e5",
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 12,
        }}
      >
        <View style={{ flex: 1 }}>
          <Text style={{ fontWeight: "600" }}>{label}</Text>
          <Text style={{ opacity: 0.7 }}>
            {item.quantity} {item.unit}
          </Text>
        </View>
        <Button title="Delete" onPress={() => deleteItem.mutate(item.id)} />
      </View>
    );
  };

  return (
    <View style={{ flex: 1 }}>
      {/* Add form */}
      <View style={{ padding: 16, gap: 8 }}>
        <Text style={{ fontSize: 18, fontWeight: "600" }}>Add to Pantry</Text>

        <Text>Name</Text>
        <TextInput
          placeholder="e.g., Black beans"
          value={name}
          onChangeText={setName}
          style={{ borderWidth: 1, borderRadius: 8, padding: 10 }}
        />

        <Text>Quantity</Text>
        <TextInput
          placeholder="1"
          keyboardType="numeric"
          value={qty}
          onChangeText={setQty}
          style={{ borderWidth: 1, borderRadius: 8, padding: 10 }}
        />

        <Text>Unit</Text>
        <TextInput
          placeholder="item"
          value={unit}
          onChangeText={setUnit}
          style={{ borderWidth: 1, borderRadius: 8, padding: 10 }}
        />

        <Button
          title={addItem.isPending ? "Adding…" : "Add Item"}
          onPress={onAdd}
          disabled={addItem.isPending}
        />
        {addItem.isError ? (
          <Text style={{ color: "red" }}>
            {(addItem.error as Error).message}
          </Text>
        ) : null}
      </View>

      {/* List */}
      <FlatList
        data={data}
        keyExtractor={(i) => i.id}
        renderItem={renderItem}
        contentContainerStyle={{ paddingBottom: 40 }}
        ListEmptyComponent={
          <View style={{ padding: 16 }}>
            <Text style={{ opacity: 0.7 }}>Your pantry is empty. Add something above.</Text>
          </View>
        }
      />
    </View>
  );
}
