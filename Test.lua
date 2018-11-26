local Watcher = import('.Watcher',...);
local observe = import('.Observer',...).observe;

local data = {A = {3,2,1} };
local model = observe(data);

local watcher = Watcher.new(model,'A',function (vm, newV, oldV) 
    print(newV,oldV);
end,{sync = true});

model.A:sort();

model.A:pairs(function(k,v)
    print('*pairs: ',k,v);
end);

-- model:pairs(function(k,v)
--     print('*pairs: ',k,v);
-- end);
