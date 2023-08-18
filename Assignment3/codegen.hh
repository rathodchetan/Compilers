#ifndef CODEGEN_HH
#define CODEGEN_HH

#include <iostream>
#include <vector>
#include <string>

class funcCode{
    public:
    string iden;
    vector<string> instr;
};

class globalVar{
    public:
    vector<string> instr;
};

class code{
    public:
    vector<string> globals;
    vector<funcCode> funcInstr;

    void printStart(){
        cout<<"\t.text\n";
        cout<<"\t.section\t.rodata\n";
    }

    void printGlobals(){
        for (int i=0;i<globals.size();i++){
            cout<<".LC"<<i<<":\n\t.string "<<globals[i]<<"\n";
        }
    }

    void printFuncCode(){
    //     .text
	// .globl	f
	// .type	f, @function
        for(int i=0;i<funcInstr.size();i++){
            cout<<"\t.text\n";
            cout<<"\t.globl "<<funcInstr[i].iden<<"\n";
            cout<<"\t.type "<<funcInstr[i].iden<<", @function\n";
            cout<<funcInstr[i].iden<<":\n";
            for (int j=0;j<funcInstr[i].instr.size();j++){
                cout<<funcInstr[i].instr[j];
            }
        }


    }
};

#endif

