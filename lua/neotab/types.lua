---@alias ntab.info { pos: integer, char: string }

---@alias ntab.pair { open: string, close: string }

---@class ntab.out.opts
---@field ignore_beginning? boolean
---@field behavior? ntab.behavior
---@field skip_prev? boolean
---@field backwards? boolean

---@alias ntab.behavior
---| "nested"
---| "closing"

---@class ntab.md
---@field prev ntab.info
---@field next ntab.info
---@field pos integer

---@class ntab.trigger
---@field pairs ntab.pair[]
---@field format? string
---@field cond? string
---@field ft? string[]
