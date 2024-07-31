#include<iostream>
#include<map>
#include<vector>
using namespace std;

int HelperCount = 0;
string CreateName()
{
    string ans = "ExpressionHelper";
    ans += to_string(HelperCount++);
    return ans;
}
struct Identifier;

struct Identifier_Value
{
	int int_data = 0; //0
	string string_data = ""; //1
	double real_data = 0; //2
	bool bool_data = false; //3
	//4 = void
	char char_data = '\0'; //5
	vector<Identifier> array_data; //consider array consist of many variables, but have the same Identifier
	map<string, Identifier> func_data; //Writing the arguments of the function
};

struct Identifier
{ //Initialize as void variable
	int Data_type = 4; //Int / string / double / bool / void data type
	string idName = "";
	bool isConst = false; //check whether it is a constant
	bool isFunc = false; //check whether it is a function
	bool isArray = false; //check whether it is an array
	Identifier_Value* value = new Identifier_Value(); //the value of the data
	int order = 0; //the order where the Identifier declare
};

class symbolTable
{
private:
	map<string, Identifier> symbol; //Data of Identifier_name-Identifier_Value
	int i = 0; //the number of Identifiers declared in this table
public:
	symbolTable() { i = 0; } //class construct
	int lookup(string s); //check whether an Identifier name has been declared
	Identifier* lookup_data(string s); //return the Identifier value
	int insertConst(string s, int DataType, Identifier_Value* value); //Inserting constant declaration data into the table
	int insertVar(string s, int DataType); //Inserting variable declaration data into the table
	int insertVar(string s, int DataType, Identifier_Value* value); //Inserting variable declaration data with value into the table
	int insertFunc(string s, int DataType, Identifier_Value* value); //Inserting function declaration data into the table
	int insertArray(string s, int DataType, vector<int> index); //Inserting array declaration data into the table
	int dump(); //Clear table
};

vector<symbolTable> table_list; //List of symbol tables for local and global variable declarations

void new_table() //Create a new table
{
	symbolTable temp;
	table_list.push_back(temp);
}

void dump_table() //Clear the last declared table in the list
{
	if (table_list.size() > 0) //While there is still a table
	{
		printf("\n\nDumping Symbol Table\n");
		table_list[table_list.size() - 1].dump(); //Dump the last declared table in the list
		table_list.pop_back(); //Pop back the last declared table in the list
		printf("Dumping Done\n\n");
	}
}

int insert_arguments_to_table(map<string, Identifier> map) //Inserting arguments of the function into the local symbol table
{
	vector<string> temp; //variable name
	vector<int>data; //variable data type
	for (int pos = 0; pos < map.size(); pos++) //converting the function data arguments into their respective name and data type based on their order
	{
		for (const auto& name : map) //for all data in the hash table
		{
			if (name.second.order == pos) //If the order match with the order of argument precedence
			{
				temp.push_back(name.first); //insert name
				data.push_back(name.second.Data_type); //insert data type
				break;
			}
		}
	}

	for (int pos = 0; pos < temp.size(); pos++) //inserting the variables of the arguments into the last declared symbol table 
	{
		table_list[table_list.size() - 1].insertVar(temp[pos], data[pos]); //insert the data to the local symbol table of the function
	}
	return 1; //Sign of success
}

Identifier* lookup_data(string s) //Get the data of the Identifier name mentioned
{
	bool not_found = true; //Initially set as the Identifier has not been found
	for (int pos = table_list.size() - 1; pos >= 0; pos--) //In all table, starting from the last declared symbol table
	{
		if (table_list[pos].lookup(s) != -1) //Check whether the variable name is there
		{
			return table_list[pos].lookup_data(s); //if found, return the data of the Identifier name mentioned
		}
	}

	if (not_found == true) //If not found
	{
		return NULL; //return empty data
	}
}

int lookup(string s) //Check whether the variable name is in the symbol table
{
	bool not_found = true;
	for (int pos = table_list.size() - 1; pos >= 0; pos--) //In all table, starting from the last declared symbol table
	{
		if (table_list[pos].lookup(s) != -1) //Check whether the variable name is there
		{
			return table_list[pos].lookup(s); //If found, return the order of the variable inserted
		}
	}

	if (not_found == true)
	{
		return -1; //-1 means not found
	}
}

int insertConst(string s, int DataType, Identifier_Value* value)
{
	return table_list[table_list.size() - 1].insertConst(s, DataType, value); //Inserting constant declaration into the last declared symbol table
}

int insertVar(string s, int DataType)
{
	return table_list[table_list.size() - 1].insertVar(s, DataType); //Inserting variable declaration into the last declared symbol table
}

int insertVar(string s, int DataType, Identifier_Value* value)
{
	return table_list[table_list.size() - 1].insertVar(s, DataType, value); //Inserting variable declaration with value into the last declared symbol table
}

int insertFunc(string s, int DataType, Identifier_Value* value) 
{
	return table_list[table_list.size() - 1].insertFunc(s, DataType, value); //Inserting function declaration into the last declared symbol table
}

int insertArray(string s, int DataType, vector<int> index)
{
	return table_list[table_list.size() - 1].insertArray(s, DataType, index); //Inserting array declaration into the last declared symbol table
}

int symbolTable::insertConst(string s, int DataType, Identifier_Value* value)
{
	if (symbol.find(s) != symbol.end()) //if the Identifier has been used, the return -1
	{
		return -1; //to said that the Identifier name has been used
	}
	else //if not been used insert it into the symbol table
	{
		Identifier temp; //make temporary
		temp.idName = s;
		temp.Data_type = DataType; //tell what is the datatype
		temp.isConst = true; //because this Identifier is constant, then true
		temp.isFunc = false; //because it is constant, not a function, then false
		temp.order = i; //the order of data is inserted
		temp.value = value; //the value of the constant
		symbol[s] = temp; //insert the data from temp to symbol table
		return i++; //next order
	}
}

int symbolTable::insertVar(string s, int DataType)
{
	if (symbol.find(s) != symbol.end())
	{
		return -1;
	}
	else
	{
		Identifier temp;
		temp.idName = s;
		temp.Data_type = DataType;
		temp.isConst = false; //because it is var, not constant, so false
		temp.isFunc = false;
		temp.order = i;
		symbol[s] = temp;
		return i++;
	}
}

int symbolTable::insertVar(string s, int DataType, Identifier_Value* value)
{
	if (symbol.find(s) != symbol.end())
	{
		return -1;
	}
	else
	{
		Identifier temp;
		temp.idName = s;
		temp.Data_type = DataType;
		temp.isConst = false;
		temp.isFunc = false;
		temp.order = i;
		temp.value = value;
		symbol[s] = temp;
		return i++;
	}
}


int symbolTable::insertFunc(string s, int DataType, Identifier_Value* value)
{
	if (symbol.find(s) != symbol.end())
	{
		return -1; //indentifier name has been used in this table
	}
	else
	{
		Identifier temp;
		temp.idName = s;
		temp.Data_type = DataType;
		temp.isConst = false;
		temp.isFunc = true; //It is a function
		temp.order = i;
		temp.value = value;
		symbol[s] = temp;
		return i++;
	}
}

int symbolTable::insertArray(string s, int DataType, vector<int> index)
{
	if (symbol.find(s) != symbol.end())
	{
		return -1;
	}
	else
	{
		Identifier temp;
		temp.idName = s;
		temp.Data_type = DataType;
		temp.isArray = true;
		temp.order = i;

		vector<Identifier> arrInit;

		for (int start = 0; start < index.size(); start++) //Insert the array data into the symbol table
		{
			Identifier arrTemp;
			arrTemp.Data_type = 0;
			arrTemp.order = start;
			arrTemp.value = new Identifier_Value();
			arrTemp.value->int_data = index[start];

			arrInit.push_back(arrTemp);
		}

		temp.value->array_data = arrInit;

		symbol[s] = temp;
		return i++;
	}
}

int symbolTable::lookup(string s)
{
	auto look = symbol.find(s);
	if (look != symbol.end())
	{
		return symbol[s].order;
	}
	else
	{
		return -1;
	}
}

Identifier* symbolTable::lookup_data(string s)
{
	return new Identifier(symbol[s]);
}

int symbolTable::dump()
{
	vector<string> temp;
	for (int pos = 0; pos < i; pos++)
	{
		for (const auto& name : symbol)
		{
			if (name.second.order == pos)
			{
				temp.push_back(name.first);
				break;
			}
		}
	}

	for (int pos = 0; pos < i; pos++)
	{
		printf("%d",pos);
		printf("\t");
		printf("%s",temp[pos].c_str());
		printf("\t");
		int type = symbol[temp[pos]].Data_type;
		bool function = symbol[temp[pos]].isFunc;
		bool array_check = symbol[temp[pos]].isArray;
		bool const_check = symbol[temp[pos]].isConst;

		switch(type)
		{
		case 0: printf("int"); break;
		case 1: printf("string"); break;
		case 2: printf("real"); break;
		case 3: printf("bool"); break;
		default: printf("void"); break;
		}

		printf("\t");
		if (function) //if it is a function, write the arguments needed)
		{
			printf("function\t");
			vector<string> argument; //argument name
			vector<int>data; //argument data type
			for (int pos_temp = 0; pos_temp < symbol[temp[pos]].value->func_data.size(); pos_temp++) //converting the function data arguments into their respective name and data type based on their order
			{
				for (const auto& name : symbol[temp[pos]].value->func_data) //for all data in the hash table
				{
					if (name.second.order == pos_temp) //If the order match with the order of argument precedence
					{
						argument.push_back(name.first); //insert name
						data.push_back(name.second.Data_type); //insert data type
						break;
					}
				}
			}
			printf("(");
			for (int pos_temp = 0; pos_temp < argument.size(); pos_temp++) //Write the arguments name and data type needed based on their precedence
			{
				printf("%s",argument[pos_temp].c_str());
				printf(": ");
				switch (data[pos_temp])
				{
				case 0: printf("int"); break;
				case 1: printf("string"); break;
				case 2: printf("real"); break;
				case 3: printf("bool"); break;
				default: printf("void"); break;
				}
				if (argument.size() - pos_temp > 1)
				{
					printf(", ");
				}
			}
			printf(")");
		}
		else if(array_check) //If array, write the size of each dimension
		{
			printf("array\ts[");
			for(int start = 0; start<symbol[temp[pos]].value->array_data.size(); start++)
			{
				printf("%d", symbol[temp[pos]].value->array_data[start].value->int_data);
				if(start<symbol[temp[pos]].value->array_data.size()-1)
				{
					printf("][");
				}
			}
			printf("]");

		}
		else if (const_check)
		{
			printf("constant");
		}
		else
		{
			printf("variable");
		}
		printf("\n");
	}
}
