// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast
import cotowali.symbols { builtin_type }

fn (mut c Checker) stmts(stmts []ast.Stmt) {
	for stmt in stmts {
		c.stmt(stmt)
	}
}

fn (mut c Checker) stmt(stmt ast.Stmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	match mut stmt {
		ast.AssignStmt { c.assign_stmt(mut stmt) }
		ast.AssertStmt { c.assert_stmt(stmt) }
		ast.Block { c.block(stmt) }
		ast.Expr { c.expr(stmt) }
		ast.EmptyStmt {}
		ast.FnDecl { c.fn_decl(stmt) }
		ast.ForInStmt { c.for_in_stmt(mut stmt) }
		ast.IfStmt { c.if_stmt(stmt) }
		ast.InlineShell {}
		ast.ReturnStmt { c.return_stmt(stmt) }
		ast.RequireStmt { c.require_stmt(mut stmt) }
		ast.WhileStmt { c.while_stmt(stmt) }
		ast.YieldStmt { c.yield_stmt(stmt) }
	}
}

fn (mut c Checker) assign_stmt(mut stmt ast.AssignStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(stmt.right)

	// 1. if is_decl, left type is set to right type
	// 2. if left type is placeholder, left is undefined variable.
	//    So error has been reported by resolver.
	if !stmt.is_decl && stmt.left.typ() != builtin_type(.placeholder) {
		c.check_types(
			want: stmt.left.type_symbol()
			got: stmt.right.type_symbol()
			pos: stmt.right.pos()
		) or {}
	}
}

fn (mut c Checker) assert_stmt(stmt ast.AssertStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(stmt.expr)
	c.expect_bool_expr(stmt.expr, 'assert condition') or {}
}

fn (mut c Checker) block(block ast.Block) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.stmts(block.stmts)
}

fn (mut c Checker) fn_decl(stmt ast.FnDecl) {
	$if trace_checker ? {
		c.trace_begin(@FN, stmt.name, stmt.signature())
		defer {
			c.trace_end()
		}
	}

	old_fn := c.current_fn
	c.current_fn = stmt
	defer {
		c.current_fn = old_fn
	}

	c.exprs(stmt.params.map(ast.Expr(it)))
	c.block(stmt.body)
}

fn (mut c Checker) for_in_stmt(mut stmt ast.ForInStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(stmt.expr)
	ts := stmt.expr.type_symbol()
	if ts.kind() != .array {
		c.error('non-array type `$ts.name` is not iterable', stmt.expr.pos())
	}
	c.block(stmt.body)
}

fn (mut c Checker) if_stmt(stmt ast.IfStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	for i, branch in stmt.branches {
		if i == stmt.branches.len - 1 && stmt.has_else {
			c.block(branch.body)
			break
		}
		c.expr(branch.cond)
		c.expect_bool_expr(branch.cond, 'if condition') or {}
		c.block(branch.body)
	}
}

fn (mut c Checker) return_stmt(stmt ast.ReturnStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(stmt.expr)
	c.check_types(
		want: c.current_fn.ret_type_symbol()
		got: stmt.expr.type_symbol()
		pos: stmt.expr.pos()
	) or {}
}

fn (mut c Checker) require_stmt(mut stmt ast.RequireStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.check_file(mut stmt.file)
}

fn (mut c Checker) while_stmt(stmt ast.WhileStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(stmt.cond)
	c.expect_bool_expr(stmt.cond, 'while condition') or {}
	c.block(stmt.body)
}

fn (mut c Checker) yield_stmt(stmt ast.YieldStmt) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(stmt.expr)

	mut want_typ := builtin_type(.placeholder)
	if array_info := c.current_fn.ret_type_symbol().array_info() {
		if array_info.variadic {
			want_typ = array_info.elem
		}
	}

	if want_typ == builtin_type(.placeholder) {
		c.error('cannot use yield in function that return non-sequence type', stmt.pos)
		return
	}

	c.check_types(
		want: c.current_fn.body.scope.must_lookup_type(want_typ)
		got: stmt.expr.type_symbol()
		pos: stmt.expr.pos()
	) or {}
}
