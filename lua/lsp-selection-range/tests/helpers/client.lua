local stub = require('luassert.stub')

local helper = {}

function helper.create_client()
  local client = {}
  local request_sync = stub(client, 'request_sync')

  function client.will_respond_for_position(position, response)
    request_sync.on_call_with('textDocument/selectionRange', {
      textDocument = vim.lsp.util.make_text_document_params(),
      positions = { position },
    }).returns({ result = response })
  end

  return client
end

return helper
