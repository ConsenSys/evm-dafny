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
include "../util/arrays.dfy"
include "../util/bytes.dfy"
include "../util/int.dfy"

module Context {
    import opened Arrays
    import opened Int
    import opened Optional
    import ByteUtils

    // =============================================================================
    // Block Context
    // =============================================================================
    datatype Block = Info(
        // Current block's beneficiary address.
        coinBase: u256,
        // Current block's timestamp.
        timeStamp: u256,
        // Current block's number.
        number: u256,
        // Current block's difficulty.
        difficulty: u256,
        // Current block's gas limit.
        gasLimit: u256,
        // Current chain ID.
        chainID: u256,
        // Base fee per gas (EIP1559)
        baseFee: u256
    )

    // =============================================================================
    // Transaction Context
    // =============================================================================

    datatype T = Context(
        // Address of account responsible for this execution.
        sender: u160,
        // Address of original transaction.
        origin: u160,
        // Address of currently executing account.
        address: u160,
        // Value deposited by instruction / transaction responsible for this execution.
        callValue: u256,
        // Input data associated with this call.
        callData: Array<u8>,
        // Return data from last contract call.
        returnData: Array<u8>,
        // Write permission (true means allowed)
        writePermission: bool,
        // Price of gas in current environment.
        gasPrice: u256,
        // Block information in current environment.
        block: Block
    ) {
        /**
         * Determine the size (in bytes) of the call data associated with this
         * context.
         */
        function CallDataSize() : u256 {
            |this.callData| as u256
        }

        /**
         * Read a word from the call data associated with this context.
         */
        function CallDataRead(loc: u256) : u256 {
            ByteUtils.ReadUint256(this.callData,loc as nat)
        }

        /**
         * Slice a sequence of bytes from the call data associated with this
         * context.
         */
        function CallDataSlice(loc: u256, len: nat) : (data:seq<u8>)
        ensures |data| == len {
            Arrays.SliceAndPad(this.callData,loc as nat, len, 0)
        }

        /**
         * Determine the size (in bytes) of the return data from the previous call
         * associated with this context.
         */
        function ReturnDataSize() : u256 {
            |this.returnData| as u256
        }

        /**
         * Slice a sequence of bytes from the return data from the previous call
         * associated with this context.
         */
        function ReturnDataSlice(loc: nat, len: nat) : (data:seq<u8>)
        // Return data cannot overflow.
        requires (loc + len) <= |this.returnData|
        ensures |data| == len {
            Arrays.SliceAndPad(this.returnData,loc, len, 0)
        }

        /**
         * Update the return data associated with this state.
         */
        function SetReturnData(data: Array<u8>) : T {
           this.(returnData:=data)
        }

    }

    /**
     * Create an initial context from various components.
     */
    function Create(sender:u160,origin:u160,recipient:u160,callValue:u256,callData:Array<u8>,writePermission:bool,gasPrice:u256, block: Block) : T {
        Context(sender,origin,address:=recipient,callValue:=callValue,callData:=callData,returnData:=[],writePermission:=writePermission,gasPrice:=gasPrice,block:=block)
    }

    // A simple witness of the Context datatype.
    const DEFAULT : T := Create(0,0,0,0,[],true,0,Block.Info(0,0,0,0,0,0,0))
}
