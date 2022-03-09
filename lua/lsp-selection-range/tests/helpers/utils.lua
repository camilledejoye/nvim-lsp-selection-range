local utils = {}

local function get_line_byte_from_position(position)
  return vim.lsp.util._get_line_byte_from_position(0, position, 'utf-16')
end

---@param position Position
function utils.move_cursor_to(position)
  vim.api.nvim_win_set_cursor(0, {
    position.line + 1,
    get_line_byte_from_position(position),
  })
end

return utils
