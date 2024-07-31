#pragma once

#include<iostream>
#include<map>
#include<vector>
using namespace std;

class symbolTable
{
private:
	map<string, int> symbol;
	int i = 0;
public:
	symbolTable() { i = 0; }
	int lookup(string s);
	int insert(string s);
	int dump();
};

int symbolTable::lookup(string s)
{
	auto look = symbol.find(s);
	if (look != symbol.end())
	{
		return symbol[s];
	}
	else
	{
		return -1;
	}
}

int symbolTable::insert(string s)
{
	int look = lookup(s);
	if (look != -1)
	{
		return look;
	}
	else
	{
		symbol[s] = i;
		i++;
	}
 
  return i;
}

int symbolTable::dump()
{
	vector<string> temp;
	for (int pos = 0; pos < i; pos++)
	{
		for (const auto& name : symbol)
		{
			if (name.second == pos)
			{
				temp.push_back(name.first);
				break;
			}
		}
	}

	for (int pos = 0; pos < i; pos++)
	{
		cout << pos << " " << temp[pos] << "\n";
	}
 
  return i;
}