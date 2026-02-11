import youid/internal/md5

// gleam_crypto don't support browser
@external(erlang, "crypto", "strong_rand_bytes")
@external(javascript, "../../youid_ffi.mjs", "strongRandomBytes")
pub fn strong_random_bytes(a: Int) -> BitArray

pub fn sha1_truncated_128(data: BitArray) -> BitArray {
  let assert <<data:bits-size(128), _:32>> = sha1(data)
  data
}

// gleam_crypto don't support browser
@external(erlang, "youid_ffi", "hash_sha1")
@external(javascript, "../../youid_ffi.mjs", "hashSha1")
pub fn sha1(data: BitArray) -> BitArray

pub fn md5(data: BitArray) -> BitArray {
  md5.md5(data)
}
