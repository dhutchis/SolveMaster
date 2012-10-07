module Master.MasterPlayer;
import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;
import std.range;
import std.typecons;
import std.math: log;
//import std.file;

import Master.MasterGame;
import Master.MasterUtil;
import Master.MasterSpecific;

//version = 0;

//Guess[] getRepGuessesFromFile(File f, in int depthRepGuess)
Guess[] getRepGuessesFromFile(File f, in GuessHistory gh)
in { 
	assert( gh.length > 0 ); // we want more than just the first turn guess
	assert( f.isOpen() ); 
	assert( f.tell == 0 ); // we're at the beginning of the file
	string firstLine = f.readln();
	int maxDepth = to!int(std.string.stripRight(firstLine)); // kill newline
	assert( maxDepth >= gh.length ); // the parameter is valid
	f.rewind();
}
out {
	assert (f.tell == 0); // file is put back at the beginning
}
body {
	// throw away first line and second line (which is just 0123)
	f.readln();
	f.readln();
	
	// get to the current representative guess set
	foreach (i, g; gh[1..$])
		findGuessInFile(f, g, i+1, gh);
	
	auto depthRepGuess = gh.length;
	Guess[] repGuesses;
	// the turn 1 guesses have 1 space, etc. (could this be more efficient?)
	foreach ( line; f.byLine()) {
		if (line[depthRepGuess-1] == ' ' && line[depthRepGuess] != ' ') {
			Guess g;
			foreach (i, d; line[depthRepGuess .. depthRepGuess+4])
				g[i] = cast(Digit)(d-'0');
			repGuesses ~= g;
		}
	}
	
	f.rewind();
	return repGuesses;
}

void findGuessInFile(File f, in Guess guess, in int depth, in GuessHistory gh) {
	//writeln("findGuessInFile: ",guessToString(guess)," ",depth);
//	uint n = 0;
	auto start_pos = f.tell();
	bool first_run = true;
	while (true) {
		foreach (line; f.byLine()) {
//			writeln(" ",++n,":",line);
			if (line[depth-1] != ' ') {
				// o no, we overshot it
				break;
			}
			if (line[depth-1] == ' ' && line[depth] != ' ') {
				Guess g;
//				foreach (i, d; line[depth .. depth+4])
//					g[i] = cast(Digit)(d-'0');
				g = stringToGuess(line[depth .. depth+4]);
				if (first_run ? guess == g : findTransform(guess,g,gh)) // check for a transform if we don't find an exact match the first time
					return;
			}
		}
		f.seek(start_pos, SEEK_SET);
		if (!first_run)
			return; // we failed...
		first_run = false;
	}
}

//template staticArrayNDeep(B, int Size, int Depth) 
//  if ( isIntegral!Size && isIntegral!Depth && Depth >= 0 && Size >= 0) {
//	static if (N == 0)
//		alias B staticArrayNDeep;
//	else
//		alias staticArrayNDeep!(B[Size],Size,Depth-1) staticArrayNDeep;
//} staticArrayNDeep!(Guess,14,Depth)

class GuessChain {
	GuessChain[Guess] map;
	
	this() {}
	this(Guess g, GuessChain gc) { map[g] = gc; }
	
	string toString() {
		return text(map);
	}
}

GuessChain getAllRepGuessesFromFile(File f, out int maxDepth)
in {
	assert( f.isOpen() ); 
	assert( f.tell == 0 ); // we're at the beginning of the file
}
out {
	assert (f.tell == 0); // file is put back at the beginning
}
body {
	// throw away first line and second line (which is just 0123)
	string firstLine = f.readln();
	maxDepth = to!int(std.string.stripRight(firstLine)); // kill newline
	
	char[] currentline;
	f.readln(currentline);
	int currentDepth = 0;
	auto ret = recurseReadRepGuessFromFile(f, currentline, currentDepth);
	f.rewind();
	return ret;
}

GuessChain recurseReadRepGuessFromFile(File f, ref char[] currentline, ref int currentDepth) {
//	assert ( {
//		int chkd = 0;
//		while(firstline.front == ' ') {
//			chkd++;
//			line.popFront();
//		}
//		return chkd;
//	}() == currentDepth, "bad current depth");

	int myDepth = currentDepth;
	GuessChain gc = new GuessChain();
	
	do { 
		Guess g = stringToGuess(currentline[currentDepth .. currentDepth+4]);
		gc.map[g] = null;
		
		size_t bytes_read = f.readln(currentline);
		if (bytes_read == 0) { // eof
			currentDepth = -1;
			return gc;
		}
		
		currentDepth = 0;
		foreach (i, c; currentline) {
			if (c == ' ')
				currentDepth++;
			else {
				//guessIdx = i;
				break;
			}
		}
		
		if (currentDepth > myDepth) {
			assert(currentDepth == myDepth+1, "bad file format");
			gc.map[g] = recurseReadRepGuessFromFile(f, currentline, currentDepth);
		}
		
		
	} while (currentDepth >= myDepth);
	
	return gc;
}

Guess[] getReprGuessesFromChainGivenHistory(in GuessChain gc, in GuessHistory past) {
	if (past.empty)
		return gc.map.keys;
	return getReprGuessesFromChainGivenHistory(gc.map[past.front], past[1 .. $]);
}

void writePossibleSolutions(in Guess[] consisT) {
	write("[ ",consisT.length," ] Consistent solutions:");
	if (consisT.length < 20)
		foreach(g; consisT) 
			write(" ",guessToString(g));
	else 
		write(" ...too many to list");
	writeln();
}


/// Plays a game of Mastermind using mg, optionally with the aid of precomputed representative guesses
/// (the file goes maxDepthRepGuess representative guesses deep)
uint playGame(MasterGame mg, in GuessChain gc, in int maxDepthRepGuess) {
	GuessHistory pastGuesses;
	ResponseHistory pastResponses;
	Guess[] consisT; // the set of consistent guesses
	writeln("New Game: ",mg);
	
	// first guess
	Guess first = [0,1,2,3];
	pastGuesses ~= first;
	pastResponses ~= mg.makeGuess(first);
	//writeln("After first guess: ",mg);
	
	// fill consisT with valid possible solutions
	foreach(g; AllGuesses)
		if (testConsistent(g, pastGuesses[0], pastResponses[0]))
			consisT ~= g;
	writePossibleSolutions(consisT);
	
	// while we didn't guess correctly yet
	while (pastResponses[$-1] != [4,0]) {
		PartitionSet psBest;
		Guess bestGuess = findBestGuess(pastGuesses, pastResponses, consisT, gc, maxDepthRepGuess, psBest);
		
		//attempt the best guess
		pastGuesses ~= bestGuess;
		pastResponses ~= mg.makeGuess(bestGuess);
		
		// update consisT according to response
//		Guess[] newConsisT;
//		foreach (g; consisT)
//			if (testConsistent(g, pastGuesses[0], pastResponses[0]))
//				newConsisT ~= g;
		consisT = psBest[responseToPartitionIndex(pastResponses[$-1])];
		
		// show status
		if (pastResponses[$-1] != [4,0])
			writePossibleSolutions(consisT);
	}
	
	writeln("Found solution after ",pastGuesses.length," guesses");
	writeln("Game history: ",mg);
	return pastGuesses.length;
}

Guess findBestGuess(in GuessHistory pastGuesses, in ResponseHistory pastResponses, in Guess[] consisT, in GuessChain gc, in int maxDepthRepGuess, out PartitionSet bestGuessPartitionSet) {
	// before doing anything, if there is only 1 consistent guess, guess it!
	if (consisT.length == 1) {
		writeln("Only 1 consistent guess: ",guessToString(consisT[0]));
		return consisT[0];
	}
	
	/*	We need to choose the guess that maximizes the information we gain after receiving feedback from our guess, ultimately minimizing the average number of guesses before winning.
		First we need to decide what guesses we will consider.  Two strategies:
		1. Use precomputed representative guesses.  They should be precomputed as computing them right now at run time is expensive.  This effectively prunes away all guesses that are
			guranteed to provide the same information as a guess in the representative set, saving quite a few CPU cycles.
		2. If precomputed representative guesses are not available, prune away as many redundant and useless guesses as possible via the guidelines in the function computeGuessesToTry().
			We will likely evaluate many more guesses than if we started with a representative set, but if we use too complex methods here, the cost to evaluate whether we should consider 
			a guess will exceed the cost of just making the guess.
		Next we will evaluate the guesses that pass the previous test by computing the entropy and number of nonempty partitions on the partiton set generated from the 14 possible responses to a guess.
		We will choose the set that has the best entropy and number of nonempty partitions.
	*/
	Guess bestGuess;
	double bestEntropy=0;
	int bestNonemptyParts=0;
	Guess[] reprGuesses;
//	const Guess[] reprGuesses = AllGuesses[]; // the guesses we will evaluate
//	auto reprGuesses = AllGuesses;
	
	//  Do this to compute the representative guesses from scratch
	//latter statement gets them from a precomputed file
	//if (pastGuesses.length <= 3)
	//	reprGuesses = computeRepresentativeGuesses(pastGuesses, pastResponses); // pass response information available at runtime for reduction in reprGuesses size
	
	if (pastGuesses.length <= maxDepthRepGuess) { // if we have precomputed representative guess information
		reprGuesses = getReprGuessesFromChainGivenHistory(gc, pastGuesses); // get the info
		writeln("From precomputed file: ",reprGuesses.length," representative guesses (narrowed down from 5040)");
		if (pastGuesses.length > 3 && haveRepeatedResponses(pastResponses)) { // for turns 3 and up, narrow down the reprGuesses based on whether we had a repeated response
			reprGuesses = computeRepresentativeGuessesNarrowing(pastGuesses, pastResponses, reprGuesses);
			writeln("\tBased on repeated responses in game history, reduced the number of representative guesses to ",reprGuesses.length); 
		}
	} else {
		reprGuesses = computeGuessesToTry(pastGuesses, pastResponses, consisT);
		writeln("Using digit analysis heuristics, reduced guesses to try from 5040 to ",reprGuesses.length);
	}
	//reprGuesses = AllGuesses[];
	
	foreach (i, rg; reprGuesses) { // for each guess to try
		// should we even consider this guess? (even more alpha/beta pruning)
		if (!shouldConsiderGuess(rg, bestGuess,bestEntropy,bestNonemptyParts,bestGuessPartitionSet,consisT)) {
			continue;
		}
		
		// should we stop evaluating guesses return the best right now?
		if (shouldStopEvaluatingGuesses(bestGuess,bestEntropy,bestNonemptyParts, consisT.length-i, bestGuessPartitionSet, consisT)) {
			break;
		}
		
		// EVALUATE GUESS: divide consisT into partitions according to all possible reponses after guessing rg
		int nonemptyParts = 0;
		PartitionSet ps = createPartition(rg, consisT, bestNonemptyParts, nonemptyParts);
		if (ps == PartitionSet.init)
			continue; // we pruned it early in createPartition
		
		// compute entropy, most parts heuristics
		double entropy = 0;
		computeEntropy(consisT.length,ps,entropy);
		version(2) {
			write(" Guess ",guessToString(rg)," has entropy=",entropy,"; nonemptyParts=",nonemptyParts,"; partition sizes");
			foreach (ga; ps) write(" ",ga.length);
			writeln();
		}
		
		// is this guess better than our best so far?
		if (shouldUpdateBestGuess(bestGuess,bestEntropy,bestNonemptyParts, bestGuessPartitionSet,
								rg,entropy,nonemptyParts, ps)) {
			version(1) {
				write(" Replacing previous best guess ",guessToString(bestGuess)," with ",guessToString(rg)," entropy=",entropy,"; nonemptyParts=",nonemptyParts,"; partition sizes");
				foreach (ga; ps) write(" ",ga.length);
				writeln();
			}
			bestGuess = rg; bestEntropy = entropy; bestNonemptyParts = nonemptyParts;
			bestGuessPartitionSet = ps.dup;
		}
	}
	write("Choosing: ",guessToString(bestGuess)," entropy=",bestEntropy,"; nonemptyParts=",bestNonemptyParts,"; partition sizes");
	foreach (ga; bestGuessPartitionSet) write(" ",ga.length);
	writeln();
	
	return bestGuess;
}

bool haveRepeatedResponses(in ResponseHistory pastResponses) {
	foreach(i, r; pastResponses)
		if (canFind(pastResponses[i .. $], r))
			return true;
	return false;
}

/// Use this after it becomes computationally expensive to calculate the minimal set of representative guesses
/// Try to eliminate as many guesses that provide duplicate information as another guess
///		(and guesses that will get pruned later anyway because they won't parition consisT best)
Guess[] computeGuessesToTry(in GuessHistory pastGuesses, in ResponseHistory pastResponses, in Guess[] consisT) {
	Guess[] guessesToTry;
	// todo: track these in the state of the problem
	bool[NUM_DIGIT] absentDigits = getAbsentDigits(pastGuesses, pastResponses), 
					uncalledDigits = getUncalledDigits(pastGuesses);
	Digit[NUM_PLACE] lowestUncalledDigits = getLowestSortedUncalledDigits(uncalledDigits);
	
	guessGenLoop: foreach (g; AllGuesses) {
		if (canFind(pastGuesses, g)) // don't include a past guess
			continue;
		
		// forward digit-by-digit analysis of g
		byte numUncalledDigits = 0;
		foreach(d; g) {
			// if we got a 0.0 response on this digit, don't include it
			if (absentDigits[d]) {
				version(3) writeln("   Pruning ",guessToString(g)," because it contains the absent digit ",to!char(d));
				continue guessGenLoop;
			}
			// if we have an uncalled digit and it's not the first representative, don't include it
			// the first representative specifies uncalled digits in strictly ascending order
			//   ex. if [5,6,7,8,9] are uncalled digits, [3,7,2,5] can be replaced with [3,5,2,6] without loss of information
			if (uncalledDigits[d]) {
				if (d != lowestUncalledDigits[numUncalledDigits]) {
					version(3) writeln("   Pruning ",guessToString(g)," because it contains an uncalled digit and is not the first representative of its kind");
					continue guessGenLoop;
				} else
					numUncalledDigits++;
			}
			
		}
		
		// all tests pass, we'll try this guess
		guessesToTry ~= g;
	}
	return guessesToTry; 
}

/// An absent digit is one from a guess with response 0.0 - no point in trying them
bool[NUM_DIGIT] getAbsentDigits(in GuessHistory pastGuesses, in ResponseHistory pastResponses) {
	bool[NUM_DIGIT] absentDigits; // all false
	foreach (i, r; pastResponses)
		if (r == [0,0])
			foreach(d; pastGuesses[i])
				absentDigits[d] = true;
	return absentDigits;
}

/// An uncalled digit is a digit that has not been in any guess yet
bool[NUM_DIGIT] getUncalledDigits(in GuessHistory pastGuesses) {
	bool[NUM_DIGIT] uncalledDigits;
	fill(uncalledDigits,true);
	foreach(g; pastGuesses)
		foreach(d; g)
			uncalledDigits[d] = false;
	return uncalledDigits;
}

/// The 4 lowest uncalled digits in ascending order, such as [4, 7, 8, 9]
Digit[NUM_PLACE] getLowestSortedUncalledDigits(bool[NUM_DIGIT] uncalledDigits) {
	Digit[NUM_PLACE] lud;
	int num = 0;
	foreach(byte i, b; uncalledDigits)
		if (b) {
			lud[num] = i;
			num++;
			if (num >= lud.length)
				return lud;
		}
	while (num < lud.length) {
		lud[num] = -1;
		num++;
	}
	return lud;
}

/// creates the PartitionSet dividing consisT as a result of guessing rg
/// bestNonemptyParts is used to stop evaluation early if we have no chance of beating the bestNonemptyParts
PartitionSet createPartition(in Guess rg, in Guess[] consisT, in int bestNonemptyParts, out int nonemptyParts) {
	PartitionSet ps;
	
	foreach (i, consis; consisT) {
		auto a = consisT.length - i;
		auto b = bestNonemptyParts - nonemptyParts;
		//writeln("a(",typeid(a),")",a," < b(",typeid(b),")",b," is ",a<b); 
//		if (cast(int)(consisT.length - i) < bestNonemptyParts - nonemptyParts) { // linked to shouldUpdateBestGuess
//			version(4) writeln("   Stopped considering ",guessToString(rg)," early because it cannot reach as many nonempty paritions as the current best");//
//			//i:",i," consisT.length",consisT.length," bestNonemptyParts:",bestNonemptyParts," nonemptyParts:",nonemptyParts," consisT.length - i:",
//			//consisT.length - i," bestNonemptyParts-nonemptyParts:",bestNonemptyParts - nonemptyParts, " eval:",(consisT.length - i) < (bestNonemptyParts - nonemptyParts),"   huh?",263<-1);
//			ps = PartitionSet.init;
//			break;
//		}
		Response r = doCompare(rg,consis); // 4.0 for rg == consis
		int idx = responseToPartitionIndex(r);
		if (ps[idx].length == 0)
			nonemptyParts++;
		ps[idx] ~= consis; 
	}
	return ps;
} 

// entropy and nonemptyParts are passed by reference
void computeEntropy(in double n, in PartitionSet ps, out double entropy) {
	entropy = 0.0;
//	nonemptyParts = 0;
	foreach (const Guess[] partition; ps) {
		if (partition.length == 0) 
			continue; // no contribution to entropy or nonemptyParts
//		writeln("\t\t",entropy," += ",partition.length," * ",log(partition.length));
		entropy -= partition.length * log(partition.length);
//		nonemptyParts++;
	}
//	writeln("\tentropy log(",n,")-(1/",n,")*",entropy," = ",log(n)," - ",(1.0/n)*entropy," = ",log(n) - (1.0/n)*entropy);
	//version(1)
		entropy = log(n) + (1.0/n)*entropy; // speedup: don't need to calculate actual entropy; instead maximize the summed negative entropy (so more positive is preferred)
	
}

/// return true if we should swap the current guess with the best guess (so that rg is the new best guess)
// linked to function createPartition
bool shouldUpdateBestGuess(in Guess bestGuess, in double bestEntropy, in int bestNonemptyParts, in PartitionSet bestPS,
	in Guess rg,in double entropy,in int nonemptyParts, in PartitionSet newPS) {
	// Current implementation: rank by mostParts first, then by entropy as second priority
	// Also, if same # nonempty parts but one is consistent while the other is not, take the consistent one (we may actually guess it right!)
//	return nonemptyParts > bestNonemptyParts || 
//		(nonemptyParts == bestNonemptyParts && (entropy > bestEntropy || 
//							(bestPS[responseToPartitionIndex([4,0])].empty && !newPS[responseToPartitionIndex([4,0])].empty)));
	
	// New implementation: Use entropy to guide guess selection.  If same entropy, use nonempty parts and consistent guessing as tiebreaker criteria.
	return (entropy > bestEntropy) ||
		(entropy == bestEntropy && (nonemptyParts > bestNonemptyParts || ( bestPS[responseToPartitionIndex([4,0])].empty && !newPS[responseToPartitionIndex([4,0])].empty) ));
}

// Return true if this guess is so good that we should stop evaluating representative guesses and choose this one as the best
bool shouldStopEvaluatingGuesses(in Guess bestGuess, in double bestEntropy, in int bestNonemptyParts, in int numGuessesRemaining, 
			in PartitionSet bestGuessPartitionSet, in Guess[] consisT) {
	// Actually, there might be a guess with better entropy than this one and max # of nonempty parts too
//	// We have the maximum # of splits - choose the guess right away
//	if (bestNonemptyParts == 14)
//		return true;
	
	// if we find a guess that divides consisT into partitions of all size 1 and this guess is consistent, it's clearly the winner.  We will win next turn (and maybe this one).
	// only possible if consisT.length is <= 14
	if (consisT.length <= 14 && !bestGuessPartitionSet[responseToPartitionIndex([4,0])].empty) {
		bool ret = true;
		foreach(partition; bestGuessPartitionSet)
			if (ret = partition.length == 1, !ret)
				break;
		if (ret)
			writeln("Stopping consideration of guesses and accepting ",guessToString(bestGuess)," because it is consistent and divides the consistent guesses into paritions all of size 1");
		return ret;
	}
	
	return false;
}

bool shouldConsiderGuess(in Guess rg, in Guess bestGuess,in double bestEntropy,in int bestNonemptyParts, in PartitionSet bestPs, in Guess[] consisT) {
	if (bestNonemptyParts >= 14 && bestPs[responseToPartitionIndex([4,0])].length == 0) {
		if (!canFind(consisT,rg)) {
			version(2) writeln("   Rejecting guess ",guessToString(rg)," because it is inconsistent and our best guess has the maximum 14 nonempty partitions");
			return false;
		}
	}
	return true;
}

