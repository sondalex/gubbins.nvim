local Path = {}
Path.dirname = function(filepath)
	local dir = filepath:match("(.*/)")
	return string.gsub(dir, "/$", "")
end
Path.parent = function(filepath)
	local dir = filepath:match("(.*/)")
	return string.gsub(dir, "/$", "")
end

function Path.root(path)
	local file = debug.getinfo(1, "S").source:sub(2)
	local folder = Path.dirname(file)
	local parent = Path.parent(folder)
	if path then
		if path:sub(-1, -1) == "/" then
			path = path:sub(1, -2)
		end
		return parent .. "/" .. path
	end
	return parent
end

local M = {}
function M.setup()
	vim.cmd([[set rtp=$VIMRUNTIME]])

	vim.opt.packpath = { Path.root(".tests/site") }
	vim.env.XDG_CONFIG_HOME = Path.root(".tests/config")
	vim.env.XDG_DATA_HOME = Path.root(".tests/data")
	vim.env.XDG_STATE_HOME = Path.root(".tests/state")
	vim.env.XDG_CACHE_HOME = Path.root(".tests/cache")
	vim.opt.runtimepath:prepend(Path.root(".tests/site"))
	vim.opt.runtimepath:prepend(Path.root(".tests/config/nvim"))
	vim.opt.runtimepath:append(".")
	vim.opt.runtimepath:append(Path.root(".tests/site/pack/deps/start/plenary.nvim"))
end

M.setup()
