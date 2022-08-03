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
include "../evm.dfy"
include "../bytecode.dfy"
include "../gas.dfy"

module EvmBerlin refines EVM {
    import Opcode
    import Bytecode
    import Gas

    /** An empty VM, with some gas.
     *
     *  @param  g   The gas loaded in this EVM.
     *  @returns    An ready-to-use EVM.
     */
    function method InitEmpty(g: nat): State
        ensures !InitEmpty(g).IsFailure()
    {
        var tx := Context.Create(0x0,0,0,[],0);
        Create(tx, map[], g, [])
    }

    /** The gas cost of each opcode. */
    const GAS := Gas.GAS_ONE

    /** The semantics of each opcode. */
    const SEMANTICS := map[
        Opcode.STOP := (s:OKState) => Bytecode.Stop(s),
        Opcode.ADD := (s:OKState) => Bytecode.Add(s),
        Opcode.MUL := (s:OKState) => Bytecode.Mul(s),
        Opcode.SUB := (s:OKState) => Bytecode.Sub(s),
        Opcode.DIV := (s:OKState) => Bytecode.Div(s),
        Opcode.SDIV := (s:OKState) => Bytecode.SDiv(s),
        Opcode.MOD := (s:OKState) => Bytecode.Mod(s),
        Opcode.SMOD := (s:OKState) => Bytecode.SMod(s),
        Opcode.ADDMOD := (s:OKState) => Bytecode.AddMod(s),
        Opcode.MULMOD := (s:OKState) => Bytecode.MulMod(s),
        //  EXP := (s:OKState) => Bytecode.evalEXP(s),
        //  SIGNEXTEND := (s:OKState) => Bytecode.evalSIGNEXTEND(s),
        // 0x10s: Comparison & Bitwise Logic
        Opcode.LT := (s:OKState) => Bytecode.Lt(s),
        Opcode.GT := (s:OKState) => Bytecode.Gt(s),
        Opcode.SLT := (s:OKState) => Bytecode.SLt(s),
        Opcode.SGT := (s:OKState) => Bytecode.SGt(s),
        Opcode.EQ := (s:OKState) => Bytecode.Eq(s),
        Opcode.ISZERO := (s:OKState) => Bytecode.IsZero(s),
        Opcode.AND := (s:OKState) => Bytecode.And(s),
        Opcode.OR := (s:OKState) => Bytecode.Or(s),
        Opcode.XOR := (s:OKState) => Bytecode.Xor(s),
        Opcode.NOT := (s:OKState) => Bytecode.Not(s),
        Opcode.BYTE := (s:OKState) => Bytecode.Byte(s),
        Opcode.SHL := (s:OKState) => Bytecode.Shl(s),
        Opcode.SHR := (s:OKState) => Bytecode.Shr(s),
        //  SAR := (s:OKState) => Bytecode.evalSAR(s),
        // 0x20s
        //  KECCAK256 := (s:OKState) => Bytecode.evalKECCAK256(s),
        // 0x30s: Environment Information
        Opcode.ADDRESS := (s:OKState) => Bytecode.Address(s),
        //  BALANCE := (s:OKState) => Bytecode.evalBALANCE(s),
        Opcode.ORIGIN := (s:OKState) => Bytecode.Origin(s),
        Opcode.CALLER := (s:OKState) => Bytecode.Caller(s),
        Opcode.CALLVALUE := (s:OKState) => Bytecode.CallValue(s),
        Opcode.CALLDATALOAD := (s:OKState) => Bytecode.CallDataLoad(s),
        Opcode.CALLDATASIZE := (s:OKState) => Bytecode.CallDataSize(s),
        Opcode.CALLDATACOPY := (s:OKState) => Bytecode.CallDataCopy(s),
        Opcode.CODESIZE := (s:OKState) => Bytecode.CodeSize(s),
        Opcode.CODECOPY := (s:OKState) => Bytecode.CodeCopy(s),
        Opcode.GASPRICE := (s:OKState) => Bytecode.GasPrice(s),
        //  EXTCODESIZE := (s:OKState) => Bytecode.evalEXTCODESIZE(s),
        //  EXTCODECOPY := (s:OKState) => Bytecode.evalEXTCODECOPY(s),
        //  RETURNDATASIZE := (s:OKState) => Bytecode.evalRETURNDATASIZE(s),
        //  RETURNDATACOPY := (s:OKState) => Bytecode.evalRETURNDATACOPY(s),
        //  EXTCODEHASH := (s:OKState) => Bytecode.evalEXTCODEHASH(s),
        // 0x40s: Block Information
        //  BLOCKHASH := (s:OKState) => Bytecode.evalBLOCKHASH(s),
        //  COINBASE := (s:OKState) => Bytecode.evalCOINBASE(s),
        //  TIMESTAMP := (s:OKState) => Bytecode.evalTIMESTAMP(s),
        //  NUMBER := (s:OKState) => Bytecode.evalNUMBER(s),
        //  DIFFICULTY := (s:OKState) => Bytecode.evalDIFFICULTY(s),
        //  GASLIMIT := (s:OKState) => Bytecode.evalGASLIMIT(s),
        //  CHAINID := (s:OKState) => Bytecode.evalCHAINID(s),
        //  SELFBALANCE := (s:OKState) => Bytecode.evalSELFBALANCE(s),
        // 0x50s: Stack, Memory, Storage and Flow
        Opcode.POP := (s:OKState) => Bytecode.Pop(s),
        Opcode.MLOAD := (s:OKState) => Bytecode.MLoad(s),
        Opcode.MSTORE := (s:OKState) => Bytecode.MStore(s),
        Opcode.MSTORE8 := (s:OKState) => Bytecode.MStore8(s),
        Opcode.SLOAD := (s:OKState) => Bytecode.SLoad(s),
        Opcode.SSTORE := (s:OKState) => Bytecode.SStore(s),
        Opcode.JUMP := (s:OKState) => Bytecode.Jump(s),
        Opcode.JUMPI := (s:OKState) => Bytecode.JumpI(s),
        Opcode.PC := (s:OKState) => if s.PC() <= MAX_U256 then Bytecode.Pc(s) else State.INVALID,
        Opcode.MSIZE := (s:OKState) => Bytecode.MSize(s),
        Opcode.JUMPDEST := (s:OKState) => Bytecode.JumpDest(s),
        // 0x60s & 0x70s: Push operations
        Opcode.PUSH1 := (s: OKState) => Push(s,1),
        Opcode.PUSH2 := (s: OKState) => Push(s,2),
        Opcode.PUSH3 := (s: OKState) => Push(s,3),
        Opcode.PUSH4 := (s: OKState) => Push(s,4),
        // Opcode.PUSH5 := (s: OKState) => Push(s,5),
        // Opcode.PUSH6 := (s: OKState) => Push(s,6),
        // Opcode.PUSH7 := (s: OKState) => Push(s,7),
        // Opcode.PUSH8 := (s: OKState) => Push(s,8),
        // Opcode.PUSH9 := (s: OKState) => Push(s,9),
        // Opcode.PUSH10 := (s: OKState) => Push(s,10),
        // Opcode.PUSH11 := (s: OKState) => Push(s,11),
        // Opcode.PUSH12 := (s: OKState) => Push(s,12),
        // Opcode.PUSH13 := (s: OKState) => Push(s,13),
        // Opcode.PUSH14 := (s: OKState) => Push(s,14),
        // Opcode.PUSH15 := (s: OKState) => Push(s,15),
        // Opcode.PUSH16 := (s: OKState) => Push(s,16),
        // Opcode.PUSH17 := (s: OKState) => Push(s,17),
        // Opcode.PUSH18 := (s: OKState) => Push(s,18),
        // Opcode.PUSH19 := (s: OKState) => Push(s,19),
        // Opcode.PUSH20 := (s: OKState) => Push(s,20),
        // Opcode.PUSH21 := (s: OKState) => Push(s,21),
        // Opcode.PUSH22 := (s: OKState) => Push(s,22),
        // Opcode.PUSH23 := (s: OKState) => Push(s,23),
        // Opcode.PUSH24 := (s: OKState) => Push(s,24),
        // Opcode.PUSH25 := (s: OKState) => Push(s,25),
        // Opcode.PUSH26 := (s: OKState) => Push(s,26),
        // Opcode.PUSH27 := (s: OKState) => Push(s,27),
        // Opcode.PUSH28 := (s: OKState) => Push(s,28),
        // Opcode.PUSH29 := (s: OKState) => Push(s,29),
        // Opcode.PUSH30 := (s: OKState) => Push(s,30),
        // Opcode.PUSH31 := (s: OKState) => Push(s,31),
        // Opcode.PUSH32 := (s: OKState) => Push(s,32),
        // 0x80s: Duplicate operations
        Opcode.DUP1 := (s:OKState) => Bytecode.Dup(s, 1),
        Opcode.DUP2 := (s:OKState) => Bytecode.Dup(s, 2),
        Opcode.DUP3 := (s:OKState) => Bytecode.Dup(s, 3),
        Opcode.DUP4 := (s:OKState) => Bytecode.Dup(s, 4),
        Opcode.DUP5 := (s:OKState) => Bytecode.Dup(s, 5),
        Opcode.DUP6 := (s:OKState) => Bytecode.Dup(s, 6),
        Opcode.DUP7 := (s:OKState) => Bytecode.Dup(s, 7),
        Opcode.DUP8 := (s:OKState) => Bytecode.Dup(s, 8),
        Opcode.DUP9 := (s:OKState) => Bytecode.Dup(s, 9),
        Opcode.DUP10 := (s:OKState) => Bytecode.Dup(s, 10),
        Opcode.DUP11 := (s:OKState) => Bytecode.Dup(s, 11),
        Opcode.DUP12 := (s:OKState) => Bytecode.Dup(s, 12),
        Opcode.DUP13 := (s:OKState) => Bytecode.Dup(s, 13),
        Opcode.DUP14 := (s:OKState) => Bytecode.Dup(s, 14),
        Opcode.DUP15 := (s:OKState) => Bytecode.Dup(s, 15),
        Opcode.DUP16 := (s:OKState) => Bytecode.Dup(s, 16),
        // 0x90s: Exchange operations
        Opcode.SWAP1 := (s:OKState) => Bytecode.Swap(s, 1),
        Opcode.SWAP2 := (s:OKState) => Bytecode.Swap(s, 2),
        Opcode.SWAP3 := (s:OKState) => Bytecode.Swap(s, 3),
        Opcode.SWAP4 := (s:OKState) => Bytecode.Swap(s, 4),
        Opcode.SWAP5 := (s:OKState) => Bytecode.Swap(s, 5),
        Opcode.SWAP6 := (s:OKState) => Bytecode.Swap(s, 6),
        Opcode.SWAP7 := (s:OKState) => Bytecode.Swap(s, 7),
        Opcode.SWAP8 := (s:OKState) => Bytecode.Swap(s, 8),
        Opcode.SWAP9 := (s:OKState) => Bytecode.Swap(s, 9),
        // Opcode.SWAP10 := (s:OKState) => Bytecode.Swap(s, 10),
        // Opcode.SWAP11 := (s:OKState) => Bytecode.Swap(s, 11),
        // Opcode.SWAP12 := (s:OKState) => Bytecode.Swap(s, 12),
        // Opcode.SWAP13 := (s:OKState) => Bytecode.Swap(s, 13),
        // Opcode.SWAP14 := (s:OKState) => Bytecode.Swap(s, 14),
        // Opcode.SWAP15 := (s:OKState) => Bytecode.Swap(s, 15),
        // Opcode.SWAP16 := (s:OKState) => Bytecode.Swap(s, 16),
        // 0xA0s: Log operations
        // else if LOG0 <=opcode <= LOG4 := (s:OKState)
         //   var k := opcode - LOG0) as int; evalLOG(st,k),
        // 0xf0
        //  CREATE := (s:OKState) => Bytecode.evalCREATE(s),
        //  CALL := (s:OKState) => Bytecode.evalCALL(s),
        //  CALLCODE := (s:OKState) => Bytecode.evalCALLCODE(s),
        Opcode.RETURN := (s:OKState) => Bytecode.Return(s),
        // DELEGATECALL := (s:OKState) => Bytecode.evalDELEGATECALL(s),
        // CREATE2 := (s:OKState) => Bytecode.evalCREATE2(s),
        // STATICCALL := (s:OKState) => Bytecode.evalSTATICCALL(s),
        Opcode.REVERT := (s:OKState) => Bytecode.Revert(s)
        // SELFDESTRUCT := (s:OKState) => Bytecode.evalSELFDESTRUCT(s),
    ]

    // A little helper method
    function method Push(s: OKState, k: nat) : State
    requires k > 0 && k <= 32 {
        if s.CodeOperands() >= k
        then
            var bytes := Code.Slice(s.evm.code, (s.evm.pc+1), k);
            assert 0 < |bytes| && |bytes| <= 32;
            Bytecode.Push(s,bytes)
        else
            State.INVALID
    }
}
