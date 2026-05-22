import youid/internal/md5
import youid/internal/sha1

// gleam_crypto don't support browser
@external(erlang, "crypto", "strong_rand_bytes")
@external(javascript, "../../youid_ffi.mjs", "strongRandomBytes")
pub fn strong_random_bytes(a: Int) -> BitArray

pub fn sha1_truncated_128(data: BitArray) -> BitArray {
  let assert <<data:bits-size(128), _:32>> = sha1(data)
  data
}

pub fn sha1(data: BitArray) -> BitArray {
  sha1.sha1(data)
}

pub fn md5(data: BitArray) -> BitArray {
  md5.md5(data)
}
