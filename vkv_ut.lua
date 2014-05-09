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
    vkv.put(1, 'abcd', {
        b = {c = 1111}, 
        [5] = 1,
        x = {y = {z = 100}}
    })
end

function teardown()
    vkv._clear_up()
end
  
function test_index()
    local copy = vkv.get_copy('abcd')
    assert(rawget(copy, 'b') == nil)
    assert(rawget(rawget(copy, '__target_obj'), 'b'))
    assert(copy.b)
    assert(rawget(copy, 'b') == nil)
    assert(rawget(copy.b, 'c') == nil)
    assert_equal(copy.b.c, 1111)
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

function test_setnil2()
    local c1 = vkv.get_copy('abcd')
    assert_equal(c1[5], 1)
    c1[5] = nil
    assert_true(vkv.set('abcd', c1))
    local c2 = vkv.get_copy('abcd')
    assert(c2[5] == nil)
end

function test_level2set()
    local c1 = vkv.get_copy('abcd')
    assert_equal(c1.b.c, 1111)
    c1.b.c = 2222
    assert_true(vkv.set('abcd', c1))
    local c2 = vkv.get_copy('abcd')
    assert_equal(2222, c2.b.c)
end

function test_level2set2()
    local c1 = vkv.get_copy('abcd')
    c1.b.c = 2222
    local c2 = vkv.get_copy('abcd')
    c2.b.c = 3333
    assert_not_equal(c1.b.c, c2.b.c)
    assert_true(vkv.set('abcd', c1))
    assert_equal(2, vkv.version_of('abcd'))
    local c3 = vkv.get_copy('abcd')
    assert_equal(2222, c3.b.c)
end

function test_level3set()
    local c1 = vkv.get_copy('abcd')
    c1[5] = 3344
    c1.x.y.z = 5566
    assert_true(vkv.set('abcd', c1))
    local c2 = vkv.get_copy('abcd')
    assert_equal(3344, c2[5])
    assert_equal(5566, c2.x.y.z)
end


function test_settable()
    local c1 = vkv.get_copy('abcd')
    c1.e = {}
    c1.e.f = 10
    c1.g = {h=20}
    c1.i = {}
    assert_true(vkv.set('abcd', c1))
    local c2 = vkv.get_copy('abcd')
    assert_equal(c2.e.f, 10)
    assert_equal(c2.g.h, 20)
    assert(next(c2.i) == nil)
end

function test_settblkey()
    local c1 = vkv.get_copy('abcd')
    assert_error(function()
        c1[{}] = 1
    end)
end

