--
--------------------------------------------------------------------------------
--         FILE:  ut_vkv.lua
--        USAGE:  ./ut_vkv.lua 
--  DESCRIPTION:  
--      OPTIONS:  ---
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  John, <chexiongsheng@qq.com>
--      COMPANY:  guangqi,shenzhen
--      VERSION:  1.0
--      CREATED:  2014年05月03日 05时44分15秒 CST
--     REVISION:  ---
--------------------------------------------------------------------------------
--

require 'lunit'
local vkv = require 'vkv'

module( "base", package.seeall, lunit.testcase )

function setup()
    vkv.set(1, 'abcd', {b = {c = 1111}, [5] = 1})
end

function teardown()
    vkv._clear_up()
end
  
function test_unfoldbyget()
    local ver, copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    assert(copy.b)
    assert(rawget(copy, 'b'))
    assert(rawget(copy.b, 'c') == nil)
    assert(copy.b.c == 1111)
    assert(rawget(copy, '__target_obj') == nil)
    assert(rawget(copy.b, '__target_obj') == nil)
end

function test_unfoldbyset()
    local ver, copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    copy.e = 2222
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
    assert(copy.e == 2222)
end

function test_unfoldbypairs()
    local ver, copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    for k, v in pairs(copy) do end
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_unfoldbyipairs()
    local ver, copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    for k, v in ipairs(copy) do end
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_unfoldbynext()
    local ver, copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    next(copy)
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_unfoldbytblfunc()
    local ver, copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    assert_equal(table.maxn(copy), 5)
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_twoversion()
    local v1, c1 = vkv.get_copy('abcd')
    local v2, c2 = vkv.get_copy('abcd')
    assert_equal(v1, v2)
    assert_not_equal(c1, c2)
    c1.e = 2000
    c2.e = 3000
    assert_equal(c1.e, 2000)
    assert_true(vkv.set_test(v1, 'abcd'))
    assert_true(vkv.set_test(v2, 'abcd'))
    vkv.set(v2, 'abcd', c2)
    assert_false(vkv.set_test(v1, 'abcd'))
    assert_false(vkv.set(v1, 'abcd', c1))
    local v3, c3 = vkv.get_copy('abcd')
    assert(v3 == v1 + 1)
    assert_equal(c3.e, 3000)
    c3.b.c = 3333
    assert_true(vkv.set(v3, 'abcd', c3))
    local v4, c4 = vkv.get_copy('abcd')
    assert_equal(c4.b.c, 3333)
end

function test_compress()
    local v1, c1 = vkv.get_copy('abcd')
    c1.e = 1000
    vkv.set(v1, 'abcd', c1)
    local cr1 = vkv._raw_get('abcd')
    assert(rawget(cr1, 'b'))
    assert(rawget(cr1.b, '__target_obj'))
    vkv.compress('abcd')
    local cr2 = vkv._raw_get('abcd')
    assert(rawget(cr2, 'b'))
    assert(rawget(cr2.b, '__target_obj') == nil)
    assert_equal(cr2.e, 1000)
    assert_equal(cr2.b.c, 1111)
end

function test_ver_over_ver()
    local v1, c1 = vkv.get_copy('abcd')
    c1.e = 1000
    vkv.set(v1, 'abcd', c1)
    local v2, c2 = vkv.get_copy('abcd')
    c2.e = 2000
    vkv.set(v2, 'abcd', c2)
    local v3, c3 = vkv.get_copy('abcd')
    assert_equal(c1.e, 1000)
    assert_equal(c3.e, 2000)
end

function test_param1()
    assert_error_match('version must be a number', function() vkv.set("fda", "fdaf", {}) end)
    assert_error_match('key must not be nil or ref type', function() vkv.set(1, {}, {}) end)
    assert_error_match('value must be a table', function() vkv.set(1, 'a11', '3214') end)
end


