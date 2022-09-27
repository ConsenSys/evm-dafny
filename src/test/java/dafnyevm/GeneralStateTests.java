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
package dafnyevm;

import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.File;
import java.io.IOException;
import java.math.BigInteger;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import org.apache.commons.lang3.tuple.Pair;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.web3j.crypto.Hash;

import dafnyevm.DafnyEvm.State;
import evmtools.util.Bytecodes;
import evmtools.util.Hex;
import evmtools.core.Environment;
import evmtools.core.Trace;
import evmtools.core.TraceTest;
import evmtools.core.Transaction;
import evmtools.core.WorldState;

/**
 * A test runner for executing the <code>GeneralStateTests</code> provided as
 * part of the Ethereum Reference tests (see
 * <a href="https://github.com/ethereum/tests/">here</a>). The test runner works
 * by combining two pieces of information for each tests:
 *
 * <ul>
 * <li><b>Test Fixture</b>. This is the (filled) tests provided by the Ethereum
 * reference tests, and accessible from this repository within the
 * <code>fixtures/</code> directory (which is a submodule).</li>
 * <li><b>Internal State</b>. This internal state information generated from
 * running the corresponding fixture using an existing tool, such as Geth's
 * `evm` command-line tool. This internal state supplements the test fixture
 * which information about the EVM internals during execution of the test (e.g.
 * the value of the stack or memory after executing each bytecode). This data is
 * stored within the <code>tests/</code> directory, where the layout follows
 * that of the <code>fixtures</code> directory.</li>
 * </ul>
 *
 * This test runner is "driven" by the test files stored within the
 * <code>tests/</code>. That means a test is only run when there is a
 * corresponding entry in this file.
 *
 * @author David J. Pearce
 *
 */
public class GeneralStateTests {
	/**
	 * Fork which (for now) I'm assuming we are running on. All others are ignored.
	 */
	public final static String FORK = "Berlin";
	/**
	 * The directory containing the test files.
	 */
	public final static Path TESTS_DIR = Path.of("tests");

	/**
	 * The set of tests which are (for various reasons) currently ignored. Each
	 * ignored test must be given a reason for this.
	 */
	public final static List<String> IGNORES = Arrays.asList( //
			"stExample/invalidTr.json", // Intrinsic Gas.
			"VMTests/vmArithmeticTest/expPower256Of256.json", // performance?
			//
			"stMemoryTest/stackLimitGas_1023.json", // #201
			"stMemoryTest/stackLimitGas_1024.json", // #201
			"stMemoryTest/stackLimitGas_1025.json", // #201
			"vmIOandFlowOperations/jumpToPush.json", // #241
			"stReturnDataTest/modexp_modsize0_returndatasize.json", // #266 (address 0x5)
			"stCreate2/create2callPrecompiles.json", // #266 (address 0x1)
			"stCreate2/CREATE2_Suicide.json", // #274
			"stMemoryTest/oog.json", // #299
			"stCreateTest/CREATE_FirstByte_loop.json", // #299
			"stCreateTest/CREATE_HighNonce.json", // #329
			"stCreate2/CREATE2_HighNonce.json", // #329
			"stSStoreTest/sstore_0to0.json", // #331
			"stSStoreTest/sstore_0to0to0.json", // #331
			"stSStoreTest/sstore_0to0toX.json", // #331
			"stSStoreTest/sstore_0toX.json", // #331
			"stSStoreTest/sstore_0toXto0.json", // #331
			"stSStoreTest/sstore_0toXto0toX.json", // #331
			"stSStoreTest/sstore_0toXtoX.json", // #331
			"stSStoreTest/sstore_0toXtoY.json", // #331
			"stSStoreTest/sstore_Xto0.json", // #331
			"stSStoreTest/sstore_Xto0to0.json", // #331
			"stSStoreTest/sstore_Xto0toX.json", // #331
			"stSStoreTest/sstore_Xto0toXto0.json", // #331
			"stSStoreTest/sstore_Xto0toY.json", // #331
			"stSStoreTest/sstore_XtoX.json", // #331
			"stSStoreTest/sstore_XtoXto0.json", // #331
			"stSStoreTest/sstore_XtoXtoX.json", // #331
			"stSStoreTest/sstore_XtoXtoY.json", // #331
			"stSStoreTest/sstore_XtoY.json", // #331
			"stSStoreTest/sstore_XtoYto0.json", // #331
			"stSStoreTest/sstore_XtoYtoX.json", // #331
			"stSStoreTest/sstore_XtoYtoY.json", // #331
			"stSStoreTest/sstore_XtoYtoZ.json", // #331
			"stRevertTest/RevertInCreateInInit.json", // #343
			// Unknowns
			"stExtCodeHash/extCodeHashCreatedAndDeletedAccountStaticCall.json", // unknown exception ??
			"stCreate2/create2noCash.json", // Unknown exception
			"stCreateTest/CREATE_ContractRETURNBigOffset.json", // large return?
			"stCreateTest/CREATE_ContractSSTOREDuringInit.json", // PERMISSIONS?
			"stCreateTest/CREATE_EContractCreateEContractInInit_Tr.json", // PERMISSIONS?
			"stCreateTest/CREATE_EContractCreateNEContractInInit_Tr.json", // PERMISSIONS?
			// Gas Unknowns
			"stRevertTest/PythonRevertTestTue201814-1430.json", // Gas (STATICALL?)
			//
			"stRevertTest/LoopCallsThenRevert.json",
			"stRevertTest/RevertOpcodeInCallsOnNonEmptyReturnData.json",
			"stRevertTest/RevertOpcodeInCreateReturns.json",
			"VMTests/vmArithmeticTest/twoOps.json",
			"VMTests/vmLogTest/log4.json",
			"VMTests/vmLogTest/log2.json",
			"VMTests/vmLogTest/log0.json",
			"VMTests/vmLogTest/log1.json",
			"VMTests/vmLogTest/log3.json",
			"VMTests/vmIOandFlowOperations/mstore8.json",
			"VMTests/vmIOandFlowOperations/mload.json",
			"VMTests/vmIOandFlowOperations/gas.json",
			"VMTests/vmIOandFlowOperations/loopsConditionals.json",
			"VMTests/vmIOandFlowOperations/return.json",
			"VMTests/vmIOandFlowOperations/pc.json",
			"VMTests/vmIOandFlowOperations/mstore.json",
			"VMTests/vmIOandFlowOperations/sstore_sload.json",
			"stReturnDataTest/call_ecrec_success_empty_then_returndatasize.json",
			"stReturnDataTest/returndatasize_initial.json",
			"stReturnDataTest/returndatasize_after_successful_staticcall.json",
			"stReturnDataTest/returndatacopy_0_0_following_successful_create.json",
			"stReturnDataTest/returndatasize_initial_zero_read.json",
			"stReturnDataTest/call_outsize_then_create_successful_then_returndatasize.json",
			"stReturnDataTest/returndatasize_following_successful_create.json",
			"stReturnDataTest/returndatasize_after_failing_staticcall.json",
			"stReturnDataTest/returndatacopy_after_revert_in_staticcall.json",
			"stReturnDataTest/returndatasize_after_failing_callcode.json",
			"stReturnDataTest/returndatacopy_after_successful_delegatecall.json",
			"stReturnDataTest/call_then_call_value_fail_then_returndatasize.json",
			"stReturnDataTest/returndatasize_after_failing_delegatecall.json",
			"stReturnDataTest/returndatasize_bug.json",
			"stReturnDataTest/returndatacopy_following_call.json",
			"stReturnDataTest/returndatacopy_after_successful_staticcall.json",
			"stReturnDataTest/call_then_create_successful_then_returndatasize.json",
			"stReturnDataTest/returndatacopy_following_revert.json",
			"stReturnDataTest/returndatasize_after_successful_delegatecall.json",
			"stReturnDataTest/returndatacopy_following_revert_in_create.json",
			"stReturnDataTest/returndatacopy_after_successful_callcode.json",
			"stReturnDataTest/returndatacopy_afterFailing_create.json",
			"stReturnDataTest/create_callprecompile_returndatasize.json",
			"stMemoryTest/bufferSrcOffset.json",
			"stCallCodes/callcodeInInitcodeToEmptyContract.json",
			"stCallCodes/callcodeEmptycontract.json",
			"stExtCodeHash/extCodeHashCALL.json",
			"stExtCodeHash/codeCopyZero.json",
			"stExtCodeHash/callToNonExistent.json",
			"stExtCodeHash/dynamicAccountOverwriteEmpty.json",
			"stExtCodeHash/extCodeHashCALLCODE.json",
			"stExtCodeHash/extCodeHashDynamicArgument.json",
			"stExtCodeHash/extCodeHashSelf.json",
			"stExtCodeHash/extCodeHashDELEGATECALL.json",
			"stExtCodeHash/extCodeHashSubcallOOG.json",
			"stExtCodeHash/createEmptyThenExtcodehash.json",
			"stExtCodeHash/extCodeHashSTATICCALL.json",
			"stExtCodeHash/extCodeHashPrecompiles.json",
			"stExtCodeHash/extCodeHashNonExistingAccount.json",
			"stCreate2/call_then_create2_successful_then_returndatasize.json",
			"stCreate2/returndatacopy_0_0_following_successful_create.json",
			"stCreate2/returndatasize_following_successful_create.json",
			"stCreate2/RevertInCreateInInitCreate2.json",
			"stCreate2/Create2OOGafterInitCodeReturndata2.json",
			"stCreate2/call_outsize_then_create2_successful_then_returndatasize.json",
			"stCreate2/Create2OOGafterInitCodeReturndata.json",
			"stCreate2/returndatacopy_following_revert_in_create.json",
			"stCreate2/RevertOpcodeInCreateReturnsCreate2.json",
			"stCreate2/returndatacopy_afterFailing_create.json",
			"stCreate2/Create2OOGafterInitCodeRevert.json",
			"stCreateTest/CreateOOGafterInitCodeRevert2.json",
			"stCreateTest/CodeInConstructor.json",
			"stCreateTest/CreateCollisionResults.json",
			//
			"VMTests/vmArithmeticTest/exp.json", // too slow?
			"vmIOandFlowOperations/jump.json",
			"vmIOandFlowOperations/jumpi.json",
			"stRevertTest/LoopDelegateCallsDepthThenRevert.json",
			"stMemoryTest/memCopySelf.json",
			"stCallCodes/callcallcall_ABCB_RECURSIVE.json",
			"stCallCodes/callcallcallcode_ABCB_RECURSIVE.json",
			"stCallCodes/callcallcodecall_ABCB_RECURSIVE.json",
			"stCallCodes/callcallcodecallcode_ABCB_RECURSIVE.json",
			"stCallCodes/callcodecallcall_ABCB_RECURSIVE.json",
			"stCallCodes/callcodecallcallcode_ABCB_RECURSIVE.json",
			"stCallCodes/callcodecallcodecall_ABCB_RECURSIVE.json",
			"stCallCodes/callcodecallcodecallcode_ABCB_RECURSIVE.json",
			"stCreateTest/CREATE_EContractCreateNEContractInInitOOG_Tr.json",
			"stCreateTest/CREATE_empty000CreateinInitCode_Transaction.json",
			"stCreateTest/TransactionCollisionToEmpty.json",
			"stCreate2/CREATE2_HighNonceDelegatecall.json",
			"stCreate2/Create2OOGafterInitCodeRevert2.json",
			"stCreate2/create2checkFieldsInInitcode.json",
			"stRevertTest/LoopCallsDepthThenRevert2.json",
			"stRevertTest/LoopCallsDepthThenRevert3.json",
			"stRevertTest/LoopCallsDepthThenRevert.json",
			"stRevertTest/RevertRemoteSubCallStorageOOG.json",
			"stExtCodeHash/extcodehashEmpty.json",
			"stExtCodeHash/callToSuicideThenExtcodehash.json",
			"stSStoreTest/InitCollision.json",
			"stSStoreTest/InitCollisionNonZeroNonce.json",
			"stSStoreTest/SstoreCallToSelfSubRefundBelowZero.json",
			"stSStoreTest/sstore_changeFromExternalCallInInitCode.json",
			"stSStoreTest/sstoreGas.json",
			"stSStoreTest/sstore_gasLeft.json",
			"dummy"
	);

	@ParameterizedTest
	@MethodSource("allTestFiles")
	public void tests(Pair<Path,TraceTest.Instance> pair) throws IOException, JSONException {
		final TraceTest.Instance instance = pair.getRight();
		//
		if(isIgnored(pair.getLeft())) {
			// Force test to be ignored.
			assumeTrue(false);
		} else {
			Transaction tx = instance.getTransaction();
			// Construct environment
			DafnyEvm.BlockInfo env = buildEnvironment(instance.getEnvironment());
			// Construct EVM
			ArrayList<Trace.Element> elements = new ArrayList<>();
			StructuredTracer tracer = new StructuredTracer(elements);
			// FIXME: following contains a workaround for an issue with the trace output,
			// whereby traces are used the _block's gas limit_ rather than the
			// _transaction's gas limit_.  #245
			DafnyEvm evm = new DafnyEvm().tracer(tracer).gasPrice(tx.gasPrice).blockInfo(env).to(tx.to).sender(tx.sender)
					.origin(tx.sender).gas(env.gasLimit).value(tx.value).data(tx.data);
			// Configure world state
			configureWorldState(evm,tx,instance.getWorldState());
			// Run the call or create
			if(tx.to != null) {
				evm.call();
			} else {
				evm.create();
			}
			//
			Trace tr = new Trace(elements);
			// Finally check for equality.
			assertEquals(instance.getTrace(),tr);
		}
	}

	private static HashSet<String> visited = new HashSet<>();

	/**
	 * Construct the necessary block environment from the test's environmental
	 * parameters.
	 *
	 * @param env
	 * @return
	 */
	public DafnyEvm.BlockInfo buildEnvironment(Environment env) {
		DafnyEvm.BlockInfo info = new DafnyEvm.BlockInfo();
		info = info.coinBase(env.currentCoinbase);
		info = info.timeStamp(env.currentTimestamp);
		// NOTE: following is commented out whilst trace data is generated using the
		// "evm" tool directly, as this does not allow a block number other than zero.
		//info = info.number(env.currentNumber);
		info = info.number(0);
		info = info.difficulty(env.currentDifficulty);
		info = info.gasLimit(env.currentGasLimit);
		return info;
	}

	/**
	 * Apply
	 * @param st
	 * @param evm
	 * @return
	 */
	public void configureWorldState(DafnyEvm evm, Transaction tx, WorldState ws) {
		// Initialise world statew
		for(Map.Entry<BigInteger, evmtools.core.Account> e : ws.entrySet()) {
			evmtools.core.Account acct = e.getValue();
			evm.create(e.getKey(), acct.nonce, acct.balance, acct.storage, acct.code);
		}
	}

	// Here we enumerate all available test cases.
	private static Stream<Pair<Path,TraceTest.Instance>> allTestFiles() throws IOException {
		return readTestFiles(TESTS_DIR);
	}

	/**
	 * Determine whether this test should be ignore because (for some reason) it is
	 * considered out of scope of the Dafny EVM. This might be due to missing
	 * features (which, eventually, will be implemeted). Or, it might because of
	 * something more fundamental (e.g. something this testing framework cannot
	 * handle).
	 *
	 * @param expect
	 * @return
	 */
	private static boolean isIgnored(Path path) {
		// Normalise path notation for platofmr
		String p = path.toString().replace(File.separator, "/");
		// Check whether this matches an IGNORE or not.
		for (int i = 0; i != IGNORES.size(); ++i) {
			String ith = IGNORES.get(i);
			if (p.endsWith(ith)) {
				return true;
			}
		}
		return false;
	}

	// ======================================================================
	// Helpers
	// ======================================================================

	public static JSONObject readTestFile(Path file) throws IOException, JSONException {
		Path fixture = TESTS_DIR.resolve(file);
		// Read contents of fixture file
		String contents = Files.readString(fixture);
		// Convert fixture into JSON
		return new JSONObject(contents);
	}

	// ======================================================================
	// Data sources
	// ======================================================================

	public static Stream<Pair<Path,TraceTest.Instance>> readTestFiles(Path dir) throws IOException {
		ArrayList<Path> testfiles = new ArrayList<>();
		//
		Files.walk(dir).forEach(f -> {
			if (f.toString().endsWith(".json")) {
				testfiles.add(f);
			}
		});
		// Instantiate each state test into one or more
		return streamTestsFromFiles(testfiles.stream());
	}

	/**
	 * Given a stream of filenames convert this into a stream of test instances. The
	 * reason for doing this is that it can be done lazily, therefore reducing
	 * overall memory footprint.
	 *
	 * @param files
	 * @return
	 */
	private static Stream<Pair<Path,TraceTest.Instance>> streamTestsFromFiles(Stream<Path> files) {
		return files.flatMap(f -> {
			try {
				// Read contents of fixture file
				String contents = Files.readString(f);
				// Convert fixture into JSON
				JSONObject json = new JSONObject(contents);
				// Parse into one or more tests
				ArrayList<Pair<Path, TraceTest.Instance>> instances = new ArrayList<>();
				for (String test : JSONObject.getNames(json)) {
					TraceTest tt = TraceTest.fromJSON(test, json.getJSONObject(test));
					if (tt.hasInstances(FORK)) {
						// Add all instances
						for (TraceTest.Instance i : tt.getInstances(FORK)) {
							instances.add(Pair.of(f, i));
						}
					}
				}
				return instances.stream();
			} catch (JSONException e) {
				e.printStackTrace();
				System.out.println("Problem parsing file into JSON (" + f + ")");
				return null;
			} catch (IOException e) {
				System.out.println("Problem reading file (" + f + ")");
				return null;
			} catch (Exception e) {
				System.out.println("Problem reading file (" + f + ")");
				e.printStackTrace();
				return null;
			}
		});
	}

	public static class StructuredTracer extends DafnyEvm.TraceAdaptor {
		private final List<Trace.Element> out;

		public StructuredTracer(List<Trace.Element> out) {
			this.out = out;
		}

		@Override
		public void step(DafnyEvm.State.Ok state) {
			int pc = state.getPC().intValueExact();
			int op = state.getOpcode();
			int depth = state.getDepth();
			long gas = state.getRemainingGas().longValueExact();
			// NOTE: to make traces equivalent with Geth we cannot appear to have "executed"
			// the invalid bytecode.
			if(op != Bytecodes.INVALID) {
				byte[] memory = state.getMemory();
				BigInteger[] stack = (BigInteger[]) state.getStack();
				// FIXME: this is a hack until such time as Geth actually reports storage.
				//Map<BigInteger, BigInteger> storage = state.getStorage();
				Map<BigInteger, BigInteger> storage = new HashMap<>();
				out.add(new Trace.Step(pc, op, depth, gas, stack, memory, storage));
			} else {
				System.out.println("SKIPPING");
			}
		}

		@Override
		public void end(State.Return state) {
			if(state.depth == 1) {
				// Unfortunately, Geth only reports RETURNS on the outermost contract call.
				out.add(new Trace.Returns(state.getReturnData()));
			}
		}

		@Override
		public void revert(State.Revert state) {
			if(state.depth == 1) {
				// Unfortunately, Geth only reports REVERTS on the outermost contract call.
				out.add(new Trace.Reverts(state.getReturnData()));
			}
		}

		@Override
		public void exception(State.Invalid state) {
			Trace.Exception.Error code = toErrorCode(state.getErrorCode());
			if(!ignored(code)) {
				out.add(new Trace.Exception(code));
			}
		}

		/**
		 * Several exception types are, for whatever reason, not reported by Geth.
		 * @param code
		 * @return
		 */
		private static boolean ignored(Trace.Exception.Error code) {
			switch(code) {
			case ACCOUNT_COLLISION:
				return true;
			default:
				return false;
			}
		}
	}

	public static Trace.Exception.Error toErrorCode(EvmState_Compile.Error err) {
		if (err instanceof EvmState_Compile.Error_INSUFFICIENT__GAS) {
			return Trace.Exception.Error.INSUFFICIENT_GAS;
		} else if (err instanceof EvmState_Compile.Error_INVALID__OPCODE) {
			return Trace.Exception.Error.INVALID_OPCODE;
		} else if (err instanceof EvmState_Compile.Error_INVALID__JUMPDEST) {
			return Trace.Exception.Error.INVALID_JUMPDEST;
		} else if (err instanceof EvmState_Compile.Error_STACK__OVERFLOW) {
			return Trace.Exception.Error.STACK_OVERFLOW;
		} else if (err instanceof EvmState_Compile.Error_STACK__UNDERFLOW) {
			return Trace.Exception.Error.STACK_UNDERFLOW;
		} else if (err instanceof EvmState_Compile.Error_MEMORY__OVERFLOW) {
			return Trace.Exception.Error.MEMORY_OVERFLOW;
		} else if (err instanceof EvmState_Compile.Error_RETURNDATA__OVERFLOW) {
			return Trace.Exception.Error.RETURNDATA_OVERFLOW;
		} else if (err instanceof EvmState_Compile.Error_INSUFFICIENT__FUNDS) {
			return Trace.Exception.Error.INSUFFICIENT_FUNDS;
		} else if (err instanceof EvmState_Compile.Error_CALLDEPTH__EXCEEDED) {
			return Trace.Exception.Error.CALLDEPTH_EXCEEDED;
		} else if (err instanceof EvmState_Compile.Error_ACCOUNT__COLLISION) {
			return Trace.Exception.Error.ACCOUNT_COLLISION;
		} else {
			return Trace.Exception.Error.UNKNOWN;
		}
	}
}
