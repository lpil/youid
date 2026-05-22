import gleam/bit_array
import gleam/crypto as gleam_crypto
import qcheck
import youid/internal/crypto

pub fn random_bytes_test() {
  assert crypto.strong_random_bytes(0) == bit_array.from_string("")
  assert crypto.strong_random_bytes(10)
    |> bit_array.byte_size()
    == 10
}

pub fn hash_sha1_truncated_128_test() {
  assert crypto.sha1_truncated_128(<<"hi":utf8>>)
    == <<194, 43, 95, 145, 120, 52, 38, 9, 66, 141, 111, 81, 178, 197, 175, 76>>
}

pub fn sha1_hash_is_robust_like_well_know_sha1_hash_test() {
  use data <- qcheck.given(qcheck.byte_aligned_bit_array())
  assert crypto.sha1(data) == gleam_crypto.hash(gleam_crypto.Sha1, data)
}

pub fn sha1_hash_always_returns_128_bits_test() {
  use data <- qcheck.given(qcheck.byte_aligned_bit_array())
  assert crypto.sha1(data)
    |> bit_array.bit_size
    == 160
}

pub fn sha1_hash_is_deterministic_test() {
  use data <- qcheck.given(qcheck.byte_aligned_bit_array())
  assert crypto.sha1(data) == crypto.sha1(data)
}

pub fn sha1_hash_differs_for_distinct_inputs_test() {
  use #(a, b) <- qcheck.given(distinct_byte_aligned_bit_array_pair())
  assert crypto.sha1(a) != crypto.sha1(b)
}

pub fn md5_hash_is_robust_like_well_know_md5_hash_test() {
  use data <- qcheck.given(qcheck.byte_aligned_bit_array())
  assert crypto.md5(data) == gleam_crypto.hash(gleam_crypto.Md5, data)
}

pub fn md5_hash_always_returns_128_bits_test() {
  use data <- qcheck.given(qcheck.byte_aligned_bit_array())
  assert crypto.md5(data)
    |> bit_array.bit_size
    == 128
}

pub fn md5_hash_is_deterministic_test() {
  use data <- qcheck.given(qcheck.byte_aligned_bit_array())
  assert crypto.md5(data) == crypto.md5(data)
}

pub fn md5_hash_differs_for_distinct_inputs_test() {
  use #(a, b) <- qcheck.given(distinct_byte_aligned_bit_array_pair())
  assert crypto.md5(a) != crypto.md5(b)
}

fn distinct_byte_aligned_bit_array_pair() -> qcheck.Generator(
  #(BitArray, BitArray),
) {
  use a <- qcheck.bind(qcheck.byte_aligned_bit_array())
  use b <- qcheck.map(qcheck.byte_aligned_bit_array())
  case a == b {
    True -> #(a, <<b:bits, 0>>)
    False -> #(a, b)
  }
}
