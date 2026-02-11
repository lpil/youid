import gleam/bit_array
import gleam/int
import youid/internal/bitwise

// gleam_crypto don't support browser
// Using RFC 3174 using Method 2
pub fn sha1(data: BitArray) -> BitArray {
  let bit_size = bit_array.bit_size(data)
  let assert Ok(number_of_zero) =
    int.modulo(448 - { { bit_size + 1 } % 512 } + 512, 512)
  let padding = <<1:big-size(1), 0:big-size({ number_of_zero })>>
  let data = <<data:bits, padding:bits, bit_size:big-size(64)>>

  let #(a, b, c, d, e) =
    process_sha1_chunk(data, #(
      0x67452301,
      0xEFCDAB89,
      0x98BADCFE,
      0x10325476,
      0xC3D2E1F0,
    ))

  <<
    a:big-size(32),
    b:big-size(32),
    c:big-size(32),
    d:big-size(32),
    e:big-size(32),
  >>
}

fn process_sha1_chunk(data: BitArray, sum: #(Int, Int, Int, Int, Int)) {
  case data {
    <<
      x0:big-size(32),
      x1:big-size(32),
      x2:big-size(32),
      x3:big-size(32),
      x4:big-size(32),
      x5:big-size(32),
      x6:big-size(32),
      x7:big-size(32),
      x8:big-size(32),
      x9:big-size(32),
      x10:big-size(32),
      x11:big-size(32),
      x12:big-size(32),
      x13:big-size(32),
      x14:big-size(32),
      x15:big-size(32),
      data:bits,
    >> -> {
      process_sha1_chunk(
        data,
        sha1_cycle(sum.0, sum.1, sum.2, sum.3, sum.4, #(
          x0,
          x1,
          x2,
          x3,
          x4,
          x5,
          x6,
          x7,
          x8,
          x9,
          x10,
          x11,
          x12,
          x13,
          x14,
          x15,
        )),
      )
    }
    _ -> sum
  }
}

fn sha1_cycle(
  ia: Int,
  ib: Int,
  ic: Int,
  id: Int,
  ie: Int,
  w: #(
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
  ),
) -> #(Int, Int, Int, Int, Int) {
  let w0 = w.0
  let w1 = w.1
  let w2 = w.2
  let w3 = w.3
  let w4 = w.4
  let w5 = w.5
  let w6 = w.6
  let w7 = w.7
  let w8 = w.8
  let w9 = w.9
  let w10 = w.10
  let w11 = w.11
  let w12 = w.12
  let w13 = w.13
  let w14 = w.14
  let w15 = w.15

  // w[i] = rotl(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1)
  let w16 = xor4_rotl1(w13, w8, w2, w0)
  let w17 = xor4_rotl1(w14, w9, w3, w1)
  let w18 = xor4_rotl1(w15, w10, w4, w2)
  let w19 = xor4_rotl1(w16, w11, w5, w3)
  let w20 = xor4_rotl1(w17, w12, w6, w4)
  let w21 = xor4_rotl1(w18, w13, w7, w5)
  let w22 = xor4_rotl1(w19, w14, w8, w6)
  let w23 = xor4_rotl1(w20, w15, w9, w7)
  let w24 = xor4_rotl1(w21, w16, w10, w8)
  let w25 = xor4_rotl1(w22, w17, w11, w9)
  let w26 = xor4_rotl1(w23, w18, w12, w10)
  let w27 = xor4_rotl1(w24, w19, w13, w11)
  let w28 = xor4_rotl1(w25, w20, w14, w12)
  let w29 = xor4_rotl1(w26, w21, w15, w13)
  let w30 = xor4_rotl1(w27, w22, w16, w14)
  let w31 = xor4_rotl1(w28, w23, w17, w15)
  let w32 = xor4_rotl1(w29, w24, w18, w16)
  let w33 = xor4_rotl1(w30, w25, w19, w17)
  let w34 = xor4_rotl1(w31, w26, w20, w18)
  let w35 = xor4_rotl1(w32, w27, w21, w19)
  let w36 = xor4_rotl1(w33, w28, w22, w20)
  let w37 = xor4_rotl1(w34, w29, w23, w21)
  let w38 = xor4_rotl1(w35, w30, w24, w22)
  let w39 = xor4_rotl1(w36, w31, w25, w23)
  let w40 = xor4_rotl1(w37, w32, w26, w24)
  let w41 = xor4_rotl1(w38, w33, w27, w25)
  let w42 = xor4_rotl1(w39, w34, w28, w26)
  let w43 = xor4_rotl1(w40, w35, w29, w27)
  let w44 = xor4_rotl1(w41, w36, w30, w28)
  let w45 = xor4_rotl1(w42, w37, w31, w29)
  let w46 = xor4_rotl1(w43, w38, w32, w30)
  let w47 = xor4_rotl1(w44, w39, w33, w31)
  let w48 = xor4_rotl1(w45, w40, w34, w32)
  let w49 = xor4_rotl1(w46, w41, w35, w33)
  let w50 = xor4_rotl1(w47, w42, w36, w34)
  let w51 = xor4_rotl1(w48, w43, w37, w35)
  let w52 = xor4_rotl1(w49, w44, w38, w36)
  let w53 = xor4_rotl1(w50, w45, w39, w37)
  let w54 = xor4_rotl1(w51, w46, w40, w38)
  let w55 = xor4_rotl1(w52, w47, w41, w39)
  let w56 = xor4_rotl1(w53, w48, w42, w40)
  let w57 = xor4_rotl1(w54, w49, w43, w41)
  let w58 = xor4_rotl1(w55, w50, w44, w42)
  let w59 = xor4_rotl1(w56, w51, w45, w43)
  let w60 = xor4_rotl1(w57, w52, w46, w44)
  let w61 = xor4_rotl1(w58, w53, w47, w45)
  let w62 = xor4_rotl1(w59, w54, w48, w46)
  let w63 = xor4_rotl1(w60, w55, w49, w47)
  let w64 = xor4_rotl1(w61, w56, w50, w48)
  let w65 = xor4_rotl1(w62, w57, w51, w49)
  let w66 = xor4_rotl1(w63, w58, w52, w50)
  let w67 = xor4_rotl1(w64, w59, w53, w51)
  let w68 = xor4_rotl1(w65, w60, w54, w52)
  let w69 = xor4_rotl1(w66, w61, w55, w53)
  let w70 = xor4_rotl1(w67, w62, w56, w54)
  let w71 = xor4_rotl1(w68, w63, w57, w55)
  let w72 = xor4_rotl1(w69, w64, w58, w56)
  let w73 = xor4_rotl1(w70, w65, w59, w57)
  let w74 = xor4_rotl1(w71, w66, w60, w58)
  let w75 = xor4_rotl1(w72, w67, w61, w59)
  let w76 = xor4_rotl1(w73, w68, w62, w60)
  let w77 = xor4_rotl1(w74, w69, w63, w61)
  let w78 = xor4_rotl1(w75, w70, w64, w62)
  let w79 = xor4_rotl1(w76, w71, w65, w63)

  // ( 0 <= t <= 19)
  let k = 0x5A827999
  let #(a, b, c, d, e) = round(ia, ib, ic, id, ie, w0, f0(ib, ic, id), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w1, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w2, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w3, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w4, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w5, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w6, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w7, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w8, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w9, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w10, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w11, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w12, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w13, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w14, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w15, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w16, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w17, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w18, f0(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w19, f0(b, c, d), k)

  // (20 <= t <= 39)
  let k = 0x6ED9EBA1
  let #(a, b, c, d, e) = round(a, b, c, d, e, w20, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w21, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w22, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w23, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w24, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w25, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w26, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w27, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w28, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w29, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w30, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w31, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w32, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w33, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w34, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w35, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w36, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w37, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w38, f1(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w39, f1(b, c, d), k)

  // (40 <= t <= 59)
  let k = 0x8F1BBCDC
  let #(a, b, c, d, e) = round(a, b, c, d, e, w40, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w41, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w42, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w43, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w44, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w45, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w46, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w47, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w48, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w49, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w50, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w51, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w52, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w53, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w54, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w55, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w56, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w57, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w58, f2(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w59, f2(b, c, d), k)

  // (60 <= t <= 79)
  let k = 0xCA62C1D6
  let #(a, b, c, d, e) = round(a, b, c, d, e, w60, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w61, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w62, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w63, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w64, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w65, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w66, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w67, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w68, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w69, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w70, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w71, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w72, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w73, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w74, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w75, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w76, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w77, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w78, f3(b, c, d), k)
  let #(a, b, c, d, e) = round(a, b, c, d, e, w79, f3(b, c, d), k)

  #(add32(a, ia), add32(b, ib), add32(c, ic), add32(d, id), add32(e, ie))
}

// f(t;B,C,D) = (B AND C) OR ((NOT B) AND D) ( 0 <= t <= 19)
fn f0(b: Int, c: Int, d: Int) -> Int {
  bitwise.or(bitwise.and(b, c), bitwise.and(bitwise.not(b), d))
}

// f(t;B,C,D) = B XOR C XOR D (20 <= t <= 39)
fn f1(b: Int, c: Int, d: Int) -> Int {
  bitwise.exclusive_or(b, bitwise.exclusive_or(c, d))
}

// f(t;B,C,D) = (B AND C) OR (B AND D) OR (C AND D) (40 <= t <= 59)
fn f2(b: Int, c: Int, d: Int) -> Int {
  bitwise.or(
    bitwise.or(bitwise.and(b, c), bitwise.and(b, d)),
    bitwise.and(c, d),
  )
}

// f(t;B,C,D) = B XOR C XOR D (60 <= t <= 79)
fn f3(b: Int, c: Int, d: Int) -> Int {
  bitwise.exclusive_or(b, bitwise.exclusive_or(c, d))
}

fn xor4_rotl1(a: Int, b: Int, c: Int, d: Int) {
  left_rotate(
    bitwise.exclusive_or(bitwise.exclusive_or(a, b), bitwise.exclusive_or(c, d)),
    1,
  )
}

fn round(a: Int, b: Int, c: Int, d: Int, e: Int, w: Int, f: Int, k: Int) {
  #(
    add32(add32(add32(add32(left_rotate(a, 5), f), e), k), w),
    a,
    left_rotate(b, 30),
    c,
    d,
  )
}

fn left_rotate(x: Int, n: Int) -> Int {
  bitwise.and(
    bitwise.or(bitwise.shift_left(x, n), bitwise.logical_shift_right(x, 32 - n)),
    0xFFFFFFFF,
  )
}

fn add32(a: Int, b: Int) -> Int {
  bitwise.and(a + b, 0xFFFFFFFF)
}
