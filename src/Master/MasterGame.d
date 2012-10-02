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
	return cast(Guess)[uniform(DIGIT_MIN,DIGIT_MAX+1),uniform(DIGIT_MIN,DIGIT_MAX+1),uniform(DIGIT_MIN,DIGIT_MAX+1),uniform(DIGIT_MIN,DIGIT_MAX+1)];
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
	
	Response makeGuess(Guess g) {
		pastGuesses ~= g;
		Response r = doCompare(g,soln);
		pastResponses ~= r;
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