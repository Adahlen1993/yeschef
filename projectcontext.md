Project: YesChef (Expo RN + TypeScript + Expo Router).
State: Auth (Supabase) working with session persistence + route guard. Tabs scaffolded (Home/Pantry/Recipes/List). Zustand + React Query in place.
DB: Using Supabase. Applied Schema v1 mostly. Notable parts:

profiles, user_settings, units, ingredient_categories

ingredients (no generated column; normalized via immutable public.norm()), ingredient_aliases, barcode_mappings

pantry_items, pantry_transactions, user_basics

recipes (+ ingredients/steps/tags/images/favorites/saves/copies)

shopping_lists, shopping_list_items (unique partial indexes; name index uses public.norm)

search view/RPC: ingredient_search_entries & ingredient_search(q, lim) (uses public.norm)
Helpers: public.norm(text) = lowercase normalizer (no unaccent).
Goal for this session: implement Pantry add modal with typeahead using ingredient_search, choosing a canonical ingredient (or “add personal” fallback), set qty/unit, then insert into pantry_items.
Acceptance (for this task):

Debounced search (≥2 chars) calls RPC; shows top 10 results (canonical first on ties).

Selecting a result sets ingredient_id and preselects a sensible unit/qty.

If no result chosen, allow “Add personal ingredient” which creates a private ingredient and adds to pantry.

Submitting inserts correctly, list updates, and modal resets.

Nice errors for offline/network/permission.

Please generate the implementation plan and then code.