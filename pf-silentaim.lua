assert(getrenv, "missing dependency: getrenv");

-- services
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local input_service = game:GetService("UserInputService");
local replicated_first = game:GetService("ReplicatedFirst");

-- variables
local camera = workspace.CurrentCamera;
local wtvp = camera.WorldToViewportPoint;
local mouse_pos = input_service.GetMouseLocation;
local localplayer = players.LocalPlayer;

-- modules
local shared = getrenv().shared;
local modules = {
    network = shared.require("network"),
    values = shared.require("PublicSettings"),
    replication = shared.require("replication"),
    physics = require(replicated_first.SharedModules.Old.Utilities.Math.physics:Clone())
};

-- functions
local function get_closest()
    local closest, player = math.huge, nil;
    for _, p in next, players:GetPlayers() do
        local character = modules.replication.getbodyparts(p);
        if character and p.Team ~= localplayer.Team then
            local pos, visible = wtvp(camera, character.head.Position);
            pos = Vector2.new(pos.X, pos.Y);

            local magnitude = (pos - mouse_pos(input_service)).Magnitude;
            if magnitude < closest then
                closest = magnitude;
                player = p;
            end
        end
    end
    return player;
end

local old = modules.network.send;
function modules.network:send(name, ...)
    local args = table.pack(...);
    if name == "newbullets" then
        local player = get_closest();
        local character = player and modules.replication.getbodyparts(player);
        local hitpart = character and character["head"];
        if player and character and hitpart then
            for _, bullet in next, args[1].bullets do
                bullet[1] = modules.physics.trajectory(args[1].firepos, modules.values.bulletAcceleration, hitpart.Position, bullet[1].Magnitude);
            end

            old(self, name, table.unpack(args));

            for _, bullet in next, args[1].bullets do
                old(self, "bullethit", player, hitpart.Position, hitpart.Name, bullet[2]);
            end

            return;
        end
    end
    if name == "bullethit" then
        return;
    end
    return old(self, name, table.unpack(args));
end
