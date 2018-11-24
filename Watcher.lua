
local function watch(original)
    local proxy = {};

    local index = function(t,k)
        print("*access to element " .. tostring(k));
        return original[k];
    end
    local newindex = function(t,k,v)
        print("*update to element " .. tostring(k) .. " to " .. tostring(v));
        original[k] =v;
    end

    local metatable = { __index = index; __newindex = newindex; }
    setmetatable(proxy,metatable);

    --需要重写:
    -- table
    -- table.concat
    -- table.insert
    -- table.move
    -- table.pack
    -- table.remove
    -- table.sort
    -- table.unpack
    function proxy:pairs(fun)
        for key,value in pairs(original) do
            index(original,key);
            if fun(key,value) then
                return;
            end
        end
    end

    function proxy:ipairs(fun)
        for key,value in ipairs(original) do
            index(original,key);
            if fun(key,value) then
                return;
            end
        end
    end

    function proxy:getn()
        return #original;
    end

    function proxy:concat(...)
        local ret = table.concat(original,...);
        return ret;
    end
    function proxy:insert(...)
        local ret = table.insert(original,...);
        return ret;
    end
    function proxy:move(...)
        local ret = table.move(original,...);
        return ret;
    end
    function proxy:pack(...)
        local ret = table.pack(original,...);
        return ret;
    end
    function proxy:remove(...)
        local ret = table.remove(original,...);
        return ret;
    end
    function proxy:sort(...)
        local ret = table.sort(original,...);
        return ret;
    end
    function proxy:unpack(...)
        local ret = table.unpack(original,...);
        return ret;
    end
    return proxy;
end

local orimodel = {A = 1};
local model = watch(orimodel);

model.A = 11;
model.B = 2;

table.insert(model,'byinsert')
table.insert(model,'byinsert')


print('*model.getn: ',model.getn());
model:pairs(function(key,value)
    print('*pairs: ',key,value);
end);


model:pairs(function(key,value)
    print('*pairs: ',key,value);
    return true;
end);

model:ipairs(function(key,value)
    print('*ipairs: ',key,value);
end);

table.remove(model,1)