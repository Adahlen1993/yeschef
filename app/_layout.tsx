import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Slot, useRouter, useSegments } from "expo-router";
import { useEffect, useState } from "react";
import RouteDebug from "../components/RouteDebug";
import { supabase } from "../lib/supabase";
import { useAuth } from "../state/useAuth";

export default function RootLayout() {
  const [queryClient] = useState(() => new QueryClient());
  const { userId, setUserId, initialized, setInitialized } = useAuth();
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    let mounted = true;
    (async () => {
      const { data } = await supabase.auth.getSession();
      if (!mounted) return;
      setUserId(data.session?.user?.id);
      setInitialized(true);
    })();
    const { data: sub } = supabase.auth.onAuthStateChange((_e, session) => {
      setUserId(session?.user?.id);
    });
    return () => { mounted = false; sub.subscription.unsubscribe(); };
  }, [setUserId, setInitialized]);

  useEffect(() => {
    if (!initialized) return;
    const pathname = "/" + (segments.join("/") || "");
    const inAuthGroup = segments[0] === "(auth)";
    console.log("[ROUTE GUARD]", { initialized, userId, segments, pathname, inAuthGroup });

    if (!userId && !inAuthGroup) {
      console.log("→ redirecting to /(auth)/login");
      router.replace("/(auth)/login");
    } else if (userId && inAuthGroup) {
      console.log("→ redirecting to /(tabs)");
      router.replace("/(tabs)");
    }
  }, [initialized, userId, segments, router]);

  return (
    <QueryClientProvider client={queryClient}>
      <RouteDebug />
<Slot />

    </QueryClientProvider>
  );
}
