local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local exec = (getexecutorname and getexecutorname()) or "unknown"

local isXeno = false
if _G.XENO or _G.xeno then isXeno = true end
if getgenv then
    local g = getgenv()
    if g and (g.XENO or g.xeno) then isXeno = true end
end
if exec:lower():find("xeno") then isXeno = true end

if isXeno then
    local screen = Instance.new("ScreenGui")
    screen.Name = "XenoBan"
    screen.Parent = game:GetService("CoreGui")
    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 400, 0, 50)
    frame.Position = UDim2.new(0.5, -200, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "SUNC INSUFFISANT"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextScaled = true
    while true do task.wait(1) end
end

local tier = 0
local checks = {
    hookmetamethod = hookmetamethod,
    newcclosure = newcclosure,
    getnamecallmethod = getnamecallmethod,
    checkcaller = checkcaller,
    writefile = writefile,
    gethui = gethui,
    Drawing = Drawing
}
for _, v in pairs(checks) do
    if v then tier = tier + 1 end
end

local gates = {
    silentAim = tier >= 4,
    fileIO = tier >= 3,
    gethui = tier >= 3
}

local connections = {}
local function connect(event, func)
    local conn = event:Connect(func)
    table.insert(connections, conn)
    return conn
end

local function flushConnections()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
end

local Combat = {}
local Vision = {}
local Farm = {}
local Misc = {}

local profiles = {
    legit = {
        silentAim = false, aura = false, triggerbot = false,
        esp = true, chams = true, showBox = false, showName = true, showRole = true, showDist = false, showTracer = false,
        autoCoin = false, magnet = true, magnetRange = 20, tpDelay = 1.0,
        speed = 16, noclip = false, fly = false, antiAfk = true, watermark = true, triggerbotRange = 50
    },
    ultra = {
        silentAim = true, aura = true, triggerbot = true,
        esp = true, chams = true, showBox = true, showName = true, showRole = true, showDist = true, showTracer = true,
        autoCoin = false, magnet = true, magnetRange = 30, tpDelay = 0.5,
        speed = 32, noclip = false, fly = false, antiAfk = true, watermark = true, triggerbotRange = 100
    },
    rage = {
        silentAim = true, aura = true, triggerbot = true,
        esp = true, chams = true, showBox = true, showName = true, showRole = true, showDist = true, showTracer = true,
        autoCoin = true, magnet = true, magnetRange = 80, tpDelay = 0.2,
        speed = 32, noclip = true, fly = false, antiAfk = true, watermark = true, triggerbotRange = 200
    }
}
local currentProfile = "ultra"

local function getRole(player)
    local char = player.Character
    if not char then return "innocent" end
    local backpack = player:FindFirstChild("Backpack")
    local function checkTool(parent)
        if not parent then return nil end
        for _, item in pairs(parent:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("knife") or name:find("murder") then return "murderer" end
                if name:find("gun") or name:find("sheriff") then return "sheriff" end
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
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local oldNamecall
if gates.silentAim and hookmetamethod then
    oldNamecall = hookmetamethod(game, "__namecall")
    local newNamecall
    newNamecall = newcclosure(function(self, ...)
        if checkcaller() then return oldNamecall(self, ...) end
        local method = getnamecallmethod()
        if method == "FireServer" and self:IsA("RemoteEvent") then
            local name = self.Name:lower()
            if name:find("shoot") or name:find("fire") or name:find("throw") then
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
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    mt.__namecall = newNamecall
    setreadonly(mt, true)
end

function Combat:Init()
    self.silentAimEnabled = false
    self.currentTarget = nil
    self.auraEnabled = false
    self.triggerbotEnabled = false
    self.triggerbotRange = 100
    self.targetRole = "murderer"
    self.localRole = "innocent"
    self.lastRoleCheck = 0
end

function Combat:Update(dt)
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then return end
    
    if os.clock() - self.lastRoleCheck > 1 then
        self.lastRoleCheck = os.clock()
        self.localRole = getRole(LocalPlayer)
    end
    local myRole = self.localRole

    self.currentTarget = nil
    local closestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = getRoot(player)
            local role = getRole(player)
            if root then
                local dist = (root.Position - myRoot.Position).Magnitude
                local shouldTarget = false
                if self.targetRole == "murderer" and role == "murderer" then shouldTarget = true
                elseif self.targetRole == "all" then shouldTarget = true
                elseif self.targetRole == "custom" and role ~= "innocent" then shouldTarget = true end
                
                if shouldTarget and dist < closestDist then
                    closestDist = dist
                    self.currentTarget = player
                end
                
                if myRole == "sheriff" and self.triggerbotEnabled and dist < self.triggerbotRange then
                    local shouldTrigger = false
                    if self.targetRole == "murderer" and role == "murderer" then shouldTrigger = true
                    elseif self.targetRole == "all" then shouldTrigger = true
                    elseif self.targetRole == "custom" and role ~= "innocent" then shouldTrigger = true end

                    if shouldTrigger then
                        local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
                        if onScreen then
                            local mousePos = UserInputService:GetMouseLocation()
                            local dx = screenPos.X - mousePos.X
                            local dy = screenPos.Y - mousePos.Y
                            if math.sqrt(dx * dx + dy * dy) < 20 then
                                pcall(function()
                                    local remote = nil
                                    for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                                        if v:IsA("RemoteEvent") and v.Name:lower():find("shoot") then
                                            remote = v
                                            break
                                        end
                                    end
                                    if remote then remote:FireServer(root.Position) end
                                end)
                            end
                        end
                    end
                end
                
                if myRole == "murderer" and self.auraEnabled then
                    if dist < 8 then
                        pcall(function()
                            local remote = nil
                            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                                if v:IsA("RemoteEvent") and (v.Name:lower():find("knife") or v.Name:lower():find("slash")) then
                                    remote = v
                                    break
                                end
                            end
                            if remote then remote:FireServer(player) end
                        end)
                    end
                end
            end
        end
    end
end

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
                local color = role == "murderer" and Color3.fromRGB(255, 0, 0) or
                              role == "sheriff" and Color3.fromRGB(0, 100, 255) or
                              Color3.fromRGB(0, 255, 0)
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
                    if self.showDist then table.insert(parts, string.format("[%d studs]", math.floor(dist))) end
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
                if self.showTracer and Drawing then
                    if not objs.tracerLine then
                        local line = Drawing.new("Line")
                        line.Thickness = 1
                        line.Transparency = 0.8
                        objs.tracerLine = line
                    end
                    local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
                    local vp = Camera.ViewportSize
                    objs.tracerLine.From = Vector2.new(vp.X / 2, vp.Y)
                    objs.tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    objs.tracerLine.Color = color
                    objs.tracerLine.Visible = onScreen
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
    
    for _, obj in pairs(Workspace:GetDescendants()) do addCoin(obj) end
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

function Misc:Init()
    self.flyEnabled = false
    self.noclipEnabled = false
    self.speed = 32
    self.antiAfk = true
    self.watermarkEnabled = true
    self.fps = 0
    self.lastFpsUpdate = tick()
    self.frameCount = 0
    self.flyVel = nil
    self.flyGyro = nil
    self.watermark = Instance.new("ScreenGui")
    self.watermark.Name = "MM2_Watermark"
    local guiParent
    local ok, res = pcall(function() return gethui() end)
    if ok and res then guiParent = res else guiParent = game:GetService("CoreGui") end
    self.watermark.Parent = guiParent
    self.watermark.IgnoreGuiInset = true
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = self.watermark
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    self.watermarkText = Instance.new("TextLabel")
    self.watermarkText.Size = UDim2.new(1, -10, 1, -10)
    self.watermarkText.Position = UDim2.new(0, 5, 0, 5)
    self.watermarkText.BackgroundTransparency = 1
    self.watermarkText.TextXAlignment = Enum.TextXAlignment.Left
    self.watermarkText.TextYAlignment = Enum.TextYAlignment.Top
    self.watermarkText.TextScaled = true
    self.watermarkText.Font = Enum.Font.GothamBold
    self.watermarkText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.watermarkText.Parent = frame
end

function Misc:Update(dt)
    self.frameCount = self.frameCount + 1
    if tick() - self.lastFpsUpdate >= 1 then
        self.fps = self.frameCount
        self.frameCount = 0
        self.lastFpsUpdate = tick()
    end
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = self.speed
    end
    if self.noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    if self.watermarkEnabled then
        local pingStr = "0"
        local ok, pingVal = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        end)
        if ok then pingStr = pingVal end
        self.watermarkText.Text = string.format("MM2 | %s | T:%d | FPS:%d | Ping:%s\nProfile: %s", exec, tier, self.fps, pingStr, currentProfile)
        self.watermark.Enabled = true
    else
        self.watermark.Enabled = false
    end
end

function Misc:ToggleFly(enabled)
    self.flyEnabled = enabled
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then return end
    if enabled then
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
    else
        pcall(function() if self.flyVel then self.flyVel:Destroy() end end)
        pcall(function() if self.flyGyro then self.flyGyro:Destroy() end end)
        self.flyVel = nil
        self.flyGyro = nil
    end
end

function Misc:AntiAfk()
    local virtualUser = game:GetService("VirtualUser")
    connect(LocalPlayer.Idled, function()
        if self.antiAfk then
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end
    end)
end

Combat:Init()
Vision:Init()
Farm:Init()
Misc:Init()
Misc:AntiAfk()

local Theme = {
    bg = Color3.fromRGB(10, 10, 16),
    panel = Color3.fromRGB(19, 19, 28),
    input = Color3.fromRGB(14, 14, 22),
    accent = Color3.fromRGB(34, 211, 238),
    accentAlt = Color3.fromRGB(168, 85, 247),
    text = Color3.fromRGB(228, 228, 236),
    subtext = Color3.fromRGB(120, 124, 138),
    border = Color3.fromRGB(38, 38, 52)
}

local guiParent
do
    local ok, res = pcall(function() return gethui() end)
    if ok and res then guiParent = res else guiParent = game:GetService("CoreGui") end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2_GUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetPlayerGuiOnSpawn = false
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 720, 0, 520)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -260)
mainFrame.BackgroundColor3 = Theme.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.border
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Theme.panel
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, -1)
headerLine.BackgroundColor3 = Theme.border
headerLine.BorderSizePixel = 0
headerLine.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 160, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MM2 HUB"
titleLabel.TextColor3 = Theme.accent
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local pillContainer = Instance.new("Frame")
pillContainer.Size = UDim2.new(0, 320, 0, 24)
pillContainer.Position = UDim2.new(0, 170, 0.5, -12)
pillContainer.BackgroundTransparency = 1
pillContainer.Parent = header

local pillLayout = Instance.new("UIListLayout")
pillLayout.FillDirection = Enum.FillDirection.Horizontal
pillLayout.Padding = UDim.new(0, 6)
pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
pillLayout.Parent = pillContainer

local function createPill(parent, text)
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 72, 1, 0)
    pill.BackgroundColor3 = Theme.input
    pill.BorderSizePixel = 0
    pill.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = pill
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

local pillExec = createPill(pillContainer, exec:sub(1, 8))
local pillTier = createPill(pillContainer, "T:" .. tier)
local pillFps = createPill(pillContainer, "FPS:0")
local pillPing = createPill(pillContainer, "Ping:0")

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
closeBtn.TextColor3 = Color3.fromRGB(239, 68, 68)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = header

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 140, 1, -48)
sidebar.Position = UDim2.new(0, 0, 0, 48)
sidebar.BackgroundColor3 = Theme.panel
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sidebarLine = Instance.new("Frame")
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.Position = UDim2.new(1, -1, 0, 0)
sidebarLine.BackgroundColor3 = Theme.border
sidebarLine.BorderSizePixel = 0
sidebarLine.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 2)
sidebarLayout.Parent = sidebar

local sidebarPad = Instance.new("Frame")
sidebarPad.Size = UDim2.new(1, 0, 0, 8)
sidebarPad.BackgroundTransparency = 1
sidebarPad.Parent = sidebar
sidebarPad.LayoutOrder = 0

local contentArea = Instance.new("Frame")
contentArea.Name = "Content"
contentArea.Size = UDim2.new(1, -140, 1, -48)
contentArea.Position = UDim2.new(0, 140, 0, 48)
contentArea.BackgroundColor3 = Theme.bg
contentArea.BorderSizePixel = 0
contentArea.Parent = mainFrame

local tabFrames = {}
local tabButtons = {}
local activeTab = "Combat"

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = Theme.subtext
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = #tabButtons + 1
    btn.Parent = sidebar

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 20)
    indicator.Position = UDim2.new(0, 0, 0.5, -10)
    indicator.BackgroundColor3 = Theme.accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = btn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 2)
    indCorner.Parent = indicator

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
createTab("Misc", "⚙")

local function switchTab(name)
    activeTab = name
    for n, data in pairs(tabButtons) do
        local isActive = (n == name)
        data.indicator.Visible = isActive
        data.btn.TextColor3 = isActive and Theme.text or Theme.subtext
        data.btn.BackgroundTransparency = isActive and 0.7 or 1
        data.btn.BackgroundColor3 = isActive and Theme.accent or Color3.fromRGB(0, 0, 0)
    end
    for n, frame in pairs(tabFrames) do
        frame.Visible = (n == name)
    end
end

for name, data in pairs(tabButtons) do
    data.btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

switchTab("Combat")

local guiSetters = {}
local openDropdowns = {}

local function createSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 24)
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
    container.Size = UDim2.new(1, -8, 0, 36)
    container.BackgroundColor3 = Theme.panel
    container.BorderSizePixel = 0
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

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
        warn.Size = UDim2.new(0, 80, 0, 14)
        warn.Position = UDim2.new(0, 12, 0, 20)
        warn.BackgroundTransparency = 1
        warn.Text = warningText
        warn.TextColor3 = Color3.fromRGB(251, 146, 60)
        warn.TextSize = 9
        warn.Font = Enum.Font.GothamBold
        warn.TextXAlignment = Enum.TextXAlignment.Left
        warn.Parent = container
        container.Size = UDim2.new(1, -8, 0, 42)
    end

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -52, 0.5, -10)
    track.BackgroundColor3 = defaultVal and Theme.accent or Theme.input
    track.BorderSizePixel = 0
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

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
        callback(state)
    end)

    return setState
end

local function createSlider(parent, labelText, min, max, defaultVal, warningThreshold, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, 48)
    container.BackgroundColor3 = Theme.panel
    container.BorderSizePixel = 0
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Theme.text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valLabel.Position = UDim2.new(0.65, 0, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(math.floor(defaultVal))
    valLabel.TextColor3 = Theme.accent
    valLabel.TextSize = 13
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = container

    local warnLabel = Instance.new("TextLabel")
    warnLabel.Size = UDim2.new(0.3, 0, 0, 14)
    warnLabel.Position = UDim2.new(0.65, 0, 0, 22)
    warnLabel.BackgroundTransparency = 1
    warnLabel.Text = ""
    warnLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
    warnLabel.TextSize = 9
    warnLabel.Font = Enum.Font.GothamBold
    warnLabel.TextXAlignment = Enum.TextXAlignment.Right
    warnLabel.Parent = container

    local trackBg = Instance.new("Frame")
    trackBg.Size = UDim2.new(1, -24, 0, 6)
    trackBg.Position = UDim2.new(0, 12, 0, 32)
    trackBg.BackgroundColor3 = Theme.input
    trackBg.BorderSizePixel = 0
    trackBg.Parent = container

    local trackBgCorner = Instance.new("UICorner")
    trackBgCorner.CornerRadius = UDim.new(1, 0)
    trackBgCorner.Parent = trackBg

    local trackFill = Instance.new("Frame")
    trackFill.Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0)
    trackFill.BackgroundColor3 = Theme.accent
    trackFill.BorderSizePixel = 0
    trackFill.Parent = trackBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = trackFill

    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 14, 0, 14)
    sliderKnob.Position = UDim2.new((defaultVal - min) / (max - min), -7, 0.5, -7)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.ZIndex = 3
    sliderKnob.Parent = trackBg

    local sliderKnobCorner = Instance.new("UICorner")
    sliderKnobCorner.CornerRadius = UDim.new(1, 0)
    sliderKnobCorner.Parent = sliderKnob

    local currentVal = defaultVal
    local draggingSlider = false

    local function updateVisual(val)
        currentVal = math.clamp(val, min, max)
        local pct = (currentVal - min) / (max - min)
        trackFill.Size = UDim2.new(pct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pct, -7, 0.5, -7)
        valLabel.Text = tostring(math.floor(currentVal * 10) / 10)
        if warningThreshold and currentVal > warningThreshold then
            warnLabel.Text = "⚠ DANGEROUS"
        else
            warnLabel.Text = ""
        end
    end

    local hitArea = Instance.new("TextButton")
    hitArea.Size = UDim2.new(1, -24, 0, 20)
    hitArea.Position = UDim2.new(0, 12, 0, 26)
    hitArea.BackgroundTransparency = 1
    hitArea.Text = ""
    hitArea.ZIndex = 2
    hitArea.Parent = container

    hitArea.MouseButton1Down:Connect(function()
        draggingSlider = true
    end)

    local sliderMoveConn = UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = (input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X
            local newVal = min + relX * (max - min)
            updateVisual(newVal)
            callback(currentVal)
        end
    end)

    local sliderUpConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)

    table.insert(connections, sliderMoveConn)
    table.insert(connections, sliderUpConn)

    local function setState(val)
        updateVisual(val)
        callback(currentVal)
    end

    updateVisual(defaultVal)
    return setState
end

local function createDropdown(parent, labelText, options, defaultVal, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, 36)
    container.BackgroundColor3 = Theme.panel
    container.BorderSizePixel = 0
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

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
    dropBtn.Size = UDim2.new(0, 100, 0, 24)
    dropBtn.Position = UDim2.new(1, -112, 0.5, -12)
    dropBtn.BackgroundColor3 = Theme.input
    dropBtn.BorderSizePixel = 0
    dropBtn.Text = selected
    dropBtn.TextColor3 = Theme.accent
    dropBtn.TextSize = 12
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.Parent = container

    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 4)
    dropCorner.Parent = dropBtn

    local dropList = Instance.new("Frame")
    dropList.Size = UDim2.new(0, 100, 0, #options * 26 + 4)
    dropList.BackgroundColor3 = Theme.input
    dropList.BorderSizePixel = 0
    dropList.Visible = false
    dropList.ZIndex = 100
    dropList.Parent = screenGui

    local dropListCorner = Instance.new("UICorner")
    dropListCorner.CornerRadius = UDim.new(0, 4)
    dropListCorner.Parent = dropList

    local dropListStroke = Instance.new("UIStroke")
    dropListStroke.Color = Theme.border
    dropListStroke.Thickness = 1
    dropListStroke.Parent = dropList
    
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
        optBtn.ZIndex = 101
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
            callback(opt)
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        dropList.Visible = not dropList.Visible
        if dropList.Visible then
            dropList.Position = UDim2.new(0, dropBtn.AbsolutePosition.X, 0, dropBtn.AbsolutePosition.Y + dropBtn.AbsoluteSize.Y + 2)
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

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    for _, dl in ipairs(openDropdowns) do
        if dl.Visible then
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = dl.AbsolutePosition
            local absSize = dl.AbsoluteSize
            if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
               mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                dl.Visible = false
            end
        end
    end
end)

local combatTab = tabFrames["Combat"]

createSection(combatTab, "PROFILES")

local profileContainer = Instance.new("Frame")
profileContainer.Size = UDim2.new(1, -8, 0, 36)
profileContainer.BackgroundTransparency = 1
profileContainer.Parent = combatTab

local profileLayout = Instance.new("UIListLayout")
profileLayout.FillDirection = Enum.FillDirection.Horizontal
profileLayout.Padding = UDim.new(0, 6)
profileLayout.Parent = profileContainer

local profileBtns = {}

local function applyProfile(name)
    currentProfile = name
    local p = profiles[name]
    Combat.silentAimEnabled = p.silentAim
    Combat.auraEnabled = p.aura
    Combat.triggerbotEnabled = p.triggerbot
    Combat.triggerbotRange = p.triggerbotRange
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
        if p[key] ~= nil then
            setter(p[key])
        end
    end
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

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 6)
    pCorner.Parent = pBtn

    pBtn.MouseButton1Click:Connect(function()
        applyProfile(pName)
    end)

    profileBtns[pName] = pBtn
end

createSection(combatTab, "COMBAT")

guiSetters.silentAim = createToggle(combatTab, "Silent Aim", Combat.silentAimEnabled, nil, function(v)
    Combat.silentAimEnabled = v
end)

guiSetters.aura = createToggle(combatTab, "Knife Aura", Combat.auraEnabled, nil, function(v)
    Combat.auraEnabled = v
end)

guiSetters.triggerbot = createToggle(combatTab, "Triggerbot", Combat.triggerbotEnabled, nil, function(v)
    Combat.triggerbotEnabled = v
end)

guiSetters.targetRole = createDropdown(combatTab, "Target Role", {"murderer", "all", "custom"}, Combat.targetRole, function(v)
    Combat.targetRole = v
end)

guiSetters.triggerbotRange = createSlider(combatTab, "Triggerbot Range", 10, 200, Combat.triggerbotRange, nil, function(v)
    Combat.triggerbotRange = v
end)

local visionTab = tabFrames["Vision"]

createSection(visionTab, "ESP")

guiSetters.esp = createToggle(visionTab, "Enable ESP", Vision.espEnabled, nil, function(v)
    Vision.espEnabled = v
end)

guiSetters.showBox = createToggle(visionTab, "Box", Vision.showBox, nil, function(v)
    Vision.showBox = v
end)

guiSetters.showName = createToggle(visionTab, "Name", Vision.showName, nil, function(v)
    Vision.showName = v
end)

guiSetters.showRole = createToggle(visionTab, "Role", Vision.showRole, nil, function(v)
    Vision.showRole = v
end)

guiSetters.showDist = createToggle(visionTab, "Distance", Vision.showDist, nil, function(v)
    Vision.showDist = v
end)

guiSetters.showTracer = createToggle(visionTab, "Tracer", Vision.showTracer, nil, function(v)
    Vision.showTracer = v
end)

guiSetters.chams = createToggle(visionTab, "Chams Highlight", Vision.chams, nil, function(v)
    Vision.chams = v
end)

local farmTab = tabFrames["Farm"]

createSection(farmTab, "FARM")

guiSetters.autoCoin = createToggle(farmTab, "Auto Coin", Farm.autoCoin, "DÉTECTABLE", function(v)
    Farm.autoCoin = v
end)

guiSetters.magnet = createToggle(farmTab, "Coin Magnet", Farm.magnet, nil, function(v)
    Farm.magnet = v
end)

guiSetters.magnetRange = createSlider(farmTab, "Magnet Range", 10, 100, Farm.magnetRange, nil, function(v)
    Farm.magnetRange = v
end)

guiSetters.tpDelay = createSlider(farmTab, "TP Delay", 0.2, 2.0, Farm.tpDelay, nil, function(v)
    Farm.tpDelay = v
end)

local miscTab = tabFrames["Misc"]

createSection(miscTab, "MOVEMENT")

guiSetters.fly = createToggle(miscTab, "Fly", Misc.flyEnabled, "DÉTECTABLE", function(v)
    Misc:ToggleFly(v)
end)

guiSetters.noclip = createToggle(miscTab, "NoClip", Misc.noclipEnabled, nil, function(v)
    Misc.noclipEnabled = v
end)

guiSetters.speed = createSlider(miscTab, "WalkSpeed", 16, 60, Misc.speed, 45, function(v)
    Misc.speed = v
end)

createSection(miscTab, "UTILITY")

guiSetters.antiAfk = createToggle(miscTab, "Anti-AFK", Misc.antiAfk, nil, function(v)
    Misc.antiAfk = v
end)

guiSetters.watermark = createToggle(miscTab, "Watermark", Misc.watermarkEnabled, nil, function(v)
    Misc.watermarkEnabled = v
end)

createSection(miscTab, "DANGER ZONE")

createButton(miscTab, "UNLOAD SCRIPT", Color3.fromRGB(220, 38, 38), function()
    getgenv().MM2_UNLOAD()
end)

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    sidebar.Visible = not isMinimized
    contentArea.Visible = not isMinimized
    mainFrame.Size = isMinimized and UDim2.new(0, 720, 0, 48) or UDim2.new(0, 720, 0, 520)
end)

local dragging = false
local dragStart = Vector2.new()
local startPos = UDim2.new()

connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

local globalDragMove = UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local globalDragEnd = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local resizing = false
local resizeStart = Vector2.new()
local resizeStartSize = UDim2.new()

local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0, 16, 0, 16)
resizeHandle.Position = UDim2.new(1, -16, 1, -16)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = "⋱"
resizeHandle.TextColor3 = Theme.subtext
resizeHandle.TextSize = 12
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.Parent = mainFrame

connect(resizeHandle.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        resizeStart = input.Position
        resizeStartSize = mainFrame.Size
    end
end)

local globalResizeMove = UserInputService.InputChanged:Connect(function(input)
    if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - resizeStart
        local newW = math.max(500, resizeStartSize.X.Offset + delta.X)
        local newH = math.max(320, resizeStartSize.Y.Offset + delta.Y)
        mainFrame.Size = UDim2.new(0, newW, 0, newH)
    end
end)

local globalResizeEnd = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
    end
end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        Misc:ToggleFly(not Misc.flyEnabled)
        if guiSetters.fly then guiSetters.fly(Misc.flyEnabled) end
    end
end)

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

connect(RunService.RenderStepped, function()
    if Misc.flyEnabled and Misc.flyVel and Misc.flyGyro and Misc.flyVel.Parent and Misc.flyGyro.Parent then
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

connect(RunService.Heartbeat, function(dt)
    Combat:Update(dt)
    Farm:Update(dt)
    Misc:Update(dt)
    pillFps.Text = "FPS:" .. Misc.fps
    local ok, pingVal = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    pillPing.Text = ok and ("Ping:" .. pingVal) or "Ping:0"
end)

connect(RunService.RenderStepped, function()
    Vision:Update()
end)

closeBtn.MouseButton1Click:Connect(function()
    getgenv().MM2_UNLOAD()
end)

getgenv().MM2_UNLOAD = function()
    flushConnections()
    Vision:Clear()
    if oldNamecall then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end)
    end
    pcall(function() Misc.watermark:Destroy() end)
    pcall(function() screenGui:Destroy() end)
    local myRoot = getRoot(LocalPlayer)
    if myRoot then
        pcall(function() if myRoot:FindFirstChild("FlyVel") then myRoot.FlyVel:Destroy() end end)
        pcall(function() if myRoot:FindFirstChild("FlyGyro") then myRoot.FlyGyro:Destroy() end end)
    end
    pcall(function() globalDragMove:Disconnect() end)
    pcall(function() globalDragEnd:Disconnect() end)
    pcall(function() globalResizeMove:Disconnect() end)
    pcall(function() globalResizeEnd:Disconnect() end)
    getgenv().MM2_UNLOAD = nil
end
-- fuck xeno is take localisation of user use solara or else but not jjsploit hot garbage

applyProfile(currentProfile)
