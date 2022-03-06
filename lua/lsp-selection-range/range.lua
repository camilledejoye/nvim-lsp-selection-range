---@class Position
---@field line number #1-based line number
---@field character number #1-based character number

---@class LspPosition
---@field line number #0-based line number
---@field character number #0-based character number

---@class LspRange
---
--- Uses 0-based indices for lines and characters and is end-exclusive.
--- https://microsoft.github.io/language-server-protocol/specification.html#range
---
---@field start LspPosition
---@field end LspPosition

local get_line_byte_from_position = vim.lsp.util._get_line_byte_from_position

---@class Range
---
--- Uses 1-based indices for lines and characters and is end-inclusive.
---
---@field start Position
---@field end Position
local Range = {}
Range.__index = Range

---@param range Range
---
---@return boolean
function Range:__eq(range)
  return self.start.line == range.start.line
    and self.start.character == range.start.character
    and self['end'].line == range['end'].line
    and self['end'].character == range['end'].character
end

--- Checks if a range contains another one
---
---@param range Range
---
---@return boolean
function Range:contains(range)
  local range_starts_after = self.start.line < range.start.line
    or (self.start.line == range.start.line and self.start.character <= range.start.character)
  local range_ends_before = range['end'].line < self['end'].line
    or (range['end'].line == self['end'].line and range['end'].character <= self['end'].character)

  return range_starts_after and range_ends_before
end

local M = {}

--- Creates a new range from each positions' indices.
---
---@param start_line number
---@param start_character number
---@param end_line number
---@param end_character number
---
---@return Range
function M.new(start_line, start_character, end_line, end_character)
  return setmetatable({
    start = { line = start_line, character = start_character },
    ['end'] = { line = end_line, character = end_character },
  }, Range)
end

--- Creates a new Range from an LspRange
---
--- LSP uses UTF indices to represent a character's position while Neovim uses bytes.
--- The buffer is required to be able to have the correct position in case of multibyte character in the line.
---
---@param lsp_range LspRange
---@param bufnr number
---
---@return Range
function M.from_lsp(bufnr, lsp_range)
  local range = M.new(
    lsp_range.start.line + 1,
    get_line_byte_from_position(bufnr, lsp_range.start) + 1,
    lsp_range['end'].line + 1,
    get_line_byte_from_position(bufnr, lsp_range['end'])
  )

  -- In LSP a end range character of zero means to select the previous line ending character(s)
  -- In Neovim it's represented by a very large number, see :h getpos()
  if 0 == range['end'].character then
    range['end'].line = range['end'].line - 1
    range['end'].character = 2147483647
  end

  return range
end

return M
