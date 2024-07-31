all:  B11015010

B11015010: lex.yy.cpp y.tab.cpp symbolTable.h
	g++ y.tab.cpp symbolTable.h -o B11015010 -ll -ly -std=c++11

lex.yy.cpp:  [Compiler2024]11015010-scanner.lex
	flex -o lex.yy.cpp [Compiler2024]11015010-scanner.lex

y.tab.cpp: [Compiler2024]11015010-parser.y
	bison -d [Compiler2024]11015010-parser.y -o y.tab.cpp

clean:
	rm B11015010 lex.yy.cpp y.tab.*
