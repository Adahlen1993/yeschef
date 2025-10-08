-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.admin_reviews (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type = ANY (ARRAY['ingredient'::text, 'recipe'::text, 'barcode'::text])),
  entity_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])),
  reviewer_id uuid,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admin_reviews_pkey PRIMARY KEY (id),
  CONSTRAINT admin_reviews_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.barcode_mappings (
  upc text NOT NULL,
  ingredient_id uuid NOT NULL,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT barcode_mappings_pkey PRIMARY KEY (upc),
  CONSTRAINT barcode_mappings_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id),
  CONSTRAINT barcode_mappings_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.cook_session_consumption (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  cook_session_id uuid NOT NULL,
  ingredient_id uuid NOT NULL,
  amount_used numeric NOT NULL,
  unit text NOT NULL,
  source text NOT NULL DEFAULT 'scaled_from_recipe'::text CHECK (source = ANY (ARRAY['direct'::text, 'scaled_from_recipe'::text])),
  CONSTRAINT cook_session_consumption_pkey PRIMARY KEY (id),
  CONSTRAINT cook_session_consumption_cook_session_id_fkey FOREIGN KEY (cook_session_id) REFERENCES public.cook_sessions(id),
  CONSTRAINT cook_session_consumption_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id),
  CONSTRAINT cook_session_consumption_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(code)
);
CREATE TABLE public.cook_session_steps (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  cook_session_id uuid NOT NULL,
  step_number integer NOT NULL,
  started_at timestamp with time zone,
  finished_at timestamp with time zone,
  CONSTRAINT cook_session_steps_pkey PRIMARY KEY (id),
  CONSTRAINT cook_session_steps_cook_session_id_fkey FOREIGN KEY (cook_session_id) REFERENCES public.cook_sessions(id)
);
CREATE TABLE public.cook_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  recipe_id uuid NOT NULL,
  chosen_servings integer,
  used_basics boolean DEFAULT true,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  finished_at timestamp with time zone,
  CONSTRAINT cook_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT cook_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT cook_sessions_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.global_ingredient_units (
  ingredient_id uuid NOT NULL,
  unit text NOT NULL,
  CONSTRAINT global_ingredient_units_pkey PRIMARY KEY (ingredient_id, unit),
  CONSTRAINT global_ingredient_units_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id)
);
CREATE TABLE public.global_ingredients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category_id uuid,
  default_unit text,
  visibility text NOT NULL DEFAULT 'public'::text CHECK (visibility = ANY (ARRAY['public'::text, 'private'::text])),
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT global_ingredients_pkey PRIMARY KEY (id),
  CONSTRAINT ingredients_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.ingredient_categories(id),
  CONSTRAINT ingredients_default_unit_fkey FOREIGN KEY (default_unit) REFERENCES public.units(code),
  CONSTRAINT ingredients_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.ingredient_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ingredient_id uuid NOT NULL,
  alias text NOT NULL,
  source text NOT NULL DEFAULT 'user'::text CHECK (source = ANY (ARRAY['system'::text, 'user'::text])),
  user_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ingredient_aliases_pkey PRIMARY KEY (id),
  CONSTRAINT ingredient_aliases_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id),
  CONSTRAINT ingredient_aliases_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.ingredient_categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  parent_id uuid,
  CONSTRAINT ingredient_categories_pkey PRIMARY KEY (id),
  CONSTRAINT ingredient_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.ingredient_categories(id)
);
CREATE TABLE public.ingredient_suggestions (
  name USER-DEFINED NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ingredient_suggestions_pkey PRIMARY KEY (user_id, name),
  CONSTRAINT ingredient_suggestions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.ingredient_units (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ingredient_id uuid NOT NULL,
  preferred_unit text,
  density_g_per_ml numeric,
  unit_conversions jsonb DEFAULT '{}'::jsonb,
  CONSTRAINT ingredient_units_pkey PRIMARY KEY (id),
  CONSTRAINT ingredient_units_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id),
  CONSTRAINT ingredient_units_preferred_unit_fkey FOREIGN KEY (preferred_unit) REFERENCES public.units(code)
);
CREATE TABLE public.ingredients_import (
  name text NOT NULL,
  external_ref text,
  possible_units text
);
CREATE TABLE public.pantry_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  ingredient_id uuid,
  name_override text,
  quantity numeric NOT NULL DEFAULT 1,
  unit text NOT NULL DEFAULT 'item'::text,
  added_via text NOT NULL DEFAULT 'manual'::text CHECK (added_via = ANY (ARRAY['manual'::text, 'barcode'::text, 'receipt'::text])),
  reorder_threshold numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT pantry_items_pkey PRIMARY KEY (id),
  CONSTRAINT pantry_items_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(code),
  CONSTRAINT pantry_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT pantry_items_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id)
);
CREATE TABLE public.pantry_transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  pantry_item_id uuid,
  user_id uuid NOT NULL,
  change_qty numeric NOT NULL,
  unit text NOT NULL,
  reason text NOT NULL CHECK (reason = ANY (ARRAY['add'::text, 'cook'::text, 'adjust'::text, 'receipt_import'::text])),
  related_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT pantry_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT pantry_transactions_pantry_item_id_fkey FOREIGN KEY (pantry_item_id) REFERENCES public.pantry_items(id),
  CONSTRAINT pantry_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT pantry_transactions_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(code)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  display_name text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.receipt_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  receipt_id uuid NOT NULL,
  line_text text,
  upc text,
  ingredient_id uuid,
  quantity numeric,
  unit text,
  price_each numeric,
  line_total numeric,
  confidence numeric,
  mapping_status text NOT NULL DEFAULT 'auto'::text CHECK (mapping_status = ANY (ARRAY['auto'::text, 'manual'::text, 'uncertain'::text])),
  CONSTRAINT receipt_items_pkey PRIMARY KEY (id),
  CONSTRAINT receipt_items_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES public.receipts(id),
  CONSTRAINT receipt_items_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id),
  CONSTRAINT receipt_items_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(code)
);
CREATE TABLE public.receipts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  vendor text,
  purchased_at timestamp with time zone,
  subtotal numeric,
  tax numeric,
  total numeric,
  raw_text text,
  status text NOT NULL DEFAULT 'parsed'::text CHECK (status = ANY (ARRAY['parsed'::text, 'needs_review'::text])),
  ocr_confidence numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT receipts_pkey PRIMARY KEY (id),
  CONSTRAINT receipts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.recipe_copies (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  src_recipe_id uuid NOT NULL,
  new_recipe_id uuid NOT NULL,
  copied_by uuid NOT NULL,
  copied_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT recipe_copies_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_copies_src_recipe_id_fkey FOREIGN KEY (src_recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_copies_new_recipe_id_fkey FOREIGN KEY (new_recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_copies_copied_by_fkey FOREIGN KEY (copied_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.recipe_favorites (
  user_id uuid NOT NULL,
  recipe_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT recipe_favorites_pkey PRIMARY KEY (user_id, recipe_id),
  CONSTRAINT recipe_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT recipe_favorites_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipe_images (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL,
  url text NOT NULL,
  sort_order integer DEFAULT 0,
  CONSTRAINT recipe_images_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_images_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipe_ingredients (
  recipe_id uuid NOT NULL,
  ingredient_id uuid NOT NULL,
  quantity numeric,
  unit text,
  optional boolean DEFAULT false,
  note text,
  CONSTRAINT recipe_ingredients_pkey PRIMARY KEY (recipe_id, ingredient_id),
  CONSTRAINT recipe_ingredients_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_ingredients_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id),
  CONSTRAINT recipe_ingredients_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(code)
);
CREATE TABLE public.recipe_saves (
  user_id uuid NOT NULL,
  recipe_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT recipe_saves_pkey PRIMARY KEY (recipe_id, user_id),
  CONSTRAINT recipe_saves_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_saves_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.recipe_steps (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL,
  step_number integer NOT NULL,
  instruction text NOT NULL,
  media_url text,
  timer_seconds integer,
  CONSTRAINT recipe_steps_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_steps_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipe_tags (
  recipe_id uuid NOT NULL,
  tag_id uuid NOT NULL,
  CONSTRAINT recipe_tags_pkey PRIMARY KEY (tag_id, recipe_id),
  CONSTRAINT recipe_tags_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id)
);
CREATE TABLE public.recipes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  author_user_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  time_minutes integer,
  servings_default integer DEFAULT 2,
  cuisine text,
  visibility text NOT NULL DEFAULT 'private'::text CHECK (visibility = ANY (ARRAY['public'::text, 'private'::text])),
  is_canonical boolean DEFAULT false,
  likes_count integer DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT recipes_pkey PRIMARY KEY (id),
  CONSTRAINT recipes_author_user_id_fkey FOREIGN KEY (author_user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.shopping_list_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  shopping_list_id uuid NOT NULL,
  ingredient_id uuid,
  name_override text,
  quantity numeric NOT NULL DEFAULT 1,
  unit text NOT NULL DEFAULT 'item'::text,
  added_from text NOT NULL DEFAULT 'manual'::text CHECK (added_from = ANY (ARRAY['manual'::text, 'recipe'::text, 'low_stock'::text, 'cook_out'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT shopping_list_items_pkey PRIMARY KEY (id),
  CONSTRAINT shopping_list_items_shopping_list_id_fkey FOREIGN KEY (shopping_list_id) REFERENCES public.shopping_lists(id),
  CONSTRAINT shopping_list_items_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id),
  CONSTRAINT shopping_list_items_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(code)
);
CREATE TABLE public.shopping_lists (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'archived'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT shopping_lists_pkey PRIMARY KEY (id),
  CONSTRAINT shopping_lists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.tags (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  CONSTRAINT tags_pkey PRIMARY KEY (id)
);
CREATE TABLE public.units (
  code text NOT NULL,
  unit_type text NOT NULL CHECK (unit_type = ANY (ARRAY['mass'::text, 'volume'::text, 'count'::text])),
  ratio_to_base numeric NOT NULL,
  CONSTRAINT units_pkey PRIMARY KEY (code)
);
CREATE TABLE public.user_addresses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  label text,
  line1 text,
  line2 text,
  city text,
  region text,
  postal_code text,
  country text,
  phone text,
  is_default boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_addresses_pkey PRIMARY KEY (id),
  CONSTRAINT user_addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.user_basics (
  user_id uuid NOT NULL,
  ingredient_id uuid NOT NULL,
  CONSTRAINT user_basics_pkey PRIMARY KEY (user_id, ingredient_id),
  CONSTRAINT user_basics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_basics_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.global_ingredients(id)
);
CREATE TABLE public.user_ingredient_submissions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  proposed_name text NOT NULL,
  upc text,
  category_id uuid,
  notes text,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])),
  decided_by uuid,
  decided_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_ingredient_submissions_pkey PRIMARY KEY (id),
  CONSTRAINT user_ingredient_submissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_ingredient_submissions_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.ingredient_categories(id),
  CONSTRAINT user_ingredient_submissions_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.user_ingredients (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  name USER-DEFINED NOT NULL,
  default_unit text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_ingredients_pkey PRIMARY KEY (id),
  CONSTRAINT user_ingredients_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.user_recipe_submissions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])),
  decided_by uuid,
  decided_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_recipe_submissions_pkey PRIMARY KEY (id),
  CONSTRAINT user_recipe_submissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_recipe_submissions_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.user_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  default_servings integer DEFAULT 2,
  dietary_preferences jsonb DEFAULT '{}'::jsonb,
  cuisines_preferences jsonb DEFAULT '{}'::jsonb,
  suggest_public_recipes boolean DEFAULT true,
  always_include_basics boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_settings_pkey PRIMARY KEY (id),
  CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);