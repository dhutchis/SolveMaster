import std.stdio;
import std.c.process;
import std.array;
import std.conv;
//import std.string;
import std.algorithm;
import std.traits;

alias byte Digit; // 0-9
enum byte DIGIT_MIN = 0, DIGIT_MAX = 9;
alias byte Place; // 0-3
enum byte PLACE_MIN = 0, PLACE_MAX = 3;
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

template permute(A : T[L], T, size_t L) {
	auto pure permute(in A arr) {
		static assert (L > 0, "no 0-length static arrays allowed");
		bool[L] used;
		fill(used, false);
		A form = void;
		A[factorial!L] allperms;
		size_t permsCtr = 0;
		doPermute(arr, used, 0u, form, allperms, permsCtr); //writeln();
		return allperms;
	}
	
	private pure @safe void doPermute(
		in A arr, bool[L] used, 
		in size_t pos, 
		A form, 
		A[factorial!L] allperms, 
		ref size_t permsCtr
	) {
		//write("\nat ",pos," ");
		foreach (i; 0 .. L) {
			if (used[i]) continue;
			used[i] = true;
			form[pos] = arr[i];
			if (pos == L-1) {
				//write(form," ",allperms);
				allperms[permsCtr] = form.dup; // idup for immutable
				permsCtr++;
			}
			else
				doPermute(arr, used, pos+1, form, allperms, permsCtr);
			used[i] = false; 
		}
	}
}
template fill(T, size_t L) {
	void fill(T[L] arr, in T val) pure @safe { // memset for efficiency?
		foreach (ref a; arr)
			a = val;
	}
}

/*template permute(A : T[], T) {
	auto permute(in A arr) {
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
	}
}*/


unittest {
	enum int[1] t1 = [5];
	enum t1res = permute(t1);
	static assert(t1res == [[5]]);
	writeln(typeid(t1res), " ", typeid(t1res[0]), " ", typeid(t1res[0][0]),"\n", t1res);
	
	enum int[3] t2 = [0,1,2];
	enum t2res = permute(t2);
	static assert(t2res == [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]);
	writeln(t2res);
	
	enum char[3] t3 = "abc";
	enum t3res = permute(t3);
	static assert(t3res == ["abc", "acb", "bac", "bca", "cab", "cba"]);
	writeln(t3res);
	
	enum string[4] t4 = ["Let's","massively","permute","string arrays"];
	enum t4res = permute(t4);
	static assert(t4res == [["Let's", "massively", "permute", "string arrays"], ["Let's", "massively", "string arrays", "permute"], ["Let's", "permute", "massively", "string arrays"], ["Let's", "permute", "string arrays", "massively"], ["Let's", "string arrays", "massively", "permute"], ["Let's", "string arrays", "permute", "massively"], ["massively", "Let's", "permute", "string arrays"], ["massively", "Let's", "string arrays", "permute"], ["massively", "permute", "Let's", "string arrays"], ["massively", "permute", "string arrays", "Let's"], ["massively", "string arrays", "Let's", "permute"], ["massively", "string arrays", "permute", "Let's"], ["permute", "Let's", "massively", "string arrays"], ["permute", "Let's", "string arrays", "massively"], ["permute", "massively", "Let's", "string arrays"], ["permute", "massively", "string arrays", "Let's"], ["permute", "string arrays", "Let's", "massively"], ["permute", "string arrays", "massively", "Let's"], ["string arrays", "Let's", "massively", "permute"], ["string arrays", "Let's", "permute", "massively"], ["string arrays", "massively", "Let's", "permute"], ["string arrays", "massively", "permute", "Let's"], ["string arrays", "permute", "Let's", "massively"], ["string arrays", "permute", "massively", "Let's"]]);
	writeln(t4res);
	
	enum float[4] t5 = [0.0f,0.1f,1.2f,3.7f];
	enum t5res = permute(t5);
	static assert(t5res == [[0, 0.1, 1.2, 3.7], [0, 0.1, 3.7, 1.2], [0, 1.2, 0.1, 3.7], [0, 1.2, 3.7, 0.1], [0, 3.7, 0.1, 1.2], [0, 3.7, 1.2, 0.1], [0.1, 0, 1.2, 3.7], [0.1, 0, 3.7, 1.2], [0.1, 1.2, 0, 3.7], [0.1, 1.2, 3.7, 0], [0.1, 3.7, 0, 1.2], [0.1, 3.7, 1.2, 0], [1.2, 0, 0.1, 3.7], [1.2, 0, 3.7, 0.1], [1.2, 0.1, 0, 3.7], [1.2, 0.1, 3.7, 0], [1.2, 3.7, 0, 0.1], [1.2, 3.7, 0.1, 0], [3.7, 0, 0.1, 1.2], [3.7, 0, 1.2, 0.1], [3.7, 0.1, 0, 1.2], [3.7, 0.1, 1.2, 0], [3.7, 1.2, 0, 0.1], [3.7, 1.2, 0.1, 0]]);
	writeln(t5res);
	
	static assert(is(typeof(factorial!3uL) : ulong));
	
	// dynamic arrays
	/*enum t6 = [2,4];
	const t6res = permute(t6);
	writeln(t6res);*/
}

void main() {
	writeln("hi");
}