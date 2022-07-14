assert(getgc, "missing dependency: getgc");

-- services
local players = game:GetService("Players");
local inputservice = game:GetService("UserInputService");
local workspace = game:GetService("Workspace");
local replicatedfirst = game:GetService("ReplicatedFirst");

-- variables
local camera = workspace.CurrentCamera;
local localplayer = players.LocalPlayer;
local ticket = 0;

-- modules
local modules = {};
modules.values = require(replicatedfirst.SharedModules.SharedConfigs.PublicSettings);
modules.network = require(replicatedfirst.ClientModules.Old.framework.network);
modules.physics = require(replicatedfirst.SharedModules.Old.Utilities.Math.physics:Clone());

for _, v in next, getgc(true) do
    if type(v) == "table" then
        if rawget(v, "getbodyparts") then
            modules.replication = v;
        elseif rawget(v, "gammo") then
            modules.gamelogic = v;
        end
    end
end

-- functions
local function get_closest()
    local closest, player = math.huge, nil;
    for _, p in next, players:GetPlayers() do
        local character = modules.replication.getbodyparts(p);
        if character and p.Team ~= localplayer.Team then
            local pos, visible = camera:WorldToViewportPoint(character.head.Position);
            pos = Vector2.new(pos.X, pos.Y);

            local magnitude = (pos - inputservice:GetMouseLocation()).Magnitude;
            if magnitude < closest and visible then
                closest = magnitude;
                player = p;
            end
        end
    end
    return player;
end

local old = modules.network.send;
function modules.network.send(self, name, ...)
    local args = table.pack(...);
    if name == "newbullets" then
        local gun = modules.gamelogic.currentgun;
        local data = gun and gun.data;
        if gun and data then
            local player = get_closest();
            local character = modules.replication.getbodyparts(player);
            if player and character then
                local hitpart = character.head;

                for _, bullet in next, args[1].bullets do
                    bullet[1] = modules.physics.trajectory(args[1].firepos, modules.values.bulletAcceleration, hitpart.Position, data.bulletspeed);
                    bullet[2] = ticket;

                    ticket += 1;
                end

                old(self, name, table.unpack(args));

                for _, bullet in next, args[1].bullets do
                    old(self, "bullethit", player, hitpart.Position, hitpart.Name, bullet[2]);
                end

                return;
            end
        end
    end
    return old(self, name, table.unpack(args));
end
