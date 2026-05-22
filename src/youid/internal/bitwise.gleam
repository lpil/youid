// In JavaScript bitwise operations convert numbers to a sequence of 32 bits
// while Erlang uses arbitrary precision.
// For hashing sha1 and md5 we want this behaviour
// so we don't use the stdlib.

@external(erlang, "erlang", "band")
@external(javascript, "../../youid_ffi.mjs", "bitwise_and")
pub fn and(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bnot")
@external(javascript, "../../youid_ffi.mjs", "bitwise_not")
pub fn not(x: Int) -> Int

@external(erlang, "erlang", "bor")
@external(javascript, "../../youid_ffi.mjs", "bitwise_or")
pub fn or(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bxor")
@external(javascript, "../../youid_ffi.mjs", "bitwise_exclusive_or")
pub fn exclusive_or(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bsl")
@external(javascript, "../../youid_ffi.mjs", "bitwise_shift_left")
pub fn shift_left(x: Int, y: Int) -> Int

@external(erlang, "erlang", "bsr")
@external(javascript, "../../youid_ffi.mjs", "bitwise_logical_shift_right")
pub fn logical_shift_right(x: Int, y: Int) -> Int
