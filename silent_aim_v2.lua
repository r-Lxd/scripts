-- phantom forces silent aim
-- by mickey#3373, updated 11/15/2022
-- https://v3rmillion.net/showthread.php?tid=1193218

-- variables
local players = game:GetService("Players");
local localplayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local shared = getrenv().shared;

-- modules
local physics = shared.require("physics");
local particle = shared.require("particle");
local replication = shared.require("ReplicationInterface");
local solve = debug.getupvalue(physics.timehit, 2);

-- functions
local function isVisible(position, ignore)
    return #camera:GetPartsObscuringTarget({ position }, ignore) == 0;
end

local function getClosest(dir, origin, ignore)
    local _angle = fov or math.huge;
    local _position, _entry;

    replication.operateOnAllEntries(function(player, entry)
        local tpObject = entry and entry._thirdPersonObject;
        local character = tpObject and tpObject._character;
        if character and player.Team ~= localplayer.Team then
            local part = targetedPart == "Random" and
                character[math.random() > 0.5 and "Head" or "Torso"] or
                character[targetedPart or "Head"];

            if not (visibleCheck and not isVisible(part.Position, ignore)) then
                local dotProduct = dir:Dot((part.Position - origin).Unit);
                local angle = math.deg(math.acos(dotProduct));
                if angle < _angle then
                    _angle = angle;
                    _position = part.Position;
                    _entry = entry;
                end
            end
        end
    end);

    return _position, _entry;
end

local function trajectory(dir, velocity, accel, speed)
    local t1, t2, t3, t4 = solve(
        accel:Dot(accel) * 0.25,
        accel:Dot(velocity),
        accel:Dot(dir) + velocity:Dot(velocity) - speed^2,
        dir:Dot(velocity) * 2,
        dir:Dot(dir));

    local time = (t1>0 and t1) or (t2>0 and t2) or (t3>0 and t3) or t4;
    local bullet = (dir + velocity*time + 0.5*accel*time^2) / time;
    return bullet, time;
end

-- hooks
local old;
old = hookfunction(particle.new, function(args)
    if args.onplayerhit and debug.getinfo(2).name == "fireRound" then
        local position, entry = getClosest(
            args.velocity.Unit,
            args.visualorigin,
            args.physicsignore);

        if position and entry then
            local index = table.find(debug.getstack(2), args.velocity);

            args.velocity = trajectory(
                position - args.visualorigin,
                entry._velspring.p,
                -args.acceleration,
                args.velocity.Magnitude);

            debug.setstack(2, index, args.velocity);
        end
    end
    return old(args);
end);
