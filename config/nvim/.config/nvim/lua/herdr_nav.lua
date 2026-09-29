local M = {}

local uv = vim.uv or vim.loop

local wincmds = { left = "h", down = "j", up = "k", right = "l" }
local tmux_flags = { left = "-L", down = "-D", up = "-U", right = "-R" }

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

-- Kept for the tmux/Herdr cohabitation: .tmux.conf still hands C-hjkl to vim
-- through its is_vim test, so vim has to know how to hand it back.
local function focus_tmux_pane(direction)
  local cmd = { "tmux", "select-pane" }
  local pane = vim.env.TMUX_PANE
  if pane and pane ~= "" then
    table.insert(cmd, "-t")
    table.insert(cmd, pane)
  end
  table.insert(cmd, tmux_flags[direction])
  pcall(vim.system, cmd)
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
  -- Herdr first: when both are around, it is the innermost multiplexer.
  if present("HERDR_SOCKET_PATH") then
    focus_herdr_pane(direction)
  elseif present("TMUX") then
    focus_tmux_pane(direction)
  end
end

return M
