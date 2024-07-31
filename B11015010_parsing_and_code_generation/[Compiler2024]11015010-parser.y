%{
#include <iostream>
#include <string>
#include "lex.yy.cpp"
#include <fstream>


#define Trace(t)        printf("\x1b[34m%s\x1b[0m\n", t); /* Writing what rule is currently being read*/
#define yyerror(msg)    fprintf(stderr, "\x1b[31m%s\x1b[0m\n", msg); exit(1); /*Write the error regarding the inputs of the data based on the rules*/

Identifier_Value* func_support = new Identifier_Value(); /*To help in inputting the arguments of the function into the function declaration*/
int function_return_data_type = -1; /*To help in determining whether the return of the function is the same with the function return data type*/
bool functionHasReturn = false; /*Check whether the function has return, if return is needed*/
bool inFunction = false; /*Check whether the current location is inside a function*/
vector<Identifier> func_invo_compare; /*Help for function declaration comparing with the arguments of the function*/
vector<int> arraySize; /*Help for knowing array dimension*/
vector<string> arrayExpressionDeclarationValue;
int arrayExpressionSize = 0; /*Help for counting the number of expression*/
int arrayExpressionPos = 0; /*Help in checking the current dimension been checked*/
int arrayDataType = 4;
bool inLoop = false; /*Check whether the current location is inside a loop */

ofstream OF;
%}


/*----------------------------------------------------------*/
/*                   UNION DECLARATION                      */
/*      to declare the datatype of the inputs given         */
/*----------------------------------------------------------*/
%union 
{
    int iType;
    float rType;
    bool bType;
    char* cType;
    string* sType;
    Identifier* idType;
}


/*----------------------------------------------------------*/
/*                    TOKEN DECLARATION                     */
/* to specify potential transmitted values from the scanner */
/*----------------------------------------------------------*/
%token VAR VAL BOOL CHAR INT REAL CLASS IF ELSE FOR WHILE DO SWITCH CASE FUNCTION RETURN MAIN PRINTLN PRINT STRING CONST DEFAULT BREAK VOID ELIF
%token ADD SUB MUL DIV MOD EQ SMALLER_THAN SMALLER_THAN_EQ BIGGER_THAN_EQ BIGGER_THAN NOT EQUAL NOT_EQUAL AND OR
%token COMMA COLON SEMICOLON OPEN_BRACKET CLOSE_BRACKET OPEN_ARRAY CLOSE_ARRAY OPEN_BLOCK CLOSE_BLOCK
%token <iType> INTEGER_VAL
%token <rType> REAL_VAL
%token <bType> FALSE TRUE
%token <cType> CHAR_VAL
%token <sType> STRING_VAL IDENTIFIER


/*----------------------------------------------------------*/
/*                      TYPE DECLARATION                    */
/*----------------------------------------------------------*/
%type <idType> constExp expression functionInvo


/*----------------------------------------------------------*/
/*                   EXPRESSION PRECENDENCE                 */
/*----------------------------------------------------------*/
%left OR
%left AND
%left NOT
%left SMALLER_THAN SMALLER_THAN_EQ BIGGER_THAN BIGGER_THAN_EQ EQUAL NOT_EQUAL
%left SUB ADD
%left MOD DIV MUL
%left OPEN_BRACKET CLOSE_BRACKET
%nonassoc UMINUS


/*----------------------------------------------------------*/
/*                   START OF THE PROGRAM                   */
/*----------------------------------------------------------*/
%%
program             : optionalHeader statementDec
                      { /*A program consists of the header (variable, constant, function, and array declaration) continued by statements*/
                            Trace("Reducing to program\n");
                            dump_table();
                      };
                      
/*----------------------------------------------------------*/
/*                    PROGRAM HEADER                        */
/*----------------------------------------------------------*/
optionalHeader      : variableDec optionalHeader
                    | constantDec optionalHeader
                    | functionDec optionalHeader
		            | voidFunctionDec optionalHeader
                    | arrayDec optionalHeader
                    |
                    ;

/*----------------------------------------------------------*/
/*                  VARIABLE DECLARATION                    */
/*----------------------------------------------------------*/
variableDec         : VAR IDENTIFIER EQ expression SEMICOLON
                    {/* var id = exp */
                        Trace("Variable declaration with expression");
                        
                        if(insertVar(*$2, $4->Data_type, $4->value) == -1)
                        {/*Check whether the identifier name has been used, while at the same time inserting the identifier declared into the table, with the expression, based on the data type of the expression*/
                            yyerror("Identifier Redefinition");
                        }

                        if($4->Data_type == 0)
                        {
                            OF<<"int "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 1)
                        {
                            OF<<"string "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 2)
                        {
                            OF<<"double "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 3)
                        {
                            OF<<"bool "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 5)
                        {
                            OF<<"char "<<*$2<<" = ";
                        }

                        OF<<$4->idName<<";\n";
                        
                    }
                   
                    | VAR IDENTIFIER COLON INT EQ expression SEMICOLON
                    {/* var id: int = exp */
                        Trace("Variable declaration of int data type with expression");

                        if($6->Data_type != 0 && $6->Data_type != 2)
                        {/*Check whether the expression is int data type */
                            yyerror("Data Type and Expression Type doesn't match");
                        }
                         
                        if(insertVar(*$2, 0, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"int "<<*$2<<" = "<<$6->idName<<";\n";
                    }

                    | VAR IDENTIFIER COLON INT SEMICOLON
                    {/* var id: int */
                        Trace("Variable declaration of int data type");

                        if(insertVar(*$2, 0) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"int "<<*$2<<";\n";
                    }

                    | VAR IDENTIFIER COLON STRING EQ expression SEMICOLON
                    {/* var id: string = exp */
                        Trace("Variable declaration of string data type with expression");

                        if($6->Data_type != 1)
                        {
                            yyerror("Data Type and Expression Type doesn't match");
                        }

                        if(insertVar(*$2, 1, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"string "<<*$2<<" = "<<$6->idName<<";\n";
                    }

                    | VAR IDENTIFIER COLON STRING SEMICOLON
                    {/* var id: string */
                        Trace("Variable declaration of string data type");

                        if(insertVar(*$2, 1) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"string "<<*$2<<";\n";
                    }

                    | VAR IDENTIFIER COLON REAL EQ expression SEMICOLON
                    {/* var id: real = exp */
                        Trace("Variable declaration of real data type with expression");

                        if($6->Data_type != 2 && $6->Data_type != 0)
                        {
                            yyerror("Data Type and Expression Type doesn't match");
                        }
                        
                        if(insertVar(*$2, 2, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"double "<<*$2<<" = "<<$6->idName<<";\n";
                    }

                    | VAR IDENTIFIER COLON REAL SEMICOLON
                    {/* var id: real */
                        Trace("Variable declaration of real data type");

                        if(insertVar(*$2, 2) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"double "<<*$2<<";\n";
                    }

                    | VAR IDENTIFIER COLON BOOL EQ expression SEMICOLON
                    {/* var id: bool = exp */
                        Trace("Variable declaration of bool data type with expression");

                        if($6->Data_type != 3)
                        {
                            yyerror("Data Type and Expression Type doesn't match");
                        }
                        
                        if(insertVar(*$2, 3, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"bool "<<*$2<<" = "<<$6->idName<<";\n";
                    }
                    | VAR IDENTIFIER COLON BOOL SEMICOLON
                    {/* var id: bool */
                        Trace("Variable declaration of bool data type");

                        if(insertVar(*$2, 3) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"bool "<<*$2<<";\n";
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*                  CONSTANT DECLARATION                    */
/*----------------------------------------------------------*/
constantDec         : VAL IDENTIFIER EQ expression SEMICOLON
                    {/* val id = exp */
                        Trace("Constant declaration with expression");

                        if($4->isConst!=true)
                        {
                            yyerror("Expression is not a constant");
                        }
                        
                        if(insertConst(*$2, $4->Data_type, $4->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        if($4->Data_type == 0)
                        {
                            OF<<"const int "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 1)
                        {
                            OF<<"const string "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 2)
                        {
                            OF<<"const double "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 3)
                        {
                            OF<<"const bool "<<*$2<<" = ";
                        }
                        else if($4->Data_type == 5)
                        {
                            OF<<"const char "<<*$2<<" = ";
                        }

                        OF<<$4->idName<<";\n";
                    }
                    | VAL IDENTIFIER COLON INT EQ expression SEMICOLON
                    {/* val id: int = exp */
                        Trace("Constant declaration of int data type with expression");

                        if($6->Data_type != 0 && $6->Data_type != 2)
                        {
                            yyerror("Data Type and Expression Type doesn't match");
                        }
                        
                        if($6->isConst!=true)
                        {
                            yyerror("Expression is not a constant");
                        }

                        if(insertConst(*$2, 0, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"const int "<<*$2<<" = "<<$6->idName<<";\n";
                    }

                    | VAL IDENTIFIER COLON STRING EQ expression SEMICOLON
                    {/* val id: string = exp */
                        Trace("Constant declaration of string data type with expression");

                        if($6->Data_type != 1)
                        {
                            yyerror("Data Type and Expression Type doesn't match");
                        }
                        
                        if($6->isConst!=true)
                        {
                            yyerror("Expression is not a constant");
                        }

                        if(insertConst(*$2, 1, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"const string "<<*$2<<" = "<<$6->idName<<";\n";
                    }

                    | VAL IDENTIFIER COLON REAL EQ expression SEMICOLON
                    {/* val id: real = exp */
                        Trace("Constant declaration of real data type with expression");

                        if($6->Data_type != 2 && $6->Data_type != 0)
                        {
                            yyerror("Data Type and Expression Type doesn't match");
                        }
                        
                        if($6->isConst!=true)
                        {
                            yyerror("Expression is not a constant");
                        }

                        if(insertConst(*$2, 2, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"const double "<<*$2<<" = "<<$6->idName<<";\n";
                    }

                    | VAL IDENTIFIER COLON BOOL EQ expression SEMICOLON
                    {/* val id: bool = exp */
                        Trace("Constant declaration of bool data type with expression");

                        if($6->Data_type != 3)
                        {
                            yyerror("Data Type and Expression Type doesn't match");
                        }
                        
                        if($6->isConst!=true)
                        {
                            yyerror("Expression is not a constant");
                        }

                        if(insertConst(*$2, 3, $6->value) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"const bool "<<*$2<<" = "<<$6->idName<<";\n";
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*                     ARRAY DECLARATION                    */
/*----------------------------------------------------------*/
arrayDec            : VAR IDENTIFIER COLON INT OPEN_ARRAY arrayDimension SEMICOLON
                    {/* var id: int[exp] */
                        Trace("Array declaration of int data type");

                        if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"int "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<";\n";

                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }
                    }

                    | VAR IDENTIFIER COLON INT OPEN_ARRAY arrayDimension EQ OPEN_BLOCK 
                    {/* var id: int[exp] */
                        Trace("Array declaration of int data type");
                        
                        if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        arrayExpressionSize = 0;
                        arrayExpressionPos = 0;
                        arrayDataType = 0;
                    }
                    arrayExpression CLOSE_BLOCK SEMICOLON
                    {
                        OF<<"int "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<" = {";

                        for(int start = 0; start<arrayExpressionDeclarationValue.size();start++)
                        {
                            OF<<arrayExpressionDeclarationValue[start];
                            if(start<arrayExpressionDeclarationValue.size()-1)
                            {
                                OF<<",";
                            }
                        }

                        OF<<"};\n";

                        while(arrayExpressionDeclarationValue.size()>0)
                        {
                            arrayExpressionDeclarationValue.pop_back();
                        }


                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }

                        arrayDataType = 4;
                    }

                    | VAR IDENTIFIER COLON CHAR OPEN_ARRAY arrayDimension SEMICOLON
                    {/* var id: char[exp] */
                        Trace("Array declaration of char data type");

                       if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"char "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<";\n";

                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }         
                    }

                    | VAR IDENTIFIER COLON CHAR OPEN_ARRAY arrayDimension EQ OPEN_BLOCK
                    {/* var id: char[exp] */
                        Trace("Array declaration of char data type");

                        if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        arrayExpressionSize = 0;
                        arrayExpressionPos = 0;
                        arrayDataType = 5;
                    }
                    arrayExpression CLOSE_BLOCK SEMICOLON
                    {
                        OF<<"char "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<" = {";

                        for(int start = 0; start<arrayExpressionDeclarationValue.size();start++)
                        {
                            OF<<arrayExpressionDeclarationValue[start];
                            if(start<arrayExpressionDeclarationValue.size()-1)
                            {
                                OF<<",";
                            }
                        }

                        OF<<"};\n";

                        while(arrayExpressionDeclarationValue.size()>0)
                        {
                            arrayExpressionDeclarationValue.pop_back();
                        }


                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }

                        arrayDataType = 4;
                    }     

                    | VAR IDENTIFIER COLON REAL OPEN_ARRAY arrayDimension SEMICOLON
                    {/* var id: real[exp] */
                        Trace("Array declaration of real data type");

                        if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"double "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<";\n";

                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }         
                    }

                    | VAR IDENTIFIER COLON REAL OPEN_ARRAY arrayDimension EQ OPEN_BLOCK
                    {/* var id: real[exp] */
                        Trace("Array declaration of real data type");

                        if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        arrayExpressionSize = 0;
                        arrayExpressionPos = 0;
                        arrayDataType = 2;
                    }
                    arrayExpression CLOSE_BLOCK SEMICOLON
                    {
                        OF<<"double "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<" = {";

                        for(int start = 0; start<arrayExpressionDeclarationValue.size();start++)
                        {
                            OF<<arrayExpressionDeclarationValue[start];
                            if(start<arrayExpressionDeclarationValue.size()-1)
                            {
                                OF<<",";
                            }
                        }

                        OF<<"};\n";

                        while(arrayExpressionDeclarationValue.size()>0)
                        {
                            arrayExpressionDeclarationValue.pop_back();
                        }


                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }

                        arrayDataType = 4;
                    }      

                    | VAR IDENTIFIER COLON BOOL OPEN_ARRAY arrayDimension SEMICOLON
                    {/* var id: bool[exp] */
                        Trace("Array declaration of bool data type");

                        if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        OF<<"bool "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<";\n";

                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }          
                    }

                    | VAR IDENTIFIER COLON BOOL OPEN_ARRAY arrayDimension EQ OPEN_BLOCK
                    {/* var id: bool[exp] */
                        Trace("Array declaration of bool data type");

                        if(insertArray(*$2, 0, arraySize) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        arrayExpressionSize = 0;
                        arrayExpressionPos = 0;
                        arrayDataType = 3;
                    }
                    arrayExpression CLOSE_BLOCK SEMICOLON
                    {
                        OF<<"bool "<<*$2;

                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<" = {";

                        for(int start = 0; start<arrayExpressionDeclarationValue.size();start++)
                        {
                            OF<<arrayExpressionDeclarationValue[start];
                            if(start<arrayExpressionDeclarationValue.size()-1)
                            {
                                OF<<",";
                            }
                        }

                        OF<<"};\n";

                        while(arrayExpressionDeclarationValue.size()>0)
                        {
                            arrayExpressionDeclarationValue.pop_back();
                        }


                        while(arraySize.size()>0)
                        {
                            arraySize.pop_back();
                        }

                        arrayDataType = 4;
                    }
                    ;

arrayDimension      : expression CLOSE_ARRAY 
                    {
                        if($1->isConst!=true)
                        {
                            yyerror("Expression is not a constant");
                        }

                        if($1->Data_type != 0)
                        {
                            yyerror("index is not an int");
                        }
                        arraySize.push_back($1->value->int_data);
                    }
                    | expression CLOSE_ARRAY OPEN_ARRAY
                    {
                        if($1->isConst!=true)
                        {
                            yyerror("Expression is not a constant");
                        }

                        if($1->Data_type != 0)
                        {
                            yyerror("index is not an int");
                        }
                        arraySize.push_back($1->value->int_data);
                    } 
                    arrayDimension
                    ;

arrayExpression     : arrayExpressionValueType
                    {
                        int temp = 1;
                        for(int start = 0; start<arraySize.size();start++)
                        {
                            temp = temp * arraySize[start];
                        }

                        if(temp < arrayExpressionSize)
                        {
                            yyerror("More initialization then available dimension!");
                        }
                    }
                    | arrayExpressionBlockType
                    {
                        if(arrayExpressionPos != arraySize.size())
                        {
                            yyerror("Dimensions initialized is not equal to the dimension of the array");
                        }
                    }
                    ;

arrayExpressionValueType    : expression
                            {
                                arrayExpressionSize += 1;

                                if(arrayDataType != $1->Data_type && arrayDataType != 2)
                                {
                                    yyerror("Initialization data type doesn't match");
                                }

                                if(arrayDataType == 2 && ($1->Data_type != 0 && $1->Data_type != 2))
                                {
                                    yyerror("Initialization data type doesn't match");
                                }

                                arrayExpressionDeclarationValue.push_back($1->idName);
                            }
                            arrayExpressionValueType
                            | COMMA expression
                            {
                                arrayExpressionSize += 1;

                                if(arrayDataType != $2->Data_type && arrayDataType != 2)
                                {
                                    yyerror("Initialization data type doesn't match");
                                }

                                if(arrayDataType == 2 && ($2->Data_type != 0 && $2->Data_type != 2))
                                {
                                    yyerror("Initialization data type doesn't match");
                                }

                                arrayExpressionDeclarationValue.push_back($2->idName);
                            }
                            arrayExpressionValueType
                            |
                            ;

arrayExpressionBlockType    : OPEN_BLOCK 
                            {
                                arrayExpressionSize = 0;
                                if(arraySize.size() > 2)
                                {
                                    yyerror("Can't use block declaration for larger than 2D array");
                                }
                            }
                            arrayExpressionValueType CLOSE_BLOCK
                            {
                                Trace("Checking initialization block type dimension");
                                
                                if(arraySize.size() == 2)
                                {
                                    if(arrayExpressionPos >= arraySize[0])
                                    {
                                        yyerror("Too much dimension for initialization");
                                    }

                                    if(arrayExpressionSize != arraySize[1])
                                    {
                                        yyerror("Initialization for the current dimension is incorrect!");
                                    }
                                }
                                else if(arraySize.size() == 1)
                                {
                                    if(arrayExpressionPos >= arraySize[0])
                                    {
                                        yyerror("Too much dimension for initialization");
                                    }
                                    if(arrayExpressionSize != 1)
                                    {
                                        yyerror("Initialization for the current dimension is incorrect!");
                                    }
                                }
                                arrayExpressionPos++;
                            }
                            arrayExpressionBlockType
                            | COMMA OPEN_BLOCK
                            {
                                arrayExpressionSize = 0;
                                if(arraySize.size() > 2)
                                {
                                    yyerror("Can't use block declaration for larger than 2D array");
                                }
                            }
                            arrayExpressionValueType CLOSE_BLOCK
                            {
                                Trace("Checking initialization block type dimension");
                                
                                if(arraySize.size() == 2)
                                {
                                    if(arrayExpressionPos >= arraySize[0])
                                    {
                                        yyerror("Too much dimension for initialization");
                                    }

                                    if(arrayExpressionSize != arraySize[1])
                                    {
                                        yyerror("Initialization for the current dimension is incorrect!");
                                    }
                                }
                                else if(arraySize.size() == 1)
                                {
                                    if(arrayExpressionPos >= arraySize[0])
                                    {
                                        yyerror("Too much dimension for initialization");
                                    }
                                    if(arrayExpressionSize != 1)
                                    {
                                        yyerror("Initialization for the current dimension is incorrect!");
                                    }
                                }
                                arrayExpressionPos++;
                            }
                            arrayExpressionBlockType
                            |
                            ;
                    
/*----------------------------------------------------------*/
/*                  FUNCTION DECLARATION                    */
/*----------------------------------------------------------*/
functionDec         : FUNCTION IDENTIFIER OPEN_BRACKET argumentsDec CLOSE_BRACKET COLON INT 
                    { /* function id (arguments): int {statements and declarations}*/
                        Trace("Function declaration of int data type with arguments");
                        
                        if(inFunction == true)
                        {/*Function can't be declared inside another function*/
                            yyerror("Function declaration inside a function");
                        }

                        /*Initially set that there has been no return value, set that the next statements and declarations would be inside a function, and the function has to have a return with int data type */
                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 0;
                        
                        if(insertFunc(*$2, 0, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table(); /*Make a local symbol table*/
                        insert_arguments_to_table(func_support->func_data); /*Insert the arguments of the function into the symbol table */

                        OF<<"int "<<*$2<<"(";

                        vector<string> argumentID;
                        vector<int> argumentType;

                        for(int start = 0; start<func_support->func_data.size(); start++)
                        {
                            for(const auto& name: func_support->func_data)
                            {
                                if(name.second.order == start)
                                {
                                    argumentID.push_back(name.first);
                                    argumentType.push_back(name.second.Data_type);
                                    break;
                                }
                            }
                        }

                        for(int start = 0; start<argumentID.size(); start++)
                        {
                            if(argumentType[start] == 0)
                            {
                                OF<<"int ";
                            }
                            else if(argumentType[start] == 1)
                            {
                                OF<<"string ";
                            }
                            else if(argumentType[start] == 2)
                            {
                                OF<<"double ";
                            }
                            else if(argumentType[start] == 3)
                            {
                                OF<<"bool ";
                            }
                            else if(argumentType[start] == 5)
                            {
                                OF<<"char ";
                            }

                            OF<<argumentID[start];

                            if(start<argumentID.size()-1)
                            {
                                OF<<", ";
                            }
                        }

                        OF<<")\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value(); /*Reinitialize arguments declaration of function*/

                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }
                        
                        OF<<"}\n";

                        inFunction = false; /*Declare that it is currently outside the function*/
                        function_return_data_type = -1; /*There should be no return outside the function*/
                        dump_table(); /*Dump the local symbol table */
                    }

                    | FUNCTION IDENTIFIER OPEN_BRACKET CLOSE_BRACKET COLON INT 
                    {/* function id (): int {statements and declarations}*/
                        Trace("Function declaration of int data type");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 0;

                        if(insertFunc(*$2, 0, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"int "<<*$2<<"()\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }

                        OF<<"}\n";

                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }

                    | FUNCTION IDENTIFIER OPEN_BRACKET argumentsDec CLOSE_BRACKET COLON STRING 
                    {/* function id (arguments): string {statements and declarations}*/
                        Trace("Function declaration of string data type with arguments");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 1;

                        if(insertFunc(*$2, 1, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"string "<<*$2<<"(";

                        vector<string> argumentID;
                        vector<int> argumentType;

                        for(int start = 0; start<func_support->func_data.size(); start++)
                        {
                            for(const auto& name: func_support->func_data)
                            {
                                if(name.second.order == start)
                                {
                                    argumentID.push_back(name.first);
                                    argumentType.push_back(name.second.Data_type);
                                    break;
                                }
                            }
                        }

                        for(int start = 0; start<argumentID.size(); start++)
                        {
                            if(argumentType[start] == 0)
                            {
                                OF<<"int ";
                            }
                            else if(argumentType[start] == 1)
                            {
                                OF<<"string ";
                            }
                            else if(argumentType[start] == 2)
                            {
                                OF<<"double ";
                            }
                            else if(argumentType[start] == 3)
                            {
                                OF<<"bool ";
                            }
                            else if(argumentType[start] == 5)
                            {
                                OF<<"char ";
                            }

                            OF<<argumentID[start];

                            if(start<argumentID.size()-1)
                            {
                                OF<<", ";
                            }
                        }

                        OF<<")\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }

                        OF<<"}\n";

                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }

                    | FUNCTION IDENTIFIER OPEN_BRACKET CLOSE_BRACKET COLON STRING 
                    {/* function id (): string {statements and declarations}*/
                        Trace("Function declaration of string data type");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 1;

                        if(insertFunc(*$2, 1, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"string "<<*$2<<"()\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }

                        OF<<"}\n";
                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }

                    | FUNCTION IDENTIFIER OPEN_BRACKET argumentsDec CLOSE_BRACKET COLON REAL
                    {/* function id (arguments): real {statements and declarations} */
                        Trace("Function declaration of real data type with arguments");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 2;

                        if(insertFunc(*$2, 2, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"double "<<*$2<<"(";

                        vector<string> argumentID;
                        vector<int> argumentType;

                        for(int start = 0; start<func_support->func_data.size(); start++)
                        {
                            for(const auto& name: func_support->func_data)
                            {
                                if(name.second.order == start)
                                {
                                    argumentID.push_back(name.first);
                                    argumentType.push_back(name.second.Data_type);
                                    break;
                                }
                            }
                        }

                        for(int start = 0; start<argumentID.size(); start++)
                        {
                            if(argumentType[start] == 0)
                            {
                                OF<<"int ";
                            }
                            else if(argumentType[start] == 1)
                            {
                                OF<<"string ";
                            }
                            else if(argumentType[start] == 2)
                            {
                                OF<<"double ";
                            }
                            else if(argumentType[start] == 3)
                            {
                                OF<<"bool ";
                            }
                            else if(argumentType[start] == 5)
                            {
                                OF<<"char ";
                            }

                            OF<<argumentID[start];

                            if(start<argumentID.size()-1)
                            {
                                OF<<", ";
                            }
                        }

                        OF<<")\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }

                        OF<<"}\n";

                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }

                    | FUNCTION IDENTIFIER OPEN_BRACKET CLOSE_BRACKET COLON REAL 
                    {/* function id (): real {statements and declarations} */
                        Trace("Function declaration of real data type");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 2;

                        if(insertFunc(*$2, 2, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"double "<<*$2<<"()\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }

                        OF<<"}\n";

                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }

                    | FUNCTION IDENTIFIER OPEN_BRACKET argumentsDec CLOSE_BRACKET COLON BOOL
                    {/* function id (arguments): bool {statements and declarations} */
                        Trace("Function declaration of bool data type with arguments");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 3;

                        if(insertFunc(*$2, 3, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"bool "<<*$2<<"(";

                        vector<string> argumentID;
                        vector<int> argumentType;

                        for(int start = 0; start<func_support->func_data.size(); start++)
                        {
                            for(const auto& name: func_support->func_data)
                            {
                                if(name.second.order == start)
                                {
                                    argumentID.push_back(name.first);
                                    argumentType.push_back(name.second.Data_type);
                                    break;
                                }
                            }
                        }

                        for(int start = 0; start<argumentID.size(); start++)
                        {
                            if(argumentType[start] == 0)
                            {
                                OF<<"int ";
                            }
                            else if(argumentType[start] == 1)
                            {
                                OF<<"string ";
                            }
                            else if(argumentType[start] == 2)
                            {
                                OF<<"double ";
                            }
                            else if(argumentType[start] == 3)
                            {
                                OF<<"bool ";
                            }
                            else if(argumentType[start] == 5)
                            {
                                OF<<"char ";
                            }

                            OF<<argumentID[start];

                            if(start<argumentID.size()-1)
                            {
                                OF<<", ";
                            }
                        }

                        OF<<")\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }

                        OF<<"}\n";

                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }

                    | FUNCTION IDENTIFIER OPEN_BRACKET CLOSE_BRACKET COLON BOOL 
                    {/* function id (): bool {statements and declarations} */
                        Trace("Function declaration of bool data type");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        functionHasReturn = false;
                        inFunction = true;
                        function_return_data_type = 3;

                        if(insertFunc(*$2, 3, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"bool "<<*$2<<"()\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        if(functionHasReturn == false)
                        {
                            yyerror("Function has no return expression");
                        }

                        OF<<"}\n";

                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*                VOID FUNCTION DECLARATION                 */
/*----------------------------------------------------------*/
voidFunctionDec     : FUNCTION IDENTIFIER OPEN_BRACKET argumentsDec CLOSE_BRACKET 
                    {/* fun id(arguments) {statements and declarations}*/
                        Trace("void function declaration with arguments");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        inFunction = true;
                        function_return_data_type = 4;

                        if(insertFunc(*$2, 4, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);
                        
                        OF<<"int "<<*$2<<"(";

                        vector<string> argumentID;
                        vector<int> argumentType;

                        for(int start = 0; start<func_support->func_data.size(); start++)
                        {
                            for(const auto& name: func_support->func_data)
                            {
                                if(name.second.order == start)
                                {
                                    argumentID.push_back(name.first);
                                    argumentType.push_back(name.second.Data_type);
                                    break;
                                }
                            }
                        }

                        for(int start = 0; start<argumentID.size(); start++)
                        {
                            if(argumentType[start] == 0)
                            {
                                OF<<"int ";
                            }
                            else if(argumentType[start] == 1)
                            {
                                OF<<"string ";
                            }
                            else if(argumentType[start] == 2)
                            {
                                OF<<"double ";
                            }
                            else if(argumentType[start] == 3)
                            {
                                OF<<"bool ";
                            }
                            else if(argumentType[start] == 5)
                            {
                                OF<<"char ";
                            }

                            OF<<argumentID[start];

                            if(start<argumentID.size()-1)
                            {
                                OF<<", ";
                            }
                        }

                        OF<<")\n";
                        OF<<"{\n";

                        func_support = new Identifier_Value();

                        
                    }
                    insideFunction
                    {
                        OF<<"return 0;\n";
                        OF<<"}\n";
                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }
                    | FUNCTION IDENTIFIER OPEN_BRACKET CLOSE_BRACKET 
                    {/* fun id() {statements and declarations} */
                        Trace("void function declaration");

                        if(inFunction == true)
                        {
                            yyerror("Function declaration inside a function");
                        }

                        inFunction = true;
                        function_return_data_type = 4;

                        if(insertFunc(*$2, 4, func_support) == -1)
                        {
                            yyerror("Identifier Redefinition");
                        }

                        new_table();
                        insert_arguments_to_table(func_support->func_data);

                        OF<<"int "<<*$2<<"()\n";
                        OF<<"{\n";
                        func_support = new Identifier_Value();
                    }
                    insideFunction
                    {
                        OF<<"return 0;\n";
                        OF<<"}\n";
                        inFunction = false;
                        function_return_data_type = -1;
                        dump_table();
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*    FUNCTION AND VOID FUNCTION ARGUMENTS DECLARATION      */
/*----------------------------------------------------------*/
argumentsDec        : argumentsDec COMMA argumentDec
                    {
                        /*the arguments can be many or single, if there is*/
                    }
                    | argumentDec
                    ;

/*----------------------------------------------------------*/
/*   FUNCTION AND VOID FUNCTION EACH ARGUMENT DECLARATION   */
/*----------------------------------------------------------*/
argumentDec         : IDENTIFIER COLON INT
                    {/* id: int */
                        Trace("Argument declaration of int data type");
                        
                        if(func_support->func_data.find(*$1) != func_support->func_data.end())
                        {
                            yyerror("Argument with identical identifier");
                        }
                         
                        Identifier temp;
                        temp.Data_type = 0;
                        temp.order = func_support->func_data.size();

                        func_support->func_data[*$1] = temp;
                    }
                    
                    | IDENTIFIER COLON STRING
                    {/* id: string */
                        Trace("Argument declaration of string data type");

                        if(func_support->func_data.find(*$1) != func_support->func_data.end())
                        {
                            yyerror("Argument with identical identifier");
                        }
                        
                        Identifier temp;
                        temp.Data_type = 1;
                        temp.order = func_support->func_data.size();

                        func_support->func_data[*$1] = temp;
                    }

                    | IDENTIFIER COLON REAL
                    {/* id: real */
                        Trace("Argument declaration of real data type");

                        if(func_support->func_data.find(*$1) != func_support->func_data.end())
                        {
                            yyerror("Argument with identical identifier");
                        }

                        Identifier temp;
                        temp.Data_type = 2;
                        temp.order = func_support->func_data.size();

                        func_support->func_data[*$1] = temp;
                    }

                    | IDENTIFIER COLON BOOL
                    {/* id: bool */
                        Trace("Argument declaration of bool data type");

                        if(func_support->func_data.find(*$1) != func_support->func_data.end())
                        {
                            yyerror("Argument with identical identifier");
                        }
                         
                        Identifier temp;
                        temp.Data_type = 3;
                        temp.order = func_support->func_data.size();

                        func_support->func_data[*$1] = temp;
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*     STATEMENTS AND DECLARATIONS ALLOWED IN LOCAL DATA    */
/*----------------------------------------------------------*/
insideFunction      : blockFunctionDec
                    ;

insideBlockFunction : statementDec insideBlockFunction
                    | variableDec insideBlockFunction
                    | constantDec insideBlockFunction
                    | arrayDec insideBlockFunction
                    | blockFunctionDec insideBlockFunction
                    |
                    ;


/*----------------------------------------------------------*/
/*                BLOCK FUNCTION DECLARATION                */
/*----------------------------------------------------------*/
blockFunctionDec    : OPEN_BLOCK
                    {/* { statements and declarations } */
                        new_table();
                        OF<<"{\n";
                    }
                    insideBlockFunction CLOSE_BLOCK
                    {
                        dump_table();
                        OF<<"}\n";
                    }
                    ;   


/*----------------------------------------------------------*/
/*                POSSIBLE STATEMENTS DECLARATIONS          */
/*----------------------------------------------------------*/
statementDec        : simpleDec statementDec
                    | conditionalDec statementDec
                    | loopDec statementDec
                    | voidFunctionInvo statementDec
                    |
                    ;
                    

/*----------------------------------------------------------*/
/*                    SIMPLE DECLARATION                    */
/*----------------------------------------------------------*/
simpleDec           : IDENTIFIER EQ expression SEMICOLON
                    { /*Update variable value -> id = exp */
                        Trace("Identifier update value");
                        
                        if(lookup(*$1) == -1)
                        {/* Identifier not found (-1 means not found) */
                            yyerror("Identifier not found");
                        }

                        Identifier* temp = lookup_data(*$1);

                        if(temp->Data_type != $3->Data_type)
                        {/* Check whether the identifier and expression data type match */
                            yyerror("Identifier and expression type not match");
                        }

                        if(temp->isConst == true)
                        {/* Constants can't be updated */
                            yyerror("Constants can't be redeclared");
                        }

                        OF<<*$1<<" = "<<$3->idName<<";\n";
                    }
                    | PRINT OPEN_BRACKET expression CLOSE_BRACKET SEMICOLON
                    {/* print(exp)  */
                        Trace("Print Expression");
                        if($3->isArray == true)
                        {
                            if($3->value->array_data.size() == 1)
                            {
                                string tempHelper = CreateName();
                                OF<<"for(int "<<tempHelper<<" = 0;"<<tempHelper<<"<"<<$3->value->array_data[0].value->int_data<<";"<<tempHelper<<"++)\n";
                                OF<<"{\n";
                                OF<<"cout<<"<<$3->idName<<"["<<tempHelper<<"]<<\" \";";
                                OF<<"}\n";
                            }
                            else if($3->value->array_data.size() == 2)
                            {
                                string tempHelper1 = CreateName();
                                string tempHelper2 = CreateName();
                                OF<<"for(int "<<tempHelper1<<" = 0;"<<tempHelper1<<"<"<<$3->value->array_data[0].value->int_data<<";"<<tempHelper1<<"++)\n";
                                OF<<"{\n";
                                OF<<"for(int "<<tempHelper2<<" = 0;"<<tempHelper2<<"<"<<$3->value->array_data[0].value->int_data<<";"<<tempHelper2<<"++)\n";
                                OF<<"{\n";
                                OF<<"cout<<"<<$3->idName<<"["<<tempHelper1<<"]["<<tempHelper2<<"]<<\" \";";
                                OF<<"}\n";
                                OF<<"cout<<\"\\n\";";
                                OF<<"}\n";
                            }
                            else
                            {
                                yyerror("Unable to print array with larger dimension");
                            }
                        }
                        else
                        {
                            OF<<"cout<<"<<$3->idName<<";\n";
                        }
                    }
                    
                    | PRINTLN OPEN_BRACKET expression CLOSE_BRACKET SEMICOLON
                    {/* println(exp)  */
                        Trace("println Expression");
                        if($3->isArray == true)
                        {
                            if($3->value->array_data.size() == 1)
                            {
                                string tempHelper = CreateName();
                                OF<<"for(int "<<tempHelper<<" = 0;"<<tempHelper<<"<"<<$3->value->array_data[0].value->int_data<<";"<<tempHelper<<"++)\n";
                                OF<<"{\n";
                                OF<<"cout<<"<<$3->idName<<"["<<tempHelper<<"]<<\" \";\n";
                                OF<<"}\n";
                            }
                            else if($3->value->array_data.size() == 2)
                            {
                                string tempHelper1 = CreateName();
                                string tempHelper2 = CreateName();
                                OF<<"for(int "<<tempHelper1<<" = 0;"<<tempHelper1<<"<"<<$3->value->array_data[0].value->int_data<<";"<<tempHelper1<<"++)\n";
                                OF<<"{\n";
                                OF<<"for(int "<<tempHelper2<<" = 0;"<<tempHelper2<<"<"<<$3->value->array_data[0].value->int_data<<";"<<tempHelper2<<"++)\n";
                                OF<<"{\n";
                                OF<<"cout<<"<<$3->idName<<"["<<tempHelper1<<"]["<<tempHelper2<<"]<<\" \";\n";
                                OF<<"}\n";
                                OF<<"cout<<\"\\n\";\n";
                                OF<<"}\n";
                            }
                            else
                            {
                                yyerror("Unable to print array with larger dimension");
                            }
                        }
                        else
                        {
                            OF<<"cout<<"<<$3->idName<<";\n";
                        }
                        
                        OF<<"cout<<\"\\n\";\n";
                    }
            
                    | RETURN expression SEMICOLON
                    {/* return exp for function, and can only be inside a function */
                        Trace("Return Expression");

                        if(inFunction == false)
                        {/* Can't be declared outside of function */
                            yyerror("Return out of function");
                        }

                        if(function_return_data_type != $2->Data_type && !((function_return_data_type == 0 && $2->Data_type == 2) || (function_return_data_type == 2 && $2->Data_type == 0)))
                        {/* The return expression data type is in correct */
                            yyerror("Function return data type and expression not match");
                        }

                        OF<<"return "<<$2->idName<<";\n";
                        functionHasReturn = true;
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*                EXPRESSION DECLARATION                    */
/*----------------------------------------------------------*/
expression          : OPEN_BRACKET expression CLOSE_BRACKET
                    {/* (exp) */
                        Trace("Expression with brackets");
                        $$ = $2;
                    }
                    | SUB expression %prec UMINUS
                    {/* -exp */
                        Trace("Negative expression");
                        if($2->Data_type != 0 && $2->Data_type != 2)
                        {
                            yyerror("Expression can't be negative");
                        }
                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
                        temp->Data_type = $2->Data_type;
                        temp->isConst = true;
                        temp->value = $2->value;

                        if(temp->Data_type == 0)
                        {
                            OF<<"const int "<<temp->idName<<" = -"<<$2->idName<<";\n";
                        }
                        else if(temp->Data_type == 2)
                        {
                            OF<<"const double "<<temp->idName<<" = -"<<$2->idName<<";\n";
                        }
                        
                        $$ = temp;
                    }
                    | expression MUL expression
                    {/* exp * exp */
                        Trace("Expressions being multiplied");

                        if(($1->isArray == true && $3->isArray == false) || ($1->isArray == false && $3->isArray == true))
                        {
                            yyerror("Can't dot product array with non-array");
                        }

                        if($1->isArray == true && $3->isArray == true)
                        {
                            if($1->value->array_data.size() != $3->value->array_data.size())
                            {
                                yyerror("Dot product of different dimensional array");
                            }

                            if($1->value->array_data.size() == 1)
                            {
                                if($1->value->array_data[0].value->int_data != $3->value->array_data[0].value->int_data)
                                {
                                    yyerror("Dot product of 1D array with different size");
                                }

                                if($1->Data_type != 0 && $1->Data_type != 2)
                                {
                                    yyerror("Dot product can only be done for int or real data");
                                }

                                if($3->Data_type != 0 && $3->Data_type != 2)
                                {
                                    yyerror("Dot product can only be done for int or real data");
                                }

                                Identifier* temp = new Identifier();
                                temp->idName = CreateName();
                                
                                string tempHelper = CreateName();
                                if($1->Data_type == 0 && $3->Data_type == 0)
                                {
                                    OF<<"int "<<tempHelper<<" = 0;\n";
                                    temp->Data_type = 0;
                                }
                                else
                                {
                                    OF<<"double "<<tempHelper<<" = 0;\n";
                                    temp->Data_type = 2;
                                }

                                string tempHelper1 = CreateName();
                                OF<<"for(int "<<tempHelper1<<" = 0;"<<tempHelper1<<"<"<<$1->value->array_data[0].value->int_data<<";"<<tempHelper1<<"++)\n";
                                OF<<"{\n";
                                OF<<tempHelper<<" = "<<$1->idName<<"["<<tempHelper1<<"] * "<<$3->idName<<"["<<tempHelper1<<"] + "<<tempHelper<<";\n";
                                OF<<"}\n";

                                if(temp->Data_type == 0)
                                {
                                    OF<<"const int "<<temp->idName<<" = "<<tempHelper<<";\n";
                                }
                                else
                                {
                                    OF<<"const double "<<temp->idName<<" = "<<tempHelper<<";\n";
                                }

                                $$ = temp;
                            }
                            else if($1->value->array_data.size() == 2)
                            {
                                if($1->value->array_data[1].value->int_data != $3->value->array_data[0].value->int_data)
                                {
                                    yyerror("Dot product of 2D array with different size");
                                }

                                Identifier* temp = new Identifier();
                                temp->idName = CreateName();
                                temp->isArray = true;

                                Identifier arrTemp;
                                arrTemp.Data_type = 0;
			                    arrTemp.order = 0;
			                    arrTemp.value = new Identifier_Value();
			                    arrTemp.value->int_data = $1->value->array_data[0].value->int_data;
                                
                                temp->value->array_data.push_back(arrTemp);
                                
                                Identifier arrTemp1;
                                arrTemp1.Data_type = 0;
			                    arrTemp1.order = 1;
			                    arrTemp1.value = new Identifier_Value();
			                    arrTemp1.value->int_data = $3->value->array_data[1].value->int_data;

                                temp->value->array_data.push_back(arrTemp1);

                                if($1->Data_type == 0 && $3->Data_type == 0)
                                {
                                    temp->Data_type = 0;
                                    OF<<"int "<<temp->idName<<"["<<temp->value->array_data[0].value->int_data<<"]["<<temp->value->array_data[1].value->int_data<<"] = {0};\n";
                                }
                                else
                                {
                                    temp->Data_type = 2;
                                    OF<<"double "<<temp->idName<<"["<<temp->value->array_data[0].value->int_data<<"]["<<temp->value->array_data[1].value->int_data<<"] = {0};\n";
                                }

                                string tempHelper = CreateName();
                                string tempHelper1 = CreateName();
                                string tempHelper2 = CreateName();

                                OF<<"for(int "<<tempHelper<<" = 0;"<<tempHelper<<"<"<<temp->value->array_data[0].value->int_data<<";"<<tempHelper<<"++)\n";
                                OF<<"{\n";
                                OF<<"for(int "<<tempHelper1<<" = 0;"<<tempHelper1<<"<"<<temp->value->array_data[1].value->int_data<<";"<<tempHelper1<<"++)\n";
                                OF<<"{\n";
                                OF<<"for(int "<<tempHelper2<<" = 0;"<<tempHelper2<<"<"<<$1->value->array_data[1].value->int_data<<";"<<tempHelper2<<"++)\n";
                                OF<<"{\n";
                                OF<<temp->idName<<"["<<tempHelper<<"]["<<tempHelper1<<"] = "<<temp->idName<<"["<<tempHelper<<"]["<<tempHelper1<<"] + "<<$1->idName<<"["<<tempHelper<<"]["<<tempHelper2<<"] * "<<$3->idName<<"["<<tempHelper2<<"]["<<tempHelper1<<"];\n";
                                OF<<"}\n";
                                OF<<"}\n";
                                OF<<"}\n";

                                $$ = temp;
                            }
                            else
                            {
                                yyerror("Dot product of array with larger than 2D");
                            }
                        }

                        if($1->isArray == false && $3->isArray == false)
                        {
                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {/* int * int -> int */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 0;
                            temp->isConst = true;
                            temp->value->int_data = $1->value->int_data * $3->value->int_data;

                            OF<<"const int "<<temp->idName<<" = "<<$1->idName<<" * "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {/* int * real -> real */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->int_data * $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" * "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {/* real * int -> real */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data * $3->value->int_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" * "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {/* real * real -> real */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data * $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" * "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {/*When not match with the above rules*/
                            yyerror("Expressions can't be multiplied");
                        }
                        }
                    }

                    | expression DIV expression
                    {/* exp / exp */
                        Trace("Expressions being divided");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No calculation for array with \'/\' sign");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 0;
                            temp->isConst = true;
                            temp->value->int_data = $1->value->int_data / $3->value->int_data;

                            OF<<"const int "<<temp->idName<<" = "<<$1->idName<<" / "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->int_data / $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" / "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data / $3->value->int_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" / "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data / $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" / "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be divided");
                        }
                    }

                    | expression MOD expression
                    {/* exp % exp */
                        Trace("Expressions being mod");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No calculation for array with \'\%\' sign");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 0;
                            temp->isConst = true;
                            temp->value->int_data = $1->value->int_data % $3->value->int_data;

                            OF<<"const int "<<temp->idName<<" = "<<$1->idName<<" % "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be mod");
                        }
                    }
                    | expression ADD expression
                    {/* exp + exp */
                        Trace("Expressions being added");

                        if(($1->isArray == true && $3->isArray == false) || ($1->isArray == false && $3->isArray == true))
                        {
                            yyerror("Can't add array with non-array");
                        }

                        if($1->isArray == true && $3->isArray == true)
                        {
                            if($1->value->array_data.size() != $3->value->array_data.size())
                            {
                                yyerror("Addition of different dimensional array");
                            }

                            if($1->value->array_data.size()>2)
                            {
                                yyerror("Currently doesn't support array addition larger than 2D");
                            }

                            for(int start = 0; start<$1->value->array_data.size(); start++)
                            {
                                if($1->value->array_data[start].value->int_data != $3->value->array_data[start].value->int_data)
                                {
                                    yyerror("Addition of array with different size");
                                }
                            }

                            if($1->value->array_data.size() == 1)
                            {
                                if($1->Data_type != 0 && $1->Data_type != 2)
                                {
                                    yyerror("Array addition can only be done for int or real data");
                                }

                                if($3->Data_type != 0 && $3->Data_type != 2)
                                {
                                    yyerror("Array addition can only be done for int or real data");
                                }

                                Identifier* temp = new Identifier();
                                temp->idName = CreateName();
                                temp->isArray = true;
                                temp->value = $1->value;
                                
                                if($1->Data_type == 0 && $3->Data_type == 0)
                                {
                                    temp->Data_type = 0;
                                    OF<<"int "<<temp->idName<<"["<<temp->value->array_data[0].value->int_data<<"] = {0};\n";
                                }
                                else
                                {
                                    temp->Data_type = 2;
                                    OF<<"double "<<temp->idName<<"["<<temp->value->array_data[0].value->int_data<<"] = {0};\n";
                                }

                                string tempHelper1 = CreateName();
                                OF<<"for(int "<<tempHelper1<<" = 0;"<<tempHelper1<<"<"<<$1->value->array_data[0].value->int_data<<";"<<tempHelper1<<"++)\n";
                                OF<<"{\n";
                                OF<<temp->idName<<"["<<tempHelper1<<"] = "<<$1->idName<<"["<<tempHelper1<<"] + "<<$3->idName<<"["<<tempHelper1<<"] + "<<temp->idName<<"["<<tempHelper1<<"];\n";
                                OF<<"}\n";

                                $$ = temp;
                            }

                            else if($1->value->array_data.size() == 2)
                            {
                                if($1->Data_type != 0 && $1->Data_type != 2)
                                {
                                    yyerror("Array addition can only be done for int or real data");
                                }

                                if($3->Data_type != 0 && $3->Data_type != 2)
                                {
                                    yyerror("Array addition can only be done for int or real data");
                                }

                                Identifier* temp = new Identifier();
                                temp->idName = CreateName();
                                temp->isArray = true;
                                temp->value = $1->value;

                                if($1->Data_type == 0 && $3->Data_type == 0)
                                {
                                    temp->Data_type = 0;
                                    OF<<"int "<<temp->idName<<"["<<temp->value->array_data[0].value->int_data<<"]["<<temp->value->array_data[1].value->int_data<<"] = {0};\n";
                                }
                                else
                                {
                                    temp->Data_type = 2;
                                    OF<<"double "<<temp->idName<<"["<<temp->value->array_data[0].value->int_data<<"]["<<temp->value->array_data[1].value->int_data<<"] = {0};\n";
                                }

                                string tempHelper = CreateName();
                                string tempHelper1 = CreateName();

                                OF<<"for(int "<<tempHelper<<" = 0;"<<tempHelper<<"<"<<temp->value->array_data[0].value->int_data<<";"<<tempHelper<<"++)\n";
                                OF<<"{\n";
                                OF<<"for(int "<<tempHelper1<<" = 0;"<<tempHelper1<<"<"<<temp->value->array_data[1].value->int_data<<";"<<tempHelper1<<"++)\n";
                                OF<<"{\n";
                                OF<<temp->idName<<"["<<tempHelper<<"]["<<tempHelper1<<"] = "<<temp->idName<<"["<<tempHelper<<"]["<<tempHelper1<<"] + "<<$1->idName<<"["<<tempHelper<<"]["<<tempHelper1<<"] + "<<$3->idName<<"["<<tempHelper<<"]["<<tempHelper1<<"];\n";
                                OF<<"}\n";
                                OF<<"}\n";

                                $$ = temp;
                            }

                        }

                        if($1->isArray == false && $3->isArray == false)
                        {
                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 0;
                            temp->isConst = true;
                            temp->value->int_data = $1->value->int_data + $3->value->int_data;

                            OF<<"const int "<<temp->idName<<" = "<<$1->idName<<" + "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->int_data + $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" + "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data + $3->value->int_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" + "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data + $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" + "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be added");
                        }
                        }
                    }

                    | expression SUB expression
                    {/* exp - exp */
                        Trace("Expressions being substracted");

                        if(($1->isArray == true && $3->isArray == false) || ($1->isArray == false && $3->isArray == true))
                        {
                            yyerror("Can't subtract array with non-array");
                        }

                        if($1->isArray == true && $3->isArray == true)
                        {
                            if($1->value->array_data.size() != $3->value->array_data.size())
                            {
                                yyerror("Subtraction of different dimensional array");
                            }

                            for(int start = 0; start<$1->value->array_data.size(); start++)
                            {
                                if($1->value->array_data[start].value->int_data != $3->value->array_data[start].value->int_data)
                                {
                                    yyerror("Subtraction of array with different size");
                                }
                            }
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 0;
                            temp->isConst = true;
                            temp->value->int_data = $1->value->int_data - $3->value->int_data;

                            OF<<"const int "<<temp->idName<<" = "<<$1->idName<<" - "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->int_data - $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" - "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data - $3->value->int_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" - "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 2;
                            temp->isConst = true;
                            temp->value->real_data = $1->value->real_data - $3->value->real_data;

                            OF<<"const double "<<temp->idName<<" = "<<$1->idName<<" - "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be substracted");
                        }
                    }

                    | expression BIGGER_THAN_EQ expression
                    {/* exp >= exp */
                        Trace("Comparing the expression by bigger than equal");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {/* int >= int -> bool*/
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data >= $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" >= "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {/* int >= real -> bool*/
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data >= $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" >= "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {/* real >= int -> bool*/
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data >= $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" >= "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {/* real >= real -> bool*/
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data >= $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" >= "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be compared");
                        }
                    }

                    | expression BIGGER_THAN expression
                    {/* exp > exp */
                        Trace("Comparing the expression by bigger than");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data > $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" > "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data > $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" > "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data > $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" > "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data > $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" > "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be compared");
                        }
                    }

                    | expression SMALLER_THAN_EQ expression
                    {/* exp <= exp */
                        Trace("Comparing the expression by smaller than equal");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data <= $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" <= "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data <= $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" <= "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data <= $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" <= "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data <= $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" <= "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be compared");
                        }
                    }

                    | expression SMALLER_THAN expression
                    {/* exp < exp */
                        Trace("Comparing the expression by smaller than");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data < $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" < "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data < $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" < "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data < $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" < "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data < $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" < "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be compared");
                        }
                    }

                    | expression EQUAL expression
                    {/* exp = exp */
                        Trace("Comparing the expression by equal");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data == $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" == "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data == $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" == "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data == $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" == "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data == $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" == "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 3 && $3->Data_type == 3)
                        {/* bool = bool -> bool */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->bool_data == $3->value->bool_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" == "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 1 && $3->Data_type == 1)
                        {/* string = string -> bool */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->string_data == $3->value->string_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" == "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 5 && $3->Data_type == 5)
                        {/* char = char -> bool */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->char_data == $3->value->char_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" == "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be compared");
                        }
                    }

                    | expression NOT_EQUAL expression
                    {/* exp != exp */
                        Trace("Comparing the expression by not equal");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 0 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data != $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" != "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 0 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->int_data != $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" != "<<$3->idName<<";\n";
                            $$ = temp;                            
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 0)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data != $3->value->int_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" != "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 2 && $3->Data_type == 2)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->real_data != $3->value->real_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" != "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 3 && $3->Data_type == 3)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->bool_data != $3->value->bool_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" != "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 1 && $3->Data_type == 1)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->string_data != $3->value->string_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" != "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else if($1->Data_type == 5 && $3->Data_type == 5)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->char_data != $3->value->char_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" != "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions can't be compared");
                        }
                    }

                    | NOT expression
                    {/* not bool exp */
                        Trace("Not expression");

                        if($2->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($2->Data_type != 3)
                        {/* only bool can be negate */
                            yyerror("Expression not bool");
                        }

                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
                        temp->Data_type = 3;
                        temp->isConst = true;
                        temp->value->bool_data = !($2->value->bool_data);

                        OF<<"const bool "<<temp->idName<<" = !"<<$2->idName<<";\n";
                        $$ = temp;
                    }

                    | expression AND expression
                    {/* exp and exp */
                        Trace("Expression and expression");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 3 && $3->Data_type == 3)
                        {/* only bool can be "and" */
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->bool_data && $3->value->bool_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" && "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions are not bool");
                        }
                    }

                    | expression OR expression
                    {/* exp or exp */
                        Trace("Expression or expression");

                        if($1->isArray == true || $3->isArray == true)
                        {
                            yyerror("No logical operation for array");
                        }

                        if($1->Data_type == 3 && $3->Data_type == 3)
                        {
                            Identifier* temp = new Identifier();
                            temp->idName = CreateName();
                            temp->Data_type = 3;
                            temp->isConst = true;
                            temp->value->bool_data = $1->value->bool_data || $3->value->bool_data;

                            OF<<"const bool "<<temp->idName<<" = "<<$1->idName<<" || "<<$3->idName<<";\n";
                            $$ = temp;
                        }
                        else
                        {
                            yyerror("Expressions are not bool");
                        }
                    }

                    | constExp
                    {/* constants */
                        $$ = $1;
                    }
                    | IDENTIFIER OPEN_ARRAY
                    {/* array declaration */
                        if(lookup(*$1) == -1)
                        {/* Check whether the identifier is found in the table */
                            yyerror("Identifier not found");
                        }

                        Identifier* check = lookup_data(*$1);

                        if(check->isArray != true)
                        {/* check whether the id declared is an array */
                            yyerror("Identifier is not an array type");
                        }
                    }
                    multiDimensionalArrayInvo
                    {
                        Identifier* check = lookup_data(*$1);
                        
                        if(check->value->array_data.size() != arraySize.size())
                        {
                            yyerror("Array invocation of different dimension");
                        }

                        for(int start = 0; start < check->value->array_data.size(); start++)
                        {
                            if(arraySize[start] >= check->value->array_data[start].value->int_data)
                            {
                                yyerror("Array invocation out of bound");
                            }
                        }

                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
                        temp->isConst = true;
                        temp->Data_type = check->Data_type;
                        /* The return for an array only check whether the data type is correct because if want to return the exact value, it would be complex */
                        
                        if(check->Data_type == 0)
                        {
                            OF<<"const int "<<temp->idName<<" = "<<*$1;
                        }
                        else if(check->Data_type == 1)
                        {
                            OF<<"const string "<<temp->idName<<" = "<<*$1;
                        }
                        else if(check->Data_type == 2)
                        {
                            OF<<"const double "<<temp->idName<<" = "<<*$1;
                        }
                        else if(check->Data_type == 3)
                        {
                            OF<<"const bool "<<temp->idName<<" = "<<*$1;
                        }
                        else if(check->Data_type == 5)
                        {
                            OF<<"const char "<<temp->idName<<" = "<<*$1;
                        }


                        for(int start = 0; start<arraySize.size(); start++)
                        {
                            OF<<"["<<arraySize[start]<<"]";
                        }

                        OF<<";\n";


                        while(arraySize.size()!=0)
                        {
                            arraySize.pop_back();
                        }

                        $$ = temp;
                    }
                    | functionInvo
                    {/* call function */
                        $$ = $1;
                    }
                    | IDENTIFIER
                    {/* identifier invocation */
                        Trace("Identifier invocation");
                        
                        if(lookup(*$1) == -1)
                        {/* check whether the id has been declared */
                            yyerror("Identifier not found");
                        }

                        Identifier* temp = lookup_data(*$1);
                        if(temp->isFunc == true)
                        {
                            yyerror("Invalid function invocation");
                        }

                        $$ = temp;
                    }
                    ;

multiDimensionalArrayInvo   : expression CLOSE_ARRAY
                            {
                                if($1->Data_type != 0)
                                {
                                    yyerror("Array index is non-integer");
                                }

                                arraySize.push_back($1->value->int_data);
                            }
                            | expression CLOSE_ARRAY OPEN_ARRAY 
                            {
                                if($1->Data_type != 0)
                                {
                                    yyerror("Array index is non-integer");
                                }
                                
                                arraySize.push_back($1->value->int_data);
                            }
                            multiDimensionalArrayInvo
                            ;
/*----------------------------------------------------------*/
/*                FUNCTION INVOCATION                       */
/*----------------------------------------------------------*/
functionInvo        : IDENTIFIER OPEN_BRACKET insideFunctionInvo CLOSE_BRACKET
                    {/* id(arguments) */
                        Trace("Function invocation with arguments inside");

                        if(lookup(*$1) == -1)
                        {
                            yyerror("Identifier not found");
                        }

                        Identifier* temp = lookup_data(*$1);

                        if(temp->isFunc == false || temp->Data_type == 4)
                        {/* the identifier must be a function, but not a void function */
                            yyerror("Identifier is not a function type");
                        }

                        /* for extracting the arguments needed for the function invocation, based on its order */
                        vector<int> func_arguments_data_type;

                        for(int pos = 0; pos < temp->value->func_data.size(); pos++)
                        {
                            for(const auto& name : temp->value->func_data)
                            {
                                if(pos == name.second.order)
                                {
                                    func_arguments_data_type.push_back(name.second.Data_type);
                                    break;
                                }
                            }
                        }

                        if(func_arguments_data_type.size()!=func_invo_compare.size())
                        {/* the number of arguments should be the same as what needed to call the function */
                            yyerror("Different number of arguments");
                        }

                        for(int pos = 0; pos < func_invo_compare.size(); pos++)
                        {/* each arguments should have the same data type with what needed to call the function */
                            if(func_arguments_data_type[pos] != func_invo_compare[pos].Data_type)
                            {
                                yyerror("Function invocation argument data type not match");
                            }
                        }

                        Identifier* temp2 = new Identifier();
                        temp2->idName = CreateName();
                        temp2->isConst = true;
                        temp2->Data_type = temp->Data_type;

                        if(temp->Data_type == 0)
                        {
                            OF<<"const int "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 1)
                        {
                            OF<<"const string "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 2)
                        {
                            OF<<"const double "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 3)
                        {
                            OF<<"const bool "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 5)
                        {
                            OF<<"const char "<<temp2->idName<<" = "<<*$1;
                        }

                        OF<<"(";

                        for(int start = 0; start<func_invo_compare.size(); start++)
                        {
                            OF<<func_invo_compare[start].idName;

                            if(start < func_invo_compare.size() - 1)
                            {
                                OF<<", ";
                            }
                        }

                        OF<<");\n";

                        while(func_invo_compare.size()!=0)
                        {/* reinitialize the argument buffer for function or void function invocation */
                            func_invo_compare.pop_back();
                        }

                        $$ = temp2;
                    }
                    | IDENTIFIER OPEN_BRACKET CLOSE_BRACKET
                    {/* id() */
                        Trace("Function invocation");

                        if(lookup(*$1) == -1)
                        {
                            yyerror("Identifier not found");
                        }

                        Identifier* temp = lookup_data(*$1);

                        if(temp->isFunc == false || temp->Data_type == 4)
                        {
                            yyerror("Identifier is not a function type");
                        }

                        if(temp->value->func_data.size() != 0)
                        {/* the function should not have any arguments */
                            yyerror("Function missing arguments");
                        }

                        Identifier* temp2 = new Identifier();
                        temp2->idName = CreateName();
                        temp2->isConst = true;
                        temp2->Data_type = temp->Data_type;

                        if(temp->Data_type == 0)
                        {
                            OF<<"const int "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 1)
                        {
                            OF<<"const string "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 2)
                        {
                            OF<<"const double "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 3)
                        {
                            OF<<"const bool "<<temp2->idName<<" = "<<*$1;
                        }
                        else if(temp->Data_type == 5)
                        {
                            OF<<"const char "<<temp2->idName<<" = "<<*$1;
                        }

                        OF<<"();\n";

                        $$ = temp;
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*         ARGUMENTS FOR FUNCTION INVOCATION                */
/*----------------------------------------------------------*/
insideFunctionInvo  : expression COMMA insideFunctionInvo
                    {/* exp, expressions */

                        /* push the expression declared into the function invocation argument buffer */
                        func_invo_compare.push_back(*$1);
                    }
                    | expression
                    {/* exp */
                        func_invo_compare.push_back(*$1);
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*         ARGUMENTS FOR FUNCTION INVOCATION                */
/*----------------------------------------------------------*/
conditionalDec      : IF expression
                    {/* if (exp) {statements and declarations} <else {statements and declarations}> */
                        Trace("Conditional declaration");
                        
                        if($2->Data_type!=3)
                        {/* the exp should be bool */
                            yyerror("Expression is not bool");
                        }

                        new_table();
                        /* make local symbol table for the part inside then */
                    }
                    insideFunction optionalElse
                    {
                        /* else is optional, after declaring statements and declarations, the local symbol table should be dumped */
                        dump_table();
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*             OPTIONAL ELSE FOR CONDITIONAL                */
/*----------------------------------------------------------*/
optionalElse        : ELIF insideFunction optionalElse
                    { /* elif {declarations and statements} */
                        /* dump the local symbol table for then, and create a new symbol table for elif */
                        dump_table();
                        new_table();
                    }

                    | ELSE insideFunction
                    { /* else {declarations and statements} */
                        /* dump the local symbol table for then, and create a new symbol table for else */
                        dump_table();
                        new_table();
                    }
                    |
                    ;
                    
/*----------------------------------------------------------*/
/*                   LOOP DECLARATIONS                      */
/*----------------------------------------------------------*/
loopDec             : WHILE OPEN_BRACKET expression CLOSE_BRACKET
                    {/* while (exp) {declarations and statements} */
                        Trace("While declaration");
                        
                        /* create a new local symbol table */
                        new_table();
                    }
                    insideFunction
                    {
                        dump_table();
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*              VOID FUNCTION INVOCATION                    */
/*----------------------------------------------------------*/
voidFunctionInvo    : IDENTIFIER OPEN_BRACKET insideFunctionInvo CLOSE_BRACKET
                    {/* id(arguments) */
                        Trace("void function invocation with arguments inside");

                        if(lookup(*$1) == -1)
                        {
                            yyerror("Identifier not found");
                        }

                        Identifier* temp = lookup_data(*$1);

                        if(temp->isFunc == false || temp->Data_type != 4)
                        {/* function is a void type function */
                            yyerror("Identifier is not a void function type");
                        }

                        vector<int> func_arguments_data_type;

                        for(int pos = 0; pos < temp->value->func_data.size(); pos++)
                        {
                            for(const auto& name : temp->value->func_data)
                            {
                                if(pos == name.second.order)
                                {
                                    func_arguments_data_type.push_back(name.second.Data_type);
                                    break;
                                }
                            }
                        }

                        if(func_arguments_data_type.size()!=func_invo_compare.size())
                        {
                            yyerror("Different number of arguments");
                        }

                        for(int pos = 0; pos < func_invo_compare.size(); pos++)
                        {
                            if(func_arguments_data_type[pos] != func_invo_compare[pos].Data_type)
                            {
                                yyerror("void function invocation argument data type not match");
                            }
                        }

                        OF<<*$1<<"(";
                        for(int start = 0; start<func_invo_compare.size(); start++)
                        {
                            OF<<func_invo_compare[start].idName;

                            if(start<func_invo_compare.size()-1)
                            {
                                OF<<", ";
                            }
                        }
                        OF<<");\n";

                        while(func_invo_compare.size()!=0)
                        {/* empty the buffer for function and void function arguments invocation */
                            func_invo_compare.pop_back();
                        }
                    }
                    | IDENTIFIER OPEN_BRACKET CLOSE_BRACKET
                    {/* id() */
                        Trace("void function invocation");

                        if(lookup(*$1) == -1)
                        {
                            yyerror("Identifier not found");
                        }

                        Identifier* temp = lookup_data(*$1);

                        if(temp->isFunc == false || temp->Data_type != 4)
                        {
                            yyerror("Identifier is not a void function type");
                        }

                        if(temp->value->func_data.size()!=0)
                        {
                            yyerror("void function missing arguments");
                        }

                        OF<<*$1<<"();\n";
                    }
                    ;
                    
/*----------------------------------------------------------*/
/*                CONSTANT DECLARATION                      */
/*----------------------------------------------------------*/
constExp            : INTEGER_VAL
                    {/* int data */
                        Trace("constant expression declaration for integer value");

                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
	                    temp->Data_type = 0;
	                    temp->isConst = true;
	                    temp->isFunc = false;
	                    temp->value->int_data = $1;

                        OF<<"const int "<<temp->idName<<" = " << $1 << ";\n";
                        $$ = temp;
                    }

                    | REAL_VAL
                     {/* real data */
                        Trace("constant expression declaration for real value");

                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
	                    temp->Data_type = 2;
	                    temp->isConst = true;
	                    temp->isFunc = false;
	                    temp->value->real_data = $1;

                        OF<<"const double "<<temp->idName<<" = " << $1 << ";\n";

                        $$ = temp;
                    }
                    
                    | STRING_VAL
                    { /* string data */
                        Trace("constant expression declaration for string value");

                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
	                    temp->Data_type = 1;
	                    temp->isConst = true;
	                    temp->isFunc = false;
	                    temp->value->string_data = *$1;

                        OF<<"const string "<<temp->idName<<" = \"" << *$1 << "\";\n";

                        $$ = temp;
                    }

                    |   CHAR_VAL
                    { /* char data */
                        Trace("constant expression declaration for char value");

                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
	                    temp->Data_type = 5;
	                    temp->isConst = true;
	                    temp->isFunc = false;
	                    temp->value->char_data = *$1;

                        OF<<"const char "<<temp->idName<<" = \'" << *$1 << "\';\n";

                        $$ = temp;
                    }

                    | TRUE
                    { /* bool data (true) */
                        Trace("constant expression declaration for bool true value");
                        
                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
	                    temp->Data_type = 3;
	                    temp->isConst = true;
	                    temp->isFunc = false;
	                    temp->value->bool_data = true;
                        
                        OF<<"const bool "<<temp->idName<<" = true;\n";

                        /* return the value (Identifier* data type)*/
                        $$ = temp;
                    }
                    | FALSE
                    {/* bool data (false) */
                        Trace("constant expression declaration for bool false value");

                        Identifier* temp = new Identifier();
                        temp->idName = CreateName();
	                    temp->Data_type = 3;
	                    temp->isConst = true;
	                    temp->isFunc = false;
	                    temp->value->bool_data = false;

                        OF<<"const bool "<<temp->idName<<" = false;\n";

                        $$ = temp;
                    }
                    ;
%%

int main(int argc, char** argv)
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    
    /*Create global symbol table */
    new_table();

    OF.open("output.cpp");

    OF<<"#include <iostream>\n";
    OF<<"using namespace std;\n\n";


    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
    
    OF.close();
}
