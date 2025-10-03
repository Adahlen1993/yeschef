import { Link } from "expo-router";
import { useState } from "react";
import { ActivityIndicator, Button, Text, TextInput, View } from "react-native";
import { supabase } from "../../lib/supabase";

export default function LoginScreen() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  async function onLogin() {
    setErrorMsg(null);
    if (!email || !password) {
      setErrorMsg("Email and password are required.");
      return;
    }
    setLoading(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (error) setErrorMsg(error.message);
    // On success, the root listener will set userId and route to (tabs)
  }

  return (
    <View style={{ flex: 1, padding: 24, gap: 12, justifyContent: "center" }}>
      <Text style={{ fontSize: 24, fontWeight: "600", textAlign: "center" }}>Sign in</Text>

      <Text>Email</Text>
      <TextInput
        autoCapitalize="none"
        keyboardType="email-address"
        value={email}
        onChangeText={setEmail}
        placeholder="you@example.com"
        style={{ borderWidth: 1, borderRadius: 8, padding: 10 }}
      />

      <Text>Password</Text>
      <TextInput
        value={password}
        onChangeText={setPassword}
        placeholder="••••••••"
        secureTextEntry
        style={{ borderWidth: 1, borderRadius: 8, padding: 10 }}
      />

      {errorMsg ? <Text style={{ color: "red" }}>{errorMsg}</Text> : null}
      {loading ? <ActivityIndicator /> : <Button title="Sign in" onPress={onLogin} />}

      <Text style={{ textAlign: "center", marginTop: 8 }}>
        No account? <Link href="/(auth)/register">Create one</Link>
      </Text>
    </View>
  );
}
