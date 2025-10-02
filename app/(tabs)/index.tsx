// app/(tabs)/index.tsx
import { useQuery } from "@tanstack/react-query";
import { Button, Text, View } from "react-native";
import { useAuth } from "../../state/useAuth";

export default function IndexTab() {
  const { userId, setUserId, signOut } = useAuth();

  const now = useQuery({
    queryKey: ["now"],
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, 300));
      return new Date().toISOString();
    },
  });

  return (
    <View style={{ flex: 1, justifyContent: "center", alignItems: "center", gap: 12 }}>
      <Text>YesChef 🚀</Text>
      <Text>{userId ? `Signed in as: ${userId}` : "Guest"}</Text>
      <Button title="Fake Sign In" onPress={() => setUserId("demo-user-1")} />
      <Button title="Sign Out" onPress={signOut} />
      <Text>{now.isLoading ? "Loading time..." : `Now: ${now.data}`}</Text>
      <Button title="Refetch Time" onPress={() => now.refetch()} />
    </View>
  );
}
