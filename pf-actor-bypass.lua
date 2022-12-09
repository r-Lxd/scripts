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
old = hookmetamethod(runService.Stepped, "__index", function(self, index)
    local indexed = old(self, index);
    if index == "ConnectParallel" and not checkcaller() then
        hookfunction(indexed, self.Connect);
    end
    return indexed;
end);

-- module destroy bypass
debug.setmetatable(getrenv().shared, {
    __newindex = function(_, index, value)
        if index == "close" and not checkcaller() then
            value = function() end;
        end
        return rawset(_, index, value);
    end
});
