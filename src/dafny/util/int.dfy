/*
 * Copyright 2022 ConsenSys Software Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License. You may obtain
 * a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software dis-
 * tributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */
module Int {
  // Powers of Two
  const TWO_7   : int := 0x0_80;
  const TWO_8   : int := 0x1_00;
  const TWO_15  : int := 0x0_8000;
  const TWO_16  : int := 0x1_0000;
  const TWO_31  : int := 0x0_8000_0000;
  const TWO_32  : int := 0x1_0000_0000;
  const TWO_63  : int := 0x0_8000_0000_0000_0000;
  const TWO_64  : int := 0x1_0000_0000_0000_0000;
  const TWO_127 : int := 0x0_8000_0000_0000_0000_0000_0000_0000_0000;
  const TWO_128 : int := 0x1_0000_0000_0000_0000_0000_0000_0000_0000;
  const TWO_160 : int := 0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
  const TWO_255 : int := 0x0_8000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
  const TWO_256 : int := 0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;

  // Signed Integers
  const MIN_I8   : int := -TWO_7;
  const MAX_I8   : int :=  TWO_7 - 1;
  const MIN_I16  : int := -TWO_15;
  const MAX_I16  : int :=  TWO_15 - 1;
  const MIN_I32  : int := -TWO_31;
  const MAX_I32  : int :=  TWO_31 - 1;
  const MIN_I64  : int := -TWO_63;
  const MAX_I64  : int :=  TWO_63 - 1;
  const MIN_I128 : int := -TWO_127;
  const MAX_I128 : int :=  TWO_127 - 1;
  const MIN_I256 : int := -TWO_255;
  const MAX_I256 : int :=  TWO_255 - 1;

  newtype{:nativeType "sbyte"} i8 = i:int   | MIN_I8 <= i <= MAX_I8
  newtype{:nativeType "short"} i16 = i:int  | MIN_I16 <= i <= MAX_I16
  newtype{:nativeType "int"}   i32 = i:int  | MIN_I32 <= i <= MAX_I32
  newtype{:nativeType "long"}  i64 = i:int  | MIN_I64 <= i <= MAX_I64
  newtype i128 = i:int | MIN_I128 <= i <= MAX_I128
  newtype i256 = i:int | MIN_I256 <= i <= MAX_I256

  // Unsigned Integers
  const MAX_U8 : int :=  TWO_8 - 1;
  const MAX_U16 : int := TWO_16 - 1;
  const MAX_U32 : int := TWO_32 - 1;
  const MAX_U64 : int := TWO_64 - 1;
  const MAX_U128 : int := TWO_128 - 1;
  const MAX_U160: int := TWO_160 - 1;
  const MAX_U256: int := TWO_256 - 1

  newtype{:nativeType "byte"} u8 = i:int    | 0 <= i <= MAX_U8
  newtype{:nativeType "ushort"} u16 = i:int | 0 <= i <= MAX_U16
  newtype{:nativeType "uint"} u32 = i:int   | 0 <= i <= MAX_U32
  newtype{:nativeType "ulong"} u64 = i:int  | 0 <= i <= MAX_U64
  newtype u128 = i:int | 0 <= i <= MAX_U128
  newtype u160 = i:int | 0 <= i <= MAX_U160
  newtype u256 = i:int | 0 <= i <= MAX_U256

  // =========================================================
  // Conversion to/from byte sequences
  // =========================================================

  function method read_u8(bytes: seq<u8>, address:nat) : u8
  requires address < |bytes| {
    bytes[address]
  }

  function method read_u16(bytes: seq<u8>, address:nat) : u16
  requires (address+1) < |bytes| {
    var b1 := bytes[address] as u16;
    var b2 := bytes[address+1] as u16;
    (b1 * (TWO_8 as u16)) + b2
  }

  function method read_u32(bytes: seq<u8>, address:nat) : u32
  requires (address+3) < |bytes| {
    var b1 := read_u16(bytes, address) as u32;
    var b2 := read_u16(bytes, address+2) as u32;
    (b1 * (TWO_16 as u32)) + b2
  }

  function method read_u64(bytes: seq<u8>, address:nat) : u64
  requires (address+7) < |bytes| {
    var b1 := read_u32(bytes, address) as u64;
    var b2 := read_u32(bytes, address+4) as u64;
    (b1 * (TWO_32 as u64)) + b2
  }


  // =========================================================
  // Non-Euclidean Division / Remainder
  // =========================================================

  // This provides a non-Euclidean division operator and is necessary
  // because Dafny (unlike just about every other programming
  // language) supports Euclidean division.  This operator, therefore,
  // always divides *towards* zero.
  function method div(lhs: int, rhs: int) : int
  requires rhs != 0 {
    if lhs >= 0 then lhs / rhs
    else
      -((-lhs) / rhs)
  }

  // This provides a non-Euclidean remainder operator and is necessary
  // because Dafny (unlike just about every other programming
  // language) supports Euclidean division.  Observe that this is a
  // true remainder operator, and not a modulus operator.  For
  // emxaple, this means the result can be negative.
  function method rem(lhs: int, rhs: int) : int
  requires rhs != 0 {
    if lhs >= 0 then (lhs % rhs)
    else
      var d := -((-lhs) / rhs);
      lhs - (d * rhs)
  }

  // Various sanity tests for division.
  method div_tests() {
    // pos-pos
    assert div(6,2) == 3;
    assert div(6,3) == 2;
    assert div(6,4) == 1;
    assert div(9,4) == 2;
    // neg-pos
    assert div(-6,2) == -3;
    assert div(-6,3) == -2;
    assert div(-6,4) == -1;
    assert div(-9,4) == -2;
    // pos-neg
    assert div(6,-2) == -3;
    assert div(6,-3) == -2;
    assert div(6,-4) == -1;
    assert div(9,-4) == -2;
    // neg-neg
    assert div(-6,-2) == 3;
    assert div(-6,-3) == 2;
    assert div(-6,-4) == 1;
    assert div(-9,-4) == 2;
  }

  // Various sanity tests for remainder.
  method rem_tests() {
    // pos-pos
    assert rem(6,2) == 0;
    assert rem(6,3) == 0;
    assert rem(6,4) == 2;
    assert rem(9,4) == 1;
    // neg-pos
    assert rem(-6,2) == 0;
    assert rem(-6,3) == 0;
    assert rem(-6,4) == -2;
    assert rem(-9,4) == -1;
    // pos-neg
    assert rem(6,-2) == 0;
    assert rem(6,-3) == 0;
    assert rem(6,-4) == 2;
    assert rem(9,-4) == 1;
    // neg-neg
    assert rem(-6,-2) == 0;
    assert rem(-6,-3) == 0;
    assert rem(-6,-4) == -2;
    assert rem(-9,-4) == -1;
  }
}

/**
 * Various helper methods related to unsigned 16bit integers.
 */
module U16 {
  import opened Int

  // Read nth 8bit word (i.e. byte) out of this u16, where 0
  // identifies the most significant byte.
  function method nth_u8(v:u16, k: nat) : u8
    // Cannot read more than two words!
  requires k < 2 {
    if k == 0
        then (v / (TWO_8 as u16)) as u8
      else
        (v % (TWO_8 as u16)) as u8
  }

  method tests_nth_u8() {
    assert nth_u8(0xde80,0) == 0xde;
    assert nth_u8(0xde80,1) == 0x80;
  }
}

/**
 * Various helper methods related to unsigned 32bit integers.
 */
module U32 {
  import opened Int

  // Read nth 16bit word out of this u32, where 0 identifies the most
  // significant word.
  function method nth_u16(v:u32, k: nat) : u16
    // Cannot read more than two words!
  requires k < 2 {
    if k == 0
        then (v / (TWO_16 as u32)) as u16
      else
        (v % (TWO_16 as u32)) as u16
  }

  method tests_nth_u16() {
    assert nth_u16(0x1230de80,0) == 0x1230;
    assert nth_u16(0x1230de80,1) == 0xde80;
  }
}

/**
 * Various helper methods related to unsigned 64bit integers.
 */
module U64 {
  import opened Int

  // Read nth 32bit word out of this u64, where 0 identifies the most
  // significant word.
  function method nth_u32(v:u64, k: nat) : u32
    // Cannot read more than two words!
  requires k < 2 {
    if k == 0
        then (v / (TWO_32 as u64)) as u32
      else
        (v % (TWO_32 as u64)) as u32
  }

  method tests_nth_u32() {
    assert nth_u32(0x00112233_44556677,0) == 0x00112233;
    assert nth_u32(0x00112233_44556677,1) == 0x44556677;
  }
}

/**
 * Various helper methods related to unsigned 128bit integers.
 */
module U128 {
  import opened Int

  // Read nth 64bit word out of this u128, where 0 identifies the most
  // significant word.
  function method nth_u64(v:u128, k: nat) : u64
    // Cannot read more than two words!
  requires k < 2 {
    if k == 0
        then (v / (TWO_64 as u128)) as u64
      else
        (v % (TWO_64 as u128)) as u64
  }

  method tests_nth_u64() {
    assert nth_u64(0x0011223344556677_8899AABBCCDDEEFF,0) == 0x0011223344556677;
    assert nth_u64(0x0011223344556677_8899AABBCCDDEEFF,1) == 0x8899AABBCCDDEEFF;
  }
}

/**
 * Various helper methods related to unsigned 256bit integers.
 */
module U256 {
  import opened Int
  import U128
  import U64
  import U32
  import U16

  // Read nth 128bit word out of this u256, where 0 identifies the most
  // significant word.
  function method nth_u128(v:u256, k: nat) : u128
    // Cannot read more than two words!
    requires k < 2 {
      if k == 0
        then (v / (TWO_128 as u256)) as u128
      else
        (v % (TWO_128 as u256)) as u128
  }

  // Read nth byte out of this u256, where 0 identifies the most
  // significant byte.
  function method nth_u8(v:u256, k: nat) : u8
    // Cannot read more than 32bytes!
    requires k < 32 {
      // This is perhaps a tad ugly.  Happy to take suggestions on
      // a better approach :)
      var w128 := nth_u128(v,k / 16);
      var w64 := U128.nth_u64(w128,(k % 16) / 8);
      var w32 :=  U64.nth_u32(w64,(k % 8) / 4);
      var w16 :=  U32.nth_u16(w32,(k % 4) / 2);
      U16.nth_u8(w16,k%2)
  }

  method tests_nth_u128() {
    assert nth_u128(0x00112233445566778899AABBCCDDEEFF_FFEEDDCCBBAA99887766554433221100,0) == 0x00112233445566778899AABBCCDDEEFF;
    assert nth_u128(0x00112233445566778899AABBCCDDEEFF_FFEEDDCCBBAA99887766554433221100,1) == 0xFFEEDDCCBBAA99887766554433221100;
  }

  method tests_nth_u8() {
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,00) == 0x00;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,01) == 0x01;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,02) == 0x02;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,03) == 0x03;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,04) == 0x04;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,05) == 0x05;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,06) == 0x06;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,07) == 0x07;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,08) == 0x08;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,09) == 0x09;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,10) == 0x0A;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,11) == 0x0B;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,12) == 0x0C;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,13) == 0x0D;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,14) == 0x0E;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,15) == 0x0F;
    //
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,16) == 0x10;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,17) == 0x11;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,18) == 0x12;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,19) == 0x13;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,20) == 0x14;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,21) == 0x15;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,22) == 0x16;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,23) == 0x17;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,24) == 0x18;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,25) == 0x19;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,26) == 0x1A;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,27) == 0x1B;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,28) == 0x1C;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,29) == 0x1D;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,30) == 0x1E;
    assert nth_u8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,31) == 0x1F;

  }
}

module I256 {
  import opened Int

  // This provides a non-Euclidean division operator and is necessary
  // because Dafny (unlike just about every other programming
  // language) supports Euclidean division.  This operator, therefore,
  // always divides *towards* zero.
  function method div(lhs: i256, rhs: i256) : i256
    // Cannot divide by zero!
    requires rhs != 0
    // Range restriction to prevent overflow
    requires (rhs != -1 || lhs != (-TWO_255 as i256)) {
    Int.div(lhs as int, rhs as int) as i256
  }

  // This provides a non-Euclidean remainder operator and is necessary
  // because Dafny (unlike just about every other programming
  // language) supports Euclidean division.  Observe that this is a
  // true remainder operator, and not a modulus operator.  For
  // emxaple, this means the result can be negative.
  function method rem(lhs: i256, rhs: i256) : i256
    // Cannot divide by zero!
    requires rhs != 0 {
    Int.rem(lhs as int, rhs as int) as i256
  }
}

module Word {
  import opened Int

  // Decode a 256bit word as a signed 256bit integer.  Since words
  // are represented as u256, the parameter has type u256.  However,
  // its important to note that this does not mean the value in
  // question represents an unsigned 256 bit integer.  Rather, it is a
  // signed integer encoded into an unsigned integer.
  function method asI256(w: u256) : i256 {
    if w > (MAX_I256 as u256)
    then
      var v := 1 + MAX_U256 - (w as int);
      (-v) as i256
    else
      w as i256
  }

  // Encode a 256bit signed integer as a 256bit word.  Since words are
  // represented as u256, the return is represented as u256.  However,
  // its important to note that this does not mean the value in
  // question represents an unsigned 256 bit integer.  Rather, it is a
  // signed integer encoded into an unsigned integer.
  function method fromI256(w: Int.i256) : u256 {
    if w < 0
    then
      var v := 1 + MAX_U256 + (w as int);
      v as u256
    else
      w as u256
  }

  // =========================================================
  // Sanity Checks
  // =========================================================

  method test() {
    // ==>
    assert asI256(0) == 0;
    assert asI256(MAX_U256 as u256) == -1;
    assert asI256(MAX_I256 as u256) == (MAX_I256 as i256);
    assert asI256((MAX_I256 + 1) as u256) == (MIN_I256 as i256);
    // <==
    assert fromI256(0) == 0;
    assert fromI256(-1) == (MAX_U256 as u256);
    assert fromI256(MAX_I256 as i256) == (MAX_I256 as u256);
    assert fromI256(MIN_I256 as i256) == (TWO_255 as u256);
  }
}