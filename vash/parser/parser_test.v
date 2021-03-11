module parser

import vash.lexer

fn test_consume_token() {
	mut p := new(lexer.new(path: '', code: '0 1 2 3 4'))
	assert p.token(0).text == '0'
	assert p.token(1).text == '1'
	assert p.token(2).text == '2'

	p.consume()
	assert p.token(0).text == '1'
	assert p.token(1).text == '2'
	assert p.token(2).text == '3'

	p.consume()
	assert p.token(0).text == '2'
	assert p.token(1).text == '3'

	p.consume()
	p.consume()
	assert p.token(0).text == '4'
	assert p.token(1).kind == .eof
	assert p.token(2).kind == .eof
}
