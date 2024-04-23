local api = vim.api
local config = require("neotab.config")
local log = require("neotab.logger")

---@class ntab.utils
local utils = {}

---@param x integer
---@param pos? integer[]
---@return string|nil
function utils.adj_char(x, pos)
    pos = pos or api.nvim_win_get_cursor(0)
    local col = pos[2] + x + 1

    local line = api.nvim_get_current_line()
    return line:sub(col, col)
end

function utils.tab()
    if config.user.act_as_tab then
        api.nvim_feedkeys(utils.replace("<Tab>"), "n", false)
    end
end

function utils.get_pair(char)
    if not char then
        return
    end

    local res = vim.tbl_filter(function(o)
        return o.close == char or o.open == char
    end, config.pairs)

    return not vim.tbl_isempty(res) and res[1] or nil
end

function utils.find_opening(info, line, col)
    if info.open == info.close then
        local idx = line:sub(1, col):reverse():find(info.open, 1, true)
        return idx and (#line - idx)
    end

    local c = 1
    for i = col, 1, -1 do
        local char = line:sub(i, i)

        if info.open == char then
            c = c - 1
        elseif info.close == char then
            c = c + 1
        end

        if c == 0 then
            return i
        end
    end
end

---@param info ntab.pair
---@param line string
---@param col integer
---@param backwards? boolean
---
---@return integer|nil
function utils.find_closing(info, line, col, backwards)
    if info.open == info.close then
        if backwards then
            for i = col - 1, 0, -1 do
                if line:sub(i, i) == info.close then
                    return i
                end
            end
            return
        else
            return line:find(info.close, col + 1, true)
        end
    end

    local start = backwards and col - 1 or col + 1
    local stop = backwards and 0 or #line
    local step = backwards and -1 or 1

    local c = 1
    for i = start, stop, step do
        local char = line:sub(i, i)

        if backwards then
            if info.close == char then
                c = c + 1
            elseif info.open == char then
                c = c - 1
            end
        else
            if info.open == char then
                c = c + 1
            elseif info.close == char then
                c = c - 1
            end
        end

        if c == 0 then
            return i
        end
    end
end

function utils.valid_pair(info, line, l, r, backwards)
    local start, stop, step
    if backwards then
        start, stop, step = r, l, -1
    else
        start, stop, step = l, r, 1
    end

    if info.open == info.close and line:sub(l, r):find(info.open, 1, true) then
        return true
    end

    local c = 1
    for i = l, r do
        local char = line:sub(i, i)

        if info.open == char then
            c = c + 1
        elseif info.close == char then
            c = c - 1
        end

        if c == 0 then
            return true
        end
    end

    return false
end

---@alias ntab.pos { cursor: integer, char: integer }

---@param info ntab.pair
---@param line string
---@param col integer
---@param opts ntab.out.opts
---
---@return integer | nil
function utils.find_next_nested(info, line, col, opts)
    local offset = opts.backwards and 0 or 1
    local char = line:sub(col - offset, col - offset)

    if info.open == info.close or info.close == char then
        local start = opts.backwards and col - 1 or col
        local stop = opts.backwards and 0 or #line
        local step = opts.backwards and -1 or 1

        for i = start, stop, step do
            char = line:sub(i, i)
            local char_info = utils.get_pair(char)

            if char_info then
                return i
            end
        end
    else
        local closing_idx = utils.find_closing(info, line, col - 2, opts.backwards)
        local first, start, stop, step

        if opts.backwards then
            start, stop, step = col - 1, closing_idx or 0, -1
        else
            start, stop, step = col, closing_idx or #line, 1
        end

        for i = start, stop, step do
            char = line:sub(i, i)
            local char_info = utils.get_pair(char)

            if char_info and char == char_info.open then
                first = first or i
                if utils.valid_pair(char_info, line, i + 1, stop) then
                    return i
                end
            end
        end

        return closing_idx or first
    end
end

---@param pair ntab.pair
---@param line string
---@param col integer
---@param opts ntab.out.opts
---
---@return integer|nil
function utils.find_next_closing(pair, line, col, opts)
    local open_char = line:sub(col - 1, col - 1)

    local i
    if pair.open == pair.close then
        i = line:find(pair.close, col, true) --
    elseif open_char ~= pair.close then
        i = utils.find_closing(pair, line, col) --
            or line:find(pair.close, col, true)
    end

    return i or utils.find_next_nested(pair, line, col, opts)
end

---@param pair ntab.pair
---@param line string
---@param col integer
---@param opts ntab.out.opts
---
---@return ntab.md | nil
function utils.find_next(pair, line, col, opts)
    local i

    if opts.behavior == "closing" then
        i = utils.find_next_closing(pair, line, col, opts)
    else
        i = utils.find_next_nested(pair, line, col, opts)
    end

    local offset = opts.backwards and 0 or 1

    if i then
        i = i + (opts.backwards and 1 or 0)

        local prev = {
            pos = col - offset,
            char = line:sub(col - offset, col - offset),
        }

        local next = {
            pos = i,
            char = line:sub(i, i),
        }

        return {
            prev = prev,
            next = next,
            pos = opts.backwards and math.min(col - 1, i) or math.max(col + 1, i),
        }
    end
end

---@param x? integer
---@param y? integer
function utils.set_cursor(x, y) --
    if not y or not x then
        local pos = api.nvim_win_get_cursor(0)
        x = x or (pos[2] + 1)
        y = y or (pos[1] + 1)
    end

    api.nvim_win_set_cursor(0, { y - 1, x - 1 })
end

---@param x integer
---@param y? integer
---@param pos? integer[]
function utils.move_cursor(x, y, pos)
    pos = pos or api.nvim_win_get_cursor(0)

    local line = pos[1] + (y or 0)
    local col = pos[2] + (x or 0)

    api.nvim_win_set_cursor(0, { line, col })

    return x
end

---@param str string
function utils.replace(str)
    return api.nvim_replace_termcodes(str, true, true, true)
end

function utils.map(mode, lhs, rhs, opts)
    local options = { noremap = true }

    if opts then
        options = vim.tbl_extend("force", options, opts)
    end

    api.nvim_set_keymap(mode, lhs, rhs, options)
end

return utils
