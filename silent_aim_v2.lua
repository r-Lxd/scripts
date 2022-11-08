-- phantom forces silent aim
-- by mickey#3373, updated 11/07/22

-- services
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local inputService = game:GetService("UserInputService");

-- variables
local shared = getrenv().shared;
local hitpart = getgenv().targetedPart or "Head";
local localplayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;

-- modules
local physics = shared.require("physics");
local particle = shared.require("particle");
local replication = shared.require("ReplicationInterface");

-- functions
local function getCharacter(entry)
    local charObject = entry and entry:getThirdPersonObject();
    if charObject then
        return charObject:getCharacterModel();
    end
end

local function worldToScreen(position)
    local screen = worldtoscreen and
        worldtoscreen({ position })[1] or
        camera:WorldToViewportPoint(position);
    return Vector2.new(screen.X, screen.Y), screen.Z > 0, screen.Z;
end

local function getClosest()
    local highestPriority = math.huge;
    local player, character, entry;

    replication.operateOnAllEntries(function(plr, plrEntry)
        local char = getCharacter(plrEntry);
        if char and plr.Team ~= localplayer.Team then
            local screen, inBounds, depth = worldToScreen(char[hitpart].Position);
            local mouse = inputService:GetMouseLocation();
            local priority = (screen - mouse).Magnitude + depth;

            if priority < highestPriority and inBounds then
                highestPriority = priority;
                player = plr;
                character = char;
                entry = plrEntry;
            end
        end
    end);

    return player, character, entry;
end

-- hooks
local old;
old = hookfunction(particle.new, function(args)
    if args.onplayerhit and not checkcaller() then
        local player, character, entry = getClosest();
        local part = character and character[hitpart];
        if player and part and entry then
            local bulletSpeed = args.velocity.Magnitude;
            local travelTime = (part.Position - args.position).Magnitude / bulletSpeed;

            args.velocity = physics.trajectory(
                args.position,
                args.acceleration,
                part.Position + entry._velspring.p * travelTime,
                bulletSpeed);
            debug.setupvalue(args.ontouch, 3, args.velocity);
        end
    end
    return old(args);
end);
