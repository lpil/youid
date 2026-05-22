import { BitArray } from "./gleam.mjs";

export function strongRandomBytes(n) {
  if (!globalThis.crypto?.getRandomValues) {
    throw new Error("WebCrypto API not supported on this JavaScript runtime");
  }
  const array = new Uint8Array(n);
  globalThis.crypto.getRandomValues(array);
  return new BitArray(array);
}

// In JavaScript bitwise operations convert numbers to a sequence of 32 bits
// while Erlang uses arbitrary precision.
// For hashing sha1 and md5 we want this behaviour
// so we don't use the stdlib.

export function bitwise_and(x, y) {
  return x & y;
}

export function bitwise_not(x) {
  return ~x;
}

export function bitwise_or(x, y) {
  return x | y;
}

export function bitwise_exclusive_or(x, y) {
  return x ^ y;
}

export function bitwise_shift_left(x, y) {
  return x << y;
}

export function bitwise_logical_shift_right(x, y) {
  return x >>> y;
}
