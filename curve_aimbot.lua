assert(mousemoverel, "missing dependency: mousemoverel");

-- services
local input_service = game:GetService("UserInputService");
local run_service = game:GetService("RunService");
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local teams = game:GetService("Teams");

-- variables
local camera = workspace.CurrentCamera;
local wtvp = camera.WorldToViewportPoint;
local localplayer = players.LocalPlayer;
local mouse_pos = input_service.GetMouseLocation;
local is_pressed = input_service.IsMouseButtonPressed;
local curve = { player = nil, i = 0 };

-- locals
local new_vector2 = Vector2.new;

-- functions
local function get_closest()
    local closest, player, position = math.huge, nil, nil;
    for _, p in next, players:GetPlayers() do
        local character = p.Character;
        if character then
            local pos, visible = wtvp(camera, character.Head.Position);
            pos = new_vector2(pos.X, pos.Y);

            local magnitude = (pos - mouse_pos(input_service)).Magnitude;
            if magnitude < closest and visible then
                closest = magnitude;
                player = p;
                position = pos;
            end
        end
    end
    return player, position;
end

local function cubic_bezier(t, p0, p3, o0, o1)
    local p1, p2 = p0 + (p3 - p0) * o0, p0 + (p3 - p0) * o1;
    return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3;
end

-- connections
run_service.Heartbeat:Connect(function(delta_time)
    if is_pressed(input_service, Enum.UserInputType.MouseButton2) then
        local player, screen = get_closest();
        if player and (player.Team ~= localplayer.Team or #teams:GetTeams() <= 1) then
            if curve.player ~= player or curve.i > 1 then
                curve.player = player;
                curve.i = 0;
            end

            local mouse = mouse_pos(input_service);
            local delta = cubic_bezier(curve.i, mouse, screen, new_vector2(0.5, 0), new_vector2(1, 0.5)) - mouse;
            mousemoverel(delta.X, delta.Y);

            curve.i += delta_time * 1.5;
        end
    else
        curve.player = nil;
        curve.i = 0;
    end
end);
