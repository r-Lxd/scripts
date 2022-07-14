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
local is_mouse_pressed = inputservice.IsMouseButtonPressed;
local curve = { player = nil, i = 0 };

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

local function quad_bezier(t, p0, p1, o0)
    return (1 - t)^2 * p0 + 2 * (1 - t) * t * (p0 + (p1 - p0) * o0) + t^2 * p1;
end

-- connections
runservice.Heartbeat:Connect(function(delta_time)
    if is_mouse_pressed(inputservice, Enum.UserInputType.MouseButton2) then
        local player, screen = get_closest();
        if player and player.Character then
            if curve.player ~= player or curve.i > 1 then
                curve.player = player;
                curve.i = 0;
            end

            local mouse = mouse_pos(inputservice);
            local delta = quad_bezier(curve.i, mouse, screen, Vector2.new(0.5, 0)) - mouse;
            mousemoverel(delta.X, delta.Y);

            curve.i += delta_time * 1.5;
        end
    else
        curve.player = nil;
        curve.i = 0;
    end
end);
