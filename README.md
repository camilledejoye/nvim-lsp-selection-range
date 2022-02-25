# Requirements

* Neovim >= `v0.6.1`
* A language server with [selection range](https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_selectionRange) capabilities

# Installation

Use your favorite package manager as usual.

# Configuration

First you must update the LSP client capabilities to let the servers know that it can handle selection range feature.
And then you need to configure a mapping to visually select accordingly to your server response.

## Using [nvim-lsp-config](https://github.com/nikvdp/nvim-lsp-config)

```lua
local nvim_lsp = require('lspconfig')
local lsp_selection_range = require('lsp-selection-range')

-- Generate the default Neovim LSP capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
-- Update the default capabilities
capabilities = lps_selection_range.update_capabilities(capabilities)

local on_attach = function(client, bufnr)
  local bmap = function(mode, lhs, rhs, options)
    options = options or {}

    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, options)
  end

  -- Put here any configuration to execute when attaching a client to a buffer

  -- Create mappings to trigger or expand the selection
  bmap('n', 'vv', [[<cmd>lua require('lsp-selection-range').trigger()<CR>]], { noremap = true })
  bmap('v', 'vv', [[<cmd>lua require('lsp-selection-range').expand()<CR>]], { noremap = true })
end

nvim_lsp['your-server-name'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  -- Put here your server configuration as usual
})
```

# Documentation

The documentation is available in Neovim with `:h lsp-selection-range`.
