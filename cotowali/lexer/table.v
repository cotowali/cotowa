module lexer

const (
	table_for_one_char_symbols = map{
		`(`: tk(.l_paren)
		`)`: tk(.r_paren)
		`{`: tk(.l_brace)
		`}`: tk(.r_brace)
		`[`: tk(.l_bracket)
		`]`: tk(.r_bracket)
		`<`: tk(.lt)
		`>`: tk(.gt)
		`#`: tk(.hash)
		`+`: tk(.plus)
		`-`: tk(.minus)
		`*`: tk(.mul)
		`/`: tk(.div)
		`%`: tk(.mod)
		`&`: tk(.amp)
		`=`: tk(.assign)
		`!`: tk(.not)
		`,`: tk(.comma)
		`.`: tk(.dot)
	}

	table_for_two_chars_symbols = map{
		'++': tk(.plus_plus)
		'--': tk(.minus_minus)
		'&&': tk(.logical_and)
		'||': tk(.logical_or)
		'+=': tk(.plus_assign)
		'-=': tk(.minus_assign)
		'*=': tk(.mul_assign)
		'/=': tk(.div_assign)
		'%=': tk(.mod_assign)
		'==': tk(.eq)
		'!=': tk(.ne)
		'<=': tk(.le)
		'>=': tk(.ge)
		'|>': tk(.pipe)
	}

	table_for_three_chars_symbols = map{
		'...': tk(.dotdotdot)
	}

	table_for_keywords = map{
		'true':    tk(.bool_lit)
		'false':   tk(.bool_lit)
		'as':      tk(.key_as)
		'assert':  tk(.key_assert)
		'decl':    tk(.key_decl)
		'export':  tk(.key_export)
		'else':    tk(.key_else)
		'fn':      tk(.key_fn)
		'for':     tk(.key_for)
		'if':      tk(.key_if)
		'in':      tk(.key_in)
		'require': tk(.key_require)
		'return':  tk(.key_return)
		'struct':  tk(.key_struct)
		'use':     tk(.key_use)
		'var':     tk(.key_var)
		'while':   tk(.key_while)
		'yield':   tk(.key_yield)
	}
)
