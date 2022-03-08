---@class Position
---@field line number #Line number (0-based)
---@field character number #Character position in the line (0-based)

---@class LspRange
---
---@field start Position
---@field end Position

---@class Range
---
--- Uses 0-based indices for lines as well as characters and is end-inclusive.
--- Follow the same rule as defined in LSP, see:
--- https://microsoft.github.io/language-server-protocol/specification.html#range
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

--- Creates a new Range from an LspRange table
---
---@param lsp_range LspRange
---
---@return Range
function M.from_table(lsp_range)
  return setmetatable(lsp_range, Range)
end

return M
