local Dep = class('Dep');

Dep.target = nil;--Watcher

function Dep:ctor()
    self.subs = {}; --Array<Watcher>
end

function Dep:addSub(sub) -- call by Watcher
    table.insert(self.subs,sub)
end

function Dep:removeSub(sub) -- call by Watcher
    table.removebyvalue(self.subs,sub)
end

function Dep:depend() -- call by observe
    if Dep.target then
        Dep.target:addDep(self);
    end
end

function Dep:notify() -- call by observe
    local subs = shallowcopy(self.subs);
    for _,watcher in ipairs(subs) do
        watcher:update();
    end
end


local targetStack = {};
local function pushTarget(_target) -- call by Watcher
    if Dep.target then
        table.insert(targetStack,_target);
    end
    Dep.target = _target;
end
local function popTarget() -- call by Watcher
    Dep.target = table.remove(targetStack);
end

return {
    Dep = Dep;
    pushTarget = pushTarget;
    popTarget = popTarget;
}