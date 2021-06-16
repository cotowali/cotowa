module ast

import cotowari.source { Pos, Source }
import cotowari.context { Context }
import cotowari.debug { Tracer }

pub struct Resolver {
mut:
	ctx    &Context
	tracer Tracer
	source &Source = 0
}

pub fn new_resolver(ctx &Context) Resolver {
	return {
		ctx: ctx
	}
}

pub fn resolve(ctx &Context, node Node) {
	mut r := new_resolver(ctx)
	r.resolve(node)
}

pub fn (mut r Resolver) resolve(node Node) {
	match node {
		File { r.file(node) }
		Stmt { r.stmt(node) }
		Expr { r.expr(node) }
	}
}

[inline]
fn (mut r Resolver) trace_begin(f string, args ...string) {
	$if trace_resolver ? {
		r.tracer.begin_fn(f, ...args)
	}
}

[inline]
fn (mut r Resolver) trace_end() {
	$if trace_resolver ? {
		r.tracer.end_fn()
	}
}

fn (mut r Resolver) error(msg string, pos Pos) {
	$if trace_resolver ? {
		r.trace_begin(@FN, msg, '$pos')
		defer {
			r.trace_end()
		}
	}

	r.ctx.errors.push(
		source: r.source
		msg: msg
		pos: pos
	)
}