local Deps = require('Dep');
local Dep = Deps.Dep;
local pushTarget = Deps.pushTarget;
local popTarget = Deps.popTarget;

local function segmentsPath(path)
    local segments = string.split(path, '.')
    return segments;
end

local function getObjBySegments(obj, segments)
    for _,v in ipairs(segments) do
        if obj == nil then
            return nil;
        end
        obj = obj[v];
    end
    return obj;
end

local function parsePath(path)
    local segments = segmentsPath(path);
    return function(self,obj)
        return getObjBySegments(obj, segments);
    end
end

local Watcher = class('Watcher');

function Watcher:ctor(vm,expOrFn,cb)
    if rawget(vm,'_watchers') == nil then
        rawset(vm,'_watchers',{})
    end
    table.insert(rawget(vm,'_watchers'),self);

    self.vm = vm;
    self.cb = cb;
    self.deps = {};

    if type(expOrFn) == 'function' then
        self.getter = expOrFn;
    else
        self.getter = parsePath(expOrFn);
        if self.getter == nil then
            self.getter = function () end;
        end
    end

    self.value = self:get();
end

function Watcher:get()
    pushTarget(self);
    local value = self.getter(self.vm, self.vm);
    popTarget();
    return value;
end

function Watcher:addDep(dep)
    dep:addSub(self);
    table.insert(self.deps,dep);
end

function Watcher:update()
    self:run();
end

function Watcher:run()
    local oldValue = self.value;
    local value = self:get();
    self.value = value;
    self.cb(self.vm, value, oldValue);
end

function Watcher:depend()
    for _,v in ipairs(self.deps) do
        v:depend();
    end
end

function Watcher:teardown()
    for _,v in ipairs(self.deps) do
        v:removeSub(self);
    end
end

return Watcher;