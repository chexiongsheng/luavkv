--
--------------------------------------------------------------------------------
--         FILE:  example.lua
--        USAGE:  ./example.lua 
--  DESCRIPTION:  
--      OPTIONS:  ---
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  John, <chexiongsheng@qq.com>
--      VERSION:  1.0
--      CREATED:  2014年05月07日 17时37分24秒 CST
--     REVISION:  ---
--------------------------------------------------------------------------------
--

local vkv = require 'vkv'
local key = 12345
print(vkv.existed(key)) --false
--init
print(vkv.put(1, key, {b = {c = 1111}, [5] = 1})) -- true
print(vkv.existed(key)) --true
local c1 = vkv.get_copy(key)
c1.d = 1000
local c2 = vkv.get_copy(key)
c2.d = 2000
print(vkv.set(key, c2)) --true
print(vkv.set(key, c1)) --false
local c3 = vkv.get_copy(key)
print(c3.d)  -- 2000
print(vkv.version_of(key)) --2
print(vkv.version_of(c3))  --3

