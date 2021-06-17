module sh

import cotowari.ast
import cotowari.token { Token }
import cotowari.symbols { builtin_type }
import cotowari.util { panic_and_value }
import cotowari.errors { unreachable }

struct ExprOpt {
	as_command        bool
	expand_array      bool
	writeln           bool
	discard_stdout    bool
	inside_arithmetic bool
}

struct ExprWithOpt {
	expr ast.Expr [required]
	opt  ExprOpt  [required]
}

fn (mut e Emitter) expr(expr ast.Expr, opt ExprOpt) {
	match expr {
		ast.AsExpr { e.expr(expr.expr, opt) }
		ast.CallExpr { e.call_expr(expr, opt) }
		ast.ParenExpr { e.paren_expr(expr, opt) }
		ast.Pipeline { e.pipeline(expr, opt) }
		ast.InfixExpr { e.infix_expr(expr, opt) }
		ast.IndexExpr { panic('uninmplemented') }
		ast.PrefixExpr { e.prefix_expr(expr, opt) }
		ast.IntLiteral { e.write_echo_if_command_then_write(expr.token.text, opt) }
		ast.ArrayLiteral { e.array_literal(expr, opt) }
		ast.StringLiteral { e.write_echo_if_command_then_write("'$expr.token.text'", opt) }
		ast.Var { e.var_(expr, opt) }
	}
	if opt.as_command && opt.discard_stdout {
		e.write(' > /dev/null')
	}
	if opt.writeln {
		e.writeln('')
	}
}

fn (mut e Emitter) write_echo_if_command(opt ExprOpt) {
	if opt.as_command {
		e.write('echo ')
	}
}

fn (mut e Emitter) write_echo_if_command_then_write(s string, opt ExprOpt) {
	e.write_echo_if_command(opt)
	e.write(s)
}

fn (mut e Emitter) var_(v ast.Var, opt ExprOpt) {
	ident := e.ident_for(v)
	match v.type_symbol().kind() {
		.array {
			e.array(ident, opt)
		}
		else {
			// '$(( n == 0 ))' or 'echo "$n"'
			s := if opt.inside_arithmetic { '$ident' } else { '"\$$ident"' }
			e.write_echo_if_command_then_write(s, opt)
		}
	}
}

fn (mut e Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.infix_op) {
		panic(unreachable)
	}

	match expr.left.typ() {
		builtin_type(.int) { e.infix_expr_for_int(expr, opt) }
		builtin_type(.string) { e.infix_expr_for_string(expr, opt) }
		else { panic('infix_expr for `$expr.left.type_symbol().name` is unimplemented') }
	}
}

fn (mut e Emitter) infix_expr_for_int(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() != builtin_type(.int) {
		panic(unreachable)
	}
	e.write_echo_if_command(opt)

	if expr.op.kind.@is(.comparsion_op) {
		op_flag := match expr.op.kind {
			.op_eq { '-eq' }
			.op_ne { '-ne' }
			.op_gt { '-gt' }
			.op_ge { '-ge' }
			.op_lt { '-lt' }
			.op_le { '-le' }
			else { panic_and_value(unreachable, '') }
		}
		e.write('[ ')
		e.expr(expr.left, {})
		e.write(' $op_flag ')
		e.expr(expr.right, {})
		e.write(' ]')
		return
	}

	match expr.op.kind {
		.op_plus, .op_minus, .op_div, .op_mul, .op_mod {
			open, close := if opt.inside_arithmetic { '', '' } else { '\$(( ( ', ' ) ))' }
			e.write_block({ open: open, close: close, inline: true }, fn (mut e Emitter, expr ast.InfixExpr) {
				e.expr(expr.left, inside_arithmetic: true)
				e.write(' $expr.op.text ')
				e.expr(expr.right, inside_arithmetic: true)
			}, expr)
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut e Emitter) infix_expr_for_string(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() != builtin_type(.string) {
		panic(unreachable)
	}
	if opt.inside_arithmetic {
		panic(unreachable)
	}

	e.write_echo_if_command(opt)

	match expr.op.kind {
		.op_eq, .op_ne {
			e.write('[ ')
			e.expr(expr.left, {})
			e.write(if expr.op.kind == .op_eq { ' = ' } else { ' != ' })
			e.expr(expr.right, {})
			e.write(' ]')
		}
		.op_plus {
			e.write_block({ open: '\$( ', close: ' )', inline: true }, fn (mut e Emitter, expr ast.InfixExpr) {
				e.write("printf '%s%s' ")
				e.expr(expr.left, {})
				e.write(' ')
				e.expr(expr.right, {})
			}, expr)
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut e Emitter) paren_expr(expr ast.ParenExpr, opt ExprOpt) {
	e.write_echo_if_command(opt)
	open, close := if opt.inside_arithmetic { ' ( ', ' ) ' } else { '', '' }
	e.write_block({ open: open, close: close, inline: true }, fn (mut e Emitter, v ExprWithOpt) {
		e.expr((v.expr as ast.ParenExpr).expr, { ...v.opt, as_command: false })
	}, ExprWithOpt{expr, opt})
}

fn (mut e Emitter) prefix_expr(expr ast.PrefixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.prefix_op) {
		panic(unreachable)
	}

	e.write_echo_if_command(opt)
	opt_for_expr := ExprOpt{
		...opt
		as_command: false
	}
	match op.kind {
		.op_plus {
			e.expr(expr.expr, opt_for_expr)
		}
		.op_minus {
			e.expr(ast.InfixExpr{
				scope: expr.scope
				left: ast.IntLiteral{
					scope: expr.scope
					token: Token{
						kind: .int_lit
						text: '-1'
					}
				}
				right: expr.expr
				op: Token{
					kind: .op_mul
					text: '*'
				}
			}, opt_for_expr)
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut e Emitter) pipeline(expr ast.Pipeline, opt ExprOpt) {
	open, close := if opt.as_command { '', '' } else { '\$(', ')' }
	e.write_block({ open: open, close: close, inline: true }, fn (mut e Emitter, pipeline ast.Pipeline) {
		for i, expr in pipeline.exprs {
			if i > 0 {
				e.write(' | ')
			}
			e.expr(expr, as_command: true)
		}
	}, expr)
}
