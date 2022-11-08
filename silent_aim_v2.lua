-- phantom forces silent aim
-- by mickey#3373, updated 11/07/22

-- settings
local targetedPart = "Head"; -- Head, Torso, Left Leg, etc.

-- services
local inputService = game:GetService("UserInputService");
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");

-- variables
local localplayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local shared = getrenv().shared;

-- modules
local particle = shared.require("particle");
local physics = shared.require("physics");
local values = shared.require("PublicSettings");
local repInterface = shared.require("ReplicationInterface");

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
    local closest = math.huge;
    local player, character;

    repInterface.operateOnAllEntries(function(plr, entry)
        local char = getCharacter(entry);
        if char and plr.Team ~= localplayer.Team then
            local screen, inBounds = worldToScreen(char[targetedPart].Position);
            local mouse = inputService:GetMouseLocation();
            local magnitude = (screen - mouse).Magnitude;

            if magnitude < closest and inBounds then
                closest = magnitude;
                player = plr;
                character = char;
            end
        end
    end);

    return player, character;
end

-- hooks
local old;
old = hookfunction(particle.new, function(args)
    if args.visualorigin then
        local player, character = getClosest();
        local part = character and character[targetedPart];
        if player and part then
            local bulletSpeed = args.velocity.Magnitude;
            local travelTime = (part.Position - args.position).Magnitude / bulletSpeed;

            args.velocity = physics.trajectory(
                args.position,
                values.bulletAcceleration,
                part.Position + part.Velocity * travelTime,
                bulletSpeed
            );

            debug.setupvalue(args.ontouch, 3, args.velocity);
        end
    end
    return old(args);
end);
