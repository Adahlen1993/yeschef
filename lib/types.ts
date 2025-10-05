// lib/types.ts
export type Suggestion = {
  id: string | number;
  label: string;        // what we display
  note?: string;        // optional secondary text (e.g., alias)
};
