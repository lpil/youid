import gleam/bit_array
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

pub fn sha1_hash_of_known_input_is_correct_test() {
  crypto.sha1(<<"":utf8>>)
  |> should.equal(<<
    218, 57, 163, 238, 94, 107, 75, 13, 50, 85, 191, 239, 149, 96, 24, 144, 175,
    216, 7, 9,
  >>)
  crypto.sha1(<<"hi":utf8>>)
  |> should.equal(<<
    194, 43, 95, 145, 120, 52, 38, 9, 66, 141, 111, 81, 178, 197, 175, 76, 11,
    222, 106, 66,
  >>)
  crypto.sha1(<<"gleam":utf8>>)
  |> should.equal(<<
    232, 186, 22, 137, 53, 192, 170, 244, 200, 54, 247, 84, 19, 74, 183, 206, 42,
    241, 203, 120,
  >>)
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

pub fn md5_hash_of_known_input_is_correct_test() {
  crypto.md5(<<"":utf8>>)
  |> should.equal(<<
    212, 29, 140, 217, 143, 0, 178, 4, 233, 128, 9, 152, 236, 248, 66, 126,
  >>)
  crypto.md5(<<"hi":utf8>>)
  |> should.equal(<<
    73, 246, 138, 92, 132, 147, 236, 44, 11, 244, 137, 130, 28, 33, 252, 59,
  >>)
  crypto.md5(<<"gleam":utf8>>)
  |> should.equal(<<
    195, 143, 147, 62, 60, 163, 163, 61, 254, 132, 220, 82, 87, 215, 94, 65,
  >>)
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
