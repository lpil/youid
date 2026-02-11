import gleam/bit_array
import gleam/crypto as gleam_crypto
import gleeunit/should
import qcheck
import youid/internal/crypto

pub fn random_bytes_test() {
  crypto.strong_random_bytes(0)
  |> should.equal(bit_array.from_string(""))
  crypto.strong_random_bytes(10)
  |> bit_array.byte_size()
  |> should.equal(10)
}

pub fn hash_sha1_truncated_128_test() {
  crypto.sha1_truncated_128(<<"hi":utf8>>)
  |> should.equal(<<
    194, 43, 95, 145, 120, 52, 38, 9, 66, 141, 111, 81, 178, 197, 175, 76,
  >>)
}

pub fn sha1_hash_is_robust_like_well_know_sha1_hash_test() {
  use string <- qcheck.given(qcheck.string())
  should.equal(
    crypto.sha1(<<string:utf8>>),
    gleam_crypto.hash(gleam_crypto.Sha1, <<string:utf8>>),
  )
}

pub fn sha1_hash_always_returns_128_bits_test() {
  use string <- qcheck.given(qcheck.string())
  crypto.sha1(<<string:utf8>>)
  |> bit_array.bit_size
  |> should.equal(160)
}

pub fn sha1_hash_is_deterministic_test() {
  use string <- qcheck.given(qcheck.string())
  should.equal(crypto.sha1(<<string:utf8>>), crypto.sha1(<<string:utf8>>))
}

pub fn sha1_hash_differs_for_distinct_inputs_test() {
  use #(a, b) <- qcheck.given(distinct_string_pair())
  should.not_equal(crypto.sha1(<<a:utf8>>), crypto.sha1(<<b:utf8>>))
}

pub fn md5_hash_is_robust_like_well_know_md5_hash_test() {
  use string <- qcheck.given(qcheck.string())
  should.equal(
    crypto.md5(<<string:utf8>>),
    gleam_crypto.hash(gleam_crypto.Md5, <<string:utf8>>),
  )
}

pub fn md5_hash_always_returns_128_bits_test() {
  use string <- qcheck.given(qcheck.string())
  crypto.md5(<<string:utf8>>)
  |> bit_array.bit_size
  |> should.equal(128)
}

pub fn md5_hash_is_deterministic_test() {
  use string <- qcheck.given(qcheck.string())
  should.equal(crypto.md5(<<string:utf8>>), crypto.md5(<<string:utf8>>))
}

pub fn md5_hash_differs_for_distinct_inputs_test() {
  use #(a, b) <- qcheck.given(distinct_string_pair())
  should.not_equal(crypto.md5(<<a:utf8>>), crypto.md5(<<b:utf8>>))
}

fn distinct_string_pair() -> qcheck.Generator(#(String, String)) {
  use a <- qcheck.bind(qcheck.string())
  use b <- qcheck.map(qcheck.string())
  case a == b {
    True -> #(a, b <> "b")
    False -> #(a, b)
  }
}
