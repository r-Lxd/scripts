local placeId = game.PlaceId;
if placeId == 292439477 or placeId == 299659045 then
    -- variables
    local runService = game:GetService("RunService");
    local replicatedFirst = game:GetService("ReplicatedFirst");

    -- actor bypass
    replicatedFirst.ChildAdded:Connect(function(instance)
        if instance:IsA("Actor") then
            replicatedFirst.ChildAdded:Wait();

            local container = Instance.new("Folder");
            container.Name = instance.Name;
            container.Parent = instance.Parent;

            for _, child in next, instance:GetChildren() do
                child.Parent = container;
            end

            instance.Parent = nil;
        end
    end);

    -- connect parallel bypass
    local old; 
    old = hookmetamethod(runService.Heartbeat, "__index", function(self, index)
        if index == "ConnectParallel" and not checkcaller() then
            index = "Connect";
        end
        return old(self, index);
    end);

    -- module-destroy bypass
    setmetatable(getrenv().shared, {
        __newindex = function(self, index, value)
            if index == "close" then
                value = function() end;
            end
            return rawset(self, index, value);
        end
    });
end
