local Range = require('lsp-selection-range.range')

describe('Range', function()
  describe('new()', function()
    it('creates a range object from positions', function()
      local range = Range.new(2, 9, 4, 8)

      assert.same(2, range.start.line)
      assert.same(9, range.start.character)
      assert.same(4, range['end'].line)
      assert.same(8, range['end'].character)
    end)
  end)

  describe('==', function()
    it('compares a range with another range', function()
      local range = Range.new(5, 13, 56, 9)
      local equal_range = Range.new(5, 13, 56, 9)
      local different_range = Range.new(41, 24, 85, 3)

      assert.is.truthy(range == equal_range, 'must match another range with same values')
      assert.is.falsy(range == different_range, 'must not match a range with different values')
    end)
  end)

  describe('from_lsp()', function()
    before_each(function()
      vim.cmd('edit ./lua/lsp-selection-range/tests/fixtures/multibyte.lua')
    end)

    it('creates a range object from an LSP range', function()
      local range = Range.from_lsp(0, {
        start = { line = 2, character = 2 },
        ['end'] = { line = 4, character = 21 },
      })

      assert.same(Range.new(3, 3, 5, 21), range)
    end)

    it('creates a range object when the end position includes the line ending character(s)', function()
      local range = Range.from_lsp(0, {
        start = { line = 1, character = 28 },
        ['end'] = { line = 5, character = 0 },
      })

      assert.same(Range.new(2, 29, 5, 2147483647), range)
    end)

    it('creates a range while taking into account multibyte character', function()
      local range = Range.from_lsp(0, {
        start = { line = 0, character = 25 },
        ['end'] = { line = 0, character = 34 },
      })

      assert.same(Range.new(1, 28, 1, 36), range)
    end)
  end)

  describe('contains()', function()
    it('checks if a range contains another', function()
      local range = Range.new(5, 13, 56, 9)
      local contained_range = Range.new(6, 18, 50, 13)
      local partially_contained_range = Range.new(6, 18, 60, 43)
      local same_lines_but_start_earlier_at_the_start = Range.new(5, 10, 56, 9)
      local same_lines_but_more_character_at_the_end = Range.new(5, 13, 56, 10)

      assert.is.truthy(range:contains(range), 'must contained itself')
      assert.is.truthy(range:contains(contained_range), 'must contained a smaller included range')
      assert.is.falsy(range:contains(partially_contained_range), 'must not contained partially contained range')
      assert.is.falsy(
        range:contains(same_lines_but_start_earlier_at_the_start),
        'must take into account starting character'
      )
      assert.is.falsy(
        range:contains(same_lines_but_more_character_at_the_end),
        'must take into account ending character'
      )
    end)
  end)
end)
