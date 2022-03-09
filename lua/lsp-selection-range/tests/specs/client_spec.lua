local client_module = require('lsp-selection-range.client')
local utils = require('lsp-selection-range.tests.helpers.utils')
local simple_php = require('lsp-selection-range.tests.helpers.simple-php')
local stub = require('luassert.stub')

describe('client', function()
  describe('select()', function()
    local function create_client(name, server_capabilities)
      return { name = name, server_capabilities = server_capabilities }
    end

    local buf_get_clients
    local php_client = create_client('php', { selectionRangeProvider = true })
    local lua_client = create_client('lua', { selectionRangeProvider = false })
    local ts_client = create_client('ts', { selectionRangeProvider = true })

    ---@vararg Client
    local function attach_clients_to_current_buffer(...)
      buf_get_clients.returns({ ... })
    end

    before_each(function()
      buf_get_clients = stub(vim.lsp, 'buf_get_clients')
      buf_get_clients.returns({})
    end)

    after_each(function()
      buf_get_clients:revert()
    end)

    it('returns "nil" when there is no client', function()
      local client = client_module.select()

      assert.same(nil, client, 'no client must be returned')
    end)

    it('returns "nil" when no client have the "selectionRangeProvider" capability', function()
      attach_clients_to_current_buffer(lua_client)

      local client = client_module.select()

      assert.same(nil, client, 'no client must be returned')
    end)

    it('returns the only client with the "selectionRangeProvider" capability', function()
      attach_clients_to_current_buffer(php_client, lua_client)

      local client = client_module.select()

      assert.same(php_client, client, 'the "php" client must be returned')
    end)

    it('asks the user to select the client to use when more than one are eligible', function()
      local ui_select = stub(vim.ui, 'select')
      attach_clients_to_current_buffer(ts_client, lua_client, php_client)

      ui_select.invokes(function(clients, opts, on_choice)
        assert.same(clients[1].name, opts.format_item(clients[1]), 'clients must be formated by name')
        assert.same({ php_client, ts_client }, clients, 'clients must be sorted by name')

        on_choice(clients[2]) -- Select "ts" client
      end)

      local client = client_module.select()

      assert.same(ts_client, client, 'the "ts" client must be returned')

      ui_select:revert()
    end)
  end)

  describe('fetch_selection_range()', function()
    local client = { name = 'fake_client' }
    local request_sync, notify

    before_each(function()
      request_sync = stub(client, 'request_sync')
      request_sync.returns({ res = nil })
      notify = stub(vim, 'notify')
    end)

    after_each(function()
      request_sync:revert()
      notify:revert()
    end)

    it('notifies when reaching the request times out', function()
      request_sync.returns(nil, 'error message')

      client_module.fetch_selection_range(client, {}, 1)

      assert.stub(notify).was_called_with('fake_client: timeout: error message', 4)
    end)

    it('notifies when the server responded with an error', function()
      request_sync.returns({ err = { code = '007', message = 'Bond, James Bond!' } })

      client_module.fetch_selection_range(client, {})

      assert.stub(notify).was_called_with('fake_client: 007: Bond, James Bond!', 4)
    end)

    it('generates params when not provided', function()
      vim.cmd('edit ' .. simple_php.file_path)
      utils.move_cursor_to(simple_php.positions.on_last_return_var)

      client_module.fetch_selection_range(client)

      assert.stub(request_sync).was_called_with('textDocument/selectionRange', {
        textDocument = { uri = 'file://' .. vim.api.nvim_buf_get_name(0) },
        positions = { simple_php.positions.on_last_return_var },
      }, nil, nil)
      vim.cmd('bdelete!')
    end)

    it('returns `nil` when the server does not provide a result', function()
      request_sync.returns({ result = {} })

      local selection_range = client_module.fetch_selection_range(client)

      assert.same(nil, selection_range)
    end)

    it('returns the selection range when the server provide a result', function()
      local expected_selection_range = simple_php.selection_ranges.from_last_return.variable
      request_sync.returns({ result = { expected_selection_range } })

      local selection_range = client_module.fetch_selection_range(client)

      assert.same(expected_selection_range, selection_range)
    end)
  end)
end)
