-- phantom forces undetected silent aim
-- by mickey#3373, updated 11/07/22

-- settings
local targetedPart = "head"; -- head, torso, larm, rarm, lleg, rleg

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
    if not entry then return; end
    local thirdPerson = entry:getThirdPersonObject();
    if not thirdPerson then return; end
    return thirdPerson:getCharacterHash();
end

local function worldToScreen(position)
    local screen, inBounds = camera:WorldToViewportPoint(position);
    return Vector2.new(screen.X, screen.Y), inBounds, screen.Z;
end

local function getClosest()
    local closest = math.huge;
    local player, character;

    repInterface.operateOnAllEntries(function(plr, entry)
        local char = getCharacter(entry);
        if char and plr.Team ~= localplayer.Team then
            local screen = worldToScreen(char[targetedPart].Position);
            local mouse = inputService:GetMouseLocation();
            local magnitude = (screen - mouse).Magnitude;

            if magnitude < closest then
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
            local velocity = physics.trajectory(
                args.position,
                values.bulletAcceleration,
                part.Position,
                args.velocity.Magnitude
            );

            args.velocity = velocity;
            debug.setupvalue(args.ontouch, 3, velocity);
        end
    end
    return old(args);
end);
