// Minimal JSX intrinsic element declarations for Lynx native elements.
// @lynx-js/types (the full type package) is a peer dep not yet installed;
// this shim keeps TypeScript happy until it is.

declare namespace JSX {
  interface IntrinsicElements {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    view: { style?: any; bindtap?: (...args: unknown[]) => void; children?: import('react').ReactNode; [key: string]: unknown }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    text: { style?: any; children?: import('react').ReactNode; [key: string]: unknown }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    image: { src?: string; style?: any; [key: string]: unknown }
  }
}
