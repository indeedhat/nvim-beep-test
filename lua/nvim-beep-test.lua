-- global import
local api = vim.api

local M = {}

-- plugin import
local utils = require 'nvim-treesitter.ts_utils'
local parsers = require 'nvim-treesitter.parsers'

-- plugin scoped vars
local debug_mode = false
local highlight_group = "BeepTest"
local highlight_namespace = api.nvim_create_namespace('beep-test')
local parser_cache = {}
local test_active = false
local current_highlight = {}

vim.cmd([[highlight default BeepTest guibg=red]])


-- @private
--
-- Print when in debug_mode
local function debug(text)
    if debug_mode then
        print(text)
    end
end

-- @private
--
-- Remove any existing highlights for the beep test plugin
--
-- @param buffer_no number of current buffer
local function remove_highlight(buffer_no)
    api.nvim_buf_clear_namespace(buffer_no, highlight_namespace, 0, -1)
end

-- @private
--
-- Highlight a range of text that the uer has to jump to/delete
--
-- @param from tulple (line, column)
-- @param to tulple (line, column)
local function highlight_range(buffer_no, from, to)
    remove_highlight(buffer_no)
    current_highlight = {
        from[1],
        from[2],
        to[1],
        to[2]
    }
    vim.highlight.range(buffer_no, highlight_namespace, highlight_group, from, to)
end


-- @private
--
-- parse the current buffer text using treesitter
--
-- @param buffer_no the current bufer number
-- @param filetype
--
-- @return tresitter node list
local function create_new_parser(buffer_no, filetype)
    if not parsers.has_parser(filetype) then
        return nil
    end

    return parsers.get_parser(buffer_no, filetype)
end

-- @private
--
-- Get the appropriate parser for the given buffer
--
-- If there is no parser in the cache then a new one is generated and cached
--
-- @param buffer_no
--
-- @return treesitter parser
local function get_parser(buffer_no)
    local filetype = vim.bo.filetype

    if parser_cache[buffer_no] ~= nil
        and parser_cache[buffer_no].filetype == filetype
    then
        return parser_cache[buffer_no].parser
    end

    local parser = create_new_parser(buffer_no, filetype)
    if parser ~= nil then
        parser_cache[buffer_no] = {
            filetype = filetype,
            parser = parser,
        }
    end

    return parser
end

-- @private
--
-- Get a flat table of tall the nodes in the current buffer
--
-- @param root tree
-- @param results table
--
-- @return table
local function flatten_node(root, results)
    results = results or {}

    for node, field in root:iter_children() do
        if node:type() ~= '\n' then
            local entry = { node:range() }
            table.insert(entry, node:type())

            table.insert(results, entry)
            flatten_node(node, results)
        end
    end

    return results
end

-- @private 
--
-- select a random node from the node list
--
-- @param parser
--
-- @return table
local function random_ts_node(parser)
    local ast  = parser:parse()
    local root = ast[1]:root()

    local flat = flatten_node(root, nil)

    math.randomseed(os.time())
    return flat[math.random(#flat)]
end


-- @privete
local function loop()
    if not test_active then
        return
    end

    local buffer_no = api.nvim_get_current_buf()
    local parser    = get_parser(buffer_no)

    if parser == nil then
        return
    end

    local node_range = random_ts_node(parser)

    local flash_on = function()
        highlight_range(
            buffer_no,
            { node_range[1], node_range[2] },
            { node_range[3], node_range[4] }
        )
    end

    local flash_off = function()
        remove_highlight(buffer_no)
    end

    debug(string.format(
        "Highlight: row(%d, %d) col(%d, %d) type(%s)",
        node_range[1],
        node_range[2],
        node_range[3],
        node_range[4],
        node_range[5]
    ))

    flash_on()
    vim.defer_fn(flash_off, 200)
    vim.defer_fn(flash_on, 300)
    vim.defer_fn(flash_off, 400)
    vim.defer_fn(flash_on, 500)
    vim.defer_fn(flash_off, 700)
    vim.defer_fn(flash_on, 800)
end

-- @private
--
-- Check if the cursor is in the range of the current highlight
local function cursor_in_highlight_range()
if current_highlight == nil then
        return false
    end

    local line, col = unpack(api.nvim_win_get_cursor(0))
    line = line - 1

    local start_line, start_col, end_line, end_col = unpack(current_highlight)

    debug(string.format(
        "Cursor Move: cursor(%d, %d) row(%d, %d) col(%d, %d)",
        line,
        col,
        start_line,
        start_col,
        end_line,
        end_col
    ))

    if line >= start_line and line <= end_line then
        if line == start_line and line == end_line then
            return col >= start_col and col < end_col
        elseif line == start_line then
            return col >= start_col
        elseif line == end_line then
            return col < end_col
        else
            return true
        end
    else
        return false
    end
end

-- start the beep test
function M.start(enable_debug)
    local buffer_no = api.nvim_get_current_buf()
    test_active     = true
    debug_mode      = enable_debug or false

    vim.cmd(string.format(
        "autocmd CursorMoved <buffer=%d> lua require'nvim-beep-test'.on_move()", 
        buffer_no
    ))

    loop()
end

-- stop the beep test
function M.stop()
    test_active = false
end

-- called when the cursor is moved
--
-- if the cursor is in the current highlight range then the next highlight will be triggered
function M.on_move()
    if not test_active then
        return
    elseif #current_highlight == 0 then
        return
    end

    if cursor_in_highlight_range() then
        loop()
    end
end

return M
