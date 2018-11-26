local Deps = import('.Dep',...);
local pushTarget = Deps.pushTarget;
local popTarget = Deps.popTarget;
local queueWatcher = import('.Scheduler').queueWatcher;

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
    return function(obj)
        return getObjBySegments(obj, segments);
    end
end

local uid = 0;
local Watcher = class('Watcher');

function Watcher:ctor(vm,expOrFn,cb,options)

    if not rawget(vm,'__is_proxy__') then
        error('vm not a proxy!'); 
    end

    if options then
        self.sync = options.sync or false;
    else
        self.sync = false;
    end

    uid = uid + 1;
    self.id = uid;
    self.active = true;
    self.vm = vm;
    self.cb = cb;
    self.deps = {};
    self.newDeps = {};

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
    local value = self.getter(self.vm);
    popTarget();
    self:cleanupDeps();
    return value;
end

function Watcher:addDep(dep) -- call by Dep
    if not self.newDeps[dep] then
        self.newDeps[dep] = true;
        if not self.deps[dep] then
            self.deps[dep] = true;
            dep:addSub(self);
        end
    end
end


function Watcher:cleanupDeps() -- private
    for dep,_ in pairs(self.deps) do
        if not self.newDeps[dep] then
            dep:removeSub(self);
        end
    end
    self.deps = self.newDeps;
    self.newDeps = {};
end

function Watcher:update() -- call by Dep
    if self.sync then
        self:run();
    else
        queueWatcher(self);
    end
end

function Watcher:run()
    if self.active then
        local newValue = self:get();
        local oldValue = self.value;
        if newValue ~= oldValue or type(newValue) == 'table' then
            self.value = newValue;
            self.cb(self.vm, newValue ,oldValue);
        end
    end
end

function Watcher:teardown()
    if self.active then
        for dep,_ in pairs(self.deps) do
            dep:removeSub(self);
        end
        self.deps = {};
        self.active = false;
    end
end

return Watcher;