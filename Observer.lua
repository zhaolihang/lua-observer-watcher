local Dep = import('.Dep',...).Dep;

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
    local function getDep(k)
        if deps[k] == nil then
            deps[k] = Dep.new();
        end
        return deps[k];
    end
    for k,v in pairs(original) do
        getDep(k);
        original[k] = observe(v);
    end

    local proxy = {};
    local tableDep = Dep.new();
    rawset(proxy, '__is_proxy__', true);
    rawset(proxy, '__dep__', tableDep);
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

    function proxy:copy()
        local ret = {};
        self:pairs(function(k,v)
            if type(v) == 'table' then
                ret[k] = v:copy();
            else
                ret[k] = v;
            end
        end);
        return ret;
    end

    function proxy:insert(...) -- 数组添加
        local args = {...};
        if #args==1 then
            table.insert(original,observe(args[1])); -- value
        else
            table.insert(original,args[1],observe(args[2]));-- pos,value
        end
        tableDep:notify();
    end
    function proxy:remove(...) -- 数组移除
        local ret = table.remove(original,...);
        tableDep:notify();
        return ret;
    end
    function proxy:sort(...) -- 数组排序
        table.sort(original,...);
        tableDep:notify();
    end

    -- core
    local __index = function(t,k) -- getter
        if Dep.target then
            getDep(k):depend();
            if type(original[k]) == 'table' then
                local childTableDep = rawget(original[k], '__dep__');
                childTableDep:depend();
            end
        end
        return original[k];
    end
    local __newindex = function(t,k,v) -- setter
        local oldValue = original[k];
        local newValue = observe(v);
        if newValue ~= oldValue then
            original[k] = newValue;
            getDep(k):notify();
            tableDep:notify();
        end
    end
    local metatable = { __index = __index; __newindex = __newindex; }
    setmetatable(proxy,metatable);

    return proxy;
end


return {
    observe = observe;
};