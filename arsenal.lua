--[[
    Kanha Hub v2 | Arsenal Edition
    UI : Rayfield | Exec : Real / Solara / Xeno / Delta / Potassium

    Changements v2 :
      - Rayfield partagé via _G.KanhaRayfield (pas de conflit loader/module)
      - Hooks avec filtre d'origine (pas de casse CameraController)
      - Silent Aim multi-method avec whitelist et cooldown humanisé
      - Kill Aura via firetouchinterest (safe) + TP fallback
      - Chams watcher (restaure si le jeu réplique)
      - Panic button global + keybind
      - Character cache (pas de FindFirstChild à chaque frame)
      - FPS-based throttling sur hooks et ESP
      - checkcaller polyfill (marche sur Delta aussi)
      - Anti-detection : random delay, pattern-break, humanisation
]]

local _H = function(h)
    local o = {}
    for i = 1, #h, 2 do o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16)) end
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
local StarterGui          = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetMouseLocation     = UserInputService.GetMouseLocation

------------------------------------------------------------
-- Polyfills exec (Delta / Xeno / Solara / Real)
------------------------------------------------------------
local function poly_checkcaller()
    return (checkcaller and checkcaller()) or false
end
local function poly_getrawmetatable(o)
    if getrawmetatable then return getrawmetatable(o) end
    if debug and debug.getmetatable then
        if setreadonly then setreadonly(o, false) end
        return debug.getmetatable(o)
    end
    return nil
end
local function poly_hookmetamethod(obj, method, fn)
    if hookmetamethod then return hookmetamethod(obj, method, fn) end
    local mt = poly_getrawmetatable(obj)
    if not mt then return nil end
    local old = mt[method]
    mt[method] = fn
    return old
end
local has_firetouchinterest = type(firetouchinterest) == "function"

------------------------------------------------------------
-- Rayfield (partagé si lancé depuis le loader)
------------------------------------------------------------
local Rayfield = _G.KanhaRayfield
if not Rayfield then
    Rayfield = loadstring(game:HttpGet(_H("68747470733a2f2f7369726975732e6d656e752f7261796669656c64")))()
    _G.KanhaRayfield = Rayfield
end

------------------------------------------------------------
-- Notify
------------------------------------------------------------
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 4,
        })
    end)
end

------------------------------------------------------------
-- State (structuré)
------------------------------------------------------------
local State = {
    Aimbot = {
        Enabled = false, Keybind = Enum.KeyCode.E,
        MouseBind = Enum.UserInputType.MouseButton2, UseMouseBind = false,
        Smoothness = 0.35, TargetPart = "Head", FOVRadius = 120,
        ShowFOV = true, FOVColor = Color3.fromRGB(255, 255, 255), FOVTransparency = 0.9,
        UsePrediction = false, Prediction = 0.165, UseAccel = false,
        TeamCheck = true, WallCheck = false, VisibleOnly = false,
        IgnoreForcefield = true, IgnoreInvisible = false,
        StickyTarget = false, StickyTime = 0.3,
    },
    Silent = {
        Enabled = false, Method = "FindPartOnRayWithIgnoreList",
        TargetPart = "Head", HitChance = 100, FOVRadius = 250,
        ShowTarget = false, TeamCheck = true, WallCheck = false,
        IgnoreForcefield = true, IgnoreInvisible = false,
        OriginFilterRadius = 30,
        CooldownBetweenHooks = 0.03,
    },
    Trigger = {
        Enabled = false, Delay = 0.08, AutoFire = false,
        UseKeybind = false, Keybind = Enum.UserInputType.MouseButton1,
        TeamCheck = true, WallCheck = false,
        IgnoreForcefield = true, IgnoreInvisible = false,
    },
    KillAura = {
        Enabled = false, Range = 15, Delay = 0.1, FlingMode = false,
        TeamCheck = true, WallCheck = false,
        IgnoreForcefield = true, IgnoreInvisible = false,
        UseTouchInterest = true,
    },
    KillAll = {
        Delay = 0.1, TeamCheck = true, WallCheck = false,
        IgnoreForcefield = true, IgnoreInvisible = false,
        UseRemote = false,
    },
    AutoFarm = { Enabled = false, Delay = 1.5 },
    ESP = {
        Enabled = false, Box = true, BoxFill = false, Name = true, Health = true,
        HealthBar = true, Distance = true, Tracer = false, Chams = false,
        MaxDistance = 2000,
        BoxColor = Color3.fromRGB(255, 60, 60),
        NameColor = Color3.fromRGB(255, 255, 255),
        DistanceColor = Color3.fromRGB(200, 200, 200),
        TracerColor = Color3.fromRGB(255, 60, 60),
        ChamsColor = Color3.fromRGB(255, 60, 60),
        ChamsTransparency = 0.4, TeamCheck = true,
    },
    Misc = {
        InfiniteAmmo = false, NoRecoil = false, NoSpread = false, NoCooldown = false,
        Fly = false, FlySpeed = 50, Noclip = false,
        WalkSpeed = 16, JumpPower = 50, Godmode = false,
        AntiAFK = false, HitMarker = false, FastEquip = false,
        TimeOfDay = "default",
    },
    Skin = { SelectedWeapon = nil, SelectedSkin = nil, AutoApply = false },
    Exploit = {
        TPOffset = -3, SelectedPlayer = nil,
        FreeTPEnabled = false, FreeTPKeybind = Enum.KeyCode.T,
        GoldenKnifeKeybind = Enum.KeyCode.G,
    },
    Panic = { Keybind = Enum.KeyCode.Delete },
}

------------------------------------------------------------
-- Internal
------------------------------------------------------------
local ESPObjects = {}
local ChamsObjects = {}
local ChamsWatcher = {}
local FlyConnection, NoclipConnection, GodmodeConnection, AntiAFKConnection
local MainLoopConnection, HeartbeatConnection
local AutoFarmThread, KillAuraThread, FreeTPConnection, TriggerbotThread, SkinAutoThread
local InputBeganConnection, InputEndedConnection
local KillAllRunning = false
local TriggerbotRunning = false

local FOVCircle        = Drawing.new("Circle")
local SilentFOVCircle  = Drawing.new("Circle")
local TargetIndicator  = Drawing.new("Circle")
local TriggerFOVCircle = Drawing.new("Circle")
local HitMarkers       = {}
local HitMarkerPool    = {}

local LastTarget, LastTargetTime = nil, 0
local TriggerbotCooldown = false
local SkinRemoteCache, SkinListCache = nil, nil
local GoldenKnifeCache, GoldenKnifeCacheTime = nil, 0
local WallCache = {}
local LastHookTime = 0

local MouseButtonStates = {
    [Enum.UserInputType.MouseButton1] = false,
    [Enum.UserInputType.MouseButton2] = false,
    [Enum.UserInputType.MouseButton3] = false,
}

------------------------------------------------------------
-- Character cache
------------------------------------------------------------
local CachedChar, CachedHum, CachedHRP = nil, nil, nil

local function refreshCharCache()
    CachedChar = LocalPlayer.Character
    CachedHum  = CachedChar and CachedChar:FindFirstChildOfClass("Humanoid")
    CachedHRP  = CachedChar and CachedChar:FindFirstChild("HumanoidRootPart")
end

local function getLocalCharacter()
    if not CachedChar or not CachedChar.Parent then refreshCharCache() end
    return CachedChar, CachedHum, CachedHRP
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    refreshCharCache()
end)
refreshCharCache()

------------------------------------------------------------
-- Utilities
------------------------------------------------------------
local function safeDisconnect(c) if c then pcall(function() c:Disconnect() end) end end
local function safeDestroy(i) if i and i.Parent then pcall(function() i:Destroy() end) end end

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
    params.FilterDescendantsInstances = { LocalPlayer.Character }
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
    if c and (now - c.t) < WALL_CACHE_TTL then return c.visible end
    local v = wallCheck(plr)
    WallCache[plr] = { visible = v, t = now }
    return v
end

local function isOnScreen(plr, partName)
    if not plr or not plr.Character then return false end
    local p = plr.Character:FindFirstChild(partName)
    if not p then return false end
    local sp, on = WorldToViewportPoint(Camera, p.Position)
    return on and sp.Z > 0
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
    if opts.VisibleOnly and not isOnScreen(plr, opts.TargetPart or "Head") then return false end
    return true
end

local function getDirection(o, t) return (t - o).Unit end

local function calculateChance(p)
    p = math.floor(p)
    if p >= 100 then return true end
    if p <= 0 then return false end
    return math.random(1, 100) <= p
end

local function humanizeDelay(base)
    return base + (math.random() * 0.02 - 0.01)
end

local function isAimActivated()
    if State.Aimbot.UseMouseBind then return MouseButtonStates[State.Aimbot.MouseBind] == true end
    return UserInputService:IsKeyDown(State.Aimbot.Keybind)
end

local function hasEquippedTool()
    local char = getLocalCharacter()
    if not char then return false end
    for _, c in ipairs(char:GetChildren()) do if c:IsA("Tool") then return true end end
    return false
end

------------------------------------------------------------
-- Input tracker
------------------------------------------------------------
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

------------------------------------------------------------
-- Drawings
------------------------------------------------------------
local function setupDrawing(d, kind)
    d.Visible = false
    d.Thickness = 1.5
    d.NumSides = kind == "Circle" and 64 or nil
    d.Filled = false
    d.Transparency = 0.9
    d.ZIndex = 999
end

setupDrawing(FOVCircle, "Circle")
FOVCircle.Radius = State.Aimbot.FOVRadius
FOVCircle.Color  = State.Aimbot.FOVColor

setupDrawing(SilentFOVCircle, "Circle")
SilentFOVCircle.Radius = State.Silent.FOVRadius
SilentFOVCircle.Color  = Color3.fromRGB(120, 200, 255)
SilentFOVCircle.Transparency = 0.85

setupDrawing(TargetIndicator, "Circle")
TargetIndicator.Radius = 8
TargetIndicator.Color  = Color3.fromRGB(255, 50, 50)
TargetIndicator.Thickness = 2

setupDrawing(TriggerFOVCircle, "Circle")
TriggerFOVCircle.Radius = 60
TriggerFOVCircle.Color  = Color3.fromRGB(255, 200, 60)
TriggerFOVCircle.Transparency = 0.85

------------------------------------------------------------
-- Hit markers (pool)
------------------------------------------------------------
local function getMarkerFromPool()
    if #HitMarkerPool > 0 then return table.remove(HitMarkerPool) end
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
    for _, line in ipairs(lines) do line.Visible = false end
    table.insert(HitMarkerPool, lines)
end

local function spawnHitMarker()
    if not State.Misc.HitMarker then return end
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
            hm.Lines[1].To   = Vector2.new(c.X - gap, c.Y - gap)
            hm.Lines[2].From = Vector2.new(c.X + gap, c.Y - gap)
            hm.Lines[2].To   = Vector2.new(c.X + gap + expand, c.Y - gap - expand)
            hm.Lines[3].From = Vector2.new(c.X - gap - expand, c.Y + gap + expand)
            hm.Lines[3].To   = Vector2.new(c.X - gap, c.Y + gap)
            hm.Lines[4].From = Vector2.new(c.X + gap, c.Y + gap)
            hm.Lines[4].To   = Vector2.new(c.X + gap + expand, c.Y + gap + expand)
            for _, line in ipairs(hm.Lines) do line.Transparency = alpha end
        end
    end
end

------------------------------------------------------------
-- Target finders
------------------------------------------------------------
local function findTargetScreen(opts)
    local closest, closestDist = nil, opts.FOVRadius
    local mousePos = GetMouseLocation(UserInputService)
    for _, plr in ipairs(Players:GetPlayers()) do
        if validate(plr, opts) then
            local tPart = plr.Character:FindFirstChild(opts.TargetPart)
            if tPart then
                local sPos, onScreen = WorldToViewportPoint(Camera, tPart.Position)
                if onScreen and sPos.Z > 0 then
                    local dist = (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude
                    if dist < closestDist then closest = tPart; closestDist = dist end
                end
            end
        end
    end
    return closest
end

local function findTarget3D(opts)
    local closest, closestDist = nil, math.huge
    local _, _, localHRP = getLocalCharacter()
    if not localHRP then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
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
        FOVRadius = State.Silent.FOVRadius, TargetPart = State.Silent.TargetPart,
        TeamCheck = State.Silent.TeamCheck, WallCheck = State.Silent.WallCheck,
        IgnoreForcefield = State.Silent.IgnoreForcefield, IgnoreInvisible = State.Silent.IgnoreInvisible,
    })
end

local function getAimbotTarget()
    return findTarget3D({
        TargetPart = State.Aimbot.TargetPart, TeamCheck = State.Aimbot.TeamCheck,
        WallCheck = State.Aimbot.WallCheck, IgnoreForcefield = State.Aimbot.IgnoreForcefield,
        IgnoreInvisible = State.Aimbot.IgnoreInvisible, VisibleOnly = State.Aimbot.VisibleOnly,
    })
end

local function getTriggerbotTarget()
    return findTargetScreen({
        FOVRadius = State.Aimbot.FOVRadius, TargetPart = State.Aimbot.TargetPart,
        TeamCheck = State.Trigger.TeamCheck, WallCheck = State.Trigger.WallCheck,
        IgnoreForcefield = State.Trigger.IgnoreForcefield, IgnoreInvisible = State.Trigger.IgnoreInvisible,
    })
end

------------------------------------------------------------
-- ESP
------------------------------------------------------------
local function createESP(plr)
    if not plr or plr == LocalPlayer or ESPObjects[plr] then return end
    local esp = {}
    esp.Box = Drawing.new("Square")
    esp.Box.Visible = false; esp.Box.Thickness = 1.5; esp.Box.Filled = false
    esp.Box.Transparency = 1; esp.Box.ZIndex = 10

    esp.BoxFill = Drawing.new("Square")
    esp.BoxFill.Visible = false; esp.BoxFill.Filled = true
    esp.BoxFill.Transparency = 0.15; esp.BoxFill.ZIndex = 9

    esp.Outline = Drawing.new("Square")
    esp.Outline.Visible = false; esp.Outline.Color = Color3.fromRGB(0, 0, 0)
    esp.Outline.Thickness = 1; esp.Outline.Filled = false
    esp.Outline.Transparency = 1; esp.Outline.ZIndex = 8

    esp.Name = Drawing.new("Text")
    esp.Name.Visible = false; esp.Name.Size = 14
    esp.Name.Center = true; esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0); esp.Name.ZIndex = 11

    esp.Health = Drawing.new("Text")
    esp.Health.Visible = false; esp.Health.Size = 12
    esp.Health.Center = true; esp.Health.Outline = true
    esp.Health.OutlineColor = Color3.fromRGB(0, 0, 0); esp.Health.ZIndex = 11

    esp.HealthBarBg = Drawing.new("Square")
    esp.HealthBarBg.Visible = false; esp.HealthBarBg.Filled = true
    esp.HealthBarBg.Color = Color3.fromRGB(30, 30, 30)
    esp.HealthBarBg.Transparency = 0.6; esp.HealthBarBg.ZIndex = 10

    esp.HealthBar = Drawing.new("Square")
    esp.HealthBar.Visible = false; esp.HealthBar.Filled = true
    esp.HealthBar.Transparency = 1; esp.HealthBar.ZIndex = 11

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

local function cleanupAllESP() for plr in pairs(ESPObjects) do removeESP(plr) end end

local function hideESP(esp)
    if not esp.Box.Visible then return end
    for _, k in ipairs({"Box","BoxFill","Outline","Name","Health","HealthBar","HealthBarBg","Distance","Tracer"}) do
        esp[k].Visible = false
    end
end

local function updateESP()
    local _, _, localHRP = getLocalCharacter()

    for plr, esp in pairs(ESPObjects) do
        local char = plr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        local valid = false
        if char and hum and hum.Health > 0 and hrp and head then
            if not (State.ESP.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                if localHRP then
                    local dist = (hrp.Position - localHRP.Position).Magnitude
                    valid = dist <= State.ESP.MaxDistance
                else valid = true end
            end
        end

        if not valid then hideESP(esp) else
            local headPos, onScreen = WorldToViewportPoint(Camera, head.Position)
            local feetPos, feetOn = WorldToViewportPoint(Camera, hrp.Position - Vector3.new(0, 3, 0))

            if onScreen and feetOn and headPos.Z > 0 then
                local height = math.abs(headPos.Y - feetPos.Y) * 1.1
                local width  = height * 0.7
                local x = headPos.X - width / 2
                local y = headPos.Y

                if State.ESP.Box then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(x, y)
                    esp.Box.Color = State.ESP.BoxColor
                    esp.Box.Visible = true
                    esp.Outline.Size = esp.Box.Size
                    esp.Outline.Position = esp.Box.Position
                    esp.Outline.Visible = true
                else
                    esp.Box.Visible = false; esp.Outline.Visible = false
                end

                if State.ESP.BoxFill then
                    esp.BoxFill.Size = esp.Box.Size
                    esp.BoxFill.Position = esp.Box.Position
                    esp.BoxFill.Color = State.ESP.BoxColor
                    esp.BoxFill.Visible = true
                else esp.BoxFill.Visible = false end

                if State.ESP.Name then
                    esp.Name.Text = plr.Name
                    esp.Name.Position = Vector2.new(headPos.X, y - 18)
                    esp.Name.Color = State.ESP.NameColor
                    esp.Name.Visible = true
                else esp.Name.Visible = false end

                if State.ESP.Health then
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

                if State.ESP.HealthBar then
                    local barW, barH = width, 3
                    local ratio = hum.Health / math.max(hum.MaxHealth, 1)
                    esp.HealthBarBg.Size = Vector2.new(barW, barH)
                    esp.HealthBarBg.Position = Vector2.new(x, y + height + 18)
                    esp.HealthBarBg.Visible = true

                    esp.HealthBar.Size = Vector2.new(barW * ratio, barH)
                    esp.HealthBar.Position = esp.HealthBarBg.Position
                    if ratio > 0.6 then esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
                    elseif ratio > 0.3 then esp.HealthBar.Color = Color3.fromRGB(255, 200, 0)
                    else esp.HealthBar.Color = Color3.fromRGB(255, 0, 0) end
                    esp.HealthBar.Visible = true
                else
                    esp.HealthBar.Visible = false; esp.HealthBarBg.Visible = false
                end

                if State.ESP.Distance and localHRP then
                    local dist = math.floor((hrp.Position - localHRP.Position).Magnitude)
                    esp.Distance.Text = dist .. "m"
                    esp.Distance.Position = Vector2.new(headPos.X, y - 34)
                    esp.Distance.Color = State.ESP.DistanceColor
                    esp.Distance.Visible = true
                else esp.Distance.Visible = false end

                if State.ESP.Tracer then
                    local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    esp.Tracer.From = sc
                    esp.Tracer.To = Vector2.new(headPos.X, headPos.Y + height)
                    esp.Tracer.Color = State.ESP.TracerColor
                    esp.Tracer.Visible = true
                else esp.Tracer.Visible = false end
            else hideESP(esp) end
        end
    end
end

------------------------------------------------------------
-- Chams (avec watcher anti-restauration)
------------------------------------------------------------
local function applyChamsToChar(plr)
    if not plr or ChamsObjects[plr] or not plr.Character then return end
    local parts = {}
    for _, part in ipairs(plr.Character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            table.insert(parts, {
                Part = part, OriginalColor = part.Color,
                OriginalMaterial = part.Material, OriginalTransparency = part.Transparency,
            })
            part.Color = State.ESP.ChamsColor
            part.Material = Enum.Material.Neon
            part.Transparency = State.ESP.ChamsTransparency
        end
    end
    ChamsObjects[plr] = parts
    ChamsWatcher[plr] = tick()
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
    ChamsWatcher[plr] = nil
end

local function cleanupAllChams() for plr in pairs(ChamsObjects) do removeChamsFromChar(plr) end end

local function refreshChamsColor()
    for _, chams in pairs(ChamsObjects) do
        for _, data in ipairs(chams) do
            if data.Part and data.Part.Parent then
                pcall(function()
                    data.Part.Color = State.ESP.ChamsColor
                    data.Part.Transparency = State.ESP.ChamsTransparency
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
    if State.ESP.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    return true
end

local function updateChams()
    if not State.ESP.Enabled or not State.ESP.Chams then
        if next(ChamsObjects) then cleanupAllChams() end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if chamsValidate(plr) then
            if not ChamsObjects[plr] then
                applyChamsToChar(plr)
            else
                local now = tick()
                if now - (ChamsWatcher[plr] or 0) > 1 then
                    ChamsWatcher[plr] = now
                    for _, data in ipairs(ChamsObjects[plr]) do
                        local p = data.Part
                        if p and p.Parent and (p.Color ~= State.ESP.ChamsColor or p.Material ~= Enum.Material.Neon) then
                            pcall(function()
                                p.Color = State.ESP.ChamsColor
                                p.Material = Enum.Material.Neon
                                p.Transparency = State.ESP.ChamsTransparency
                            end)
                        end
                    end
                end
            end
        else
            if ChamsObjects[plr] then removeChamsFromChar(plr) end
        end
    end
end

------------------------------------------------------------
-- Hooks (silent aim avec filtre d'origine + cooldown)
------------------------------------------------------------
local oldNamecall
local hook_ok = pcall(function()
    oldNamecall = poly_hookmetamethod(game, "__namecall", newcclosure(function(...)
        local method = getnamecallmethod()

        if method ~= "FindPartOnRayWithIgnoreList"
           and method ~= "FindPartOnRay"
           and method ~= "Raycast" then
            return oldNamecall(...)
        end

        local self = ...
        local args = {...}

        local function is_from_camera(origin)
            if typeof(origin) ~= "Vector3" then return false end
            return (origin - Camera.CFrame.Position).Magnitude < State.Silent.OriginFilterRadius
        end

        if self == Workspace and not poly_checkcaller() then
            local rayIndex, origin
            if method == "FindPartOnRayWithIgnoreList" and typeof(args[2]) == "Ray" and typeof(args[3]) == "table" then
                rayIndex, origin = 2, args[2].Origin
            elseif method == "FindPartOnRay" and typeof(args[2]) == "Ray" then
                rayIndex, origin = 2, args[2].Origin
            elseif method == "Raycast" and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3" then
                rayIndex, origin = 3, args[2]
            end

            if rayIndex and is_from_camera(origin) then
                if State.Silent.Enabled and (tick() - LastHookTime) > State.Silent.CooldownBetweenHooks then
                    if calculateChance(State.Silent.HitChance) then
                        local tPart = getSilentAimTarget()
                        if tPart then
                            LastHookTime = tick()
                            local dir = getDirection(origin, tPart.Position)
                            if method == "Raycast" then args[3] = dir
                            else args[2] = Ray.new(origin, dir) end
                            return oldNamecall(unpack(args))
                        end
                    end
                end

                if State.Misc.NoSpread then
                    if method == "Raycast" then args[3] = Camera.CFrame.LookVector
                    else args[2] = Ray.new(origin, Camera.CFrame.LookVector) end
                    return oldNamecall(unpack(args))
                end
            end
        end

        if method == "Fire" and State.Misc.InfiniteAmmo and typeof(self) == "Instance" and self:IsA("Tool") then
            for _, name in ipairs({"Ammo","Clip","Mag","CurrentAmmo","AmmoCount"}) do
                local v = self:FindFirstChild(name)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 999 end) end
            end
        end

        return oldNamecall(...)
    end))
end)

if not hook_ok then
    warn("[KanhaHub] __namecall hook failed — silent aim disabled")
end

local oldIndex
local index_hook_ok = pcall(function()
    oldIndex = poly_hookmetamethod(game, "__index", newcclosure(function(self, key)
        if self == Mouse and not poly_checkcaller() and State.Silent.Enabled then
            if State.Silent.Method == "Mouse.Hit/Target" then
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
end)

------------------------------------------------------------
-- Aimbot
------------------------------------------------------------
local function aimbotUpdate()
    if not State.Aimbot.Enabled then return end
    if not isAimActivated() then
        if TargetIndicator.Visible then TargetIndicator.Visible = false end
        LastTarget = nil
        return
    end

    local targetPart
    if State.Aimbot.StickyTarget and LastTarget and (tick() - LastTargetTime) < State.Aimbot.StickyTime then
        if LastTarget.Parent then
            local hum = LastTarget.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then targetPart = LastTarget
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
        if targetPart.Parent then
            local targetHRP = targetPart.Parent:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                if State.Aimbot.UsePrediction then
                    targetPos = targetPos + (targetHRP.Velocity * State.Aimbot.Prediction)
                end
                if State.Aimbot.UseAccel then
                    targetPos = targetPos + (targetHRP.Velocity * State.Aimbot.Prediction) * 0.5
                end
            end
        end
        local currentCFrame = Camera.CFrame
        local desiredCFrame = CFrame.new(currentCFrame.Position, targetPos)
        Camera.CFrame = currentCFrame:Lerp(desiredCFrame, State.Aimbot.Smoothness)
        LastTargetTime = tick()

        if State.Silent.ShowTarget then
            local sPos, onScreen = WorldToViewportPoint(Camera, targetPart.Position)
            if onScreen then
                TargetIndicator.Position = Vector2.new(sPos.X, sPos.Y)
                TargetIndicator.Visible = true
            else TargetIndicator.Visible = false end
        elseif TargetIndicator.Visible then TargetIndicator.Visible = false end
    elseif TargetIndicator.Visible then TargetIndicator.Visible = false end
end

------------------------------------------------------------
-- Triggerbot
------------------------------------------------------------
local hasMouse1Click   = type(mouse1click) == "function"
local hasMouse1Press   = type(mouse1press) == "function"
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
        while State.Trigger.Enabled do
            if not TriggerbotCooldown then
                local shouldFire = true
                if State.Trigger.UseKeybind and not MouseButtonStates[State.Trigger.Keybind] then shouldFire = false end
                if shouldFire then
                    local tPart = getTriggerbotTarget()
                    if tPart and hasEquippedTool() then
                        TriggerbotCooldown = true
                        if State.Trigger.AutoFire then fireWeapon() end
                        spawnHitMarker()
                        task.wait(humanizeDelay(math.max(State.Trigger.Delay, 0.05)))
                        TriggerbotCooldown = false
                    end
                end
            end
            task.wait(0.02)
        end
        TriggerbotRunning = false
    end)
end

------------------------------------------------------------
-- Movement
------------------------------------------------------------
local FLY_VEL_NAME  = _H("4b616e6861466c7956656c6f63697479")
local FLY_GYRO_NAME = _H("4b616e6861466c794779726f")

local function toggleFly(state)
    local _, _, hrp = getLocalCharacter()
    if state then
        if not hrp then return end
        safeDestroy(hrp:FindFirstChild(FLY_VEL_NAME))
        safeDestroy(hrp:FindFirstChild(FLY_GYRO_NAME))
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp; bv.Name = FLY_VEL_NAME
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 10000; bg.D = 100
        bg.Parent = hrp; bg.Name = FLY_GYRO_NAME
        safeDisconnect(FlyConnection)
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not hrp or not hrp.Parent then return end
            local moveDir = Vector3.zero
            local camCF = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
            local curBV = hrp:FindFirstChild(FLY_VEL_NAME)
            if curBV then curBV.Velocity = moveDir * State.Misc.FlySpeed end
            local curBG = hrp:FindFirstChild(FLY_GYRO_NAME)
            if curBG then curBG.CFrame = camCF end
        end)
    else
        safeDisconnect(FlyConnection); FlyConnection = nil
        local _, _, h = getLocalCharacter()
        if h then
            safeDestroy(h:FindFirstChild(FLY_VEL_NAME))
            safeDestroy(h:FindFirstChild(FLY_GYRO_NAME))
        end
    end
end

local function toggleNoclip(state)
    if state then
        safeDisconnect(NoclipConnection)
        NoclipConnection = RunService.Stepped:Connect(function()
            local c = getLocalCharacter()
            if not c or not c.Parent then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end)
    else
        safeDisconnect(NoclipConnection); NoclipConnection = nil
        local c = getLocalCharacter()
        if c and c.Parent then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
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

------------------------------------------------------------
-- Weapon mods
------------------------------------------------------------
local RECOIL_NAMES   = {"Recoil", "CamRecoil", "RecoilMultiplier", "RecoilAmount", "ViewRecoil"}
local SPREAD_NAMES   = {"Spread", "SpreadMultiplier", "SpreadAmount", "BaseSpread"}
local COOLDOWN_NAMES = {"Cooldown", "FireRate", "FireDelay", "CooldownTime", "Delay"}

local function applyWeaponMods()
    if not State.Misc.NoRecoil and not State.Misc.NoSpread and not State.Misc.NoCooldown then return end
    local char = getLocalCharacter()
    if not char then return end
    local function process(tool)
        if not tool:IsA("Tool") then return end
        if State.Misc.NoRecoil then
            for _, n in ipairs(RECOIL_NAMES) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
            end
        end
        if State.Misc.NoSpread then
            for _, n in ipairs(SPREAD_NAMES) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
            end
        end
        if State.Misc.NoCooldown then
            for _, n in ipairs(COOLDOWN_NAMES) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
            end
        end
    end
    for _, t in ipairs(char:GetChildren()) do process(t) end
    local pack = LocalPlayer:FindFirstChild("Backpack")
    if pack then for _, t in ipairs(pack:GetChildren()) do process(t) end end
    if State.Misc.NoRecoil then
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

------------------------------------------------------------
-- Skin changer
------------------------------------------------------------
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
                    SkinRemoteCache = r; return r
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
    local char = getLocalCharacter()
    if not char then return nil end
    for _, c in ipairs(char:GetChildren()) do if c:IsA("Tool") then return c end end
    return nil
end

local function applySkin(weaponName, skinName)
    local remote = findSkinRemote()
    local tool   = findCurrentWeapon()
    local tW = weaponName or (tool and tool.Name) or "Knife"
    local tS = skinName or State.Skin.SelectedSkin or "Default"
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
        if not State.Skin.AutoApply or not State.Skin.SelectedSkin then return end
        local tool = findCurrentWeapon()
        if tool then
            local hasSkin = false
            for _, n in ipairs({"Skin","CurrentSkin","SkinName"}) do
                local v = tool:FindFirstChild(n)
                if v and v:IsA("ValueBase") and v.Value == State.Skin.SelectedSkin then hasSkin = true; break end
            end
            if not hasSkin then applySkin(tool.Name, State.Skin.SelectedSkin) end
        end
    end)
end

------------------------------------------------------------
-- Exploits
------------------------------------------------------------
local function tpToPlayer(plr)
    if not plr or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local _, _, localHRP = getLocalCharacter()
    if not localHRP then return end
    localHRP.CFrame = CFrame.new(hrp.Position + hrp.CFrame.LookVector * (State.Exploit.TPOffset or -3))
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

    if has_firetouchinterest and State.KillAura.UseTouchInterest then
        local _, _, localHRP = getLocalCharacter()
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if localHRP and hrp then
            pcall(function()
                firetouchinterest(localHRP, hrp, 0)
                task.wait(0.02)
                firetouchinterest(localHRP, hrp, 1)
            end)
            return
        end
    end

    if State.KillAll.UseRemote then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local origin = Camera.CFrame.Position
            local dir = getDirection(origin, hrp.Position)
            for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
                if d:IsA("RemoteEvent") then
                    local nm = d.Name:lower()
                    if (nm == "hit" or nm == "damage" or nm:endswith("_hit") or nm:endswith("_damage")) then
                        for _, a in ipairs({{hrp.Position},{origin, dir}}) do
                            pcall(function() d:FireServer(unpack(a)) end)
                        end
                    end
                end
            end
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
                    TeamCheck = State.KillAll.TeamCheck, WallCheck = State.KillAll.WallCheck,
                    IgnoreForcefield = State.KillAll.IgnoreForcefield, IgnoreInvisible = State.KillAll.IgnoreInvisible,
                }) then
                    tpToPlayer(plr)
                    task.wait(humanizeDelay(State.KillAll.Delay))
                    killPlayer(plr)
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end)
                    task.wait(humanizeDelay(State.KillAll.Delay))
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
                    result = item; break
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
    local char = getLocalCharacter()
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
        if not State.KillAura.Enabled then return end
        local _, _, localHRP = getLocalCharacter()
        if not localHRP then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - localHRP.Position).Magnitude
                    if dist <= State.KillAura.Range then
                        if validate(plr, {
                            TeamCheck = State.KillAura.TeamCheck, WallCheck = State.KillAura.WallCheck,
                            IgnoreForcefield = State.KillAura.IgnoreForcefield, IgnoreInvisible = State.KillAura.IgnoreInvisible,
                        }) then
                            killPlayer(plr)
                            task.wait(humanizeDelay(State.KillAura.Delay))
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
        if not State.Exploit.FreeTPEnabled then return end
        if UserInputService:IsKeyDown(State.Exploit.FreeTPKeybind) then
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
        while State.AutoFarm.Enabled do
            killAll()
            task.wait(State.AutoFarm.Delay)
        end
        AutoFarmThread = nil
    end)
end

------------------------------------------------------------
-- Panic (kill switch global)
------------------------------------------------------------
local function panic()
    State.Aimbot.Enabled = false
    State.Silent.Enabled = false
    State.Trigger.Enabled = false
    State.KillAura.Enabled = false
    State.AutoFarm.Enabled = false
    State.ESP.Enabled = false
    State.ESP.Chams = false
    State.Misc.Fly = false
    State.Misc.Noclip = false
    State.Misc.Godmode = false
    State.Misc.NoRecoil = false
    State.Misc.NoSpread = false
    State.Misc.NoCooldown = false
    State.Misc.InfiniteAmmo = false
    State.Exploit.FreeTPEnabled = false
    toggleFly(false)
    toggleNoclip(false)
    toggleGodmode(false)
    cleanupAllChams()
    cleanupAllESP()
    if TargetIndicator.Visible then TargetIndicator.Visible = false end
    FOVCircle.Visible = false
    SilentFOVCircle.Visible = false
    TriggerFOVCircle.Visible = false
    notify("KanhaHub", "Panic — tout désactivé.", 3)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == State.Panic.Keybind then panic() end
    if input.KeyCode == State.Exploit.GoldenKnifeKeybind then equipGoldenKnife() end
end)

------------------------------------------------------------
-- Character respawn
------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    refreshCharCache()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.Misc.WalkSpeed
        hum.JumpPower = State.Misc.JumpPower
        hum.ChildAdded:Connect(function(c) if c:IsA("Tool") then onToolEquipped() end end)
        hum.ChildRemoved:Connect(function(c) if c:IsA("Tool") then onToolEquipped() end end)
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        safeDestroy(hrp:FindFirstChild(FLY_VEL_NAME))
        safeDestroy(hrp:FindFirstChild(FLY_GYRO_NAME))
    end
    if State.Misc.Fly then task.wait(0.3); toggleFly(true) end
    if State.Misc.Noclip then task.wait(0.3); toggleNoclip(true) end
    if State.ESP.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not ESPObjects[plr] then createESP(plr) end
        end
    end
end)

------------------------------------------------------------
-- Main loops (FPS-based throttle)
------------------------------------------------------------
local espTick, logicTick, weaponTick = 0, 0, 0
local ESP_INTERVAL    = 1 / 30
local CHAMS_INTERVAL  = 1 / 2
local WEAPON_INTERVAL = 1

MainLoopConnection = RunService.RenderStepped:Connect(function(dt)
    espTick = espTick + dt
    logicTick = logicTick + dt

    if State.ESP.Enabled and espTick >= ESP_INTERVAL then
        espTick = 0
        updateESP()
    end

    aimbotUpdate()

    if State.Aimbot.ShowFOV and State.Aimbot.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Radius = State.Aimbot.FOVRadius
        FOVCircle.Position = GetMouseLocation(UserInputService)
        FOVCircle.Color = State.Aimbot.FOVColor
        FOVCircle.Transparency = State.Aimbot.FOVTransparency
    elseif FOVCircle.Visible then FOVCircle.Visible = false end

    if State.Silent.ShowTarget and State.Silent.Enabled then
        SilentFOVCircle.Visible = true
        SilentFOVCircle.Radius = State.Silent.FOVRadius
        SilentFOVCircle.Position = GetMouseLocation(UserInputService)
    elseif SilentFOVCircle.Visible then SilentFOVCircle.Visible = false end

    if State.Trigger.Enabled then
        TriggerFOVCircle.Visible = true
        TriggerFOVCircle.Radius = State.Aimbot.FOVRadius
        TriggerFOVCircle.Position = GetMouseLocation(UserInputService)
    elseif TriggerFOVCircle.Visible then TriggerFOVCircle.Visible = false end

    updateHitMarkers()
end)

HeartbeatConnection = RunService.Heartbeat:Connect(function(dt)
    logicTick = logicTick + dt
    weaponTick = weaponTick + dt

    if logicTick >= CHAMS_INTERVAL then
        logicTick = 0
        updateChams()
    end

    if weaponTick >= WEAPON_INTERVAL then
        weaponTick = 0
        applyWeaponMods()
    end
end)

------------------------------------------------------------
-- Player connections
------------------------------------------------------------
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then createESP(plr) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        createESP(plr)
        if State.ESP.Enabled and State.ESP.Chams then
            task.wait(1)
            if plr.Character and chamsValidate(plr) then applyChamsToChar(plr) end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
    removeChamsFromChar(plr)
    WallCache[plr] = nil
end)

------------------------------------------------------------
-- Rayfield UI
------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = _H("417273656e616c202f2f204b616e6861204875622076322e30") .. (isVip and _H("205b5649505d") or ""),
    LoadingTitle = _H("4c6f6164696e67204b616e6861204875622076322e302e2e2e"),
    LoadingSubtitle = _H("6279204b616e6861"),
    Theme = "Dark",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    ConfigurationSaving = { Enabled = true, FolderName = "KanhaHub", FileName = "ArsenalV2" },
    KeySystem = false,
})

local CombatTab = Window:CreateTab(_H("436f6d626174"), 6031097226)

CombatTab:CreateSection(_H("53696c656e742041696d"))
CombatTab:CreateToggle({Name = _H("456e61626c652053696c656e742041696d"), CurrentValue = false, Flag = "SilentEnabled",
    Callback = function(v) State.Silent.Enabled = v end})
CombatTab:CreateDropdown({Name = _H("4d6574686f64"),
    Options = {"FindPartOnRayWithIgnoreList", "FindPartOnRay", "Raycast", "Mouse.Hit/Target"},
    CurrentOption = {"FindPartOnRayWithIgnoreList"}, Flag = "SilentMethod",
    Callback = function(opt) State.Silent.Method = typeof(opt) == "table" and opt[1] or opt end})
CombatTab:CreateDropdown({Name = _H("5461726765742050617274"), Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = {"Head"}, Flag = "SilentPart",
    Callback = function(opt) State.Silent.TargetPart = typeof(opt) == "table" and opt[1] or opt end})
CombatTab:CreateSlider({Name = _H("486974204368616e6365"), Range = {0, 100}, Increment = 1, Suffix = "%",
    CurrentValue = 100, Flag = "SilentChance",
    Callback = function(v) State.Silent.HitChance = v end})
CombatTab:CreateSlider({Name = _H("464f5620526164697573"), Range = {10, 800}, Increment = 1, Suffix = "px",
    CurrentValue = 250, Flag = "SilentFOV",
    Callback = function(v) State.Silent.FOVRadius = v end})
CombatTab:CreateSlider({Name = _H("4f726967696e2046696c746572"), Range = {5, 100}, Increment = 1, Suffix = " studs",
    CurrentValue = 30, Flag = "SilentOrigin",
    Callback = function(v) State.Silent.OriginFilterRadius = v end})
CombatTab:CreateToggle({Name = _H("5465616d20436865636b"), CurrentValue = true, Flag = "SilentTeam",
    Callback = function(v) State.Silent.TeamCheck = v end})
CombatTab:CreateToggle({Name = _H("57616c6c20436865636b"), CurrentValue = false, Flag = "SilentWall",
    Callback = function(v) State.Silent.WallCheck = v end})
CombatTab:CreateToggle({Name = _H("53686f772054617267657420496e64696361746f72"), CurrentValue = false, Flag = "SilentShow",
    Callback = function(v)
        State.Silent.ShowTarget = v
        if not v and TargetIndicator.Visible then TargetIndicator.Visible = false end
    end})

CombatTab:CreateSection(_H("41696d626f74"))
CombatTab:CreateToggle({Name = _H("456e61626c652041696d626f74"), CurrentValue = false, Flag = "AimbotEnabled",
    Callback = function(v)
        State.Aimbot.Enabled = v
        if not v then
            if TargetIndicator.Visible then TargetIndicator.Visible = false end
            LastTarget = nil
        end
    end})
CombatTab:CreateKeybind({Name = _H("41696d626f74204b6579"), CurrentKeybind = "E", HoldToInteract = false, Flag = "AimbotKey",
    Callback = function(k) State.Aimbot.Keybind = Enum.KeyCode[k] end})
CombatTab:CreateToggle({Name = _H("557365204d6f75736520427574746f6e"), CurrentValue = false, Flag = "AimbotMouse",
    Callback = function(v) State.Aimbot.UseMouseBind = v end})
CombatTab:CreateDropdown({Name = _H("4d6f75736520427574746f6e"),
    Options = {"MouseButton1 (Left)", "MouseButton2 (Right)", "MouseButton3 (Middle)"},
    CurrentOption = {"MouseButton2 (Right)"}, Flag = "AimbotMouseBtn",
    Callback = function(opt)
        local val = typeof(opt) == "table" and opt[1] or opt
        if val == "MouseButton1 (Left)" then State.Aimbot.MouseBind = Enum.UserInputType.MouseButton1
        elseif val == "MouseButton2 (Right)" then State.Aimbot.MouseBind = Enum.UserInputType.MouseButton2
        elseif val == "MouseButton3 (Middle)" then State.Aimbot.MouseBind = Enum.UserInputType.MouseButton3 end
    end})
CombatTab:CreateSlider({Name = _H("536d6f6f74686e657373"), Range = {0.01, 1}, Increment = 0.01, Suffix = "",
    CurrentValue = 0.35, Flag = "AimbotSmooth",
    Callback = function(v) State.Aimbot.Smoothness = v end})
CombatTab:CreateDropdown({Name = _H("41696d626f74205461726765742050617274"),
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = {"Head"}, Flag = "AimbotPart",
    Callback = function(opt) State.Aimbot.TargetPart = typeof(opt) == "table" and opt[1] or opt end})
CombatTab:CreateToggle({Name = _H("50726564696374696f6e"), CurrentValue = false, Flag = "AimbotPred",
    Callback = function(v) State.Aimbot.UsePrediction = v end})
CombatTab:CreateSlider({Name = _H("50726564696374696f6e20416d6f756e74"), Range = {0.01, 1}, Increment = 0.01, Suffix = "",
    CurrentValue = 0.165, Flag = "AimbotPredAmt",
    Callback = function(v) State.Aimbot.Prediction = v end})
CombatTab:CreateToggle({Name = _H("537469636b7920546172676574"), CurrentValue = false, Flag = "AimbotSticky",
    Callback = function(v) State.Aimbot.StickyTarget = v end})
CombatTab:CreateSlider({Name = _H("537469636b79204475726174696f6e"), Range = {0.1, 2}, Increment = 0.05, Suffix = "s",
    CurrentValue = 0.3, Flag = "AimbotStickyTime",
    Callback = function(v) State.Aimbot.StickyTime = v end})
CombatTab:CreateToggle({Name = _H("56697369626c65204f6e6c79"), CurrentValue = false, Flag = "AimbotVisible",
    Callback = function(v) State.Aimbot.VisibleOnly = v end})
CombatTab:CreateToggle({Name = _H("41696d626f74205465616d20436865636b"), CurrentValue = true, Flag = "AimbotTeam",
    Callback = function(v) State.Aimbot.TeamCheck = v end})
CombatTab:CreateToggle({Name = _H("41696d626f742057616c6c20436865636b"), CurrentValue = false, Flag = "AimbotWall",
    Callback = function(v) State.Aimbot.WallCheck = v end})

CombatTab:CreateSection(_H("54726967676572626f74"))
CombatTab:CreateToggle({Name = _H("456e61626c652054726967676572626f74"), CurrentValue = false, Flag = "TrigEnabled",
    Callback = function(v)
        State.Trigger.Enabled = v
        if v then triggerbotLoop() end
    end})
CombatTab:CreateToggle({Name = _H("4175746f2d46697265"), CurrentValue = false, Flag = "TrigAuto",
    Callback = function(v) State.Trigger.AutoFire = v end})
CombatTab:CreateToggle({Name = _H("557365204b657962696e64204f6e6c79"), CurrentValue = false, Flag = "TrigUseKey",
    Callback = function(v) State.Trigger.UseKeybind = v end})
CombatTab:CreateSlider({Name = _H("44656c6179"), Range = {0.05, 0.5}, Increment = 0.01, Suffix = "s",
    CurrentValue = 0.08, Flag = "TrigDelay",
    Callback = function(v) State.Trigger.Delay = v end})

local ExploitTab = Window:CreateTab(_H("4578706c6f697473"), 6031097226)
ExploitTab:CreateSection(_H("4b696c6c20416c6c"))
ExploitTab:CreateSlider({Name = _H("44656c6179"), Range = {0.05, 1}, Increment = 0.01, Suffix = "s",
    CurrentValue = 0.1, Flag = "KillAllDelay",
    Callback = function(v) State.KillAll.Delay = v end})
ExploitTab:CreateToggle({Name = _H("5465616d20436865636b"), CurrentValue = true, Flag = "KillAllTeam",
    Callback = function(v) State.KillAll.TeamCheck = v end})
ExploitTab:CreateToggle({Name = _H("57616c6c20436865636b"), CurrentValue = false, Flag = "KillAllWall",
    Callback = function(v) State.KillAll.WallCheck = v end})
ExploitTab:CreateToggle({Name = _H("5573652052656d6f7465202864616e6765726f7573)"), CurrentValue = false, Flag = "KillAllRemote",
    Callback = function(v)
        State.KillAll.UseRemote = v
        if v then notify("KanhaHub", "RemoteEvent kill = risque de ban.", 4) end
    end})
ExploitTab:CreateButton({Name = _H("4b494c4c20414c4c"), Callback = function() killAll() end})

ExploitTab:CreateSection(_H("4175746f204661726d"))
ExploitTab:CreateToggle({Name = _H("456e61626c65204175746f204661726d"), CurrentValue = false, Flag = "AutoFarmOn",
    Callback = function(v)
        State.AutoFarm.Enabled = v
        if v then startAutoFarm() end
    end})
ExploitTab:CreateSlider({Name = _H("4661726d2044656c6179"), Range = {0.5, 10}, Increment = 0.5, Suffix = "s",
    CurrentValue = 1.5, Flag = "AutoFarmDelay",
    Callback = function(v) State.AutoFarm.Delay = v end})

ExploitTab:CreateSection(_H("4b696c6c2041757261"))
ExploitTab:CreateToggle({Name = _H("456e61626c65204b696c6c2041757261"), CurrentValue = false, Flag = "KillAuraOn",
    Callback = function(v)
        State.KillAura.Enabled = v
        if v then startKillAura() end
    end})
ExploitTab:CreateSlider({Name = _H("52616e6765"), Range = {5, 100}, Increment = 1, Suffix = "m",
    CurrentValue = 15, Flag = "KillAuraRange",
    Callback = function(v) State.KillAura.Range = v end})
ExploitTab:CreateToggle({Name = _H("55736520546f756368496e746572657374"), CurrentValue = true, Flag = "KillAuraTouch",
    Callback = function(v) State.KillAura.UseTouchInterest = v end})

ExploitTab:CreateSection(_H("476f6c64656e204b6e696665"))
ExploitTab:CreateButton({
    Name = _H("457175697020476f6c64656e204b6e696665"),
    Callback = function()
        local ok = equipGoldenKnife()
        notify("Golden Knife", ok and "Equipped." or "Not found.", 3)
    end})
ExploitTab:CreateKeybind({Name = _H("476f6c64656e204b6e696665204b6579"), CurrentKeybind = "G", HoldToInteract = false, Flag = "GoldenKey",
    Callback = function(k) State.Exploit.GoldenKnifeKeybind = Enum.KeyCode[k] end})

local SkinTab = Window:CreateTab(_H("536b696e73"), 6031097226)
SkinTab:CreateSection(_H("536b696e204368616e676572"))
local skinList = scanSkins()
SkinTab:CreateDropdown({Name = _H("536b696e"), Options = skinList, CurrentOption = {}, Flag = "SkinSelect",
    Callback = function(opt) State.Skin.SelectedSkin = typeof(opt) == "table" and opt[1] or opt end})
SkinTab:CreateButton({
    Name = _H("4170706c7920746f2043757272656e7420576561706f6e"),
    Callback = function()
        if not State.Skin.SelectedSkin then
            notify("Skin", "Pick a skin first.", 3); return
        end
        local tool = findCurrentWeapon()
        if not tool then notify("Skin", "No weapon equipped.", 3); return end
        local ok = applySkin(tool.Name, State.Skin.SelectedSkin)
        notify("Skin", ok and ("OK: " .. State.Skin.SelectedSkin) or "Local fallback.", 3)
    end})
SkinTab:CreateToggle({Name = _H("4175746f2d4170706c79206f6e204571756970"), CurrentValue = false, Flag = "SkinAuto",
    Callback = function(v) State.Skin.AutoApply = v; if v then startSkinAuto() end end})

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
        State.Exploit.SelectedPlayer = Players:FindFirstChild(val)
    end})
Players.PlayerAdded:Connect(function() playerDropdown:Refresh(refreshPlayerList()) end)
Players.PlayerRemoving:Connect(function() playerDropdown:Refresh(refreshPlayerList()) end)
TPTab:CreateButton({Name = _H("545020746f2053656c6563746564"),
    Callback = function() if State.Exploit.SelectedPlayer then tpToPlayer(State.Exploit.SelectedPlayer) end end})
TPTab:CreateButton({Name = _H("4272696e672053656c6563746564"),
    Callback = function() if State.Exploit.SelectedPlayer then bringPlayer(State.Exploit.SelectedPlayer) end end})
TPTab:CreateButton({Name = _H("4252494e4720414c4c"), Callback = function() bringAll() end})
TPTab:CreateSection(_H("46726565205450"))
TPTab:CreateToggle({Name = _H("456e61626c652046726565205450"), CurrentValue = false, Flag = "FreeTPOn",
    Callback = function(v)
        State.Exploit.FreeTPEnabled = v
        if v then startFreeTP() end
    end})
TPTab:CreateKeybind({Name = _H("46726565205450204b6579"), CurrentKeybind = "T", HoldToInteract = false, Flag = "FreeTPKey",
    Callback = function(k) State.Exploit.FreeTPKeybind = Enum.KeyCode[k] end})

local VisualsTab = Window:CreateTab(_H("56697375616c73"), 6031097226)
VisualsTab:CreateSection(_H("455350"))
VisualsTab:CreateToggle({Name = _H("456e61626c6520455350"), CurrentValue = false, Flag = "ESPOn",
    Callback = function(v)
        State.ESP.Enabled = v
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then createESP(plr) end
            end
        else cleanupAllESP() end
    end})
VisualsTab:CreateToggle({Name = _H("426f78"), CurrentValue = true, Flag = "ESPBox",
    Callback = function(v) State.ESP.Box = v end})
VisualsTab:CreateToggle({Name = _H("426f782046696c6c"), CurrentValue = false, Flag = "ESPBoxFill",
    Callback = function(v) State.ESP.BoxFill = v end})
VisualsTab:CreateToggle({Name = _H("4e616d65"), CurrentValue = true, Flag = "ESPName",
    Callback = function(v) State.ESP.Name = v end})
VisualsTab:CreateToggle({Name = _H("4865616c7468"), CurrentValue = true, Flag = "ESPHealth",
    Callback = function(v) State.ESP.Health = v end})
VisualsTab:CreateToggle({Name = _H("4865616c746820426172"), CurrentValue = true, Flag = "ESPHealthBar",
    Callback = function(v) State.ESP.HealthBar = v end})
VisualsTab:CreateToggle({Name = _H("44697374616e6365"), CurrentValue = true, Flag = "ESPDist",
    Callback = function(v) State.ESP.Distance = v end})
VisualsTab:CreateToggle({Name = _H("547261636572"), CurrentValue = false, Flag = "ESPTracer",
    Callback = function(v) State.ESP.Tracer = v end})
VisualsTab:CreateToggle({Name = _H("4368616d73"), CurrentValue = false, Flag = "ESPChams",
    Callback = function(v)
        State.ESP.Chams = v
        if not v then cleanupAllChams() end
    end})
VisualsTab:CreateToggle({Name = _H("5465616d20436865636b"), CurrentValue = true, Flag = "ESPTeam",
    Callback = function(v) State.ESP.TeamCheck = v end})
VisualsTab:CreateSection(_H("436f6c6f7273"))
VisualsTab:CreateColorPicker({Name = _H("426f7820436f6c6f72"), Color = Color3.fromRGB(255, 60, 60), Flag = "ESPBoxCol",
    Callback = function(c) State.ESP.BoxColor = c end})
VisualsTab:CreateColorPicker({Name = _H("4e616d6520436f6c6f72"), Color = Color3.fromRGB(255, 255, 255), Flag = "ESPNameCol",
    Callback = function(c) State.ESP.NameColor = c end})
VisualsTab:CreateColorPicker({Name = _H("54726163657220436f6c6f72"), Color = Color3.fromRGB(255, 60, 60), Flag = "ESPTracerCol",
    Callback = function(c) State.ESP.TracerColor = c end})
VisualsTab:CreateColorPicker({Name = _H("4368616d7320436f6c6f72"), Color = Color3.fromRGB(255, 60, 60), Flag = "ESPChamsCol",
    Callback = function(c) State.ESP.ChamsColor = c; refreshChamsColor() end})

local PlayerTab = Window:CreateTab(_H("506c61796572"), 6031097226)
PlayerTab:CreateSection(_H("4d6f76656d656e74"))
PlayerTab:CreateSlider({Name = _H("57616c6b5370656564"), Range = {16, 500}, Increment = 1, Suffix = "",
    CurrentValue = 16, Flag = "WS",
    Callback = function(v)
        State.Misc.WalkSpeed = v
        local _, hum = getLocalCharacter()
        if hum then hum.WalkSpeed = v end
    end})
PlayerTab:CreateSlider({Name = _H("4a756d70506f776572"), Range = {50, 500}, Increment = 1, Suffix = "",
    CurrentValue = 50, Flag = "JP",
    Callback = function(v)
        State.Misc.JumpPower = v
        local _, hum = getLocalCharacter()
        if hum then hum.JumpPower = v end
    end})
PlayerTab:CreateToggle({Name = _H("466c79"), CurrentValue = false, Flag = "FlyOn",
    Callback = function(v) State.Misc.Fly = v; toggleFly(v) end})
PlayerTab:CreateSlider({Name = _H("466c79205370656564"), Range = {10, 500}, Increment = 1, Suffix = "",
    CurrentValue = 50, Flag = "FlySpeed",
    Callback = function(v) State.Misc.FlySpeed = v end})
PlayerTab:CreateToggle({Name = _H("4e6f636c6970"), CurrentValue = false, Flag = "NoclipOn",
    Callback = function(v) State.Misc.Noclip = v; toggleNoclip(v) end})
PlayerTab:CreateToggle({Name = _H("476f646d6f6465"), CurrentValue = false, Flag = "GodOn",
    Callback = function(v) State.Misc.Godmode = v; toggleGodmode(v) end})
PlayerTab:CreateSection(_H("576561706f6e"))
PlayerTab:CreateToggle({Name = _H("496e66696e69746520416d6d6f"), CurrentValue = false, Flag = "InfAmmo",
    Callback = function(v) State.Misc.InfiniteAmmo = v end})
PlayerTab:CreateToggle({Name = _H("4e6f205265636f696c"), CurrentValue = false, Flag = "NoRecoil",
    Callback = function(v) State.Misc.NoRecoil = v end})
PlayerTab:CreateToggle({Name = _H("4e6f20537072656164"), CurrentValue = false, Flag = "NoSpread",
    Callback = function(v) State.Misc.NoSpread = v end})
PlayerTab:CreateToggle({Name = _H("4e6f20436f6f6c646f776e"), CurrentValue = false, Flag = "NoCooldown",
    Callback = function(v) State.Misc.NoCooldown = v end})
PlayerTab:CreateSection(_H("5574696c697479"))
PlayerTab:CreateToggle({Name = _H("416e74692d41464b"), CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v) State.Misc.AntiAFK = v; toggleAntiAFK(v) end})
PlayerTab:CreateToggle({Name = _H("486974204d61726b6572"), CurrentValue = false, Flag = "HitMark",
    Callback = function(v) State.Misc.HitMarker = v end})

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
SettingsTab:CreateSection(_H("50616e6963"))
SettingsTab:CreateKeybind({Name = _H("50616e6963204b657962696e64"), CurrentKeybind = "Delete", HoldToInteract = false, Flag = "PanicKey",
    Callback = function(k) State.Panic.Keybind = Enum.KeyCode[k] end})
SettingsTab:CreateButton({Name = _H("50414e49432028546f75742044c3a97361637469766572)"),
    Callback = function() panic() end})
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
        State.AutoFarm.Enabled = false
        State.KillAura.Enabled = false
        State.Trigger.Enabled = false
        cleanupAllESP(); cleanupAllChams()
        WallCache = {}
        for _, hm in ipairs(HitMarkers) do releaseMarkerToPool(hm.Lines) end
        HitMarkers = {}
        for _, lines in ipairs(HitMarkerPool) do
            for _, line in ipairs(lines) do pcall(function() line:Remove() end) end
        end
        HitMarkerPool = {}
        pcall(function() FOVCircle:Remove() end)
        pcall(function() SilentFOVCircle:Remove() end)
        pcall(function() TargetIndicator:Remove() end)
        pcall(function() TriggerFOVCircle:Remove() end)
        Rayfield:Destroy()
    end})

notify("Kanha Hub v2.0", "Arsenal | tier: " .. session.tier .. " | Delete = panic", 6)
