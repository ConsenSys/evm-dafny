include "../../../dafny/util/int.dfy"
include "../utils.dfy"

module IntTests {
    import opened Int
    import opened Utils
    import opened U16
    import opened U256
    import opened I256
    import opened Word
    import opened Optional

    // Various tests for roundup
    method {:test} RoundUpTests() {
        AssertAndExpect(RoundUp(2,16) == 16);
        AssertAndExpect(RoundUp(16,16) == 16);
        AssertAndExpect(RoundUp(17,16) == 32);
        AssertAndExpect(RoundUp(31,16) == 32);
        AssertAndExpect(RoundUp(32,16) == 32);
        AssertAndExpect(RoundUp(33,16) == 48);
    }

    // Various sanity tests for division.
    method {:test} DivTests() {
        // pos-pos
        AssertAndExpect(Int.Div(6,2) == 3);
        AssertAndExpect(Int.Div(6,3) == 2);
        AssertAndExpect(Int.Div(6,4) == 1);
        AssertAndExpect(Int.Div(9,4) == 2);
        // neg-pos
        AssertAndExpect(Int.Div(-6,2) == -3);
        AssertAndExpect(Int.Div(-6,3) == -2);
        AssertAndExpect(Int.Div(-6,4) == -1);
        AssertAndExpect(Int.Div(-9,4) == -2);
        // pos-neg
        AssertAndExpect(Int.Div(6,-2) == -3);
        AssertAndExpect(Int.Div(6,-3) == -2);
        AssertAndExpect(Int.Div(6,-4) == -1);
        AssertAndExpect(Int.Div(9,-4) == -2);
        // neg-neg
        AssertAndExpect(Int.Div(-6,-2) == 3);
        AssertAndExpect(Int.Div(-6,-3) == 2);
        AssertAndExpect(Int.Div(-6,-4) == 1);
        AssertAndExpect(Int.Div(-9,-4) == 2);
        // Misc
        AssertAndExpect(Int.Div(-1,1) == -1);
    }

    // Various sanity tests for Remainder.
    method {:test} RemTests() {
        // pos-pos
        AssertAndExpect(Int.Rem(6,2) == 0);
        AssertAndExpect(Int.Rem(6,3) == 0);
        AssertAndExpect(Int.Rem(6,4) == 2);
        AssertAndExpect(Int.Rem(9,4) == 1);
        // neg-pos
        AssertAndExpect(Int.Rem(-6,2) == 0);
        AssertAndExpect(Int.Rem(-6,3) == 0);
        AssertAndExpect(Int.Rem(-6,4) == -2);
        AssertAndExpect(Int.Rem(-9,4) == -1);
        // pos-neg
        AssertAndExpect(Int.Rem(6,-2) == 0);
        AssertAndExpect(Int.Rem(6,-3) == 0);
        AssertAndExpect(Int.Rem(6,-4) == 2);
        AssertAndExpect(Int.Rem(9,-4) == 1);
        // neg-neg
        AssertAndExpect(Int.Rem(-6,-2) == 0);
        AssertAndExpect(Int.Rem(-6,-3) == 0);
        AssertAndExpect(Int.Rem(-6,-4) == -2);
        AssertAndExpect(Int.Rem(-9,-4) == -1);
    }

    method {:test} NthUint8Tests() {
        AssertAndExpect(U16.NthUint8(0xde80,0) == 0xde);
        AssertAndExpect(U16.NthUint8(0xde80,1) == 0x80);
        // U32
        AssertAndExpect(U32.NthUint16(0x1230de80,0) == 0x1230);
        AssertAndExpect(U32.NthUint16(0x1230de80,1) == 0xde80);
        // U64
        AssertAndExpect(U64.NthUint32(0x00112233_44556677,0) == 0x00112233);
        AssertAndExpect(U64.NthUint32(0x00112233_44556677,1) == 0x44556677);
        // U128
        AssertAndExpect(U128.NthUint64(0x0011223344556677_8899AABBCCDDEEFF,0) == 0x0011223344556677);
        AssertAndExpect(U128.NthUint64(0x0011223344556677_8899AABBCCDDEEFF,1) == 0x8899AABBCCDDEEFF);
        // U256
        AssertAndExpect(U256.NthUint128(0x00112233445566778899AABBCCDDEEFF_FFEEDDCCBBAA99887766554433221100,0) == 0x00112233445566778899AABBCCDDEEFF);
        AssertAndExpect(U256.NthUint128(0x00112233445566778899AABBCCDDEEFF_FFEEDDCCBBAA99887766554433221100,1) == 0xFFEEDDCCBBAA99887766554433221100);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,00) == 0x00);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,01) == 0x01);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,02) == 0x02);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,03) == 0x03);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,04) == 0x04);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,05) == 0x05);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,06) == 0x06);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,07) == 0x07);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,08) == 0x08);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,09) == 0x09);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,10) == 0x0A);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,11) == 0x0B);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,12) == 0x0C);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,13) == 0x0D);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,14) == 0x0E);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,15) == 0x0F);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,16) == 0x10);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,17) == 0x11);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,18) == 0x12);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,19) == 0x13);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,20) == 0x14);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,21) == 0x15);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,22) == 0x16);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,23) == 0x17);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,24) == 0x18);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,25) == 0x19);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,26) == 0x1A);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,27) == 0x1B);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,28) == 0x1C);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,29) == 0x1D);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,30) == 0x1E);
        AssertAndExpect(U256.NthUint8(0x000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F,31) == 0x1F);
    }

    method {:test} ToBytesTests() {
        // U16
        AssertAndExpect(U16.ToBytes(0) == [0x00,0x00]);
        AssertAndExpect(U16.ToBytes(1) == [0x00,0x01]);
        AssertAndExpect(U16.ToBytes(258) == [0x01,0x02]);
        AssertAndExpect(U16.ToBytes(32769) == [0x80,0x01]);
        // U32
        AssertAndExpect(U32.ToBytes(0) == [0x00,0x00,0x00,0x00]);
        AssertAndExpect(U32.ToBytes(1) == [0x00,0x00,0x00,0x01]);
        AssertAndExpect(U32.ToBytes(258) == [0x00,0x00,0x01,0x02]);
        AssertAndExpect(U32.ToBytes(33554437) == [0x02,0x00,0x00,0x05]);
        // U64
        AssertAndExpect(U64.ToBytes(0) == [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]);
        AssertAndExpect(U64.ToBytes(1) == [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01]);
        AssertAndExpect(U64.ToBytes(258) == [0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x02]);
        AssertAndExpect(U64.ToBytes(33554437) == [0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x05]);
        AssertAndExpect(U64.ToBytes(65536 * 33554437) == [0x00,0x00,0x02,0x00,0x00,0x05,0x00,0x00]);
        // Uint
        AssertAndExpect(Int.ToBytes(0) == [0x00]);
        AssertAndExpect(Int.ToBytes(1) == [0x01]);
        AssertAndExpect(Int.ToBytes(256) == [0x01,0x00]);
        AssertAndExpect(Int.ToBytes(257) == [0x01,0x01]);
        AssertAndExpect(Int.ToBytes(513) == [0x02,0x01]);
        AssertAndExpect(Int.ToBytes(65535) == [0xff,0xff]);
        AssertAndExpect(Int.ToBytes(65536) == [0x01,0x00,0x00]);
        AssertAndExpect(Int.ToBytes(65537) == [0x01,0x00,0x01]);
        AssertAndExpect(Int.ToBytes(33554437) == [0x02,0x00,0x00,0x05]);
        AssertAndExpect(Int.ToBytes(65536 * 33554437) == [0x02,0x00,0x00,0x05,0x00,0x00]);
    }

    method {:test} FromBytesTests() {
        // Uint
        AssertAndExpect(Int.FromBytes([]) == 0x00);
        AssertAndExpect(Int.FromBytes([0x00]) == 0x00);
        AssertAndExpect(Int.FromBytes([0x01]) == 0x01);
        AssertAndExpect(Int.FromBytes([0xfe]) == 0xfe);
        AssertAndExpect(Int.FromBytes([0x01,0x00]) == 0x100);
        AssertAndExpect(Int.FromBytes([0x10,0xec]) == 0x10ec);
        AssertAndExpect(Int.FromBytes([0xff,0xff]) == 0xffff);
        assert Int.FromBytes([0x01,0x00,0x00]) == 0x010000;
        AssertAndExpect(Int.FromBytes([0x01,0x00,0x00]) == 0x010000);
        assert Int.FromBytes([0x01,0x01,0x01]) == 0x010101;
        AssertAndExpect(Int.FromBytes([0x01,0x01,0x01]) == 0x010101);
        assert {:fuel FromBytes,2} Int.FromBytes([0x02,0x00,0x00,0x05]) == 0x2000005;
        AssertAndExpect(Int.FromBytes([0x02,0x00,0x00,0x05]) == 0x2000005);
    }

    method {:test} SarTests() {
        AssertAndExpect(I256.Sar(4, 1) == 2);
        AssertAndExpect(I256.Sar(4, 2) == 1);
        AssertAndExpect(I256.Sar(4, 3) == 0);
        AssertAndExpect(I256.Sar(4, 4) == 0);
        AssertAndExpect(I256.Sar(15, 1) == 7);
        AssertAndExpect(I256.Sar(15, 2) == 3);
        AssertAndExpect(I256.Sar(15, 3) == 1);
        AssertAndExpect(I256.Sar(15, 4) == 0);
        AssertAndExpect(I256.Sar(90, 1) == 45);
        AssertAndExpect(I256.Sar(90, 2) == 22);
        AssertAndExpect(I256.Sar(90, 3) == 11);
        AssertAndExpect(I256.Sar(90, 4) == 5);
        AssertAndExpect(I256.Sar(-90, 1) == -45);
        AssertAndExpect(I256.Sar(-90, 2) == -23);
        AssertAndExpect(I256.Sar(-90, 3) == -12);
        AssertAndExpect(I256.Sar(-90, 4) == -6);
        AssertAndExpect(I256.Sar(-15, 1) == -8);
        AssertAndExpect(I256.Sar(-15, 2) == -4);
        AssertAndExpect(I256.Sar(-15, 3) == -2);
        AssertAndExpect(I256.Sar(-15, 4) == -1);
        AssertAndExpect(I256.Sar(-4, 1) == -2);
        AssertAndExpect(I256.Sar(-4, 2) == -1);
        AssertAndExpect(I256.Sar(-4, 3) == -1);
        AssertAndExpect(I256.Sar(-4, 4) == -1);
        AssertAndExpect(I256.Sar(-1, 1) == -1);
        AssertAndExpect(I256.Sar(1, 256) == 0);
        AssertAndExpect(I256.Sar(-1, 256) == -1);
        AssertAndExpect(I256.Sar(-TWO_128 as i256, 256) == -1);
    }

    method {:test} Log2Tests() {
        // U8
        AssertAndExpect(U8.Log2(0) == 0);
        AssertAndExpect(U8.Log2(1) == 0);
        AssertAndExpect(U8.Log2(2) == 1);
        AssertAndExpect(U8.Log2(3) == 1);
        AssertAndExpect(U8.Log2(4) == 2);
        AssertAndExpect(U8.Log2(5) == 2);
        AssertAndExpect(U8.Log2(6) == 2);
        AssertAndExpect(U8.Log2(7) == 2);
        AssertAndExpect(U8.Log2(8) == 3);
        AssertAndExpect(U8.Log2(9) == 3);
        AssertAndExpect(U8.Log2(10) == 3);
        AssertAndExpect(U8.Log2(11) == 3);
        AssertAndExpect(U8.Log2(12) == 3);
        AssertAndExpect(U8.Log2(13) == 3);
        AssertAndExpect(U8.Log2(14) == 3);
        AssertAndExpect(U8.Log2(15) == 3);
        AssertAndExpect(U8.Log2(16) == 4);
        AssertAndExpect(U8.Log2(17) == 4);
        AssertAndExpect(U8.Log2(28) == 4);
        AssertAndExpect(U8.Log2(29) == 4);
        AssertAndExpect(U8.Log2(30) == 4);
        AssertAndExpect(U8.Log2(31) == 4);
        AssertAndExpect(U8.Log2(32) == 5);
        AssertAndExpect(U8.Log2(33) == 5);
        AssertAndExpect(U8.Log2(60) == 5);
        AssertAndExpect(U8.Log2(61) == 5);
        AssertAndExpect(U8.Log2(62) == 5);
        AssertAndExpect(U8.Log2(63) == 5);
        AssertAndExpect(U8.Log2(64) == 6);
        AssertAndExpect(U8.Log2(65) == 6);
        AssertAndExpect(U8.Log2(66) == 6);
        AssertAndExpect(U8.Log2(126) == 6);
        AssertAndExpect(U8.Log2(127) == 6);
        AssertAndExpect(U8.Log2(128) == 7);
        AssertAndExpect(U8.Log2(129) == 7);
        AssertAndExpect(U8.Log2(130) == 7);
        AssertAndExpect(U8.Log2(181) == 7);
        AssertAndExpect(U8.Log2(182) == 7);
        AssertAndExpect(U8.Log2(183) == 7);
        AssertAndExpect(U8.Log2(184) == 7);
        AssertAndExpect(U8.Log2(185) == 7);
        AssertAndExpect(U8.Log2(186) == 7);
        AssertAndExpect(U8.Log2(254) == 7);
        AssertAndExpect(U8.Log2(255) == 7);
        // U16
        AssertAndExpect(U16.Log2(0) == 0);
        AssertAndExpect(U16.Log2(1) == 0);
        AssertAndExpect(U16.Log2(2) == 1);
        AssertAndExpect(U16.Log2(3) == 1);
        AssertAndExpect(U16.Log2(4) == 2);
        AssertAndExpect(U16.Log2(5) == 2);
        AssertAndExpect(U16.Log2(254) == 7);
        AssertAndExpect(U16.Log2(255) == 7);
        AssertAndExpect(U16.Log2(256) == 8);
        AssertAndExpect(U16.Log2(257) == 8);
        AssertAndExpect(U16.Log2(511) == 8);
        AssertAndExpect(U16.Log2(512) == 9);
        AssertAndExpect(U16.Log2(513) == 9);
        AssertAndExpect(U16.Log2(1023) == 9);
        AssertAndExpect(U16.Log2(1024) == 10);
        AssertAndExpect(U16.Log2(1025) == 10);
        AssertAndExpect(U16.Log2(65534) == 15);
        AssertAndExpect(U16.Log2(65535) == 15);
        // U32
        AssertAndExpect(U32.Log2(0) == 0);
        AssertAndExpect(U32.Log2(1) == 0);
        AssertAndExpect(U32.Log2(2) == 1);
        AssertAndExpect(U32.Log2(3) == 1);
        AssertAndExpect(U32.Log2(4) == 2);
        AssertAndExpect(U32.Log2(5) == 2);
        AssertAndExpect(U32.Log2(254) == 7);
        AssertAndExpect(U32.Log2(255) == 7);
        AssertAndExpect(U32.Log2(65535) == 15);
        AssertAndExpect(U32.Log2(65536) == 16);
        AssertAndExpect(U32.Log2(131071) == 16);
        AssertAndExpect(U32.Log2(131072) == 17);
        AssertAndExpect(U32.Log2(262143) == 17);
        AssertAndExpect(U32.Log2(262144) == 18);
        AssertAndExpect(U32.Log2(MAX_U32 as u32) == 31);
        // U64
        AssertAndExpect(U64.Log2(0) == 0);
        AssertAndExpect(U64.Log2(1) == 0);
        AssertAndExpect(U64.Log2(2) == 1);
        AssertAndExpect(U64.Log2(3) == 1);
        AssertAndExpect(U64.Log2(4) == 2);
        AssertAndExpect(U64.Log2(5) == 2);
        AssertAndExpect(U64.Log2(254) == 7);
        AssertAndExpect(U64.Log2(255) == 7);
        AssertAndExpect(U64.Log2(65535) == 15);
        AssertAndExpect(U64.Log2(65536) == 16);
        AssertAndExpect(U64.Log2(MAX_U32 as u64) == 31);
        AssertAndExpect(U64.Log2(TWO_32 as u64) == 32);
        AssertAndExpect(U64.Log2(MAX_U64 as u64) == 63);
        // U128
        AssertAndExpect(U128.Log2(0) == 0);
        AssertAndExpect(U128.Log2(1) == 0);
        AssertAndExpect(U128.Log2(2) == 1);
        AssertAndExpect(U128.Log2(3) == 1);
        AssertAndExpect(U128.Log2(4) == 2);
        AssertAndExpect(U128.Log2(5) == 2);
        AssertAndExpect(U128.Log2(254) == 7);
        AssertAndExpect(U128.Log2(255) == 7);
        AssertAndExpect(U128.Log2(65535) == 15);
        AssertAndExpect(U128.Log2(65536) == 16);
        AssertAndExpect(U128.Log2(MAX_U32 as u128) == 31);
        AssertAndExpect(U128.Log2(TWO_32 as u128) == 32);
        AssertAndExpect(U128.Log2(MAX_U64 as u128) == 63);
        AssertAndExpect(U128.Log2(TWO_64 as u128) == 64);
        AssertAndExpect(U128.Log2(MAX_U128 as u128) == 127);
        // U256
        AssertAndExpect(U256.Log2(0) == 0);
        AssertAndExpect(U256.Log2(1) == 0);
        AssertAndExpect(U256.Log2(2) == 1);
        AssertAndExpect(U256.Log2(3) == 1);
        AssertAndExpect(U256.Log2(4) == 2);
        AssertAndExpect(U256.Log2(5) == 2);
        AssertAndExpect(U256.Log2(254) == 7);
        AssertAndExpect(U256.Log2(255) == 7);
        AssertAndExpect(U256.Log2(65535) == 15);
        AssertAndExpect(U256.Log2(65536) == 16);
        AssertAndExpect(U256.Log2(MAX_U32 as u256) == 31);
        AssertAndExpect(U256.Log2(TWO_32 as u256) == 32);
        AssertAndExpect(U256.Log2(MAX_U64 as u256) == 63);
        AssertAndExpect(U256.Log2(TWO_64 as u256) == 64);
        AssertAndExpect(U256.Log2(MAX_U128 as u256) == 127);
        AssertAndExpect(U256.Log2(TWO_128 as u256) == 128);
        AssertAndExpect(U256.Log2(MAX_U256 as u256) == 255);
    }

    method {:test} Log256Tests() {
        AssertAndExpect(U256.Log256(0) == 0);
        AssertAndExpect(U256.Log256(1) == 0);
        AssertAndExpect(U256.Log256(0x80) == 0);
        AssertAndExpect(U256.Log256(0xff) == 0);
        AssertAndExpect(U256.Log256(0x100) == 1);
        AssertAndExpect(U256.Log256(0x554) == 1);
        AssertAndExpect(U256.Log256(0x3334) == 1);
        AssertAndExpect(U256.Log256(0xffff) == 1);
        AssertAndExpect(U256.Log256(0x1_0000) == 2);
        AssertAndExpect(U256.Log256(1020314) == 2);
        AssertAndExpect(U256.Log256(16777215) == 2);
        AssertAndExpect(U256.Log256(16777216) == 3);
        AssertAndExpect(U256.Log256(1677091272) == 3);
        AssertAndExpect(U256.Log256(0xffff_ffff) == 3);
        AssertAndExpect(U256.Log256(0x1_0000_0000) == 4);
        AssertAndExpect(U256.Log256(0xffff_ffff_ff) == 4);
        AssertAndExpect(U256.Log256(0x1_0000_0000_00) == 5);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff) == 5);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000) == 6);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ff) == 6);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_00) == 7);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff) == 7);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000) == 8);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ff) == 8);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_00) == 9);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff) == 9);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000) == 10);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ff) == 10);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_00) == 11);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff) == 11);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000) == 12);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ff) == 12);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_00) == 13);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff) == 13);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000) == 14);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 14);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_00) == 15);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 15);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000) == 16);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 16);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_00) == 17);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 17);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000) == 18);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 18);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_00) == 19);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 19);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000) == 20);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 20);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_00) == 21);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 21);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000) == 22);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 22);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_00) == 23);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 23);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000) == 24);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 24);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_00) == 25);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 25);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000) == 26);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 26);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_00) == 27);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 27);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000) == 28);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 28);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_00) == 29);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 29);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000) == 30);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ff) == 30);
        AssertAndExpect(U256.Log256(0x1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_00) == 31);
        AssertAndExpect(U256.Log256(0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff) == 31);
    }

    method {:test} WordTests() {
        // ==>
        AssertAndExpect(Word.asI256(0) == 0);
        AssertAndExpect(Word.asI256(MAX_U256 as u256) == -1);
        AssertAndExpect(Word.asI256(MAX_I256 as u256) == (MAX_I256 as i256));
        AssertAndExpect(Word.asI256((MAX_I256 + 1) as u256) == (MIN_I256 as i256));
        // <==
        AssertAndExpect(Word.fromI256(0) == 0);
        AssertAndExpect(Word.fromI256(-1) == (MAX_U256 as u256));
        AssertAndExpect(Word.fromI256(MAX_I256 as i256) == (MAX_I256 as u256));
        AssertAndExpect(Word.fromI256(MIN_I256 as i256) == (TWO_255 as u256));
    }
}
