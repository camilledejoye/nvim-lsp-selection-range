--- Short ServerCapabilities representation containing only what I need
---
---@class ServerCapabilities
---@field selectionRangeProvider boolean

---@alias DocumentUri string

--- TextDocumentIdentifier as defined by LSP
---
---@class TextDocumentIdentifier
---@field uri DocumentUri

--- SelectionRangeParams as defined by LSP
---
---@class SelectionRangeParams
---@field TextDocument TextDocumentIdentifier
---@field positions Position[]

--- Client object as returned by Neovim LSP
---
---@class Client
---@field name string
---@field server_capabilities ServerCapabilities
---@field request_sync fun(method: string, params: table, timeout_ms: number, bufnr: number): ResponseMessage|nil, nil|string

---@class ResponseMessage
---@field result? any #The result from the LSP handler
---@field err? ResponseError #The error from the LSP handler

---@class ResponseError
---@field code number
---@field message string
---@field data? any

---@alias SelectClientFunc fun(): Client|nil

local if_nil = vim.F.if_nil
-- TODO: is it needed to reset it when a new client is attached ?
local clients_by_filetype = {}
local M = {}

--- Select a client with the `selectionRangeProvider` capability
---
--- When multiple clients provide the capability let the user select one using `vim.ui.select`.
--- When only one client provides the capability return it.
--- When no client provide the capability return `nil`.
---
---@return Client|nil
---
---@see vim.ui.select
function M.select()
  local clients = vim.tbl_values(vim.lsp.buf_get_clients())

  -- Keep only clients with matching capabilities
  clients = vim.tbl_filter(function(client)
    return nil ~= client.server_capabilities
      and false ~= if_nil(client.server_capabilities.selectionRangeProvider, false)
  end, clients)

  table.sort(clients, function(a, b)
    return a.name < b.name
  end)

  if 0 == #clients then
    return nil
  end

  if 1 == #clients then
    return clients[1]
  end

  local selected_client = nil
  vim.ui.select(clients, {
    prompt = 'Select a language server:',
    format_item = function(client)
      return client.name
    end,
  }, function(client)
    selected_client = client
  end)

  return selected_client
end

--- Decorate a selection method by only asking once per filetype
---
--- If the selector returns `nil` the value is not cached and the selector will be call again the next time
--- until a client is returened.
---
---@param selector SelectClientFunc
---
---@return SelectClientFunc
function M.select_by_filetype(selector)
  return function()
    vim.validate({ selector = { selector, 'function' } })
    local filetype = vim.api.nvim_buf_get_option(0, 'filetype')

  if "" == filetype then
    return selector()
  end

  if nil == clients_by_filetype[filetype] then
    clients_by_filetype[filetype] = selector()
  end

  return clients_by_filetype[filetype]
  end
end

--- Fetches selection range from client
---
---@param client Client
---@param params? SelectionRangeParams
---@param timeout_ms? number #Defaults to 1000
---@param bufnr? number #Defaults to 0
---
---@result SelectionRange|nil
function M.fetch_selection_range(client, params, timeout_ms, bufnr)
  if not params then
    local position_params = vim.lsp.util.make_position_params()
    params = {
      textDocument = position_params.textDocument,
      positions = { position_params.position },
    }
  end

  local res, err = client.request_sync('textDocument/selectionRange', params, timeout_ms, bufnr)

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

return M
