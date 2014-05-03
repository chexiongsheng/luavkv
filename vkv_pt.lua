--
--------------------------------------------------------------------------------
--         FILE:  vkv_pt.lua
--        USAGE:  ./vkv_pt.lua 
--  DESCRIPTION:  
--      OPTIONS:  ---
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  John, <chexiongsheng@qq.com>
--      COMPANY:  guangqi,shenzhen
--      VERSION:  1.0
--      CREATED:  2014年05月03日 10时39分12秒 CST
--     REVISION:  ---
--------------------------------------------------------------------------------
--
local function rndstr(num)
    local str = 'abcdefghijklmnhopqrstuvwxyz' --默认是全小写，你也可加入其他大写字母

    local ret =''
    for i=1 ,num do --根据长度生成字符串
        local rchr = math.random(1,string.len(str))
        ret = ret .. string.sub(str, rchr, rchr)
    end

    return ret
end

local function shallowcopy(obj)
    local ret = {}
    for k, v in pairs(obj) do
        ret[k] = v
    end
    return ret
end

local function valuecopy(obj)
    local ret = {}
    for k, v in pairs(obj) do
        ret[k] = type(v) == 'table' and {} or v
    end
    return ret
end

local function deepcopy(orig) -- used by cycle()
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

local vkv = require 'vkv'


local key_num = assert(tonumber(arg[1]), 'USEAGE:luajit '..arg[0]..' key_num [testcase]')
local test_data = {}
for i = 1, key_num do
    local t = math.random(4)
    local key = rndstr(10)
    if t == 1 then
        test_data[key] = {}
    elseif t == 2 then
        test_data[key] = rndstr(20)
    elseif t == 3 then
        test_data[key] = math.random(100)
    else
        test_data[key] = math.random(2) == 1 and true or false
    end
end

vkv.set(1, 'abcd', test_data)

local loop_times = 1000 * 1000 

local test = {
    get_copy = function()
        for i = 1, loop_times do
            assert(vkv.get_copy('abcd'))
        end
    end,
    unfold = function()
        for i = 1, loop_times do
            local v, c = vkv.get_copy('abcd')
            c[1] = 3121231
        end
    end,
    unfold1 = function()
        for i = 1, loop_times do
            local v, c = vkv.get_copy('abcd')
            c[1] = 3121231
            c[2] = 3121231
        end
    end,
    --for comparetion begin
    msgpack = function() 
        require 'util'
        require 'msgpack_lua'
        local pkg_max_len = 102400
        local pkg_buff = malloc(pkg_max_len)
        for i = 1, loop_times do
            msgpack.pack_b(pkg_buff, pkg_max_len, test_data)
        end
    end,
    shallowcopy = function()
        for i = 1, loop_times do
            shallowcopy(test_data)
        end
    end,
    deepcopy = function()
        for i = 1, loop_times do
            deepcopy(test_data)
        end
    end,
    valuecopy = function()
        for i = 1, loop_times do
            valuecopy(test_data)
        end
    end,
    --for comparetion end
}

if test[arg[2]] then
    print('testcase:'..arg[2])
    test[arg[2]]()
end



