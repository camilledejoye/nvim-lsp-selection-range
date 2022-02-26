--- Short ServerCapabilities representation containing only what I need
---
---@class ServerCapabilities
---@field selectionRangeProvider boolean

--- Client object as returned by Neovim LSP
---
---@class Client
---@field name string
---@field server_capabilities ServerCapabilities

local if_nil = vim.F.if_nil
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
  -- TODO handle caching clients:
  -- * keep the selected client in memory for each filetype
  -- * reset the cached client when new client is attached for the filetype (using on_attach)
  -- * create wrapper function to add the caching logic around any function to use in place of get_client()
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

return M
