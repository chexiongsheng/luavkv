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

local _value_to_version = setmetatable({}, {__mode = 'k'})

local make_folded_obj, folded_obj_mt, is_folded_obj, is_unfold_obj

--save the original table func
local original = {table = {}}
original.next = _G.next
original.pairs = _G.pairs
original.ipairs = _G.ipairs
for fun_name, fun in pairs(_G.table) do
    original.table[fun_name] = fun
end

local pairs = _G.pairs

local unfold_the_obj = function(obj)
    if is_unfold_obj(obj) then 
        return obj 
    end
    setmetatable(obj, nil)
    local target_obj = rawget(obj, '__target_obj')
    rawset(obj, '__target_obj', nil)
    --shallow copy of target_obj, and if a child is unfold, make a folded object of it 
    for k, v in pairs(target_obj) do
        if type(v) == 'table' then
            local av = rawget(obj, v)
            if av then 
                rawset(obj, k, av)
                rawset(obj, v, nil)
            else
                rawset(obj, k, make_folded_obj(v))
            end
        else
            rawset(obj, k, v)
        end
    end
    return obj
end

folded_obj_mt = {
    __index = function(t, k)
        local v = rawget(rawget(t, '__target_obj'), k)
        if type(v) == 'table' then
            local cv = rawget(t, v)
            if cv then
                v = cv
            else
                local nv = make_folded_obj(v)
                rawset(t, v, nv)
                v = nv
            end
        end
        return v
    end,
    __newindex = function(t, k, v)
        assert(type(k) ~= 'table')
        unfold_the_obj(t)[k] = v
    end
}

is_folded_obj = function(obj)
    return getmetatable(obj) == folded_obj_mt
end

is_unfold_obj = function(obj)
    return not is_folded_obj(obj)
end

local make_table_fun = function(org_fun)
    return function(t, ...)
        return org_fun(unfold_the_obj(t), ...)
    end
end
local intercepted = {table = {}}
for fun_name, fun in pairs(_G.table) do
    intercepted.table[fun_name] = make_table_fun(fun)
end
intercepted.next = make_table_fun(next)
intercepted.pairs = make_table_fun(pairs)
intercepted.ipairs = make_table_fun(ipairs)
local intercept_tbl_func = function()
    for fun_name, fun in pairs(_G.table) do
        _G.table[fun_name] = intercepted.table[fun_name]
    end
    _G.next = intercepted.next
    _G.pairs = intercepted.pairs
    _G.ipairs = intercepted.ipairs
end

make_folded_obj = function(obj)
    return is_folded_obj(obj) and obj or setmetatable({__target_obj = obj}, folded_obj_mt)
end


local function _merge(obj)
    local obj_modifyed = false

    for k, v in pairs(obj) do
        if type(k) == 'table' then
            local nv, bm = _merge(v)
            rawset(obj, k, nv)
            obj_modifyed = obj_modifyed or bm
        end
    end

    local target_obj = rawget(obj, '__target_obj')
    if obj_modifyed and target_obj then --merge change to target_obj
        --target_obj is normal obj
        assert(is_unfold_obj(target_obj))
        for k, v in pairs(target_obj) do
            local nv = rawget(obj, v)
            if nv then 
                rawset(target_obj, k, nv)
            end
        end
    end
    return (target_obj or obj), (obj_modifyed or target_obj == nil)
end

local put, set, set_test, get, remove, version_of, existed

put = function(version, key, value)
    assert(type(version) == 'number', 'version must be a number!') 
    assert(key ~= nil and type(key) ~= 'table' and type(key) ~= 'userdata', 'key must not be nil or ref type')
    assert(type(value) == 'table', 'value must be a table')
    if existed(key) then return false end
    _version_of[key] = version
    _value_of[key] = value
    _value_to_version[value] = version
    return true
end

--test if a version of key can set
set_test = function(key, value)
    assert(key ~= nil, 'key must not be nil')
    assert(type(key) ~= 'table' and type(key) ~= 'userdata', 'key must not be ref type')
    assert(type(value) == 'table', 'value must be a table')
    local version = _value_to_version[value]
    if not version then return false end
    local prev_ver = _version_of[key]
    return prev_ver == nil or (prev_ver + 1) == version
end

--version:version of kv pair
--return if success, boolean
set = function(key, value) 
    if not set_test(key, value) then return false end
    local version = assert(_value_to_version[value])
    _version_of[key] = version
    _value_of[key] = _merge(value)
    _value_to_version[value] = nil
    return true
end

--get a new copy
--return version, value, if not data, version is nil
get_copy = function(key) 
    assert(key)
    local version = _version_of[key]
    if version then
        local ret = make_folded_obj(_value_of[key])
        _value_to_version[ret] = version + 1
        return ret
    end
end

--remove the data(for memory saving)
remove = function(key)
    assert(key)
    if existed(key) then
        _value_to_version[_value_of[key]] = nil
        _version_of[key], _value_of[key] = nil, nil
    end
end

--for debug only
version_of = function(q)
    if type(q) == 'table' then
        return _value_to_version[q] 
    else
        return _version_of[q]
    end
end

existed = function(key)
    return _version_of[key] ~= nil
end

local M = {
    put = put,
    set = set,
    set_test = set_test,
    get_copy = get_copy,
    remove = remove,
    version_of = version_of,
    existed = existed,
    table_func = {
        original = original,
        next = intercepted.next,
        ipairs = intercepted.ipairs,
        pairs = intercepted.pairs,
        table = intercepted.table,
    },
    intercept_G = intercept_tbl_func,
}

--unsafe api, for inner usage only
M._raw_get = function(key) return _value_of[key] end
M._raw_get_all = function() return _value_of end
M._clear_up = function()
    _value_of = {}
    _version_of = {}
    _value_to_version = setmetatable({}, {__mode = 'k'})
end

return M

