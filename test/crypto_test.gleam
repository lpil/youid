import gleam/bit_array
import gleeunit/should
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

pub fn hash_sha1_test() {
  crypto.sha1(<<"hi":utf8>>)
  |> should.equal(<<
    194, 43, 95, 145, 120, 52, 38, 9, 66, 141, 111, 81, 178, 197, 175, 76, 11,
    222, 106, 66,
  >>)
}

pub fn hash_md5_test() {
  crypto.md5(<<"hi":utf8>>)
  |> should.equal(<<
    73, 246, 138, 92, 132, 147, 236, 44, 11, 244, 137, 130, 28, 33, 252, 59,
  >>)
}
