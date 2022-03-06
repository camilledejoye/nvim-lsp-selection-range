local selection = require('lsp-selection-range.selection')
local Range = require('lsp-selection-range.range')
local utils = require('lsp-selection-range.tests.helpers.utils')

describe('selection', function()
  before_each(function()
    utils.replace_buffer_content([[
here is some text
to play with
    ]])
    vim.cmd('normal! \27') -- Leave insert mode
  end)

  describe('current()', function()
    it('returns nil when not in visual mode', function()
      assert.same(nil, selection.current())
    end)

    it('returns a Range matching the visual selection done from start to end', function()
      vim.cmd('normal! gg02wve') -- selects the word "some" with the cursor being on the "e"

      local selected_range = selection.current()

      assert.same(Range.new(1, 9, 1, 12), selected_range)
    end)

    it('returns a Range matching the visual selection done from end to start', function()
      vim.cmd('normal! gg03evb') -- selects the word "some" with the cursor being on the "s"

      local selected_range = selection.current()

      assert.same(Range.new(1, 9, 1, 12), selected_range)
    end)
  end)

  describe('select(range)', function()
    it('visually select the provided range', function()
      local range = Range.new(1, 9, 1, 12)

      selection.select(range)

      assert.same(range, selection.current())
    end)

    it('replaces existing visual selection with the provided range', function()
      local range = Range.new(2, 4, 2, 7)
      selection.select(Range.new(1, 9, 1, 12))

      selection.select(range)

      assert.same(range, selection.current())
    end)

    it('preserve the value of `virtualedit` even when an error happens', function()
      vim.api.nvim_set_option('virtualedit', 'all')

      selection.select(Range.new(-1, 9, 1, 12))

      assert.same('all', vim.api.nvim_get_option('virtualedit'))
      assert.same(nil, selection:current())
    end)
  end)
end)
