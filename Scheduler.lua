local MAX_UPDATE_COUNT = 100;
local queue = {}; -- array

local has = {};
local circular = {};

local waiting = false;
local flushing = false;
local index = 1; -- flushingSchedulerQueueIndex

local resetSchedulerState;
local resetSchedulerState;
local queueWatcher;
local nextTickHandler;
local nextTick;

resetSchedulerState = function ()
    index = 1;
    queue = {};
    has = {};
    circular = {};
    waiting = false;
    flushing = false;
end

flushSchedulerQueue = function ()
    flushing = true;

    table.sort(function(a,b)
        return a.id - b.id;
    end)

    index = 1;
    while index <= #queue do
        local watcher = queue[index];
        has[watcher] = nil;

        watcher:run();

        if has[watcher] then
            circular[watcher] = (circular[watcher] or 0) + 1;
            if circular[watcher] > MAX_UPDATE_COUNT then
                -- error('circulard update!');
                break;
            end
        end

        index = index + 1;
    end

    resetSchedulerState();
end

queueWatcher = function (watcher)
    if not has[watcher] then
        has[watcher] = true;
        if not flushing then
           table.insert(queue,watcher);
        else
            local i = #queue;
            while i > index and queue[i].id > watcher.id do
                i = i - 1;
            end
            table.insert(queue,i + 1,watcher);
        end
        if not waiting then
            waiting = true;
            nextTick(flushSchedulerQueue);
        end
    end
end

local timerFun = function() end;
local function setTimerFun(v)
    timerFun = v;
end
local function getTimerFun()
    return timerFun;
end

local callbacks = {}; -- array
local pending = false;

nextTickHandler = function ()
    pending = false;
    local copies = clone(callbacks);
    callbacks = {};
    for _,v in ipairs(copies) do
        v();
    end
end

nextTick = function (cb)
    table.insert(callbacks,function()
        if cb then
            cb();
        end
    end)

    if not pending then
        pending = true;
        timerFun(nextTickHandler);
    end
end


return {
    queueWatcher = queueWatcher;
    setTimerFun = setTimerFun;
}