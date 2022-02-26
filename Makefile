.PHONY: test
test:
	nvim --headless --noplugin -u lua/lsp-selection-range/tests/minimal_init.vim \
		-c "PlenaryBustedDirectory lua/lsp-selection-range/tests/specs/ {minimal_init = 'lua/lsp-selection-range/tests/minimal_init.vim'}"
