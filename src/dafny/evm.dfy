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
include "state.dfy"
include "util/ExtraTypes.dfy"

/**
 * Top-level definition of an Ethereum Virtual Machine.
 */
abstract module EVM {
    import opened EvmState
    import opened Int
    import opened ExtraTypes

    /** The semantics of opcodes.
     *
     *  @param op   The opcode to look up.
     *  @param s    The state to apply the opcode to.
     *  @returns    The new state obtained after applying the semantics
     *              of the opcode.
     *  @note       If an opcode is not supported, or there is not enough gas
     *              the returned state is INVALID.
     */
    function method OpSem(op: u8, s: State): State

    /** The gas cost semantics of an opcode.
     *
     *  @param op   The opcode to look up.
     *  @param s    A state.
     *  @returns    The new state obtained having consumed the gas that corresponds to
     *              the cost of `opcode` is `s`.
     */
    function method OpGas(op: u8, s: State): State

    /**
     * Create a fresh EVM to execute a given sequence of bytecode instructions.
     * The EVM is initialised with an empty stack and empty local memory.
     */
    function method Create(context: Context.T, world: map<u160,WorldState.Account>, gas: nat, code: seq<u8>) : State
    // Code to executed cannot exceed maximum limit.
    requires |code| <= Code.MAX_CODE_SIZE
    // Account under which EVM is executing must exist!
    requires context.address in world {
        var stck := Stack.Create();
        var mem := Memory.Create();
        var wld := WorldState.Create(world);
        var cod := Code.Create(code);
        var evm := EVM(stack:=stck,memory:=mem,world:=wld,context:=context,code:=cod,log:=[],gas:=gas,pc:=0);
        // Off we go!
        State.OK(evm)
    }

    /**
     *  Execute the next instruction.
     *
     *  @param  st  A state.
     *  @returns    The state reached after executing the instruction
     *              pointed to by 'st.PC()'.
     *  @note       If the opcode semantics/gas is not implemented, the next
     *              state is INVALID.
     */
    function method Execute(st:State) : State
    {
        match st.OpDecode()
          case Some(opcode) => OpSem(opcode, OpGas(opcode, st))
          case None => State.INVALID(INVALID_OPCODE)
    }

    /**
     * Perform initial call into this EVM, assuming a given depth.
     *
     * @param world The current state of all accounts.
     * @param ctx The context for this call (where e.g. ctx.address is the recipient).
     * @param code Bytecodes which should be executed.
     * @param gas The available gas to use for the call.
     * @param depth The current call depth.
     */
    method Call(world: WorldState.T, ctx: Context.T, code: seq<u8>, gas: nat, depth: nat) returns (nst:State)
    requires |code| <= Code.MAX_CODE_SIZE
    requires |ctx.callData| < MAX_U256 {
        // Check call depth
        if depth >= 1024 {
            return State.INVALID(CALLDEPTH_EXCEEDED);
        } else {
            // Create default account (if none exists)
            var w := world.EnsureAccount(ctx.address).Deposit(ctx.address,ctx.callValue as nat);
            // Check for end-user account
            if |code| == 0 {
                // Yes, this is an end user account.
                return State.RETURNS(gas, [], []);
            } else {
                // Construct fresh EVM
                var stack := Stack.Create();
                var mem := Memory.Create();
                var cod := Code.Create(code);
                var evm := EVM(ctx,w,stack,mem,cod,[],gas,0);
                // Off we go!
                return State.OK(evm);
            }
        }
    }
}
