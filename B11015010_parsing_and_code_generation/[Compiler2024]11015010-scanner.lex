%{
#include "symbolTable.h"
#include "y.tab.hpp"

#define LIST                strcat(buffer,yytext)
#define token(t)            {LIST; if(printOption) printf("<%s>\n",#t); return(t);}
#define tokenSpec(t)        {LIST; if(printOption) printf("<%s>\n",#t);}
#define tokenInteger(t,i)   {LIST; if(printOption) printf("<%s:%d>\n",#t,i);}
#define tokenString(t,s)    {LIST; if(printOption) printf("<%s:%s>\n",#t,s);}

#define MAX_BUFFER_SIZE 256

int printOption = 0;
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
"fun"           {token(FUNCTION);}
"ret"           {token(RETURN);}
"println"       {token(PRINTLN);}
"print"         {token(PRINT);}

 /* additional */
"string"        {token(STRING);}
"default"       {token(DEFAULT);}
"break"         {token(BREAK);}
"void"          {token(VOID);}
"elif"          {token(ELIF);}


"+"             {tokenSpec('+'); return ADD;}
"-"             {tokenSpec('-'); return SUB;}
"*"             {tokenSpec('*'); return MUL;}
"/"             {tokenSpec('/'); return DIV;}
"%"             {tokenSpec('%'); return MOD;}
"="             {tokenSpec('='); return EQ;}
"<"             {tokenSpec('<'); return(SMALLER_THAN);}
"<="            {tokenSpec('<='); return(SMALLER_THAN_EQ);}
">="            {tokenSpec('>='); return(BIGGER_THAN_EQ);}
">"             {tokenSpec('>'); return(BIGGER_THAN);}
"!"             {tokenSpec('!'); return(NOT);}
"=="            {tokenSpec('='); return(EQUAL);}
"!="            {tokenSpec('!='); return(NOT_EQUAL);}
"&&"            {tokenSpec('&&'); return(AND);}
"||"            {tokenSpec('||'); return(OR);}



","             {tokenSpec(','); return(COMMA);}
":"             {tokenSpec(':'); return(COLON);}
";"             {tokenSpec(';'); return(SEMICOLON);}
"("             {tokenSpec('('); return(OPEN_BRACKET);}
")"             {tokenSpec(')'); return(CLOSE_BRACKET);}
"["             {tokenSpec('['); return(OPEN_ARRAY);}
"]"             {tokenSpec(']'); return(CLOSE_ARRAY);}
"{"             {tokenSpec('{'); return(OPEN_BLOCK);}
"}"             {tokenSpec('}'); return(CLOSE_BLOCK);}


{IDENTIFIER}    { tokenString(id, yytext); 
                  yylval.sType  = new string(yytext);
                  return IDENTIFIER;}

{DIGITS}       { tokenInteger(integer, atoi(yytext));
                 yylval.iType = atoi(yytext);
                 return INTEGER_VAL;}

{REAL_NUMBER}   { tokenString(real_number, yytext);
                  yylval.rType = atof(yytext);
                  return REAL_VAL;}
                  

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
                        yylval.cType = char_text;
                        BEGIN 0;
                        return CHAR_VAL;
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
                        yylval.sType = new string(str_text);
                        BEGIN 0;
                        return STRING_VAL;
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
