(function(root) {
  'use strict';
  const api = {
    displayName(nativeName, storedName, fallback) {
      const clean = value => typeof value === 'string' ? value.trim() : '';
      const name = clean(nativeName) || clean(storedName);
      return !name || /^realmcraft-map-input-/i.test(name) ? fallback : name;
    }
  };
  root.AtlasMapPresentation = api;
  if (typeof module !== 'undefined') module.exports = api;
})(typeof window !== 'undefined' ? window : globalThis);
