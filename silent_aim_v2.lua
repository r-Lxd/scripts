-- phantom forces silent aim
-- by mickey#3373, updated 11/14/22
-- credits: integer, wyvern
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
local solve = debug.getupvalue(physics.trajectory, 1);

-- functions
local function isVisible(position, ignore)
    return #camera:GetPartsObscuringTarget({ position }, ignore) == 0;
end

local function getClosest(dir, ignore)
    local _product = 1 - (fov or 180) / 90;
    local _position, _entry;

    replication.operateOnAllEntries(function(player, entry)
        local tpObject = entry and entry._thirdPersonObject;
        local character = tpObject and tpObject._character;
        if character and player.Team ~= localplayer.Team then
            local part = targetedPart == "Random" and
                character[math.random() > 0.5 and "Head" or "Torso"] or
                character[targetedPart or "Head"];

            if not (visibleCheck and not isVisible(part.Position, ignore)) then
                local product = dir:Dot((part.Position - camera.CFrame.p).Unit);
                if product > _product then
                    _product = product;
                    _position = part.Position;
                    _entry = entry;
                end
            end
        end
    end);

    return _position, _entry;
end

local function trajectory(dir, velocity, accel, speed)
    local roots = {solve(
        accel:Dot(accel) * 0.25,
        -accel:Dot(velocity),
        accel:Dot(dir) + velocity:Dot(velocity) - speed*speed,
        velocity:Dot(dir) * 2,
        dir:Dot(dir)
    )};

    for _, root in next, roots do
        if root > 0 then
            return 0.5*accel*root + dir/root + velocity, root;
        end
    end
end

-- hooks
local old;
old = hookfunction(particle.new, function(args)
    if args.onplayerhit and debug.getinfo(2).name == "fireRound" then
        local position, entry = getClosest(args.velocity.Unit, args.physicsignore);
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
