luavkv
======

key-value store with version number

###usage:  
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


