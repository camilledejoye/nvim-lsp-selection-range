local Range = require('lsp-selection-range.range')

local visual_modes_bytes = {
  118, -- visual
  86, -- visual_line
  22, -- visual_block
}

---@param position Position
local function get_line_byte_from_position(position)
  local offset_encoding = vim.lsp.util._get_offset_encoding(0)

  return vim.lsp.util._get_line_byte_from_position(0, position, offset_encoding)
end

local selection = {}

--- Gets the current visual selection
---
---@return Range|nil
function selection.current()
  local mode = vim.api.nvim_get_mode().mode
  local in_visual_mode = vim.tbl_contains(visual_modes_bytes, mode:byte())

  if not in_visual_mode then
    return nil
  end

   -- Leave visual selection to set '<' and '>' marks and immediately reselect
  vim.cmd('normal! \27gv')
  local ok, result = pcall(vim.lsp.util.make_given_range_params)

  if not ok then
    vim.notify(result, vim.log.levels.ERROR)
  end

  -- Use a end position with a character position of 0 when needed to be consistent
  -- This will help comparing ranges since this is how we would manually define it
  local last_col = vim.fn.col({ result.range['end'].line + 1, '$' })
  local last_character = vim.lsp.util.character_offset(0, result.range['end'].line, last_col)
  if last_character < result.range['end'].character then
    result.range['end'].line = result.range['end'].line + 1
    result.range['end'].character = 0
  end

  return Range.from_table(result.range)
end

--- Visually select the provided range
---
---@param range Range
function selection.select(range)
  -- Allows to select one more character at the end of the lines
  -- This is needed to be able to select from after the last character of a line
  local previous_virtualedit = vim.api.nvim_get_option('virtualedit')
  vim.api.nvim_set_option('virtualedit', 'onemore')

  -- Use pcall to prevent any blocking error until we were able to revert the option's value
  local ok, err = pcall(function(visual_range)
    vim.cmd('normal! \27') -- Leave visual mode if already in it
    -- nvim_win_set_cursor is (1,0)-indexed for line and character positions
    vim.api.nvim_win_set_cursor(0, {
      visual_range.start.line + 1,
      get_line_byte_from_position(visual_range.start),
    })
    vim.cmd('normal! v')
    if 0 == visual_range['end'].character then
      -- In case we want to select until the last line, including line ending character(s)
      vim.api.nvim_win_set_cursor(0, {
        visual_range['end'].line,
        vim.fn.col({ visual_range['end'].line, '$' }),
      })
    else
      vim.api.nvim_win_set_cursor(0, {
        visual_range['end'].line + 1,
        get_line_byte_from_position({ line = visual_range['end'].line, character = visual_range['end'].character - 1 }),
      })
    end
  end, range)

  -- vim.cmd('normal! \27');dump(vim.api.nvim_buf_get_mark(0, '<'), vim.api.nvim_buf_get_mark(0, '>')); vim.cmd('normal! gv'); dump('flush')
  vim.api.nvim_set_option('virtualedit', previous_virtualedit)

  if not ok then
    vim.cmd('normal! \27') -- Leave visual mode if needed
    vim.notify('lsp-selection-range: ' .. err, vim.log.levels.ERROR)
  end
end

return selection
