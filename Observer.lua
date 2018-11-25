local Deps = require('Dep');
local Dep = Deps.Dep;
local Watcher = require('Watcher');

local function observe(original)

    if type(original) ~= 'table' then
        return original;
    end

    if rawget(original,'__is_proxy__') then
        return original;
    end

    if rawget(original,'__proxy__') then
        return rawget(original,'__proxy__');
    end

    local deps = {};
    for k,v in pairs(original) do
        deps[k] = Dep.new();
        original[k] = observe(v);
    end

    local proxy = {};
    rawset(proxy, '__is_proxy__', true);
    rawset(original, '__proxy__', proxy);

    function proxy:getn()
        return #original;
    end

    function proxy:pairs(fun)
        for k,v in pairs(original) do
            if v ~= proxy then
                if fun(k,v) then
                    break;
                end
            end
        end
    end

    function proxy:ipairs(fun)
        for k,v in ipairs(original) do
            if fun(k,v) then
                break;
            end
        end
    end

    -- function proxy:insert(...) -- 数组添加
    --     local args = {...};
    --     if #args==1 then
    --         table.insert(original,observe(args[1])); -- value
    --     else
    --         table.insert(original,args[1],observe(args[2]));-- pos,value
    --     end
    --     if tableDep then 
    --         tableDep:notify();
    --     end
    -- end
    -- function proxy:remove(...) -- 数组移除
    --     local ret = table.remove(original,...);
    --     if tableDep then 
    --         tableDep:notify();
    --     end
    --     return ret;
    -- end
    -- function proxy:sort(...) -- 数组排序
    --     table.sort(original,...);
    --     if tableDep then 
    --         tableDep:notify();
    --     end
    -- end

    -- core
    local __index = function(t,k) -- getter
        if Dep.target then
            if deps[k] == nil then
                deps[k] = Dep.new();
            end
            deps[k]:depend();
        end
        return original[k];
    end
    local __newindex = function(t,k,v) -- setter
        if deps[k] == nil then
            deps[k] = Dep.new();
        end
        local oldValue = original[k];
        local newValue = observe(v,deps[k]);
        if newValue ~= oldValue then
            original[k] = newValue;
            deps[k]:notify();
        end
    end
    local metatable = { __index = __index; __newindex = __newindex; }
    setmetatable(proxy,metatable);

    return proxy;
end

local data = {A = 1};
local model = observe(data);

local w = Watcher.new(model,'A',function (vm, newV, oldV) 
    print(newV,oldV);
end);

model.A = 11;

model:pairs(function(k,v)
    print('*pairs: ',k,v);
end);
