local debug_mode = false
local M = {}

-- Print when in debug_mode
--
-- @param text the text to print
-- @param ... varags used for string formatting
function M.print(text, ...)
    if not debug_mode then
        return
    end

    if #arg > 0 then
        text = string.format(text, unpack(...))
    end

    print(text)
end

-- enable/disable debug mode
--
-- @param enabled
function M.enable(enabled)
    debug_mode = enabled
end

return M
