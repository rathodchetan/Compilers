#ifndef AST_HH
#define AST_HH

#include <iostream>
#include <vector>
using namespace std;

// enum typeExp{

//     INT,
//     FLOAT,
//     VOID,
//     STRUCT,
//     STRING_LITERAL
// };

class abstract_astnode
{
    public:
    virtual void print(int blank) = 0;
    // typeExp astnode_type;
};

class statement_astnode : public abstract_astnode
{
    public:
    virtual void print(int blank) = 0;
};

class exp_astnode : public abstract_astnode
{
    public:
    virtual void print(int blank) = 0;
    virtual exp_astnode* getChild1(){return this;};
    virtual exp_astnode* getChild2(){return this;};
    string typeExp;
};

class ref_astnode : public exp_astnode
{
    public:
    virtual void print(int blank) = 0;
};

class empty_astnode : public statement_astnode
{
    public:
    int empty = 1;
    void print(int blank);
};

class seq_astnode : public statement_astnode
{
    protected:
        vector<statement_astnode*> child1;
    public:
    seq_astnode(vector<statement_astnode*> c1);
    seq_astnode(){};
    void print(int blank);
}; 

class assignS_astnode : public statement_astnode
{
    protected:
        exp_astnode *child1;
        exp_astnode *child2;
    public:
    assignS_astnode(exp_astnode *c1,exp_astnode *c2);
    void print(int blank);
}; 

class return_expnode : public statement_astnode
{
    protected:
        exp_astnode *child1;
    public:
    return_expnode(exp_astnode *c1);
    void print(int blank);
};

class proccall_astnode : public statement_astnode
{
    protected:
        ref_astnode* child1;
        vector<exp_astnode*> child2;
    public:
    proccall_astnode(ref_astnode* c1,vector<exp_astnode*>c2);
    proccall_astnode(ref_astnode* c1);
    void print(int blank);
};

class if_astnode : public statement_astnode
{
    protected:
        exp_astnode *child1;
        statement_astnode *child2;
        statement_astnode *child3;
    public:
    if_astnode(exp_astnode *c1, statement_astnode *c2, statement_astnode *c3);
    void print(int blank);
};

class while_astnode : public statement_astnode
{
    protected:
        exp_astnode *child1;
        statement_astnode *child2;
    public:
    while_astnode(exp_astnode *c1, statement_astnode *c2);
    void print(int blank);
};

class for_astnode : public statement_astnode
{
    protected:
        exp_astnode *child1;
        exp_astnode *child2;
        exp_astnode *child3;
        statement_astnode *child4;

    public:
    for_astnode(exp_astnode *c1,exp_astnode *c2,exp_astnode *c3,statement_astnode *c4);
    void print(int blank);
};

class op_binary_astnode : public exp_astnode
{
    protected:
        string child1;
        exp_astnode *child2;
        exp_astnode *child3;
    public:
        op_binary_astnode(string c1,exp_astnode *c2,exp_astnode *c3,string typeVal);
        void print(int blank);
};

class op_unary_astnode : public exp_astnode
{
    protected:
        string child1;
        exp_astnode *child2;
    public:
        op_unary_astnode(string c1,exp_astnode *c2,string typeVal);
        void print(int blank);
};

class assignE_exp : public exp_astnode
{
    protected:
        exp_astnode *child1;
        exp_astnode *child2;
    public:
        assignE_exp(exp_astnode *c1,exp_astnode *c2,string typeVal);
        void print(int blank);
        exp_astnode* getChild1();
        exp_astnode* getChild2();
};

class funcall_astnode : public exp_astnode
{
    protected:
        ref_astnode* child1;
        vector<exp_astnode*> child2;
    public:
        funcall_astnode(ref_astnode *c1,vector<exp_astnode*> c2,string typeVal);
        funcall_astnode(ref_astnode *c1,string typeVal);
        void print(int blank);
};

class floatconst_astnode : public exp_astnode
{
    protected:
        float child1;
    public:
        floatconst_astnode(float c1);
        void print(int blank);
};

class intconst_astnode : public exp_astnode
{
    protected:
        int child1;
        
    public:
        intconst_astnode(int c1);
        void print(int blank);
};

class string_astnode : public exp_astnode
{
    protected:
        string child1;
    public:
        string_astnode(string c1);
        void print(int blank);
};

class pointer_astnode : public exp_astnode
{
    protected:
        exp_astnode *child1;
        
    public:
        pointer_astnode(exp_astnode *c1);
        void print(int blank);
};

class identifier_astnode : public ref_astnode
{
    protected:
        string child1;
    public:
        identifier_astnode(string c1,string typeVal);
        void print(int blank);
        string getChild();
};

class member_astnode : public ref_astnode
{
    protected:
        exp_astnode *child1;
        identifier_astnode *child2;
    public:
        member_astnode(exp_astnode *c1,identifier_astnode *c2,string typeVal);
        void print(int blank);
};

class arrow_astnode : public ref_astnode
{
    protected:
        exp_astnode *child1;
        identifier_astnode *child2;
    public:
        arrow_astnode(exp_astnode *c1,identifier_astnode *c2,string typeVal);
        void print(int blank);
};

class arrayref_astnode : public ref_astnode
{
    protected:
        exp_astnode *child1;
        exp_astnode *child2;
    public:
        arrayref_astnode(exp_astnode *c1,exp_astnode *c2,string typeVal);
        void print(int blank);
};


// extra classes created

// class for storing unary_operator 

class unary_operator_ast
{
    
    public:
    string child1;
    string typeExp;
    unary_operator_ast(string c1){
        this->child1 = c1;
        this->typeExp = c1;
    }
    void print(int blank){return;}
};

#endif
