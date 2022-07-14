assert(getgc, "missing dependency: getgc");

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
local ticket = 0;

-- locals
local new_vector2 = Vector2.new;

-- modules
local modules = {};
modules.network = require(replicated_first.ClientModules.Old.framework.network);
modules.values = require(replicated_first.SharedModules.SharedConfigs.PublicSettings);
modules.physics = require(replicated_first.SharedModules.Old.Utilities.Math.physics:Clone());

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
            local pos, visible = wtvp(camera, character.head.Position);
            pos = new_vector2(pos.X, pos.Y);

            local magnitude = (pos - mouse_pos(input_service)).Magnitude;
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
