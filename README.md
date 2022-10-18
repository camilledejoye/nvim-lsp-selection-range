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

-- Update existing capabilities
capabilities = lsp_selection_range.update_capabilities(capabilities)

-- If you don't already have custom capabilities you can simply do
local capabilities = lsp_selection_range.update_capabilities({})

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

## Caching the choice of client per filetype

When you have more than one server offering the selection range feature you'll be asked to choose which one to use every time you want to select something.
This can quickly be annoying, to help you with that you can add a little bit of configuration to setup the plugin
accordingly:

```lua
local lsp_selection_range = require('lsp-selection-range')
local lsr_client = require('lsp-selection-range.client')

lsp_selection_range.setup({
  get_client = lsr_client.select_by_filetype(lsr_client.select)
})
```

You can provide to `get_client` any function with the following signature `func(): Client|nil`.

The `lsr_client.select` is the default implementation used by this plugin:
* If no client supports the feature: returns `nil`
* If only one client supports the feature: returns it
* If more than one client support the feature: will ask you to choose using `vim.select` UI

The `lsr_client.select_by_filetype` will create a wrapper around any function returning a client and memorized the returned client for each filetype.

# Documentation

There is no documentation outside this `README.md`.
The plugin does not yet integrate enough configuration or possibilities to justify investing time into setting up an automatic generation of the documentation.
And since I far more to lazy to do it by hand... :)
