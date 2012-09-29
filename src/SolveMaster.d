import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;
import std.range;

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
alias Digit[2] Response;
// alias function for transformation

auto findTransform(in Guess p, in Guess q, in Response[Guess] history)
{
	// iterate over all feasible transformations that could take p to q
	// then check whether a feasible transformation respects the history
	// return the first one to pass
	Digit[Digit] substitution;
	Place[Place] permutation;
	bool[Place] available; // the places in q that are available for assignment
	foreach (Place pl; PLACE_MIN..PLACE_MAX+1)
		available[pl] = true;
	
	foreach (Digit start; p) {
		foreach (Place pl, ref bool avail; available) {
			if (!avail)
				continue;
			avail = false;
			substitution[start] = q[pl];
		}
		foreach (Digit end; q) {
			//substitution
		}
	}
	
	//enum allSubstitutions = GenerateSubstitutions!(PLACE_MAX+1);
	
	
} 

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

enum DEBUG_MSG = false;
void dnoln(A...)(A a)
if (is(typeof({write(a);}()))) {
	static if(DEBUG_MSG) {
		write(a);
		stdout.flush();
	}
}
void d(A...)(A a)
if (is(typeof({writeln(a);}()))) {
	static if(DEBUG_MSG) {
		writeln(a);
		stdout.flush();
	}
}

template permute(A : T[L], T, size_t L) {
	auto pure permute(in A arr) {
		static assert (L > 0, "no 0-length static arrays allowed");
		bool[L] used;
		fill(used, false);
		A form = void;
		A[factorial!L] allperms;
		size_t permsCtr = 0;
		doPermute(arr, used, 0u, form, allperms, permsCtr); d();
		d("after ", allperms);
		return allperms;
	}
	
	private pure @safe void doPermute(
		in A arr, 
		bool[L] used, 
		in size_t pos, 
		A form, 
		ref A[factorial!L] allperms, 
		ref size_t permsCtr
	) {
		dnoln("\nat ",pos," ");
		foreach (i; 0 .. L) {
			if (used[i]) continue;
			used[i] = true;
			form[pos] = arr[i];
			if (pos == L-1) {
				dnoln(form," ",allperms,"; ");
				allperms[permsCtr] = form.idup; // idup for immutable
				dnoln(form," ",allperms);
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

// are all the elements in this static array equal to some value?
// can be generalized to take any unary function that takes a member val and returns a bool
pure @safe bool allEqual(T, size_t L, B = staticArrayBaseType!(T[L]))
						(in T[L] arr, in B val) {
	bool ret = true;
	static if (isStaticArray!T) {
		foreach(ref row; arr)
			if (!(ret = allEqual(row,val),ret))
				break;
	} else {
		foreach(ref a; arr)
			if (!(ret = a == val,ret))
				break;
	}
	return ret;
}
unittest {
	enum bool[2] b = [true,true];
	static assert(allEqual(b,true));
	static assert(!allEqual(b,false));
	enum double[2][2] d = [[3.3, 3.4],[3.3,3.3]];
	static assert(!allEqual(d,3.3));
}

auto findTransform(in Guess p, in Guess q, in Guess[] pastGuesses)
{
	
	
	
	
	 
}

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
		if (allEqual(row,true))
			substMap[i] = -2;
	
	findSubstitution_Impl(p,q,pastGuesses,validSubst,substMap,used,DIGIT_MIN);
	
}
void markInvalidSubsts(in Guess p, in Guess q, ref bool[NUM_DIGIT][NUM_DIGIT] validSubst) {
	// digits in p can only go to digits in q
	auto qsort = q.dup; qsort.sort;
	foreach (Digit from; p)
		foreach (Digit tonot; setDifference(ALL_DIGITS, qsort)) // speedup by static array impl.?
			validSubst[from][tonot] = false;
}
unittest {
	mixin DPROP;
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
mixin template DPROP() {
	void dprop(string a)() { writeln(a,":",typeid(mixin(a)),":",mixin(a)); }
}

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
}

void main() {
	writeln("hi");
}