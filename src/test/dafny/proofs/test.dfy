include "../../../dafny/evm.dfy"
include "../../../dafny/core/fork.dfy"

import opened Int
import opened Opcode

/**
 */
module Test {

    import opened Int
    import opened Opcode
    import EVM
    import EvmFork
    import Bytecode
    import ByteUtils
    import Gas

    /** The gas loaded in the EVM before executing a program. */
    const INITGAS := 0xFFFFFFFF

    // ===========================================================================
    // Straight line test
    // ===========================================================================

    /**
     *  Run a program with MSTORE and check:
     *  1. execution can go through
     *  2. the gas left at the end of the program.
     */
    method {:verify false} Test_EVM_01(x: u8)
    {
        // Assuption required because Z3 cannot figure this out!
        assume {:axiom} {PUSH1,MSTORE,RETURN} <= EvmFork.BERLIN_BYTECODES;
        // Initialise Bytecode
        var vm := EVM.Init(
          gas := INITGAS,
          code := [
            PUSH1, x,
            PUSH1, 0x0,
            MSTORE,
            PUSH1, 0x1,
            PUSH1, 0x1F,
            RETURN
            ]);

        // PUSH1 x
        vm := EVM.Execute(vm);
        // PUSH1 0x0
        vm := EVM.Execute(vm);
        // MSTORE
        vm := EVM.Execute(vm);
        // PUSH ... RETURN
        vm := EVM.ExecuteN(vm,3);
        //
        assert vm.RETURNS?;
        //
        assert vm.data == [x];
        var g := (5 * Gas.G_VERYLOW) + Gas.G_MEMORY;
        assert g == 0x12;
        // Following should hold.
        assert vm.Gas() == INITGAS - g;
    }

    /**
     *  Same as Test_EVM_01 but using EVM-IR instructions (no code, no PC).
     */
    method {:verify false} Test_IR_01(x: u8)
    {
        // Initialise Bytecode
        var vm := EVM.Init(gas := INITGAS);
        //
        vm := Bytecode.Push1(vm,x);
        vm := Bytecode.Push1(vm,0);
        vm := Bytecode.MStore(vm);
        vm := Bytecode.Push1(vm,0x1);
        vm := Bytecode.Push1(vm,0x1F);
        vm := Bytecode.Return(vm);
        assert vm.RETURNS?;
        //
        assert vm.data  == [x];
    }

    function {:verify false} Test_IR_02b(x: u8, y: u8) : (z:u16)
      ensures z == (x as u16) + (y as u16)
    {
        var xpy := (x as u256) + (y as u256);
        var vm0 := EVM.Init(gas := INITGAS);
        //
        var vm1 := Bytecode.Push1(vm0,x);
        var vm2 := Bytecode.Push1(vm1,y);
        var vm3 := Bytecode.Add(vm2);
        assert vm3.EXECUTING?;
        assert vm3.Peek(0) == xpy;
        var vm4 := Bytecode.Push1(vm3,0);
        var vm5 := Bytecode.MStore(vm4);
        assert vm5.EXECUTING?;
        assert vm5.Read(0) == xpy;
        var vm6 := Bytecode.Push1(vm5,0x2);
        var vm7 := Bytecode.Push1(vm6,0x1E);
        var vm8 := Bytecode.Return(vm7);
        // read 2 bytes from vm.data starting at 0
        ByteUtils.ReadUint16(vm8.data,0)
    }

    /**
     *  Subtract `y` from `x` and return result in `z`.
     */
    method {:verify false} Test_IR_03(x: u8, y: u8) returns (z:u8)
    requires x >= y
    ensures z <= x
    {
        var vm := EVM.Init(gas := INITGAS);
        //
        vm := Bytecode.Push1(vm,y);
        vm := Bytecode.Push1(vm,x);
        vm := Bytecode.Sub(vm); // x - y
        assert vm.Peek(0) == (x as u256) - (y as u256);
        vm := Bytecode.Push1(vm,0);
        vm := Bytecode.MStore(vm);
        vm := Bytecode.Push1(vm,0x1);
        vm := Bytecode.Push1(vm,0x1F);
        vm := Bytecode.Return(vm);
        //  read one byte from vm.data starting at 0
        return ByteUtils.ReadUint8(vm.data,0);
    }

    /**
     *  Subtract `y` from `x` and return result in `z`.
     */
    function Test_IR_03b(x: u8, y: u8) : (z:u8)
    requires x >= y
    ensures z <= x
    {
        var vm0 := EVM.Init(gas := INITGAS);
        //
        var vm1 := Bytecode.Push1(vm0,y);
        var vm2 := Bytecode.Push1(vm1,x);
        var vm3 := Bytecode.Sub(vm2); // x - y
        assert vm3.Peek(0) == (x as u256) - (y as u256);
        var vm4 := Bytecode.Push1(vm3,0);
        var vm5 := Bytecode.MStore(vm4);
        var vm6 := Bytecode.Push1(vm5,0x1);
        var vm7 := Bytecode.Push1(vm6,0x1F);
        var vm8 := Bytecode.Return(vm7);
        //  read one byte from vm.data starting at 0
        ByteUtils.ReadUint8(vm8.data,0)
    }

    // ===========================================================================
    // Branching Tests
    // ===========================================================================

    // This is an underflow test.  Either the contract reverts, or there was no underflow.
    method {:verify false} Test_IR_04(x: u8, y: u8) returns (z:u8, revert:bool)
        // Check revert only when overflow would have occurred.
        ensures revert <==> y > x
        // If didn't revert, then result is less.
        ensures !revert <==> (z <= x)
    {
        // var tx := Context.Create(0xabc,0xdef,0,[],0);
        var vm := EVM.Init(
            gas := INITGAS,
            code := [
                PUSH1, x,
                PUSH1, y,
                GT,
                ISZERO,
                PUSH1, 0x0A,
                JUMPI,
                REVERT,
                JUMPDEST,
                PUSH1, x,
                PUSH1, y,
                SUB,
                PUSH1, 0x0,
                MSTORE,
                PUSH1, 0x1,
                PUSH1, 0x1F,
                RETURN]);
        //
        vm := Bytecode.Push1(vm,x);   // 0x00
        vm := Bytecode.Push1(vm,y);   // 0x02
        vm := Bytecode.Gt(vm);        // 0x04
        vm := Bytecode.IsZero(vm);    // 0x05
        vm := Bytecode.Push1(vm,0xA); // 0x06
        vm := Bytecode.JumpI(vm);     // 0x08
        //
        assert vm.evm.pc == 0x09 <==> y > x;
        if vm.evm.pc == 0x09 {
          vm := Bytecode.Revert(vm);  // 0x09
          return y,true;
        } else {
          // Happy path
          vm := Bytecode.JumpDest(vm); // 0xA
          assert x >= y;
          vm := Bytecode.Push1(vm,y);
          vm := Bytecode.Push1(vm,x);
          vm := Bytecode.Sub(vm); // x - y
          assert vm.Peek(0) == (x as u256) - (y as u256);
          vm := Bytecode.Push1(vm,0);
          vm := Bytecode.MStore(vm);
          vm := Bytecode.Push1(vm,0x1);
          vm := Bytecode.Push1(vm,0x1F);
          vm := Bytecode.Return (vm);
          //
          return ByteUtils.ReadUint8(vm.data,0), false;
        }
    }
}
