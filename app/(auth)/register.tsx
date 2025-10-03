import { Link } from "expo-router";
import { useState } from "react";
import { ActivityIndicator, Button, Text, TextInput, View } from "react-native";
import { supabase } from "../../lib/supabase";


export default function RegisterScreen() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [infoMsg, setInfoMsg] = useState<string | null>(null);

  async function onRegister() {
    setErrorMsg(null);
    setInfoMsg(null);
    if (!email || !password) {
      setErrorMsg("Email and password are required.");
      return;
    }
    setLoading(true);
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      // You can add redirectTo for email confirmations with deep links later
      // options: { emailRedirectTo: "exp://..." },
    });
    setLoading(false);
    if (error) {
      setErrorMsg(error.message);
      return;
    }

    // If "Confirm email" is ON in Supabase Auth settings, user must confirm via email.
    // Otherwise, session may be created immediately.
    if (!data.session) {
      setInfoMsg("Check your email to confirm your account, then return to sign in.");
    }
  }

  return (
    <View style={{ flex: 1, padding: 24, gap: 12, justifyContent: "center" }}>
      <Text style={{ fontSize: 24, fontWeight: "600", textAlign: "center" }}>Create account</Text>

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
        placeholder="At least 6 characters"
        secureTextEntry
        style={{ borderWidth: 1, borderRadius: 8, padding: 10 }}
      />

      {errorMsg ? <Text style={{ color: "red" }}>{errorMsg}</Text> : null}
      {infoMsg ? <Text style={{ color: "green" }}>{infoMsg}</Text> : null}
      {loading ? <ActivityIndicator /> : <Button title="Sign up" onPress={onRegister} />}

      <Text style={{ textAlign: "center", marginTop: 8 }}>
        Already have an account? <Link href="/(auth)/login">Sign in</Link>
      </Text>
    </View>
  );
}
