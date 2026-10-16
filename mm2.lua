local _H = function(h)
    local o = {}
    for i = 1, #h, 2 do
        o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16))
    end
    return table.concat(o)
end

local _SRV = "https://kanha-hub.loca.lt"
local _DISCORD = "https://discord.gg/n9vcsTdce"

local Players             = game:GetService("Players")
local HttpService         = game:GetService("HttpService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local Lighting            = game:GetService("Lighting")
local TeleportService     = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetMouseLocation     = UserInputService.GetMouseLocation

local Rayfield = loadstring(game:HttpGet(_H("68747470733a2f2f7369726975732e6d656e752f7261796669656c64")))()

-- ═══════════════════════════════════════════════════════════════
-- HWID + KEY
-- ═══════════════════════════════════════════════════════════════

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
            ["User-Agent"] = "Roblox/KanhaMM2",
        },
        Body = HttpService:JSONEncode({key = key, hwid = HWID}),
    })
    if res.s == 0 then return false, "Serveur injoignable.", nil end
    local ok, d = pcall(function() return HttpService:JSONDecode(res.b) end)
    if not ok or type(d) ~= "table" then return false, "Réponse invalide.", nil end
    if d.ok ~= true then return false, tostring(d.msg or "Clé refusée."), nil end
    return true, "OK", { key = key, exp = tonumber(d.exp) or 0, tier = tostring(d.tier or "free"), sig = tostring(d.sig or ""), hwid = HWID }
end

local CACHE = "kha_mm2_s.dat"

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
-- MENU
-- ═══════════════════════════════════════════════════════════════

local function _launchMenu(session)
    _G.KanhaSession = session
    local isVip = (session.tier == "vip" or session.tier == "vip+" or session.tier == "ami" or session.tier == "owner")

    -- ═══════════════════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════════════════

    local ESPSettings = {
        Enabled = false,
        Role = true, Name = true, Distance = true,
        Box = true, Health = false,
        ItemESP = true, CoinESP = true, GunESP = true,
        Tracer = false,
        MurdererColor = Color3.fromRGB(255, 50, 50),
        SheriffColor = Color3.fromRGB(80, 150, 255),
        InnocentColor = Color3.fromRGB(80, 255, 80),
        HeroColor = Color3.fromRGB(255, 200, 60),
        SuspectColor = Color3.fromRGB(255, 100, 0),
        ItemColor = Color3.fromRGB(255, 220, 80),
        CoinColor = Color3.fromRGB(255, 180, 30),
        GunColor = Color3.fromRGB(200, 100, 255),
        MaxDistance = 2000,
    }

    local AimSettings = {
        Enabled = false, SilentEnabled = false,
        Keybind = Enum.KeyCode.E,
        MouseBind = Enum.UserInputType.MouseButton2, UseMouseBind = false,
        Smoothness = 0.35, TargetPart = "Head",
        FOVRadius = 120, ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 255, 255),
        ShowTarget = true,
        UsePrediction = false, Prediction = 0.165,
        StickyTarget = false, StickyTime = 0.5,
    }

    local AutoShootSettings = {
        Enabled = false, Delay = 0.15,
        TargetMurderer = true, TargetSheriff = false, TargetInnocent = false,
        RequireGun = true,
    }

    local KillSettings = {
        AutoKillSheriff = false, AutoKillInnocent = false,
        AutoKillMurderer = false,
        KnifeRange = 30,
        FlingEnabled = false,
    }

    local AutoPickupSettings = {
        AutoPickupGun = false, AutoPickupCoins = false, AutoPickupDelay = 0.5,
    }

    local MiscSettings = {
        Fly = false, FlySpeed = 60,
        Noclip = false,
        WalkSpeed = 16, JumpPower = 50,
        InfiniteJump = false,
        AntiAFK = false,
        AutoFarmCoins = false,
        FarmDelay = 3,
        Fullbright = false,
        AutoRespawn = false,
    }

    local DetectorSettings = {
        NotifyMurderer = true,
        NotifySheriff = true,
        NotifyGun = true,
        NotifyKnife = true,
    }

    local DetectionSettings = {
        Enabled = true,
        SpeedThreshold = 60,
        TPThreshold = 100,
        NotifyOnDetection = true,
        MarkInESP = true,
    }

    -- ═══════════════════════════════════════════════════════════
    -- INTERNAL
    -- ═══════════════════════════════════════════════════════════

    local ESPObjects = {}
    local ItemESPObjects = {}
    local HitMarkers = {}
    local HitMarkerPool = {}
    local NotifiedItems = {}
    local RoleNotified = {}
    local SuspiciousPlayers = {}
    local PlayerHistory = {}

    local FlyConnection, NoclipConnection, AntiAFKConnection, AutoFarmThread
    local RenderConnection, HeartbeatConnection, AutoShootThread, KillAuraThread
    local AutoPickupThread, InfJumpConnection
    local InputBeganConnection, InputEndedConnection
    local aimbotBindName = "KanhaAimMM2_" .. tostring(math.random(1, 99999))

    local FOVCircle = Drawing.new("Circle")
    local TargetIndicator = Drawing.new("Circle")

    local LastTarget, LastTargetTime = nil, 0
    local AutoFarmRunning = false
    local AutoShootCooldown = false

    local OriginalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
    }

    local MouseButtonStates = {
        [Enum.UserInputType.MouseButton1] = false,
        [Enum.UserInputType.MouseButton2] = false,
        [Enum.UserInputType.MouseButton3] = false,
    }

    -- ═══════════════════════════════════════════════════════════
    -- UTILITIES
    -- ═══════════════════════════════════════════════════════════

    local function safeDisconnect(c) if c then pcall(function() c:Disconnect() end) end end
    local function safeDestroy(i) if i and i.Parent then pcall(function() i:Destroy() end) end end

    local function getLocalCharacter()
        local char = LocalPlayer.Character
        if not char then return nil, nil, nil end
        return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    end

    local GUN_NAMES = {"gun", "revolver", "pistol", "sheriff", "hero"}
    local KNIFE_NAMES = {"knife", "blade", "dagger"}

    local function containerHas(container, names)
        if not container then return false end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                for _, name in ipairs(names) do
                    if n == name or n:find(name) then return true end
                end
            end
        end
        return false
    end

    local function getPlayerRole(plr)
        if not plr then return "Unknown" end
        local char = plr.Character
        if not char then return "Unknown" end
        local backpack = plr:FindFirstChild("Backpack")

        local hasKnife = containerHas(char, KNIFE_NAMES) or containerHas(backpack, KNIFE_NAMES)
        local hasGun = containerHas(char, GUN_NAMES) or containerHas(backpack, GUN_NAMES)

        if hasKnife then return "Murderer" end
        if hasGun then return "Sheriff" end
        return "Innocent"
    end

    local function roleColor(role)
        if role == "Murderer" then return ESPSettings.MurdererColor end
        if role == "Sheriff" then return ESPSettings.SheriffColor end
        if role == "Hero" then return ESPSettings.HeroColor end
        return ESPSettings.InnocentColor
    end

    local function validate(plr, opts)
        if not plr or plr == LocalPlayer then return false end
        local char = plr.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if not char:FindFirstChild("HumanoidRootPart") then return false end
        return true
    end

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

    -- ═══════════════════════════════════════════════════════════
    -- EXECUTOR / CHEATER DETECTION
    -- ═══════════════════════════════════════════════════════════

    local function flagPlayer(plr, reason)
        if not plr then return end
        if not SuspiciousPlayers[plr] then
            SuspiciousPlayers[plr] = { reasons = {}, score = 0, t = tick() }
        end
        if not SuspiciousPlayers[plr].reasons[reason] then
            SuspiciousPlayers[plr].reasons[reason] = true
            SuspiciousPlayers[plr].score = SuspiciousPlayers[plr].score + 1
            SuspiciousPlayers[plr].t = tick()
            if DetectionSettings.NotifyOnDetection then
                Rayfield:Notify({
                    Title = "SUSPECT DETECTE",
                    Content = plr.Name .. " : " .. reason,
                    Duration = 6,
                })
            end
        end
    end

    local function getSuspicionScore(plr)
        local s = SuspiciousPlayers[plr]
        return s and s.score or 0
    end

    local function updateDetection(dt)
        if not DetectionSettings.Enabled then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local now = tick()
                    local hist = PlayerHistory[plr]
                    if not hist then
                        PlayerHistory[plr] = { lastPos = hrp.Position, lastCheck = now, tpCount = 0, speedCount = 0 }
                    else
                        local dtHist = now - hist.lastCheck
                        if dtHist > 0.05 then
                            local dist = (hrp.Position - hist.lastPos).Magnitude
                            local speed = dist / dtHist

                            if speed > DetectionSettings.SpeedThreshold then
                                hist.speedCount = hist.speedCount + 1
                                if hist.speedCount >= 3 then
                                    flagPlayer(plr, "Speed " .. math.floor(speed) .. " s/s")
                                end
                            else
                                hist.speedCount = 0
                            end

                            if dist > DetectionSettings.TPThreshold and dtHist < 0.5 then
                                hist.tpCount = hist.tpCount + 1
                                if hist.tpCount >= 2 then
                                    flagPlayer(plr, "TP " .. math.floor(dist) .. " studs")
                                end
                            else
                                if hist.tpCount > 0 then hist.tpCount = hist.tpCount - 1 end
                            end

                            hist.lastPos = hrp.Position
                            hist.lastCheck = now
                        end
                    end
                end
            end
        end

        for plr, _ in pairs(PlayerHistory) do
            if not plr or not plr.Parent then PlayerHistory[plr] = nil end
        end
        for plr, s in pairs(SuspiciousPlayers) do
            if not plr or not plr.Parent then
                SuspiciousPlayers[plr] = nil
            elseif (tick() - s.t) > 60 then
                SuspiciousPlayers[plr] = nil
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- INPUT
    -- ═══════════════════════════════════════════════════════════

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

    -- ═══════════════════════════════════════════════════════════
    -- DRAWINGS
    -- ═══════════════════════════════════════════════════════════

    FOVCircle.Visible = false
    FOVCircle.Radius = AimSettings.FOVRadius
    FOVCircle.Color = AimSettings.FOVColor
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.9
    FOVCircle.ZIndex = 999

    TargetIndicator.Visible = false
    TargetIndicator.Radius = 10
    TargetIndicator.Color = Color3.fromRGB(255, 50, 50)
    TargetIndicator.Thickness = 2
    TargetIndicator.NumSides = 32
    TargetIndicator.Filled = false
    TargetIndicator.Transparency = 1
    TargetIndicator.ZIndex = 999

    -- ═══════════════════════════════════════════════════════════
    -- HIT MARKERS
    -- ═══════════════════════════════════════════════════════════

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

    -- ═══════════════════════════════════════════════════════════
    -- ESP JOUEURS
    -- ═══════════════════════════════════════════════════════════

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
        esp.Role = Drawing.new("Text")
        esp.Role.Visible = false; esp.Role.Size = 13
        esp.Role.Center = true; esp.Role.Outline = true
        esp.Role.OutlineColor = Color3.fromRGB(0, 0, 0); esp.Role.ZIndex = 11
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

    local function cleanupAllESP()
        for plr, _ in pairs(ESPObjects) do removeESP(plr) end
    end

    local function hideESP(esp)
        if not esp.Box.Visible then return end
        esp.Box.Visible = false; esp.Outline.Visible = false
        esp.Name.Visible = false; esp.Role.Visible = false
        esp.Health.Visible = false; esp.Distance.Visible = false
        esp.Tracer.Visible = false
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
                if localHRP then
                    local dist = (hrp.Position - localHRP.Position).Magnitude
                    valid = dist <= ESPSettings.MaxDistance
                else valid = true end
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
                    local role = getPlayerRole(plr)
                    local col = roleColor(role)
                    local suspectScore = getSuspicionScore(plr)
                    local suspectTag = suspectScore > 0 and (" [SUSPECT x" .. suspectScore .. "]") or ""

                    if ESPSettings.Box then
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(x, y)
                        esp.Box.Color = suspectScore > 0 and ESPSettings.SuspectColor or col
                        esp.Box.Visible = true
                        esp.Outline.Size = esp.Box.Size
                        esp.Outline.Position = esp.Box.Position
                        esp.Outline.Visible = true
                    else esp.Box.Visible = false; esp.Outline.Visible = false end

                    if ESPSettings.Name then
                        esp.Name.Text = plr.Name .. suspectTag
                        esp.Name.Position = Vector2.new(headPos.X, y - 32)
                        esp.Name.Color = suspectScore > 0 and ESPSettings.SuspectColor or col
                        esp.Name.Visible = true
                    else esp.Name.Visible = false end

                    if ESPSettings.Role then
                        esp.Role.Text = "[" .. role .. "]"
                        esp.Role.Position = Vector2.new(headPos.X, y - 18)
                        esp.Role.Color = col
                        esp.Role.Visible = true
                    else esp.Role.Visible = false end

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
                        esp.Distance.Position = Vector2.new(headPos.X, y + height + 18)
                        esp.Distance.Color = col
                        esp.Distance.Visible = true
                    else esp.Distance.Visible = false end

                    if ESPSettings.Tracer then
                        local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        esp.Tracer.From = sc
                        esp.Tracer.To = Vector2.new(headPos.X, headPos.Y + height)
                        esp.Tracer.Color = suspectScore > 0 and ESPSettings.SuspectColor or col
                        esp.Tracer.Visible = true
                    else esp.Tracer.Visible = false end
                else
                    hideESP(esp)
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- ITEM ESP
    -- ═══════════════════════════════════════════════════════════

    local function getItemCategory(item)
        local n = item.Name:lower()
        if n == "coin" or n:find("coin") then return "coin" end
        if item:IsA("Tool") then
            if n:find("gun") or n:find("revolver") then return "gun" end
            if n:find("knife") then return "knife" end
            return "tool"
        end
        return nil
    end

    local function createItemESP(item, category)
        if not item or ItemESPObjects[item] then return end
        local text = Drawing.new("Text")
        text.Visible = false; text.Size = 13
        text.Center = true; text.Outline = true
        text.OutlineColor = Color3.fromRGB(0, 0, 0)
        text.ZIndex = 11
        if category == "coin" then text.Color = ESPSettings.CoinColor
        elseif category == "gun" then text.Color = ESPSettings.GunColor
        else text.Color = ESPSettings.ItemColor end
        ItemESPObjects[item] = text
    end

    local function removeItemESP(item)
        local text = ItemESPObjects[item]
        if not text then return end
        pcall(function() text:Remove() end)
        ItemESPObjects[item] = nil
    end

    local function cleanupAllItemESP()
        for item, _ in pairs(ItemESPObjects) do removeItemESP(item) end
    end

    local function updateItemESP()
        if not ESPSettings.ItemESP and not ESPSettings.CoinESP and not ESPSettings.GunESP then
            if next(ItemESPObjects) then cleanupAllItemESP() end
            return
        end

        local seen = {}

        local function processItem(item)
            local category = getItemCategory(item)
            if not category then return end

            local show = false
            if category == "coin" and ESPSettings.CoinESP then show = true end
            if category == "gun" and ESPSettings.GunESP then show = true end
            if category == "knife" and ESPSettings.GunESP then show = true end
            if category == "tool" and ESPSettings.ItemESP then show = true end
            if not show then return end

            seen[item] = true
            if not ItemESPObjects[item] then createItemESP(item, category) end
            local text = ItemESPObjects[item]
            if not text then return end

            local handle = item:FindFirstChild("Handle") or item:FindFirstChild("Base")
            local pos = handle and handle.Position or (item:IsA("BasePart") and item.Position) or nil
            if not pos then return end

            local sPos, onScreen = WorldToViewportPoint(Camera, pos)
            if onScreen and sPos.Z > 0 then
                text.Position = Vector2.new(sPos.X, sPos.Y - 20)
                text.Text = item.Name
                text.Visible = true

                if not NotifiedItems[item] then
                    if category == "gun" and DetectorSettings.NotifyGun then
                        Rayfield:Notify({Title = "Gun detecte", Content = "Un pistolet est au sol !", Duration = 4})
                    end
                    if category == "knife" and DetectorSettings.NotifyKnife then
                        Rayfield:Notify({Title = "Couteau detecte", Content = "Le couteau est au sol !", Duration = 4})
                    end
                    NotifiedItems[item] = true
                end
            else
                text.Visible = false
            end
        end

        local function scanContainer(container, depth)
            if depth > 3 or not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Folder") or item:IsA("Model") then
                    scanContainer(item, depth + 1)
                else
                    processItem(item)
                end
            end
        end
        scanContainer(Workspace, 0)

        for item, _ in pairs(ItemESPObjects) do
            if not seen[item] or not item.Parent then
                removeItemESP(item)
            end
        end
        for item, _ in pairs(NotifiedItems) do
            if not item or not item.Parent or not seen[item] then
                NotifiedItems[item] = nil
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- ROLE DETECTOR
    -- ═══════════════════════════════════════════════════════════

    local function updateRoleDetector()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not RoleNotified[plr] then
                local role = getPlayerRole(plr)
                if role == "Murderer" and DetectorSettings.NotifyMurderer then
                    Rayfield:Notify({Title = "Murderer detecte", Content = plr.Name .. " est le Murderer !", Duration = 5})
                    RoleNotified[plr] = true
                elseif role == "Sheriff" and DetectorSettings.NotifySheriff then
                    Rayfield:Notify({Title = "Sheriff detecte", Content = plr.Name .. " est le Sheriff", Duration = 5})
                    RoleNotified[plr] = true
                end
            end
        end
        for plr, _ in pairs(RoleNotified) do
            if not plr or not plr.Parent then
                RoleNotified[plr] = nil
            else
                local currentRole = getPlayerRole(plr)
                if currentRole == "Innocent" then
                    RoleNotified[plr] = nil
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- TARGET FINDER
    -- ═══════════════════════════════════════════════════════════

    local function findTargetByRole(preferredRole)
        local allPlayers = Players:GetPlayers()
        if #allPlayers <= 1 then return nil end
        local closest, closestDist = nil, AimSettings.FOVRadius
        local mousePos = GetMouseLocation(UserInputService)

        for _, plr in ipairs(allPlayers) do
            if validate(plr, {}) then
                local role = getPlayerRole(plr)
                local matches = false
                if preferredRole == "Murderer" and role == "Murderer" then matches = true end
                if preferredRole == "Sheriff" and role == "Sheriff" then matches = true end
                if preferredRole == "Innocent" and role == "Innocent" then matches = true end
                if preferredRole == "Any" then matches = true end
                if preferredRole == "Suspect" and getSuspicionScore(plr) > 0 then matches = true end

                if matches then
                    local tPart = plr.Character:FindFirstChild(AimSettings.TargetPart)
                    if tPart then
                        local sPos, onScreen = WorldToViewportPoint(Camera, tPart.Position)
                        if onScreen and sPos.Z > 0 then
                            local dist = (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude
                            if dist < closestDist then
                                closest = tPart
                                closestDist = dist
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    -- ═══════════════════════════════════════════════════════════
    -- AIMBOT
    -- ═══════════════════════════════════════════════════════════

    local function aimbotUpdate(dt)
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
            if LastTarget.Parent and LastTarget.Parent:FindFirstChildOfClass("Humanoid") and LastTarget.Parent.Humanoid.Health > 0 then
                targetPart = LastTarget
            else
                LastTarget = nil
            end
        end

        if not targetPart then
            targetPart = findTargetByRole("Any")
            if targetPart then
                LastTarget = targetPart
                LastTargetTime = tick()
            end
        end

        if targetPart then
            local pos = targetPart.Position
            if AimSettings.UsePrediction and targetPart.Parent then
                local targetHRP = targetPart.Parent:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    pos = pos + (targetHRP.Velocity * AimSettings.Prediction)
                end
            end
            local cur = Camera.CFrame
            local desired = CFrame.new(cur.Position, pos)
            Camera.CFrame = cur:Lerp(desired, AimSettings.Smoothness)

            if AimSettings.ShowTarget then
                local sPos, on = WorldToViewportPoint(Camera, pos)
                if on then
                    TargetIndicator.Position = Vector2.new(sPos.X, sPos.Y)
                    TargetIndicator.Visible = true
                else
                    TargetIndicator.Visible = false
                end
            end
        else
            if TargetIndicator.Visible then TargetIndicator.Visible = false end
        end
    end

    pcall(function() RunService:UnbindFromRenderStep(aimbotBindName) end)
    RunService:BindToRenderStep(aimbotBindName, Enum.RenderPriority.Camera.Value + 1, aimbotUpdate)

    -- ═══════════════════════════════════════════════════════════
    -- AUTO SHOOT
    -- ═══════════════════════════════════════════════════════════

    local hasMouse1Click = type(mouse1click) == "function"

    local function fireWeapon()
        if hasMouse1Click then pcall(mouse1click)
        else
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end

    local function hasGunEquipped()
        local char = LocalPlayer.Character
        if not char then return false end
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") then
                local n = c.Name:lower()
                for _, g in ipairs(GUN_NAMES) do
                    if n:find(g) then return true end
                end
            end
        end
        return false
    end

    local function getPreferredTargetForAutoShoot()
        if AutoShootSettings.TargetMurderer then
            local t = findTargetByRole("Murderer")
            if t then return t end
        end
        if AutoShootSettings.TargetSheriff then
            local t = findTargetByRole("Sheriff")
            if t then return t end
        end
        if AutoShootSettings.TargetInnocent then
            local t = findTargetByRole("Innocent")
            if t then return t end
        end
        return nil
    end

    local function autoShootLoop()
        if AutoShootThread then return end
        AutoShootThread = task.spawn(function()
            while AutoShootSettings.Enabled do
                if (not AutoShootSettings.RequireGun) or hasGunEquipped() then
                    if not AutoShootCooldown then
                        local t = getPreferredTargetForAutoShoot()
                        if t then
                            AutoShootCooldown = true
                            pcall(function() fireWeapon() end)
                            task.wait(AutoShootSettings.Delay)
                            AutoShootCooldown = false
                        end
                    end
                end
                task.wait(0.05)
            end
            AutoShootThread = nil
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- KILL AURA + FLING
    -- ═══════════════════════════════════════════════════════════

    local function killPlayer(plr)
        if not plr or plr == LocalPlayer or not plr.Character then return end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end

        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                for _, name in ipairs({"KnifeHit", "KnifeKill", "Hit", "Slash", "Stab", "Attack"}) do
                    local r = remotes:FindFirstChild(name)
                    if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                        pcall(function() r:FireServer(plr) end)
                        pcall(function() r:FireServer(plr.Character) end)
                        pcall(function() r:FireServer(plr.Character, hum) end)
                    end
                end
            end
        end)
        pcall(function() hum.Health = 0 end)
    end

    local function flingPlayer(plr)
        if not plr or plr == LocalPlayer or not plr.Character then return end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHRP then
            pcall(function()
                for _, part in ipairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Velocity = Vector3.new(1e5, 1e5, 1e5)
                    end
                end
            end)
        end
    end

    local function startKillAura()
        safeDisconnect(KillAuraThread)
        KillAuraThread = RunService.Heartbeat:Connect(function()
            if not KillSettings.AutoKillSheriff
               and not KillSettings.AutoKillInnocent
               and not KillSettings.AutoKillMurderer
               and not KillSettings.FlingEnabled then
                return
            end
            local _, _, localHRP = getLocalCharacter()
            if not localHRP then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - localHRP.Position).Magnitude
                        if dist <= KillSettings.KnifeRange then
                            local role = getPlayerRole(plr)
                            if (KillSettings.AutoKillSheriff and role == "Sheriff")
                               or (KillSettings.AutoKillMurderer and role == "Murderer")
                               or (KillSettings.AutoKillInnocent and role == "Innocent") then
                                killPlayer(plr)
                                task.wait(0.1)
                            end
                            if KillSettings.FlingEnabled then
                                flingPlayer(plr)
                            end
                        end
                    end
                end
            end
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- MOVEMENT
    -- ═══════════════════════════════════════════════════════════

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

    local function toggleInfiniteJump(state)
        if state then
            safeDisconnect(InfJumpConnection)
            InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                local _, hum = getLocalCharacter()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            safeDisconnect(InfJumpConnection); InfJumpConnection = nil
        end
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

    local function toggleFullbright(state)
        pcall(function()
            if state then
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.Brightness = 3
                Lighting.ClockTime = 14
            else
                Lighting.Ambient = OriginalLighting.Ambient
                Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
                Lighting.Brightness = OriginalLighting.Brightness
                Lighting.ClockTime = OriginalLighting.ClockTime
            end
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- AUTO PICKUP
    -- ═══════════════════════════════════════════════════════════

    local function teleportToItem(item)
        local _, _, hrp = getLocalCharacter()
        if not hrp then return end
        local handle = item:FindFirstChild("Handle") or (item:IsA("BasePart") and item)
        if handle and handle.Position then
            hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))
        end
    end

    local function autoPickupLoop()
        if AutoPickupThread then return end
        AutoPickupThread = task.spawn(function()
            while AutoPickupSettings.AutoPickupGun or AutoPickupSettings.AutoPickupCoins do
                if AutoPickupSettings.AutoPickupGun then
                    for _, item in ipairs(Workspace:GetChildren()) do
                        if item:IsA("Tool") then
                            local n = item.Name:lower()
                            if n:find("gun") or n:find("revolver") then
                                teleportToItem(item)
                                task.wait(AutoPickupSettings.AutoPickupDelay)
                                break
                            end
                        end
                    end
                end
                if AutoPickupSettings.AutoPickupCoins then
                    for _, item in ipairs(Workspace:GetChildren()) do
                        local n = item.Name:lower()
                        if n == "coin" or n:find("coin") then
                            teleportToItem(item)
                            task.wait(0.1)
                        end
                    end
                end
                task.wait(0.3)
            end
            AutoPickupThread = nil
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- AUTO FARM
    -- ═══════════════════════════════════════════════════════════

    local function startAutoFarm()
        if AutoFarmThread then return end
        AutoFarmRunning = true
        AutoFarmThread = task.spawn(function()
            while AutoFarmRunning and MiscSettings.AutoFarmCoins do
                local _, _, hrp = getLocalCharacter()
                if hrp then
                    for _, item in ipairs(Workspace:GetChildren()) do
                        local n = item.Name:lower()
                        if n == "coin" or n:find("coin") then
                            local handle = item:FindFirstChild("Handle") or (item:IsA("BasePart") and item)
                            if handle and handle.Position then
                                pcall(function()
                                    hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))
                                end)
                                task.wait(0.08)
                            end
                        end
                    end
                end
                task.wait(MiscSettings.FarmDelay)
            end
            AutoFarmRunning = false
            AutoFarmThread = nil
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- TELEPORT
    -- ═══════════════════════════════════════════════════════════

    local function tpToPlayer(plr)
        if not plr or not plr.Character then return end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local _, _, localHRP = getLocalCharacter()
        if not localHRP then return end
        localHRP.CFrame = CFrame.new(hrp.Position)
    end

    local function tpToRole(role)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if getPlayerRole(plr) == role then
                    tpToPlayer(plr)
                    return
                end
            end
        end
    end

    local function tpToNearestCoin()
        local _, _, hrp = getLocalCharacter()
        if not hrp then return end
        local closest, closestDist = nil, math.huge
        for _, item in ipairs(Workspace:GetChildren()) do
            local n = item.Name:lower()
            if n == "coin" or n:find("coin") then
                local handle = item:FindFirstChild("Handle") or (item:IsA("BasePart") and item)
                if handle and handle.Position then
                    local d = (handle.Position - hrp.Position).Magnitude
                    if d < closestDist then closest = item; closestDist = d end
                end
            end
        end
        if closest then teleportToItem(closest) end
    end

    local function tpToNearestGun()
        local _, _, hrp = getLocalCharacter()
        if not hrp then return end
        local closest, closestDist = nil, math.huge
        for _, item in ipairs(Workspace:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("gun") or n:find("revolver") then
                    local handle = item:FindFirstChild("Handle")
                    if handle and handle.Position then
                        local d = (handle.Position - hrp.Position).Magnitude
                        if d < closestDist then closest = item; closestDist = d end
                    end
                end
            end
        end
        if closest then teleportToItem(closest) end
    end

    -- ═══════════════════════════════════════════════════════════
    -- AUTO RESPAWN
    -- ═══════════════════════════════════════════════════════════

    local function setupAutoRespawn(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.Died:Connect(function()
            if MiscSettings.AutoRespawn then
                task.wait(2)
                pcall(function()
                    if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
                end)
            end
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- RESPAWN
    -- ═══════════════════════════════════════════════════════════

    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = MiscSettings.WalkSpeed
            hum.JumpPower = MiscSettings.JumpPower
        end
        if MiscSettings.Fly then task.wait(0.3); toggleFly(true) end
        if MiscSettings.Noclip then task.wait(0.3); toggleNoclip(true) end
        if ESPSettings.Enabled then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and not ESPObjects[plr] then createESP(plr) end
            end
        end
        setupAutoRespawn(char)
    end)
    if LocalPlayer.Character then setupAutoRespawn(LocalPlayer.Character) end

    -- ═══════════════════════════════════════════════════════════
    -- LOOPS
    -- ═══════════════════════════════════════════════════════════

    local espTick, itemTick, roleTick, detectTick = 0, 0, 0, 0
    local ESP_INTERVAL, ITEM_INTERVAL, ROLE_INTERVAL, DETECT_INTERVAL = 0.033, 0.1, 0.5, 0.1

    RenderConnection = RunService.RenderStepped:Connect(function(dt)
        espTick = espTick + dt
        itemTick = itemTick + dt
        roleTick = roleTick + dt
        detectTick = detectTick + dt

        if ESPSettings.Enabled and espTick >= ESP_INTERVAL then
            espTick = 0
            updateESP()
        end

        if itemTick >= ITEM_INTERVAL then
            itemTick = 0
            updateItemESP()
        end

        if roleTick >= ROLE_INTERVAL then
            roleTick = 0
            updateRoleDetector()
        end

        if detectTick >= DETECT_INTERVAL then
            detectTick = 0
            updateDetection(dt)
        end

        if AimSettings.ShowFOV and AimSettings.Enabled then
            FOVCircle.Visible = true
            FOVCircle.Radius = AimSettings.FOVRadius
            FOVCircle.Position = GetMouseLocation(UserInputService)
        else
            if FOVCircle.Visible then FOVCircle.Visible = false end
        end

        updateHitMarkers()
    end)

    -- ═══════════════════════════════════════════════════════════
    -- PLAYER CONNECTIONS
    -- ═══════════════════════════════════════════════════════════

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then createESP(plr) end
    end
    Players.PlayerAdded:Connect(function(plr) if plr ~= LocalPlayer then createESP(plr) end end)
    Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
        RoleNotified[plr] = nil
        SuspiciousPlayers[plr] = nil
        PlayerHistory[plr] = nil
    end)

    -- ═══════════════════════════════════════════════════════════
    -- UI
    -- ═══════════════════════════════════════════════════════════

    local Window = Rayfield:CreateWindow({
        Name = _H("4d4d32202f2f204b616e6861204875622076312e30") .. (isVip and _H("205b5649505d") or ""),
        LoadingTitle = _H("4c6f6164696e67204b616e6861204875622e2e2e"),
        LoadingSubtitle = _H("6279204b616e6861"),
        Theme = "Dark",
        ToggleUIKeybind = Enum.KeyCode.RightShift,
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local MainTab = Window:CreateTab(_H("4d61696e"), 6031097226)
    MainTab:CreateSection(_H("4175746f20506c6179"))
    MainTab:CreateToggle({Name = _H("4175746f204661726d20436f696e73"), CurrentValue = false, Flag = "AutoFarmOn",
        Callback = function(v)
            MiscSettings.AutoFarmCoins = v
            if v then startAutoFarm() else AutoFarmRunning = false end
        end})
    MainTab:CreateSlider({Name = _H("4661726d2044656c6179"), Range = {0.5, 10}, Increment = 0.5, Suffix = "s",
        CurrentValue = 3, Flag = "FarmDelay",
        Callback = function(v) MiscSettings.FarmDelay = v end})
    MainTab:CreateToggle({Name = _H("4175746f205265737061776e"), CurrentValue = false, Flag = "AutoRespawn",
        Callback = function(v) MiscSettings.AutoRespawn = v end})

    MainTab:CreateSection(_H("517569636b20416374696f6e"))
    MainTab:CreateButton({Name = _H("5450204e65617265737420436f696e"), Callback = function() tpToNearestCoin() end})
    MainTab:CreateButton({Name = _H("5450204e6561726573742047756e"), Callback = function() tpToNearestGun() end})
    MainTab:CreateButton({Name = _H("5450204d75726465726572"), Callback = function() tpToRole("Murderer") end})
    MainTab:CreateButton({Name = _H("54502053686572696666"), Callback = function() tpToRole("Sheriff") end})

    local CombatTab = Window:CreateTab(_H("436f6d626174"), 6031097226)
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
    CombatTab:CreateSlider({Name = _H("464f5620526164697573"), Range = {10, 800}, Increment = 1, Suffix = "px",
        CurrentValue = 120, Flag = "AimbotFOV",
        Callback = function(v) AimSettings.FOVRadius = v end})
    CombatTab:CreateToggle({Name = _H("53686f7720464f56"), CurrentValue = true, Flag = "ShowFOV",
        Callback = function(v) AimSettings.ShowFOV = v end})
    CombatTab:CreateToggle({Name = _H("50726564696374696f6e"), CurrentValue = false, Flag = "AimbotPred",
        Callback = function(v) AimSettings.UsePrediction = v end})
    CombatTab:CreateSlider({Name = _H("50726564696374696f6e20416d6f756e74"), Range = {0.01, 1}, Increment = 0.01, Suffix = "",
        CurrentValue = 0.165, Flag = "AimbotPredAmt",
        Callback = function(v) AimSettings.Prediction = v end})
    CombatTab:CreateToggle({Name = _H("537469636b7920546172676574"), CurrentValue = false, Flag = "AimbotSticky",
        Callback = function(v) AimSettings.StickyTarget = v end})
    CombatTab:CreateSlider({Name = _H("537469636b79204475726174696f6e"), Range = {0.1, 2}, Increment = 0.05, Suffix = "s",
        CurrentValue = 0.5, Flag = "AimbotStickyTime",
        Callback = function(v) AimSettings.StickyTime = v end})

    CombatTab:CreateSection(_H("4175746f2053686f6f74"))
    CombatTab:CreateToggle({Name = _H("456e61626c65204175746f2053686f6f74"), CurrentValue = false, Flag = "AutoShoot",
        Callback = function(v)
            AutoShootSettings.Enabled = v
            if v then autoShootLoop() end
        end})
    CombatTab:CreateToggle({Name = _H("4175746f2053686f6f74204d75726465726572"), CurrentValue = true, Flag = "AutoShootMurderer",
        Callback = function(v) AutoShootSettings.TargetMurderer = v end})
    CombatTab:CreateToggle({Name = _H("4175746f2053686f6f742053686572696666"), CurrentValue = false, Flag = "AutoShootSheriff",
        Callback = function(v) AutoShootSettings.TargetSheriff = v end})
    CombatTab:CreateToggle({Name = _H("4175746f2053686f6f7420496e6e6f63656e74"), CurrentValue = false, Flag = "AutoShootInnocent",
        Callback = function(v) AutoShootSettings.TargetInnocent = v end})
    CombatTab:CreateToggle({Name = _H("526571756972652047756e"), CurrentValue = true, Flag = "AutoShootRequireGun",
        Callback = function(v) AutoShootSettings.RequireGun = v end})
    CombatTab:CreateSlider({Name = _H("4175746f2053686f6f742044656c6179"), Range = {0.05, 1}, Increment = 0.01, Suffix = "s",
        CurrentValue = 0.15, Flag = "AutoShootDelay",
        Callback = function(v) AutoShootSettings.Delay = v end})

    CombatTab:CreateSection(_H("4b696c6c2041757261"))
    CombatTab:CreateToggle({Name = _H("4175746f204b696c6c2053686572696666"), CurrentValue = false, Flag = "AutoKillSheriff",
        Callback = function(v) KillSettings.AutoKillSheriff = v; if v then startKillAura() end end})
    CombatTab:CreateToggle({Name = _H("4175746f204b696c6c20496e6e6f63656e74"), CurrentValue = false, Flag = "AutoKillInnocent",
        Callback = function(v) KillSettings.AutoKillInnocent = v; if v then startKillAura() end end})
    CombatTab:CreateToggle({Name = _H("4175746f204b696c6c204d75726465726572"), CurrentValue = false, Flag = "AutoKillMurderer",
        Callback = function(v) KillSettings.AutoKillMurderer = v; if v then startKillAura() end end})
    CombatTab:CreateSlider({Name = _H("4b6e6966652052616e6765"), Range = {5, 100}, Increment = 1, Suffix = "m",
        CurrentValue = 30, Flag = "KnifeRange",
        Callback = function(v) KillSettings.KnifeRange = v end})
    CombatTab:CreateToggle({Name = _H("466c696e67204d6f6465"), CurrentValue = false, Flag = "FlingEnabled",
        Callback = function(v) KillSettings.FlingEnabled = v; if v then startKillAura() end end})

    local ESPTab = Window:CreateTab(_H("455350"), 6031097226)
    ESPTab:CreateSection(_H("506c6179657273"))
    ESPTab:CreateToggle({Name = _H("456e61626c6520455350"), CurrentValue = false, Flag = "ESPOn",
        Callback = function(v)
            ESPSettings.Enabled = v
            if v then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then createESP(plr) end
                end
            else cleanupAllESP() end
        end})
    ESPTab:CreateToggle({Name = _H("426f78"), CurrentValue = true, Flag = "ESPBox",
        Callback = function(v) ESPSettings.Box = v end})
    ESPTab:CreateToggle({Name = _H("4e616d65"), CurrentValue = true, Flag = "ESPName",
        Callback = function(v) ESPSettings.Name = v end})
    ESPTab:CreateToggle({Name = _H("526f6c65"), CurrentValue = true, Flag = "ESPRole",
        Callback = function(v) ESPSettings.Role = v end})
    ESPTab:CreateToggle({Name = _H("4865616c7468"), CurrentValue = false, Flag = "ESPHealth",
        Callback = function(v) ESPSettings.Health = v end})
    ESPTab:CreateToggle({Name = _H("44697374616e6365"), CurrentValue = true, Flag = "ESPDist",
        Callback = function(v) ESPSettings.Distance = v end})
    ESPTab:CreateToggle({Name = _H("547261636572"), CurrentValue = false, Flag = "ESPTracer",
        Callback = function(v) ESPSettings.Tracer = v end})
    ESPTab:CreateSlider({Name = _H("4d61782044697374616e6365"), Range = {100, 5000}, Increment = 100, Suffix = "m",
        CurrentValue = 2000, Flag = "ESPMaxDist",
        Callback = function(v) ESPSettings.MaxDistance = v end})

    ESPTab:CreateSection(_H("4974656d73"))
    ESPTab:CreateToggle({Name = _H("4974656d20455350"), CurrentValue = true, Flag = "ItemESP",
        Callback = function(v) ESPSettings.ItemESP = v end})
    ESPTab:CreateToggle({Name = _H("436f696e20455350"), CurrentValue = true, Flag = "CoinESP",
        Callback = function(v) ESPSettings.CoinESP = v end})
    ESPTab:CreateToggle({Name = _H("47756e20455350"), CurrentValue = true, Flag = "GunESP",
        Callback = function(v) ESPSettings.GunESP = v end})

    ESPTab:CreateSection(_H("436f6c6f7273"))
    ESPTab:CreateColorPicker({Name = _H("4d7572646572657220436f6c6f72"), Color = Color3.fromRGB(255, 50, 50), Flag = "ESPColMurderer",
        Callback = function(c) ESPSettings.MurdererColor = c end})
    ESPTab:CreateColorPicker({Name = _H("5368657269666620436f6c6f72"), Color = Color3.fromRGB(80, 150, 255), Flag = "ESPColSheriff",
        Callback = function(c) ESPSettings.SheriffColor = c end})
    ESPTab:CreateColorPicker({Name = _H("496e6e6f63656e7420436f6c6f72"), Color = Color3.fromRGB(80, 255, 80), Flag = "ESPColInnocent",
        Callback = function(c) ESPSettings.InnocentColor = c end})
    ESPTab:CreateColorPicker({Name = _H("5375737065637420436f6c6f72"), Color = Color3.fromRGB(255, 100, 0), Flag = "ESPColSuspect",
        Callback = function(c) ESPSettings.SuspectColor = c end})
    ESPTab:CreateColorPicker({Name = _H("4974656d20436f6c6f72"), Color = Color3.fromRGB(255, 220, 80), Flag = "ESPColItem",
        Callback = function(c) ESPSettings.ItemColor = c end})
    ESPTab:CreateColorPicker({Name = _H("436f696e20436f6c6f72"), Color = Color3.fromRGB(255, 180, 30), Flag = "ESPColCoin",
        Callback = function(c) ESPSettings.CoinColor = c end})
    ESPTab:CreateColorPicker({Name = _H("47756e20436f6c6f72"), Color = Color3.fromRGB(200, 100, 255), Flag = "ESPColGun",
        Callback = function(c) ESPSettings.GunColor = c end})

    local DetectorTab = Window:CreateTab(_H("4465746563746f72"), 6031097226)

    DetectorTab:CreateSection(_H("4e6f74696669636174696f6e73"))
    DetectorTab:CreateToggle({Name = _H("4e6f74696679204d75726465726572"), CurrentValue = true, Flag = "NotifyMurderer",
        Callback = function(v) DetectorSettings.NotifyMurderer = v end})
    DetectorTab:CreateToggle({Name = _H("4e6f746966792053686572696666"), CurrentValue = true, Flag = "NotifySheriff",
        Callback = function(v) DetectorSettings.NotifySheriff = v end})
    DetectorTab:CreateToggle({Name = _H("4e6f746966792047756e"), CurrentValue = true, Flag = "NotifyGun",
        Callback = function(v) DetectorSettings.NotifyGun = v end})
    DetectorTab:CreateToggle({Name = _H("4e6f74696679204b6e696665"), CurrentValue = true, Flag = "NotifyKnife",
        Callback = function(v) DetectorSettings.NotifyKnife = v end})

    DetectorTab:CreateSection(_H("4578656375746f722044657465637465"))
    DetectorTab:CreateToggle({Name = _H("456e61626c65204578656375746f722044657465637465"), CurrentValue = true, Flag = "DetectionEnabled",
        Callback = function(v) DetectionSettings.Enabled = v end})
    DetectorTab:CreateToggle({Name = _H("4e6f74696679206f6e20446574656374696f6e"), CurrentValue = true, Flag = "DetectionNotify",
        Callback = function(v) DetectionSettings.NotifyOnDetection = v end})
    DetectorTab:CreateToggle({Name = _H("4d61726b20696e20455350"), CurrentValue = true, Flag = "DetectionMark",
        Callback = function(v) DetectionSettings.MarkInESP = v end})
    DetectorTab:CreateSlider({Name = _H("5370656564205468726573686f6c64"), Range = {20, 200}, Increment = 5, Suffix = "s/s",
        CurrentValue = 60, Flag = "SpeedThreshold",
        Callback = function(v) DetectionSettings.SpeedThreshold = v end})
    DetectorTab:CreateSlider({Name = _H("5450205468726573686f6c64"), Range = {30, 500}, Increment = 10, Suffix = "studs",
        CurrentValue = 100, Flag = "TPThreshold",
        Callback = function(v) DetectionSettings.TPThreshold = v end})

    DetectorTab:CreateSection(_H("5375737065637473"))
    DetectorTab:CreateButton({
        Name = _H("53686f7720537573706963696f757320506c6179657273"),
        Callback = function()
            local found = false
            for plr, s in pairs(SuspiciousPlayers) do
                if plr and plr.Parent then
                    found = true
                    local reasons = {}
                    for r, _ in pairs(s.reasons) do
                        table.insert(reasons, r)
                    end
                    Rayfield:Notify({
                        Title = "Suspect: " .. plr.Name,
                        Content = "Score: " .. s.score .. " | " .. table.concat(reasons, ", "),
                        Duration = 6,
                    })
                end
            end
            if not found then
                Rayfield:Notify({Title = "Suspects", Content = "Aucun suspect detecte.", Duration = 4})
            end
        end,
    })
    DetectorTab:CreateButton({
        Name = _H("526573657420446574656374696f6e"),
        Callback = function()
            SuspiciousPlayers = {}
            PlayerHistory = {}
            Rayfield:Notify({Title = "Reset", Content = "Liste des suspects videe.", Duration = 3})
        end,
    })

    local PickupTab = Window:CreateTab(_H("5069636b7570"), 6031097226)
    PickupTab:CreateSection(_H("4175746f205069636b7570"))
    PickupTab:CreateToggle({Name = _H("4175746f205069636b75702047756e"), CurrentValue = false, Flag = "AutoPickupGun",
        Callback = function(v)
            AutoPickupSettings.AutoPickupGun = v
            if v then autoPickupLoop() end
        end})
    PickupTab:CreateToggle({Name = _H("4175746f205069636b757020436f696e73"), CurrentValue = false, Flag = "AutoPickupCoins",
        Callback = function(v)
            AutoPickupSettings.AutoPickupCoins = v
            if v then autoPickupLoop() end
        end})
    PickupTab:CreateSlider({Name = _H("5069636b75702044656c6179"), Range = {0.1, 2}, Increment = 0.1, Suffix = "s",
        CurrentValue = 0.5, Flag = "AutoPickupDelay",
        Callback = function(v) AutoPickupSettings.AutoPickupDelay = v end})

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
        CurrentValue = 60, Flag = "FlySpeed",
        Callback = function(v) MiscSettings.FlySpeed = v end})
    PlayerTab:CreateToggle({Name = _H("4e6f636c6970"), CurrentValue = false, Flag = "NoclipOn",
        Callback = function(v) MiscSettings.Noclip = v; toggleNoclip(v) end})
    PlayerTab:CreateToggle({Name = _H("496e66696e697465204a756d70"), CurrentValue = false, Flag = "InfJump",
        Callback = function(v) MiscSettings.InfiniteJump = v; toggleInfiniteJump(v) end})

    PlayerTab:CreateSection(_H("5574696c697479"))
    PlayerTab:CreateToggle({Name = _H("416e74692d41464b"), CurrentValue = false, Flag = "AntiAFK",
        Callback = function(v) MiscSettings.AntiAFK = v; toggleAntiAFK(v) end})
    PlayerTab:CreateToggle({Name = _H("46756c6c627269676874"), CurrentValue = false, Flag = "Fullbright",
        Callback = function(v) MiscSettings.Fullbright = v; toggleFullbright(v) end})

    local SettingsTab = Window:CreateTab(_H("53657474696e6773"), 6031097226)
    SettingsTab:CreateSection(_H("536572766572"))
    SettingsTab:CreateButton({Name = _H("52656a6f696e20536572766572"),
        Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})
    SettingsTab:CreateButton({Name = _H("53657276657220486f70"),
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
    SettingsTab:CreateSection(_H("536372697074"))
    SettingsTab:CreateButton({
        Name = _H("556e6c6f616420536372697074"),
        Callback = function()
            safeDisconnect(RenderConnection); safeDisconnect(HeartbeatConnection)
            safeDisconnect(FlyConnection); safeDisconnect(NoclipConnection)
            safeDisconnect(AntiAFKConnection); safeDisconnect(KillAuraThread)
            safeDisconnect(InputBeganConnection); safeDisconnect(InputEndedConnection)
            safeDisconnect(InfJumpConnection)
            pcall(function() RunService:UnbindFromRenderStep(aimbotBindName) end)
            AutoFarmRunning = false
            AutoShootSettings.Enabled = false
            AutoPickupSettings.AutoPickupGun = false
            AutoPickupSettings.AutoPickupCoins = false
            cleanupAllESP(); cleanupAllItemESP()
            toggleFullbright(false)
            SuspiciousPlayers = {}
            PlayerHistory = {}
            for _, hm in ipairs(HitMarkers) do releaseMarkerToPool(hm.Lines) end
            HitMarkers = {}
            for _, lines in ipairs(HitMarkerPool) do
                for _, line in ipairs(lines) do pcall(function() line:Remove() end) end
            end
            HitMarkerPool = {}
            pcall(function() FOVCircle:Remove() end)
            pcall(function() TargetIndicator:Remove() end)
            Rayfield:Destroy()
        end})

    Rayfield:Notify({
        Title = _H("4b616e6861204d4d322076312e30"),
        Content = _H("52696768745368696674203d205549202020202020746965723a20") .. session.tier,
        Duration = 6,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- KEY UI
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
-- START
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
