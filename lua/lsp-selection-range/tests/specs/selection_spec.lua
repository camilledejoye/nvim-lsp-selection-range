local selection = require('lsp-selection-range.selection')
local Range = require('lsp-selection-range.range')
local stub = require('luassert.stub')
local notify

describe('selection', function()
  before_each(function()
    vim.cmd('edit ./lua/lsp-selection-range/tests/fixtures/multibyte.lua')

    notify = stub(vim, 'notify')
    notify.invokes(function(msg, log_level, _)
      if vim.log.levels.ERROR == log_level then
        error(msg)
      else
        error('Unexpected notification: ' .. msg)
      end
    end)
  end)

  after_each(function()
    notify:revert()
    vim.cmd('bdelete!')
  end)

  describe('current()', function()
    it('returns nil when not in visual mode', function()
      assert.same(nil, selection.current())
    end)

    it('returns a Range matching the visual selection done from start to end', function()
      vim.cmd('normal! gg06wve') -- selects the word "multibyte" from left to right

      local selected_range = selection.current()

      assert.same(Range.new(0, 25, 0, 34), selected_range)
    end)

    it('returns a Range matching the visual selection done from end to start', function()
      vim.cmd('normal! gg07evb') -- selects the word "multibyte" from right to left

      local selected_range = selection.current()

      assert.same(Range.new(0, 25, 0, 34), selected_range)
    end)
  end)

  describe('select(range)', function()
    it('visually selects a simple provided range', function()
      local range = Range.new(0, 25, 0, 34)

      selection.select(range)

      assert.same(range, selection.current())
    end)

    it('visually selects a simple provided range', function()
      local range = Range.new(1, 6, 1, 24)

      selection.select(range)

      assert.same(range, selection.current())
    end)

    it('replaces existing visual selection with the provided range', function()
      local range = Range.new(1, 6, 1, 24)
      selection.select(Range.new(0, 25, 0, 34))

      selection.select(range)

      assert.same(range, selection.current())
    end)

    it('preserve the value of `virtualedit` even when an error happens', function()
      notify.invokes(function() end)
      vim.api.nvim_set_option('virtualedit', 'all')

      selection.select(Range.new(0, 25, -1, 34))

      assert.same('all', vim.api.nvim_get_option('virtualedit'))
      assert.same(nil, selection:current())
    end)

    it('visually selects a range starting and ending after the last characters', function()
      local range = Range.new(1, 28, 5, 0)

      selection.select(range)

      assert.same(range, selection.current())
    end)
  end)
end)
