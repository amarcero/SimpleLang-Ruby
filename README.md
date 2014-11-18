simple-lang
===========

A simple language interpreter written in Ruby.

grammar used:

Parse  ::= Stmnt Semicolon Parse | e
Stmnt  ::= ID = Expr | Expr
Expr   ::= Term Expr'
Expr'  ::= Addop Term Expr' | e
Term   ::= Factor Term'
Term'  ::= Multop Factor Term' | e
Factor ::= Num | ID | (Expr) | -Expr
Multop ::= * | /
Addop  ::= + | -
