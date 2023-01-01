-- phantom forces silent aim
-- by mickey#3373, working 12/23/2022
-- https://v3rmillion.net/showthread.php?tid=1193218

-- check for parameter sent through syn.run_on_actor. allows silent aim to be ran without a bypass in auto execute
local param = ...

if syn and typeof(syn) == 'table' and syn.run_on_actor and param ~= "Spoorloos" then
    local framework = game:GetService("ReplicatedFirst"):FindFirstChild("Framework", true)
    
    if framework and framework.Parent:IsA("Actor") then
        return syn.run_on_actor(framework.Parent, game:HttpGet("https://raw.githubusercontent.com/Spoorloos/scripts/main/silent_aim_v2.lua"), "Spoorloos")
    end
end

-- variables
local localPlayer = game:GetService("Players").LocalPlayer;
local camera = game:GetService("Workspace").CurrentCamera;

-- modules
local newParticle, loopEntries, solveQuartic;
local garbageCollection = getgc(false);

for i = 1, #garbageCollection do
    local object = garbageCollection[i];
    local source, name = debug.info(object, "sn");
    local script = string.match(source, "%w+$");

    if name == "new" and script == "particle" then
        newParticle = object;
    elseif name == "operateOnAllEntries" and script == "ReplicationInterface" then
        loopEntries = object;
    elseif name == "solve" and script == "physics" then
        solveQuartic = object;
    end
    
    if newParticle and loopEntries and solveQuartic then
        break;
    end
end

assert(newParticle and loopEntries and solveQuartic, "Failed to find module(s)");

-- functions
local function isVisible(position, ignore)
    return #camera:GetPartsObscuringTarget({ position }, ignore) == 0;
end

local function getClosest(dir, origin, ignore)
    local _angle = fov or 180;
    local _position, _entry;

    loopEntries(function(player, entry)
        local tpObject = entry and entry._thirdPersonObject;
        local character = tpObject and tpObject._character;
        if character and player.Team ~= localPlayer.Team then
            local part = character[targetedPart == "Random" and
                (math.random() < (headChance or 0.5) and "Head" or "Torso") or
                (targetedPart or "Head")];

            local position = part.Position +
                (part.Size * 0.5 * (math.random() * 2 - 1)) * (randomization or 0);

            if not (visibleCheck and not isVisible(position, ignore)) then
                local dot = dir.Unit:Dot((position - origin).Unit);
                local angle = 180 - (dot + 1) * 90;
                if angle < _angle then
                    _angle = angle;
                    _position = position;
                    _entry = entry;
                end
            end
        end
    end);

    return _position, _entry;
end

local function getTrajectory(dir, velocity, accel, speed)
    local r1, r2, r3, r4 = solveQuartic(
        accel:Dot(accel) * 0.25,
        accel:Dot(velocity),
        accel:Dot(dir) + velocity:Dot(velocity) - speed^2,
        dir:Dot(velocity) * 2,
        dir:Dot(dir));

    local time = (r1>0 and r1) or (r2>0 and r2) or (r3>0 and r3) or r4;
    local bullet = 0.5*accel*time + dir/time + velocity;
    return bullet, time;
end

-- hooks
local old;
old = hookfunction(newParticle, function(args)
    if debug.info(2, "n") == "fireRound" then
        local position, entry = getClosest(args.velocity, args.visualorigin, args.physicsignore);
        if position and entry then
            local index = table.find(debug.getstack(2), args.velocity);

            args.velocity = getTrajectory(
                position - args.visualorigin,
                entry._velspring._p0,
                -args.acceleration,
                args.velocity.Magnitude);

            debug.setstack(2, index, args.velocity);
        end
    end
    return old(args);
end);
