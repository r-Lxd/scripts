-- variables
local runService = game:GetService("RunService");
local replicatedFirst = game:GetService("ReplicatedFirst");

local placeId = game.PlaceId;
if placeId == 292439477 or placeId == 299659045 then
    -- connect parallel bypass
    local old; 
    old = hookmetamethod(runService.Heartbeat, "__index", function(_, index)
        return old(_, (index == "ConnectParallel" and not checkcaller()) and "Connect" or index);
    end);
    -- actor bypass
    replicatedFirst.ChildAdded:Connect(function(instance)
       if instance:IsA("Actor") then
           replicatedFirst.ChildAdded:Wait();
     
           local container = Instance.new("Folder");
           for _, child in next, instance:GetChildren() do
               child.Parent = container;
           end
     
           container.Name = instance.Name;
           container.Parent = instance.Parent;
     
           instance.Parent = nil;
       end
    end);
end
