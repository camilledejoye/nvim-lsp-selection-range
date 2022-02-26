---@brief [[
--- lsp-selection-range is a plugin for handling the selection range feature as defined by the LSP protocol:
--- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_selectionRange
---@brief ]]

---@tag lsp-selection-range

--- ClientCapabilities object as returned by Neovim LSP
---
---@class ClientCapabilities
---@field textDocument TextDocument

--- Short TextDocument representation containing only what I need
---
---@class TextDocument
---@field selectionRange boolean

local M = {}

--- Update client capabilities to handle the selection range feature
---
---@param capabilities|nil ClientCapabilities #Create new client capabilities if `nil` is provided
---@return ClientCapabilities
---@see vim.lsp.protocol.make_client_capabilities()
function M.update_capabilities(capabilities)
  vim.validate({ capabilities = { capabilities, 'table', true } })
  capabilities = capabilities or vim.lsp.protocol.make_client_capabilities()

  capabilities.textDocument = vim.tbl_extend('force', capabilities.textDocument or {}, {
    selectionRange = { dynamicRegistration = false },
  })

  return capabilities
end

return M
