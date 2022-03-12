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

--- Description of the configuration options accepted by the setup() function
---
---@class LspSelectionRangeConfig
---@field get_client? SelectClientFunc #Defaults to require('lsp-selection-range.client').select

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

  return client_module.fetch_selection_range(client)
end

--- Retrieve the last selection ranged used to visually select something in order to expand it
---
---@return SelectionRange|nil
local function get_last_selection_range()
  local success, result = pcall(vim.api.nvim_buf_get_var, 0, 'lsp_selection_range_last_selection_range')
  return success and result or nil
end

--- Saves the selection range for the buffer so that we can expand the selection later on
---
---@param selection_range SelectionRange|nil
local function remember_last_selection_range(selection_range)
  vim.api.nvim_buf_set_var(0, 'lsp_selection_range_last_selection_range', selection_range)
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

  remember_last_selection_range(selection_range)
  selection.select(Range.from_table(selection_range.range))
end

--- Expand the visual selection
function M.expand()
  local selection_range = get_last_selection_range()
  local visual_selection = selection.current()

  if not visual_selection then
    return nil
  end

  if selection_range and visual_selection == Range.from_table(selection_range.range) then
    selection_range = selection_range.parent or nil
  else
    selection_range = request_selection_range_under_cursor()

    while nil ~= selection_range and not Range.from_table(selection_range.range):contains(visual_selection) do
      selection_range = selection_range.parent
    end
  end

  if nil == selection_range then
    return
  end

  remember_last_selection_range(selection_range)
  selection.select(Range.from_table(selection_range.range))
end

--- Configure the plugin
---
--- @param config LspSelectionRangeConfig
function M.setup(config)
  config = config or {}
  vim.validate({
    get_client = { config.get_client, 'function', true },
  })

  M.get_client = config.get_client or client_module.select
end

return M
