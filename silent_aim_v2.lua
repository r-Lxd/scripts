-- phantom forces silent aim
-- by mickey#3373, working 12/23/2022
-- https://v3rmillion.net/showthread.php?tid=1193218

-- variables
local localPlayer = game:GetService("Players").LocalPlayer;
local camera = game:GetService("Workspace").CurrentCamera;

-- modules
local newParticle; 
local operateOnAllEntries; 
local solve;

for _, object in next, getgc(false) do
    local name = debug.info(object, "n");
    local source = tostring(getfenv(object).script);

    if name == "new" and source == "particle" then
        newParticle = object;
    elseif name == "operateOnAllEntries" and source == "ReplicationInterface" then
        operateOnAllEntries = object;
    elseif name == "solve" and source == "physics" then
        solve = object;
    end
    
    if newParticle and operateOnAllEntries and solve then
        break;
    end
end

assert(newParticle and operateOnAllEntries and solve, "Failed to find module(s)");

-- functions
local function isVisible(position, ignore)
    return #camera:GetPartsObscuringTarget({ position }, ignore) == 0;
end

local function getClosest(dir, origin, ignore)
    local _angle = fov or 180;
    local _position, _entry;

    operateOnAllEntries(function(player, entry)
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

local function trajectory(dir, velocity, accel, speed)
    local r1, r2, r3, r4 = solve(
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

            args.velocity = trajectory(
                position - args.visualorigin,
                entry._velspring._p0,
                -args.acceleration,
                args.velocity.Magnitude);

            debug.setstack(2, index, args.velocity);
        end
    end
    return old(args);
end);
