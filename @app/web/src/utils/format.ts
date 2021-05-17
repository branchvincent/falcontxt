export const capitalize = (s: string): string =>
  s.charAt(0).toUpperCase() + s.slice(1)

export const camelToSnakeCase = (str: string): string =>
  str.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`)
