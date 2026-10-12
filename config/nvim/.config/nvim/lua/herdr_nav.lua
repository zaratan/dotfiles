local M = {}

local uv = vim.uv or vim.loop

local wincmds = { left = "h", down = "j", up = "k", right = "l" }

-- Talk to the Herdr socket directly: forking the 23MB CLI costs ~0.6ms of
-- main-thread time per hop, this costs ~0.005ms.
local function focus_herdr_pane(direction)
  local pipe = uv.new_pipe(false)
  if not pipe then
    return
  end
  local request = vim.json.encode({
    id = "nvim-herdr-nav",
    method = "pane.focus_direction",
    params = { direction = direction, pane_id = vim.env.HERDR_PANE_ID },
  }) .. "\n"
  pipe:connect(vim.env.HERDR_SOCKET_PATH, function(err)
    if err then
      pipe:close()
      return
    end
    pipe:write(request, function()
      pipe:close()
    end)
  end)
end

local function present(name)
  local value = vim.env[name]
  return value ~= nil and value ~= ""
end

function M.navigate(direction)
  local before = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(wincmds[direction])
  if vim.api.nvim_get_current_win() ~= before then
    return
  end
  if present("HERDR_SOCKET_PATH") then
    focus_herdr_pane(direction)
  end
end

return M
