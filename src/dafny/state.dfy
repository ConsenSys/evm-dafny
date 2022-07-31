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
include "util/int.dfy"
include "util/memory.dfy"
include "util/storage.dfy"
include "util/stack.dfy"
include "util/context.dfy"
include "util/code.dfy"
include "opcodes.dfy"

module EvmState {
    import opened Int
    import Stack
    import Memory
    import Storage
    import Context
    import Code
    import Opcode

    datatype T = EVM(
        context: Context.T,
        storage : Storage.T,
        stack   : Stack.T,
        memory  : Memory.T,
        code: Code.T,
        gas: nat,
        pc : nat
    )

    /** The type for non failure states. */
    type OKState = s:State | !s.IsFailure() 
      witness OK(
        EVM(
            Context.Create(0xabcd,[]), 
            Storage.Create(map[]), 
            Stack.Create(),
            Memory.Create(),
            Code.Create([]),
            0, 
            0
        )
    )

    /**
    * Captures the possible state of the machine.  Normal execution is indicated
    * by OK (with the current machine data).  An exceptional halt is indicated by INVALID
    * (e.g. insufficient gas, insufficient stack operands, etc).  Finally, a RETURN or REVERT
    * with return data are indicated accordingly (along with any gas returned).
    */
    datatype State = OK(evm:T)
        | INVALID
        | RETURNS(gas:nat,data:seq<u8>)
        | REVERTS(gas:nat,data:seq<u8>) {

        /**
        * Check whether EVM has failed (e.g. due to an exception
        * or a revert, etc) or not.
        */
        predicate method IsFailure() { !this.OK? }

        /**
         * Extract underlying raw state.
         */
        function method Unwrap(): T
        requires !IsFailure() {
            this.evm
        }
        /**
        * Determine number of operands on stack.
        */
        function method Operands() : nat
        requires !IsFailure() {
            Stack.Size(evm.stack)
        }
        /**
        * Determine remaining gas.
        */
        function method Gas(): nat
        requires !IsFailure() {
            this.evm.gas
        }
        /**
        * Determine current PC value.
        */
        function method PC(): nat
        requires !IsFailure() {
            this.evm.pc
        }
        /**
        * Get the state of the internal stack.
        */
        function method GetStack(): Stack.T
        requires !IsFailure() {
            this.evm.stack
        }

        /**
        * Read word from byte address in memory.
        */
        function method Read(address:u256) : u256
        requires !IsFailure()
        requires (address as int) + 31 <= MAX_U256 {
            Memory.ReadUint256(evm.memory,address)
        }

        /**
        * Write word to byte address in memory.
        */
        function method Write(address:u256, val: u256) : State
        requires !IsFailure()
        requires (address as int) + 31 <= MAX_U256 {
            OK(evm.(memory:=Memory.WriteUint256(evm.memory,address,val)))
        }

        /**
        * Write byte to byte address in memory.
        */
        function method Write8(address:u256, val: u8) : State
        requires (address as int) < MAX_U256
        requires !IsFailure() {
            OK(evm.(memory := Memory.WriteUint8(evm.memory,address,val)))
        }

        /**
        * Copy byte sequence to byte address in memory.  Any bytes
        * that overflow are dropped.
        */
        function method Copy(address:u256, data: seq<u8>) : State
        requires (address as int) + |data| <= MAX_U256
        requires !IsFailure() {
            OK(evm.(memory:=Memory.Copy(evm.memory,address,data)))
        }

        /**
         * Write word to storage
         */
        function method Store(address:u256, val: u256) : State
        requires !IsFailure() {
            OK(evm.(storage:=Storage.Write(evm.storage,address,val)))
        }

        /**
         * Read word from storage
         */
        function method Load(address:u256) : u256
        requires !IsFailure() {
            Storage.Read(evm.storage,address)
        }

        /**
         * Decode next opcode from machine.
         */
        function method Decode() : u8
        requires !IsFailure() {
            // Sanity check pc location
            if evm.pc < Code.Size(evm.code) as nat
            then
                Code.DecodeUint8(evm.code,evm.pc as nat)
            else
                Opcode.INVALID
        }

        /**
         * Move program counter to a given location.
         */
        function method Goto(k:u256) : State
        requires !IsFailure() {
        // Sanity check valid target address
        // if k <= Code.Size(evm.code)
        // then 
        State.OK(evm.(pc := k as nat))
        // else State.INVALID
        }

        /**
         * Move program counter to next instruction.
         */
        function method Next() : State
        requires !IsFailure() {
            // if evm.pc < Code.Size(evm.code)
            // then 
            State.OK(evm.(pc := evm.pc + 1))
            // else State.INVALID
        }

        /**
        * Move program counter over k instructions / operands.
        */
        function method Skip(k:nat) : State
        requires !IsFailure() {
            var pc_k := (evm.pc as nat) + k;
            // if pc_k < |evm.code.contents|
            // then 
            State.OK(evm.(pc := pc_k))
            // else State.INVALID
        }

        /**
         * Check capacity remaining on stack.
         */
        function method Capacity() : nat
        requires !IsFailure() {
            Stack.Capacity(evm.stack)
        }

        /**
         * Push word onto stack.
         */
        function method Push(v:u256) : State
        requires !IsFailure()
        requires Capacity() > 0 {
            OK(evm.(stack:=Stack.Push(evm.stack,v)))
        }

        /**
         * peek word from a given position on the stack, where "1" is the
         * topmost position, "2" is the next position and so on.
         */
        function method Peek(k:nat) : u256
        requires !IsFailure()
        // Sanity check peek possible
        requires k < Stack.Size(evm.stack) {
            Stack.Peek(evm.stack,k)
        }

        /**
         * Pop word from stack.
         */
        function method Pop() : State
        requires !IsFailure()
        // Cannot pop from empty stack
        requires Stack.Size(evm.stack) >= 1 {
            OK(evm.(stack:=Stack.Pop(evm.stack)))
        }

        /**
         * Swap top item with kth item.
         */
        function method Swap(k:nat) : State
        requires !IsFailure()
        requires Operands() > k {
            OK(evm.(stack:=Stack.Swap(evm.stack,k)))
        }

        /**
         * Check how many code operands are available.
         */
        function method CodeOperands() : int
        requires !IsFailure() {
            (Code.Size(evm.code) as nat) - ((evm.pc as nat) + 1)
        }

        /**
         * Check whether a given Program Counter location holds the JUMPDEST bytecode.
         */
        predicate method IsJumpDest(pc: u256)
        requires !IsFailure() {
            pc < Code.Size(evm.code) && Code.DecodeUint8(evm.code,pc as nat) == Opcode.JUMPDEST
        }
    }
}