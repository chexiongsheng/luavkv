--
--------------------------------------------------------------------------------
--         FILE:  vkv.lua
--        USAGE:  ./vkv.lua 
--  DESCRIPTION:  key-value store with version number
--      OPTIONS:  ---
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  John, <chexiongsheng@qq.com>
--      COMPANY:  guangqi,shenzhen
--      VERSION:  1.0
--      CREATED:  2014年04月24日 17时37分19秒 CST
--     REVISION:  ---
--------------------------------------------------------------------------------
--

local _version_of = {}

local _value_of = {}

local make_folded_obj, folded_obj_mt, is_folded_obj, is_unfold_obj

local unfold_the_obj = function(obj)
    if is_unfold_obj(obj) then 
        return obj 
    end
    setmetatable(obj, nil)
    local target_obj = rawget(obj, '__target_obj')
    rawset(obj, '__target_obj', nil)
    --shallow copy of target_obj, and if a child is unfold, make a folded object of it 
    for k, v in pairs(target_obj) do
        obj[k] = (type(v) == 'table' and is_unfold_obj(v)) and make_folded_obj(v) or v
    end
    return obj
end

folded_obj_mt = {
    __index = function(t, k)
        return unfold_the_obj(t)[k]
    end,
    __newindex = function(t, k, v)
        unfold_the_obj(t)[k] = v
    end
}

is_folded_obj = function(obj)
    return getmetatable(obj) == folded_obj_mt
end

is_unfold_obj = function(obj)
    return not is_folded_obj(obj)
end

--intercep the table functions begin
local make_table_fun = function(org_fun)
    return function(t, ...)
        return org_fun(unfold_the_obj(t), ...)
    end
end

local org_next = _G.next
local org_pairs = _G.pairs
local org_ipairs = _G.ipairs
local org_table = {}
for fun_name, fun in org_pairs(_G.table) do
    org_table[fun_name] = fun
    _G.table[fun_name] = make_table_fun(fun)
end
_G.next = make_table_fun(next)
_G.pairs = make_table_fun(pairs)
_G.ipairs = make_table_fun(ipairs)
--intercep the table functions end

make_folded_obj = function(obj)
    return is_folded_obj(obj) and obj or setmetatable({__target_obj = obj}, folded_obj_mt)
end

--make obj to raw table
local _compress
_compress = function(tbl)
    if is_folded_obj(tbl) then --folded_obj, just return __target_obj
        tbl = rawget(tbl, '__target_obj')
    end
    for k, v in org_pairs(tbl) do
        if type(v) == 'table' then
            tbl[k] = _compress(v) --m
        end
    end
    return tbl
end

local set, set_test, get, remove, version_of, existed

--test if a version of key can set
set_test = function(version, key)
    assert(type(version) == 'number', 'version must be a number!') 
    assert(key ~= nil and type(key) ~= 'table' and type(key) ~= 'userdata', 'key must not be nil or ref type')
    local prev_ver = _version_of[key]
    return prev_ver == nil or (prev_ver + 1) == version
end

--version:version of kv pair
--return if success, boolean
set = function(version, key, value) 
    assert(type(value) == 'table', 'value must be a table')
    if not set_test(version, key) then return false end
    _version_of[key] = version
    if is_unfold_obj(value) then --accessed
        _value_of[key] = value
    end
    return true
end

--get a new copy
--return version, value, if not data, version is nil
--bcompress:if do the compression 
get_copy = function(key) 
    assert(key)
    local version = _version_of[key]
    if version then
        return (version + 1), make_folded_obj(_value_of[key])
    end
end

local compress = function(key)
    assert(key)
    if _version_of[key] then
        _value_of[key] = _compress(_value_of[key]) 
    end
end

--remove the data(for memory saving)
remove = function(key)
    assert(key)
    _version_of[key], _value_of[key] = nil, nil
end

--for debug only
version_of = function(key)
    return _version_of[key]
end

existed = function(key)
    return _version_of[key] ~= nil
end

local M = {
    set = set,
    set_test = set_test,
    get_copy = get_copy,
    compress = compress,
    remove = remove,
    version_of = version_of,
    existed = existed,
    original_func = {
        pairs = org_pairs,
        ipairs = org_ipairs,
        next = org_next,
        table = org_table,
    }
}

--unsafe api, for inner usage only
M._raw_get = function(key) return _value_of[key] end
M._raw_get_all = function() return _value_of end
M._clear_up = function()
    _value_of = {}
    _version_of = {}
end

return M

