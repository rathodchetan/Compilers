#include "ast.hh"
#include <iostream>
#include <vector>
#include <string>
using namespace std;


seq_astnode::seq_astnode(vector<statement_astnode*> c1){
        this->child1 = c1;
}
void seq_astnode::print(int blank){
    cout<<"{\"seq\": [\n";
    for(int i=0;i<child1.size();i++){
        
        cout<<"\n";
        child1[i]->print(0);
        if(i==child1.size()-1)
            cout<<"\n";
        else
            cout<<"\n,\n";
    }
    cout<<"]\n}\n";
}

assignS_astnode::assignS_astnode(exp_astnode *c1,exp_astnode *c2){
    this->child1 = c1;
    this->child2 = c2;
    
}

void assignS_astnode::print(int blank){
    cout<<"{\"assignS\": {\n";

    cout<<"\"left\":\n";
    child1->print(0);
    cout<<",\n";

    cout<<"\"right\":\n";
    child2->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

return_expnode::return_expnode(exp_astnode *c1){
    this->child1 = c1;
}

void return_expnode::print(int blank){
    cout<<"{\"return\":\n";
    child1->print(0);
    cout<<"}\n";
}

proccall_astnode::proccall_astnode(ref_astnode* c1,vector<exp_astnode*>c2){
    this->child1 = c1;
    this->child2 = c2;
}

proccall_astnode::proccall_astnode(ref_astnode* c1){
    this->child1 = c1;
}

void proccall_astnode::print(int blank){
    cout<<"{\"proccall\": {\n";

    cout<<"\"fname\": \n"; 
    child1->print(0);
    cout<<",\n";

    
    cout<<"\"params\": [\n"; 
    for(int i=0;i<child2.size();i++){
        cout<<"\n";
        child2[i]->print(0);
        if(i==child2.size()-1)
            cout<<"\n";
        else
        cout<<",\n";
    }
    cout<<"]\n";
    
    cout<<"}\n}\n";
}

if_astnode::if_astnode(exp_astnode *c1, statement_astnode *c2, statement_astnode *c3){
    this->child1 = c1;
    this->child2 = c2;
    this->child3 = c3;
}

void if_astnode::print(int blank){
    cout<<"{\"if\": {\n";
    cout<<"\"cond\":\n";
    child1->print(0);

    cout<<",\n";
    cout<<"\"then\":\n";
    child2->print(0);
    cout<<",\n";

    cout<<"\"else\":\n";
    child3->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

while_astnode::while_astnode(exp_astnode *c1, statement_astnode *c2){
    this->child1 = c1;
    this->child2 = c2;
}

void while_astnode::print(int blank){
    cout<<"{\"while\": {\n";

    cout<<"\"cond\":\n";
    child1->print(0);
    cout<<",\n";
    cout<<"\"stmt\":\n";
    child2->print(0);

    cout<<"\n";

    cout<<"}\n}\n";
}

for_astnode::for_astnode(exp_astnode *c1,exp_astnode *c2,exp_astnode *c3,statement_astnode *c4){
    this->child1 = c1;
    this->child2 = c2;
    this->child3 = c3;
    this->child4 = c4;
}

void for_astnode::print(int blank){
    cout<<"{\"for\": {\n";
    cout<<"\"init\": \n";
    child1->print(0);
    cout<<",\n";
    cout<<"\"guard\": \n";
    child2->print(0);
    cout<<",\n";
    cout<<"\"step\": \n";
    child3->print(0);
    cout<<",\n";
    cout<<"\"body\": \n";
    child4->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

op_binary_astnode::op_binary_astnode(string c1,exp_astnode *c2,exp_astnode *c3,string typeVal){
    this->child1 = c1;
    this->child2 = c2;
    this->child3 = c3;
    this->typeExp = typeVal;
}

void op_binary_astnode::print(int blank){
    cout<<"{\"op_binary\": {\n";
    cout<<"\"op\": \"" << child1<<"\",\n";
    cout<<"\"left\": \n";
    child2->print(0);
    cout<<",\n";

    cout<<"\"right\": \n";
    child3->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

op_unary_astnode::op_unary_astnode(string c1,exp_astnode *c2,string typeVal){
    this->child1 = c1;
    this->child2 = c2;
    this->typeExp = typeVal;
}

void op_unary_astnode::print(int blank){
    cout<<"{\"op_unary\": {\n";
    cout<<"\"op\": \"" << child1<<"\",\n";
    cout<<"\"child\": \n";
    child2->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

assignE_exp::assignE_exp(exp_astnode *c1,exp_astnode *c2,string typeVal){
    this->child1 = c1;
    this->child2 = c2;
    this->typeExp = typeVal;
}

void assignE_exp::print(int blank){
    cout<<"{\"assignE\": {\n";

    cout<<"\"left\": \n";
    child1->print(0);
    cout<<",\n";

    cout<<"\"right\": ";
    child2->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

exp_astnode* assignE_exp::getChild1(){
    return this->child1;
}

exp_astnode* assignE_exp::getChild2(){
    return this->child2;
}

funcall_astnode::funcall_astnode(ref_astnode *c1,vector<exp_astnode*> c2,string typeVal){
    this->child1 = c1;
    this->child2 = c2;
    this->typeExp = typeVal;
}

funcall_astnode::funcall_astnode(ref_astnode *c1,string typeVal){
    this->child1 = c1;
    this->typeExp = typeVal;
}

void funcall_astnode::print(int blank){
    cout<<"{\"funcall\": {\n";

    cout<<"\"fname\": \n"; 
    child1->print(0);
    cout<<",\n";

    
    cout<<"\"params\": [\n"; 
    for(int i=0;i<child2.size();i++){
        cout<<"\n";
        child2[i]->print(0);
        if(i==child2.size()-1)
            cout<<"\n";
        else
        cout<<",\n";
    }
    cout<<"]\n";
    
    cout<<"}\n}\n";
}

floatconst_astnode::floatconst_astnode(float c1){
    this->child1 = c1;
    this->typeExp = "float";
}

void floatconst_astnode::print(int blank){
    cout<<"{\"floatconst\": " << child1 <<"\n}";
}

intconst_astnode::intconst_astnode(int c1){
    this->child1 = c1;
    this->typeExp = "int";
}

void intconst_astnode::print(int blank){
    cout<<"{\"intconst\": " << child1 <<"\n}";
   
}

string_astnode::string_astnode(string c1){
    this->child1 = c1;
    this->typeExp = "string";
}

void string_astnode::print(int blank){
    cout<<"{\"stringconst\": " << child1 <<"\n}";
}

pointer_astnode::pointer_astnode(exp_astnode *c1){
    this->child1 = c1;
}

void pointer_astnode::print(int blank){
    cout<<"{\"pointer\": {\n";

    cout<<"\"child\": \n";
    child1->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

identifier_astnode::identifier_astnode(string c1,string typeVal){
    this->child1 = c1;
    this->typeExp = typeVal;
}

void identifier_astnode::print(int blank){
    cout<<"{\"identifier\": \"" << child1 <<"\"\n}";
    // cout<<typeExp<<"---------\n";
}

string identifier_astnode::getChild(){
    return this->child1;
}

member_astnode::member_astnode(exp_astnode *c1,identifier_astnode *c2,string typeVal){
    this->child1 = c1;
    this->child2 = c2;
    this->typeExp = typeVal;
}

void member_astnode::print(int blank){
    cout<<"{\"member\": {\n";

    cout<<"\"struct\": \n";
    child1->print(0);
    cout<<",\n";

    cout<<"\"field\": \n";
    child2->print(0);
    cout<<"\n";

    cout<<"}\n}\n";

}

arrow_astnode::arrow_astnode(exp_astnode *c1,identifier_astnode *c2,string typeVal){
    this->child1=c1;
    this->child2=c2;
    this->typeExp = typeVal;
}

void arrow_astnode::print(int blank){
    cout<<"{\"arrow\": {\n";

    cout<<"\"pointer\": \n";
    child1->print(0);
    cout<<",\n";

    cout<<"\"field\": \n";
    child2->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

arrayref_astnode::arrayref_astnode(exp_astnode *c1,exp_astnode *c2,string typeVal){
    this->child1 = c1;
    this->child2 = c2;
    this->typeExp = typeVal;
}

void arrayref_astnode::print(int blank){
    cout<<"{\"arrayref\": {\n";

    cout<<"\"array\": \n";
    child1->print(0);
    cout<<",\n";

    cout<<"\"index\": ";
    child2->print(0);
    cout<<"\n";

    cout<<"}\n}\n";
}

void empty_astnode::print(int blank){
    cout << "\"empty\"";
};