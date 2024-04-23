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

    if not opts.skip_prev then
        local prev_pair = utils.get_pair(line:sub(col - 1, col - 1))
        if prev_pair then
            local md = utils.find_next(prev_pair, line, col, opts.behavior)
            if md then
                return log.debug(md, "prev pair")
            end
        end
    end

    local curr_pair = utils.get_pair(line:sub(col, col))
    if curr_pair then
        local prev = {
            pos = col,
            char = line:sub(col, col),
        }

        local md = {
            prev = prev,
            next = prev,
            pos = col + 1,
        }

        return log.debug(md, "curr pair")
    end
end

return tab
