module Master.Main;

import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;
import std.range;

import Master.MasterGame;
import Master.MasterPlayer;
import Master.MasterSpecific;

void main() {
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