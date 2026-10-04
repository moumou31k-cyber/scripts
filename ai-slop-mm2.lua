-- ============================================================
-- MM2 HUB v4.0
-- Safe boot · diagnostics auto · GUI étendue · keybinds
-- Compatible : Solara, Medium, Real, Wave, Potassium, Volt, Codex
-- ============================================================

-- ============================================================
-- [1] DIAGNOSTICS (avant tout — si ça crash, tu vois pourquoi)
-- ============================================================
local Diagnostics = {
    results = {},
    warnings = {},
    errors = {},
    order = {},
}

function Diagnostics.check(label, fn, silent)
    table.insert(Diagnostics.order, label)
    local ok, result = pcall(fn)
    if ok then
        Diagnostics.results[label] = result ~= false and (result == nil and true or result)
    else
        Diagnostics.results[label] = false
        Diagnostics.warnings[label] = tostring(result)
        if not silent then
            warn(string.format("[MM2 v4] %s: %s", label, tostring(result)))
        end
    end
    return Diagnostics.results[label]
end

function Diagnostics.getGlobal(name)
    if _G[name] ~= nil then return _G[name] end
    if getgenv then
        local ok, g = pcall(getgenv)
        if ok and g and g[name] ~= nil then return g[name] end
    end
    return nil
end

function Diagnostics.summary()
    local passed, failed = 0, 0
    for _, label in ipairs(Diagnostics.order) do
        if Diagnostics.results[label] then passed = passed + 1 else failed = failed + 1 end
    end
    return passed, failed
end

-- ============================================================
-- [2] SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- [3] SAFE EXECUTOR DETECTION
-- ============================================================
local execName = "unknown"
Diagnostics.check("getexecutorname", function()
    if not getexecutorname then return "fallback" end
    local ok, name = pcall(getexecutorname)
    if ok and type(name) == "string" and name ~= "" then
        execName = name
        return name
    end
    return "fallback"
end)

-- Fallback detection via globals
if execName == "unknown" or execName == "fallback" then
    if Diagnostics.getGlobal("syn") then execName = "Synapse"
    elseif Diagnostics.getGlobal("KRNL_LOADED") then execName = "Krnl"
    elseif Diagnostics.getGlobal("fluxus") then execName = "Fluxus"
    elseif Diagnostics.getGlobal("secure_load") then execName = "Script-Ware"
    elseif Diagnostics.getGlobal("is_sirhurt_closure") then execName = "SirHurt"
    elseif Diagnostics.getGlobal("Solara") or Diagnostics.getGlobal("solara") then execName = "Solara"
    elseif Diagnostics.getGlobal("medium") or Diagnostics.getGlobal("Medium") then execName = "Medium"
    elseif Diagnostics.getGlobal("real") then execName = "Real"
    elseif Diagnostics.getGlobal("wave") then execName = "Wave"
    elseif Diagnostics.getGlobal("potassium") then execName = "Potassium"
    else execName = "Unknown executor" end
end

-- ============================================================
-- [4] XENO GATE
-- ============================================================
do
    local isXeno = false
    if _G.XENO or _G.xeno then isXeno = true end
    if getgenv then
        local ok, g = pcall(getgenv)
        if ok and g and (g.XENO or g.xeno) then isXeno = true end
    end
    if type(execName) == "string" and execName:lower():find("xeno") then isXeno = true end

    if isXeno then
        local ok, err = pcall(function()
            local target = (gethui and gethui()) or game:GetService("CoreGui")
            local sg = Instance.new("ScreenGui")
            sg.Name = "XenoBan" .. math.random(1e6, 9e6)
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            sg.DisplayOrder = 2147483647
            sg.Parent = target
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 560, 0, 220)
            frame.Position = UDim2.new(0.5, -280, 0.5, -110)
            frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
            frame.BorderSizePixel = 0
            frame.Parent = sg
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
            local s = Instance.new("UIStroke", frame)
            s.Color = Color3.fromRGB(239, 68, 68); s.Thickness = 3
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 55); title.Position = UDim2.new(0, 0, 0, 26)
            title.BackgroundTransparency = 1; title.Text = "SUNC INSUFFISANT"
            title.TextColor3 = Color3.fromRGB(239, 68, 68)
            title.Font = Enum.Font.GothamBlack; title.TextSize = 34
            title.Parent = frame
            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(1, -50, 0, 100); sub.Position = UDim2.new(0, 25, 0, 92)
            sub.BackgroundTransparency = 1
            sub.Text = "Xeno détecté.\nInstalle Solara, Medium, Wave, Potassium ou Real.\nCe script ne tournera jamais sur Xeno."
            sub.TextColor3 = Color3.fromRGB(210, 210, 220)
            sub.Font = Enum.Font.Gotham; sub.TextSize = 14
            sub.TextWrapped = true; sub.Parent = frame
        end)
        while true do task.wait(1) end
    end
end

-- ============================================================
-- [5] CAPABILITY PROBE
-- ============================================================
Diagnostics.check("getrawmetatable", function() return type(Diagnostics.getGlobal("getrawmetatable")) == "function" end)
Diagnostics.check("setreadonly", function() return type(Diagnostics.getGlobal("setreadonly")) == "function" end)
Diagnostics.check("hookfunction", function() return type(Diagnostics.getGlobal("hookfunction")) == "function" end)
Diagnostics.check("hookmetamethod", function() return type(Diagnostics.getGlobal("hookmetamethod")) == "function" end)
Diagnostics.check("newcclosure", function() return type(Diagnostics.getGlobal("newcclosure")) == "function" end)
Diagnostics.check("getnamecallmethod", function() return type(Diagnostics.getGlobal("getnamecallmethod")) == "function" end)
Diagnostics.check("checkcaller", function() return type(Diagnostics.getGlobal("checkcaller")) == "function" end)
Diagnostics.check("Drawing", function() return type(Diagnostics.getGlobal("Drawing")) == "table" end)
Diagnostics.check("gethui", function() return type(Diagnostics.getGlobal("gethui")) == "function" end)
Diagnostics.check("writefile", function() return type(Diagnostics.getGlobal("writefile")) == "function" end)
Diagnostics.check("CoreGui", function()
    local cg = game:GetService("CoreGui")
    return cg ~= nil
end)
Diagnostics.check("CoreGui write", function()
    local cg = game:GetService("CoreGui")
    local f = Instance.new("Folder")
    f.Name = "_diag_" .. math.random(1e6, 9e6)
    f.Parent = cg
    task.defer(function() pcall(function() f:Destroy() end) end)
    return true
end, true)
Diagnostics.check("gethui write", function()
    if type(Diagnostics.getGlobal("gethui")) ~= "function" then return false end
    local ok, h = pcall(Diagnostics.getGlobal("gethui"))
    if not ok or not h then return false end
    local f = Instance.new("Folder")
    f.Parent = h
    task.defer(function() pcall(function() f:Destroy() end) end)
    return true
end, true)

local capabilities = {
    hookfunction = Diagnostics.results["hookfunction"],
    hookmetamethod = Diagnostics.results["hookmetamethod"],
    newcclosure = Diagnostics.results["newcclosure"],
    getnamecallmethod = Diagnostics.results["getnamecallmethod"],
    checkcaller = Diagnostics.results["checkcaller"],
    getrawmetatable = Diagnostics.results["getrawmetatable"],
    setreadonly = Diagnostics.results["setreadonly"],
    Drawing = Diagnostics.results["Drawing"],
    fileIO = Diagnostics.results["writefile"],
    hui = Diagnostics.results["gethui"] and Diagnostics.results["gethui write"],
}

local tier = 0
for _, v in pairs(capabilities) do
    if v then tier = tier + 1 end
end

local gates = {
    silentAim = capabilities.getrawmetatable and capabilities.setreadonly and
                capabilities.newcclosure and capabilities.getnamecallmethod and
                capabilities.checkcaller,
    esp = capabilities.Drawing,
    fileIO = capabilities.fileIO,
    gethui = capabilities.hui,
}

-- ============================================================
-- [6] CONNECTION POOL
-- ============================================================
local connections = {}
local function connect(event, func)
    if not event or not event.Connect then return nil end
    local ok, conn = pcall(function() return event:Connect(func) end)
    if ok and conn then
        table.insert(connections, conn)
        return conn
    end
    return nil
end

local function flushConnections()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
end

-- ============================================================
-- [7] NOTIFICATIONS
-- ============================================================
local Notifications = { toasts = {} }

function Notifications.push(title, text, duration)
    duration = duration or 3
    local target = (gates.gethui and select(2, pcall(gethui))) or game:GetService("CoreGui")
    if not target then return end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MM2_Toast_" .. math.random(1e6, 9e6)
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2000
    local pOk = pcall(function() sg.Parent = target end)
    if not pOk then sg:Destroy(); return end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(1, -320, 0, 20 + #Notifications.toasts * 70)
    frame.BackgroundColor3 = Color3.fromRGB(19, 19, 28)
    frame.BorderSizePixel = 0
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", frame)
    s.Color = Color3.fromRGB(34, 211, 238); s.Thickness = 1

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 20)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title; titleLbl.TextColor3 = Color3.fromRGB(34, 211, 238)
    titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = frame

    local textLbl = Instance.new("TextLabel")
    textLbl.Size = UDim2.new(1, -20, 0, 26)
    textLbl.Position = UDim2.new(0, 10, 0, 26)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = text; textLbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    textLbl.Font = Enum.Font.Gotham; textLbl.TextSize = 11
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.TextWrapped = true
    textLbl.Parent = frame

    table.insert(Notifications.toasts, sg)
    task.delay(duration, function()
        pcall(function() sg:Destroy() end)
        for i, t in ipairs(Notifications.toasts) do
            if t == sg then table.remove(Notifications.toasts, i); break end
        end
    end)
end

-- ============================================================
-- [8] MODULES
-- ============================================================
local Combat = {}
local Vision = {}
local Farm = {}
local Misc = {}
local KillFeed = { events = {}, maxEvents = 20 }

-- ============================================================
-- [9] PROFILES
-- ============================================================
local profiles = {
    legit = {
        silentAim = false, aura = false, triggerbot = false,
        esp = true, chams = true, showBox = false, showName = true, showRole = true,
        showDist = false, showTracer = false,
        autoCoin = false, magnet = true, magnetRange = 20, tpDelay = 1.0,
        speed = 16, noclip = false, fly = false, antiAfk = true, watermark = true,
        triggerbotRange = 50, targetRole = "murderer", targetMode = "nearest",
    },
    ultra = {
        silentAim = true, aura = true, triggerbot = true,
        esp = true, chams = true, showBox = true, showName = true, showRole = true,
        showDist = true, showTracer = true,
        autoCoin = false, magnet = true, magnetRange = 30, tpDelay = 0.5,
        speed = 32, noclip = false, fly = false, antiAfk = true, watermark = true,
        triggerbotRange = 100, targetRole = "murderer", targetMode = "closest_mouse",
    },
    rage = {
        silentAim = true, aura = true, triggerbot = true,
        esp = true, chams = true, showBox = true, showName = true, showRole = true,
        showDist = true, showTracer = true,
        autoCoin = true, magnet = true, magnetRange = 80, tpDelay = 0.2,
        speed = 32, noclip = true, fly = false, antiAfk = true, watermark = true,
        triggerbotRange = 200, targetRole = "all", targetMode = "lowest_hp",
    },
}
local currentProfile = "ultra"

-- ============================================================
-- [10] HELPERS
-- ============================================================
local function getRole(player)
    if not player or not player.Character then return "innocent" end
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    local function checkTool(parent)
        if not parent then return nil end
        for _, item in pairs(parent:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("knife") or name:find("murder") then return "murderer" end
                if name:find("gun") or name:find("sheriff") or name:find("revolver") then return "sheriff" end
            end
        end
        return nil
    end

    local cRole = checkTool(char)
    if cRole then return cRole end
    if backpack then
        local bRole = checkTool(backpack)
        if bRole then return bRole end
    end
    return "innocent"
end

local function getRoot(player)
    local char = player and player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
    local char = player and player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function roleColor(role)
    if role == "murderer" then return Color3.fromRGB(255, 60, 60) end
    if role == "sheriff" then return Color3.fromRGB(60, 140, 255) end
    return Color3.fromRGB(80, 220, 120)
end

-- ============================================================
-- [11] SILENT AIM HOOK (safe install)
-- ============================================================
local oldNamecall = nil
local hookInstalled = false
do
    if gates.silentAim then
        local getRawMeta = Diagnostics.getGlobal("getrawmetatable")
        local setRO = Diagnostics.getGlobal("setreadonly")
        local newCC = Diagnostics.getGlobal("newcclosure")
        local getNameMethod = Diagnostics.getGlobal("getnamecallmethod")
        local checkCallerFn = Diagnostics.getGlobal("checkcaller")

        local ok, err = pcall(function()
            local mt = getRawMeta(game)
            if not mt then error("getrawmetatable returned nil") end
            oldNamecall = mt.__namecall
            if not oldNamecall then error("__namecall nil") end

            local newNamecall = newCC(function(self, ...)
                if checkCallerFn() then return oldNamecall(self, ...) end
                local method = getNameMethod()
                if method == "FireServer" and self and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                    local name = self.Name:lower()
                    if name:find("shoot") or name:find("fire") or name:find("throw") or name:find("slash") then
                        if Combat.silentAimEnabled and Combat.currentTarget then
                            local args = {...}
                            local targetRoot = getRoot(Combat.currentTarget)
                            if targetRoot then
                                args[1] = targetRoot.Position
                                return oldNamecall(self, table.unpack(args))
                            end
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)

            setRO(mt, false)
            mt.__namecall = newNamecall
            setRO(mt, true)
            hookInstalled = true
        end)

        if not ok then
            oldNamecall = nil
            hookInstalled = false
            Diagnostics.warnings["silentAimHook"] = tostring(err)
            warn("[MM2 v4] Silent aim hook échoué : " .. tostring(err))
        end
    end
end

-- ============================================================
-- [12] COMBAT MODULE
-- ============================================================
function Combat:Init()
    self.silentAimEnabled = false
    self.currentTarget = nil
    self.auraEnabled = false
    self.triggerbotEnabled = false
    self.triggerbotRange = 100
    self.targetRole = "murderer"
    self.targetMode = "nearest"
    self.localRole = "innocent"
    self.lastRoleCheck = 0
    self._cachedPlayers = {}
    self._lastPlayersScan = 0
end

function Combat:shouldTarget(role, myRole)
    if self.targetRole == "murderer" then return role == "murderer" end
    if self.targetRole == "all" then return role ~= myRole or myRole ~= "innocent" end
    if self.targetRole == "custom" then return role ~= "innocent" end
    return false
end

function Combat:selectTarget(candidates)
    if #candidates == 0 then return nil end
    if self.targetMode == "nearest" then
        local best, bestD = nil, math.huge
        for _, c in ipairs(candidates) do
            if c.dist < bestD then best, bestD = c, c.dist end
        end
        return best
    elseif self.targetMode == "closest_mouse" then
        local mouse = UserInputService:GetMouseLocation()
        local best, bestD = nil, math.huge
        for _, c in ipairs(candidates) do
            local sp, on = Camera:WorldToViewportPoint(c.root.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                if d < bestD then best, bestD = c, d end
            end
        end
        return best or candidates[1]
    elseif self.targetMode == "lowest_hp" then
        local best, bestHP = nil, math.huge
        for _, c in ipairs(candidates) do
            local hp = c.hum and c.hum.Health or 100
            if hp < bestHP then best, bestHP = c, hp end
        end
        return best
    end
    return candidates[1]
end

function Combat:Update(dt)
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then return end

    if os.clock() - self.lastRoleCheck > 1 then
        self.lastRoleCheck = os.clock()
        self.localRole = getRole(LocalPlayer)
    end
    local myRole = self.localRole

    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = getRoot(player)
            local hum = getHumanoid(player)
            if root and hum and hum.Health > 0 then
                local role = getRole(player)
                local dist = (root.Position - myRoot.Position).Magnitude
                if self:shouldTarget(role, myRole) then
                    table.insert(candidates, {player = player, root = root, hum = hum, dist = dist, role = role})
                end
            end
        end
    end

    local pick = self:selectTarget(candidates)
    self.currentTarget = pick and pick.player or nil

    if myRole == "sheriff" and self.triggerbotEnabled and self.currentTarget and pick then
        if pick.dist < self.triggerbotRange then
            local sp, on = Camera:WorldToViewportPoint(pick.root.Position)
            if on then
                local mouse = UserInputService:GetMouseLocation()
                local dx = sp.X - mouse.X
                local dy = sp.Y - mouse.Y
                if math.sqrt(dx * dx + dy * dy) < 30 then
                    pcall(function()
                        local remote = nil
                        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                            if v:IsA("RemoteEvent") and v.Name:lower():find("shoot") then
                                remote = v; break
                            end
                        end
                        if remote then remote:FireServer(pick.root.Position) end
                    end)
                end
            end
        end
    end

    if myRole == "murderer" and self.auraEnabled then
        for _, c in ipairs(candidates) do
            if c.dist < 8 then
                pcall(function()
                    local remote = nil
                    for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (v.Name:lower():find("knife") or v.Name:lower():find("slash")) then
                            remote = v; break
                        end
                    end
                    if remote then remote:FireServer(c.player) end
                end)
                break
            end
        end
    end
end

-- ============================================================
-- [13] VISION MODULE
-- ============================================================
function Vision:Init()
    self.espEnabled = true
    self.showBox = true
    self.showName = true
    self.showRole = true
    self.showDist = true
    self.showTracer = true
    self.chams = true
    self.objects = {}
end

function Vision:Clear()
    for player, objs in pairs(self.objects) do
        for _, obj in pairs(objs) do
            pcall(function()
                if typeof(obj) == "Instance" then obj:Destroy()
                elseif obj.Remove then obj:Remove() end
            end)
        end
    end
    self.objects = {}
end

function Vision:Update()
    if not self.espEnabled then
        self:Clear()
        return
    end
    local myRoot = getRoot(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = getRoot(player)
            local role = getRole(player)
            if root then
                local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                if not self.objects[player] then
                    self.objects[player] = {}
                end
                local objs = self.objects[player]
                local color = roleColor(role)

                if self.chams then
                    if not objs.highlight or not objs.highlight.Parent then
                        local hl = Instance.new("Highlight")
                        hl.Name = "MM2_HL"
                        hl.FillTransparency = 0.7
                        hl.OutlineTransparency = 0
                        hl.Parent = player.Character
                        objs.highlight = hl
                    end
                    objs.highlight.FillColor = color
                    objs.highlight.OutlineColor = color
                else
                    if objs.highlight then
                        pcall(function() objs.highlight:Destroy() end)
                        objs.highlight = nil
                    end
                end

                local needBB = self.showName or self.showRole or self.showDist or self.showBox
                if needBB then
                    if not objs.billboard or not objs.billboard.Parent then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "MM2_BB"
                        bb.Size = UDim2.new(0, 120, 0, 60)
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.AlwaysOnTop = true
                        bb.Parent = root
                        objs.billboard = bb
                        local box = Instance.new("Frame")
                        box.Name = "Box"
                        box.Size = UDim2.new(1, 0, 1, 0)
                        box.BackgroundTransparency = 1
                        box.BorderSizePixel = 2
                        box.Parent = bb
                        local text = Instance.new("TextLabel")
                        text.Name = "Info"
                        text.Size = UDim2.new(1, 0, 1, 0)
                        text.BackgroundTransparency = 1
                        text.TextScaled = true
                        text.Font = Enum.Font.GothamBold
                        text.Parent = bb
                        objs.text = text
                    end
                    objs.billboard.Adornee = root
                    objs.billboard.Box.Visible = self.showBox
                    objs.billboard.Box.BorderColor3 = color
                    local parts = {}
                    if self.showName then table.insert(parts, player.Name) end
                    if self.showRole then table.insert(parts, "[" .. role:upper() .. "]") end
                    if self.showDist then table.insert(parts, string.format("[%d]", math.floor(dist))) end
                    objs.text.Text = table.concat(parts, "\n")
                    objs.text.TextColor3 = color
                    objs.text.Visible = (#parts > 0)
                else
                    if objs.billboard then
                        pcall(function() objs.billboard:Destroy() end)
                        objs.billboard = nil
                        objs.text = nil
                    end
                end

                if self.showTracer and capabilities.Drawing then
                    if not objs.tracerLine then
                        objs.tracerLine = Drawing.new("Line")
                        objs.tracerLine.Thickness = 1
                        objs.tracerLine.Transparency = 0.8
                    end
                    local sp, on = Camera:WorldToViewportPoint(root.Position)
                    local vp = Camera.ViewportSize
                    objs.tracerLine.From = Vector2.new(vp.X / 2, vp.Y)
                    objs.tracerLine.To = Vector2.new(sp.X, sp.Y)
                    objs.tracerLine.Color = color
                    objs.tracerLine.Visible = on
                else
                    if objs.tracerLine then
                        pcall(function() objs.tracerLine:Remove() end)
                        objs.tracerLine = nil
                    end
                end
            end
        else
            if self.objects[player] then
                for _, obj in pairs(self.objects[player]) do
                    pcall(function()
                        if typeof(obj) == "Instance" then obj:Destroy()
                        elseif obj.Remove then obj:Remove() end
                    end)
                end
                self.objects[player] = nil
            end
        end
    end
end

-- ============================================================
-- [14] FARM MODULE
-- ============================================================
function Farm:Init()
    self.autoCoin = false
    self.magnet = true
    self.magnetRange = 30
    self.tpDelay = 0.5
    self.lastCoinTP = 0
    self.coins = {}

    local function addCoin(obj)
        if obj:IsA("BasePart") and obj.Name:lower():find("coin") then
            self.coins[obj] = true
        end
    end

    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do addCoin(obj) end
    end)
    connect(Workspace.DescendantAdded, addCoin)
    connect(Workspace.DescendantRemoving, function(obj) self.coins[obj] = nil end)
end

function Farm:Update(dt)
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then return end

    for obj, _ in pairs(self.coins) do
        if obj.Parent then
            local dist = (obj.Position - myRoot.Position).Magnitude
            if self.magnet and dist < self.magnetRange then
                pcall(function()
                    if not obj:FindFirstChild("CoinVel") then
                        local vel = Instance.new("BodyVelocity")
                        vel.Name = "CoinVel"
                        vel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        vel.Velocity = (myRoot.Position - obj.Position).Unit * 50
                        vel.Parent = obj
                    else
                        obj.CoinVel.Velocity = (myRoot.Position - obj.Position).Unit * 50
                    end
                end)
            elseif self.autoCoin and dist > 30 and dist < 200 then
                local now = os.clock()
                if now - self.lastCoinTP >= self.tpDelay then
                    self.lastCoinTP = now
                    pcall(function() myRoot.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0)) end)
                end
            end
        else
            self.coins[obj] = nil
        end
    end
end

-- ============================================================
-- [15] MISC MODULE
-- ============================================================
function Misc:Init()
    self.flyEnabled = false
    self.noclipEnabled = false
    self.speed = 32
    self.antiAfk = true
    self.watermarkEnabled = true
    self.roleNotify = true
    self.fps = 0
    self.lastFpsUpdate = tick()
    self.frameCount = 0
    self.flyVel = nil
    self.flyGyro = nil
    self.lastKnownRole = nil

    -- Watermark
    local target = (gates.gethui and select(2, pcall(gethui))) or game:GetService("CoreGui")
    if target then
        local wm = Instance.new("ScreenGui")
        wm.Name = "MM2_Watermark"
        wm.IgnoreGuiInset = true
        wm.ResetOnSpawn = false
        local ok = pcall(function() wm.Parent = target end)
        if ok then
            self.watermark = wm
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 220, 0, 82)
            frame.Position = UDim2.new(0, 10, 0, 10)
            frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.Parent = wm
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke", frame)
            s.Color = Color3.fromRGB(34, 211, 238); s.Thickness = 1
            self.watermarkText = Instance.new("TextLabel")
            self.watermarkText.Size = UDim2.new(1, -12, 1, -12)
            self.watermarkText.Position = UDim2.new(0, 6, 0, 6)
            self.watermarkText.BackgroundTransparency = 1
            self.watermarkText.TextXAlignment = Enum.TextXAlignment.Left
            self.watermarkText.TextYAlignment = Enum.TextYAlignment.Top
            self.watermarkText.TextScaled = true
            self.watermarkText.Font = Enum.Font.Code
            self.watermarkText.TextColor3 = Color3.fromRGB(230, 230, 240)
            self.watermarkText.Parent = frame
        end
    end
end

function Misc:Update(dt)
    self.frameCount = self.frameCount + 1
    if tick() - self.lastFpsUpdate >= 1 then
        self.fps = self.frameCount
        self.frameCount = 0
        self.lastFpsUpdate = tick()
    end

    local hum = getHumanoid(LocalPlayer)
    if hum then
        hum.WalkSpeed = self.speed
    end

    if self.noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- Role detection + notify
    if self.roleNotify and LocalPlayer.Character then
        local role = getRole(LocalPlayer)
        if role ~= "innocent" and role ~= self.lastKnownRole then
            self.lastKnownRole = role
            Notifications.push("RÔLE", "Tu es : " .. role:upper(), 4)
        elseif role == "innocent" and self.lastKnownRole == nil then
            self.lastKnownRole = "innocent"
        end
    end

    if self.watermarkText then
        local pingStr = "0"
        local ok, pingVal = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        end)
        if ok then pingStr = pingVal end
        self.watermarkText.Text = string.format(
            "MM2 v4 | %s\nTier:%d | FPS:%d | Ping:%s\nProfile: %s",
            execName, tier, self.fps, pingStr, currentProfile:upper()
        )
    end
    if self.watermark then
        self.watermark.Enabled = self.watermarkEnabled
    end
end

function Misc:ToggleFly(enabled)
    self.flyEnabled = enabled
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then return end
    if enabled then
        pcall(function()
            if not self.flyVel or not self.flyVel.Parent then
                self.flyVel = Instance.new("BodyVelocity")
                self.flyVel.Name = "FlyVel"
                self.flyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                self.flyVel.Velocity = Vector3.new(0, 0, 0)
                self.flyVel.Parent = myRoot
            end
            if not self.flyGyro or not self.flyGyro.Parent then
                self.flyGyro = Instance.new("BodyGyro")
                self.flyGyro.Name = "FlyGyro"
                self.flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                self.flyGyro.P = 1e4
                self.flyGyro.Parent = myRoot
            end
        end)
    else
        pcall(function() if self.flyVel then self.flyVel:Destroy() end end)
        pcall(function() if self.flyGyro then self.flyGyro:Destroy() end end)
        self.flyVel = nil
        self.flyGyro = nil
    end
end

function Misc:AntiAfk()
    connect(LocalPlayer.Idled, function()
        if self.antiAfk then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end

-- ============================================================
-- [16] INIT MODULES
-- ============================================================
Combat:Init()
Vision:Init()
Farm:Init()
Misc:Init()
Misc:AntiAfk()

-- ============================================================
-- [17] THEME
-- ============================================================
local Theme = {
    bg         = Color3.fromRGB(10, 10, 16),
    panel      = Color3.fromRGB(19, 19, 28),
    panelHover = Color3.fromRGB(26, 26, 38),
    input      = Color3.fromRGB(14, 14, 22),
    accent     = Color3.fromRGB(34, 211, 238),
    accentAlt  = Color3.fromRGB(168, 85, 247),
    text       = Color3.fromRGB(228, 228, 236),
    subtext    = Color3.fromRGB(120, 124, 138),
    border     = Color3.fromRGB(38, 38, 52),
    success    = Color3.fromRGB(34, 197, 94),
    danger     = Color3.fromRGB(239, 68, 68),
    warning    = Color3.fromRGB(245, 158, 11),
}

-- ============================================================
-- [18] SAFE GUI PARENT
-- ============================================================
local function findGuiParent()
    local candidates = {}
    if type(Diagnostics.getGlobal("gethui")) == "function" then
        local ok, h = pcall(Diagnostics.getGlobal("gethui"))
        if ok and h then table.insert(candidates, h) end
    end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then table.insert(candidates, cg) end
    local ok3, pg = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 3) end)
    if ok3 and pg then table.insert(candidates, pg) end

    for _, p in ipairs(candidates) do
        local ok = pcall(function()
            local f = Instance.new("Folder")
            f.Name = "_test_" .. math.random(1e6, 9e6)
            f.Parent = p
            f:Destroy()
        end)
        if ok then return p end
    end
    return nil
end

local guiParent = findGuiParent()
if not guiParent then
    warn("[MM2 v4] Aucun parent GUI accessible — GUI désactivée. Le script tourne quand même.")
end

-- ============================================================
-- [19] GUI
-- ============================================================
local screenGui, mainFrame, tabFrames, tabButtons, guiSetters, openDropdowns, switchTab
local activeTab = "Combat"

if guiParent then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MM2_HUB_v4"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100
    local ok = pcall(function() screenGui.Parent = guiParent end)
    if not ok then
        warn("[MM2 v4] GUI non parentable — désactivée.")
        screenGui = nil
    end
end

if screenGui then
    -- Main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 760, 0, 540)
    mainFrame.Position = UDim2.new(0.5, -380, 0.5, -270)
    mainFrame.BackgroundColor3 = Theme.bg
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    local ms = Instance.new("UIStroke")
    ms.Color = Theme.border; ms.Thickness = 1
    ms.Parent = mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = Theme.panel
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    local headerMask = Instance.new("Frame")
    headerMask.Size = UDim2.new(1, 0, 0, 12)
    headerMask.Position = UDim2.new(0, 0, 1, -12)
    headerMask.BackgroundColor3 = Theme.panel
    headerMask.BorderSizePixel = 0
    headerMask.Parent = header
    local hLine = Instance.new("Frame")
    hLine.Size = UDim2.new(1, 0, 0, 1)
    hLine.Position = UDim2.new(0, 0, 1, -1)
    hLine.BackgroundColor3 = Theme.border
    hLine.BorderSizePixel = 0
    hLine.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 180, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "MM2 HUB"
    title.TextColor3 = Theme.accent
    title.TextSize = 18
    title.Font = Enum.Font.GothamBlack
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local versionLbl = Instance.new("TextLabel")
    versionLbl.Size = UDim2.new(0, 100, 1, 0)
    versionLbl.Position = UDim2.new(0, 110, 0, 0)
    versionLbl.BackgroundTransparency = 1
    versionLbl.Text = "v4.0"
    versionLbl.TextColor3 = Theme.accentAlt
    versionLbl.TextSize = 12
    versionLbl.Font = Enum.Font.GothamBold
    versionLbl.TextXAlignment = Enum.TextXAlignment.Left
    versionLbl.Parent = header

    -- Status pills
    local pillRow = Instance.new("Frame")
    pillRow.Size = UDim2.new(0, 380, 0, 24)
    pillRow.Position = UDim2.new(0, 190, 0.5, -12)
    pillRow.BackgroundTransparency = 1
    pillRow.Parent = header
    local pl = Instance.new("UIListLayout")
    pl.FillDirection = Enum.FillDirection.Horizontal
    pl.Padding = UDim.new(0, 5)
    pl.VerticalAlignment = Enum.VerticalAlignment.Center
    pl.Parent = pillRow

    local function createPill(text)
        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, 84, 1, 0)
        pill.BackgroundColor3 = Theme.input
        pill.BorderSizePixel = 0
        pill.Parent = pillRow
        Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.subtext
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium
        lbl.Parent = pill
        return lbl
    end

    local pillExec = createPill(execName:sub(1, 10))
    local pillTier = createPill("T:" .. tier)
    local pillFps = createPill("FPS:0")
    local pillPing = createPill("Ping:0")

    -- Minimize / close
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    minimizeBtn.Position = UDim2.new(1, -72, 0.5, -16)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = Theme.subtext
    minimizeBtn.TextSize = 16
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.danger
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 150, 1, -48)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = Theme.panel
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    local slLine = Instance.new("Frame")
    slLine.Size = UDim2.new(0, 1, 1, 0)
    slLine.Position = UDim2.new(1, -1, 0, 0)
    slLine.BackgroundColor3 = Theme.border
    slLine.BorderSizePixel = 0
    slLine.Parent = sidebar
    local slLayout = Instance.new("UIListLayout")
    slLayout.Padding = UDim.new(0, 3)
    slLayout.Parent = sidebar
    local slPad = Instance.new("Frame")
    slPad.Size = UDim2.new(1, 0, 0, 8)
    slPad.BackgroundTransparency = 1
    slPad.LayoutOrder = 0
    slPad.Parent = sidebar

    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -150, 1, -48)
    contentArea.Position = UDim2.new(0, 150, 0, 48)
    contentArea.BackgroundColor3 = Theme.bg
    contentArea.BorderSizePixel = 0
    contentArea.Parent = mainFrame

    tabFrames = {}
    tabButtons = {}

    local function createTab(name, icon)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, -8, 0, 38)
        btn.BackgroundColor3 = Theme.panel
        btn.BackgroundTransparency = 1
        btn.Text = "  " .. icon .. "   " .. name
        btn.TextColor3 = Theme.subtext
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = #tabButtons + 1
        btn.Parent = sidebar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0, 20)
        indicator.Position = UDim2.new(0, 0, 0.5, -10)
        indicator.BackgroundColor3 = Theme.accent
        indicator.BorderSizePixel = 0
        indicator.Visible = false
        indicator.Parent = btn
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)

        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = name
        scroll.Size = UDim2.new(1, -16, 1, -16)
        scroll.Position = UDim2.new(0, 8, 0, 8)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 4
        scroll.ScrollBarImageColor3 = Theme.border
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Visible = false
        scroll.Parent = contentArea

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.Parent = scroll

        local pad = Instance.new("Frame")
        pad.Size = UDim2.new(1, 0, 0, 4)
        pad.BackgroundTransparency = 1
        pad.LayoutOrder = 0
        pad.Parent = scroll

        tabFrames[name] = scroll
        tabButtons[name] = { btn = btn, indicator = indicator }
    end

    createTab("Combat", "⚔")
    createTab("Vision", "👁")
    createTab("Farm", "🌾")
    createTab("Players", "👥")
    createTab("Diag", "🔧")
    createTab("Misc", "⚙")

    switchTab = function(name)
        activeTab = name
        for n, data in pairs(tabButtons) do
            local isActive = (n == name)
            data.indicator.Visible = isActive
            data.btn.TextColor3 = isActive and Theme.text or Theme.subtext
            data.btn.BackgroundTransparency = isActive and 0.5 or 1
            data.btn.BackgroundColor3 = isActive and Theme.accent or Theme.panel
        end
        for n, frame in pairs(tabFrames) do
            frame.Visible = (n == name)
        end
    end

    for name, data in pairs(tabButtons) do
        data.btn.MouseButton1Click:Connect(function() switchTab(name) end)
    end
    switchTab("Combat")

    -- Widget helpers
    guiSetters = {}
    openDropdowns = {}

    local function createSection(parent, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -8, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Text = text:upper()
        lbl.TextColor3 = Theme.accent
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = parent
        return lbl
    end

    local function createToggle(parent, labelText, defaultVal, warningText, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -8, 0, warningText and 42 or 36)
        container.BackgroundColor3 = Theme.panel
        container.BorderSizePixel = 0
        container.Parent = parent
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Theme.text
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container

        if warningText then
            local warn = Instance.new("TextLabel")
            warn.Size = UDim2.new(0, 140, 0, 14)
            warn.Position = UDim2.new(0, 12, 0, 22)
            warn.BackgroundTransparency = 1
            warn.Text = warningText
            warn.TextColor3 = Theme.warning
            warn.TextSize = 9
            warn.Font = Enum.Font.GothamBold
            warn.TextXAlignment = Enum.TextXAlignment.Left
            warn.Parent = container
        end

        local track = Instance.new("Frame")
        track.Size = UDim2.new(0, 40, 0, 20)
        track.Position = UDim2.new(1, -52, 0.5, -10)
        track.BackgroundColor3 = defaultVal and Theme.accent or Theme.input
        track.BorderSizePixel = 0
        track.Parent = container
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = defaultVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = defaultVal
        local function setState(val)
            state = val
            track.BackgroundColor3 = val and Theme.accent or Theme.input
            knob.Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = container

        btn.MouseButton1Click:Connect(function()
            state = not state
            setState(state)
            pcall(callback, state)
        end)

        return setState
    end

    local function createSlider(parent, labelText, min, max, defaultVal, warningThreshold, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -8, 0, 50)
        container.BackgroundColor3 = Theme.panel
        container.BorderSizePixel = 0
        container.Parent = parent
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Theme.text
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container

        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0.3, 0, 0, 20)
        valLabel.Position = UDim2.new(0.65, 0, 0, 5)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = tostring(math.floor(defaultVal))
        valLabel.TextColor3 = Theme.accent
        valLabel.TextSize = 13
        valLabel.Font = Enum.Font.GothamBold
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.Parent = container

        local warnLabel = Instance.new("TextLabel")
        warnLabel.Size = UDim2.new(0.3, 0, 0, 14)
        warnLabel.Position = UDim2.new(0.65, 0, 0, 24)
        warnLabel.BackgroundTransparency = 1
        warnLabel.Text = ""
        warnLabel.TextColor3 = Theme.danger
        warnLabel.TextSize = 9
        warnLabel.Font = Enum.Font.GothamBold
        warnLabel.TextXAlignment = Enum.TextXAlignment.Right
        warnLabel.Parent = container

        local trackBg = Instance.new("Frame")
        trackBg.Size = UDim2.new(1, -24, 0, 6)
        trackBg.Position = UDim2.new(0, 12, 0, 36)
        trackBg.BackgroundColor3 = Theme.input
        trackBg.BorderSizePixel = 0
        trackBg.Parent = container
        Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Theme.accent
        fill.BorderSizePixel = 0
        fill.Parent = trackBg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local sliderKnob = Instance.new("Frame")
        sliderKnob.Size = UDim2.new(0, 14, 0, 14)
        sliderKnob.Position = UDim2.new((defaultVal - min) / (max - min), -7, 0.5, -7)
        sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderKnob.BorderSizePixel = 0
        sliderKnob.ZIndex = 3
        sliderKnob.Parent = trackBg
        Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

        local currentVal = defaultVal
        local dragging = false

        local function updateVisual(val)
            currentVal = math.clamp(val, min, max)
            local pct = (currentVal - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            sliderKnob.Position = UDim2.new(pct, -7, 0.5, -7)
            valLabel.Text = tostring(math.floor(currentVal * 10) / 10)
            if warningThreshold and currentVal > warningThreshold then
                warnLabel.Text = "⚠ DANGER"
            else
                warnLabel.Text = ""
            end
        end

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, -24, 0, 20)
        hit.Position = UDim2.new(0, 12, 0, 30)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.ZIndex = 2
        hit.Parent = container

        hit.MouseButton1Down:Connect(function() dragging = true end)

        local moveConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local relX = (input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X
                updateVisual(min + relX * (max - min))
                pcall(callback, currentVal)
            end
        end)
        local upConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        table.insert(connections, moveConn)
        table.insert(connections, upConn)

        local function setState(val) updateVisual(val); pcall(callback, currentVal) end
        updateVisual(defaultVal)
        return setState
    end

    local function createDropdown(parent, labelText, options, defaultVal, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -8, 0, 36)
        container.BackgroundColor3 = Theme.panel
        container.BorderSizePixel = 0
        container.Parent = parent
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Theme.text
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container

        local selected = defaultVal
        local dropBtn = Instance.new("TextButton")
        dropBtn.Size = UDim2.new(0, 120, 0, 24)
        dropBtn.Position = UDim2.new(1, -132, 0.5, -12)
        dropBtn.BackgroundColor3 = Theme.input
        dropBtn.BorderSizePixel = 0
        dropBtn.Text = selected
        dropBtn.TextColor3 = Theme.accent
        dropBtn.TextSize = 12
        dropBtn.Font = Enum.Font.GothamBold
        dropBtn.Parent = container
        Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)

        local dropList = Instance.new("Frame")
        dropList.Size = UDim2.new(0, 120, 0, #options * 26 + 4)
        dropList.BackgroundColor3 = Theme.input
        dropList.BorderSizePixel = 0
        dropList.Visible = false
        dropList.ZIndex = 500
        dropList.Parent = screenGui
        Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 4)
        local dlStroke = Instance.new("UIStroke")
        dlStroke.Color = Theme.border; dlStroke.Thickness = 1
        dlStroke.Parent = dropList

        table.insert(openDropdowns, dropList)

        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 24)
            optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 26 + 2)
            optBtn.BackgroundTransparency = 1
            optBtn.Text = opt
            optBtn.TextColor3 = opt == selected and Theme.accent or Theme.text
            optBtn.TextSize = 12
            optBtn.Font = Enum.Font.GothamMedium
            optBtn.ZIndex = 501
            optBtn.Parent = dropList

            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                dropBtn.Text = opt
                dropList.Visible = false
                for _, child in pairs(dropList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.TextColor3 = child.Text == opt and Theme.accent or Theme.text
                    end
                end
                pcall(callback, opt)
            end)
        end

        dropBtn.MouseButton1Click:Connect(function()
            local nowVisible = not dropList.Visible
            for _, dl in ipairs(openDropdowns) do dl.Visible = false end
            dropList.Visible = nowVisible
            if nowVisible then
                dropList.Position = UDim2.new(0, dropBtn.AbsolutePosition.X, 0,
                    dropBtn.AbsolutePosition.Y + dropBtn.AbsoluteSize.Y + 2)
            end
        end)

        local function setState(val)
            selected = val
            dropBtn.Text = val
            for _, child in pairs(dropList:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = child.Text == val and Theme.accent or Theme.text
                end
            end
        end
        return setState
    end

    local function createButton(parent, labelText, bgColor, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 36)
        btn.BackgroundColor3 = bgColor
        btn.BorderSizePixel = 0
        btn.Text = labelText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function() pcall(callback) end)
        return btn
    end

    -- ============================================================
    -- COMBAT TAB
    -- ============================================================
    local combatTab = tabFrames["Combat"]
    createSection(combatTab, "PROFILES")

    local profileContainer = Instance.new("Frame")
    profileContainer.Size = UDim2.new(1, -8, 0, 36)
    profileContainer.BackgroundTransparency = 1
    profileContainer.Parent = combatTab
    local pLayout = Instance.new("UIListLayout")
    pLayout.FillDirection = Enum.FillDirection.Horizontal
    pLayout.Padding = UDim.new(0, 6)
    pLayout.Parent = profileContainer

    local profileBtns = {}

    local function applyProfile(name)
        currentProfile = name
        local p = profiles[name]
        Combat.silentAimEnabled = p.silentAim
        Combat.auraEnabled = p.aura
        Combat.triggerbotEnabled = p.triggerbot
        Combat.triggerbotRange = p.triggerbotRange
        Combat.targetRole = p.targetRole
        Combat.targetMode = p.targetMode
        Vision.espEnabled = p.esp
        Vision.chams = p.chams
        Vision.showBox = p.showBox
        Vision.showName = p.showName
        Vision.showRole = p.showRole
        Vision.showDist = p.showDist
        Vision.showTracer = p.showTracer
        Farm.autoCoin = p.autoCoin
        Farm.magnet = p.magnet
        Farm.magnetRange = p.magnetRange
        Farm.tpDelay = p.tpDelay
        Misc.speed = p.speed
        Misc.noclipEnabled = p.noclip
        Misc.antiAfk = p.antiAfk
        Misc.watermarkEnabled = p.watermark
        Misc:ToggleFly(p.fly)
        for n, b in pairs(profileBtns) do
            b.BackgroundColor3 = (n == name) and Theme.accentAlt or Theme.panel
            b.TextColor3 = (n == name) and Color3.fromRGB(255, 255, 255) or Theme.subtext
        end
        for key, setter in pairs(guiSetters) do
            if p[key] ~= nil then setter(p[key]) end
        end
        Notifications.push("PROFIL", "Chargé : " .. name:upper(), 2)
    end

    for _, pName in ipairs({"legit", "ultra", "rage"}) do
        local pBtn = Instance.new("TextButton")
        pBtn.Size = UDim2.new(0.3, -4, 1, 0)
        pBtn.BackgroundColor3 = (pName == currentProfile) and Theme.accentAlt or Theme.panel
        pBtn.BorderSizePixel = 0
        pBtn.Text = pName:upper()
        pBtn.TextColor3 = (pName == currentProfile) and Color3.fromRGB(255, 255, 255) or Theme.subtext
        pBtn.TextSize = 12
        pBtn.Font = Enum.Font.GothamBold
        pBtn.Parent = profileContainer
        Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
        pBtn.MouseButton1Click:Connect(function() applyProfile(pName) end)
        profileBtns[pName] = pBtn
    end

    createSection(combatTab, "COMBAT")
    guiSetters.silentAim = createToggle(combatTab, "Silent Aim", Combat.silentAimEnabled,
        hookInstalled and nil or "UNSUPPORTED", function(v) Combat.silentAimEnabled = v end)
    guiSetters.aura = createToggle(combatTab, "Knife Aura", Combat.auraEnabled, nil,
        function(v) Combat.auraEnabled = v end)
    guiSetters.triggerbot = createToggle(combatTab, "Triggerbot", Combat.triggerbotEnabled, nil,
        function(v) Combat.triggerbotEnabled = v end)
    guiSetters.targetRole = createDropdown(combatTab, "Target Role",
        {"murderer", "all", "custom"}, Combat.targetRole,
        function(v) Combat.targetRole = v end)
    guiSetters.targetMode = createDropdown(combatTab, "Target Mode",
        {"nearest", "closest_mouse", "lowest_hp"}, Combat.targetMode,
        function(v) Combat.targetMode = v end)
    guiSetters.triggerbotRange = createSlider(combatTab, "Triggerbot Range", 10, 200,
        Combat.triggerbotRange, nil, function(v) Combat.triggerbotRange = v end)

    -- VISION TAB
    local visionTab = tabFrames["Vision"]
    createSection(visionTab, "ESP")
    guiSetters.esp = createToggle(visionTab, "Enable ESP", Vision.espEnabled, nil,
        function(v) Vision.espEnabled = v end)
    guiSetters.showBox = createToggle(visionTab, "Box", Vision.showBox, nil,
        function(v) Vision.showBox = v end)
    guiSetters.showName = createToggle(visionTab, "Name", Vision.showName, nil,
        function(v) Vision.showName = v end)
    guiSetters.showRole = createToggle(visionTab, "Role", Vision.showRole, nil,
        function(v) Vision.showRole = v end)
    guiSetters.showDist = createToggle(visionTab, "Distance", Vision.showDist, nil,
        function(v) Vision.showDist = v end)
    guiSetters.showTracer = createToggle(visionTab, "Tracer", Vision.showTracer,
        (not capabilities.Drawing) and "SANS DRAWING" or nil, function(v) Vision.showTracer = v end)
    guiSetters.chams = createToggle(visionTab, "Chams Highlight", Vision.chams, nil,
        function(v) Vision.chams = v end)

    -- FARM TAB
    local farmTab = tabFrames["Farm"]
    createSection(farmTab, "FARM")
    guiSetters.autoCoin = createToggle(farmTab, "Auto Coin", Farm.autoCoin, "DÉTECTABLE", 
        function(v) Farm.autoCoin = v end)
    guiSetters.magnet = createToggle(farmTab, "Coin Magnet", Farm.magnet, nil,
        function(v) Farm.magnet = v end)
    guiSetters.magnetRange = createSlider(farmTab, "Magnet Range", 10, 100, Farm.magnetRange, nil,
        function(v) Farm.magnetRange = v end)
    guiSetters.tpDelay = createSlider(farmTab, "TP Delay", 0.2, 2.0, Farm.tpDelay, nil,
        function(v) Farm.tpDelay = v end)

    -- PLAYERS TAB (nouveau)
    local playersTab = tabFrames["Players"]
    createSection(playersTab, "LIVE PLAYERS")

    local playerListHolder = Instance.new("Frame")
    playerListHolder.Size = UDim2.new(1, -8, 0, 400)
    playerListHolder.BackgroundColor3 = Theme.panel
    playerListHolder.BorderSizePixel = 0
    playerListHolder.Parent = playersTab
    Instance.new("UICorner", playerListHolder).CornerRadius = UDim.new(0, 6)

    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -12, 1, -12)
    playerScroll.Position = UDim2.new(0, 6, 0, 6)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ScrollBarImageColor3 = Theme.border
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerScroll.Parent = playerListHolder
    local psLayout = Instance.new("UIListLayout")
    psLayout.Padding = UDim.new(0, 3)
    psLayout.Parent = playerScroll

    local playerRows = {}
    local function refreshPlayerList()
        if activeTab ~= "Players" then return end
        local seen = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                seen[player] = true
                if not playerRows[player] then
                    local row = Instance.new("TextButton")
                    row.Size = UDim2.new(1, 0, 0, 28)
                    row.BackgroundColor3 = Theme.bg
                    row.BorderSizePixel = 0
                    row.Text = ""
                    row.Parent = playerScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
                    nameLbl.Position = UDim2.new(0, 10, 0, 0)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.TextColor3 = Theme.text
                    nameLbl.TextSize = 12
                    nameLbl.Font = Enum.Font.GothamMedium
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.Parent = row
                    local roleLbl = Instance.new("TextLabel")
                    roleLbl.Size = UDim2.new(0.25, 0, 1, 0)
                    roleLbl.Position = UDim2.new(0.5, 0, 0, 0)
                    roleLbl.BackgroundTransparency = 1
                    roleLbl.TextSize = 11
                    roleLbl.Font = Enum.Font.GothamBold
                    roleLbl.TextXAlignment = Enum.TextXAlignment.Center
                    roleLbl.Parent = row
                    local hpLbl = Instance.new("TextLabel")
                    hpLbl.Size = UDim2.new(0.25, -10, 1, 0)
                    hpLbl.Position = UDim2.new(0.75, 0, 0, 0)
                    hpLbl.BackgroundTransparency = 1
                    hpLbl.TextSize = 11
                    hpLbl.Font = Enum.Font.Code
                    hpLbl.TextXAlignment = Enum.TextXAlignment.Right
                    hpLbl.Parent = row
                    playerRows[player] = { row = row, name = nameLbl, role = roleLbl, hp = hpLbl }
                end
                local r = playerRows[player]
                local role = getRole(player)
                local hum = getHumanoid(player)
                r.name.Text = player.DisplayName
                r.role.Text = role:upper()
                r.role.TextColor3 = roleColor(role)
                if hum then
                    r.hp.Text = string.format("%d HP", math.floor(hum.Health))
                    local pct = hum.Health / math.max(hum.MaxHealth, 1)
                    r.hp.TextColor3 = Color3.fromRGB(
                        math.floor(255 * (1 - pct)),
                        math.floor(255 * pct),
                        60
                    )
                else
                    r.hp.Text = "dead"
                    r.hp.TextColor3 = Theme.subtext
                end
            end
        end
        for p, r in pairs(playerRows) do
            if not seen[p] then r.row:Destroy(); playerRows[p] = nil end
        end
    end

    -- DIAG TAB (nouveau)
    local diagTab = tabFrames["Diag"]
    createSection(diagTab, "EXECUTOR DIAGNOSTICS")

    local diagInfo = Instance.new("TextLabel")
    diagInfo.Size = UDim2.new(1, -8, 0, 80)
    diagInfo.BackgroundColor3 = Theme.panel
    diagInfo.BorderSizePixel = 0
    diagInfo.TextXAlignment = Enum.TextXAlignment.Left
    diagInfo.TextYAlignment = Enum.TextYAlignment.Top
    diagInfo.TextColor3 = Theme.text
    diagInfo.TextSize = 12
    diagInfo.Font = Enum.Font.Code
    diagInfo.Parent = diagTab
    Instance.new("UICorner", diagInfo).CornerRadius = UDim.new(0, 6)
    local diagPad = Instance.new("UIPadding")
    diagPad.PaddingTop = UDim.new(0, 8)
    diagPad.PaddingLeft = UDim.new(0, 10)
    diagPad.Parent = diagInfo

    local passed, failed = Diagnostics.summary()
    diagInfo.Text = string.format(
        "Executor : %s\nTier     : %d / 11\nChecks   : %d pass, %d fail",
        execName, tier, passed, failed
    )

    createSection(diagTab, "CHECKS")
    for _, label in ipairs(Diagnostics.order) do
        local ok = Diagnostics.results[label]
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 26)
        row.BackgroundColor3 = Theme.panel
        row.BorderSizePixel = 0
        row.Parent = diagTab
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Theme.text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size = UDim2.new(0, 50, 1, 0)
        statusLbl.Position = UDim2.new(1, -60, 0, 0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = ok and "OK" or "FAIL"
        statusLbl.TextColor3 = ok and Theme.success or Theme.danger
        statusLbl.TextSize = 11
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextXAlignment = Enum.TextXAlignment.Right
        statusLbl.Parent = row
    end

    createSection(diagTab, "ACTIONS")
    createButton(diagTab, "REFRESH DIAGNOSTICS", Theme.accentAlt, function()
        Notifications.push("DIAG", "Rerun non implémenté — recharge le script pour refaire les checks", 4)
    end)

    -- MISC TAB
    local miscTab = tabFrames["Misc"]
    createSection(miscTab, "MOVEMENT")
    guiSetters.fly = createToggle(miscTab, "Fly", Misc.flyEnabled, "DÉTECTABLE",
        function(v) Misc:ToggleFly(v) end)
    guiSetters.noclip = createToggle(miscTab, "NoClip", Misc.noclipEnabled, nil,
        function(v) Misc.noclipEnabled = v end)
    guiSetters.speed = createSlider(miscTab, "WalkSpeed", 16, 60, Misc.speed, 45,
        function(v) Misc.speed = v end)

    createSection(miscTab, "UTILITY")
    guiSetters.antiAfk = createToggle(miscTab, "Anti-AFK", Misc.antiAfk, nil,
        function(v) Misc.antiAfk = v end)
    guiSetters.watermark = createToggle(miscTab, "Watermark", Misc.watermarkEnabled, nil,
        function(v) Misc.watermarkEnabled = v end)
    guiSetters.roleNotify = createToggle(miscTab, "Role Notify", Misc.roleNotify, nil,
        function(v) Misc.roleNotify = v end)

    createSection(miscTab, "KEYBINDS")
    local keybindInfo = Instance.new("TextLabel")
    keybindInfo.Size = UDim2.new(1, -8, 0, 80)
    keybindInfo.BackgroundColor3 = Theme.panel
    keybindInfo.BorderSizePixel = 0
    keybindInfo.TextXAlignment = Enum.TextXAlignment.Left
    keybindInfo.TextYAlignment = Enum.TextYAlignment.Top
    keybindInfo.TextColor3 = Theme.text
    keybindInfo.TextSize = 11
    keybindInfo.Font = Enum.Font.Code
    keybindInfo.Text = "  F    → Toggle Fly\n  END  → Unload\n  RSHIFT → Toggle GUI"
    keybindInfo.Parent = miscTab
    Instance.new("UICorner", keybindInfo).CornerRadius = UDim.new(0, 6)
    local kbPad = Instance.new("UIPadding")
    kbPad.PaddingTop = UDim.new(0, 8)
    kbPad.PaddingLeft = UDim.new(0, 10)
    kbPad.Parent = keybindInfo

    createSection(miscTab, "DANGER ZONE")
    createButton(miscTab, "UNLOAD SCRIPT", Theme.danger, function()
        if getgenv().MM2_UNLOAD then getgenv().MM2_UNLOAD() end
    end)

    -- ============================================================
    -- MINIMIZE / DRAG / RESIZE
    -- ============================================================
    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        sidebar.Visible = not isMinimized
        contentArea.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 760, 0, 48) or UDim2.new(0, 760, 0, 540)
    end)

    local dragging, dragStart, startPos = false, Vector2.new(), UDim2.new()
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = mainFrame.Position
        end
    end)

    local globalDragMove = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                            startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    local globalDragEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local resizing, resizeStart, startSize = false, Vector2.new(), UDim2.new()
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.Position = UDim2.new(1, -16, 1, -16)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.Text = "⋱"
    resizeHandle.TextColor3 = Theme.subtext
    resizeHandle.TextSize = 14
    resizeHandle.Font = Enum.Font.GothamBold
    resizeHandle.Parent = mainFrame

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true; resizeStart = input.Position; startSize = mainFrame.Size
        end
    end)
    local globalResizeMove = UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - resizeStart
            mainFrame.Size = UDim2.new(0, math.max(600, startSize.X.Offset + d.X),
                                        0, math.max(380, startSize.Y.Offset + d.Y))
        end
    end)
    local globalResizeEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        if getgenv().MM2_UNLOAD then getgenv().MM2_UNLOAD() end
    end)

    -- dropdown close on outside click (BUG FIX)
    local dropdownCloseConn = UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local mouse = UserInputService:GetMouseLocation()
        for _, dl in ipairs(openDropdowns) do
            if dl.Visible then
                local ap = dl.AbsolutePosition
                local as = dl.AbsoluteSize
                if mouse.X < ap.X or mouse.X > ap.X + as.X
                   or mouse.Y < ap.Y or mouse.Y > ap.Y + as.Y then
                    dl.Visible = false
                end
            end
        end
    end)
    table.insert(connections, dropdownCloseConn)

    -- keybinds
    connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.F then
            Misc:ToggleFly(not Misc.flyEnabled)
            if guiSetters.fly then guiSetters.fly(Misc.flyEnabled) end
        elseif input.KeyCode == Enum.KeyCode.RightShift then
            if mainFrame then mainFrame.Visible = not mainFrame.Visible end
        elseif input.KeyCode == Enum.KeyCode.End then
            if getgenv().MM2_UNLOAD then getgenv().MM2_UNLOAD() end
        end
    end)

    applyProfile(currentProfile)

    -- cleanup refs
    MM2_CLEANUP = {
        globalDragMove = globalDragMove,
        globalDragEnd = globalDragEnd,
        globalResizeMove = globalResizeMove,
        globalResizeEnd = globalResizeEnd,
    }
end

-- ============================================================
-- [20] MAIN LOOPS
-- ============================================================
connect(RunService.Heartbeat, function(dt)
    pcall(function() Combat:Update(dt) end)
    pcall(function() Farm:Update(dt) end)
    pcall(function() Misc:Update(dt) end)
    if guiParent and tabFrames then
        -- FPS/ping pills
        if activeTab == "Players" then
            pcall(function()
                local seen = {}
                for _, player in ipairs(Players:GetPlayers()) do seen[player] = true end
            end)
        end
    end
end)

connect(RunService.RenderStepped, function()
    pcall(function() Vision:Update() end)
    if Misc.flyEnabled and Misc.flyVel and Misc.flyGyro
       and Misc.flyVel.Parent and Misc.flyGyro.Parent then
        local myRoot = getRoot(LocalPlayer)
        if myRoot and myRoot.Parent then
            local camCF = Camera.CFrame
            Misc.flyGyro.CFrame = camCF
            local vel = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + camCF.LookVector * 50 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - camCF.LookVector * 50 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - camCF.RightVector * 50 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + camCF.RightVector * 50 end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 50, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, 50, 0) end
            Misc.flyVel.Velocity = vel
        end
    end
end)

-- PlayerRemoving cleanup
connect(Players.PlayerRemoving, function(player)
    if Vision.objects[player] then
        for _, obj in pairs(Vision.objects[player]) do
            pcall(function()
                if typeof(obj) == "Instance" then obj:Destroy()
                elseif obj.Remove then obj:Remove() end
            end)
        end
        Vision.objects[player] = nil
    end
end)

-- ============================================================
-- [21] CHAT COMMANDS
-- ============================================================
connect(LocalPlayer.Chatted, function(msg)
    local cmd = msg:lower()
    if cmd == "/legit" then applyProfile("legit")
    elseif cmd == "/ultra" then applyProfile("ultra")
    elseif cmd == "/rage" then applyProfile("rage")
    elseif cmd == "/esp" then Vision.espEnabled = not Vision.espEnabled
    elseif cmd == "/unload" and getgenv().MM2_UNLOAD then getgenv().MM2_UNLOAD() end
end)

-- ============================================================
-- [22] UNLOAD
-- ============================================================
getgenv().MM2_UNLOAD = function()
    pcall(flushConnections)
    pcall(function() Vision:Clear() end)
    if oldNamecall and gates.silentAim then
        pcall(function()
            local mt = getrawmetatable(game)
            if mt then
                setreadonly(mt, false)
                mt.__namecall = oldNamecall
                setreadonly(mt, true)
            end
        end)
    end
    if MM2_CLEANUP then
        for _, c in pairs(MM2_CLEANUP) do pcall(function() c:Disconnect() end) end
    end
    if Misc.watermark then pcall(function() Misc.watermark:Destroy() end) end
    if screenGui then pcall(function() screenGui:Destroy() end) end
    local myRoot = getRoot(LocalPlayer)
    if myRoot then
        pcall(function() if myRoot:FindFirstChild("FlyVel") then myRoot.FlyVel:Destroy() end end)
        pcall(function() if myRoot:FindFirstChild("FlyGyro") then myRoot.FlyGyro:Destroy() end end)
    end
    getgenv().MM2_UNLOAD = nil
end

-- ============================================================
-- [23] BOOT
-- ============================================================
local passed, failed = Diagnostics.summary()
print(string.format("[MM2 v4] Loaded | %s | tier %d/11 | %d OK, %d FAIL",
    execName, tier, passed, failed))

if not hookInstalled then
    warn("[MM2 v4] Silent aim non installé — vérifie l'onglet Diag.")
end

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "MM2 v4",
        Text = string.format("%s | Tier %d", execName, tier),
        Duration = 3,
    })
end)
