-- phantom forces silent aim
-- by mickey#3373, updated 11/07/22

-- services
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local inputService = game:GetService("UserInputService");

-- variables
local shared = getrenv().shared;
local localplayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;

-- modules
local physics = shared.require("physics");
local particle = shared.require("particle");
local replication = shared.require("ReplicationInterface");

-- functions
local function getCharacter(entry)
    local character = entry and entry._thirdPersonObject;
    return character and character._character;
end

local function worldToScreen(position)
    local screen = worldtoscreen and
        worldtoscreen({ position })[1] or
        camera:WorldToViewportPoint(position);
    return Vector2.new(screen.X, screen.Y), screen.Z > 0, screen.Z;
end

local function getClosest()
    local _priority = fov or math.huge;
    local _part, _entry;

    replication.operateOnAllEntries(function(player, entry)
        local character = getCharacter(entry);
        if character and player.Team ~= localplayer.Team then
            local part = character[targetedPart or "Head"];
            local screen, inBounds = worldToScreen(part.Position);
            local center = camera.ViewportSize * 0.5;

            local priority = (screen - center).Magnitude;
            if priority < _priority and inBounds then
                _priority = priority;
                _part = part;
                _entry = entry;
            end
        end
    end);

    return _part, _entry;
end

-- hooks
local old;
old = hookfunction(particle.new, function(args)
    if args.onplayerhit and not checkcaller() then
        local part, entry = getClosest();
        if part and entry then
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
