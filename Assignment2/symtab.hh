#ifndef SYMTAB_HH
#define SYMTAB_HH

#include<iostream>
#include <vector>
#include <string>
#include <map>
#include <algorithm>

class Entryl{
	public:
	string varfun;
	int offset;
	int size;
	string type;
	string scope;
	string iden;
};

class LSymbtab{
	public:
	string iden;
	vector<Entryl*> Entries;
	void print(){
		sort(Entries.begin(),Entries.end(),
			[](auto a,auto b) -> bool {
				return a->iden < b->iden;
			}
		);
		cout<<"[";
		for(int i=0;i<Entries.size();i++){
			cout<<"[\""<<Entries[i]->iden<<"\",";
			cout<<"\""<<Entries[i]->varfun<<"\",";
			cout<<"\""<<Entries[i]->scope<<"\",";
			cout<<Entries[i]->size<<",";
			cout<<Entries[i]->offset<<",";
			cout<<"\""<<Entries[i]->type<<"\"]";
			if(i==Entries.size()-1)	break;
			cout<<",";
		}
		cout<<"]";
	};
};

class Entryg{
	public:
	LSymbtab* symbtab;
	string varfun;
	int offset;
	int size;
	string type;
	string scope;
	string iden;
};

class SymbTab{
	public:
	map<string,Entryg*> Entries;
	void printgst(){
		cout<<"[";
		int k = Entries.size();
		int count=0;
		for(auto i:Entries){
			cout<<"[\""<<i.first<<"\",";
			cout<<"\""<<i.second->varfun<<"\",";
			cout<<"\""<<i.second->scope<<"\",";
			cout<<i.second->size<<",";
			if(i.second->varfun=="struct"){
				cout<<"\"-\",";
			}
			else{
				cout<<i.second->offset<<",";
			}
			cout<<"\""<<i.second->type<<"\"]";
			count++;
			if(count!=k)	cout<<",";
		}
		cout<<"]";
	};
};


#endif