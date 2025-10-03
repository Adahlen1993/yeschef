import { Stack } from "expo-router";

// This is the layout for all (auth) screens, i.e. login and register
// It checks if a user is logged in, and if so, redirects to the (tabs) layout


export default function AuthLayout() {
  return (
    <Stack
      screenOptions={{
        headerTitleAlign: "center",
      }}
    />
  );
}
