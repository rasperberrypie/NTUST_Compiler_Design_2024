all:  B11015010_scanner

B11015010_scanner:  lex.yy.cc
	g++ -o B11015010_scanner -O lex.yy.cc -ll

lex.yy.cc:  11015010_scanner.lex
	lex 11015010_scanner.lex
	mv lex.yy.c lex.yy.cc

clean:
	rm lex.yy.cc B11015010_scanner