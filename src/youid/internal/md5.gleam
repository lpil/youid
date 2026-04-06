import gleam/bit_array
import gleam/int
import youid/internal/bitwise

// gleam_crypto don't support browser
// Based on https://www.myersdaily.org/joseph/javascript/md5-text.html
pub fn md5(data: BitArray) -> BitArray {
  let bit_size = bit_array.bit_size(data)
  let assert Ok(number_of_zero) = int.modulo(448 - { bit_size + 1 } % 512, 512)
  let padding = <<1:little-size(1), 0:little-size({ number_of_zero })>>
  let data = <<data:bits, padding:bits, bit_size:little-size(64)>>

  let #(a, b, c, d) =
    process_md5_chunk(data, #(0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476))

  <<a:little-size(32), b:little-size(32), c:little-size(32), d:little-size(32)>>
}

fn process_md5_chunk(data: BitArray, sum: #(Int, Int, Int, Int)) {
  case data {
    <<
      w0:little-size(32),
      w1:little-size(32),
      w2:little-size(32),
      w3:little-size(32),
      w4:little-size(32),
      w5:little-size(32),
      w6:little-size(32),
      w7:little-size(32),
      w8:little-size(32),
      w9:little-size(32),
      w10:little-size(32),
      w11:little-size(32),
      w12:little-size(32),
      w13:little-size(32),
      w14:little-size(32),
      w15:little-size(32),
      next:bits,
    >> -> {
      let w = {
        #(w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15)
      }
      process_md5_chunk(next, md5_cycle(sum, w))
    }
    _ -> sum
  }
}

fn md5_cycle(
  i: #(Int, Int, Int, Int),
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
) -> #(Int, Int, Int, Int) {
  let a = i.0
  let b = i.1
  let c = i.2
  let d = i.3

  let a = ff(a, b, c, d, w.0, 7, 0xd76aa478)
  let d = ff(d, a, b, c, w.1, 12, 0xe8c7b756)
  let c = ff(c, d, a, b, w.2, 17, 0x242070db)
  let b = ff(b, c, d, a, w.3, 22, 0xc1bdceee)
  let a = ff(a, b, c, d, w.4, 7, 0xf57c0faf)
  let d = ff(d, a, b, c, w.5, 12, 0x4787c62a)
  let c = ff(c, d, a, b, w.6, 17, 0xa8304613)
  let b = ff(b, c, d, a, w.7, 22, 0xfd469501)
  let a = ff(a, b, c, d, w.8, 7, 0x698098d8)
  let d = ff(d, a, b, c, w.9, 12, 0x8b44f7af)
  let c = ff(c, d, a, b, w.10, 17, 0xffff5bb1)
  let b = ff(b, c, d, a, w.11, 22, 0x895cd7be)
  let a = ff(a, b, c, d, w.12, 7, 0x6b901122)
  let d = ff(d, a, b, c, w.13, 12, 0xfd987193)
  let c = ff(c, d, a, b, w.14, 17, 0xa679438e)
  let b = ff(b, c, d, a, w.15, 22, 0x49b40821)

  let a = gg(a, b, c, d, w.1, 5, 0xf61e2562)
  let d = gg(d, a, b, c, w.6, 9, 0xc040b340)
  let c = gg(c, d, a, b, w.11, 14, 0x265e5a51)
  let b = gg(b, c, d, a, w.0, 20, 0xe9b6c7aa)
  let a = gg(a, b, c, d, w.5, 5, 0xd62f105d)
  let d = gg(d, a, b, c, w.10, 9, 0x02441453)
  let c = gg(c, d, a, b, w.15, 14, 0xd8a1e681)
  let b = gg(b, c, d, a, w.4, 20, 0xe7d3fbc8)
  let a = gg(a, b, c, d, w.9, 5, 0x21e1cde6)
  let d = gg(d, a, b, c, w.14, 9, 0xc33707d6)
  let c = gg(c, d, a, b, w.3, 14, 0xf4d50d87)
  let b = gg(b, c, d, a, w.8, 20, 0x455a14ed)
  let a = gg(a, b, c, d, w.13, 5, 0xa9e3e905)
  let d = gg(d, a, b, c, w.2, 9, 0xfcefa3f8)
  let c = gg(c, d, a, b, w.7, 14, 0x676f02d9)
  let b = gg(b, c, d, a, w.12, 20, 0x8d2a4c8a)

  let a = hh(a, b, c, d, w.5, 4, 0xfffa3942)
  let d = hh(d, a, b, c, w.8, 11, 0x8771f681)
  let c = hh(c, d, a, b, w.11, 16, 0x6d9d6122)
  let b = hh(b, c, d, a, w.14, 23, 0xfde5380c)
  let a = hh(a, b, c, d, w.1, 4, 0xa4beea44)
  let d = hh(d, a, b, c, w.4, 11, 0x4bdecfa9)
  let c = hh(c, d, a, b, w.7, 16, 0xf6bb4b60)
  let b = hh(b, c, d, a, w.10, 23, 0xbebfbc70)
  let a = hh(a, b, c, d, w.13, 4, 0x289b7ec6)
  let d = hh(d, a, b, c, w.0, 11, 0xeaa127fa)
  let c = hh(c, d, a, b, w.3, 16, 0xd4ef3085)
  let b = hh(b, c, d, a, w.6, 23, 0x04881d05)
  let a = hh(a, b, c, d, w.9, 4, 0xd9d4d039)
  let d = hh(d, a, b, c, w.12, 11, 0xe6db99e5)
  let c = hh(c, d, a, b, w.15, 16, 0x1fa27cf8)
  let b = hh(b, c, d, a, w.2, 23, 0xc4ac5665)

  let a = ii(a, b, c, d, w.0, 6, 0xf4292244)
  let d = ii(d, a, b, c, w.7, 10, 0x432aff97)
  let c = ii(c, d, a, b, w.14, 15, 0xab9423a7)
  let b = ii(b, c, d, a, w.5, 21, 0xfc93a039)
  let a = ii(a, b, c, d, w.12, 6, 0x655b59c3)
  let d = ii(d, a, b, c, w.3, 10, 0x8f0ccc92)
  let c = ii(c, d, a, b, w.10, 15, 0xffeff47d)
  let b = ii(b, c, d, a, w.1, 21, 0x85845dd1)
  let a = ii(a, b, c, d, w.8, 6, 0x6fa87e4f)
  let d = ii(d, a, b, c, w.15, 10, 0xfe2ce6e0)
  let c = ii(c, d, a, b, w.6, 15, 0xa3014314)
  let b = ii(b, c, d, a, w.13, 21, 0x4e0811a1)
  let a = ii(a, b, c, d, w.4, 6, 0xf7537e82)
  let d = ii(d, a, b, c, w.11, 10, 0xbd3af235)
  let c = ii(c, d, a, b, w.2, 15, 0x2ad7d2bb)
  let b = ii(b, c, d, a, w.9, 21, 0xeb86d391)

  #(add32(a, i.0), add32(b, i.1), add32(c, i.2), add32(d, i.3))
}

fn cmn(q: Int, a: Int, b: Int, x: Int, s: Int, t: Int) -> Int {
  let a = add32(add32(a, q), add32(x, t))
  add32(
    bitwise.or(bitwise.shift_left(a, s), bitwise.logical_shift_right(a, 32 - s)),
    b,
  )
}

fn ff(a: Int, b: Int, c: Int, d: Int, x: Int, s: Int, t: Int) -> Int {
  cmn(
    bitwise.or(bitwise.and(b, c), bitwise.and(bitwise.not(b), d)),
    a,
    b,
    x,
    s,
    t,
  )
}

fn gg(a: Int, b: Int, c: Int, d: Int, x: Int, s: Int, t: Int) -> Int {
  cmn(
    bitwise.or(bitwise.and(b, d), bitwise.and(c, bitwise.not(d))),
    a,
    b,
    x,
    s,
    t,
  )
}

fn hh(a: Int, b: Int, c: Int, d: Int, x: Int, s: Int, t: Int) -> Int {
  cmn(bitwise.exclusive_or(b, bitwise.exclusive_or(c, d)), a, b, x, s, t)
}

fn ii(a: Int, b: Int, c: Int, d: Int, x: Int, s: Int, t: Int) -> Int {
  cmn(bitwise.exclusive_or(c, bitwise.or(b, bitwise.not(d))), a, b, x, s, t)
}

fn add32(a: Int, b: Int) -> Int {
  bitwise.and(a + b, 0xFFFFFFFF)
}
