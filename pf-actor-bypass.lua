-- place id check
local placeId = game.PlaceId;
if placeId ~= 292439477 and placeId ~= 299659045 then
    return;
end

-- variables
local runService = game:GetService("RunService");
local replicatedFirst = game:GetService("ReplicatedFirst");

-- actor bypass
replicatedFirst.ChildAdded:Connect(function(instance)
    if instance:IsA("Actor") then
        while true do
            instance.ChildAdded:Wait();

            for _, child in next, instance:GetChildren() do
                child.Parent = replicatedFirst;
            end
        end
    end
end);

-- connect parallel bypass
local old;
old = hookmetamethod(runService.Stepped, "__index", function(self, index)
    local indexed = old(self, index);
    if index == "ConnectParallel" and not checkcaller() then
        hookfunction(indexed, newcclosure(function(signal, callback)
            return old(self, "Connect")(signal, function()
                return self:Wait() and callback();
            end);
        end));
    end
    return indexed;
end);

-- module destroy bypass
task.spawn(function()
    local shared = getrenv().shared;

    repeat task.wait() until shared.close;

    hookfunction(shared.close, function() end);
end);
