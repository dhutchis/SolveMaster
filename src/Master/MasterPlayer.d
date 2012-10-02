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

import Master.MasterGame;
import Master.MasterUtil;
import Master.MasterSpecific;


void playGame(MasterGame mg) {
	GuessHistory pastGuesses;
	ResponseHistory pastResponses;
	Guess[] consisT;
	
	// first guess
	Guess first = [0,1,2,3];
	pastGuesses ~= first;
	pastResponses ~= mg.makeGuess(first);
	writeln("after first guess: ",mg.toString());
	
	// fill consisT with valid possible solutions
	foreach(g; AllGuessesGenerator())
		if (testConsistent(g, pastGuesses[0], pastResponses[0]))
			consisT ~= g;
	writeln(consisT.length," possible solutions after first guess");
	
	// while we didn't guess correctly yet
	while (pastResponses[$-1] != [4,0]) {
		PartitionSet psBest;
		Guess bestGuess = findBestGuess(pastGuesses, pastResponses, consisT, psBest);
		
		//attempt the best guess
		pastGuesses ~= bestGuess;
		pastResponses ~= mg.makeGuess(bestGuess);
		
		// update consisT according to response
		Guess[] newConsisT;
		foreach (g; consisT)
			if (testConsistent(g, pastGuesses[0], pastResponses[0]))
				newConsisT ~= g;
		consisT = newConsisT;
		
		// show status
		writeln(consisT.length," possible solutions remain. ",mg.toString());
	}
	
	writeln("Found solution after ",pastGuesses.length," guesses");
}

Guess findBestGuess(in GuessHistory pastGuesses, in ResponseHistory pastResponses, in Guess[] consisT, out PartitionSet bestGuessPartitionSet) {
	Guess bestGuess;
	double bestEntropy=0;
	int bestNonemptyParts=0;
	
	// only evaluate the representative guesses - this gets expensive after turn 3
	Guess[] reprGuesses;
	if (pastGuesses.length <= 3)
		reprGuesses = computeRepresentativeGuesses(pastGuesses, pastResponses); // pass response information available at runtime for reduction in reprGuesses size
	else
		reprGuesses = computeGuessesToTry(pastGuesses, pastResponses, consisT);
	foreach (i, rg; reprGuesses) {
		// should we even consider this guess? (alpha/beta pruning)
		if (!shouldConsiderGuess(rg, bestGuess,bestEntropy,bestNonemptyParts,bestGuessPartitionSet,consisT)) {
			continue;
		}
		
		// should we stop evaluating guesses return the best right now?
		if (shouldStopEvaluatingGuesses(bestGuess,bestEntropy,bestNonemptyParts, consisT.length-i, bestGuessPartitionSet, consisT)) {
			write("stopped evaluating guesses early; ");
			break;
		}
		
		// EVALUATE GUESS: divide consisT into partitions according to all possible reponses after guessing rg
		int nonemptyParts = 0;
		PartitionSet ps = createPartition(rg, consisT, bestNonemptyParts, nonemptyParts);
		
		// compute entropy, most parts heuristics
		double entropy = 0;
		computeEntropyMostParts(consisT.length,ps,entropy,nonemptyParts);
		
		// is this guess better than our best so far?
		if (shouldUpdateBestGuess(bestGuess,bestEntropy,bestNonemptyParts,rg,entropy,nonemptyParts)) {
			bestGuess = rg; bestEntropy = entropy; bestNonemptyParts = nonemptyParts;
			bestGuessPartitionSet = ps.dup;
		}
	}
	writeln("CHOSEN GUESS: ",guessToString(bestGuess)," entropy=",bestEntropy,"; nonemptyParts=",bestNonemptyParts);
	
	return bestGuess;
}

/// Use this after it becomes computationally expensive to calculate the minimal set of representative guesses
/// Try to eliminate as many guesses that provide duplicate information as another guess
///		(and guesses that will get pruned later anyway because they won't parition consisT best)
Guess[] computeGuessesToTry(in GuessHistory pastGuesses, in ResponseHistory pastResponses, in Guess[] consisT) {
	Guess[] guessesToTry;
	bool[NUM_DIGIT] absentDigits = getAbsentDigits(pastGuesses, pastResponses), // future: track these in the state of the problem
		uncalledDigits = getUncalledDigits(pastGuesses);
	Digit[NUM_PLACE] lowestUncalledDigits = getLowestSortedUncalledDigits(uncalledDigits);
	
	guessGenLoop: foreach (g; AllGuessesGenerator()) {
		if (canFind(pastGuesses, g)) // don't include a past guess
			continue;
		
		// forward digit-by-digit analysis of g
		byte numUncalledDigits = 0;
		foreach(d; g) {
			// if we got a 0.0 response on this digit, don't include it
			if (absentDigits[d])
				continue guessGenLoop;
			// if we have an uncalled digit and it's not the first representative, don't include it
			// first representative specifies uncalled digits in strictly ascending order
			//   ex. if [5,6,7,8,9] uncalled, [3,7,2,5] can be replaced with [3,5,2,6] without loss of information
			if (uncalledDigits[d]) {
				if (d != lowestUncalledDigits[numUncalledDigits])
					continue guessGenLoop;
				else
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
		if (consisT.length - i < bestNonemptyParts - nonemptyParts) // linked to shouldUpdateBestGuess
			break;
		// if rg is consistent itself, add it to the final category -- This will happen natually
//		if (rg == consis) {
//			ps[responseToPartitionIndex([4,0])] ~= rg;
//			nonemptyParts++;
//			continue;
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
void computeEntropyMostParts(in double n, in PartitionSet ps, out double entropy = 0, out int nonemptyParts = 0) {
	foreach (const Guess[] partition; ps) {
		if (partition.length == 0) 
			continue; // no contribution to entropy or nonemptyParts
		entropy += partition.length * log(partition.length);
		nonemptyParts++;
	}
	entropy = log(n) - (1/n)*entropy;
}

/// return true if we should swap the current guess with the best guess (so that rg is the new best guess)
// linked to function createPartition
bool shouldUpdateBestGuess(in Guess bestGuess, in double bestEntropy, in int bestNonemptyParts,in Guess rg,in double entropy,in int nonemptyParts) {
	// Current implementation: rank by mostParts first, then by entropy as second priority
	return nonemptyParts > bestNonemptyParts || 
		(nonemptyParts == bestNonemptyParts && entropy > bestEntropy);
}

// Return true if this guess is so good that we should stop evaluating representative guesses and choose this one as the best
bool shouldStopEvaluatingGuesses(in Guess bestGuess, in double bestEntropy, in int bestNonemptyParts, in int numGuessesRemaining, 
			in PartitionSet bestGuessPartitionSet, in Guess[] consisT) {
	// Actually, there might be a guess with better entropy than this one and max # of nonempty parts too
//	// We have the maximum # of splits - choose the guess right away
//	if (bestNonemptyParts == 14)
//		return true;
	
	// if we find a guess that divides consisT into partitions of all size 1, it's clearly the winner.  We will win next turn (and maybe this one).
	// only possible if consisT.length is <= 14
	if (consisT.length <= 14) {
		bool ret = true;
		foreach(partition; bestGuessPartitionSet)
			if (ret = partition.length == 1, !ret)
				break;
		return ret;
	}
	
	return false;
}

bool shouldConsiderGuess(in Guess rg, in Guess bestGuess,in double bestEntropy,in int bestNonemptyParts, in PartitionSet bestPs, in Guess[] consisT) {
	if (bestNonemptyParts == 13 && bestPs[responseToPartitionIndex([4,0])].length == 0)
		return canFind(consisT,rg);
	else return true;
}

