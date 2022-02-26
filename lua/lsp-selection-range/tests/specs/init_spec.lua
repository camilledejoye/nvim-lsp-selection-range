local lsp_selection_range = require('lsp-selection-range')

describe('update_capabilities()', function()
  it('creates new capabilities including "textDocument/selectionRange" and returns them', function()
    local expectedCapabilities = vim.lsp.protocol.make_client_capabilities()
    expectedCapabilities.textDocument.selectionRange = { dynamicRegistration = false }

    local capabilities = lsp_selection_range.update_capabilities(nil)

    assert.same(expectedCapabilities, capabilities)
  end)

  it('updates the provided capabilities to handle "textDocument/selectionRange" and returns them', function()
    local capabilities = {
      textDocument = {
        hover = {
          dynamicRegistration = false,
        },
      },
      workspace = {
        applyEdit = true,
      },
    }
    local expectedCapabilities = vim.deepcopy(capabilities)
    expectedCapabilities.textDocument.selectionRange = { dynamicRegistration = false }

    capabilities = lsp_selection_range.update_capabilities(capabilities)

    assert.same(expectedCapabilities, capabilities)
  end)
end)
