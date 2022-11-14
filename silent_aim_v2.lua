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

local solve = debug.getupvalue(physics.trajectory, 1);

-- functions
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
        local tpObject = entry and entry._thirdPersonObject;
        local character = tpObject and tpObject._character;
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

-- Credits to integer, i'm terrible at math.
local function trajectory(dir, velocity, accel, speed)
    local roots = {solve(
        accel:Dot(accel) * 0.25,
        -accel:Dot(velocity),
        accel:Dot(dir) + velocity:Dot(velocity) - speed*speed,
        velocity:Dot(dir) * 2,
        dir:Dot(dir)
    )};

    for _, t in next, roots do
        if t and t > 0 then
            return 0.5*accel*t + dir/t + velocity, t;
        end
    end
end

-- hooks
local old;
old = hookfunction(particle.new, function(args)
    if args.onplayerhit and debug.getinfo(2).name == "fireRound" then
        local position, entry = getClosest();
        if position and entry then
            local index = table.find(debug.getstack(2), args.velocity);

            args.velocity = trajectory(
                position - args.position,
                entry._velspring.p,
                args.acceleration,
                args.velocity.Magnitude);

            debug.setstack(2, index, args.velocity);
        end
    end
    return old(args);
end);
