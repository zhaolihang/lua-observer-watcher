local uid = 0;

local Dep = class('Dep');

Dep.target = nil;

function Dep:ctor()
    self.id = uid++;
    self.subs = {};
end

function Dep:addSub(sub)
    table.insert(self.subs,sub)
end

function Dep:removeSub(sub)
    table.removebyvalue(self.subs,sub)
end

function Dep:depend()
    if Dep.target then
        Dep.target:addDep(self);
    end
end

function Dep:notify()
    local subs = table.unpack(self.subs);
    for _,cb in ipairs(subs) do
        cb.update();
    end
end


local targetStack = {};
local function pushTarget(_target) 
    if Dep.target then
        table.insert(targetStack,_target);
    end
    Dep.target = _target;
end
local function popTarget()
    Dep.target = table.remove(targetStack);
end
