local client_module = require('lsp-selection-range.client')
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
end)
