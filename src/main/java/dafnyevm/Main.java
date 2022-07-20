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

import org.apache.commons.cli.*;

import dafnyevm.util.Tracers;
import dafnyevm.util.Hex;

import java.math.BigInteger;
import java.util.HashMap;

public class Main {

	private static final Option[] OPTIONS = new Option[] {
			new Option("input", true, "Input data for the transaction."),
			new Option("sender", true, "The transaction origin."),
			new Option("debug", false, "Generate trace output"),
			new Option("json", false, "Generate JSON output conforming to EIP-3155")
	};

	public static CommandLine parseCommandLine(String[] args) {
		// Configure command-line options.
		Options options = new Options();
		for(Option o : OPTIONS) { options.addOption(o); }
		CommandLineParser parser = new DefaultParser();
		// use to read Command Line Arguments
		HelpFormatter formatter = new HelpFormatter();  // // Use to Format
		try {
			return parser.parse(options, args);  //it will parse according to the options and parse option value
		} catch (ParseException e) {
			System.out.println(e.getMessage());
			formatter.printHelp("dafnyevm", options);
			System.exit(1);
			return null;
		}
	}

	public static void main(String[] args) {
		// Parse command-line arguments.
		CommandLine cmd = parseCommandLine(args);
		// Extract transaction sender.
		BigInteger sender = Hex.toBigInt(cmd.getOptionValue("sender", "0xdeff"));
		// Extract call data (if applicable)
		byte[] calldata = Hex.toBytes(cmd.getOptionValue("input", "0x"));
		// Continue processing remaining arguments.
		args = cmd.getArgs();
		// Parse input string
		byte[] bytes = Hex.toBytes(args[0]);
		// Construct EVM
		DafnyEvm evm = new DafnyEvm(new HashMap<>(), bytes);
		//
		if(cmd.hasOption("json")) {
			evm.setTracer(new Tracers.JSON());
		} else if(cmd.hasOption("debug")) {
			evm.setTracer(new Tracers.Debug());
		}
		// Execute the EVM
		evm.call(sender, calldata);
	}
}
