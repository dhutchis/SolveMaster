module Master.Main;

import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;
import std.range;
import std.path : baseName;
import std.getopt;
//import std.file;
//import std.contracts;
//import std.parallelism;
import std.datetime;

import Master.MasterGame;
import Master.MasterPlayer;
import Master.MasterSpecific;
import Master.MasterUtil;

// --genRepGuess --repGuessFile repGuess.txt --depth 2
// Production compiler switches: -release -O -inline -noboundscheck

void print_usage_die(A...)(string[] args, A msg) 
	if (is(typeof({write(msg);}()))) {
	writeln("Usage: ");
	writeln(baseName(args[0]), " [--repGuessFile rep_guess_file] [--target codeWord | --computeAvgGameLength] [--benchmark]\n\tStarts a new game with "
		"the specified target code (or a random one if unspecified) using the representative guess file.\n\t"
		"If computeAvgGameLength is specified, outputs a table with the average game length classified according to first response.");
	writeln(baseName(args[0]), " --genRepGuess --repGuessFile rep_guess_file --depth depth_level [--benchmark]\n\tGenerates a representative "
		"guess file x levels deep and saves it to the file"); 
	writeln(msg);
	exit(0);
}

void printTabs(File f, int numTabs) {
	while (numTabs--)
		f.write(" ");
} 

/// for saving representative guesses to a file
void recurseSaveRepGuess(File f, in int depthLimit, in GuessHistory gh) {
	auto depth = gh.length;
//	writeln("recurse ",gh);
	auto repGs = computeRepresentativeGuesses(gh);
	foreach (const Guess repG; repGs) {
		auto tmp = gh~repG;
		tmp = tmp[0 .. depth+1]; // weird compiler bug workaround
//		writeln(" repG: ",repG," with type",typeid(repG),"; gh~repG (",typeid(tmp),"): ",tmp);//cast(Digit[4][]) (cast(Digit[][])gh ~ cast(Digit[])repG) );
		printTabs(f, depth);
		f.writeln(guessToString(repG));
		if (depth < depthLimit)
			recurseSaveRepGuess(f, depthLimit, tmp);//gh ~ repG);
	}
	
}

/// Reads the first line of a file and returns the maximunm depth of represenative guesses in that file
int getMaxDepthFile(File f) 
in {
	assert( f.isOpen() ); 
	assert( f.tell == 0 ); // we're at the beginning of the file
}
out {
	assert (f.tell == 0); // file is put back at the beginning
}
body {
	scope(exit) f.rewind();
	string firstLine = f.readln();
	int maxDepth = to!int(std.string.stripRight(firstLine)); // kill newline
	assert( maxDepth >= 0 ); // the parameter is valid
	return maxDepth;
}


void main(string[] args) {
	string targetString = "";
	string repGuessFileString = "";
	int depth = -1;
	bool genRepGuess = false;
	bool help = false;
	//bool interactive = true;
	bool computeAvgGameLength = false;
	bool do_benchmark = false;
	TickDuration benchmark_result;
	
	//foreach(a; args) writeln(a);
	getopt(args, std.getopt.config.passThrough,
		"repGuessFile|f", &repGuessFileString,
		"target", &targetString,
		"depth", &depth,
		"genRepGuess", &genRepGuess,
		"help|h|?", &help,
		"computeAvgGameLength", &computeAvgGameLength,
		"benchmark", &do_benchmark//,
		//"interactive|i", &interactive
	);
	
	//computeAvgGameLength = true;
	//repGuessFileString = "../repGuess.txt";
//	repGuessFileString="";
	
//	writeln("ARGS: ",args);
//	print_usage_die(args, "repGuessFile:",repGuessFileString,"; target:",targetString,"; depth:",depth,"; genRepGuess:",genRepGuess);
	if (help || args.length > 1) print_usage_die(args,"");
	
	if (genRepGuess) {
		// generate representative guesses of given depth
		if (repGuessFileString.empty()) print_usage_die(args, "Where should I save the representative guesses?"); 
		if (depth <= 0) print_usage_die(args, "You didn't specify a depth to generate representative guesses");
		File f = File(repGuessFileString, "w");
		
		GuessHistory guessHistory = [[0,1,2,3]]; // initial guess is always 0123
		f.writeln(depth);
		f.writeln(guessToString(guessHistory[0]));
		if (do_benchmark)
			benchmark_result = benchmark!({recurseSaveRepGuess(f, depth, guessHistory);})(1) [0];
		else
			recurseSaveRepGuess(f, depth, guessHistory);
		f.close();
		writeln("Successfully saved representative guesses to depth ",depth," to file ",repGuessFileString);
		
	} else {
		// let's play a game - get the max depth of the repr guesses from the file if it's available
		File f = repGuessFileString.empty() ? File.init : File(repGuessFileString);
		int maxDepthFile = repGuessFileString.empty() ? 0 : getMaxDepthFile(f);
		if (computeAvgGameLength) {
			if (do_benchmark)
				benchmark_result = benchmark!({computeAverageGameLength(f,maxDepthFile);})(1) [0];
			else
				computeAverageGameLength(f,maxDepthFile);
		} else {
			if (!targetString.empty()) {
				// use the given target
				Guess soln = stringToGuess(targetString);
				if (do_benchmark)
					benchmark_result = benchmark!({playGame(new MasterGame( soln ), f, maxDepthFile);})(1) [0];
				else
					playGame(new MasterGame( soln ), f, maxDepthFile);
			} else {
				// use random target
				if (do_benchmark)
					benchmark_result = benchmark!({playGame(new MasterGame(), f, maxDepthFile);})(1) [0];
				else
					playGame(new MasterGame(), f, maxDepthFile);
			}
		}
	}
	if (do_benchmark)
		writeln("Benchmark results: ",benchmark_result.msecs()," ms");
	
}

double computeAverageGameLength(File f, in int maxDepthFile) {
	writeln("about to start"); stdout.flush();
	File savedstdout = stdout;
	version(Windows) stdout = File("NUL","w");
	else stdout = File(r"\dev\null","w");
//	scope(exit) stdout = savedstdout;
	
//	shared string s = f.name();
	ulong[14] categorySum;
	uint[14] categoryCount;
	int i = 0;
//	auto taskPool = new TaskPool();
//	foreach(g; parallel(AllGuessesGenerator(), 20)) {
	foreach(g; AllGuessesGenerator()) {
//		auto f2 = File(s, "r");
		i++;
		//savedstdout.write(i,' '); savedstdout.flush();
		// classify this guess based on the response it generates if the first guess is 0123 
		auto l = playGame(new MasterGame(g), f, maxDepthFile);
		auto idx = responseToPartitionIndex(doCompare(g,[0,1,2,3]));
		categorySum[ idx ] += l;
		categoryCount[idx]++;
		if (i % (cast(int)(5040*0.1)) == 0)
			{savedstdout.write("\nOn guess ",i," / 5040. Computing..."); savedstdout.flush();}
//		f2.close();
	}
//	int i = 5040;
	stdout.close();
	stdout = savedstdout;
	writeln("FirstResp.  Count  Avg.GameLength");
	ulong grandSum = 0;
	uint grandCount = 0;
	foreach(r; AllResponses) {
		auto idx = responseToPartitionIndex(r);
		writeln(responseToString(r),'\t',categoryCount[idx],"   \t",cast(double)(categorySum[idx])/categoryCount[idx]);
		grandSum += categorySum[idx];
		grandCount += categoryCount[idx];
	}
	writeln("Total count of guesses: ",grandCount);
	writeln("Overall average game length: ",cast(double)(grandSum)/grandCount);
	return cast(double)(grandSum)/grandCount; 
}



	// This is to test the reading of the repGuess file.
//	const Guess[] gs = [[0,1,2,3],[1,2,3,5]];
//	//writeln("HEY: ",gs ~ cast(Guess)[5,6,7,8]);
//	File f2 = File(repGuessFileString, "r");
//	scope(exit) f2.close();
//	foreach (Guess g; getRepGuessesFromFile(f2,gs))
//		writeln(guessToString(g));
//	return;
	
	
	
	//playGame(new MasterGame());
	
//	import Master.MasterUtil;
//	enum Guess[] nopast = { Guess[] g; return g;}(); 
//	 assert (computeRepresentativeGuesses(nopast) == [[0,1,2,3]]);
//	enum Guess[] afterfirst = [[0,1,2,3]];
//     Guess[] reprGuess2nd = computeRepresentativeGuesses(afterfirst);
//    assert (reprGuess2nd.length == 19);
//    
//    Guess[][] reprGuess3rd;
//    reprGuess3rd.length = reprGuess2nd.length;
//    uint total_rg = 0;
//    foreach (i, g; reprGuess2nd) {
//if (i == 0) break;
//    	dnoln(afterfirst~g);
//    	reprGuess3rd[i] = computeRepresentativeGuesses(afterfirst~g);
//    	total_rg += reprGuess3rd[i].length;
//    	d(" has ",reprGuess3rd[i].length," repr guesses: ");//,reprGuess3rd[i]);
//
//    }
//    d("Total 3rd level repr. guesses: ",total_rg);
//    d("Average (/",reprGuess2nd.length,") = ",cast(double)(total_rg)/reprGuess2nd.length);
//    assert(reprGuess3rd.length == reprGuess2nd.length);
