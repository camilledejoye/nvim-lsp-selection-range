local lsp_selection_range = require('lsp-selection-range')
local client_module = require('lsp-selection-range.client')
local Range = require('lsp-selection-range.range')
local selection = require('lsp-selection-range.selection')
local utils = require('lsp-selection-range.tests.helpers.utils')
local simple_php = require('lsp-selection-range.tests.helpers.simple-php')
local stub = require('luassert.stub')
local buf_get_clients

local function use_client(client)
  buf_get_clients.returns({ client })
end

describe('update_capabilities()', function()
  it('creates new capabilities including "textDocument/selectionRange" and raises deprecation on nil', function()
    local expectedCapabilities = vim.lsp.protocol.make_client_capabilities()
    expectedCapabilities.textDocument.selectionRange = { dynamicRegistration = false }
    local notify_once = stub(vim, 'notify_once')

    local capabilities = lsp_selection_range.update_capabilities(nil)

    assert.stub(notify_once)
          .was_called_with('lsp-selection-range.update_capabilities: Passing nil is deprecated.', vim.log.levels.WARN)

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

  it('does not override dynamicRegistration of existing "textDocument/selectionRange" capabilities', function()
    local capabilities = {
      textDocument = {
        selectionRange = {
          dynamicRegistration = true,
        },
      },
    }
    local expectedCapabilities = vim.deepcopy(capabilities)

    capabilities = lsp_selection_range.update_capabilities(capabilities)

    assert.same(expectedCapabilities, capabilities)
  end)
end)

describe('trigger()', function()
  before_each(function()
    buf_get_clients = stub(vim.lsp, 'buf_get_clients')
    vim.cmd('edit ' .. simple_php.file_path)
    use_client(nil)
  end)

  after_each(function()
    buf_get_clients:revert()
    vim.cmd('bdelete!')
  end)

  it('preserves current visual selection when no client provide selection ranges', function()
    local visual_range = Range.from_table(simple_php.selection_ranges.from_last_return.variable.range)
    selection.select(visual_range)

    lsp_selection_range.trigger()

    assert.same(visual_range, selection.current())
  end)

  it('selects the first range returned by the client', function()
    local expected_visual_range = Range.from_table(simple_php.selection_ranges.from_last_return.variable.range)
    use_client(simple_php.get_client())
    utils.move_cursor_to(simple_php.positions.on_last_return_var)

    lsp_selection_range.trigger()

    assert.same(expected_visual_range, selection.current())
  end)
end)

describe('expand()', function()
  before_each(function()
    buf_get_clients = stub(vim.lsp, 'buf_get_clients')
    vim.cmd('edit ' .. simple_php.file_path)
    use_client(simple_php.get_client())
  end)

  after_each(function()
    buf_get_clients:revert()
    vim.cmd('bdelete!')
  end)

  it('does nothing when not in visual mode', function()
    utils.move_cursor_to(simple_php.positions.on_last_return_var)

    lsp_selection_range.expand()

    assert.same(nil, selection.current())
  end)

  it('selects the parent of the current selection range when it matches the visual selection', function()
    local expected_selection_range = simple_php.selection_ranges.from_last_return.return_stmt
    utils.move_cursor_to(simple_php.positions.on_last_return_var)
    lsp_selection_range.trigger()

    lsp_selection_range.expand()

    assert.same(Range.from_table(expected_selection_range.range), selection.current())
  end)

  it('can be chained', function()
    local expected_selection_range = simple_php.selection_ranges.from_last_return.return_stmt
    utils.move_cursor_to(simple_php.positions.on_last_return_var)
    lsp_selection_range.trigger()

    lsp_selection_range.expand()
    lsp_selection_range.expand()

    assert.same(Range.from_table(expected_selection_range.parent.range), selection.current())
  end)

  it(
    'selects the first range containing the visual selection when it does not match the current selection range',
    function()
      local visual_range = Range.from_table(simple_php.ranges.from_if_to_last_return)
      local expected_visual_range = Range.from_table(
        simple_php.selection_ranges.from_last_return.function_body_without_braces.range
      )
      selection.select(visual_range)

      lsp_selection_range.expand()

      assert.same(expected_visual_range, selection.current())
    end
  )
end)

describe('setup', function()
  after_each(function()
    lsp_selection_range.setup()
  end)

  describe('get_client', function()
    it('use defaults when not provided', function()
      lsp_selection_range.setup()

      assert.same(client_module.select, lsp_selection_range.get_client, 'get_client function not correctly defined')
    end)

    it('sets the function used to choose which client to use', function()
      local custom_function = function() end
      lsp_selection_range.setup({ get_client = custom_function })

      assert.same(custom_function, lsp_selection_range.get_client, 'get_client function not correctly defined')
    end)
  end)
end)
