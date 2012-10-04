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

import Master.MasterGame;
import Master.MasterPlayer;
import Master.MasterSpecific;
import Master.MasterUtil;

void print_usage_die(A...)(string[] args, A msg) 
	if (is(typeof({write(msg);}()))) {
	writeln("Usage: ");
	writeln(baseName(args[0]), " [--repGuessFile rep_guess_file] [--target codeWord]\n\tStarts a new game with "
		"the specified target code (or a random one if unspecified) using the representative guess file");
	writeln(baseName(args[0]), " --genRepGuess --repGuessFile rep_guess_file --depth depth_level\n\tGenerates a representative "
		"guess file x levels deep and saves it to the file"); 
	writeln(msg);
	exit(0);
}

void printTabs(File f, int numTabs) {
	while (numTabs--)
		f.write(" ");
} 

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

void main(string[] args) {
	string targetString = "";
	string repGuessFile = "";
	int depth = -1;
	bool genRepGuess = false;
	bool help = false;
	
	//foreach(a; args) writeln(a);
	getopt(args, std.getopt.config.passThrough,
		"repGuessFile", &repGuessFile,
		"target", &targetString,
		"depth", &depth,
		"genRepGuess", &genRepGuess,
		"help|h|?", &help
	);
//	writeln("ARGS: ",args);
//	print_usage_die(args, "repGuessFile:",repGuessFile,"; target:",targetString,"; depth:",depth,"; genRepGuess:",genRepGuess);
	if (help || args.length > 1) print_usage_die(args,"");
	
	const Guess[] gs = [[0,1,2,3],[1,2,3,5]];
	//writeln("HEY: ",gs ~ cast(Guess)[5,6,7,8]);
	File f2 = File(repGuessFile, "r");
	scope(exit) f2.close();
	foreach (Guess g; getRepGuessesFromFile(f2,gs))
		writeln(guessToString(g));
	return;
	
	if (genRepGuess) {
		// generate representative guesses of given depth
		if (repGuessFile.empty()) print_usage_die(args, "Where should I save the representative guesses?"); 
		if (depth <= 0) print_usage_die(args, "You didn't specify a depth to generate representative guesses");
		File f = File(repGuessFile, "w");
		
		GuessHistory guessHistory = [[0,1,2,3]];
		f.writeln(depth);
		f.writeln(guessToString(guessHistory[0]));
		recurseSaveRepGuess(f, depth, guessHistory);
		f.close();
		
		writeln("yay");
		
	} else {
		// let's play a game
		if (!targetString.empty()) {
			// use the given target
			
		} else {
			// use random target
			
		}
		
	}
	
	
	
	
	
	
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
}