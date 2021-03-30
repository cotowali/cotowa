module ast

import cotowari.pos { Pos }
import cotowari.token { Token }
import cotowari.symbols { Scope, Var }
import cotowari.errors

pub struct File {
pub:
	path string
pub mut:
	stmts  []Stmt
	scope  &Scope
	errors []errors.Error
}

pub type Stmt = AssignStmt | Block | EmptyStmt | Expr | FnDecl | IfStmt

pub struct EmptyStmt {}

pub struct Block {
pub:
	scope &Scope
pub mut:
	stmts []Stmt
}

pub struct FnDecl {
pub:
	pos  Pos
	name string
pub mut:
	params []Var
	body   Block
}

pub struct AssignStmt {
pub:
	pos   Pos
	left  Var
	right Expr
}

pub struct IfBranch {
pub:
	cond Expr
	body Block
}

pub struct IfStmt {
pub:
	pos      Pos
	branches []IfBranch
	has_else bool
}

pub struct InfixExpr {
pub:
	pos   Pos
	op    Token
	left  Expr
	right Expr
}

// expr | expr | expr
pub struct Pipeline {
pub:
	pos   Pos
	exprs []Expr
}

pub type Expr = CallFn | InfixExpr | IntLiteral | Pipeline | Var

pub struct CallFn {
pub:
	pos Pos
pub mut:
	func Var
	args []Expr
}

pub struct IntLiteral {
pub:
	pos   Pos
	token Token
}
