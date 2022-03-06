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

--- SelectionRange as defined by LSP
---
---@class SelectionRange
---@field parent? SelectionRange
---@field range LspRange

local client_module = require('lsp-selection-range.client')
local selection = require('lsp-selection-range.selection')
local Range = require('lsp-selection-range.range')
local M = {}

--- Fetches the selection range from the selected client.
---
---@return SelectionRange|nil
local function request_selection_range_under_cursor()
  local client = M.get_client()

  if nil == client then
    return
  end

  local method = 'textDocument/selectionRange'
  local position_params = vim.lsp.util.make_position_params()
  local params = {
    textDocument = position_params.textDocument,
    positions = { position_params.position },
  }
  local res, err = client.request_sync(method, params)

  if 'string' == type(err) then
    vim.notify(('%s: timeout: %s'):format(client.name, err), vim.log.levels.ERROR)
    vim.api.nvim_command('redraw')
    return
  end

  if nil ~= res.err then
    err = res.err
    vim.notify(('%s: %s: %s'):format(client.name, tostring(err.code), err.message), vim.log.levels.ERROR)
    vim.api.nvim_command('redraw')
    return
  end

  local result = res.result

  if 'table' == type(result) then
    -- Since we only send one position in the request we will only have one result
    result = result[1]
  end

  return result
end

--- Retrieves the client to use to retrieve the selection range
---
---@return Client|nil #`nil` if no clients have the `selectionRangeProvider` capability
M.get_client = client_module.select

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

--- Trigger the visual selection of the selection range under the cursor
function M.trigger()
  local selection_range = request_selection_range_under_cursor()

  if nil == selection_range then
    return
  end

  selection.select(Range.from_lsp(0, selection_range.range))
end

return M
