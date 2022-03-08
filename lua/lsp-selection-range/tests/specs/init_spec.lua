local lsp_selection_range = require('lsp-selection-range')
local Range = require('lsp-selection-range.range')
local selection = require('lsp-selection-range.selection')
local simple_php = require('lsp-selection-range.tests.helpers.simple-php')

local function use_client(client)
  lsp_selection_range.get_client = function()
    return client
  end
end

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

---@param position Position
local function move_cursor_to(position)
  vim.api.nvim_win_set_cursor(0, { position.line + 1, position.character })
end

describe('trigger()', function()
  before_each(function()
    vim.cmd('edit ' .. simple_php.file_path)
    use_client(nil)
  end)

  after_each(function()
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
    move_cursor_to(simple_php.positions.on_last_return_var)

    lsp_selection_range.trigger()

    assert.same(expected_visual_range, selection.current())
  end)
end)

describe('expand()', function()
  before_each(function()
    vim.cmd('edit ' .. simple_php.file_path)
    use_client(simple_php.get_client())
  end)

  after_each(function()
    vim.cmd('bdelete!')
  end)

  it('does nothing when not in visual mode', function()
    move_cursor_to(simple_php.positions.on_last_return_var)

    lsp_selection_range.expand()

    assert.same(nil, selection.current())
  end)

  it('selects the parent of the current selection range when it matches the visual selection', function()
    local expected_selection_range = simple_php.selection_ranges.from_last_return.return_stmt
    move_cursor_to(simple_php.positions.on_last_return_var)
    lsp_selection_range.trigger()

    lsp_selection_range.expand()

    assert.same(Range.from_table(expected_selection_range.range), selection.current())
  end)

  it('can be chained', function()
    local expected_selection_range = simple_php.selection_ranges.from_last_return.return_stmt
    move_cursor_to(simple_php.positions.on_last_return_var)
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
