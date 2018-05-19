open Core
open Ast

let slcmd c a =
  "\t" ^ c ^ "\t" ^ a ^ "\n" |> print_string

let bicmd c a b =
  "\t" ^ c ^ "\t" ^ a ^ ", " ^ b ^ "\n" |> print_string

let global_fun f =
  "\t.global " ^ f ^ "\n" |> print_string

let start_fun f =
  f ^ ":\n" |> print_string

let movl s d = bicmd "movl" s d

let push = slcmd "push"

let pop = slcmd "pop"

let sete = slcmd "sete"

let cmpl = bicmd "cmpl"

let addl = bicmd "addl"

let subl = bicmd "subl"

let imul = bicmd "imul"

let idivl = slcmd "idivl"

let xor = bicmd "xor"

let neg = slcmd "neg"

let nnot = slcmd "nnot"

let ret () = "\tret\n" |> print_string

let gen_const c =
  match c with
  | Int i -> movl ("$"^ string_of_int i) "%eax"
  | Char c -> movl ("$"^ string_of_int (Char.to_int c)) "%eax"
  | String s -> print_string s

let gen_unop uop =
  match uop with
  | Negate -> neg "%eax"
  | Pos -> ()
  | Complement -> nnot "%eax"
  | Not ->
    cmpl "$0" "%eax";
    movl "$0" "%eax";
    sete "%al"

let gen_binop bop =
  match bop with
  | Add -> addl "%ecx" "%eax"
  | Sub -> subl "%ecx" "%eax"
  | Mult -> imul "%ecx" "%eax"
  | Div -> xor "%edx" "%edx"; idivl "%ecx"
  | Mod -> xor "%edx" "%edx"; idivl "%ecx"; movl "%edx" "%eax"
  | Xor -> xor "%ecx" "%eax"
  | _ -> ()

let rec gen_exp e =
  match e with
  | Const c -> gen_const c
  | UnOp (uop, e) -> gen_exp e; gen_unop uop
  | BinOp (bop, e1, e2) ->
    gen_exp e1;
    push "%eax";
    gen_exp e2;
    movl "%eax" "%ecx";
    pop "%eax";
    gen_binop bop

let gen_statement s =
  match s with
  | ReturnVal e ->
    gen_exp e; ret ()

let gen_fun f =
  match f with
  | Fun (id, bdy) ->
    global_fun id;
    start_fun id;
    gen_statement bdy

let rec gen_prog p =
  match p with
  | Prog [] -> ();
  | Prog (f :: fs) ->
    gen_fun f;
    print_newline ();
    gen_prog (Prog fs)
