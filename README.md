# YesChef

Cross-platform mobile app (Expo/React Native + TypeScript) that helps people manage their pantry and discover recipes from what they already have — barcode scan now, receipt OCR + AI later.

---

## Status

- ✅ Expo app (TypeScript, Expo Router with Tabs)
- ✅ State: Zustand (local/UI), TanStack Query (server)
- ⏳ Auth/DB (Supabase)
- ⏳ Pantry CRUD
- ⏳ Barcode scan (POC)
- ⏳ Recipe suggestions
- ⏳ Shopping list
- ⏳ Receipt OCR + AI (post-MVP)

---

## MVP Features

- Email/password auth
- Pantry items: add/edit/delete (manual first)
- Barcode scan proof-of-concept
- Simple recipe suggestions from pantry overlap
- Basic shopping list

### Post-MVP (v2)

- Receipt OCR → auto-add items
- Community recipes (public/private, likes/favorites)
- Budget/analytics (“How much did I spend on produce?”)
- AI Q&A (“What can I cook tonight?”)

---

## Tech Decisions

- **Frontend:** Expo (React Native) + Expo Router (Tabs)
- **Language:** TypeScript (loose now, tighten later)
- **State:**
  - **Zustand** for local/UI (auth session, UI flags)
  - **TanStack Query** for server state (pantry, recipes)
- **Backend/DB:** Supabase (Postgres, Auth, Storage, RLS) — free-tier friendly
- **Barcode:** `expo-barcode-scanner` (later)
- **OCR:** Cloud provider via backend (later)
- **AI:** Backend endpoint calling an LLM (later)

---

## Project Structure

