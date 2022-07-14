assert(mousemoverel, "missing dependency: mousemoverel");

-- services
local players = game:GetService("Players");
local inputservice = game:GetService("UserInputService");
local runservice = game:GetService("RunService");
local workspace = game:GetService("Workspace");

-- variables
local camera = workspace.CurrentCamera;
local wtvp = camera.WorldToViewportPoint;
local localplayer = players.LocalPlayer;
local mouse_pos = inputservice.GetMouseLocation;
local curve = { player = nil, i = 0 };
local mouse_down = false;

-- functions
local function get_closest()
    local closest, player, position = math.huge, nil, nil;
    for _, p in next, players:GetPlayers() do
        local character = p.Character;
        if character and p.Team ~= localplayer.Team then
            local pos, visible = wtvp(camera, character.Head.Position);
            pos = Vector2.new(pos.X, pos.Y);

            local magnitude = (pos - mouse_pos(inputservice)).Magnitude;
            if magnitude < closest and visible then
                closest = magnitude;
                player = p;
                position = pos;
            end
        end
    end
    return player, position;
end

local function quad_bezier(t, p0, p1)
    local o0 = p0 + (p1 - p0) * Vector2.new(0.5, 0);
    return (1 - t)^2 * p0 + 2 * (1 - t) * t * o0 + t^2 * p1;
end

-- connections
inputservice.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        mouse_down = true;
    end
end);

inputservice.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        mouse_down = false;
    end
end);

runservice.Heartbeat:Connect(function()
    if mouse_down then
        local player, screen = get_closest();
        if player and player.Character then
            if curve.player ~= player or curve.i > 1 then
                curve = { player = player, i = 0 };
            end

            local mouse = mouse_pos(inputservice);
            local delta = quad_bezier(curve.i, mouse, screen) - mouse;
            mousemoverel(delta.X, delta.Y);

            curve.i += 0.025;
        end
    else
        curve = { player = nil, i = 0 };
    end
end);
