assert(Drawing, "missing function/library: drawing");

-- services
local run_service = game:GetService("RunService");
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");

-- variables
local localplayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local viewport_size = camera.ViewportSize;
local cache = {};

-- locals
local new_vector2 = Vector2.new;
local new_color3 = Color3.new;
local new_drawing = Drawing.new;
local rad = math.rad;
local tan = math.tan;
local floor = math.floor;

-- functions
local function floor_xy(x, y)
    return floor(x), floor(y);
end

local function create_esp(player)
    local esp = {};

    esp.box = new_drawing("Square");
    esp.box.Thickness = 1;
    esp.box.Filled = false;
    esp.box.Visible = false;

    esp.name = new_drawing("Text");
    esp.name.Font = Drawing.Fonts.Plex;
    esp.name.Size = 13;
    esp.name.Center = true;
    esp.name.Visible = false;

    esp.distance = new_drawing("Text");
    esp.distance.Font = Drawing.Fonts.Plex;
    esp.distance.Size = 13;
    esp.distance.Center = true;
    esp.distance.Visible = false;

    esp.tracer = new_drawing("Line");
    esp.tracer.Thickness = 1;
    esp.tracer.Visible = false;

    cache[player] = esp;
end

local function remove_esp(player)
    if cache[player] then
        for _, drawing in next, cache[player] do
            drawing:Remove();
        end

        cache[player] = nil;
    end
end

local function update_esp(player, esp)
    local character = player and player.Character;
    if character and character.PrimaryPart then
        local cframe = character.GetPrimaryPartCFrame(character);
        local position, visible = camera.WorldToViewportPoint(camera, cframe.Position);

        esp.box.Visible = visible;
        esp.name.Visible = visible;
        esp.distance.Visible = visible;
        esp.tracer.Visible = visible;

        if visible then
            local scale_factor = 1 / (position.Z * tan(rad(camera.FieldOfView * 0.5)) * 2) * 1000;
            local width, height = floor_xy(3 * scale_factor, 5 * scale_factor);
            local x, y = floor_xy(position.X, position.Y);

            esp.box.Size = new_vector2(width, height);
            esp.box.Position = new_vector2(floor_xy(x - width * 0.5, y - height * 0.5));
            esp.box.Color = player.Team and player.TeamColor.Color or new_color3(1,1,1);

            esp.name.Text = player.Name;
            esp.name.Color = player.Team and player.TeamColor.Color or new_color3(1,1,1);
            esp.name.Position = new_vector2(floor_xy(x, y - height * 0.5 - esp.name.TextBounds.Y));

            esp.distance.Text = floor(position.Z) .. " studs";
            esp.distance.Color = player.Team and player.TeamColor.Color or new_color3(1,1,1);
            esp.distance.Position = new_vector2(floor_xy(x, y + height * 0.5));

            esp.tracer.From = new_vector2(viewport_size.X * 0.5, viewport_size.Y);
            esp.tracer.To = new_vector2(floor_xy(x, y + height * 0.5));
            esp.tracer.Color = player.Team and player.TeamColor.Color or new_color3(1,1,1);
        end
    else
        esp.box.Visible = false;
        esp.name.Visible = false;
        esp.distance.Visible = false;
        esp.tracer.Visible = false;
    end
end

-- main
for _, player in next, players:GetPlayers() do
    if player ~= localplayer then
        create_esp(player);
    end
end

players.PlayerAdded:Connect(create_esp);
players.PlayerRemoving:Connect(remove_esp);

run_service:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
    for player, esp in next, cache do
        update_esp(player, esp);
    end
end);
