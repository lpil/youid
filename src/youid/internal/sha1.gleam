import gleam/bit_array
import gleam/dict
import gleam/int
import gleam/list

// In JavaScript bitwise operations convert numbers to a sequence of 32 bits
// while Erlang uses arbitrary precision.
// For hashing sha1 and md5 we want this behaviour
// so we don't use the stdlib.

@external(erlang, "erlang", "band")
@external(javascript, "../../youid_ffi.mjs", "bitwise_and")
pub fn bitwise_and(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bnot")
@external(javascript, "../../youid_ffi.mjs", "bitwise_not")
pub fn bitwise_not(x: Int) -> Int

@external(erlang, "erlang", "bor")
@external(javascript, "../../youid_ffi.mjs", "bitwise_or")
pub fn bitwise_or(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bxor")
@external(javascript, "../../youid_ffi.mjs", "bitwise_exclusive_or")
pub fn bitwise_exclusive_or(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bsl")
@external(javascript, "../../youid_ffi.mjs", "bitwise_shift_left")
fn bitwise_shift_left(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bsr")
@external(javascript, "../../youid_ffi.mjs", "bitwise_logical_shift_right")
fn bitwise_logical_shift_right(x: Int, y: Int) -> Int

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
  let w =
    list.index_fold(
      [
        w.0,
        w.1,
        w.2,
        w.3,
        w.4,
        w.5,
        w.6,
        w.7,
        w.8,
        w.9,
        w.10,
        w.11,
        w.12,
        w.13,
        w.14,
        w.15,
      ],
      dict.new(),
      fn(w, val, i) { dict.insert(w, i, val) },
    )

  let #(a, b, c, d, e, _) = sha1_cycle_loop(#(ia, ib, ic, id, ie, w), 0)

  #(add32(a, ia), add32(b, ib), add32(c, ic), add32(d, id), add32(e, ie))
}

fn sha1_cycle_loop(acc, t) {
  case t {
    80 -> acc
    _ -> {
      let #(a, b, c, d, e, w) = acc

      let s = bitwise_and(t, 0x0000000F)

      let w = case t >= 16 {
        True -> {
          let assert Ok(ws13) = dict.get(w, bitwise_and(s + 13, 0x0000000F))
          let assert Ok(ws8) = dict.get(w, bitwise_and(s + 8, 0x0000000F))
          let assert Ok(ws2) = dict.get(w, bitwise_and(s + 2, 0x0000000F))
          let assert Ok(ws0) = dict.get(w, s)
          let ws =
            left_rotate(
              ws13
                |> bitwise_exclusive_or(ws8)
                |> bitwise_exclusive_or(ws2)
                |> bitwise_exclusive_or(ws0),
              1,
            )
          dict.insert(w, s, ws)
        }
        _ -> w
      }

      let assert Ok(ws) = dict.get(w, s)

      let temp =
        add32(left_rotate(a, 5), f(t, b, c, d))
        |> add32(e)
        |> add32(ws)
        |> add32(k(t))

      sha1_cycle_loop(#(temp, a, left_rotate(b, 30), c, d, w), t + 1)
    }
  }
}

// f(t;B,C,D) = (B AND C) OR ((NOT B) AND D) ( 0 <= t <= 19)
// f(t;B,C,D) = B XOR C XOR D (20 <= t <= 39)
// f(t;B,C,D) = (B AND C) OR (B AND D) OR (C AND D) (40 <= t <= 59)
// f(t;B,C,D) = B XOR C XOR D (60 <= t <= 79)
fn f(t: Int, b: Int, c: Int, d: Int) -> Int {
  case t {
    _ if 0 <= t && t <= 19 ->
      bitwise_or(bitwise_and(b, c), bitwise_and(bitwise_not(b), d))
    _ if 20 <= t && t <= 39 ->
      bitwise_exclusive_or(b, bitwise_exclusive_or(c, d))
    _ if 40 <= t && t <= 59 ->
      bitwise_or(
        bitwise_or(bitwise_and(b, c), bitwise_and(b, d)),
        bitwise_and(c, d),
      )
    _ -> bitwise_exclusive_or(b, bitwise_exclusive_or(c, d))
  }
}

// K(t) = 5A827999 ( 0 <= t <= 19)
// K(t) = 6ED9EBA1 (20 <= t <= 39)
// K(t) = 8F1BBCDC (40 <= t <= 59)
// K(t) = CA62C1D6 (60 <= t <= 79)
fn k(t: Int) -> Int {
  case t {
    _ if 0 <= t && t <= 19 -> 0x5A827999
    _ if 20 <= t && t <= 39 -> 0x6ED9EBA1
    _ if 40 <= t && t <= 59 -> 0x8F1BBCDC
    _ -> 0xCA62C1D6
  }
}

fn left_rotate(x: Int, n: Int) -> Int {
  bitwise_and(
    bitwise_or(bitwise_shift_left(x, n), bitwise_logical_shift_right(x, 32 - n)),
    0xFFFFFFFF,
  )
}

fn add32(a: Int, b: Int) -> Int {
  bitwise_and(a + b, 0xFFFFFFFF)
}
