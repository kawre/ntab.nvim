local utils = require("neotab.utils")
local log = require("neotab.logger")
local config = require("neotab.config")

---@class ntab.tab
local tab = {}

---@param lines string[]
---@param pos integer[]
---@param opts? ntab.out.opts
---
---@return ntab.md | nil
function tab.out(lines, pos, opts)
    opts = vim.tbl_extend("force", {
        ignore_beginning = false,
        behavior = config.user.behavior,
        skip_prev = false,
        backwards = false,
    }, opts or {})

    log.debug(opts, "tabout opts")
    log.debug(pos, "cursor pos")

    local line = lines[pos[1]]

    if not opts.ignore_beginning then
        local before_cursor = line:sub(0, pos[2])
        if vim.trim(before_cursor) == "" then
            return
        end
    end

    -- convert from 0 to 1 based indexing
    local col = pos[2] + 1
    local offset = opts.backwards and 0 or 1

    if not opts.skip_prev then
        local prev_char = line:sub(col - offset, col - offset)
        local prev_pair = utils.get_pair(prev_char)

        if prev_pair then
            local md = utils.find_next(prev_pair, line, col, opts)
            if md then
                return log.debug(md, "prev pair")
            end
        end
    end

    local curr_pos = opts.backwards and col - 1 or col
    local curr_char = line:sub(curr_pos, curr_pos)
    local curr_pair = utils.get_pair(curr_char)

    if curr_pair then
        local prev = {
            pos = curr_pos,
            char = curr_char,
        }

        local md = {
            prev = prev,
            next = prev,
            pos = curr_pos + offset,
        }

        return log.debug(md, "curr pair")
    end
end

return tab
