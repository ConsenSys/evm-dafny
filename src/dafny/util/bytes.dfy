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
include "int.dfy"

module Bytes {
  import opened Int

    /**
     * Read the byte at a given address in Memory.  If the given location
     * has not been initialised, then zero is returned as default.
     */
    function method read_u8(mem:seq<u8>, address:nat) : u8 {
        // Read location
        if address < |mem|
        then
          mem[address]
        else
          0
    }

    /**
     * Read a 16bit word from a given address in Memory assuming
     * big-endian addressing.  If the read overflows the available
     * data, then it is padded with zeros.
     */
    function method read_u16(mem:seq<u8>, address:nat) : u16 {
        var w1 := read_u8(mem,address) as u16;
        var w2 := read_u8(mem,address+1) as u16;
        (w1 * (TWO_8 as u16)) + w2
    }

    /**
     * Read a 32bit word from a given address in Memory assuming
     * big-endian addressing.
     */
    function method read_u32(mem:seq<u8>, address:nat) : u32 {
        var w1 := read_u16(mem,address) as u32;
        var w2 := read_u16(mem,address+2) as u32;
        (w1 * (TWO_16 as u32)) + w2
    }

    /**
     * Read a 64bit word from a given address in Memory assuming
     * big-endian addressing.  If the read overflows the available
     * data, then it is padded with zeros.
     */
    function method read_u64(mem:seq<u8>, address:nat) : u64 {
        var w1 := read_u32(mem,address) as u64;
        var w2 := read_u32(mem,address+4) as u64;
        (w1 * (TWO_32 as u64)) + w2
    }

    /**
     * Read a 128bit word from a given address in Memory assuming
     * big-endian addressing.  If the read overflows the available
     * data, then it is padded with zeros.
     */
    function method read_u128(mem:seq<u8>, address:nat) : u128 {
        var w1 := read_u64(mem,address) as u128;
        var w2 := read_u64(mem,address+8) as u128;
        (w1 * (TWO_64 as u128)) + w2
    }

    /**
     * Read a 256bit word from a given address in Memory assuming
     * big-endian addressing.  If the read overflows the available
     * data, then it is padded with zeros.
     */
    function method read_u256(mem:seq<u8>, address:nat) : u256 {
        var w1 := read_u128(mem,address) as u256;
        var w2 := read_u128(mem,address+16) as u256;
        (w1 * (TWO_128 as u256)) + w2
    }

    /**
     * Slice out a subsequence of bytes from a given sequence.
     * If the requested subsequence overflows available memory,
     * it is padded out with zeros.
     */
    function method slice(mem:seq<u8>, address:nat, len:nat) : seq<u8> {
      var n := address + len;
      // Sanity check for overflow
      if n <= |mem| then mem[address..n]
      // Yes overflow, so manage it.
      else if address < |mem| then mem[address..] + padding(n-|mem|)
      else padding(len)
    }

    /**
     * Construct a sequence of an arbitrary sized padded out with zeros.
     */
    function method padding(n:nat) : seq<u8> { seq(n, i => 0) }
}
