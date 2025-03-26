import gleam/bit_array
import gleam/erlang/process
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import youid/uuid

pub fn main() {
  gleeunit.main()
}

pub fn v1_from_string_test() {
  let assert Ok(uuid) = uuid.from_string("49cac37c-310b-11eb-adc1-0242ac120002")
  uuid
  |> uuid.version
  |> should.equal(uuid.V1)
}

pub fn v1_from_string_upper_test() {
  let assert Ok(uuid) = uuid.from_string("49CAC37C-310B-11EB-ADC1-0242AC120002")
  uuid
  |> uuid.version
  |> should.equal(uuid.V1)
}

pub fn v4_from_string_test() {
  let assert Ok(uuid) = uuid.from_string("16b53fc5-f9a7-4f6b-8180-399ab0986250")
  uuid
  |> uuid.version
  |> should.equal(uuid.V4)
}

pub fn v4_from_string_upper_test() {
  let assert Ok(uuid) = uuid.from_string("16B53FC5-F9A7-4F6B-8180-399AB0986250")
  uuid
  |> uuid.version
  |> should.equal(uuid.V4)
}

pub fn v7_from_string_test() {
  let assert Ok(uuid) = uuid.from_string("018ed16d-0f82-7d38-a8ad-31f11b97d10c")
  uuid
  |> uuid.version
  |> should.equal(uuid.V7)
}

pub fn v7_from_string_upper_test() {
  let assert Ok(uuid) = uuid.from_string("018ED16D-0F82-7D38-A8AD-31F11B97D10C")
  uuid
  |> uuid.version
  |> should.equal(uuid.V7)
}

pub fn unknown_version_test() {
  let assert Ok(uuid) = uuid.from_string("16b53fc5-f9a7-0f6b-8180-399ab0986250")
  uuid
  |> uuid.version
  |> should.equal(uuid.VUnknown)
}

pub fn too_short_test() {
  "16b53fc5-f9a7-4f6b-8180-399ab098625"
  |> uuid.from_string()
  |> should.equal(Error(Nil))
}

pub fn too_long_test() {
  "16b53fc5-f9a7-4f6b-8180-399ab09862500"
  |> uuid.from_string()
  |> should.equal(Error(Nil))
}

pub fn non_hex_char_test() {
  "16z53fc5-f9a7-4f6b-8180-399ab0986250"
  |> uuid.from_string()
  |> should.equal(Error(Nil))
}

pub fn from_bit_array_too_long_test() {
  "16b53fc5f9a74f6b8180399ab098625000"
  |> bit_array.base16_decode()
  |> should.be_ok()
  |> uuid.from_bit_array()
  |> should.be_error()
}

pub fn from_bit_array_too_short_test() {
  "16b53fc5f9a74f6b8180399ab09862"
  |> bit_array.base16_decode()
  |> should.be_ok()
  |> uuid.from_bit_array()
  |> should.be_error()
}

pub fn from_bit_array_invalid_version_test() {
  "16b53fc5f9a70f6b8180399ab0986225"
  |> bit_array.base16_decode()
  |> should.be_ok()
  |> uuid.from_bit_array()
  |> should.be_error()
}

//
// V1 Tests
//
pub fn v1_roundtrip_test() {
  let uuid = uuid.v1()
  uuid
  |> uuid.to_string()
  |> uuid.from_string()
  |> should.equal(Ok(uuid))
}

pub fn v1_case_test() {
  let uuid = uuid.v1()
  uuid
  |> uuid.to_string()
  |> string.uppercase()
  |> uuid.from_string()
  |> should.equal(Ok(uuid))
}

pub fn v1_own_version_test() {
  uuid.v1()
  |> uuid.version
  |> should.equal(uuid.V1)
}

pub fn v1_own_variant_test() {
  uuid.v1()
  |> uuid.variant
  |> should.equal(uuid.Rfc4122)
}

pub fn v1_custom_node_and_clock_seq() {
  let node = "B6:00:CD:CA:75:C7"
  let node_no_colons = "B600CDCA75C7"
  let clock_seq = 15_000
  let assert Ok(uuid) =
    uuid.v1_custom(uuid.CustomNode(node), uuid.CustomClockSeq(<<clock_seq:14>>))

  uuid
  |> uuid.node
  |> should.equal(node_no_colons)

  uuid
  |> uuid.clock_sequence
  |> should.equal(clock_seq)
}

pub fn v1_to_bit_array_length_test() {
  let uuid = uuid.v1()

  uuid
  |> uuid.to_bit_array()
  |> bit_array.byte_size()
  |> should.equal(16)
}

pub fn v1_to_bit_array_correctness_test() {
  let uuid = uuid.v1()

  let uuid_from_string =
    uuid
    |> uuid.to_string()
    |> string.replace("-", "")
    |> bit_array.base16_decode()
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> should.equal(uuid_from_string)
}

pub fn v1_from_bit_array_test() {
  let uuid = uuid.v1()

  uuid
  |> uuid.to_bit_array()
  |> uuid.from_bit_array()
  |> should.be_ok()
  |> should.equal(uuid)
}

pub fn v1_posix_time_test() {
  let assert Ok(uuid) = uuid.from_string("49cac37c-310b-11eb-adc1-0242ac120002")

  uuid
  |> uuid.time_posix_microsec()
  |> should.equal(1_606_521_011_735_846)

  uuid
  |> uuid.time_posix_millisec()
  |> should.equal(1_606_521_011_735)
}

//
// V3 Tests
//
pub fn v3_dns_namespace_test() {
  let assert Ok(uuid) = uuid.v3(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
  uuid.to_string(uuid)
  |> should.equal("03bf0706-b7e9-33b8-aee5-c6142a816478")
}

pub fn v3_dont_crash_on_bad_name_test() {
  uuid.v5(uuid.dns_uuid(), <<1:1>>)
  |> should.equal(Error(Nil))
}

pub fn v3_to_bit_array_length_test() {
  let uuid =
    uuid.v3(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> bit_array.byte_size()
  |> should.equal(16)
}

pub fn v3_to_bit_array_correctness_test() {
  let uuid =
    uuid.v3(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
    |> should.be_ok()

  let uuid_from_string =
    uuid
    |> uuid.to_string()
    |> string.replace("-", "")
    |> bit_array.base16_decode()
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> should.equal(uuid_from_string)
}

pub fn v3_from_bit_array_test() {
  let uuid =
    uuid.v3(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> uuid.from_bit_array()
  |> should.be_ok()
  |> should.equal(uuid)
}

//
// V4 Tests
//
pub fn v4_can_validate_self_test() {
  let assert Ok(uuid) =
    uuid.v4()
    |> uuid.to_string()
    |> uuid.from_string()

  uuid
  |> uuid.version
  |> should.equal(uuid.V4)

  uuid
  |> uuid.variant
  |> should.equal(uuid.Rfc4122)
}

pub fn v4_to_bit_array_length_test() {
  let uuid = uuid.v4()

  uuid
  |> uuid.to_bit_array()
  |> bit_array.byte_size()
  |> should.equal(16)
}

pub fn v4_to_bit_array_correctness_test() {
  let uuid = uuid.v4()

  let uuid_from_string =
    uuid
    |> uuid.to_string()
    |> string.replace("-", "")
    |> bit_array.base16_decode()
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> should.equal(uuid_from_string)
}

pub fn v4_from_bit_array_test() {
  let uuid = uuid.v4()

  uuid
  |> uuid.to_bit_array()
  |> uuid.from_bit_array()
  |> should.be_ok()
  |> should.equal(uuid)
}

//
// V5 Tests
//
pub fn v5_dns_namespace_test() {
  let assert Ok(uuid) = uuid.v5(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
  uuid
  |> uuid.to_string
  |> should.equal("016c25fd-70e0-56fe-9d1a-56e80fa20b82")
}

pub fn v5_dont_crash_on_bad_name_test() {
  uuid.v5(uuid.dns_uuid(), <<1:1>>)
  |> should.equal(Error(Nil))
}

pub fn v5_to_bit_array_length_test() {
  let uuid =
    uuid.v5(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> bit_array.byte_size()
  |> should.equal(16)
}

pub fn v5_to_bit_array_correctness_test() {
  let uuid =
    uuid.v5(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
    |> should.be_ok()

  let uuid_from_string =
    uuid
    |> uuid.to_string()
    |> string.replace("-", "")
    |> bit_array.base16_decode()
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> should.equal(uuid_from_string)
}

pub fn v5_from_bit_array_test() {
  let uuid =
    uuid.v5(uuid.dns_uuid(), <<"my.domain.com":utf8>>)
    |> should.be_ok()

  uuid
  |> uuid.to_bit_array()
  |> uuid.from_bit_array()
  |> should.be_ok()
  |> should.equal(uuid)
}

//
// V7 Tests
//
pub fn v7_from_millisec_timestamp_test() {
  let uuid = uuid.v7_from_millisec(1_712_910_566)

  uuid.time_posix_millisec(uuid)
  |> should.equal(1_712_910_566)

  uuid.time_posix_microsec(uuid)
  |> should.equal(1_712_910_566_000)
}

pub fn v7_can_validate_self_test() {
  let assert Ok(uuid) =
    uuid.v7()
    |> uuid.to_string()
    |> uuid.from_string()

  uuid
  |> uuid.version
  |> should.equal(uuid.V7)

  uuid
  |> uuid.variant
  |> should.equal(uuid.Rfc4122)
}

pub fn v7_generation_sequence_test() {
  let ids =
    list.range(0, 1000)
    |> list.map(fn(_) {
      process.sleep(1)
      uuid.v7_string()
    })
  let sorted = list.sort(ids, string.compare)

  sorted
  |> should.equal(ids)
}
