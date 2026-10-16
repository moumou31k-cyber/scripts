local _H = function(h)
    local o = {}
    for i = 1, #h, 2 do
        o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16))
    end
    return table.concat(o)
end

local session = _G.KanhaSession or { tier = "free", exp = 0 }
local isVip = (session.tier == "vip" or session.tier == "vip+" or session.tier == "ami" or session.tier == "owner")

local Players             = game:GetService("Players")
local HttpService         = game:GetService("HttpService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local TeleportService     = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetMouseLocation     = UserInputService.GetMouseLocation

local Rayfield = loadstring(game:HttpGet(_H("68747470733a2f2f7369726975732e6d656e752f7261796669656c64")))()

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════

local AimSettings = {
    Enabled = false, Keybind = Enum.KeyCode.E,
    MouseBind = Enum.UserInputType.MouseButton2, UseMouseBind = false,
    Smoothness = 0.35, TargetPart = "Head", FOVRadius = 120,
    ShowFOV = true, FOVColor = Color3.fromRGB(255, 255, 255), FOVTransparency = 0.9,
    UsePrediction = false, Prediction = 0.165,
    TeamCheck = true, WallCheck = false,
    IgnoreForcefield = true, IgnoreInvisible = false,
    StickyTarget = false, StickyTime = 0.3,
}

local SilentAimSettings = {
    Enabled = false, Method = "FindPartOnRayWithIgnoreList",
    TargetPart = "Head", HitChance = 100, FOVRadius = 250,
    ShowTarget = false, TeamCheck = true, WallCheck = false,
    IgnoreForcefield = true, IgnoreInvisible = false,
}

local TriggerbotSettings = {
    Enabled = false, Delay = 0.08, AutoFire = false,
    TeamCheck = true, WallCheck = false,
    IgnoreForcefield = true, IgnoreInvisible = false,
}

local KillAuraSettings = {
    Enabled = false, Range = 15, Delay = 0.1,
    TeamCheck = true, WallCheck = false,
    IgnoreForcefield = true, IgnoreInvisible = false,
}

local KillAllSettings = {
    Delay = 0.1, TeamCheck = true, WallCheck = false,
    IgnoreForcefield = true, IgnoreInvisible = false, UseRemote = true,
}

local AutoFarmSettings = { Enabled = false, Delay = 1.5 }

local ESPSettings = {
    Enabled = false, Box = true, Name = true, Health = true, Distance = true,
    Tracer = false, Chams = false, MaxDistance = 2000,
    BoxColor = Color3.fromRGB(255, 60, 60),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistanceColor = Color3.fromRGB(200, 200, 200),
    TracerColor = Color3.fromRGB(255, 60, 60),
    ChamsColor = Color3.fromRGB(255, 60, 60),
    ChamsTransparency = 0.4, TeamCheck = true,
}

local MiscSettings = {
    InfiniteAmmo = false, NoRecoil = false, NoSpread = false, NoCooldown = false,
    Fly = false, FlySpeed = 50, Noclip = false,
    WalkSpeed = 16, JumpPower = 50, Godmode = false,
    AntiAFK = false, HitMarker = false,
}

local SkinSettings = { SelectedWeapon = nil, SelectedSkin = nil, AutoApply = false }

local ExploitSettings = {
    TPOffset = -3, SelectedPlayer = nil,
    FreeTPEnabled = false, FreeTPKeybind = Enum.KeyCode.T,
    GoldenKnifeKeybind = Enum.KeyCode.G,
}

-- ═══════════════════════════════════════════════════════════════
-- INTERNAL
-- ═══════════════════════════════════════════════════════════════

local ESPObjects = {}
local ChamsObjects = {}
local FlyConnection, NoclipConnection, GodmodeConnection, AntiAFKConnection
local MainLoopConnection, HeartbeatConnection
local AutoFarmThread, KillAuraThread, FreeTPConnection, TriggerbotThread, SkinAutoThread
local InputBeganConnection, InputEndedConnection
local KillAllRunning = false
local TriggerbotRunning = false

local FOVCircle       = Drawing.new("Circle")
local SilentFOVCircle = Drawing.new("Circle")
local TargetIndicator = Drawing.new("Circle")
local HitMarkers      = {}
local HitMarkerPool   = {}

local LastTarget, LastTargetTime = nil, 0
local TriggerbotCooldown = false
local SkinRemoteCache, SkinListCache = nil, nil
local GoldenKnifeCache, GoldenKnifeCacheTime = nil, 0
local WallCache = {}

local MouseButtonStates = {
    [Enum.UserInputType.MouseButton1] = false,
    [Enum.UserInputType.MouseButton2] = false,
    [Enum.UserInputType.MouseButton3] = false,
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════════

local function safeDisconnect(c) if c then pcall(function() c:Disconnect() end) end end
local function safeDestroy(i) if i and i.Parent then pcall(function() i:Destroy() end) end end

local function getLocalCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function hasForcefield(plr)
    if not plr or not plr.Character then return false end
    return plr.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function isInvisible(plr)
    if not plr or not plr.Character then return false end
    for _, p in ipairs(plr.Character:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 1 and p.Transparency > 0 then return false end
    end
    return true
end

local function wallCheck(plr)
    if not plr or not plr.Character then return false end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true
    local result = Workspace:Raycast(Camera.CFrame.Position, hrp.Position - Camera.CFrame.Position, params)
    if result then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        return hitModel == plr.Character
    end
    return true
end

local WALL_CACHE_TTL = 0.15

local function cachedWallCheck(plr)
    if not plr or not plr.Character then return false end
    local now = tick()
    local c = WallCache[plr]
    if c and (now - c.t) < WALL_CACHE_TTL then
        return c.visible
    end
    local v = wallCheck(plr)
    WallCache[plr] = { visible = v, t = now }
    return v
end

local function validate(plr, opts)
    if not plr or plr == LocalPlayer then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    if opts.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    if opts.IgnoreForcefield and hasForcefield(plr) then return false end
    if opts.IgnoreInvisible and isInvisible(plr) then return false end
    if opts.WallCheck and not cachedWallCheck(plr) then return false end
    return true
end

local function getDirection(o, t) return (t - o).Unit end

local function calculateChance(p)
    p = math.floor(p)
    if p >= 100 then return true end
    if p <= 0 then return false end
    return math.random(1, 100) <= p
end

local function isAimActivated()
    if AimSettings.UseMouseBind then return MouseButtonStates[AimSettings.MouseBind] == true end
    return UserInputService:IsKeyDown(AimSettings.Keybind)
end

local function hasEquippedTool()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, c in ipairs(char:GetChildren()) do if c:IsA("Tool") then return true end end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- INPUT
-- ═══════════════════════════════════════════════════════════════

InputBeganConnection = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if MouseButtonStates[input.UserInputType] ~= nil then
        MouseButtonStates[input.UserInputType] = true
    end
end)

InputEndedConnection = UserInputService.InputEnded:Connect(function(input)
    if MouseButtonStates[input.UserInputType] ~= nil then
        MouseButtonStates[input.UserInputType] = false
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- DRAWINGS
-- ═══════════════════════════════════════════════════════════════

FOVCircle.Visible = false
FOVCircle.Radius = AimSettings.FOVRadius
FOVCircle.Color = AimSettings.FOVColor
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = AimSettings.FOVTransparency
FOVCircle.ZIndex = 999

SilentFOVCircle.Visible = false
SilentFOVCircle.Radius = SilentAimSettings.FOVRadius
SilentFOVCircle.Color = Color3.fromRGB(120, 200, 255)
SilentFOVCircle.Thickness = 1.5
SilentFOVCircle.NumSides = 64
SilentFOVCircle.Filled = false
SilentFOVCircle.Transparency = 0.85
SilentFOVCircle.ZIndex = 999

TargetIndicator.Visible = false
TargetIndicator.Radius = 8
TargetIndicator.Color = Color3.fromRGB(255, 50, 50)
TargetIndicator.Thickness = 2
TargetIndicator.NumSides = 32
TargetIndicator.Filled = false
TargetIndicator.Transparency = 1
TargetIndicator.ZIndex = 999

-- ═══════════════════════════════════════════════════════════════
-- HIT MARKER (pooled)
-- ═══════════════════════════════════════════════════════════════

local function getMarkerFromPool()
    if #HitMarkerPool > 0 then
        return table.remove(HitMarkerPool)
    end
    local lines = {}
    for _ = 1, 4 do
        local line = Drawing.new("Line")
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 2
        line.Transparency = 1
        line.ZIndex = 1000
        line.Visible = false
        table.insert(lines, line)
    end
    return lines
end

local function releaseMarkerToPool(lines)
    for _, line in ipairs(lines) do
        line.Visible = false
    end
    table.insert(HitMarkerPool, lines)
end

local function spawnHitMarker()
    if not MiscSettings.HitMarker then return end
    local lines = getMarkerFromPool()
    for _, line in ipairs(lines) do line.Visible = true end
    local c = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    table.insert(HitMarkers, { Lines = lines, StartTime = tick(), Duration = 0.3, Center = c })
end

local function updateHitMarkers()
    for i = #HitMarkers, 1, -1 do
        local hm = HitMarkers[i]
        local alpha = 1 - ((tick() - hm.StartTime) / hm.Duration)
        if alpha <= 0 then
            releaseMarkerToPool(hm.Lines)
            table.remove(HitMarkers, i)
        else
            local expand = 6 + (1 - alpha) * 6
            local gap = 3
            local c = hm.Center
            hm.Lines[1].From = Vector2.new(c.X - gap - expand, c.Y - gap - expand)
            hm.Lines[1].To = Vector2.new(c.X - gap, c.Y - gap)
            hm.Lines[2].From = Vector2.new(c.X + gap, c.Y - gap)
            hm.Lines[2].To = Vector2.new(c.X + gap + expand, c.Y - gap - expand)
            hm.Lines[3].From = Vector2.new(c.X - gap - expand, c.Y + gap + expand)
            hm.Lines[3].To = Vector2.new(c.X - gap, c.Y + gap)
            hm.Lines[4].From = Vector2.new(c.X + gap, c.Y + gap)
            hm.Lines[4].To = Vector2.new(c.X + gap + expand, c.Y + gap + expand)
            for _, line in ipairs(hm.Lines) do line.Transparency = alpha end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TARGET FINDERS
-- ═══════════════════════════════════════════════════════════════

local function findTargetScreen(opts)
    local allPlayers = Players:GetPlayers()
    if #allPlayers <= 1 then return nil end
    local closest, closestDist = nil, opts.FOVRadius
    local mousePos = GetMouseLocation(UserInputService)
    for _, plr in ipairs(allPlayers) do
        if validate(plr, opts) then
            local tPart = plr.Character:FindFirstChild(opts.TargetPart)
            if tPart then
                local sPos, onScreen = WorldToViewportPoint(Camera, tPart.Position)
                if onScreen then
                    local dist = (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude
                    if dist < closestDist then closest = tPart; closestDist = dist end
                end
            end
        end
    end
    return closest
end

local function findTarget3D(opts)
    local allPlayers = Players:GetPlayers()
    if #allPlayers <= 1 then return nil end
    local closest, closestDist = nil, math.huge
    local localChar = LocalPlayer.Character
    if not localChar then return nil end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return nil end
    for _, plr in ipairs(allPlayers) do
        if validate(plr, opts) then
            local tPart = plr.Character:FindFirstChild(opts.TargetPart)
            if tPart then
                local dist = (tPart.Position - localHRP.Position).Magnitude
                if dist < closestDist then closest = tPart; closestDist = dist end
            end
        end
    end
    return closest, closestDist
end

local function getSilentAimTarget()
    return findTargetScreen({
        FOVRadius = SilentAimSettings.FOVRadius, TargetPart = SilentAimSettings.TargetPart,
        TeamCheck = SilentAimSettings.TeamCheck, WallCheck = SilentAimSettings.WallCheck,
        IgnoreForcefield = SilentAimSettings.IgnoreForcefield, IgnoreInvisible = SilentAimSettings.IgnoreInvisible,
    })
end

local function getAimbotTarget()
    return findTarget3D({
        TargetPart = AimSettings.TargetPart, TeamCheck = AimSettings.TeamCheck,
        WallCheck = AimSettings.WallCheck, IgnoreForcefield = AimSettings.IgnoreForcefield,
        IgnoreInvisible = AimSettings.IgnoreInvisible,
    })
end

local function getTriggerbotTarget()
    return findTargetScreen({
        FOVRadius = AimSettings.FOVRadius, TargetPart = AimSettings.TargetPart,
        TeamCheck = TriggerbotSettings.TeamCheck, WallCheck = TriggerbotSettings.WallCheck,
        IgnoreForcefield = TriggerbotSettings.IgnoreForcefield, IgnoreInvisible = TriggerbotSettings.IgnoreInvisible,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════════════════

local function createESP(plr)
    if not plr or plr == LocalPlayer or ESPObjects[plr] then return end
    local esp = {}
    esp.Box = Drawing.new("Square")
    esp.Box.Visible = false; esp.Box.Thickness = 1.5; esp.Box.Filled = false
    esp.Box.Transparency = 1; esp.Box.ZIndex = 10
    esp.Outline = Drawing.new("Square")
    esp.Outline.Visible = false; esp.Outline.Color = Color3.fromRGB(0, 0, 0)
    esp.Outline.Thickness = 1; esp.Outline.Filled = false
    esp.Outline.Transparency = 1; esp.Outline.ZIndex = 9
    esp.Name = Drawing.new("Text")
    esp.Name.Visible = false; esp.Name.Size = 14
    esp.Name.Center = true; esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0); esp.Name.ZIndex = 11
    esp.Health = Drawing.new("Text")
    esp.Health.Visible = false; esp.Health.Size = 12
    esp.Health.Center = true; esp.Health.Outline = true
    esp.Health.OutlineColor = Color3.fromRGB(0, 0, 0); esp.Health.ZIndex = 11
    esp.Distance = Drawing.new("Text")
    esp.Distance.Visible = false; esp.Distance.Size = 11
    esp.Distance.Center = true; esp.Distance.Outline = true
    esp.Distance.OutlineColor = Color3.fromRGB(0, 0, 0); esp.Distance.ZIndex = 11
    esp.Tracer = Drawing.new("Line")
    esp.Tracer.Visible = false; esp.Tracer.Thickness = 1
    esp.Tracer.Transparency = 1; esp.Tracer.ZIndex = 8
    ESPObjects[plr] = esp
end

local function removeESP(plr)
    local esp = ESPObjects[plr]
    if not esp then return end
    for _, obj in pairs(esp) do
        if obj and obj.Remove then pcall(function() obj:Remove() end) end
    end
    ESPObjects[plr] = nil
end

local function cleanupAllESP() for plr, _ in pairs(ESPObjects) do removeESP(plr) end end

local function hideESP(esp)
    if not esp.Box.Visible then return end
    esp.Box.Visible = false; esp.Outline.Visible = false
    esp.Name.Visible = false; esp.Health.Visible = false
    esp.Distance.Visible = false; esp.Tracer.Visible = false
end

local function updateESP()
    local localChar = LocalPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for plr, esp in pairs(ESPObjects) do
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        local valid = false
        if char and hum and hum.Health > 0 and hrp and head then
            if not (ESPSettings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                if localHRP then
                    local dist = (hrp.Position - localHRP.Position).Magnitude
                    valid = dist <= ESPSettings.MaxDistance
                else
                    valid = true
                end
            end
        end

        if not valid then
            hideESP(esp)
        else
            local headPos, onScreen = WorldToViewportPoint(Camera, head.Position)
            local feetPos, feetOn = WorldToViewportPoint(Camera, hrp.Position - Vector3.new(0, 3, 0))

            if onScreen and feetOn and headPos.Z > 0 then
                local height = math.abs(headPos.Y - feetPos.Y) * 1.1
                local width = height * 0.7
                local x = headPos.X - width / 2
                local y = headPos.Y

                if ESPSettings.Box then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(x, y)
                    esp.Box.Color = ESPSettings.BoxColor
                    esp.Box.Visible = true
                    esp.Outline.Size = esp.Box.Size
                    esp.Outline.Position = esp.Box.Position
                    esp.Outline.Visible = true
                else
                    esp.Box.Visible = false; esp.Outline.Visible = false
                end

                if ESPSettings.Name then
                    esp.Name.Text = plr.Name
                    esp.Name.Position = Vector2.new(headPos.X, y - 18)
                    esp.Name.Color = ESPSettings.NameColor
                    esp.Name.Visible = true
                else esp.Name.Visible = false end

                if ESPSettings.Health then
                    local hp = math.floor(hum.Health)
                    local maxHp = math.floor(hum.MaxHealth)
                    esp.Health.Text = hp .. " / " .. maxHp
                    local ratio = hp / math.max(maxHp, 1)
                    if ratio > 0.6 then esp.Health.Color = Color3.fromRGB(0, 255, 0)
                    elseif ratio > 0.3 then esp.Health.Color = Color3.fromRGB(255, 200, 0)
                    else esp.Health.Color = Color3.fromRGB(255, 0, 0) end
                    esp.Health.Position = Vector2.new(headPos.X, y + height + 2)
                    esp.Health.Visible = true
                else esp.Health.Visible = false end

                if ESPSettings.Distance and localHRP then
                    local dist = math.floor((hrp.Position - localHRP.Position).Magnitude)
                    esp.Distance.Text = dist .. "m"
                    esp.Distance.Position = Vector2.new(headPos.X, y - 34)
                    esp.Distance.Color = ESPSettings.DistanceColor
                    esp.Distance.Visible = true
                else esp.Distance.Visible = false end

                if ESPSettings.Tracer then
                    local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    esp.Tracer.From = sc
                    esp.Tracer.To = Vector2.new(headPos.X, headPos.Y + height)
                    esp.Tracer.Color = ESPSettings.TracerColor
                    esp.Tracer.Visible = true
                else esp.Tracer.Visible = false end
            else
                hideESP(esp)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CHAMS
-- ═══════════════════════════════════════════════════════════════

local function applyChamsToChar(plr)
    if not plr or ChamsObjects[plr] or not plr.Character then return end
    local parts = {}
    for _, part in ipairs(plr.Character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            table.insert(parts, {
                Part = part, OriginalColor = part.Color,
                OriginalMaterial = part.Material, OriginalTransparency = part.Transparency,
            })
            part.Color = ESPSettings.ChamsColor
            part.Material = Enum.Material.Neon
            part.Transparency = ESPSettings.ChamsTransparency
        end
    end
    ChamsObjects[plr] = parts
end

local function removeChamsFromChar(plr)
    local chams = ChamsObjects[plr]
    if not chams then return end
    for _, data in ipairs(chams) do
        if data.Part and data.Part.Parent then
            pcall(function()
                data.Part.Color = data.OriginalColor
                data.Part.Material = data.OriginalMaterial
                data.Part.Transparency = data.OriginalTransparency
            end)
        end
    end
    ChamsObjects[plr] = nil
end

local function cleanupAllChams() for plr, _ in pairs(ChamsObjects) do removeChamsFromChar(plr) end end

local function refreshChamsColor()
    for _, chams in pairs(ChamsObjects) do
        for _, data in ipairs(chams) do
            if data.Part and data.Part.Parent then
                pcall(function()
                    data.Part.Color = ESPSettings.ChamsColor
                    data.Part.Transparency = ESPSettings.ChamsTransparency
                end)
            end
        end
    end
end

local function chamsValidate(plr)
    if not plr or plr == LocalPlayer then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if ESPSettings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    return true
end

local function updateChams()
    if not ESPSettings.Enabled or not ESPSettings.Chams then
        if next(ChamsObjects) then cleanupAllChams() end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if chamsValidate(plr) then
            if not ChamsObjects[plr] then applyChamsToChar(plr) end
        else
            if ChamsObjects[plr] then removeChamsFromChar(plr) end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- HOOKS
-- ═══════════════════════════════════════════════════════════════

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local method = getnamecallmethod()

    if method ~= "FindPartOnRayWithIgnoreList"
       and method ~= "FindPartOnRay"
       and method ~= "Raycast"
       and method ~= "Fire" then
        return oldNamecall(...)
    end

    local self = ...
    local args = {...}

    if self == Workspace and not checkcaller() then
        local shouldRedirect = false
        local rayIndex = nil

        if SilentAimSettings.Enabled then
            if method == "FindPartOnRayWithIgnoreList" then
                rayIndex = 2
                if typeof(args[2]) == "Ray" and typeof(args[3]) == "table"
                   and (args[2].Origin - Camera.CFrame.Position).Magnitude < 30 then
                    shouldRedirect = true
                end
            elseif method == "FindPartOnRay" then
                rayIndex = 2
                if typeof(args[2]) == "Ray"
                   and (args[2].Origin - Camera.CFrame.Position).Magnitude < 30 then
                    shouldRedirect = true
                end
            elseif method == "Raycast" then
                rayIndex = 3
                if typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3"
                   and (args[2] - Camera.CFrame.Position).Magnitude < 30 then
                    shouldRedirect = true
                end
            end
        end

        if shouldRedirect and calculateChance(SilentAimSettings.HitChance) then
            local tPart = getSilentAimTarget()
            if tPart then
                local origin = rayIndex == 2 and args[2].Origin or args[2]
                local dir = getDirection(origin, tPart.Position)
                if method == "Raycast" then args[3] = dir
                else args[2] = Ray.new(origin, dir) end
                return oldNamecall(unpack(args))
            end
        end

        if MiscSettings.NoSpread then
            if method == "FindPartOnRayWithIgnoreList" and typeof(args[2]) == "Ray" and typeof(args[3]) == "table"
               and (args[2].Origin - Camera.CFrame.Position).Magnitude < 30 then
                args[2] = Ray.new(args[2].Origin, Camera.CFrame.LookVector)
                return oldNamecall(unpack(args))
            elseif method == "Raycast" and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3"
                   and (args[2] - Camera.CFrame.Position).Magnitude < 30 then
                args[3] = Camera.CFrame.LookVector
                return oldNamecall(unpack(args))
            end
        end
    end

    if method == "Fire" and MiscSettings.InfiniteAmmo then
        if typeof(self) == "Instance" and self:IsA("Tool") then
            for _, name in ipairs({"Ammo", "Clip", "Mag", "CurrentAmmo", "AmmoCount"}) do
                local v = self:FindFirstChild(name)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 999 end) end
            end
        end
    end

    return oldNamecall(...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if self == Mouse and not checkcaller() and SilentAimSettings.Enabled then
        if SilentAimSettings.Method == "Mouse.Hit/Target" then
            if key == "Target" or key == "Hit" then
                local tPart = getSilentAimTarget()
                if tPart then
                    if key == "Target" then return tPart
                    else return tPart.CFrame end
                end
            end
        end
    end
    return oldIndex(self, key)
end))

-- ═══════════════════════════════════════════════════════════════
-- AIMBOT
-- ═══════════════════════════════════════════════════════════════

local function aimbotUpdate()
    if not AimSettings.Enabled then return end
    local _, _, localHRP = getLocalCharacter()
    if not localHRP then return end

    if not isAimActivated() then
        if TargetIndicator.Visible then TargetIndicator.Visible = false end
        LastTarget = nil
        return
    end

    local targetPart
    if AimSettings.StickyTarget and LastTarget and (tick() - LastTargetTime) < AimSettings.StickyTime then
        if LastTarget.Parent then
            local hum = LastTarget.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                targetPart = LastTarget
            else LastTarget = nil end
        else LastTarget = nil end
    end

    if not targetPart then
        targetPart = getAimbotTarget()
        if targetPart then
            LastTarget = targetPart
            LastTargetTime = tick()
        end
    end

    if targetPart then
        local targetPos = targetPart.Position
        if AimSettings.UsePrediction and targetPart.Parent then
            local targetHRP = targetPart.Parent:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                targetPos = targetPos + (targetHRP.Velocity * AimSettings.Prediction)
            end
        end
        local currentCFrame = Camera.CFrame
        local desiredCFrame = CFrame.new(currentCFrame.Position, targetPos)
        Camera.CFrame = currentCFrame:Lerp(desiredCFrame, AimSettings.Smoothness)
        LastTargetTime = tick()

        if SilentAimSettings.ShowTarget then
            local sPos, onScreen = WorldToViewportPoint(Camera, targetPart.Position)
            if onScreen then
                TargetIndicator.Position = Vector2.new(sPos.X, sPos.Y)
                TargetIndicator.Visible = true
            else TargetIndicator.Visible = false end
        else
            if TargetIndicator.Visible then TargetIndicator.Visible = false end
        end
    else
        if TargetIndicator.Visible then TargetIndicator.Visible = false end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TRIGGERBOT
-- ═══════════════════════════════════════════════════════════════

local hasMouse1Click = type(mouse1click) == "function"
local hasMouse1Press = type(mouse1press) == "function"
local hasMouse1Release = type(mouse1release) == "function"

local function fireWeapon()
    if hasMouse1Click then pcall(mouse1click)
    elseif hasMouse1Press and hasMouse1Release then
        pcall(mouse1press); task.wait(0.02); pcall(mouse1release)
    else
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

local function triggerbotLoop()
    if TriggerbotRunning then return end
    TriggerbotRunning = true
    task.spawn(function()
        while TriggerbotSettings.Enabled do
            if not TriggerbotCooldown then
                local tPart = getTriggerbotTarget()
                if tPart and hasEquippedTool() then
                    TriggerbotCooldown = true
                    if TriggerbotSettings.AutoFire then fireWeapon() end
                    task.wait(math.max(TriggerbotSettings.Delay, 0.05))
                    TriggerbotCooldown = false
                end
            end
            task.wait(0.02)
        end
        TriggerbotRunning = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MOVEMENT
-- ═══════════════════════════════════════════════════════════════

local function toggleFly(state)
    local _, _, hrp = getLocalCharacter()
    if state then
        if not hrp then return end
        safeDestroy(hrp:FindFirstChild(_H("4b616e6861466c7956656c6f63697479")))
        safeDestroy(hrp:FindFirstChild(_H("4b616e6861466c794779726f")))
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp; bv.Name = _H("4b616e6861466c7956656c6f63697479")
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 10000; bg.D = 100
        bg.Parent = hrp; bg.Name = _H("4b616e6861466c794779726f")
        safeDisconnect(FlyConnection)
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not hrp or not hrp.Parent then return end
            local moveDir = Vector3.new(0, 0, 0)
            local camCF = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            local curBV = hrp:FindFirstChild(_H("4b616e6861466c7956656c6f63697479"))
            if curBV then curBV.Velocity = moveDir * MiscSettings.FlySpeed end
            local curBG = hrp:FindFirstChild(_H("4b616e6861466c794779726f"))
            if curBG then curBG.CFrame = camCF end
        end)
    else
        safeDisconnect(FlyConnection); FlyConnection = nil
        local char = LocalPlayer.Character
        if char then
            local hrp2 = char:FindFirstChild("HumanoidRootPart")
            if hrp2 then
                safeDestroy(hrp2:FindFirstChild(_H("4b616e6861466c7956656c6f63697479")))
                safeDestroy(hrp2:FindFirstChild(_H("4b616e6861466c794779726f")))
            end
        end
    end
end

local function toggleNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    if state then
        safeDisconnect(NoclipConnection)
        NoclipConnection = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if not c or not c.Parent then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part and part.Parent and part:IsA("BasePart") and part.CanCollide then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end)
    else
        safeDisconnect(NoclipConnection); NoclipConnection = nil
        local c = LocalPlayer.Character
        if c and c.Parent then
            for _, part in ipairs(c:GetDescendants()) do
                if part and part.Parent and part:IsA("BasePart") then
                    pcall(function() part.CanCollide = true end)
                end
            end
        end
    end
end

local function toggleGodmode(state)
    if state then
        safeDisconnect(GodmodeConnection)
        GodmodeConnection = RunService.Heartbeat:Connect(function()
            local _, hum = getLocalCharacter()
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
    else safeDisconnect(GodmodeConnection); GodmodeConnection = nil end
end

local function toggleAntiAFK(state)
    if state then
        safeDisconnect(AntiAFKConnection)
        local vu = game:GetService("VirtualUser")
        AntiAFKConnection = LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    else safeDisconnect(AntiAFKConnection); AntiAFKConnection = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- WEAPON MODS
-- ═══════════════════════════════════════════════════════════════

local RECOIL_NAMES   = {"Recoil", "CamRecoil", "RecoilMultiplier", "RecoilAmount", "ViewRecoil"}
local SPREAD_NAMES   = {"Spread", "SpreadMultiplier", "SpreadAmount", "BaseSpread"}
local COOLDOWN_NAMES = {"Cooldown", "FireRate", "FireDelay", "CooldownTime", "Delay"}

local function applyWeaponMods()
    if not MiscSettings.NoRecoil and not MiscSettings.NoSpread and not MiscSettings.NoCooldown then
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local function process(tool)
        if not tool:IsA("Tool") then return end
        if MiscSettings.NoRecoil then
            for _, n in ipairs(RECOIL_NAMES) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
            end
        end
        if MiscSettings.NoSpread then
            for _, n in ipairs(SPREAD_NAMES) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
            end
        end
        if MiscSettings.NoCooldown then
            for _, n in ipairs(COOLDOWN_NAMES) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
            end
        end
    end
    for _, t in ipairs(char:GetChildren()) do process(t) end
    local pack = LocalPlayer:FindFirstChild("Backpack")
    if pack then
        for _, t in ipairs(pack:GetChildren()) do process(t) end
    end
    if MiscSettings.NoRecoil then
        for _, n in ipairs(RECOIL_NAMES) do
            local v = Camera:FindFirstChild(n)
            if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
        end
    end
end

local function onToolEquipped()
    task.wait(0.1)
    applyWeaponMods()
end

-- ═══════════════════════════════════════════════════════════════
-- SKIN CHANGER
-- ═══════════════════════════════════════════════════════════════

local function findSkinRemote()
    if SkinRemoteCache and SkinRemoteCache.Parent then return SkinRemoteCache end
    local candidates = {"ChangeSkin","EquipSkin","SkinChange","SetSkin","ApplySkin","ChangeWeaponSkin"}
    local containers = {
        ReplicatedStorage:FindFirstChild("Remotes"), ReplicatedStorage:FindFirstChild("RemoteEvents"),
        ReplicatedStorage:FindFirstChild("Events"), ReplicatedStorage:FindFirstChild("Net"), ReplicatedStorage,
    }
    for _, c in ipairs(containers) do
        if c then
            for _, name in ipairs(candidates) do
                local r = c:FindFirstChild(name)
                if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                    SkinRemoteCache = r
                    return r
                end
            end
        end
    end
    return nil
end

local function scanSkins()
    if SkinListCache then return SkinListCache end
    local list, seen = {}, {}
    local function add(n)
        if n and n ~= "" and not seen[n] then seen[n] = true; table.insert(list, n) end
    end
    local containers = {
        ReplicatedStorage:FindFirstChild("Skins"), ReplicatedStorage:FindFirstChild("SkinData"),
        ReplicatedStorage:FindFirstChild("WeaponSkins"), ReplicatedStorage:FindFirstChild("Cosmetics"),
        ReplicatedStorage:FindFirstChild("Items"),
    }
    for _, c in ipairs(containers) do
        if c then
            for _, item in ipairs(c:GetDescendants()) do
                if item:IsA("StringValue") or item:IsA("Model") or item:IsA("Tool") or item:IsA("Folder") then
                    local n = item.Name
                    if not n:find("^%d+$") and #n < 30 then add(n) end
                end
            end
        end
    end
    if #list == 0 then
        for _, n in ipairs({"Default","Gold","Emerald","Ruby","Diamond","Neon","Galaxy","Rainbow","Plasma","Shadow"}) do add(n) end
    end
    table.sort(list)
    SkinListCache = list
    return list
end

local function findCurrentWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, c in ipairs(char:GetChildren()) do if c:IsA("Tool") then return c end end
    return nil
end

local function applySkin(weaponName, skinName)
    local remote = findSkinRemote()
    local tool = findCurrentWeapon()
    local tW = weaponName or (tool and tool.Name) or "Knife"
    local tS = skinName or SkinSettings.SelectedSkin or "Default"
    if not remote then
        if tool then
            for _, n in ipairs({"Skin","CurrentSkin","SkinName"}) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = tS end) end
            end
        end
        return false
    end
    for _, a in ipairs({{tW,tS},{tS},{tS,tW},{tW,tS,true}}) do
        if pcall(function() remote:FireServer(unpack(a)) end) then return true end
    end
    return false
end

local function startSkinAuto()
    safeDisconnect(SkinAutoThread)
    SkinAutoThread = RunService.Heartbeat:Connect(function()
        if not SkinSettings.AutoApply or not SkinSettings.SelectedSkin then return end
        local tool = findCurrentWeapon()
        if tool then
            local hasSkin = false
            for _, n in ipairs({"Skin","CurrentSkin","SkinName"}) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") and v.Value == SkinSettings.SelectedSkin then hasSkin = true; break end
            end
            if not hasSkin then applySkin(tool.Name, SkinSettings.SelectedSkin) end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- EXPLOITS
-- ═══════════════════════════════════════════════════════════════

local function tpToPlayer(plr)
    if not plr or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local _, _, localHRP = getLocalCharacter()
    if not localHRP then return end
    localHRP.CFrame = CFrame.new(hrp.Position + hrp.CFrame.LookVector * (ExploitSettings.TPOffset or -3))
end

local function bringPlayer(plr)
    if not plr or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    local _, _, localHRP = getLocalCharacter()
    if hrp and localHRP then hrp.CFrame = localHRP.CFrame * CFrame.new(0, 0, 3) end
end

local function bringAll()
    local _, _, localHRP = getLocalCharacter()
    if not localHRP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.CFrame = localHRP.CFrame * CFrame.new(0, 0, 3) end) end
        end
    end
end

local function killPlayer(plr)
    if not plr or plr == LocalPlayer or not plr.Character then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if KillAllSettings.UseRemote and hrp then
        local origin = Camera.CFrame.Position
        local dir = getDirection(origin, hrp.Position)
        for _, a in ipairs({{hrp.Position},{origin, dir},{hrp, hrp.Position},{plr.Character, hrp.Position, dir}}) do
            pcall(function()
                for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
                    if d:IsA("RemoteEvent") and (d.Name:lower():find("hit") or d.Name:lower():find("damage")) then
                        d:FireServer(unpack(a))
                    end
                end
            end)
        end
    end
    pcall(function() hum.Health = 0 end)
    pcall(function() hum:TakeDamage(hum.MaxHealth) end)
end

local function killAll()
    if KillAllRunning then return end
    KillAllRunning = true
    task.spawn(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if validate(plr, {
                    TeamCheck = KillAllSettings.TeamCheck, WallCheck = KillAllSettings.WallCheck,
                    IgnoreForcefield = KillAllSettings.IgnoreForcefield, IgnoreInvisible = KillAllSettings.IgnoreInvisible,
                }) then
                    tpToPlayer(plr)
                    task.wait(KillAllSettings.Delay)
                    killPlayer(plr)
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end)
                    task.wait(KillAllSettings.Delay)
                end
            end
        end
        KillAllRunning = false
    end)
end

local function getGoldenKnife()
    if GoldenKnifeCache and GoldenKnifeCache.Parent and (tick() - GoldenKnifeCacheTime) < 5 then
        return GoldenKnifeCache
    end
    local result = nil
    local paths = {
        ReplicatedStorage:FindFirstChild("Tools"), ReplicatedStorage:FindFirstChild("Weapons"),
        ReplicatedStorage:FindFirstChild("Items"), ReplicatedStorage,
    }
    for _, c in ipairs(paths) do
        if c then
            for _, item in ipairs(c:GetDescendants()) do
                local n = item.Name:lower()
                if (n:find("gold") or n:find("golden")) and (n:find("knife") or n:find("melee") or n:find("blade")) then
                    result = item
                    break
                end
            end
            if result then break end
        end
    end
    if not result then
        for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
            if item:IsA("Tool") and item.Name:lower():find("gold") then result = item; break end
        end
    end
    GoldenKnifeCache = result
    GoldenKnifeCacheTime = tick()
    return result
end

local function equipGoldenKnife()
    local knife = getGoldenKnife()
    local char = LocalPlayer.Character
    if not char then return false end
    if knife then
        pcall(function()
            local clone = knife:Clone()
            clone.Parent = LocalPlayer.Backpack
            task.wait(0.1)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(clone) end
        end)
        return true
    end
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:lower():find("gold") then
            pcall(function()
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(item) end
            end)
            return true
        end
    end
    return false
end

local function startKillAura()
    safeDisconnect(KillAuraThread)
    KillAuraThread = RunService.Heartbeat:Connect(function()
        if not KillAuraSettings.Enabled then return end
        local _, _, localHRP = getLocalCharacter()
        if not localHRP then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - localHRP.Position).Magnitude
                    if dist <= KillAuraSettings.Range then
                        if validate(plr, {
                            TeamCheck = KillAuraSettings.TeamCheck, WallCheck = KillAuraSettings.WallCheck,
                            IgnoreForcefield = KillAuraSettings.IgnoreForcefield, IgnoreInvisible = KillAuraSettings.IgnoreInvisible,
                        }) then
                            killPlayer(plr)
                            task.wait(KillAuraSettings.Delay)
                        end
                    end
                end
            end
        end
    end)
end

local function startFreeTP()
    safeDisconnect(FreeTPConnection)
    FreeTPConnection = RunService.RenderStepped:Connect(function()
        if not ExploitSettings.FreeTPEnabled then return end
        if UserInputService:IsKeyDown(ExploitSettings.FreeTPKeybind) then
            local mp = GetMouseLocation(UserInputService)
            local ray = Camera:ViewportPointToRay(mp.X, mp.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if result then
                local _, _, hrp = getLocalCharacter()
                if hrp then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
            end
        end
    end)
end

local function startAutoFarm()
    if AutoFarmThread then return end
    AutoFarmThread = task.spawn(function()
        while AutoFarmSettings.Enabled do
            killAll()
            task.wait(AutoFarmSettings.Delay)
        end
        AutoFarmThread = nil
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- RESPAWN
-- ═══════════════════════════════════════════════════════════════

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = MiscSettings.WalkSpeed
        hum.JumpPower = MiscSettings.JumpPower
        hum.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then onToolEquipped() end
        end)
        hum.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then onToolEquipped() end
        end)
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        safeDestroy(hrp:FindFirstChild(_H("4b616e6861466c7956656c6f63697479")))
        safeDestroy(hrp:FindFirstChild(_H("4b616e6861466c794779726f")))
    end
    if MiscSettings.Fly then task.wait(0.3); toggleFly(true) end
    if MiscSettings.Noclip then task.wait(0.3); toggleNoclip(true) end
    if ESPSettings.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not ESPObjects[plr] then createESP(plr) end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOPS (optimized)
-- ═══════════════════════════════════════════════════════════════

local espTick = 0
local logicTick = 0
local weaponTick = 0
local ESP_INTERVAL = 0.033

MainLoopConnection = RunService.RenderStepped:Connect(function(dt)
    espTick = espTick + dt
    logicTick = logicTick + dt

    if ESPSettings.Enabled and espTick >= ESP_INTERVAL then
        espTick = 0
        updateESP()
    end

    aimbotUpdate()

    if AimSettings.ShowFOV and AimSettings.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Radius = AimSettings.FOVRadius
        FOVCircle.Position = GetMouseLocation(UserInputService)
        FOVCircle.Color = AimSettings.FOVColor
        FOVCircle.Transparency = AimSettings.FOVTransparency
    else
        if FOVCircle.Visible then FOVCircle.Visible = false end
    end

    if SilentAimSettings.ShowTarget and SilentAimSettings.Enabled then
        SilentFOVCircle.Visible = true
        SilentFOVCircle.Radius = SilentAimSettings.FOVRadius
        SilentFOVCircle.Position = GetMouseLocation(UserInputService)
    else
        if SilentFOVCircle.Visible then SilentFOVCircle.Visible = false end
    end

    updateHitMarkers()
end)

HeartbeatConnection = RunService.Heartbeat:Connect(function(dt)
    logicTick = logicTick + dt
    weaponTick = weaponTick + dt

    if logicTick >= 0.5 then
        logicTick = 0
        updateChams()
    end

    if weaponTick >= 1 then
        weaponTick = 0
        applyWeaponMods()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PLAYER CONNECTIONS
-- ═══════════════════════════════════════════════════════════════

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then createESP(plr) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        createESP(plr)
        if ESPSettings.Enabled and ESPSettings.Chams then
            task.wait(1)
            if plr.Character and chamsValidate(plr) then
                applyChamsToChar(plr)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
    removeChamsFromChar(plr)
    WallCache[plr] = nil
end)

-- ═══════════════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = _H("417273656e616c202f2f204b616e6861204875622076312e30") .. (isVip and _H("205b5649505d") or ""),
    LoadingTitle = _H("4c6f6164696e67204b616e6861204875622e2e2e"),
    LoadingSubtitle = _H("6279204b616e6861"),
    Theme = "Dark",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    ConfigurationSaving = { Enabled = true, FolderName = "KanhaHub", FileName = "ArsenalV1" },
    KeySystem = false,
})

local CombatTab = Window:CreateTab(_H("436f6d626174"), 6031097226)
CombatTab:CreateSection(_H("53696c656e742041696d"))
CombatTab:CreateToggle({Name = _H("456e61626c652053696c656e742041696d"), CurrentValue = false, Flag = "SilentEnabled",
    Callback = function(v) SilentAimSettings.Enabled = v end})
CombatTab:CreateDropdown({Name = _H("4d6574686f64"),
    Options = {"FindPartOnRayWithIgnoreList", "FindPartOnRay", "Raycast", "Mouse.Hit/Target"},
    CurrentOption = {"FindPartOnRayWithIgnoreList"}, Flag = "SilentMethod",
    Callback = function(opt) SilentAimSettings.Method = typeof(opt) == "table" and opt[1] or opt end})
CombatTab:CreateDropdown({Name = _H("5461726765742050617274"), Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = {"Head"}, Flag = "SilentPart",
    Callback = function(opt) SilentAimSettings.TargetPart = typeof(opt) == "table" and opt[1] or opt end})
CombatTab:CreateSlider({Name = _H("486974204368616e6365"), Range = {0, 100}, Increment = 1, Suffix = "%",
    CurrentValue = 100, Flag = "SilentChance",
    Callback = function(v) SilentAimSettings.HitChance = v end})
CombatTab:CreateSlider({Name = _H("464f5620526164697573"), Range = {10, 800}, Increment = 1, Suffix = "px",
    CurrentValue = 250, Flag = "SilentFOV",
    Callback = function(v) SilentAimSettings.FOVRadius = v end})
CombatTab:CreateToggle({Name = _H("5465616d20436865636b"), CurrentValue = true, Flag = "SilentTeam",
    Callback = function(v) SilentAimSettings.TeamCheck = v end})
CombatTab:CreateToggle({Name = _H("57616c6c20436865636b"), CurrentValue = false, Flag = "SilentWall",
    Callback = function(v) SilentAimSettings.WallCheck = v end})
CombatTab:CreateToggle({Name = _H("53686f772054617267657420496e64696361746f72"), CurrentValue = false, Flag = "SilentShow",
    Callback = function(v)
        SilentAimSettings.ShowTarget = v
        if not v then TargetIndicator.Visible = false end
    end})

CombatTab:CreateSection(_H("41696d626f74"))
CombatTab:CreateToggle({Name = _H("456e61626c652041696d626f74"), CurrentValue = false, Flag = "AimbotEnabled",
    Callback = function(v)
        AimSettings.Enabled = v
        if not v then TargetIndicator.Visible = false; LastTarget = nil end
    end})
CombatTab:CreateKeybind({Name = _H("41696d626f74204b6579"), CurrentKeybind = "E", HoldToInteract = false, Flag = "AimbotKey",
    Callback = function(k) AimSettings.Keybind = Enum.KeyCode[k] end})
CombatTab:CreateToggle({Name = _H("557365204d6f75736520427574746f6e"), CurrentValue = false, Flag = "AimbotMouse",
    Callback = function(v) AimSettings.UseMouseBind = v end})
CombatTab:CreateDropdown({Name = _H("4d6f75736520427574746f6e"),
    Options = {"MouseButton1 (Left)", "MouseButton2 (Right)", "MouseButton3 (Middle)"},
    CurrentOption = {"MouseButton2 (Right)"}, Flag = "AimbotMouseBtn",
    Callback = function(opt)
        local val = typeof(opt) == "table" and opt[1] or opt
        if val == "MouseButton1 (Left)" then AimSettings.MouseBind = Enum.UserInputType.MouseButton1
        elseif val == "MouseButton2 (Right)" then AimSettings.MouseBind = Enum.UserInputType.MouseButton2
        elseif val == "MouseButton3 (Middle)" then AimSettings.MouseBind = Enum.UserInputType.MouseButton3 end
    end})
CombatTab:CreateSlider({Name = _H("536d6f6f74686e657373"), Range = {0.01, 1}, Increment = 0.01, Suffix = "",
    CurrentValue = 0.35, Flag = "AimbotSmooth",
    Callback = function(v) AimSettings.Smoothness = v end})
CombatTab:CreateDropdown({Name = _H("41696d626f74205461726765742050617274"),
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = {"Head"}, Flag = "AimbotPart",
    Callback = function(opt) AimSettings.TargetPart = typeof(opt) == "table" and opt[1] or opt end})
CombatTab:CreateToggle({Name = _H("50726564696374696f6e"), CurrentValue = false, Flag = "AimbotPred",
    Callback = function(v) AimSettings.UsePrediction = v end})
CombatTab:CreateSlider({Name = _H("50726564696374696f6e20416d6f756e74"), Range = {0.01, 1}, Increment = 0.01, Suffix = "",
    CurrentValue = 0.165, Flag = "AimbotPredAmt",
    Callback = function(v) AimSettings.Prediction = v end})
CombatTab:CreateToggle({Name = _H("537469636b7920546172676574"), CurrentValue = false, Flag = "AimbotSticky",
    Callback = function(v) AimSettings.StickyTarget = v end})
CombatTab:CreateSlider({Name = _H("537469636b79204475726174696f6e"), Range = {0.1, 2}, Increment = 0.05, Suffix = "s",
    CurrentValue = 0.3, Flag = "AimbotStickyTime",
    Callback = function(v) AimSettings.StickyTime = v end})
CombatTab:CreateToggle({Name = _H("41696d626f74205465616d20436865636b"), CurrentValue = true, Flag = "AimbotTeam",
    Callback = function(v) AimSettings.TeamCheck = v end})
CombatTab:CreateToggle({Name = _H("41696d626f742057616c6c20436865636b"), CurrentValue = false, Flag = "AimbotWall",
    Callback = function(v) AimSettings.WallCheck = v end})

CombatTab:CreateSection(_H("54726967676572626f74"))
CombatTab:CreateToggle({Name = _H("456e61626c652054726967676572626f74"), CurrentValue = false, Flag = "TrigEnabled",
    Callback = function(v)
        TriggerbotSettings.Enabled = v
        if v then triggerbotLoop() end
    end})
CombatTab:CreateToggle({Name = _H("4175746f2d46697265"), CurrentValue = false, Flag = "TrigAuto",
    Callback = function(v) TriggerbotSettings.AutoFire = v end})
CombatTab:CreateSlider({Name = _H("44656c6179"), Range = {0.05, 0.5}, Increment = 0.01, Suffix = "s",
    CurrentValue = 0.08, Flag = "TrigDelay",
    Callback = function(v) TriggerbotSettings.Delay = v end})

local ExploitTab = Window:CreateTab(_H("4578706c6f697473"), 6031097226)
ExploitTab:CreateSection(_H("4b696c6c20416c6c"))
ExploitTab:CreateSlider({Name = _H("44656c6179"), Range = {0.05, 1}, Increment = 0.01, Suffix = "s",
    CurrentValue = 0.1, Flag = "KillAllDelay",
    Callback = function(v) KillAllSettings.Delay = v end})
ExploitTab:CreateToggle({Name = _H("5465616d20436865636b"), CurrentValue = true, Flag = "KillAllTeam",
    Callback = function(v) KillAllSettings.TeamCheck = v end})
ExploitTab:CreateToggle({Name = _H("57616c6c20436865636b"), CurrentValue = false, Flag = "KillAllWall",
    Callback = function(v) KillAllSettings.WallCheck = v end})
ExploitTab:CreateButton({Name = _H("4b494c4c20414c4c"), Callback = function() killAll() end})

ExploitTab:CreateSection(_H("4175746f204661726d"))
ExploitTab:CreateToggle({Name = _H("456e61626c65204175746f204661726d"), CurrentValue = false, Flag = "AutoFarmOn",
    Callback = function(v)
        AutoFarmSettings.Enabled = v
        if v then startAutoFarm() end
    end})
ExploitTab:CreateSlider({Name = _H("4661726d2044656c6179"), Range = {0.5, 10}, Increment = 0.5, Suffix = "s",
    CurrentValue = 1.5, Flag = "AutoFarmDelay",
    Callback = function(v) AutoFarmSettings.Delay = v end})

ExploitTab:CreateSection(_H("4b696c6c2041757261"))
ExploitTab:CreateToggle({Name = _H("456e61626c65204b696c6c2041757261"), CurrentValue = false, Flag = "KillAuraOn",
    Callback = function(v)
        KillAuraSettings.Enabled = v
        if v then startKillAura() end
    end})
ExploitTab:CreateSlider({Name = _H("52616e6765"), Range = {5, 100}, Increment = 1, Suffix = "m",
    CurrentValue = 15, Flag = "KillAuraRange",
    Callback = function(v) KillAuraSettings.Range = v end})

ExploitTab:CreateSection(_H("476f6c64656e204b6e696665"))
ExploitTab:CreateButton({
    Name = _H("457175697020476f6c64656e204b6e696665"),
    Callback = function()
        local ok = equipGoldenKnife()
        Rayfield:Notify({Title = _H("476f6c64656e204b6e696665"), Content = ok and _H("45717569707065642e") or _H("4e6f7420666f756e642e"), Duration = 3})
    end})
ExploitTab:CreateKeybind({Name = _H("476f6c64656e204b6e696665204b6579"), CurrentKeybind = "G", HoldToInteract = false, Flag = "GoldenKey",
    Callback = function(k) ExploitSettings.GoldenKnifeKeybind = Enum.KeyCode[k] end})
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == ExploitSettings.GoldenKnifeKeybind then equipGoldenKnife() end
end)

local SkinTab = Window:CreateTab(_H("536b696e73"), 6031097226)
SkinTab:CreateSection(_H("536b696e204368616e676572"))
local skinList = scanSkins()
SkinTab:CreateDropdown({Name = _H("536b696e"), Options = skinList, CurrentOption = {}, Flag = "SkinSelect",
    Callback = function(opt) SkinSettings.SelectedSkin = typeof(opt) == "table" and opt[1] or opt end})
SkinTab:CreateButton({
    Name = _H("4170706c7920746f2043757272656e7420576561706f6e"),
    Callback = function()
        if not SkinSettings.SelectedSkin then
            Rayfield:Notify({Title = _H("536b696e"), Content = _H("5069636b206120736b696e2066697273742e"), Duration = 3}); return
        end
        local tool = findCurrentWeapon()
        if not tool then
            Rayfield:Notify({Title = _H("536b696e"), Content = _H("4e6f20776561706f6e2065717569707065642e"), Duration = 3}); return
        end
        local ok = applySkin(tool.Name, SkinSettings.SelectedSkin)
        Rayfield:Notify({Title = _H("536b696e"), Content = ok and (_H("4f4b3a20") .. SkinSettings.SelectedSkin) or _H("4c6f63616c2066616c6c6261636b2e"), Duration = 3})
    end})
SkinTab:CreateToggle({Name = _H("4175746f2d4170706c79206f6e204571756970"), CurrentValue = false, Flag = "SkinAuto",
    Callback = function(v) SkinSettings.AutoApply = v; if v then startSkinAuto() end end})

local TPTab = Window:CreateTab(_H("54656c65706f7274"), 6031097226)
TPTab:CreateSection(_H("545020746f20506c61796572"))
local function refreshPlayerList()
    local l = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(l, plr.Name) end
    end
    return l
end
local playerDropdown = TPTab:CreateDropdown({
    Name = _H("53656c65637420506c61796572"), Options = refreshPlayerList(), CurrentOption = {}, Flag = "TPSel",
    Callback = function(opt)
        local val = typeof(opt) == "table" and opt[1] or opt
        ExploitSettings.SelectedPlayer = Players:FindFirstChild(val)
    end})
Players.PlayerAdded:Connect(function() playerDropdown:Refresh(refreshPlayerList()) end)
Players.PlayerRemoving:Connect(function() playerDropdown:Refresh(refreshPlayerList()) end)
TPTab:CreateButton({Name = _H("545020746f2053656c6563746564"),
    Callback = function() if ExploitSettings.SelectedPlayer then tpToPlayer(ExploitSettings.SelectedPlayer) end end})
TPTab:CreateButton({Name = _H("4272696e672053656c6563746564"),
    Callback = function() if ExploitSettings.SelectedPlayer then bringPlayer(ExploitSettings.SelectedPlayer) end end})
TPTab:CreateButton({Name = _H("4252494e4720414c4c"), Callback = function() bringAll() end})
TPTab:CreateSection(_H("46726565205450"))
TPTab:CreateToggle({Name = _H("456e61626c652046726565205450"), CurrentValue = false, Flag = "FreeTPOn",
    Callback = function(v)
        ExploitSettings.FreeTPEnabled = v
        if v then startFreeTP() end
    end})
TPTab:CreateKeybind({Name = _H("46726565205450204b6579"), CurrentKeybind = "T", HoldToInteract = false, Flag = "FreeTPKey",
    Callback = function(k) ExploitSettings.FreeTPKeybind = Enum.KeyCode[k] end})

local VisualsTab = Window:CreateTab(_H("56697375616c73"), 6031097226)
VisualsTab:CreateSection(_H("455350"))
VisualsTab:CreateToggle({Name = _H("456e61626c6520455350"), CurrentValue = false, Flag = "ESPOn",
    Callback = function(v)
        ESPSettings.Enabled = v
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then createESP(plr) end
            end
        else cleanupAllESP() end
    end})
VisualsTab:CreateToggle({Name = _H("426f78"), CurrentValue = true, Flag = "ESPBox",
    Callback = function(v) ESPSettings.Box = v end})
VisualsTab:CreateToggle({Name = _H("4e616d65"), CurrentValue = true, Flag = "ESPName",
    Callback = function(v) ESPSettings.Name = v end})
VisualsTab:CreateToggle({Name = _H("4865616c7468"), CurrentValue = true, Flag = "ESPHealth",
    Callback = function(v) ESPSettings.Health = v end})
VisualsTab:CreateToggle({Name = _H("44697374616e6365"), CurrentValue = true, Flag = "ESPDist",
    Callback = function(v) ESPSettings.Distance = v end})
VisualsTab:CreateToggle({Name = _H("547261636572"), CurrentValue = false, Flag = "ESPTracer",
    Callback = function(v) ESPSettings.Tracer = v end})
VisualsTab:CreateToggle({Name = _H("4368616d73"), CurrentValue = false, Flag = "ESPChams",
    Callback = function(v)
        ESPSettings.Chams = v
        if not v then cleanupAllChams() end
    end})
VisualsTab:CreateToggle({Name = _H("5465616d20436865636b"), CurrentValue = true, Flag = "ESPTeam",
    Callback = function(v) ESPSettings.TeamCheck = v end})
VisualsTab:CreateSection(_H("436f6c6f7273"))
VisualsTab:CreateColorPicker({Name = _H("426f7820436f6c6f72"), Color = Color3.fromRGB(255, 60, 60), Flag = "ESPBoxCol",
    Callback = function(c) ESPSettings.BoxColor = c end})
VisualsTab:CreateColorPicker({Name = _H("4e616d6520436f6c6f72"), Color = Color3.fromRGB(255, 255, 255), Flag = "ESPNameCol",
    Callback = function(c) ESPSettings.NameColor = c end})
VisualsTab:CreateColorPicker({Name = _H("54726163657220436f6c6f72"), Color = Color3.fromRGB(255, 60, 60), Flag = "ESPTracerCol",
    Callback = function(c) ESPSettings.TracerColor = c end})
VisualsTab:CreateColorPicker({Name = _H("4368616d7320436f6c6f72"), Color = Color3.fromRGB(255, 60, 60), Flag = "ESPChamsCol",
    Callback = function(c) ESPSettings.ChamsColor = c; refreshChamsColor() end})

local PlayerTab = Window:CreateTab(_H("506c61796572"), 6031097226)
PlayerTab:CreateSection(_H("4d6f76656d656e74"))
PlayerTab:CreateSlider({Name = _H("57616c6b5370656564"), Range = {16, 500}, Increment = 1, Suffix = "",
    CurrentValue = 16, Flag = "WS",
    Callback = function(v)
        MiscSettings.WalkSpeed = v
        local _, hum = getLocalCharacter()
        if hum then hum.WalkSpeed = v end
    end})
PlayerTab:CreateSlider({Name = _H("4a756d70506f776572"), Range = {50, 500}, Increment = 1, Suffix = "",
    CurrentValue = 50, Flag = "JP",
    Callback = function(v)
        MiscSettings.JumpPower = v
        local _, hum = getLocalCharacter()
        if hum then hum.JumpPower = v end
    end})
PlayerTab:CreateToggle({Name = _H("466c79"), CurrentValue = false, Flag = "FlyOn",
    Callback = function(v) MiscSettings.Fly = v; toggleFly(v) end})
PlayerTab:CreateSlider({Name = _H("466c79205370656564"), Range = {10, 500}, Increment = 1, Suffix = "",
    CurrentValue = 50, Flag = "FlySpeed",
    Callback = function(v) MiscSettings.FlySpeed = v end})
PlayerTab:CreateToggle({Name = _H("4e6f636c6970"), CurrentValue = false, Flag = "NoclipOn",
    Callback = function(v) MiscSettings.Noclip = v; toggleNoclip(v) end})
PlayerTab:CreateToggle({Name = _H("476f646d6f6465"), CurrentValue = false, Flag = "GodOn",
    Callback = function(v) MiscSettings.Godmode = v; toggleGodmode(v) end})
PlayerTab:CreateSection(_H("576561706f6e"))
PlayerTab:CreateToggle({Name = _H("496e66696e69746520416d6d6f"), CurrentValue = false, Flag = "InfAmmo",
    Callback = function(v) MiscSettings.InfiniteAmmo = v end})
PlayerTab:CreateToggle({Name = _H("4e6f205265636f696c"), CurrentValue = false, Flag = "NoRecoil",
    Callback = function(v) MiscSettings.NoRecoil = v end})
PlayerTab:CreateToggle({Name = _H("4e6f20537072656164"), CurrentValue = false, Flag = "NoSpread",
    Callback = function(v) MiscSettings.NoSpread = v end})
PlayerTab:CreateToggle({Name = _H("4e6f20436f6f6c646f776e"), CurrentValue = false, Flag = "NoCooldown",
    Callback = function(v) MiscSettings.NoCooldown = v end})
PlayerTab:CreateSection(_H("5574696c697479"))
PlayerTab:CreateToggle({Name = _H("416e74692d41464b"), CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v) MiscSettings.AntiAFK = v; toggleAntiAFK(v) end})
PlayerTab:CreateToggle({Name = _H("486974204d61726b6572"), CurrentValue = false, Flag = "HitMark",
    Callback = function(v) MiscSettings.HitMarker = v end})

local SettingsTab = Window:CreateTab(_H("53657474696e6773"), 6031097226)
SettingsTab:CreateSection(_H("536572766572"))
SettingsTab:CreateButton({Name = _H("52656a6f696e20536572766572"),
    Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})
SettingsTab:CreateButton({Name = _H("53657276657220486f70"),
    Callback = function()
        local ok, r = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(_H("68747470733a2f2f67616d65732e726f626c6f782e636f6d2f76312f67616d65732f") .. game.PlaceId .. _H("2f736572766572732f5075626c69633f736f72744f726465723d417363266c696d69743d313030")))
        end)
        if ok and r and r.data then
            for _, s in pairs(r.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
    end})
SettingsTab:CreateSection(_H("536372697074"))
SettingsTab:CreateButton({
    Name = _H("556e6c6f616420536372697074"),
    Callback = function()
        safeDisconnect(MainLoopConnection); safeDisconnect(HeartbeatConnection)
        safeDisconnect(FlyConnection); safeDisconnect(NoclipConnection)
        safeDisconnect(GodmodeConnection); safeDisconnect(AntiAFKConnection)
        safeDisconnect(KillAuraThread); safeDisconnect(FreeTPConnection)
        safeDisconnect(SkinAutoThread)
        safeDisconnect(InputBeganConnection); safeDisconnect(InputEndedConnection)
        AutoFarmSettings.Enabled = false
        KillAuraSettings.Enabled = false
        TriggerbotSettings.Enabled = false
        cleanupAllESP(); cleanupAllChams()
        WallCache = {}
        for _, hm in ipairs(HitMarkers) do
            releaseMarkerToPool(hm.Lines)
        end
        HitMarkers = {}
        for _, lines in ipairs(HitMarkerPool) do
            for _, line in ipairs(lines) do pcall(function() line:Remove() end) end
        end
        HitMarkerPool = {}
        pcall(function() FOVCircle:Remove() end)
        pcall(function() SilentFOVCircle:Remove() end)
        pcall(function() TargetIndicator:Remove() end)
        Rayfield:Destroy()
    end})

Rayfield:Notify({
    Title = _H("4b616e6861204875622076312e30"),
    Content = _H("52696768745368696674203d205549202020202020746965723a20") .. session.tier,
    Duration = 6,
})
