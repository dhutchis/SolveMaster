/**
	Contains 10-color, 4-unique-digit Mastermind-specific algorithms and tools 
	
*/
module Master.MasterSpecific;
import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;
import std.range;
import std.typecons;

import Master.MasterUtil;

static this() {
	static assert(NUM_DIGIT == 10); // 10 colors only
	static assert(NUM_PLACE == 4);  // 4 places only
}

pure @safe nothrow bool canFind(Guess g, Digit d) {
	return g[0] == d || g[1] == d || g[2] == d || g[3] == d;
}