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

export function hashSha1(bitArray) {
  const msg = bitArray.rawBuffer;
  const msgLen = msg.length;
  const msgBitLen = msgLen * 8;
  const padLen = (msgLen + 9 + 63) & ~63;
  const buf = new Uint8Array(padLen);
  buf.set(msg);
  buf[msgLen] = 0x80;
  buf[padLen - 4] = (msgBitLen >>> 24) & 0xff;
  buf[padLen - 3] = (msgBitLen >>> 16) & 0xff;
  buf[padLen - 2] = (msgBitLen >>> 8) & 0xff;
  buf[padLen - 1] = msgBitLen & 0xff;

  let h0 = 0x67452301,
    h1 = 0xefcdab89,
    h2 = 0x98badcfe,
    h3 = 0x10325476,
    h4 = 0xc3d2e1f0;
  const w = new Uint32Array(80);

  for (let i = 0; i < buf.length; i += 64) {
    for (let j = 0; j < 16; j++) {
      const o = i + j * 4;
      w[j] =
        (buf[o] << 24) | (buf[o + 1] << 16) | (buf[o + 2] << 8) | buf[o + 3];
    }
    for (let j = 16; j < 80; j++) {
      const v = w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16];
      w[j] = (v << 1) | (v >>> 31);
    }

    let a = h0,
      b = h1,
      c = h2,
      d = h3,
      e = h4;

    for (let j = 0; j < 80; j++) {
      let f, k;
      if (j < 20) {
        f = (b & c) | (~b & d);
        k = 0x5a827999;
      } else if (j < 40) {
        f = b ^ c ^ d;
        k = 0x6ed9eba1;
      } else if (j < 60) {
        f = (b & c) | (b & d) | (c & d);
        k = 0x8f1bbcdc;
      } else {
        f = b ^ c ^ d;
        k = 0xca62c1d6;
      }
      const t = (((a << 5) | (a >>> 27)) + f + e + k + w[j]) >>> 0;
      e = d;
      d = c;
      c = (b << 30) | (b >>> 2);
      b = a;
      a = t;
    }

    h0 = (h0 + a) >>> 0;
    h1 = (h1 + b) >>> 0;
    h2 = (h2 + c) >>> 0;
    h3 = (h3 + d) >>> 0;
    h4 = (h4 + e) >>> 0;
  }

  return new BitArray(
    Uint8Array.of(
      h0 >>> 24,
      h0 >>> 16,
      h0 >>> 8,
      h0,
      h1 >>> 24,
      h1 >>> 16,
      h1 >>> 8,
      h1,
      h2 >>> 24,
      h2 >>> 16,
      h2 >>> 8,
      h2,
      h3 >>> 24,
      h3 >>> 16,
      h3 >>> 8,
      h3,
      h4 >>> 24,
      h4 >>> 16,
      h4 >>> 8,
      h4,
    ),
  );
}
