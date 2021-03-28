import os

fn test_compile_errors() ? {
	dir := os.dir(@FILE)
	filter := fn (s string) bool {
		return s.contains('_err.') && !s.ends_with('.out')
	}
	sources := (os.ls(dir) ?).filter(filter).map(os.join_path(dir, it))
	assert os.execute('v cmd/ri').exit_code == 0
	for path in sources {
		println('$path')
		result := os.execute('./cmd/ri/ri $path')
		out_path := path.trim_suffix(os.file_ext(path)) + '.out'
		expected := os.read_file(out_path) ?
		println('FILE: $path')
		assert result.exit_code != 0
		assert result.output == expected
	}
}
