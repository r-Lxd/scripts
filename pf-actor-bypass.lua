-- variables
local runService = game:GetService("RunService");
local replicatedFirst = game:GetService("ReplicatedFirst");
-- place id check
if game.PlaceId == 292439477 then
    -- connect parallel bypass
    local old; 
    old = hookmetamethod(runService.Heartbeat, "__index", function(_, index)
        return old(_, index == "ConnectParallel" and "Connect" or index);
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
