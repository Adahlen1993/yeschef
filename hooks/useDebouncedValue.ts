import { useEffect, useState } from "react";

/**
 * useDebouncedValue
 * Delays updating the returned value until `delay` ms after the last change.
 *
 * Example:
 * const debouncedQuery = useDebouncedValue(query, 400);
 * useEffect(() => { search(debouncedQuery); }, [debouncedQuery]);
 */
export function useDebouncedValue<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState<T>(value);

  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);

  return debounced;
}
