--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║   RIVALS // KANHA HUB  v2.0                                  ║
    ║                                                              ║
    ║   Features: AutoLoad, Background Loader, Device Spoofer,     ║
    ║   Anti-Katana, Silent Aim, Aimbot, ESP, Triggerbot,           ║
    ║   Ragebot, Infinite Jump, Fly, Noclip, Skin Changer,         ║
    ║   Server Hop, Auto Loadout, and more.                        ║
    ║                                                              ║
    ║   Server: https://kanha-hub.loca.lt                          ║
    ║   Discord: https://discord.gg/n9vcsTdce                      ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════
-- SECTION 1 : CONFIG & AUTO-LOAD
-- ═══════════════════════════════════════════════════════════════

local _H = function(h)
    local o = {}
    for i = 1, #h, 2 do
        o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16))
    end
    return table.concat(o)
end

local AUTO_LOAD_FILE = "kanha_autoload.txt"
local AUTO_LOAD_ENABLED = true

local function loadAutoLoadSetting()
    if not isfile or not isfile(AUTO_LOAD_FILE) then return true end
    local ok, content = pcall(readfile, AUTO_LOAD_FILE)
    if ok and content then
        return content:lower():find("true") ~= nil
    end
    return true
end

local function saveAutoLoadSetting(state)
    if writefile then
        pcall(writefile, AUTO_LOAD_FILE, tostring(state))
    end
end

AUTO_LOAD_ENABLED = loadAutoLoadSetting()

local function enableAutoLoad()
    if not AUTO_LOAD_ENABLED then return end
    pcall(function()
        queue_on_teleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/moumou31k-cyber/scripts/refs/heads/main/kanha-loader.lua"))()
        ]])
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 2 : KEY SYSTEM
-- ═══════════════════════════════════════════════════════════════

local _SRV = "https://kanha-hub.loca.lt"
local _DISCORD = "https://discord.gg/n9vcsTdce"

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
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetMouseLocation     = UserInputService.GetMouseLocation

local function getHWID()
    local tries = {
        function() return gethwid and gethwid() end,
        function() return get_hwid and get_hwid() end,
        function() return syn and syn.get_hwid and syn.get_hwid() end,
        function() return KRNL_GET_HWID and KRNL_GET_HWID() end,
    }
    for _, f in ipairs(tries) do
        local ok, v = pcall(f)
        if ok and v and v ~= "" then return tostring(v) end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id and id ~= "" then return "rbx-" .. tostring(id):sub(1, 24) end
    return "unknown-" .. tostring(math.random(1e6, 1e7))
end

local HWID = getHWID()

local function httpRequest(o)
    local fn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if fn then
        local ok, r = pcall(fn, o)
        if ok and r then return {s = tonumber(r.StatusCode or r.Status) or 0, b = r.Body or r.body or ""} end
    end
    local ok, r = pcall(function()
        return HttpService:RequestAsync({Url = o.Url, Method = o.Method or "GET", Headers = o.Headers or {}, Body = o.Body})
    end)
    if ok and r then return {s = tonumber(r.StatusCode) or 0, b = r.Body or ""} end
    return {s = 0, b = ""}
end

local function validateKey(key)
    local res = httpRequest({
        Url = _SRV .. "/validate",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Bypass-Tunnel-Reminder"] = "true",
            ["User-Agent"] = "Roblox/KanhaRivals",
        },
        Body = HttpService:JSONEncode({key = key, hwid = HWID}),
    })
    if res.s == 0 then return false, "Serveur injoignable.", nil end
    local ok, d = pcall(function() return HttpService:JSONDecode(res.b) end)
    if not ok or type(d) ~= "table" then return false, "Réponse invalide.", nil end
    if d.ok ~= true then return false, tostring(d.msg or "Clé refusée."), nil end
    return true, "OK", {
        key = key,
        exp = tonumber(d.exp) or 0,
        tier = tostring(d.tier or "free"),
        sig = tostring(d.sig or ""),
        hwid = HWID,
    }
end

local CACHE = "kha_rivals_s.dat"

local function loadCache()
    if not (isfile and isfile(CACHE)) then return nil end
    local ok, raw = pcall(readfile, CACHE)
    if not ok or not raw then return nil end
    local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(d) ~= "table" or not d.k or not d.t then return nil end
    if os.time() - tonumber(d.t) > 86400 then pcall(delfile, CACHE); return nil end
    if d.h and d.h ~= HWID then pcall(delfile, CACHE); return nil end
    return d
end

local function saveCache(s)
    if writefile then
        pcall(writefile, CACHE, HttpService:JSONEncode({
            k = s.key, h = HWID, tier = s.tier, exp = s.exp, sig = s.sig, t = os.time()
        }))
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 3 : MENU (session-validated)
-- ═══════════════════════════════════════════════════════════════

local function _launchMenu(session)
    _G.KanhaSession = session
    local isVip = (session.tier == "vip" or session.tier == "vip+" or session.tier == "ami" or session.tier == "owner")

    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    -- ═══ STATE ═══
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
        Enabled = false, Method = "Raycast",
        TargetPart = "Head", HitChance = 100, FOVRadius = 250,
        ShowTarget = false, TeamCheck = true, WallCheck = false,
        IgnoreForcefield = true, IgnoreInvisible = false,
        AntiKatana = false,
    }

    local TriggerbotSettings = {
        Enabled = false, Delay = 0.08, AutoFire = false,
        TeamCheck = true, WallCheck = false,
        IgnoreForcefield = true, IgnoreInvisible = false,
    }

    local RageSettings = {
        Enabled = false, FullAuto = true, HitChance = 100,
        TargetPart = "Head",
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
        InfiniteJump = false,
        DeviceSpoofer = false, DeviceMode = "VR",
    }

    local SkinSettings = { SelectedWeapon = nil, SelectedSkin = nil, AutoApply = false }
    local ExploitSettings = {
        TPOffset = -3, SelectedPlayer = nil,
        FreeTPEnabled = false, FreeTPKeybind = Enum.KeyCode.T,
        GoldenKnifeKeybind = Enum.KeyCode.G,
    }

    local ESPObjects = {}
    local ChamsObjects = {}
    local FlyConnection, NoclipConnection, GodmodeConnection, AntiAFKConnection
    local MainLoopConnection, AutoFarmThread, KillAuraThread, FreeTPConnection, TriggerbotThread, SkinAutoThread
    local InfiniteJumpConnection
    local KillAllRunning = false
    local TriggerbotRunning = false

    local FOVCircle       = Drawing.new("Circle")
    local SilentFOVCircle = Drawing.new("Circle")
    local TargetIndicator = Drawing.new("Circle")
    local HitMarkers      = {}

    local LastTarget, LastTargetTime = nil, 0
    local TriggerbotCooldown = false
    local WeaponModTimer = 0
    local SkinRemoteCache, SkinListCache = nil, nil

    local MouseButtonStates = {
        [Enum.UserInputType.MouseButton1] = false,
        [Enum.UserInputType.MouseButton2] = false,
        [Enum.UserInputType.MouseButton3] = false,
    }

    -- ═══ UTILITIES ═══
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
        if opts.WallCheck and not wallCheck(plr) then return false end
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

    -- ═══ MOUSE TRACKING ═══
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if MouseButtonStates[input.UserInputType] ~= nil then MouseButtonStates[input.UserInputType] = true end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if MouseButtonStates[input.UserInputType] ~= nil then MouseButtonStates[input.UserInputType] = false end
    end)

    -- ═══ DRAWINGS ═══
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

    -- ═══ HIT MARKER ═══
    local function updateHitMarkers()
        for i = #HitMarkers, 1, -1 do
            local hm = HitMarkers[i]
            local alpha = 1 - ((tick() - hm.StartTime) / hm.Duration)
            if alpha <= 0 then
                for _, line in ipairs(hm.Lines) do pcall(function() line:Remove() end) end
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

    -- ═══ TARGET FINDERS ═══
    local function findTargetScreen(opts)
        local closest, closestDist = nil, opts.FOVRadius
        local mousePos = GetMouseLocation(UserInputService)
        for _, plr in ipairs(Players:GetPlayers()) do
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
        local closest, closestDist = nil, math.huge
        local localChar = LocalPlayer.Character
        if not localChar then return nil end
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
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

    -- ═══ ESP ═══
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

    local function espValidate(plr)
        if not plr or plr == LocalPlayer then return false end
        local char = plr.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if not char:FindFirstChild("HumanoidRootPart") then return false end
        if ESPSettings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
        return true
    end

    local function updateESP()
        for plr, esp in pairs(ESPObjects) do
            local valid = espValidate(plr)
            if valid then
                local localChar = LocalPlayer.Character
                if localChar then
                    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
                    if localHRP then
                        local dist = (plr.Character.HumanoidRootPart.Position - localHRP.Position).Magnitude
                        if dist > ESPSettings.MaxDistance then valid = false end
                    end
                end
            end
            if not valid then
                esp.Box.Visible = false; esp.Outline.Visible = false
                esp.Name.Visible = false; esp.Health.Visible = false
                esp.Distance.Visible = false; esp.Tracer.Visible = false
            else
                local char = plr.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                if hum and hrp and head then
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
                        else esp.Box.Visible = false; esp.Outline.Visible = false end
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
                        if ESPSettings.Distance then
                            local localChar = LocalPlayer.Character
                            if localChar then
                                local localHRP = localChar:FindFirstChild("HumanoidRootPart")
                                if localHRP then
                                    local dist = math.floor((hrp.Position - localHRP.Position).Magnitude)
                                    esp.Distance.Text = dist .. "m"
                                    esp.Distance.Position = Vector2.new(headPos.X, y - 34)
                                    esp.Distance.Color = ESPSettings.DistanceColor
                                    esp.Distance.Visible = true
                                end
                            end
                        else esp.Distance.Visible = false end
                        if ESPSettings.Tracer then
                            local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            esp.Tracer.From = sc
                            esp.Tracer.To = Vector2.new(headPos.X, headPos.Y + height)
                            esp.Tracer.Color = ESPSettings.TracerColor
                            esp.Tracer.Visible = true
                        else esp.Tracer.Visible = false end
                    else
                        esp.Box.Visible = false; esp.Outline.Visible = false
                        esp.Name.Visible = false; esp.Health.Visible = false
                        esp.Distance.Visible = false; esp.Tracer.Visible = false
                    end
                end
            end
        end
    end

    -- ═══ CHAMS ═══
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
        if not ESPSettings.Enabled or not ESPSettings.Chams then cleanupAllChams(); return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if chamsValidate(plr) then
                if not ChamsObjects[plr] then applyChamsToChar(plr) end
            else
                if ChamsObjects[plr] then removeChamsFromChar(plr) end
            end
        end
    end

    -- ═══ HOOKS ═══
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local method = getnamecallmethod()
        local self = ...
        local args = {...}

        if SilentAimSettings.Enabled and self == Workspace and not checkcaller() then
            local shouldRedirect = false
            local rayIndex = nil
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

        if MiscSettings.InfiniteAmmo and method == "Fire" then
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
        if SilentAimSettings.Enabled and self == Mouse and not checkcaller() then
            if SilentAimSettings.Method == "Mouse.Hit/Target" then
                local tPart = getSilentAimTarget()
                if tPart then
                    if key == "Target" then return tPart
                    elseif key == "Hit" then return tPart.CFrame end
                end
            end
        end
        return oldIndex(self, key)
    end))

    -- ═══ AIMBOT ═══
    local function aimbotUpdate()
        if not AimSettings.Enabled then return end
        local _, _, localHRP = getLocalCharacter()
        if not localHRP then return end
        if not isAimActivated() then
            TargetIndicator.Visible = false
            LastTarget = nil
            return
        end
        local targetPart
        if AimSettings.StickyTarget and LastTarget and (tick() - LastTargetTime) < AimSettings.StickyTime then
            if LastTarget.Parent and LastTarget.Parent:FindFirstChildOfClass("Humanoid") and LastTarget.Parent.Humanoid.Health > 0 then
                local plr = Players:GetPlayerFromCharacter(LastTarget.Parent)
                if plr and validate(plr, {
                    TeamCheck = AimSettings.TeamCheck, WallCheck = AimSettings.WallCheck,
                    IgnoreForcefield = AimSettings.IgnoreForcefield, IgnoreInvisible = AimSettings.IgnoreInvisible,
                }) then targetPart = LastTarget
                else LastTarget = nil end
            else LastTarget = nil end
        end
        if not targetPart then
            targetPart = getAimbotTarget()
            if targetPart then LastTarget = targetPart; LastTargetTime = tick() end
        end
        if targetPart then
            local targetPos = targetPart.Position
            if AimSettings.UsePrediction and targetPart.Parent then
                local targetHRP = targetPart.Parent:FindFirstChild("HumanoidRootPart")
                if targetHRP then targetPos = targetPos + (targetHRP.Velocity * AimSettings.Prediction) end
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
            else TargetIndicator.Visible = false end
        else TargetIndicator.Visible = false end
    end

    -- ═══ TRIGGERBOT ═══
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

    -- ═══ MOVEMENT ═══
    local function toggleFly(state)
        local _, _, hrp = getLocalCharacter()
        if state then
            if not hrp then return end
            safeDestroy(hrp:FindFirstChild("KanhaFlyVelocity"))
            safeDestroy(hrp:FindFirstChild("KanhaFlyGyro"))
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp; bv.Name = "KanhaFlyVelocity"
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.P = 10000; bg.D = 100
            bg.Parent = hrp; bg.Name = "KanhaFlyGyro"
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
                local curBV = hrp:FindFirstChild("KanhaFlyVelocity")
                if curBV then curBV.Velocity = moveDir * MiscSettings.FlySpeed end
                local curBG = hrp:FindFirstChild("KanhaFlyGyro")
                if curBG then curBG.CFrame = camCF end
            end)
        else
            safeDisconnect(FlyConnection); FlyConnection = nil
            local char = LocalPlayer.Character
            if char then
                local hrp2 = char:FindFirstChild("HumanoidRootPart")
                if hrp2 then
                    safeDestroy(hrp2:FindFirstChild("KanhaFlyVelocity"))
                    safeDestroy(hrp2:FindFirstChild("KanhaFlyGyro"))
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

    local function toggleInfiniteJump(state)
        if state then
            safeDisconnect(InfiniteJumpConnection)
            InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                local _, hum = getLocalCharacter()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            safeDisconnect(InfiniteJumpConnection)
            InfiniteJumpConnection = nil
        end
    end

    -- ═══ DEVICE SPOOFER ═══
    local function applyDeviceSpoofer()
        if not MiscSettings.DeviceSpoofer then return end
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local replication = remotes:FindFirstChild("Replication")
                if replication then
                    local fighter = replication:FindFirstChild("Fighter")
                    if fighter then
                        local setControls = fighter:FindFirstChild("SetControls")
                        if setControls and setControls:IsA("RemoteEvent") then
                            setControls:FireServer(MiscSettings.DeviceMode)
                        end
                    end
                end
            end
        end)
    end

    -- ═══ WEAPON MODS ═══
    local RECOIL_NAMES   = {"Recoil", "CamRecoil", "RecoilMultiplier", "RecoilAmount", "ViewRecoil"}
    local SPREAD_NAMES   = {"Spread", "SpreadMultiplier", "SpreadAmount", "BaseSpread"}
    local COOLDOWN_NAMES = {"Cooldown", "FireRate", "FireDelay", "CooldownTime", "Delay"}

    local function applyWeaponMods()
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
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do process(t) end
        if MiscSettings.NoRecoil then
            for _, n in ipairs(RECOIL_NAMES) do
                local v = Camera:FindFirstChild(n)
                if v and v:IsA("ValueBase") then pcall(function() v.Value = 0 end) end
            end
        end
    end

    -- ═══ SKIN CHANGER ═══
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

    -- ═══ EXPLOITS ═══
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
        local paths = {
            ReplicatedStorage:FindFirstChild("Tools"), ReplicatedStorage:FindFirstChild("Weapons"),
            ReplicatedStorage:FindFirstChild("Items"), ReplicatedStorage,
        }
        for _, c in ipairs(paths) do
            if c then
                for _, item in ipairs(c:GetDescendants()) do
                    local n = item.Name:lower()
                    if (n:find("gold") or n:find("golden")) and (n:find("knife") or n:find("melee") or n:find("blade")) then
                        return item
                    end
                end
            end
        end
        for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
            if item:IsA("Tool") and item.Name:lower():find("gold") then return item end
        end
        return nil
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

    -- ═══ RESPAWN ═══
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = MiscSettings.WalkSpeed
            hum.JumpPower = MiscSettings.JumpPower
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            safeDestroy(hrp:FindFirstChild("KanhaFlyVelocity"))
            safeDestroy(hrp:FindFirstChild("KanhaFlyGyro"))
        end
        if MiscSettings.Fly then task.wait(0.3); toggleFly(true) end
        if MiscSettings.Noclip then task.wait(0.3); toggleNoclip(true) end
        if MiscSettings.DeviceSpoofer then task.wait(0.5); applyDeviceSpoofer() end
        if ESPSettings.Enabled then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and not ESPObjects[plr] then createESP(plr) end
            end
        end
    end)

    -- ═══ MAIN LOOP ═══
    MainLoopConnection = RunService.RenderStepped:Connect(function(dt)
        if ESPSettings.Enabled then updateESP() end
        updateChams()
        aimbotUpdate()

        if AimSettings.ShowFOV and AimSettings.Enabled then
            FOVCircle.Visible = true
            FOVCircle.Radius = AimSettings.FOVRadius
            FOVCircle.Position = GetMouseLocation(UserInputService)
            FOVCircle.Color = AimSettings.FOVColor
            FOVCircle.Transparency = AimSettings.FOVTransparency
        else FOVCircle.Visible = false end

        if SilentAimSettings.ShowTarget and SilentAimSettings.Enabled then
            SilentFOVCircle.Visible = true
            SilentFOVCircle.Radius = SilentAimSettings.FOVRadius
            SilentFOVCircle.Position = GetMouseLocation(UserInputService)
        else SilentFOVCircle.Visible = false end

        updateHitMarkers()
        WeaponModTimer = WeaponModTimer + dt
        if WeaponModTimer > 0.15 then
            WeaponModTimer = 0
            applyWeaponMods()
        end
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then createESP(plr) end
    end
    Players.PlayerAdded:Connect(function(plr) if plr ~= LocalPlayer then createESP(plr) end end)
    Players.PlayerRemoving:Connect(function(plr) removeESP(plr); removeChamsFromChar(plr) end)

    -- ═══ UI ═══
    local Window = Rayfield:CreateWindow({
        Name = _H("526976616c73202f2f204b616e6861204875622076322e30") .. (isVip and _H("205b5649505d") or ""),
        LoadingTitle = _H("4c6f6164696e67204b616e6861204875622e2e2e"),
        LoadingSubtitle = _H("6279204b616e6861"),
        Theme = "Dark",
        ToggleUIKeybind = Enum.KeyCode.RightShift,
        ConfigurationSaving = { Enabled = true, FolderName = "KanhaHub", FileName = "RivalsConfig_v2" },
        KeySystem = false,
    })

    local CombatTab = Window:CreateTab("Combat", 6031097226)
    CombatTab:CreateSection("Silent Aim")
    CombatTab:CreateToggle({Name = "Enable Silent Aim", CurrentValue = false, Flag = "SilentEnabled",
        Callback = function(v) SilentAimSettings.Enabled = v end})
    CombatTab:CreateDropdown({Name = "Method",
        Options = {"Raycast", "FindPartOnRayWithIgnoreList", "Mouse.Hit/Target"},
        CurrentOption = {"Raycast"}, Flag = "SilentMethod",
        Callback = function(opt) SilentAimSettings.Method = typeof(opt) == "table" and opt[1] or opt end})
    CombatTab:CreateDropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart", "Torso"},
        CurrentOption = {"Head"}, Flag = "SilentPart",
        Callback = function(opt) SilentAimSettings.TargetPart = typeof(opt) == "table" and opt[1] or opt end})
    CombatTab:CreateSlider({Name = "Hit Chance", Range = {0, 100}, Increment = 1, Suffix = "%",
        CurrentValue = 100, Flag = "SilentChance",
        Callback = function(v) SilentAimSettings.HitChance = v end})
    CombatTab:CreateSlider({Name = "FOV Radius", Range = {10, 800}, Increment = 1, Suffix = "px",
        CurrentValue = 250, Flag = "SilentFOV",
        Callback = function(v) SilentAimSettings.FOVRadius = v end})
    CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "SilentTeam",
        Callback = function(v) SilentAimSettings.TeamCheck = v end})
    CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = false, Flag = "SilentWall",
        Callback = function(v) SilentAimSettings.WallCheck = v end})
    CombatTab:CreateToggle({Name = "Anti-Katana", CurrentValue = false, Flag = "SilentAntiKatana",
        Callback = function(v) SilentAimSettings.AntiKatana = v end})
    CombatTab:CreateToggle({Name = "Show Target Indicator", CurrentValue = false, Flag = "SilentShow",
        Callback = function(v)
            SilentAimSettings.ShowTarget = v
            if not v then TargetIndicator.Visible = false end
        end})

    CombatTab:CreateSection("Aimbot")
    CombatTab:CreateToggle({Name = "Enable Aimbot", CurrentValue = false, Flag = "AimbotEnabled",
        Callback = function(v)
            AimSettings.Enabled = v
            if not v then TargetIndicator.Visible = false; LastTarget = nil end
        end})
    CombatTab:CreateKeybind({Name = "Aimbot Key", CurrentKeybind = "E", HoldToInteract = false, Flag = "AimbotKey",
        Callback = function(k) AimSettings.Keybind = Enum.KeyCode[k] end})
    CombatTab:CreateToggle({Name = "Use Mouse Button", CurrentValue = false, Flag = "AimbotMouse",
        Callback = function(v) AimSettings.UseMouseBind = v end})
    CombatTab:CreateDropdown({Name = "Mouse Button",
        Options = {"MouseButton1 (Left)", "MouseButton2 (Right)", "MouseButton3 (Middle)"},
        CurrentOption = {"MouseButton2 (Right)"}, Flag = "AimbotMouseBtn",
        Callback = function(opt)
            local val = typeof(opt) == "table" and opt[1] or opt
            if val == "MouseButton1 (Left)" then AimSettings.MouseBind = Enum.UserInputType.MouseButton1
            elseif val == "MouseButton2 (Right)" then AimSettings.MouseBind = Enum.UserInputType.MouseButton2
            elseif val == "MouseButton3 (Middle)" then AimSettings.MouseBind = Enum.UserInputType.MouseButton3 end
        end})
    CombatTab:CreateSlider({Name = "Smoothness", Range = {0.01, 1}, Increment = 0.01, Suffix = "",
        CurrentValue = 0.35, Flag = "AimbotSmooth",
        Callback = function(v) AimSettings.Smoothness = v end})
    CombatTab:CreateDropdown({Name = "Aimbot Target Part", Options = {"Head", "HumanoidRootPart", "Torso"},
        CurrentOption = {"Head"}, Flag = "AimbotPart",
        Callback = function(opt) AimSettings.TargetPart = typeof(opt) == "table" and opt[1] or opt end})
    CombatTab:CreateToggle({Name = "Enable Prediction", CurrentValue = false, Flag = "AimbotPred",
        Callback = function(v) AimSettings.UsePrediction = v end})
    CombatTab:CreateSlider({Name = "Prediction Amount", Range = {0.01, 1}, Increment = 0.01, Suffix = "",
        CurrentValue = 0.165, Flag = "AimbotPredAmt",
        Callback = function(v) AimSettings.Prediction = v end})
    CombatTab:CreateToggle({Name = "Sticky Target", CurrentValue = false, Flag = "AimbotSticky",
        Callback = function(v) AimSettings.StickyTarget = v end})
    CombatTab:CreateSlider({Name = "Sticky Duration", Range = {0.1, 2}, Increment = 0.05, Suffix = "s",
        CurrentValue = 0.3, Flag = "AimbotStickyTime",
        Callback = function(v) AimSettings.StickyTime = v end})
    CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "AimbotTeam",
        Callback = function(v) AimSettings.TeamCheck = v end})
    CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = false, Flag = "AimbotWall",
        Callback = function(v) AimSettings.WallCheck = v end})

    CombatTab:CreateSection("Triggerbot")
    CombatTab:CreateToggle({Name = "Enable Triggerbot", CurrentValue = false, Flag = "TrigEnabled",
        Callback = function(v)
            TriggerbotSettings.Enabled = v
            if v then triggerbotLoop() end
        end})
    CombatTab:CreateToggle({Name = "Auto-Fire", CurrentValue = false, Flag = "TrigAuto",
        Callback = function(v) TriggerbotSettings.AutoFire = v end})
    CombatTab:CreateSlider({Name = "Delay", Range = {0.05, 0.5}, Increment = 0.01, Suffix = "s",
        CurrentValue = 0.08, Flag = "TrigDelay",
        Callback = function(v) TriggerbotSettings.Delay = v end})
    CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "TrigTeam",
        Callback = function(v) TriggerbotSettings.TeamCheck = v end})
    CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = false, Flag = "TrigWall",
        Callback = function(v) TriggerbotSettings.WallCheck = v end})

    local RageTab = Window:CreateTab("Rage", 6031097226)
    RageTab:CreateSection("Ragebot")
    RageTab:CreateToggle({Name = "Enable Ragebot", CurrentValue = false, Flag = "RageOn",
        Callback = function(v) RageSettings.Enabled = v end})
    RageTab:CreateToggle({Name = "Full Auto", CurrentValue = true, Flag = "RageFullAuto",
        Callback = function(v) RageSettings.FullAuto = v end})
    RageTab:CreateSlider({Name = "Hit Chance", Range = {0, 100}, Increment = 1, Suffix = "%",
        CurrentValue = 100, Flag = "RageChance",
        Callback = function(v) RageSettings.HitChance = v end})

    local ExploitTab = Window:CreateTab("Exploits", 6031097226)
    ExploitTab:CreateSection("Kill All")
    ExploitTab:CreateSlider({Name = "Delay", Range = {0.05, 1}, Increment = 0.01, Suffix = "s",
        CurrentValue = 0.1, Flag = "KillAllDelay",
        Callback = function(v) KillAllSettings.Delay = v end})
    ExploitTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "KillAllTeam",
        Callback = function(v) KillAllSettings.TeamCheck = v end})
    ExploitTab:CreateToggle({Name = "Wall Check", CurrentValue = false, Flag = "KillAllWall",
        Callback = function(v) KillAllSettings.WallCheck = v end})
    ExploitTab:CreateButton({Name = "KILL ALL", Callback = function() killAll() end})

    ExploitTab:CreateSection("Auto Farm")
    ExploitTab:CreateToggle({Name = "Enable Auto Farm", CurrentValue = false, Flag = "AutoFarmOn",
        Callback = function(v)
            AutoFarmSettings.Enabled = v
            if v then startAutoFarm() end
        end})
    ExploitTab:CreateSlider({Name = "Farm Delay", Range = {0.5, 10}, Increment = 0.5, Suffix = "s",
        CurrentValue = 1.5, Flag = "AutoFarmDelay",
        Callback = function(v) AutoFarmSettings.Delay = v end})

    ExploitTab:CreateSection("Kill Aura")
    ExploitTab:CreateToggle({Name = "Enable Kill Aura", CurrentValue = false, Flag = "KillAuraOn",
        Callback = function(v)
            KillAuraSettings.Enabled = v
            if v then startKillAura() end
        end})
    ExploitTab:CreateSlider({Name = "Range", Range = {5, 100}, Increment = 1, Suffix = "m",
        CurrentValue = 15, Flag = "KillAuraRange",
        Callback = function(v) KillAuraSettings.Range = v end})

    ExploitTab:CreateSection("Golden Knife")
    ExploitTab:CreateButton({
        Name = "Equip Golden Knife",
        Callback = function()
            local ok = equipGoldenKnife()
            Rayfield:Notify({Title = "Golden Knife", Content = ok and "Equipped." or "Not found.", Duration = 3})
        end})
    ExploitTab:CreateKeybind({Name = "Golden Knife Key", CurrentKeybind = "G", HoldToInteract = false, Flag = "GoldenKey",
        Callback = function(k) ExploitSettings.GoldenKnifeKeybind = Enum.KeyCode[k] end})
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == ExploitSettings.GoldenKnifeKeybind then equipGoldenKnife() end
    end)

    local SkinTab = Window:CreateTab("Skins", 6031097226)
    SkinTab:CreateSection("Skin Changer")
    local skinList = scanSkins()
    SkinTab:CreateDropdown({Name = "Skin", Options = skinList, CurrentOption = {}, Flag = "SkinSelect",
        Callback = function(opt) SkinSettings.SelectedSkin = typeof(opt) == "table" and opt[1] or opt end})
    SkinTab:CreateButton({
        Name = "Apply to Current Weapon",
        Callback = function()
            if not SkinSettings.SelectedSkin then
                Rayfield:Notify({Title = "Skin", Content = "Pick a skin first.", Duration = 3}); return
            end
            local tool = findCurrentWeapon()
            if not tool then
                Rayfield:Notify({Title = "Skin", Content = "No weapon equipped.", Duration = 3}); return
            end
            local ok = applySkin(tool.Name, SkinSettings.SelectedSkin)
            Rayfield:Notify({Title = "Skin", Content = ok and ("OK: " .. SkinSettings.SelectedSkin) or "Local fallback.", Duration = 3})
        end})
    SkinTab:CreateToggle({Name = "Auto-Apply on Equip", CurrentValue = false, Flag = "SkinAuto",
        Callback = function(v) SkinSettings.AutoApply = v; if v then startSkinAuto() end end})

    local TPTab = Window:CreateTab("Teleport", 6031097226)
    TPTab:CreateSection("TP to Player")
    local function refreshPlayerList()
        local l = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then table.insert(l, plr.Name) end
        end
        return l
    end
    local playerDropdown = TPTab:CreateDropdown({
        Name = "Select Player", Options = refreshPlayerList(), CurrentOption = {}, Flag = "TPSel",
        Callback = function(opt)
            local val = typeof(opt) == "table" and opt[1] or opt
            ExploitSettings.SelectedPlayer = Players:FindFirstChild(val)
        end})
    Players.PlayerAdded:Connect(function() playerDropdown:Refresh(refreshPlayerList()) end)
    Players.PlayerRemoving:Connect(function() playerDropdown:Refresh(refreshPlayerList()) end)
    TPTab:CreateButton({Name = "TP to Selected",
        Callback = function() if ExploitSettings.SelectedPlayer then tpToPlayer(ExploitSettings.SelectedPlayer) end end})
    TPTab:CreateButton({Name = "Bring Selected",
        Callback = function() if ExploitSettings.SelectedPlayer then bringPlayer(ExploitSettings.SelectedPlayer) end end})
    TPTab:CreateButton({Name = "BRING ALL", Callback = function() bringAll() end})
    TPTab:CreateSection("Free TP")
    TPTab:CreateToggle({Name = "Enable Free TP", CurrentValue = false, Flag = "FreeTPOn",
        Callback = function(v)
            ExploitSettings.FreeTPEnabled = v
            if v then startFreeTP() end
        end})
    TPTab:CreateKeybind({Name = "Free TP Key", CurrentKeybind = "T", HoldToInteract = false, Flag = "FreeTPKey",
        Callback = function(k) ExploitSettings.FreeTPKeybind = Enum.KeyCode[k] end})

    local VisualsTab = Window:CreateTab("Visuals", 6031097226)
    VisualsTab:CreateSection("ESP")
    VisualsTab:CreateToggle({Name = "Enable ESP", CurrentValue = false, Flag = "ESPOn",
        Callback = function(v)
            ESPSettings.Enabled = v
            if v then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then createESP(plr) end
                end
            else cleanupAllESP() end
        end})
    VisualsTab:CreateToggle({Name = "Box", CurrentValue = true, Flag = "ESPBox",
        Callback = function(v) ESPSettings.Box = v end})
    VisualsTab:CreateToggle({Name = "Name", CurrentValue = true, Flag = "ESPName",
        Callback = function(v) ESPSettings.Name = v end})
    VisualsTab:CreateToggle({Name = "Health", CurrentValue = true, Flag = "ESPHealth",
        Callback = function(v) ESPSettings.Health = v end})
    VisualsTab:CreateToggle({Name = "Distance", CurrentValue = true, Flag = "ESPDist",
        Callback = function(v) ESPSettings.Distance = v end})
    VisualsTab:CreateToggle({Name = "Tracer", CurrentValue = false, Flag = "ESPTracer",
        Callback = function(v) ESPSettings.Tracer = v end})
    VisualsTab:CreateToggle({Name = "Chams", CurrentValue = false, Flag = "ESPChams",
        Callback = function(v)
            ESPSettings.Chams = v
            if not v then cleanupAllChams() end
        end})
    VisualsTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "ESPTeam",
        Callback = function(v) ESPSettings.TeamCheck = v end})
    VisualsTab:CreateSection("Colors")
    VisualsTab:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 60, 60), Flag = "ESPBoxCol",
        Callback = function(c) ESPSettings.BoxColor = c end})
    VisualsTab:CreateColorPicker({Name = "Name Color", Color = Color3.fromRGB(255, 255, 255), Flag = "ESPNameCol",
        Callback = function(c) ESPSettings.NameColor = c end})
    VisualsTab:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(255, 60, 60), Flag = "ESPTracerCol",
        Callback = function(c) ESPSettings.TracerColor = c end})
    VisualsTab:CreateColorPicker({Name = "Chams Color", Color = Color3.fromRGB(255, 60, 60), Flag = "ESPChamsCol",
        Callback = function(c) ESPSettings.ChamsColor = c; refreshChamsColor() end})

    local PlayerTab = Window:CreateTab("Player", 6031097226)
    PlayerTab:CreateSection("Movement")
    PlayerTab:CreateSlider({Name = "WalkSpeed", Range = {16, 500}, Increment = 1, Suffix = "",
        CurrentValue = 16, Flag = "WS",
        Callback = function(v)
            MiscSettings.WalkSpeed = v
            local _, hum = getLocalCharacter()
            if hum then hum.WalkSpeed = v end
        end})
    PlayerTab:CreateSlider({Name = "JumpPower", Range = {50, 500}, Increment = 1, Suffix = "",
        CurrentValue = 50, Flag = "JP",
        Callback = function(v)
            MiscSettings.JumpPower = v
            local _, hum = getLocalCharacter()
            if hum then hum.JumpPower = v end
        end})
    PlayerTab:CreateToggle({Name = "Fly", CurrentValue = false, Flag = "FlyOn",
        Callback = function(v) MiscSettings.Fly = v; toggleFly(v) end})
    PlayerTab:CreateSlider({Name = "Fly Speed", Range = {10, 500}, Increment = 1, Suffix = "",
        CurrentValue = 50, Flag = "FlySpeed",
        Callback = function(v) MiscSettings.FlySpeed = v end})
    PlayerTab:CreateToggle({Name = "Noclip", CurrentValue = false, Flag = "NoclipOn",
        Callback = function(v) MiscSettings.Noclip = v; toggleNoclip(v) end})
    PlayerTab:CreateToggle({Name = "Godmode", CurrentValue = false, Flag = "GodOn",
        Callback = function(v) MiscSettings.Godmode = v; toggleGodmode(v) end})
    PlayerTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
        Callback = function(v) MiscSettings.InfiniteJump = v; toggleInfiniteJump(v) end})
    PlayerTab:CreateSection("Weapon")
    PlayerTab:CreateToggle({Name = "Infinite Ammo", CurrentValue = false, Flag = "InfAmmo",
        Callback = function(v) MiscSettings.InfiniteAmmo = v end})
    PlayerTab:CreateToggle({Name = "No Recoil", CurrentValue = false, Flag = "NoRecoil",
        Callback = function(v) MiscSettings.NoRecoil = v end})
    PlayerTab:CreateToggle({Name = "No Spread", CurrentValue = false, Flag = "NoSpread",
        Callback = function(v) MiscSettings.NoSpread = v end})
    PlayerTab:CreateToggle({Name = "No Cooldown", CurrentValue = false, Flag = "NoCooldown",
        Callback = function(v) MiscSettings.NoCooldown = v end})
    PlayerTab:CreateSection("Utility")
    PlayerTab:CreateToggle({Name = "Anti-AFK", CurrentValue = false, Flag = "AntiAFK",
        Callback = function(v) MiscSettings.AntiAFK = v; toggleAntiAFK(v) end})
    PlayerTab:CreateToggle({Name = "Hit Marker", CurrentValue = false, Flag = "HitMark",
        Callback = function(v) MiscSettings.HitMarker = v end})

    local MiscTab = Window:CreateTab("Misc", 6031097226)
    MiscTab:CreateSection("Device Spoofer")
    MiscTab:CreateToggle({Name = "Enable Device Spoofer", CurrentValue = false, Flag = "DevSpoof",
        Callback = function(v)
            MiscSettings.DeviceSpoofer = v
            if v then applyDeviceSpoofer() end
        end})
    MiscTab:CreateDropdown({Name = "Device Mode", Options = {"VR", "Touch", "Gamepad", "MouseKeyboard"},
        CurrentOption = {"VR"}, Flag = "DevMode",
        Callback = function(opt)
            MiscSettings.DeviceMode = typeof(opt) == "table" and opt[1] or opt
            if MiscSettings.DeviceSpoofer then applyDeviceSpoofer() end
        end})

    local SettingsTab = Window:CreateTab("Settings", 6031097226)
    SettingsTab:CreateSection("Server")
    SettingsTab:CreateButton({Name = "Rejoin Server",
        Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})
    SettingsTab:CreateButton({Name = "Server Hop",
        Callback = function()
            local ok, r = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
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
    SettingsTab:CreateSection("AutoLoad")
    SettingsTab:CreateToggle({Name = "AutoLoad on Teleport", CurrentValue = AUTO_LOAD_ENABLED, Flag = "AutoLoadOn",
        Callback = function(v)
            AUTO_LOAD_ENABLED = v
            saveAutoLoadSetting(v)
            if v then enableAutoLoad() end
        end})
    SettingsTab:CreateSection("Script")
    SettingsTab:CreateButton({
        Name = "Unload Script",
        Callback = function()
            safeDisconnect(MainLoopConnection); safeDisconnect(FlyConnection)
            safeDisconnect(NoclipConnection); safeDisconnect(GodmodeConnection)
            safeDisconnect(AntiAFKConnection); safeDisconnect(KillAuraThread)
            safeDisconnect(FreeTPConnection); safeDisconnect(SkinAutoThread)
            safeDisconnect(InfiniteJumpConnection)
            AutoFarmSettings.Enabled = false; KillAuraSettings.Enabled = false
            TriggerbotSettings.Enabled = false
            cleanupAllESP(); cleanupAllChams()
            for _, hm in ipairs(HitMarkers) do
                for _, line in ipairs(hm.Lines) do pcall(function() line:Remove() end) end
            end
            HitMarkers = {}
            pcall(function() FOVCircle:Remove() end)
            pcall(function() SilentFOVCircle:Remove() end)
            pcall(function() TargetIndicator:Remove() end)
            Rayfield:Destroy()
        end})

    -- Auto-load on start if enabled
    if AUTO_LOAD_ENABLED then enableAutoLoad() end

    Rayfield:Notify({
        Title = _H("4b616e6861205275616c732076322e30"),
        Content = _H("52696768745368696674203d205549202020202020746965723a20") .. session.tier,
        Duration = 6,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 4 : KEY UI
-- ═══════════════════════════════════════════════════════════════

local function _showUI(cb)
    local old = PlayerGui:FindFirstChild("KhaUI")
    if old then old:Destroy() end

    local g = Instance.new("ScreenGui")
    g.Name = "KhaUI"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.DisplayOrder = 9999
    g.Parent = PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
    bg.BackgroundTransparency = 0.12
    bg.BorderSizePixel = 0
    bg.Parent = g

    local c = Instance.new("Frame")
    c.Size = UDim2.new(0, 460, 0, 290)
    c.Position = UDim2.new(0.5, -230, 0.5, -145)
    c.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    c.BorderSizePixel = 0
    c.Parent = g
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 14)

    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(80, 120, 220)
    st.Thickness = 1.5
    st.Transparency = 0.35
    st.Parent = c

    local ac = Instance.new("Frame")
    ac.Size = UDim2.new(1, -40, 0, 3)
    ac.Position = UDim2.new(0, 20, 0, 0)
    ac.BackgroundColor3 = Color3.fromRGB(90, 130, 230)
    ac.BorderSizePixel = 0
    ac.Parent = c
    Instance.new("UICorner", ac).CornerRadius = UDim.new(1, 0)

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, 0, 0, 44)
    ttl.Position = UDim2.new(0, 0, 0, 22)
    ttl.BackgroundTransparency = 1
    ttl.Font = Enum.Font.GothamBold
    ttl.TextSize = 24
    ttl.TextColor3 = Color3.fromRGB(235, 240, 255)
    ttl.Text = _H("4b414e4841204b45592053595354454d")
    ttl.Parent = c

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0, 66)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(150, 160, 180)
    sub.Text = _H("456e74726520746120636cc3a920706f757220636f6e74696e756572")
    sub.Parent = c

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -60, 0, 44)
    box.Position = UDim2.new(0, 30, 0, 108)
    box.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Code
    box.TextSize = 15
    box.TextColor3 = Color3.fromRGB(235, 240, 255)
    box.PlaceholderText = _H("4b414e48412d585858582d585858582d58585858")
    box.PlaceholderColor3 = Color3.fromRGB(90, 100, 125)
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = c
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(60, 70, 92)
    bs.Thickness = 1
    bs.Parent = box

    local stat = Instance.new("TextLabel")
    stat.Size = UDim2.new(1, -60, 0, 22)
    stat.Position = UDim2.new(0, 30, 0, 162)
    stat.BackgroundTransparency = 1
    stat.Font = Enum.Font.Gotham
    stat.TextSize = 12
    stat.TextColor3 = Color3.fromRGB(150, 160, 180)
    stat.Text = ""
    stat.TextXAlignment = Enum.TextXAlignment.Left
    stat.Parent = c

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -60, 0, 46)
    btn.Position = UDim2.new(0, 30, 0, 192)
    btn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = _H("56414c49444552")
    btn.AutoButtonColor = false
    btn.Parent = c
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local gk = Instance.new("TextButton")
    gk.Size = UDim2.new(1, -60, 0, 18)
    gk.Position = UDim2.new(0, 30, 0, 252)
    gk.BackgroundTransparency = 1
    gk.Font = Enum.Font.Gotham
    gk.TextSize = 12
    gk.TextColor3 = Color3.fromRGB(100, 160, 255)
    gk.Text = _H("4f6274656e697220756e6520636cc3a920202020") .. _DISCORD
    gk.Parent = c

    local dr, dS, sP
    ttl.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dr = true; dS = i.Position; sP = c.Position
        end
    end)
    ttl.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dr = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dr and i.UserInputType == Enum.UserInputType.MouseMovement then
            local h = i.Position - dS
            c.Position = UDim2.new(sP.X.Scale, sP.X.Offset + h.X, sP.Y.Scale, sP.Y.Offset + h.Y)
        end
    end)

    local v = false
    local function setStat(t, col)
        stat.Text = t
        stat.TextColor3 = col or Color3.fromRGB(150, 160, 180)
    end

    local function fadeOut(s)
        local tw = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(bg, tw, {BackgroundTransparency = 1}):Play()
        TweenService:Create(c, tw, {BackgroundTransparency = 1}):Play()
        for _, ch in ipairs(c:GetDescendants()) do
            if ch:IsA("TextLabel") or ch:IsA("TextButton") then
                pcall(function() TweenService:Create(ch, tw, {TextTransparency = 1}):Play() end)
            end
        end
        task.wait(0.4)
        g:Destroy()
        if cb then cb(s) end
    end

    local function attempt()
        if v then return end
        local k = box.Text:gsub("%s+", "")
        if k == "" then setStat(_H("456e74726520756e6520636cc3a92e"), Color3.fromRGB(230, 90, 90)); return end
        v = true
        btn.Text = _H("56c3a952494649434154494f4e2e2e2e")
        btn.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
        setStat(_H("436f6e7461637420647520736572766575722e2e2e"), Color3.fromRGB(210, 200, 120))
        task.spawn(function()
            local ok, msg, s = validateKey(k)
            if ok then
                setStat(_H("e29c93") .. " " .. msg, Color3.fromRGB(90, 220, 130))
                btn.Text = _H("e29c93") .. " " .. _H("414343c38853204155544f524953c389")
                btn.BackgroundColor3 = Color3.fromRGB(50, 165, 95)
                saveCache(s)
                task.wait(0.7)
                fadeOut(s)
            else
                setStat(_H("e29c97") .. " " .. msg, Color3.fromRGB(230, 90, 90))
                btn.Text = _H("56414c49444552")
                btn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
                v = false
            end
        end)
    end

    btn.MouseButton1Click:Connect(attempt)
    box.FocusLost:Connect(function(e) if e then attempt() end end)
    gk.MouseButton1Click:Connect(function()
        setStat(_H("436f7069c3a9"), Color3.fromRGB(150, 180, 240))
        if setclipboard then pcall(setclipboard, _DISCORD) end
    end)
    task.wait(0.15)
    box:CaptureFocus()
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 5 : START
-- ═══════════════════════════════════════════════════════════════

local cached = loadCache()
if cached then
    task.spawn(function()
        local ok, _, s = validateKey(cached.k)
        if ok then
            saveCache(s)
            _launchMenu(s)
        else
            pcall(delfile, CACHE)
            _showUI(_launchMenu)
        end
    end)
else
    _showUI(_launchMenu)
end
