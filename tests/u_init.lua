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

--- Works with Unix like paths only

local get_clone_cmd = function(user, name, install_path)
    local cmd = {
        "git",
        "clone",
        "--depth=1",
        "https://github.com/" .. user .. "/" .. name .. ".git",
        install_path,
    }
    return table.concat(cmd, " ")
end

function M.install(plugin, directory)
    local user, name = plugin:match("([^/]+)/([^/]+)$")
    local install_path = directory .. "/" .. name
    if not vim.loop.fs_stat(install_path) then
        print("Installing " .. plugin .. " to " .. directory)
        os.execute("mkdir -p " .. directory)
        os.execute(get_clone_cmd(user, name, install_path))
    end
end

function M.setup()
    vim.cmd([[set rtp=$VIMRUNTIME]])
    vim.opt.packpath = { Path.root(".tests/site") }
    vim.env.XDG_CONFIG_HOME = Path.root(".tests/config")
    vim.env.XDG_DATA_HOME = Path.root(".tests/data")
    vim.env.XDG_STATE_HOME = Path.root(".tests/state")
    vim.env.XDG_CACHE_HOME = Path.root(".tests/cache")

    vim.opt.runtimepath:prepend(Path.root(".tests/site"))
    vim.opt.runtimepath:prepend(Path.root(".tests/config/nvim"))
    local install_path = Path.root(".tests/site/pack/deps/start")
    M.install("nvim-lua/plenary.nvim", install_path)
end

M.setup()
