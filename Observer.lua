
local Observer = class('Observer');

function Observer:ctor(value)
    self.value = value;
end

local function observe(original)

    if type(original) ~= 'table' then
        return original;
    end

    if rawget(original,'__observer__') then
        return original;
    end
    
    local proxy = {};
    rawset(proxy, '__observer__', true);

    for key,value in pairs(original) do
        original[key] = observe(value);
    end

    function proxy:getn()
        return #original;
    end

    function proxy:pairs(fun)
        for key,value in pairs(original) do
            if fun(key,value) then
                break;
            end
        end
    end

    function proxy:ipairs(fun)
        for key,value in ipairs(original) do
            if fun(key,value) then
                break;
            end
        end
    end

    function proxy:insert(...) --数组添加
        local args = {...};
        if #args==1 then
            table.insert(original,observe(args[1])); --value
        else
            table.insert(original,args[1],observe(args[2]));--pos,value
        end
        --notify
    end

    function proxy:remove(...) --数组移除
        local ret = table.remove(original,...);
        --notify
        return ret;
    end

    function proxy:sort(...) --数组排序
        table.sort(original,...);
        --notify
    end

    -- core
    local __index = function(t,k) --getter
        return original[k];
    end
    local __newindex = function(t,k,v) --setter
        original[k] = observe(v);
        --notify
    end
    local metatable = { __index = __index; __newindex = __newindex; }
    setmetatable(proxy,metatable);

    return proxy;
end

local data = {A = 1};
local model = observe(data);

model.A = 11;
model.B = 22;

model:insert(1,'byinsert')
model:insert('byinsert')
model:insert('byinsert')

model:pairs(function(key,value)
    print('*pairs: ',key,value);
end);

model:ipairs(function(key,value)
    print('*ipairs: ',key,value);
end);