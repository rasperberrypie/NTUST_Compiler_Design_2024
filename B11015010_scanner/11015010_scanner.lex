%{
#include "symbolTable.h"
#define LIST                strcat(buffer,yytext)
#define token(t)            {LIST; printf("<%s>\n",#t);}
#define tokenInteger(t,i)   {LIST; printf("<%s:%d>\n",#t,i);}
#define tokenString(t,s)    {LIST; printf("<%s:%s>\n",#t,s);}

#define MAX_BUFFER_SIZE 256

int linenum = 1;
char buffer[MAX_BUFFER_SIZE];

symbolTable* table;

%}

DIGITS              [0-9]+
REAL_NUMBER         [+-]?{DIGITS}\.({DIGITS})?([Ee][+-]?{DIGITS})?
IDENTIFIER          [a-zA-Z_][a-zA-Z_0-9]*
LINE_COMMENT        (\/\/[^\n]*)
PARA_COMMENT_OPEN   (\/\*)
PARA_COMMENT_CLOSE  (\*\/)

%x COMMENT STRING_TEXT CHAR_TEXT

%%

"var"           {token(VAR);}
"val"           {token(VAL);}
"bool"          {token(BOOL);}
"char"          {token(CHAR);}
"string"        {token(STRING);}
"int"           {token(INT);}
"real"          {token(REAL);}
"true"          {token(TRUE);}
"false"         {token(FALSE);}
"class"         {token(CLASS);}
"if"            {token(IF);}
"else"          {token(ELSE);}
"for"           {token(FOR);}
"while"         {token(WHILE);}
"do"            {token(DO);}
"switch"        {token(SWITCH);}
"case"          {token(CASE);}
"default"       {token(DEFAULT);}
"break"         {token(BREAK);}
"fun"           {token(FUNCTION);}
"ret"           {token(RETURN);}
"main"          {token(MAIN);}
"println"       {token(PRINTLN);}


"+"             {token('+');}
"-"             {token('-');}
"*"             {token('*');}
"/"             {token('/');}
"="             {token('=');}
"<"             {token('<');}
"<="            {token('<=');}
">="            {token('>=');}
">"             {token('>');}
"=="            {token('==');}
"!="            {token('!=');}
"%"             {token('%');}
"++"            {token('++');}
"--"            {token('--');}
"&&"            {token('&&');}
"||"            {token('||');}



","             {token(',');}
":"             {token(':');}
";"             {token(';');}
"("             {token('(');}
")"             {token(')');}
"["             {token('[');}
"]"             {token(']');}
"{"             {token('{');}
"}"             {token('}');}


{IDENTIFIER}    { tokenString(id, yytext); 
                  table->insert(yytext);}

{DIGITS}        { tokenInteger(int, atoi(yytext)); }

{REAL_NUMBER}   { tokenString(real, yytext);}
                  

"\'"            { yymore();
                  BEGIN CHAR_TEXT; }

<CHAR_TEXT>[^\']      { yymore(); }

<CHAR_TEXT>"\\n"      { yymore(); }

<CHAR_TEXT>"\\t"      { yymore(); }

<CHAR_TEXT>"\\\\"     { yymore(); }

<CHAR_TEXT>"\\\'"     { yymore(); }

<CHAR_TEXT>"\\\""     { yymore(); }

<CHAR_TEXT>"\\\?"     { yymore(); }

<CHAR_TEXT>"\'"       { int pos = 0;
                        int i = 1;
                        char char_text[MAX_BUFFER_SIZE];
                        if (yytext[i] == '\\')
                        {
                            if (yytext[i+1] == 'n')
                            {
                                char_text[pos] = '\n';
                                i += 2;
                            }
                            else if (yytext[i+1] == 't')
                            {
                                char_text[pos] = '\t';
                                i += 2;
                            }
                            else if (yytext[i+1] == '\\')
                            {
                                char_text[pos] = '\\';
                                i += 2;
                            }
                            else if (yytext[i+1] == '\'')
                            {
                                char_text[pos] = '\'';
                                i += 2;
                            }
                            else if (yytext[i+1] == '\"')
                            {
                                char_text[pos] = '\"';
                                i += 2;
                            }
                            else if (yytext[i+1] == '\?')
                            {
                                char_text[pos] = '\?';
                                i += 2;
                            }
                        }
                        else
                        {
                            if (yyleng > 3) 
                            {
                                exit(-1);
                            } 
                            else 
                            {
                                char_text[pos] = yytext[i];
                                i++;
                            }
                        }
                        char_text[pos+1] = '\0';
                        tokenString(char, char_text);
                        BEGIN 0;
                      }



"\""            { yymore();
                  BEGIN STRING_TEXT; }

<STRING_TEXT>[^\"]    { yymore(); }

<STRING_TEXT>"\\n"    { yymore(); }

<STRING_TEXT>"\\t"    { yymore(); }

<STRING_TEXT>"\\\\"   { yymore(); }

<STRING_TEXT>"\\\'"   { yymore(); }

<STRING_TEXT>"\\\""   { yymore(); }

<STRING_TEXT>"\\\?"   { yymore(); }

<STRING_TEXT>"\""     { int pos = 0;
                        char str_text[MAX_BUFFER_SIZE];
                        for (int i = 1; i < yyleng - 1; i++)
                        {
                            if (yytext[i] == '\\' && yytext[i+1] == '\"')
                            {
                                str_text[pos] = '\"';
                                i++;
                            }
                            else if (yytext[i] == '\\' && yytext[i+1] == '\'')
                            {
                                str_text[pos] = '\'';
                                i++;
                            }
                            else if (yytext[i] == '\\' && yytext[i+1] == '\?')
                            {
                                str_text[pos] = '\?';
                                i++;
                            }
                            else
                            {
                                str_text[pos] = yytext[i];
                            }
                            pos++;
                        }
                        str_text[pos] = '\0';
                        tokenString(string, str_text);
                        BEGIN 0;
                      }


{LINE_COMMENT}                  { LIST; }

{PARA_COMMENT_OPEN}             { LIST;
                                  BEGIN COMMENT; }

<COMMENT>[^\n]                  { LIST; }

<COMMENT>[\n]                   { LIST;
                                  printf("%d: %s", linenum, buffer);
                                  linenum++;
                                  buffer[0] = '\0'; }

<COMMENT>{PARA_COMMENT_CLOSE}   { LIST;
                                  BEGIN 0; }



\n      {
        LIST;
        printf("%d: %s", linenum++, buffer);
        buffer[0] = '\0';
        }

\r\n    {
        LIST;
        printf("%d: %s", linenum++, buffer);
        buffer[0] = '\0';
        }
        
[ \t]*  {LIST;}

.       {
        LIST;
        printf("%d:%s\n", linenum+1, buffer);
        printf("bad character:'%s'\n",yytext);
        exit(-1);
        }
%%


int main(int argc, char** argv)
{
    table = new symbolTable();
    if(argc>1)
    {
        yyin = fopen(argv[1], "r");
    }
    else
    {
        yyin = stdin;
    }

    yylex();
    printf("\nSymbol Table:\n");
    table->dump();
    return 0;
}