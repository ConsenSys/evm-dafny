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
include "opcodes.dfy"
include "state.dfy"
include "core/memory.dfy"
include "core/code.dfy"
include "core/context.dfy"
include "core/fork.dfy"
include "core/worldstate.dfy"
include "core/substate.dfy"
include "util/bytes.dfy"

module Gas {
	import opened Opcode
	import opened EvmState
    import opened EvmFork
    import opened Int
    import opened Memory

    const G_ZERO: nat := 0
    const G_JUMPDEST: nat := 1
    const G_BASE: nat := 2
	  const G_VERYLOW: nat := 3
    const G_LOW: nat := 5
	const G_MID: nat := 8
	const G_HIGH: nat := 10
    // Cost of a warm account or storage access
    const G_WARMACCESS: nat := 100
    // Cost of a cold account access.
    const G_COLDACCOUNTACCESS: nat := 2600
    // Cost of cold storage access
    const G_COLDSLOAD: nat := 2100
	const G_SSET: nat := 20000
	const G_SRESET: nat := 2900
	const R_SCLEAR: nat := 15000
	const R_SELFDESTRUCT: nat := 24000
	const G_SELFDESTRUCT: nat := 5000
	const G_CREATE: nat := 32000
	const G_CODEDEPOSIT: nat := 200
	const G_CALLVALUE: nat := 9000
	const G_CALLSTIPEND: nat := 2300
	const G_NEWACCOUNT: nat := 25000
	const G_EXP: nat := 10
	const G_EXPBYTE: nat := 50
	const G_MEMORY: nat := 3
	const G_TXCREATE: nat := 32000
	const G_TXDATAZERO: nat := 4
	const G_TXDATANONZERO: nat := 16
	const G_TRANSACTION: nat := 21000
	const G_LOG: nat := 375
	const G_LOGDATA: nat := 8
	const G_LOGTOPIC: nat := 375
	const G_KECCAK256: nat := 30
	const G_KECCAK256WORD: nat := 6
	const G_COPY: nat := 3
	const G_BLOCKHASH: nat := 20
    // EIP-2930
    const G_ACCESS_LIST_ADDRESS_COST: nat := 2400
    const G_ACCESS_LIST_STORAGE_KEY_COST: nat := 1900
    // EIP-3860
    const G_INITCODE_WORD_COST := 2
    /**
     *  Assign a cost as a function of the memory size.
     *
     *  @param  memUsedSize     The size of the memory in 32bytes (words).
     *  @returns                The cost of using a memory of size `memUsedSize`
     *  @note                   The memory cost is linear up to a certain point (
     *                          22*32 = 704 bytes), and then quadratic.
     */
    function {:verify false} QuadraticCost(memUsedSize: nat): nat
    {
        G_MEMORY * memUsedSize + ((memUsedSize * memUsedSize) / 512)
    }

    /**
     *  The quadratic cost function is increasing.
     */
    lemma {:verify false} QuadraticCostIsMonotonic(x: nat, y: nat)
    ensures x >= y ==> QuadraticCost(x) >= QuadraticCost(y)
    {
        if x > y {
           QuadraticCostIsMonotonic(x-1,y);
        }
    }

    /*  Compute the cost of a memory expansion by an arbitrary number of words to cover
     *  a given address and data of length len.
     *
     *  @param   mem         The current memory (also referred to as old memory).
     *  @param   address     The offset to start storing from.
     *  @param   len         The length of data to read or write in bytes.
     *  @results             The number of chunks of 32bytes needed to add to `mem` to cover
     *                       address `address + len - 1`.
     */
    function ExpansionSize(mem: Memory.T, address: nat, len: nat) : nat
    {
        if len == 0 || address + len - 1 < |mem.contents| then
            0
        else
            // NOTE: there is a bug here as this should not round down.
            var before := |mem.contents| / 32;
            var after := Memory.SmallestLarg32(address + len - 1) / 32;
            QuadraticCostIsMonotonic(after, before);
            assert QuadraticCost(after) >= QuadraticCost(before);
            QuadraticCost(after) - QuadraticCost(before)
    }

    /**
     * Compute the memory expansion cost associated with a given memory address
     * and length, where those values are currently stored on the stack.  If
     * there are insufficient operands on the stack, this returns zero so that a
     * stack underflow can be subsequently reported.
     *
     * @param st Current state
     * @param nOperands Total number of operands expected on the stack.
     * @param locSlot Stack slot containing the location to be accessed.
     * @param length  Number of bytes to read.
     */
    function CostExpandBytes(st: ExecutingState, nOperands: nat, locSlot: nat, length: nat) : nat
    requires nOperands > locSlot {
        if st.Operands() >= nOperands
        then
            var loc := st.Peek(locSlot) as nat;
            ExpansionSize(st.evm.memory,loc,length)
        else
            G_ZERO
    }

    /**
     * Compute the memory expansion cost associated with a given memory range,
     * as determined by an address.  The values of the range, however, are
     * currently stored on the stack and therefore need to be peeked.   If
     * there are insufficient operands on the stack, this returns zero so that a
     * stack underflow can be subsequently reported.
     *
     * @param st Current state
     * @param nOperands Total number of operands expected on the stack.
     * @param locSlot Stack slot containing the location to be accessed.
     * @param lenSlot Stack slot containing the number of bytes to access.
     */
    function CostExpandRange(st: ExecutingState, nOperands: nat, locSlot: nat, lenSlot: nat) : nat
    requires nOperands > locSlot && nOperands > lenSlot {
        if st.Operands() >= nOperands
        then
            var loc := st.Peek(locSlot) as nat;
            var len := st.Peek(lenSlot) as nat;
            ExpansionSize(st.evm.memory,loc,len)
        else
            G_ZERO
    }

    /**
     * Compute the memory expansion cost associated with two memory ranges
     * (a+b), as determined by their respective addresses and lengths.  The
     * values of both ranges, however, are currently stored on the stack and
     * therefore need to be peeked.   If there are insufficient operands on the
     * stack, this returns zero so that a stack underflow can be subsequently
     * reported.
     *
     * @param st Current state
     * @param nOperands Total number of operands expected on the stack.
     * @param aLocSlot Stack slot containing location to be accessed (for first range).
     * @param aLenSlot Stack slot containing the number of bytes to access (for first range).
     * @param bLocSlot Stack slot containing location to be accessed (for second range).
     * @param bLenSlot Stack slot containing the number of bytes to access (for second range).
     */
    function CostExpandDoubleRange(st: ExecutingState, nOperands: nat, aLocSlot: nat, aLenSlot: nat, bLocSlot: nat, bLenSlot: nat) : nat
    requires nOperands > aLocSlot && nOperands > aLenSlot
    requires nOperands > bLocSlot && nOperands > bLenSlot {
        if st.Operands() >= nOperands
        then
            // Determine which range is higher in the address space (hence will
            // determine gas requred).
            var aCost := CostExpandRange(st,nOperands,aLocSlot,aLenSlot);
            var bCost := CostExpandRange(st,nOperands,bLocSlot,bLenSlot);
            Int.Max(aCost,bCost)
        else
            G_ZERO
    }

    /**
     * Compute gas cost for copying bytecodes (e.g. CALLDATACOPY).  The stack
     * slot containing the copy length is provided as an argument as this
     * differs between bytecodes (e.g. EXTCODECOPY vs CODECOPY).
     */
    function CostCopy(st: ExecutingState, lenSlot: nat) : nat
    {
        if st.Operands() > lenSlot
        then
            var len := st.Peek(lenSlot) as nat;
            var n := RoundUp(len,32) / 32;
            (G_COPY * n)
        else
            G_ZERO
    }

    /**
     * As defined in EIP-3860.
     */
    function CostInitCode(fork: Fork, len: nat) : nat {
        if fork.IsActive(3860)
        then G_INITCODE_WORD_COST * (Int.RoundUp(len,32)/32)
        else 0
    }

    /*
     * Compute gas cost for CREATE2 bytecode.
     * @param st    A non-failure state.
     */
    function CostCreate(st: ExecutingState) : nat {
        if st.Operands() >= 3
        then
            var len := st.Peek(2) as nat;
            G_CREATE + CostInitCode(st.Fork(),len)
        else
            G_ZERO
    }
    
    /*
     * Compute gas cost for CREATE2 bytecode.
     * @param st    A non-failure state.
     */
    function CostCreate2(st: ExecutingState) : nat
    {
        if st.Operands() >= 4
        then
            var len := st.Peek(2) as nat;
            var rhs := RoundUp(len,32) / 32;
            G_CREATE + (G_KECCAK256WORD * rhs) + CostInitCode(st.Fork(),len)
        else
            G_ZERO
    }

    /*
     * Compute gas cost for KECCAK256 bytecode.
     * @param st    A non-failure state.
     */
    function CostKeccak256(st: ExecutingState) : nat
    {
        if st.Operands() >= 2
        then
            var len := st.Peek(1) as nat;
            var rhs := RoundUp(len,32) / 32;
            G_KECCAK256 + (G_KECCAK256WORD * rhs)
        else
            G_ZERO
    }

    /*
     * Compute gas cost for LogX bytecode.
     * @param st    A non-failure state.
     * @param n     The number of topics being logged.
     */
    function CostLog(st: ExecutingState, n: nat) : nat
    {
        if st.Operands() >= 2
        then
            // Determine how many bytes of log data
            var loc := st.Peek(0) as nat;
            var len := st.Peek(1) as nat;
            // Do the calculation!
            G_LOG + (len * G_LOGDATA) + (n * G_LOGTOPIC)
        else
            G_ZERO
    }

    /**
     * Determine the amount of gas for a CALL bytecode only. Note that GasCap is
     * not included here, as this is accounted for separately.
     * @param st A non-failure state
     * @param nOperands number of operands in total required for this bytecode.
     */
    function CallCost(st: ExecutingState) : nat
    {
        if st.Operands() >= 7
            then
                var value := st.Peek(2) as nat;
                var to := ((st.Peek(1) as int) % TWO_160) as u160;
                CostAccess(st,to) + CostCallXfer(value) + CostCallNew(st,to,value)
        else
            G_ZERO
    }

    /**
     * Determine the amount of gas for a CALLCODE bytecode only. Note
     * that GasCap is not included here, as this is accounted for separately.
     * @param st A non-failure state
     * @param nOperands number of operands in total required for this bytecode.
     */
    function CallCodeCost(st: ExecutingState) : nat
    {
        if st.Operands() >= 7
            then
                var value := st.Peek(2) as nat;
                var to := ((st.Peek(1) as int) % TWO_160) as u160;
                // NOTE: it is not a mistake that CostCallNew() is left out
                // here.  Despite what the yellow paper says, the new account
                // cost is never charged here.
                CostAccess(st,to) + CostCallXfer(value)
        else
            G_ZERO
    }

    /**
     * Determine the amount of gas for a DELEGATECALL bytecode only. Note that
     * GasCap is not included here, as this is accounted for separately.
     * @param st A non-failure state
     * @param nOperands number of operands in total required for this bytecode.
     */
    function DelegateCallCost(st: ExecutingState) : nat
    {
        if st.Operands() >= 6
            then
                var to := ((st.Peek(1) as int) % TWO_160) as u160;
                // NOTE: it is not a mistake that CostCallNew() is left out
                // here.  Despite what the yellow paper says, the new account
                // cost is never charged here.
                CostAccess(st,to)
        else
            G_ZERO
    }

    /**
     * Determine the amount of gas for a STATICCALL.
     * @param st A non-failure state
     * @param nOperands number of operands in total required for this bytecode.
     */
    function StaticCallCost(st: ExecutingState) : nat
    {
        if st.Operands() >= 6
            then
                var to := ((st.Peek(1) as int) % TWO_160) as u160;
                CostAccess(st,to)
        else
            G_ZERO
    }

    /**
     * Determine amount of gas which should be supplied to the caller.
     */
    function CallGas(st: ExecutingState, gas: nat, value: u256) : (r:nat)
    {
        CallGasCap(st,gas) + CallStipend(value)
    }

    /**
     * Determine whether a stipend should be offered (or not).
     */
    function CallStipend(value: u256) : (r:nat) {
        if value != 0 then G_CALLSTIPEND else 0
    }

    /**
     * Determine amount of gas which can be supplied to the caller.  Observe
     * that this cannot exceed the amount of available gas!
     */
    function CallGasCap(st: ExecutingState, gas: nat) : (r:nat)
    {
        Min(L(st.Gas()),gas)
    }

    /**
     * Determine amount of gas which should be provide for a create.
     */
    function CreateGasCap(st: ExecutingState) : (r:nat)
    {
        L(st.Gas())
    }

    /* YP refers to this function by the name "L" */
    function L(n: nat): nat { n - (n / 64) }

    /**
     * Determine any additional costs that apply (this is C_extra in the yellow
     * paper)
     */
    function CostCallExtra(st: ExecutingState, to: u160, value: nat) : nat
    {
        CostAccess(st,to) + CostCallXfer(value) + CostCallNew(st,to,value)
    }

    /**
     * Determine cost for transfering a given amount of value (this is C_xfer in
     * the Yellow paper).
     */
    function CostCallXfer(value: nat) : nat {
        if value != 0 then G_CALLVALUE else 0
    }

    /**
     * Determine cost for creating an account if applicable (this is C_new in
     * the yellow paper).
     */
    function CostCallNew(st: ExecutingState, to: u160, value: nat) : nat
    {
        // if the account is DEAD (which is the default account) or does not
        // exists, then charge G_newaccount amount of gas
        if  st.IsDead(to) && (value != 0)
            then G_NEWACCOUNT
        else
            0
    }

    /**
     * Determine cost for accessing a given contract address.
     */
    function CostExtAccount(st: ExecutingState) : nat
    {
        if st.Operands() >= 1
        then
            // Extract contract account
            var account := (st.Peek(0) as nat % TWO_160) as u160;
            // Cost it!
            CostAccess(st,account)
        else
            G_ZERO
    }

    /**
     * Determine cost for accessing a given contract address (this is C_access
     * in the yellow paper).
     */
    function CostAccess(st: ExecutingState, x: u160) : nat
    {
        if st.WasAccountAccessed(x) then G_WARMACCESS else G_COLDACCOUNTACCESS
    }

    /**
     * Determine cost for load a given storage location in the currently
     * executing account.
     */
    function CostSLoad(st: ExecutingState) : nat
    {
        if st.Operands() >= 1
        then
            var loc := st.Peek(0);
            // Check whether previously accessed or not.
            if st.WasKeyAccessed(loc) then G_WARMACCESS else G_COLDSLOAD
        else
            G_ZERO
    }

    /*
     * Computes the gas charge for an SSTORE instruction.  Note, since refunds
     * are currently ignored by the DafnyEVM, there is no calculation for this.
     */
    function CostSStore(st: ExecutingState): nat {
        var currentAccount := st.evm.world.GetAccount(st.evm.context.address).Unwrap();
        var originalAccount := st.evm.world.GetOrDefaultPretransaction(st.evm.context.address);
        //
        if st.Gas() <= G_CALLSTIPEND
        then
            // NOTE: The following forces an out-of-gas exception if the stipend
            // would be jeorpodised, as following the yellow paper.
            MAX_U256
        else if st.Operands() >= 2
        then
            var loc := st.Peek(0);
            var newVal := st.Peek(1) as nat;
            // Determine access cost
            var accessCost := if st.WasKeyAccessed(loc) then 0 else G_COLDSLOAD;
            // Determine current versus original values
            var currentVal:= Storage.Read(currentAccount.storage, loc) as nat;
            var originalVal := Storage.Read(originalAccount.storage, loc) as nat;
            // Do the calculation
            CostSStoreCalc(originalVal,currentVal,newVal) + accessCost
        else
            G_ZERO
    }

    /**
     * Compututation for SSTORE gas cost based on the various dirty/clean cases,
     * etc.
     */
    function CostSStoreCalc(originalVal: nat, currentVal: nat, newVal: nat): nat {
        if currentVal == newVal
        then
            G_WARMACCESS
        else if originalVal == currentVal
        then
            if originalVal == 0
            then
                G_SSET
            else
                G_SRESET
        else 
            G_WARMACCESS
    }

    /**
     * Determine cost for deleting a given account.
     */
    function CostSelfDestruct(st: ExecutingState) : nat {
        if st.Operands() >= 1
        then
            var r := (st.Peek(0) as nat % TWO_160) as u160;
            // Done
            G_SELFDESTRUCT + CostSelfDestructAccess(st,r) + CostSelfDestructNewAccount(st,r)
        else
            G_ZERO
    }

    function CostSelfDestructAccess(st: ExecutingState, r: u160) : nat {
        if st.WasAccountAccessed(r) then 0 else G_COLDACCOUNTACCESS
    }

    function CostSelfDestructNewAccount(st: ExecutingState, r: u160) : nat {
        // Extract our address
        var Ia := st.evm.context.address;
        // Check whether refund can happen (or not)
        if st.evm.world.IsDead(r) && st.evm.world.Balance(Ia) != 0 then G_NEWACCOUNT else 0
    }

    function CostExp(st: ExecutingState) : nat {
        if st.Operands() >= 2
        then
            var exp := st.Peek(1);
            //
            if exp == 0 then G_EXP
            else
                // Compute logarithim
                var l256 := 1 + U256.Log256(exp);
                // Perform gas calc
                G_EXP + (G_EXPBYTE * l256)
        else
            G_ZERO
    }
}
