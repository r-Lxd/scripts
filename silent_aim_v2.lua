-- phantom forces silent aim
-- by mickey#3373, updated 11/07/22
-- https://v3rmillion.net/showthread.php?tid=1193218

-- variables
local players = game:GetService("Players");
local localplayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local ignoreList = {
    workspace.Terrain,
    workspace.Players,
    workspace.Ignore
};

-- modules
local shared = getrenv().shared;
local physics = shared.require("physics");
local particle = shared.require("particle");
local replication = shared.require("ReplicationInterface");

-- functions
local function getCharacter(entry)
    local tpObject = entry and entry._thirdPersonObject;
    return tpObject and tpObject._character;
end

local function worldToScreen(position)
    local screen = worldtoscreen and
        worldtoscreen({ position })[1] or
        camera:WorldToViewportPoint(position);
    return Vector2.new(screen.X, screen.Y), screen.Z > 0, screen.Z;
end

local function isVisible(...)
    return #camera:GetPartsObscuringTarget({ ... }, ignoreList) == 0;
end

local function getClosest()
    local _magnitude = fov or math.huge;
    local _position, _entry;

    replication.operateOnAllEntries(function(player, entry)
        local character = getCharacter(entry);
        if character and player.Team ~= localplayer.Team then
            local part = targetedPart == "Random" and
                character[math.random() > 0.5 and "Head" or "Torso"] or
                character[targetedPart or "Head"];

            if not (visibleCheck and not isVisible(part.Position)) then
                local screen, inBounds = worldToScreen(part.Position);
                local magnitude = (screen - camera.ViewportSize * 0.5).Magnitude;
                if magnitude < _magnitude and inBounds then
                    _magnitude = magnitude;
                    _position = part.Position;
                    _entry = entry;
                end
            end
        end
    end);

    return _position, _entry;
end

-- hooks
local old;
old = hookfunction(particle.new, function(args)
    if args.onplayerhit and debug.getinfo(2).name == "fireRound" then
        local position, entry = getClosest();
        if position and entry then
            local bulletSpeed = args.velocity.Magnitude;
            local travelTime = (position - args.position).Magnitude / bulletSpeed;
            local index = table.find(debug.getstack(2), args.velocity);

            args.velocity = physics.trajectory(
                args.position,
                args.acceleration,
                position + entry._velspring.p * travelTime,
                bulletSpeed);

            debug.setstack(2, index, args.velocity);
        end
    end
    return old(args);
end);
