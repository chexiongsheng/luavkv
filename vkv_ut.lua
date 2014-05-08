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
vkv.intercept_G() --make pairs, ipairs, next, table.each etc. intercepted

module( "base", package.seeall, lunit.testcase )

function setup()
    vkv.put(1, 'abcd', {b = {c = 1111}, [5] = 1})
end

function teardown()
    vkv._clear_up()
end
  
function test_unfoldbyget()
    local copy = vkv.get_copy('abcd')
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
    local copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    copy.e = 2222
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
    assert(copy.e == 2222)
end

function test_unfoldbypairs()
    local copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    for k, v in pairs(copy) do end
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_unfoldbyipairs()
    local copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    for k, v in ipairs(copy) do end
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_unfoldbynext()
    local copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    next(copy)
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_unfoldbytblfunc()
    local copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    assert_equal(table.maxn(copy), 5)
    assert(rawget(copy, 'b'))
    assert(rawget(copy, '__target_obj') == nil)
end

function test_twoversion()
    local c1 = vkv.get_copy('abcd')
    local c2 = vkv.get_copy('abcd')
    assert_not_equal(c1, c2)
    c1.e = 2000
    c2.e = 3000
    assert_equal(c1.e, 2000)
    assert_true(vkv.set_test('abcd', c1))
    assert_true(vkv.set_test('abcd', c2))
    vkv.set('abcd', c2)
    assert_false(vkv.set_test('abcd', c1))
    assert_false(vkv.set('abcd', c1))
    local c3 = vkv.get_copy('abcd')
    assert_equal(c3.e, 3000)
    c3.b.c = 3333
    assert_true(vkv.set('abcd', c3))
    local c4 = vkv.get_copy('abcd')
    assert_equal(c4.b.c, 3333)
end

function test_compress()
    local c1 = vkv.get_copy('abcd')
    c1.e = 1000
    vkv.set('abcd', c1)
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
    local c1 = vkv.get_copy('abcd')
    c1.e = 1000
    vkv.set('abcd', c1)
    local c2 = vkv.get_copy('abcd')
    c2.e = 2000
    vkv.set('abcd', c2)
    local c3 = vkv.get_copy('abcd')
    assert_equal(c1.e, 1000)
    assert_equal(c3.e, 2000)
end

function test_param1()
    assert_error_match('key must not be nil', function() vkv.set() end)
    assert_error_match('key must not be ref type', function() vkv.set({}, {}) end)
    assert_error_match('value must be a table', function() vkv.set('a11', '3214') end)
end

function test_existed()
    assert_true(vkv.existed('abcd'))
    assert_false(vkv.existed(1234))
    vkv.put(1, 1234, {})
    assert_true(vkv.existed(1234))
end

function test_setnil()
    local c1 = vkv.get_copy('abcd')
    assert(c1.b)
    c1.b = nil
    assert_true(vkv.set('abcd', c1))
    local c2 = vkv.get_copy('abcd')
    assert(c2.b == nil)
end

