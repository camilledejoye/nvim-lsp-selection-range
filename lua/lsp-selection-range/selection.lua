local Range = require('lsp-selection-range.range')

local selection = {}

--- Gets the current visual selection
---
---@return Range|nil
function selection.current()
  if not vim.tbl_contains({ 118, 86, 22 }, vim.api.nvim_get_mode().mode:byte()) then
    return nil
  end

  -- When not in visual mode returns the cursor position
  local _, visual_line, visual_character = unpack(vim.fn.getpos('v'))
  local _, cursor_line, cursor_character = unpack(vim.fn.getcurpos())

  -- Depending on the direction of the selection the cursor position could be the start or the end
  return (visual_line < cursor_line or visual_character < cursor_character)
      and Range.new(visual_line, visual_character, cursor_line, cursor_character)
    or Range.new(cursor_line, cursor_character, visual_line, visual_character)
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
    vim.cmd('normal! \27') -- Leave visual mode if needed
    -- nvim_win_set_cursor is (1,0)-indexed for lines and character positions
    vim.api.nvim_win_set_cursor(0, { visual_range.start.line, visual_range.start.character - 1 })
    vim.cmd('normal! v')
    vim.api.nvim_win_set_cursor(0, { visual_range['end'].line, visual_range['end'].character - 1 })
  end, range)

  vim.api.nvim_set_option('virtualedit', previous_virtualedit)

  if not ok then
    vim.notify('lsp-selection-range: ' .. err, vim.log.levels.ERROR)
  end
end

return selection
