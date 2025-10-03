import { usePathname, useSegments } from "expo-router";
import { useState } from "react";
import { Pressable, Text } from "react-native";

export default function RouteDebug() {
  const pathname = usePathname();
  const segments = useSegments();
  const [visible, setVisible] = useState(true);

  if (!__DEV__ || !visible) return null;

  return (
    <Pressable
      onLongPress={() => setVisible(false)}
      style={{
        position: "absolute",
        top: 40,
        left: 8,
        right: 8,
        padding: 8,
        borderRadius: 8,
        backgroundColor: "rgba(0,0,0,0.6)",
      }}
    >
      <Text style={{ color: "white" }}>path: {pathname}</Text>
      <Text style={{ color: "white" }}>segments: {JSON.stringify(segments)}</Text>
      <Text style={{ color: "white", opacity: 0.7 }}>(long-press to hide)</Text>
    </Pressable>
  );
}
