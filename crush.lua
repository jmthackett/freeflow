--- crush - The uncomplicated dependency system for LÖVE.
--
-- Author: Lorenzo Cogotti
-- Copyright: 2022 The DoubleFourteen Code Forge
-- Home: https://gitea.it/1414codeforge/crush
-- License: MIT

local io = require 'io'
local os = require 'os'

-- Lua version check

local function check_version()
    -- Generic Lua version check - 5.2 required
    if _VERSION then
        local maj, min = _VERSION:match("Lua (%d+)%.(%d+)")

        if maj and min then
            maj, min = tonumber(maj), tonumber(min)
            if maj > 5 or (maj == 5 and min >= 2) then
                return true
            end
        end
    end

    -- LuaJIT check - 2.0.0 required (technically 2.0.0_beta11)
    if jit and jit.version_num and jit.version_num >= 20000 then
        return true
    end

    return false
end

if not check_version() then
    error("Unsupported Lua version!\nSorry, crush requires Lua 5.2 or LuaJIT 2.0.0.")
end

-- System specific functions
--
-- Portions of this code are based on work from the LuaRocks project.
-- LuaRocks is free software and uses the MIT license.
--
-- LuaRocks website: https://luarocks.org
-- LuaRocks sources: https://github.com/luarocks/luarocks

local is_windows = package.config:sub(1,1) == "\\"

local is_directory
local Q
local quiet
local chdir
local mkdir

if is_windows then
    -- local
    function is_directory(path)
        local fh, _, code = io.open(path, 'r')

        if code == 13 then  -- directories return "Permission denied"
            fh, _, code = io.open(path.."\\", 'r')
            if code == 2 then  -- directories return 2, files return 22
                return true
            end
        end
        if fh then
            fh:close()
        end
        return false
    end

    local function split_path(s)
        local drive = ""
        local root = ""
        local rest

        local unquoted = s:match("^['\"](.*)['\"]$")
        if unquoted then
            s = unquoted
        end
        if s:match("^.:") then
            drive = s:sub(1, 2)
            s = s:sub(3)
        end
        if s:match("^[\\/]") then
            root = s:sub(1, 1)
            rest = s:sub(2)
        else
            rest = s
        end
        return drive, root, rest
    end

    -- local
    function Q(s)
        local drive, root, rest = split_path(s)
        if root ~= "" then
            s = s:gsub("/", "\\")
        end
        if s == "\\" then
            return '\\' -- CHDIR needs special handling for root dir
        end

        -- URLs and anything else
        s = s:gsub('\\(\\*)"', '\\%1%1"')
        s = s:gsub('\\+$', '%0%0')
        s = s:gsub('"', '\\"')
        s = s:gsub('(\\*)%%', '%1%1"%%"')
        return '"'..s..'"'
    end

    -- local
    function quiet(cmd)
        return cmd.."  2> NUL 1> NUL"
    end

    -- local
    function chdir(newdir, cmd)
        local drive = newdir:match("^([A-Za-z]:)")

        cmd = "cd "..Q(newdir).." & "..cmd
        if drive then
            cmd = drive.." & "..cmd
        end
        return cmd
    end

    -- local
    function mkdir(path)
        local cmd = "mkdir "..Q(path).." 2> NUL 1> NUL"

        os.execute(cmd)
        if not is_directory(path) then
            error("Couldn't create directory '"..path.."'.")
        end
    end
else
    -- local
    function is_directory(path)
        local fh, _, code = io.open(path.."/.", 'r')

        if code == 2 then   -- "No such file or directory"
            return false
        end
        if code == 20 then  -- "Not a directory", regardless of permissions
            return false
        end
        if code == 13 then  -- "Permission denied", but is a directory
            return true
        end
        if fh then
            _, _, code = fh:read(1)
            fh:close()
            if code == 21 then  -- "Is a directory"
                return true
            end
        end
        return false
    end

    -- local
    function Q(s)
        return "'"..s:gsub("'", "'\\''").."'"
    end

    -- local
    function quiet(cmd)
        return cmd.." >/dev/null 2>&1"
    end

    -- local
    function chdir(newdir, cmd)
        return "cd "..Q(newdir).." && "..cmd
    end

    -- local
    function mkdir(path)
        local cmd = "mkdir "..Q(path).." >/dev/null 2>&1"

        os.execute(cmd)
        if not is_directory(path) then
            error("Couldn't create directory '"..path.."'.")
        end
    end
end

-- Dependency fetch

local function fetch(dep)
    local dest = 'lib/'..dep.name

    print(("Dependency %s -> %s (%s)"):format(dep.name, dest, dep.url))

    local cmd, fullcmd

    if is_directory(dest) then
        -- Directory exists, pull operation
        cmd = "git pull"
        fullcmd = chdir(dest, quiet("git pull"))
    else
        -- Directory doesn't exist, clone operation
        cmd = "git clone "..Q(dep.url).." "..Q(dep.name)
        fullcmd = chdir("lib", quiet(cmd))
    end

    -- On success, os.execute() returns:
    -- true on regular Lua
    -- 0 on LuaJIT (actual OS error code)
    local code = os.execute(fullcmd)
    if code ~= true and code ~= 0 then
        error(dep.name..": Dependency fetch failed ("..cmd..").")
    end
end

-- .lovedeps file scan

local function map_file(name)
    local fh = io.open(name, 'r')
    if fh == nil then
        error(name..": can't read file.")
    end

    local contents = fh:read('*all')
    fh:close()

    return contents
end

local function scandeps(manifest, mode, deps)
    mode = mode or 'nodups'
    deps = deps or {}

    local contents = map_file(manifest)
    contents = "return "..contents

    local fun, res = load(contents, manifest, 't', {})
    if not fun then
        error(res)
    end

    local ok, def = pcall(fun)
    if not ok then
        error(def)  -- def is now pcall()'s error message
    end
    if type(def) ~= 'table' then
        error("[string \""..manifest.."\"]: Loading resulted in a '"..type(def).."', while 'table' was expected.")
    end

    for name,url in pairs(def) do
        if type(url) == 'function' then
            goto skip  -- ignore functions
        end

        if type(url) ~= 'string' then
            error("[string \""..manifest.."\"]: "..name..": git repository URL must be a 'string'.")
        end

        for i in ipairs(deps) do
            if name == deps[i].name then
                if mode == 'skipdups' then
                    goto skip
                end

                error("[string \""..manifest.."\"]: "..name..": Duplicate dependency.")
            end
        end

        deps[#deps+1] = { name = name, url = url }

        ::skip::
    end

    return deps
end

-- Entry point

local function file_exists(name)
    local fh = io.open(name, 'r')
    if fh ~= nil then
        fh:close()

        return true
    end

    return false
end

local function run()
    local deps = scandeps(".lovedeps")

    mkdir("lib")

    -- NOTE: deps array may grow while scanning
    local i = 1
    while i <= #deps do
        local dep = deps[i]

        -- Fetch dependency
        fetch(dep)

        -- Resolve dependency's dependencies
        local depmanifest = "lib/"..dep.name.."/.lovedeps"

        if file_exists(depmanifest) then
            scandeps(depmanifest, 'skipdups', deps)
        end

        i = i + 1
    end
end

run()
