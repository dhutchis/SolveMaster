For the real readme, look at the top-level PDF!  This is a midterm project for an AI class I wrote in [D][DLang] to solve the [Mastermind][MastermindWiki] game.  It uses a greedy local search algorithm, getting decent results in decent amounts of time.  The primary heuristic is the entropy of the parition set that a potential guess divides the remaining consistent solutions into.  In order to prune the list of guesses to consider, the algorithm uses precomputed representative guesses based on equivalence classes of the guesses respecting a past history along with other digit heuristics.

Game Parameters:

*	# of colors: 10 (the digits '0'-'9')
*	# of holes: 4
*	Only **unique** colors allowed

Results:

*	Average Game Length: **5.24286** turns
*	Time to run all 5040 possible games: about 15.5 minutes on my laptop

Current distribution of number of turns:

	1	1
	2	5
	3	62
	4	612
	5	2481
	6	1780
	7	98
	8	1		(evil number: 9637)

[DLang]: http://dlang.org/ "D Language"
[MastermindWiki]: http://en.wikipedia.org/wiki/Mastermind_(board_game) "Mastermind Wikipedia"