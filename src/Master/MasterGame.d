module Master.MasterGame;
import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;
import std.range;
import std.random;

import Master.MasterUtil;
import Master.MasterSpecific;

Guess generateRandomGuess() {
	Guess generateRandomGuess(Guess g, Place p) {
		outterCheckLoop: while ( true ) {
			g[p] = cast(Digit)uniform(DIGIT_MIN,DIGIT_MAX+1);
			foreach (d; g[0 .. p])
				if (d == g[p])
					continue outterCheckLoop;
			break;
		}
		if (p == PLACE_MAX)
			return g;
		else
			return generateRandomGuess(g, cast(Place)(p+1));
	}
	return generateRandomGuess(Guess.init, PLACE_MIN);
//	return cast(Guess)[uniform(DIGIT_MIN,DIGIT_MAX+1),uniform(DIGIT_MIN,DIGIT_MAX+1),uniform(DIGIT_MIN,DIGIT_MAX+1),uniform(DIGIT_MIN,DIGIT_MAX+1)];
}

class MasterGame {
private:
	Guess soln;
	GuessHistory pastGuesses;
	ResponseHistory pastResponses;
	
public:
	this() {
		soln = generateRandomGuess();
	}
	this(Guess g) {
		soln = g;
	}
	
	Response makeGuess(Guess g) {
		pastGuesses ~= g;
		Response r = doCompare(g,soln);
		pastResponses ~= r;
		writeln("Guess: ",guessToString(g)," Response: ",responseToString(r));
		return r;
	}
	
//	auto @property getNumGuesses() { return numGuesses; }
	
	override string toString() {
		string s = "GAME[soln="~guessToString(soln)~",#gs="~text(pastGuesses.length)~"] ";
		foreach (i, g; pastGuesses)
			s ~= "("~guessToString(g)~","~responseToString(pastResponses[i])~")";
		return s;
	}
	
	invariant() {
		assert(pastGuesses.length == pastResponses.length);
	}
}