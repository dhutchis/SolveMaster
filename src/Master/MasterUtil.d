module Master.MasterUtil;
// see if we can get static array functionality via array-wise operators []
import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;
import std.range;
//import std.typecons;

import Master.MasterSpecific;

alias byte Digit; // 0-9
enum Digit DIGIT_MIN = 0, DIGIT_MAX = 9, NUM_DIGIT = DIGIT_MAX-DIGIT_MIN+1;
enum Digit[] ALL_DIGITS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
alias byte Place; // 0-3
enum Place PLACE_MIN = 0, PLACE_MAX = 3, NUM_PLACE = PLACE_MAX-PLACE_MIN+1;
/*template Place() {
	alias byte Place;
	enum MIN = 0;
	enum MAX = 3;
}*/
alias Digit[4] Guess;
alias Digit[NUM_DIGIT] Substitution;
alias Place[NUM_PLACE] Permutation;
alias byte[2] Response;
//alias Tuple!(Guess,Response) GuessResponse;
//alias GuessResponse[] History;
alias Guess[] GuessHistory;
alias Response[] ResponseHistory;
// alias function for transformation
alias Guess[][14] PartitionSet;

string toString(Guess g) { return guessToString(g); }

// todo build lookup table at compile time
int responseToPartitionIndex(Response r) {
	switch(r[0]) {
		case 0: return r[1];
		case 1: return 5+r[1];
		case 2: return 9+r[1];
		case 3: assert(r[1] == 0); return 12;
		case 4: assert(r[1] == 0); return 13;
		default: assert(false,"invalid reponse: "~text(r));
	}
}

string guessToString(Guess g) {
	string s;
	foreach(d; g)
		s ~= text(d);
	return s;
}
string responseToString(Response r) {
	return text(r[0])~"."~text(r[1]);
}


//auto findTransform(in Guess p, in Guess q, in Response[Guess] history)
//{
//	// iterate over all feasible transformations that could take p to q
//	// then check whether a feasible transformation respects the history
//	// return the first one to pass
//	Digit[Digit] substitution;
//	Place[Place] permutation;
//	bool[Place] available; // the places in q that are available for assignment
//	foreach (Place pl; PLACE_MIN..PLACE_MAX+1)
//		available[pl] = true;
//	
//	foreach (Digit start; p) {
//		foreach (Place pl, ref bool avail; available) {
//			if (!avail)
//				continue;
//			avail = false;
//			substitution[start] = q[pl];
//		}
//		foreach (Digit end; q) {
//			//substitution
//		}
//	}
//	
//	//enum allSubstitutions = GenerateSubstitutions!(PLACE_MAX+1);
//	
//	
//} 

// create function to return a map of all the possible mappings ret[0] is the first mapping 
//  ret[0][0] is the mapping of the first character in first mapping
// later create function to return theses as a lazy range
/*auto GenerateSubstitutions(A)(A maxp)
if (isIntegral!A && isIntegral!B)
{
	int[factorial(maxp)][maxp] ret;
	
}*/

// returns same type as the typeof n
template factorial(alias n)
if (isIntegral!(typeof(n)) && n >= 0) {
	static if (n <= 1)
		enum factorial = 1;
	else
		enum factorial = n*factorial!(n-1);
}

//enum DEBUG_MSG = true;
//void dnoln(A...)(A a)
//if (is(typeof({write(a);}()))) {
//	static if(DEBUG_MSG) {
//		write(a);
//		stdout.flush();
//	}
//}
//void d(A...)(A a)
//if (is(typeof({writeln(a);}()))) {
//	static if(DEBUG_MSG) {
//		writeln(a);
//		stdout.flush();
//	}
//}

template permute(A : T[L], T, size_t L) {
	auto pure permute(in A arr) {
		static assert (L > 0, "no 0-length static arrays allowed");
		bool[L] used;
		fill(used, false);
		A form = void;
		A[factorial!L] allperms;
		size_t permsCtr = 0;
		doPermute(arr, used, 0u, form, allperms, permsCtr); //d();
//		d("after ", allperms);
		return allperms;
	}
	
	private pure void doPermute(
		in A arr, 
		bool[L] used, 
		in size_t pos, 
		A form, 
		ref A[factorial!L] allperms, 
		ref size_t permsCtr
	) {
//		dnoln("\nat ",pos," ");
		foreach (i; 0 .. L) {
			if (used[i]) continue;
			used[i] = true;
			form[pos] = arr[i];
			if (pos == L-1) {
//				dnoln(form," ",allperms,"; ");
				allperms[permsCtr] = form.idup; // idup for immutable
//				dnoln(form," ",allperms);
				permsCtr++;
			}
			else
				doPermute(arr, used, pos+1, form, allperms, permsCtr);
			used[i] = false; 
		}
	}
}

template staticArrayBaseType(T : U[N], U, size_t N)
{
	static if (isStaticArray!U)
		alias staticArrayBaseType!U staticArrayBaseType;
	else
		alias U staticArrayBaseType;
}
unittest {
	static assert(is(staticArrayBaseType!(bool[3]) == bool));
	static assert(is(staticArrayBaseType!(float[7][6][5]) == float));
	static assert(is(staticArrayBaseType!(Object[2][2]) == Object));
}


pure @safe void fill(T, size_t L, B = staticArrayBaseType!(T[L]))
					(ref T[L] arr, in B val)  {
	//writeln("T:",typeid(T),"; L:",typeid(L),"; B:",typeid(B),"; arr:",typeid(arr),"; val:",typeid(val),"; sa:",isStaticArray!T,"; arr=",arr,"; val=",val);
	static if (isStaticArray!T)
		foreach(ref row; arr)
			fill(row,val);
	else
		foreach (ref pos; arr)
			pos = val;
} 

unittest {
	float[2][1] fl; fill(fl,1.1);
	assert ( fl == [[1.1f,1.1f]]);
	int[3] i; fill(i, 7);
	assert ( i == [7,7,7] );
}

//template permute(A : T[], T) {
//	auto permute(A : T[], T)(in A arr) {
//		return permute(cast(const T[arr.length])arr);
//	}
	
	/*auto permute(in A arr) {
		bool[] used; //used.length = arr.length;
		//std.algorithm.fill(used, false);
		A form; //form.length = arr.length;
		A[] allperms; //allperms.length = factorial!(arr.length);
		foreach (ref a; arr) { used ~= false; form ~= T.init; }
		size_t permsCtr = 0;
		doPermute(arr, used, 0u, form, allperms, permsCtr); writeln();
		return allperms;
	}
	
	private  void doPermute(
		in A arr, 
		bool[] used, 
		in size_t pos, 
		A form, 
		A[] allperms, 
		ref size_t permsCtr
	) {
		write("\nat ",pos," ");
		foreach (i; 0 .. arr.length) {
			if (used[i]) continue;
			used[i] = true;
			form[pos] = arr[i];
			if (pos == arr.length-1) {
				//write(form," ",allperms);
				allperms ~= form.dup; // idup for immutable
				permsCtr++;
			}
			else
				doPermute(arr, used, pos+1, form, allperms, permsCtr);
			used[i] = false; 
		}
	}*/
//}

unittest {
	enum int[1] t1 = [5];
	auto t1res = permute(t1);
	assert(t1res == [[5]]);
//	writeln(typeid(t1res), " ", typeid(t1res[0]), " ", typeid(t1res[0][0]),"\n", t1res);
	
	enum int[3] t2 = [0,1,2];
	enum t2res = permute(t2);
	static assert(t2res == [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]);
//	writeln(t2res);
	
	enum char[3] t3 = "abc";
	enum t3res = permute(t3);
	static assert(t3res == ["abc", "acb", "bac", "bca", "cab", "cba"]);
//	writeln(t3res);
	
	enum string[4] t4 = ["Let's","massively","permute","string arrays"];
	enum t4res = permute(t4);
	static assert(t4res == [["Let's", "massively", "permute", "string arrays"], ["Let's", "massively", "string arrays", "permute"], ["Let's", "permute", "massively", "string arrays"], ["Let's", "permute", "string arrays", "massively"], ["Let's", "string arrays", "massively", "permute"], ["Let's", "string arrays", "permute", "massively"], ["massively", "Let's", "permute", "string arrays"], ["massively", "Let's", "string arrays", "permute"], ["massively", "permute", "Let's", "string arrays"], ["massively", "permute", "string arrays", "Let's"], ["massively", "string arrays", "Let's", "permute"], ["massively", "string arrays", "permute", "Let's"], ["permute", "Let's", "massively", "string arrays"], ["permute", "Let's", "string arrays", "massively"], ["permute", "massively", "Let's", "string arrays"], ["permute", "massively", "string arrays", "Let's"], ["permute", "string arrays", "Let's", "massively"], ["permute", "string arrays", "massively", "Let's"], ["string arrays", "Let's", "massively", "permute"], ["string arrays", "Let's", "permute", "massively"], ["string arrays", "massively", "Let's", "permute"], ["string arrays", "massively", "permute", "Let's"], ["string arrays", "permute", "Let's", "massively"], ["string arrays", "permute", "massively", "Let's"]]);
//	writeln(t4res);
	
	enum float[4] t5 = [0.0f,0.1f,1.2f,3.7f];
	enum t5res = permute(t5);
	static assert(t5res == [[0, 0.1, 1.2, 3.7], [0, 0.1, 3.7, 1.2], [0, 1.2, 0.1, 3.7], [0, 1.2, 3.7, 0.1], [0, 3.7, 0.1, 1.2], [0, 3.7, 1.2, 0.1], [0.1, 0, 1.2, 3.7], [0.1, 0, 3.7, 1.2], [0.1, 1.2, 0, 3.7], [0.1, 1.2, 3.7, 0], [0.1, 3.7, 0, 1.2], [0.1, 3.7, 1.2, 0], [1.2, 0, 0.1, 3.7], [1.2, 0, 3.7, 0.1], [1.2, 0.1, 0, 3.7], [1.2, 0.1, 3.7, 0], [1.2, 3.7, 0, 0.1], [1.2, 3.7, 0.1, 0], [3.7, 0, 0.1, 1.2], [3.7, 0, 1.2, 0.1], [3.7, 0.1, 0, 1.2], [3.7, 0.1, 1.2, 0], [3.7, 1.2, 0, 0.1], [3.7, 1.2, 0.1, 0]]);
//	writeln(t5res);
	
	static assert(is(typeof(factorial!3uL) : ulong));
	
	// dynamic arrays
//	auto t6 = [2,4];
//	auto t6res = permute(t6);
//	writeln(t6res);
}

pure @safe bool allPassFun(alias op, T, size_t L, B = staticArrayBaseType!(T[L]))
						(in T[L] arr) 
						if (is(typeof(op(B)) == bool)) {
	bool ret = true;
	static if (isStaticArray!T) {
		foreach(ref row; arr)
			if (!(ret = allPassFun!op(row),ret))
				break;
	} else {
		foreach(ref a; arr)
			if (!(ret = op(a),ret))
				break;
	}
	return ret;
}

//// are all the elements in this static array equal to some value?
//// can be generalized to take any unary function that takes a member val and returns a bool
//pure @safe bool allPassFun(T, size_t L, B = staticArrayBaseType!(T[L]))
//						(in T[L] arr, in B val) {
//	bool ret = true;
//	static if (isStaticArray!T) {
//		foreach(ref row; arr)
//			if (!(ret = allPassFun(row,val),ret))
//				break;
//	} else {
//		foreach(ref a; arr)
//			if (!(ret = a == val,ret))
//				break;
//	}
//	return ret;
//}
unittest {
	enum bool[2] b = [true,true];
	static assert(allPassFun!((x) {return x;})(b));
	static assert(!allPassFun!((x) {return !x;})(b));
	enum double[2][2] d = [[3.3, 3.4],[3.3,3.3]];
	static assert(!allPassFun!( (x) {return x == 3.3;} )(d));
	static assert(allPassFun!( (x) {return x > 2;} )(d));
}

/// Evaluates op on each member of arr, returning the index of the first one that returns true, or -1 on all false
pure @safe int findFirstMatch(alias op, T, size_t L)(in T[L] arr)
if (is(typeof(op(T)) == bool))  {
	foreach (i, a; arr)
		if (op(a))
			return i;
	return -1;
} 

/// Try to find a transformation f such that f(p)==q and foreach(g; pastGuesses) f(g)==g
///	f can involve a substitution and a permutation of Digits
/// If f exists, p and q are in the same representative class -- guessing p will produce the same parition splits as guessing q
bool findTransform(in Guess p, in Guess q, in GuessHistory pastGuesses)
{
	foreach (subst; validSubstitutionStream(p,q,pastGuesses)) {
		auto psub = applySubstitution(p,subst);
		auto perm = getPermMap(psub,q); 
//		d("p",p," =subst",subst,"=> ",psub," =perm",perm,"=> ",q);
		assert(applyPermutation(psub,perm)==q); // transformation p->q guranteed to exist
												// the transformation also taking each pastGuess to itself is not guranteed
		// try the permutation on every past guess.  Success on all means we found a transform: subst composed with perm
		bool ret = true;
		foreach (const Guess past; pastGuesses) {
//		if (allPassFun!( delegate bool(Guess pg) { return pg == applyPermutation(pg,perm); } )(pastGuesses)) // NOT Fully recursive
			if (ret = past == applyPermutation(applySubstitution(past,subst),perm), /*d("\tperm takes ",past," => ",applyPermutation(applySubstitution(past,subst),perm)),*/ !ret)
				break;
		}
		if (ret)
			return true;
	}
	return false; 
}
unittest {
	enum Guess p = [0,1,2,4], q = [0,1,5,3];
	enum Guess[] past = [[0,1,2,3]];
	 assert(findTransform(p,q,past));
//	writeln(findTransform(p,q,past));
}

GuessHistory[] groupPastGuessesBySameResponse(in GuessHistory pastGuesses, in ResponseHistory pastResponses) 
in { assert(pastGuesses.length == pastResponses.length); } 
body {
	GuessHistory[] groups;
	bool[] seen; // keeps track of responses already grouped
	foreach (i, r; pastResponses) {
		if (!seen.empty) {
			bool front = seen.front;
			seen.popFront();
			if (front) continue;
		}
		GuessHistory group = [pastGuesses[i]];
		foreach (j; i+1 .. pastResponses.length) {
//			d("i:",i," j:",j," seen:",seen);
			if ((j-i > seen.length || !seen[j-i-1]) && pastResponses[j] == r) { 
				group ~= pastGuesses[j];
				seen.length = max(seen.length, j-i); // extends with false
				seen[j-i-1] = true;
			}
		}
		groups ~= group;
		
	}
	return groups;
}
unittest {
	GuessHistory gh1 = [[0,1,2,3],[1,2,3,4]];
	ResponseHistory rh1 = [[0,1], [0,1]];
	assert(groupPastGuessesBySameResponse(gh1,rh1) == [[[0, 1, 2, 3], [1, 2, 3, 4]]]);
	GuessHistory gh2 = [[0,1,2,3], [2,3,4,5], [1,2,3,4]];
	ResponseHistory rh2 = [[0,1], [1,0], [0,1]];
	assert(groupPastGuessesBySameResponse(gh2,rh2) == [[[0, 1, 2, 3], [1, 2, 3, 4]], [[2, 3, 4, 5]]]);
	ResponseHistory rh3 = [[0,1], [0,1], [0,1]];
	assert(groupPastGuessesBySameResponse(gh2,rh3) == [[[0, 1, 2, 3], [2, 3, 4, 5], [1, 2, 3, 4]]]);
	ResponseHistory rh4 = [[0,1], [0,1], [1,0]];
	assert(groupPastGuessesBySameResponse(gh2,rh4) == [[[0, 1, 2, 3], [2, 3, 4, 5]], [[1, 2, 3, 4]]]);
	assert(groupPastGuessesBySameResponse([],[]) == []);
}

/// This version of findTransform takes additional information -- the responses at runtime!
/// By Lemma 11 [Slovesnov], we can group pastGuesses into sets that share the same response
/// transformation f only needs to take a group to itself, not each individual past guess to itself
/// Could help in turn 3 if we get the same response in turns 1 and 2
bool findTransform(in Guess p, in Guess q, in GuessHistory[] pastGuessSets) {
	//const GuessHistory[] pastGuessSets = groupPastGuessesBySameResponse(pastGuesses, pastResponses);
	
	foreach (subst; validSubstitutionStream(p,q,pastGuessSets)) {
		auto psub = applySubstitution(p,subst);
		auto perm = getPermMap(psub,q); 
//		d("p",p," =subst",subst,"=> ",psub," =perm",perm,"=> ",q);
		assert(applyPermutation(psub,perm)==q); // transformation p->q guranteed to exist
												// the transformation also taking each pastGuess to itself is not guranteed
		// try the permutation on every past guess.  Success on all means we found a transform: subst composed with perm
		bool ret = true;
		tryThisTrans: foreach (const GuessHistory pastGuessSet; pastGuessSets) {
			GuessHistory newHistory;
			foreach (const Guess past; pastGuessSet)
				newHistory ~= applyPermutation(applySubstitution(past,subst),perm);
			foreach (const Guess past; pastGuessSet)
				if (ret = canFind(newHistory, past), !ret)
					break tryThisTrans;
		}
		if (ret)
			return true;
	}
	return false; 
}
unittest {
	/// Finds transformations that are valid only by using additional response information  
	GuessHistory gh1 = [[0,1,2,3],[1,2,3,4]];
	ResponseHistory rh1 = [[0,1], [0,1]];
	GuessHistory[] gg = groupPastGuessesBySameResponse(gh1, rh1);
	Guess p = [0,1,2,5];
	uint count = 0;
	foreach (q; AllGuessesGenerator()) {
		if (!findTransform(p,q,gh1) && findTransform(p,q,gg)) {
			d(q);
			count++;
		}
	}
	d(count);
}


// takes 2 Guesses with the same digits, possible in a rearranged order, returns the permutation map to go from one to the other
Permutation getPermMap(in Guess from, in Guess to) {
	Permutation pm;
	foreach (i, Digit din; from) {
		pm[i] = cast(Place)countUntil(cast(Digit[])to, din);
		assert(pm[i] != -1,"from ("~text(from)~")and to ("~text(to)~")should have the same Digit set");
	}
	return pm;
}
unittest {
	enum Guess p = [0,1,3,5], q = [0,1,5,3];
	static assert(getPermMap(p,q) == [0, 1, 3, 2]);
}
Guess applyPermutation(in Guess from, in Permutation perm) {
	Guess o;
	foreach(i, din; from)
		o[perm[i]] = din;
	return o;
}
unittest {
	enum Guess g = [6,7,8,9];
	enum Permutation perm = [0,1,3,2];
	static assert(applyPermutation(g,perm) == [6,7,9,8]);
}

struct ValidSubstitutionStream
{
private:
//    alias T[L] A;
//    const A p;
//    const A q;
//    const A[] pastGuesses;
    
    bool[NUM_DIGIT][NUM_DIGIT] validSubst; //validSubst[2][4]==true means 2->4 is a valid mapping
	Digit[NUM_DIGIT] substMap; // the actual mapping; substMap[2]==4 means 2 maps to 4
	bool[NUM_DIGIT] used; // signifies whether we already used the number in a previous substitution
	Digit pos = DIGIT_MIN-1;
	
	bool _empty = false;
		
	/// Setup given past guesses but no response information
	void doInit(in Guess p, in Guess q, in Guess[] pastGuesses) {
		fill(validSubst, true);
		fill(substMap, cast(Digit)(DIGIT_MIN-1));    // -2 implies free (can map to any other free var)
		fill(used, false);
		
		// setup validSubst -- mark substitutions which cannot occur as impossible
		markInvalidSubsts(p,q,validSubst);
		foreach (ref g; pastGuesses)
			markInvalidSubsts(g,g,validSubst);
		
		// mark the unrestricted digits that can be substituted for anything as free
		foreach (i, ref row; validSubst)
			if (allPassFun!((x) {return x;})(row))
				substMap[i] = -2;
		
		pos = DIGIT_MIN-1;
		_empty = false;
	}
	
	/// Setup given past guesses grouped by same response
	void doInit(in Guess p, in Guess q, in GuessHistory[] guessSets) {
		fill(validSubst, true);
		fill(substMap, cast(Digit)(DIGIT_MIN-1));    // -2 implies free (can map to any other free var)
		fill(used, false);
		
		// setup validSubst -- mark substitutions which cannot occur as impossible
		markInvalidSubsts(p,q,validSubst);
		foreach (guessSet; guessSets)
			markInvalidSubstsUnion(guessSet,validSubst);
		
		// mark the unrestricted digits that can be substituted for anything as free
		foreach (i, ref row; validSubst)
			if (allPassFun!((x) {return x;})(row))
				substMap[i] = -2;
		
		pos = DIGIT_MIN-1;
		_empty = false;
	}

    void findNextSubst()
    {
    	if (_empty) return;
    	bool direc = true; // going forward
		if (pos > DIGIT_MAX) direc = false; // going backward
		
    	posloop: while (direc ? pos++ : pos--, DIGIT_MIN <= pos && pos <= DIGIT_MAX) {
	    	// find valid choices for this position
			if (substMap[pos] == -2) // free variable
				continue;
			if (!direc) 
				used[substMap[pos]] = false;
			foreach (Digit i; cast(Digit)(substMap[pos]+1) .. cast(Digit)(DIGIT_MAX+1)) {
				if (used[i]) continue; // digit already used
				if (!validSubst[pos][i]) continue; // not a valid substitution
				// we have a valid substitution of pos -> i
				used[i] = true;
				substMap[pos] = i;
				direc = true;
				continue posloop;
			}
			// exhausted possibilities for this pos
//			used[pos] = false;
			substMap[pos] = cast(Digit)(DIGIT_MIN-1);
			direc = false;
			
		}        
		if (pos < DIGIT_MIN) // no more possible substitutions
			_empty = true;
		// pos > DIGIT_MAX means we have a valid substitution in substMap
    }

public:
    this(in Guess p, in Guess q, in Guess[] pastGuesses) {
        doInit(p,q,pastGuesses);
        // prime: find first substitution
        popFront();
    }
    
    this(in Guess p, in Guess q, in GuessHistory[] guessSets) {
    	doInit(p,q,guessSets);
        // prime: find first substitution
        popFront();
    }

    void popFront() {
        findNextSubst();
    }

    @property Substitution front() {
        assert(!_empty);
        return substMap;
    }

    @property typeof(this) save() {
        auto ret = this;
//        assert(ret.p == p);
//        assert(ret.q == q);
//        assert(ret.pastGuesses == pastGuesses);
	    ret.validSubst = validSubst.dup;
	    ret.substMap = substMap.dup; 
	    ret.used = used.dup;
		assert(pos == ret.pos);
		assert(ret._empty == _empty);
        return ret;
    }

    @property bool empty() { return _empty; }
    
    unittest {
    	//static assert (is(bool[NUM_DIGIT][NUM_DIGIT] == bool[L][L]));  // make more generic when this fails
    }
}
auto validSubstitutionStream(in Guess p, in Guess q, in Guess[] pastGuesses) {
	return ValidSubstitutionStream(p,q,pastGuesses);
}
unittest {
	Guess p = [0,1,2,4], q = [0,1,5,3];
	Guess[] past = [[0,1,2,3]];
//	foreach (subst; validSubstitutionStream(p,q,past))
//		writeln(subst);
}
auto validSubstitutionStream(in Guess p, in Guess q, in GuessHistory[] guessSets) {
	return ValidSubstitutionStream(p,q,guessSets);
}


Guess applySubstitution(Guess g, Substitution subst) {
	Guess o;
	foreach(i, din; g)
		o[i] = subst[din];
	return o;
}
unittest {
	enum Guess p = [0,1,2,4];
	enum Substitution subst = [0, 1, 3, 2, 5, -2, -2, -2, -2, -2];
	static assert(applySubstitution(p,subst) == [0, 1, 3, 5]);
}

/*
auto findSubstitution(in Guess p, in Guess q, in Guess[] pastGuesses)
{
	bool[NUM_DIGIT][NUM_DIGIT] validSubst; //validSubst[2][4]==true means 2->4 is a valid mapping
		fill(validSubst, true);
	Digit[NUM_DIGIT] substMap; // the actual mapping; substMap[2]==4 means 2 maps to 4
		fill(substMap, cast(Digit)-1);    // -1 implies not filled yet; -2 implies free (can map to any other free var)
	bool[NUM_DIGIT] used; // signifies whether we already used the number in a previous substitution
		fill(used, false);
	
	// setup validSubst -- mark substitutions which cannot occur as impossible
	markInvalidSubsts(p,q,validSubst);
	foreach (ref g; pastGuesses)
		markInvalidSubsts(g,g,validSubst);
	
	// mark the unrestricteddigits that can be substituted for anything as free
	foreach (i, ref row; validSubst)
		if (allPassFun(row,true)) {
			substMap[i] = -2;
		} else if (allPassFun(row,false)) {
			// no possible substitutition can work here
			writeln("no possible subst");
			return;
		}
	
	findSubstitution_Impl(p,q,pastGuesses,validSubst,substMap,used,DIGIT_MIN);
	
}*/
//auto mySetDifference(T,size_t L)(in T[] univ, in T[L] toRem) {
////	foreach (
//}

/// marks false in validSubst for each substition a->b defined by validSubst[a][b]
///  that will result in an impossible transformation function because range(subst(p)) != domain(q)
void markInvalidSubsts(in Guess p, in Guess q, ref bool[NUM_DIGIT][NUM_DIGIT] validSubst) {
	// digits in p can only go to digits in q
	auto qsort = q.dup; 
//	qsort.sort; // speedup y efficient sort?
	sort(qsort);
	foreach (Digit from; p)
		foreach (Digit tonot; setDifference(ALL_DIGITS, qsort)) // speedup by static array impl.?
			validSubst[from][tonot] = false;
}
unittest {
	//mixin DPROP;
	//void dprop(string a)() { writeln(a,":",typeid(mixin(a)),":",mixin(a)); }
	
	Guess p = [0,1,2,4], q = [0,1,5,3];
	/*auto qsort = q.dup;
	qsort.sort;
	dprop!"p"; //writeln("p:",typeid(p),":",p,"; qsort:",typeid(qsort),":",qsort);
	dprop!"qsort";
	auto ps = p[];
	dprop!"ps"; //writeln("p[]:",typeid(ps),":",ps);
	dprop!"ALL_DIGITS"; //writeln("ALL_DIGITS:",typeid(ALL_DIGITS),":",ALL_DIGITS);
	writeln(isInputRange!(typeof(ALL_DIGITS)), isInputRange!(typeof(qsort)));
	auto sd = setDifference(ALL_DIGITS, qsort);
	dprop!"sd";*/
	bool[NUM_DIGIT][NUM_DIGIT] validSubst; fill(validSubst,true);
	markInvalidSubsts(p,q,validSubst);
//	writeln(validSubst);
	assert(validSubst == [[true, true, false, true, false, true, false, false, false, false], [true, true, false, true, false, true, false, false, false, false], [true, true, false, true, false, true, false, false, false, false], [true, true, true, true, true, true, true, true, true, true], [true, true, false, true, false, true, false, false, false, false], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true]]);
//	foreach(i, row; validSubst)
//		writeln(i,": ",row);
}
/// allows for local instantiation
//mixin template DPROP() {
//	void dprop(string a)() { writeln(a,":",typeid(mixin(a)),":",mixin(a)); }
//}

/// insert val, if not already there, into array in sorted position 
void insertUniqueSorted(T,E)(ref T[] array, in E val)
if (is(E : T)) {
	assert (isSorted(array));
	sizediff_t pos = countUntil!("a > b")(array, val);
	if (pos == -1)
		array ~= val;
	else
		array.insertInPlace(pos, val);
}
unittest {
	long[] arr = [];
	insertUniqueSorted(arr, 5);
	assert(arr == [5]);
	insertUniqueSorted(arr, 3);
	assert(arr == [3,5]);
	insertUniqueSorted(arr, 8);
	assert(arr == [3,5,8]);
	insertUniqueSorted(arr, 6);
	assert(arr == [3,5,6,8]);
}

/// Similar to above, but eliminates substitutions that do not take a digit in guessSet to some other digit in guessSet
void markInvalidSubstsUnion(in Guess[] guessSet, ref bool[NUM_DIGIT][NUM_DIGIT] validSubst) {
	Digit[] digitsInSet;
	foreach (g; guessSet)
		foreach(Digit d; g)
			insertUniqueSorted(digitsInSet, d); 
	foreach (Digit from; digitsInSet)
		foreach (Digit tonot; setDifference(ALL_DIGITS, digitsInSet))
			validSubst[from][tonot] = false;
}
unittest {
	Guess[] guessSet = [[0,1,2,3],[1,2,3,4]];
	bool[NUM_DIGIT][NUM_DIGIT] validSubst; fill(validSubst,true);
	markInvalidSubstsUnion(guessSet, validSubst);
//	foreach(i, row; validSubst)
//		writeln(i,": ",row);
	assert(validSubst == [[true, true, true, true, true, false, false, false, false, false], [true, true, true, true, true, false, false, false, false, false], [true, true, true, true, true, false, false, false, false, false], [true, true, true, true, true, false, false, false, false, false], [true, true, true, true, true, false, false, false, false, false], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true], [true, true, true, true, true, true, true, true, true, true]]);
	
}

/*
void findSubstitution_Impl(
	in Guess p, 
	in Guess q,
	in Guess[] pastGuesses,
	ref bool[NUM_DIGIT][NUM_DIGIT] validSubst,
	ref Digit[NUM_DIGIT] substMap,
	ref bool[NUM_DIGIT] used,
	in Digit pos
) {
	if (pos > DIGIT_MAX) { // speedup: do arms-length recursion
		// we're done; passed all the digits
		// YIELD substMap
		writeln("subst: ",substMap);
	}
	// find valid choices for this position
	if (substMap[pos] == -2) { // free variable
		findSubstitution_Impl(p,q,pastGuesses,validSubst,substMap,used,cast(Digit)(pos+1));
	} else {
		foreach (Digit i; DIGIT_MIN .. DIGIT_MAX+1) {
			if (used[i]) continue; // digit already used
			if (!validSubst[pos][i]) continue; // not a valid substitution
			// we have a valid substitution of pos -> i
			used[i] = true;
			substMap[pos] = i;
			findSubstitution_Impl(p,q,pastGuesses,validSubst,substMap,used,cast(Digit)(pos+1));
			used[i] = false;
		}
	}
}*/

struct AllGuessesGenerator {
private:
    Guess cur = [0,1,2,3];
    bool[NUM_DIGIT] used = [true,true,true,true,false,false,false,false,false,false];
    Place pos;
	bool _empty = false;

	Digit getFirstAvailDigPast(in Digit start) {
		Digit p = cast(Digit)(start+1);
		while (p <= DIGIT_MAX && used[p])
			p++;
		return p ;//> DIGIT_MAX ? getFirstAvailDigPast(DIGIT_MIN-1) : p;
	}

public:
	// just default constructor
	
    void popFront() {
    	assert(!_empty);
    	pos = PLACE_MAX;
    	Digit nd;
    	do {
    		used[cur[pos]] = false;
    		nd = getFirstAvailDigPast(cur[pos]);
    		pos--;
		} while (pos >= PLACE_MIN && nd > DIGIT_MAX);
    	pos++;
    	if (nd > DIGIT_MAX) {
        	_empty = true;
        	return;
        }
    	cur[pos] = nd;
    	used[nd] = true;
    	while (++pos <= PLACE_MAX) {
    		cur[pos] = getFirstAvailDigPast(DIGIT_MIN-1);
    		used[cur[pos]] = true;
    	}
    	
    }

    @property Guess front() {
        assert(!_empty);
        return cur;
    }

    @property typeof(this) save() {
        auto ret = this;
	    ret.cur = cur.dup;
	    assert(pos == ret.pos);
		assert(ret._empty == _empty);
        return ret;
    }

    @property bool empty() { return _empty; }
    
    unittest {
    	//static assert(equal(AllGuessesGenerator(),mixin(import("testperms.txt"))));
//    	foreach(g; AllGuessesGenerator())
//    		write(g,",");
//		writeln();
    }
}

/// Returns only the representative guesses, i.e., no 2 guesses returned will convey exactly the same information upon partitioning
/// Allows for trial of a minimum set of parition instances
Guess[] computeRepresentativeGuesses(in GuessHistory past) {
	Guess[] reprGuesses = past.dup; // past guesses are always representative
	foreach (g; AllGuessesGenerator()) {
		bool equiv = false;
		foreach (reprG; reprGuesses) {
			if (equiv = findTransform(g,reprG,past),equiv)
				break;
		}
		if (!equiv) { // g is not equivalent to any guess already in reprGuesses
			reprGuesses ~= g;
		}
	}
	// now eliminate the past guesses
	return reprGuesses[past.length .. $];
}
unittest {
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


/// Makes use of additional information (responses) to further narrow down representative guesses
Guess[] computeRepresentativeGuesses(in GuessHistory past, in ResponseHistory pastResponses) {
	return computeRepresentativeGuessesNarrowing(past, pastResponses, AllGuessesGenerator());
}
	
Guess[] computeRepresentativeGuessesNarrowing(Range)(in GuessHistory past, in ResponseHistory pastResponses, Range reprGuessesRange)
 if (isInputRange!Range && is(ElementType!Range == Guess)) {	
	Guess[] reprGuesses = past.dup; // past guesses are always representative
	// group pastGuesses into sets with same responses
	const GuessHistory[] pastGrouped = groupPastGuessesBySameResponse(past, pastResponses);
	
	foreach (g; reprGuessesRange) {
		bool equiv = false;
		foreach (reprG; reprGuesses) {
			if (equiv = findTransform(g,reprG,pastGrouped),equiv)
				break;
		}
		if (!equiv) { // g is not equivalent to any guess already in reprGuesses
			reprGuesses ~= g;
		}
	}
	// now eliminate the past guesses
	return reprGuesses[past.length .. $];
}
unittest {
	/// Writes the reduction in representative guess size after using additional response information
	/// Todo: Output this for many different cominations
//	GuessHistory gh = [[0,1,2,3],[1,2,3,4]];
//	ResponseHistory rh = [[0,1],[0,1]];
//	Guess[] rg_noinfo = computeRepresentativeGuesses(gh);
//	writeln("rg_noinfo: ",rg_noinfo.length);
//	Guess[] rg_info = computeRepresentativeGuesses(gh, rh);
//	writeln("rg_info: ",rg_info.length);
//	assert (rg_info.length < rg_noinfo.length);
}

Response doCompare(Guess a, Guess b) {
	Response r = [0,0];
	foreach (i, d; a) {
		if (b[i] == d)
			r[0]++;
		else
			foreach (j, d2; b)
				if (i != j && d == d2) {
					r[1]++;
					break;
				}
	}
	return r;
}
unittest {
	enum Guess g1 = [0,1,2,3],
 		g2 = [0,1,2,4],
 		g3 = [1,0,2,4],
 		g4 = [6,7,8,9];
	static assert(doCompare(g1,g1) == [4,0]);
	static assert(doCompare(g1,g2) == [3,0]);
	static assert(doCompare(g1,g3) == [1,2]);
	static assert(doCompare(g1,g4) == [0,0]);
}

/// is g still consistent after receiving feedback f(x,T)=r?
/// if so, then f(x,g)==r too
bool testConsistent(Guess g, Guess x, Response r) {
	return doCompare(x,g) == r;
}

//void main() {
////	Guess[] past = [[0,1,2,3],[0, 1, 2, 4]];
////	writeln("past: ",past);
////	auto reprGuesses = computeRepresentativeGuesses(past);
////	writeln(reprGuesses.length,":");
////	foreach(i, rg; reprGuesses)
////		write(rg,",");
//	
//	
//	
//}

enum Response[14] AllResponses = [[0,0],[0,1],[0,2],[0,3],[0,4],[1,0],[1,1],[1,2],[1,3],[2,0],[2,1],[2,2],[3,0],[4,0]];

Guess stringToGuess(const char[] s) {
	Guess g;
	foreach (i, d; s)
		g[i] = cast(Digit)(d-'0');
	return g;
}
 