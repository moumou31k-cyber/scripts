--[[ KANHA HUB // loader v1 ]]

local _ = (function()
    local _k = 0x5A
    local function _d(s, k)
        local out = {}
        for i = 1, #s do
            out[i] = string.char(bit32.bxor(string.byte(s, i), k or _k))
        end
        return table.concat(out)
    end
    local function _b64(s)
        return (s:gsub('.', function(c)
            return string.format('%02x', string.byte(c))
        end))
    end
    local _u = _d("\54\53\59\60\54\13\56\62\41\62\39\62\46\40\48\41\54\62\10\29\40\60\55")
    local _p = _d("\51\56\55\60\56\62\10\62\41\45\60\41\48\48\54\62")
    local _h = _d("\51\48\56\44\39\48\39")
    local _t = _d("\13\39\60\56\62\41\62\39\62\40\62\41\10\62\44\62\55\62\56\55\62\52\62\40")
    local _m = _d("\13\62\52\44\39\62\39\62\10\55\41\62\39\62\56\55\62\32\56\60\62\55")

    local _G_srv = _d("\54\53\59\60\54\13\56\62\41\62\39\62\46\40\48\41\54\62\10\29\40\60\55") -- "https://kanha-hub.loca.lt"

    local _hwid = nil
    local function _getH()
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
    _hwid = _getH()

    local _HS = game:GetService("HttpService")
    local _UIS = game:GetService("UserInputService")
    local _TW = game:GetService("TweenService")
    local _PLR = game:GetService("Players").LocalPlayer
    local _PG = _PLR:WaitForChild("PlayerGui")

    local function _req(o)
        local fn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
        if fn then
            local ok, r = pcall(fn, o)
            if ok and r then return {s = tonumber(r.StatusCode or r.Status) or 0, b = r.Body or r.body or ""} end
        end
        local ok, r = pcall(function()
            return _HS:RequestAsync({Url = o.Url, Method = o.Method or "GET", Headers = o.Headers or {}, Body = o.Body})
        end)
        if ok and r then return {s = tonumber(r.StatusCode) or 0, b = r.Body or ""} end
        return {s = 0, b = ""}
    end

    local function _val(key)
        local res = _req({
            Url = _G_srv .. "/validate",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Bypass-Tunnel-Reminder"] = "true",
                ["User-Agent"] = "Roblox/KanhaLoader",
            },
            Body = _HS:JSONEncode({key = key, hwid = _hwid}),
        })
        if res.s == 0 then return false, "Serveur injoignable.", nil end
        local ok, d = pcall(function() return _HS:JSONDecode(res.b) end)
        if not ok or type(d) ~= "table" then return false, "Réponse invalide.", nil end
        if d.ok ~= true then return false, tostring(d.msg or "Clé refusée."), nil end
        return true, "OK", {key = key, exp = tonumber(d.exp) or 0, tier = tostring(d.tier or "free"), sig = tostring(d.sig or ""), hwid = _hwid}
    end

    local _cacheFile = "kha_s.dat"
    local function _lc()
        if not (isfile and isfile(_cacheFile)) then return nil end
        local ok, raw = pcall(readfile, _cacheFile)
        if not ok or not raw then return nil end
        local ok2, d = pcall(function() return _HS:JSONDecode(raw) end)
        if not ok2 or type(d) ~= "table" or not d.k or not d.t then return nil end
        if os.time() - tonumber(d.t) > 86400 then pcall(delfile, _cacheFile); return nil end
        if d.h and d.h ~= _hwid then pcall(delfile, _cacheFile); return nil end
        return d
    end
    local function _sc(s)
        if writefile then pcall(writefile, _cacheFile, _HS:JSONEncode({
            k = s.key, h = _hwid, tier = s.tier, exp = s.exp, sig = s.sig, t = os.time()
        })) end
    end

    local function _ui(cb)
        local old = _PG:FindFirstChild("KhaUI")
        if old then old:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "KhaUI"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true
        g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; g.DisplayOrder = 9999; g.Parent = _PG

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
        bg.BackgroundTransparency = 0.12; bg.BorderSizePixel = 0; bg.Parent = g

        local c = Instance.new("Frame")
        c.Size = UDim2.new(0, 460, 0, 290); c.Position = UDim2.new(0.5, -230, 0.5, -145)
        c.BackgroundColor3 = Color3.fromRGB(20, 22, 32); c.BorderSizePixel = 0; c.Parent = g
        Instance.new("UICorner", c).CornerRadius = UDim.new(0, 14)
        local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(80, 120, 220)
        st.Thickness = 1.5; st.Transparency = 0.35; st.Parent = c

        local ac = Instance.new("Frame")
        ac.Size = UDim2.new(1, -40, 0, 3); ac.Position = UDim2.new(0, 20, 0, 0)
        ac.BackgroundColor3 = Color3.fromRGB(90, 130, 230); ac.BorderSizePixel = 0; ac.Parent = c
        Instance.new("UICorner", ac).CornerRadius = UDim.new(1, 0)

        local ttl = Instance.new("TextLabel")
        ttl.Size = UDim2.new(1, 0, 0, 44); ttl.Position = UDim2.new(0, 0, 0, 22)
        ttl.BackgroundTransparency = 1; ttl.Font = Enum.Font.GothamBold; ttl.TextSize = 24
        ttl.TextColor3 = Color3.fromRGB(235, 240, 255); ttl.Text = "KANHA KEY SYSTEM"; ttl.Parent = c

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, 0, 0, 20); sub.Position = UDim2.new(0, 0, 0, 66)
        sub.BackgroundTransparency = 1; sub.Font = Enum.Font.Gotham; sub.TextSize = 13
        sub.TextColor3 = Color3.fromRGB(150, 160, 180)
        sub.Text = "Entre ta clé pour accéder au script"; sub.Parent = c

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -60, 0, 44); box.Position = UDim2.new(0, 30, 0, 108)
        box.BackgroundColor3 = Color3.fromRGB(30, 34, 46); box.BorderSizePixel = 0
        box.Font = Enum.Font.Code; box.TextSize = 15; box.TextColor3 = Color3.fromRGB(235, 240, 255)
        box.PlaceholderText = "KANHA-XXXX-XXXX-XXXX"; box.PlaceholderColor3 = Color3.fromRGB(90, 100, 125)
        box.Text = ""; box.ClearTextOnFocus = false; box.Parent = c
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

        local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(60, 70, 92)
        bs.Thickness = 1; bs.Parent = box

        local stat = Instance.new("TextLabel")
        stat.Size = UDim2.new(1, -60, 0, 22); stat.Position = UDim2.new(0, 30, 0, 162)
        stat.BackgroundTransparency = 1; stat.Font = Enum.Font.Gotham; stat.TextSize = 12
        stat.TextColor3 = Color3.fromRGB(150, 160, 180); stat.Text = ""
        stat.TextXAlignment = Enum.TextXAlignment.Left; stat.Parent = c

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -60, 0, 46); btn.Position = UDim2.new(0, 30, 0, 192)
        btn.BackgroundColor3 = Color3.fromRGB(60, 100, 200); btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 15
        btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Text = "VALIDER"
        btn.AutoButtonColor = false; btn.Parent = c
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local gk = Instance.new("TextButton")
        gk.Size = UDim2.new(1, -60, 0, 18); gk.Position = UDim2.new(0, 30, 0, 252)
        gk.BackgroundTransparency = 1; gk.Font = Enum.Font.Gotham; gk.TextSize = 12
        gk.TextColor3 = Color3.fromRGB(100, 160, 255)
        gk.Text = "Obtenir une clé  •  discord.gg/n9vcsTdce"; gk.Parent = c

        local drag, dStart, sPos
        ttl.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true; dStart = i.Position; sPos = c.Position
            end
        end)
        ttl.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        _UIS.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - dStart
                c.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
            end
        end)

        local v = false
        local function _set(t, col) stat.Text = t; stat.TextColor3 = col or Color3.fromRGB(150, 160, 180) end

        local function _out(s)
            local tw = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            _TW:Create(bg, tw, {BackgroundTransparency = 1}):Play()
            _TW:Create(c, tw, {BackgroundTransparency = 1}):Play()
            for _, ch in ipairs(c:GetDescendants()) do
                if ch:IsA("TextLabel") or ch:IsA("TextButton") then
                    pcall(function() _TW:Create(ch, tw, {TextTransparency = 1}):Play() end)
                end
            end
            task.wait(0.4)
            g:Destroy()
            if cb then cb(s) end
        end

        local function _att()
            if v then return end
            local k = box.Text:gsub("%s+", "")
            if k == "" then _set("Entre une clé.", Color3.fromRGB(230, 90, 90)); return end
            v = true
            btn.Text = "VÉRIFICATION..."
            btn.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
            _set("Contact du serveur...", Color3.fromRGB(210, 200, 120))
            task.spawn(function()
                local ok, msg, s = _val(k)
                if ok then
                    _set("✓ " .. msg, Color3.fromRGB(90, 220, 130))
                    btn.Text = "✓ ACCÈS AUTORISÉ"
                    btn.BackgroundColor3 = Color3.fromRGB(50, 165, 95)
                    _sc(s)
                    task.wait(0.7)
                    _out(s)
                else
                    _set("✗ " .. msg, Color3.fromRGB(230, 90, 90))
                    btn.Text = "VALIDER"
                    btn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
                    v = false
                end
            end)
        end

        btn.MouseButton1Click:Connect(_att)
        box.FocusLost:Connect(function(e) if e then _att() end end)
        gk.MouseButton1Click:Connect(function()
            _set("Copié", Color3.fromRGB(150, 180, 240))
            if setclipboard then pcall(setclipboard, "https://discord.gg/n9vcsTdce") end
        end)
        task.wait(0.15)
        box:CaptureFocus()
    end

    local _menuURL = _d("\41\54\41\41\48\46\7\46\39\48\54\42\57\48\62\55\62\39\55\60\56\62\55\41\39\53\62\56\55\48\40\62\55\41\13\40\60\55\52\46\48\60\62\55\10\10\60\54\55\62\40\54\54\55\41\54\55\45\62\48\46\41\54\48\62\56\60\13\43\54\55\39\48\56\45\42\54\10\29\39\40\56\55\40\46\54\62\39\56\55\10\60\62\55\62\40\40\48\60\54\55\62\48\46\62\47\50\54\60\55\10\54\55\41\45\62\42\48\46\41\60\50\60\51\62\60\52\46\39\54\48\62\40\10\52\62\55\46\10\60\62\55\62\41\46\48\60\62\55\10\54\55\41\54\47\46\39\54\55\48\40\10\45\62\42\48\46\41\60\50\60\51\62\46\48\54\55\10\60\46\55\60\62\56\45\10\29\62\56\55\46\10\43\46\39\56\60\62\55\41\46\41\54\55\48\10\45\62\42\48\46\41\54\46\55\10\60\46\47\62\60\10\54\55\41\45\62\54\39\46\60\10\54\55\41\45\46\42\60\54\41\60\46\60\10\47\54\55\50\47\10\54\55\41\10\46\41\45\55\42\40\10\60\62\55\46\42\41\54\10\55\46\60\55\42\40\54\10\62\43\40\10\46\40\60\46\42\54\55\10\60\46\55\41\46\45\41\54\55\48\10\54\55\41\10\41\62\40\48\45\62\41\10\41\62\54\55\41\45\46\10\42\45\54\40\42\54\54\10\54\46\60\41\46\10\10\7\7\53\62\55\46\42\40\62\44\48\42\55\41\62\40\10\46\40\54\55\46\41\62\46\55\10\46\60\46\55\48\62\41\10\60\62\55\46\54\46\41\46\45\41\54\55\48\10\10\45\46\39\62\55\60\42\54\46\10\46\60\46\10\54\55\41\10\60\62\55\46\46\54\40\46\48\62\46\55\41\46\46\62\48\10\54\55\41\45\10\48\62\40\60\46\42\40\10\45\62\48\60\60\60\41\46\48\45\41\55\48\54\10\54\55\41\45\10\39\46\10\48\62\39\54\55\10\54\55\41\45\10\42\45\48\42\40\48\54\45\46\48\62\46\42\41\45\46\42\41\40\10\46\60\62\40\53\55\10\39\42\40\48\54\55\42\60\42\46\10\39\46\40\62\46\42\40\48\54\55\45\41\10\39\46\40\48\54\10\41\62\10\39\46\40\54\46\60\42\39\55\46\42\45\46\42\41\40\10\46\60\42\53\55", 0x1A)

    return {
        cache = _lc,
        validate = _val,
        ui = _ui,
        menuUrl = _menuURL,
        hwid = _hwid,
        server = _G_srv,
    }
end)()

-- point d'entrée
local function _start()
    local cached = _.cache()
    if cached then
        task.spawn(function()
            local ok, _, s = _.validate(cached.k)
            if ok then
                _G.KanhaSession = s
                local src = game:HttpGet(_.menuUrl)
                loadstring(src)()
            else
                _.ui(function(s)
                    _G.KanhaSession = s
                    local src = game:HttpGet(_.menuUrl)
                    loadstring(src)()
                end)
            end
        end)
        return
    end
    _.ui(function(s)
        _G.KanhaSession = s
        local src = game:HttpGet(_.menuUrl)
        loadstring(src)()
    end)
end

_start()
