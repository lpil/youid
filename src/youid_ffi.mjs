import { BitArray } from "./gleam.mjs";

export function strongRandomBytes(n) {
  if (!globalThis.crypto?.getRandomValues) {
    throw new Error("WebCrypto API not supported on this JavaScript runtime");
  }
  const array = new Uint8Array(n);
  globalThis.crypto.getRandomValues(array);
  return new BitArray(array);
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

const MD5_S = [
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5,
  9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11,
  16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15,
  21,
];

const MD5_K = Array.from({ length: 64 }, (_, i) =>
  Math.floor(Math.abs(Math.sin(i + 1)) * 2 ** 32),
);

export function hashMd5(bitArray) {
  const data = bitArray.rawBuffer;
  const dataLen = data.length;
  const dataBitLen = dataLen * 8;
  const padded = new Uint8Array((dataLen + 9 + 63) & ~63);
  padded.set(data);
  padded[dataLen] = 0x80;
  padded[padded.length - 8] = dataBitLen & 0xff;
  padded[padded.length - 7] = (dataBitLen >>> 8) & 0xff;
  padded[padded.length - 6] = (dataBitLen >>> 16) & 0xff;
  padded[padded.length - 5] = (dataBitLen >>> 24) & 0xff;

  let a = 0x67452301,
    b = 0xefcdab89,
    c = 0x98badcfe,
    d = 0x10325476;

  for (let i = 0; i < padded.length; i += 64) {
    const x = new Uint32Array(padded.buffer, i, 16);
    let aa = a,
      bb = b,
      cc = c,
      dd = d;

    for (let j = 0; j < 64; j++) {
      let f, g;
      if (j < 16) {
        f = (b & c) | (~b & d);
        g = j;
      } else if (j < 32) {
        f = (d & b) | (~d & c);
        g = (5 * j + 1) % 16;
      } else if (j < 48) {
        f = b ^ c ^ d;
        g = (3 * j + 5) % 16;
      } else {
        f = c ^ (b | ~d);
        g = (7 * j) % 16;
      }
      const rotateAmount = MD5_S[j];
      const sum = (a + f + MD5_K[j] + x[g]) >>> 0;
      const oldD = d;
      d = c;
      c = b;
      b = (b + ((sum << rotateAmount) | (sum >>> (32 - rotateAmount)))) >>> 0;
      a = oldD;
    }

    a = (a + aa) >>> 0;
    b = (b + bb) >>> 0;
    c = (c + cc) >>> 0;
    d = (d + dd) >>> 0;
  }

  const out = new Uint8Array(16);
  const view = new DataView(out.buffer);
  view.setUint32(0, a, true);
  view.setUint32(4, b, true);
  view.setUint32(8, c, true);
  view.setUint32(12, d, true);
  return new BitArray(out);
}
