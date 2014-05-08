luavkv
======

key-value store with version number

## Usage

### Basics

```lua
local vkv = require 'vkv'  
local key = 12345  
print(vkv.existed(key)) --false  
--init a value, paramters: version-key-value, that is why this lib named vkv
print(vkv.put(1, key, {b = {c = 1111}, [5] = 1})) -- true  
print(vkv.existed(key)) --true  
local c1 = vkv.get_copy(key)  
c1.d = 1000  
local c2 = vkv.get_copy(key)  
c2.d = 2000  
print(vkv.set(key, c2)) --true  
print(vkv.set(key, c1)) --false  
print(vkv.set_test(key, c1)) --false  
local c3 = vkv.get_copy(key)  
print(c3.d)  -- 2000  
print(vkv.version_of(key)) --2
print(vkv.version_of(c3))  --3
```

### Intercept the table functions

```lua
local vkv = require 'vkv'
local key = 12345
vkv.put(1, key, {b = {c = 1111}, [5] = 1}) -- true

local c = vkv.get_copy(key)

for k in pairs(c) do
    print(k)
end
--output:
--    __target_obj

vkv.intercept_G() --make pairs, ipairs, next, table.each etc. intercepted
for k in pairs(c) do
    print(k)
end
--output:
--    b
--    5
```
