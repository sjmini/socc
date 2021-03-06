%{
  open Core
  open Ast
%}

%token <int> INT
%token <char> CHAR
%token <string> ID
%token BRACE_OPEN BRACE_CLOSE PAREN_OPEN PAREN_CLOSE BRACKET_OPEN BRACKET_CLOSE
%token COMMA QUESTION SEMICOLON COLON
%token VOID_KW INT_KW CHAR_KW LONG_KW UNSIGNED_KW FLOAT_KW DOUBLE_KW
%token STRUCT_KW CONST_KW STATIC_KW SIZEOF_KW RETURN_KW GOTO_KW
%token IF_KW ELSE_KW SWITCH_KW FOR_KW DO_KW WHILE_KW BREAK_KW CONTINUE_KW
%token BANG COMPLEMENT
%token PLUS MINUS NEG_MINUS MULT DIV MOD
%token PLUS_EQ MINUS_EQ MULT_EQ DIV_EQ MOD_EQ
%token BIT_AND_EQ BIT_OR_EQ XOR_EQ SHIFT_LEFT_EQ SHIFT_RIGHT_EQ
%token EQ DOUBLE_EQ NEQ LT LE GT GE AND OR
%token BIT_AND BIT_OR XOR SHIFT_LEFT SHIFT_RIGHT
%token ARROW ADDROF DEREF
%token EOF

%left COMMA
%right EQ PLUS_EQ MINUS_EQ MULT_EQ DIV_EQ MOD_EQ BIT_AND_EQ BIT_OR_EQ XOR_EQ SHIFT_LEFT_EQ SHIFT_RIGHT_EQ
%right QUESTION COLON
%left OR
%left AND
%left BIT_OR
%left XOR
%left BIT_AND
%left DOUBLE_EQ NEQ
%left LE LT GE GT
%left SHIFT_LEFT SHIFT_RIGHT
%left PLUS MINUS
%left MULT DIV MOD
%nonassoc NEG_MINUS ADDROF DEREF

%type <Ast.prog> program
%type <fun_decl> fun_decl
%type <exp> exp

%start program

%%

type_def:
  | VOID_KW { VoidType }
  | INT_KW { IntType }
  | CHAR_KW { CharType }
  | FLOAT_KW { FloatType }
  | DOUBLE_KW { DoubleType }
  | t = type_def MULT
    { PointerType t }

program:
  | f = fun_decl p = program
    { let Prog fs = p in Prog (f :: fs) }
  | EOF { Prog [] }
;

fun_decl:
  ftype = type_def id = ID
  PAREN_OPEN params = params PAREN_CLOSE
  body = block
  { { name = id;
      fun_type = ftype;
      params;
      body; } }
;

params:
  | { [] }
  | t = type_def id = option(ID)
    { [(id, t)] }
  | t = type_def id = option(ID) COMMA ps = params
    { (id, t) :: ps }

args:
  | { [] }
  | e = exp { [e] }
  | e = exp COMMA es = args
    { e :: es }

block:
  | BRACE_OPEN sts = statements BRACE_CLOSE
    { sts }

statements:
  | { [] }
  | s = statement ss = statements
    { s :: ss }
;

statement:
  | de = decl_exp SEMICOLON
    { Decl de }
  | RETURN_KW e = exp SEMICOLON
    { ReturnVal e }
  | e = exp SEMICOLON
    { Exp e }
  | IF_KW PAREN_OPEN cond = exp PAREN_CLOSE
    tstat = statement fstat = if_fstat
    { If { cond; tstat; fstat; } }
  | FOR_KW PAREN_OPEN init = exp SEMICOLON
    cond = exp SEMICOLON post = exp PAREN_CLOSE
    body = statement
    { For { init; cond; post; body; } }
  | FOR_KW PAREN_OPEN init = decl_exp SEMICOLON
    cond = exp SEMICOLON post = exp PAREN_CLOSE
    body = statement
    { ForDecl { init; cond; post; body; } }
  | WHILE_KW PAREN_OPEN cond = exp PAREN_CLOSE
    body = statement
    { While (cond, body) }
  | DO_KW body = statement WHILE_KW
    PAREN_OPEN cond = exp PAREN_CLOSE SEMICOLON
    { Do (cond, body) }
  | BREAK_KW SEMICOLON
    { Break }
  | CONTINUE_KW SEMICOLON
    { Continue }
  | l = ID COLON
    { Label l }
  | GOTO_KW l = ID SEMICOLON
    { Goto l }
  | SEMICOLON
    { Nop }
  | b = block
    { Compound b }
;

decl_exp:
  var_type = type_def id = ID e = decl_exp_init
  { { var_type; name = id; init = e } }

decl_exp_init:
  | { None }
  | EQ e = exp { Some e }

if_fstat:
  | { None }
  | ELSE_KW fstat = statement { Some fstat }

exp:
  | i = INT
    { Const (Int i) }
  | PAREN_OPEN e = exp PAREN_CLOSE
    { e }
  | e1 = exp op = binop e2 = exp
    { BinOp (op, e1, e2) }
  | COMPLEMENT e = exp
    { UnOp (Complement, e) }
  | BANG e = exp
    { UnOp (Not, e) }
  | MINUS e = exp %prec NEG_MINUS
    { UnOp (Negate, e) }
  | MULT e = exp %prec DEREF
    { Dereference e }
  | BIT_AND e = exp %prec ADDROF
    { AddressOf e }
  | lexp = exp aop = assign_op rexp = exp
    { Assign (aop, lexp, rexp) }
  | id = ID
    { Var id }
  | cond = exp QUESTION texp = exp COLON fexp = exp
    { Condition (cond, texp, fexp) }
  | id = ID PAREN_OPEN args = args PAREN_CLOSE
    { Call (id, args) }
  | SIZEOF_KW PAREN_OPEN t = type_def PAREN_CLOSE
    { SizeofType t }
  | SIZEOF_KW PAREN_OPEN e = exp PAREN_CLOSE
    { SizeofExp e }
;

%inline binop:
  | PLUS { Add }
  | MINUS { Sub }
  | MULT { Mult }
  | DIV { Div }
  | MOD { Mod }
  | LT { Lt }
  | LE { Le }
  | GT { Gt }
  | GE { Ge }
  | DOUBLE_EQ { Eq }
  | NEQ { Neq }
  | AND { And }
  | OR { Or }
  | BIT_AND { BitAnd }
  | BIT_OR { BitOr }
  | XOR { Xor }
  | SHIFT_LEFT { ShiftL }
  | SHIFT_RIGHT { ShiftR }
;

%inline assign_op:
  | EQ { AssignEq }
  | PLUS_EQ { AddEq }
  | MINUS_EQ { SubEq }
  | MULT_EQ { MultEq }
  | DIV_EQ { DivEq }
  | MOD_EQ { ModEq }
  | BIT_AND_EQ { BitAndEq }
  | BIT_OR_EQ { BitOrEq }
  | XOR_EQ { XorEq }
  | SHIFT_LEFT_EQ { ShiftLEq }
  | SHIFT_RIGHT_EQ { ShiftREq }
%%
