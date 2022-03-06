local utils = {}

--- Splits a multi-lines string
---
--- @return string[]
function utils.content_to_lines(content)
  local lines = {}
  for line, _ in content:gmatch('([^\n]*)\n?') do
    table.insert(lines, line)
  end

  table.remove(lines, #lines)

  return lines
end

--- Replaces the entire content of a buffer
---
---@param content string
---@param bufnr? number #Defaults to 0
function utils.replace_buffer_content(content, bufnr)
  bufnr = bufnr or 0

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, utils.content_to_lines(content))
end


return utils
