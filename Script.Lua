-- Ui

local UI = (function()
    local Players       = game:GetService("Players")
    local Teams         = game:GetService("Teams")
    local Input         = game:GetService("UserInputService")
    local TweenService  = game:GetService("TweenService")
    local RunService    = game:GetService("RunService")
    local HttpService   = game:GetService("HttpService")
    local TextService   = game:GetService("TextService")

    local player = Players.LocalPlayer
    local UI, Section = {}, {}
    UI.__index, Section.__index = UI, Section

    local function safe(fn, ...)
        if type(fn) ~= "function" then return false end
        local ok, err = pcall(fn, ...)
        return ok, err
    end

    local defaults = {
        background = Color3.fromRGB(8, 8, 8),
        sidebar    = Color3.fromRGB(12, 12, 12),
        panel      = Color3.fromRGB(12, 12, 12),
        raised     = Color3.fromRGB(19, 19, 19),
        hover      = Color3.fromRGB(27, 27, 28),
        text       = Color3.fromRGB(242, 242, 244),
        muted      = Color3.fromRGB(151, 151, 154),
        outline    = Color3.fromRGB(26, 26, 29),
        accent     = Color3.fromRGB(110, 135, 200),
        ink        = Color3.fromRGB(8, 11, 19),
    }

    local iconAssetIds = {
        crosshair = "128484340819096",
        eye       = "81182929477807",
        more      = "86535281649816",
        settings  = "123802788977158",
        person    = "95694267458868",
        search    = "124720799360909",
        chevron   = "76843582814068",
        folder    = "127410692749985",
        sliders   = "76990137077018",
        palette   = "111221333254814",
    }

    local iconAliases = {
        crosshair = "crosshair", aim = "crosshair", combat = "crosshair",
        eye = "eye", visuals = "eye",
        more = "more", misc = "more",
        settings = "settings", gear = "settings",
        person = "person", players = "person", user = "person",
        search = "search", chevron = "chevron", ["chevron-down"] = "chevron",
        folder = "folder", config = "folder", configs = "folder",
        sliders = "sliders", menu = "sliders",
        palette = "palette", theme = "palette",
    }

    local function create(class, properties, parent)
        local x = Instance.new(class)
        if properties then
            for k, v in pairs(properties) do
                pcall(function() x[k] = v end)
            end
        end
        if parent then
            pcall(function() x.Parent = parent end)
        end
        return x
    end

    local function round(x, r)
        if not x or not x.Parent then return end
        local c = x:FindFirstChildOfClass("UICorner") or create("UICorner", {}, x)
        if c then c.CornerRadius = UDim.new(0, r or 4) end
        return c
    end

    local function pill(x)
        local c = round(x)
        if c then c.CornerRadius = UDim.new(.5, 0) end
    end

    local function pad(x, l, r, t, b)
        if not x then return end
        create("UIPadding", {
            PaddingLeft   = UDim.new(0, l or 0),
            PaddingRight  = UDim.new(0, r or l or 0),
            PaddingTop    = UDim.new(0, t or 0),
            PaddingBottom = UDim.new(0, b or t or 0),
        }, x)
    end

    local function layout(x, gap, horizontal)
        if not x then return end
        return create("UIListLayout", {
            Padding       = UDim.new(0, gap or 8),
            SortOrder     = Enum.SortOrder.LayoutOrder,
            FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        }, x)
    end

    local function clone(t)
        local r = {}
        for _, v in ipairs(t or {}) do table.insert(r, v) end
        return r
    end

    local function invoke(callback, ...)
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback, ...)
    end

    local function clamp(v, a, b) return math.clamp(tonumber(v) or a, a, b) end

    local keyboardKeys = {}
    pcall(function()
        for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
            if key ~= Enum.KeyCode.Unknown then keyboardKeys[key.Name:lower()] = key end
        end
    end)

    local keyAliases = {
        ctrl = "LeftControl", control = "LeftControl",
        ["left ctrl"] = "LeftControl", ["right ctrl"] = "RightControl",
        shift = "LeftShift", alt = "LeftAlt", spacebar = "Space",
        ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four",
        ["5"] = "Five", ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight",
        ["9"] = "Nine", ["0"] = "Zero",
        ["mouse left"] = "MouseButton1", ["mouse right"] = "MouseButton2",
        ["mouse middle"] = "MouseButton3",
        mb1 = "MouseButton1", mb2 = "MouseButton2", mb3 = "MouseButton3",
    }

    local function keyOf(name)
        if typeof(name) == "EnumItem" then name = name.Name end
        if type(name) ~= "string" then return nil end
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        name = keyAliases[name:lower()] or name
        local key = keyboardKeys[name:lower()]
        if key then return key end
        for _, button in ipairs({"MouseButton1", "MouseButton2", "MouseButton3"}) do
            if name:lower() == button:lower() then return Enum.UserInputType[button] end
        end
    end

    local function inputKey(input)
        if not input then return nil end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Unknown then return input.KeyCode.Name end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
            return input.UserInputType.Name
        end
    end

    local function shown(x)
        while x and not x:IsA("ScreenGui") do
            if x:IsA("GuiObject") and x.Visible == false then return false end
            x = x.Parent
        end
        return x ~= nil
    end

    local function keyName(key)
        local map = {
            MouseButton1 = "Mouse Left", MouseButton2 = "Mouse Right",
            MouseButton3 = "Mouse Middle",
            LeftControl  = "Left Ctrl", RightControl = "Right Ctrl",
        }
        return map[key] or key
    end

    local function cleanName(s)
        s = tostring(s or "default"):gsub("[^%w_%-]", "_"):sub(1, 48)
        if s == "auto" then s = "_auto" end
        return s ~= "" and s or "default"
    end

    function UI:_connect(signal, fn)
        if not signal then return nil end
        local ok, c = pcall(function() return signal:Connect(fn) end)
        if ok and c then
            table.insert(self.connections, c)
            return c
        end
        return nil
    end

    function UI:_tween(x, props, duration, style)
        if self.destroyed or not x or not x.Parent then return end
        safe(function()
            local active = self.tweens[x]
            if not active then active = {}; self.tweens[x] = active end
            for property, value in pairs(props) do
                if active[property] then pcall(function() active[property]:Cancel() end) end
                local t = TweenService:Create(
                    x,
                    TweenInfo.new(duration or .25, style or self.easing, Enum.EasingDirection.Out),
                    {[property] = value}
                )
                active[property] = t
                t.Completed:Once(function()
                    if active[property] == t then active[property] = nil end
                end)
                t:Play()
            end
        end)
    end

    function UI:_changeText(x, text, silent)
        if self.destroyed or not x or not x.Parent then return end
        safe(function()
            text = tostring(text or "")
            if x.Text == text then
                if silent then x.TextTransparency = 0 end
                return
            end
            x.Text = text
            if not silent then
                x.TextTransparency = .45
                self:_tween(x, {TextTransparency = 0}, .18, Enum.EasingStyle.Sine)
            else
                x.TextTransparency = 0
            end
        end)
    end

    function UI:_bind(x, property, role, transform)
        if not x then return end
        local entry = {x = x, property = property, role = role, transform = transform}
        table.insert(self.bindings, entry)
        safe(function()
            x[property] = transform and transform(self.colors[role]) or self.colors[role]
        end)
        return entry
    end

    function UI:_frame(parent, props, role)
        local x = create("Frame", props, parent)
        if role then self:_bind(x, "BackgroundColor3", role) end
        return x
    end

    function UI:_text(parent, text, size, role)
        local x = create("TextLabel", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Text = tostring(text or ""), Font = Enum.Font.GothamBlack,
            TextSize = (size or 12) + 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
        }, parent)
        self:_bind(x, "TextColor3", role or "text")
        return x
    end

    function UI:_stroke(x, role, transparency)
        local s = create("UIStroke", {
            Thickness = 1, Transparency = transparency or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, x)
        self:_bind(s, "Color", role or "outline")
        return s
    end

    function UI:_gradient(x)
        return create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(100, 107, 137)),
        }, x)
    end

    function UI:_glow(parent, radius)
        local parts = {}
        for i, extra in ipairs({16, 10, 5}) do
            local f = self:_frame(parent, {
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.fromOffset(-extra / 2, -extra / 2),
                Size = UDim2.new(1, extra, 1, extra), ZIndex = 1,
            }, "accent")
            round(f, radius + extra / 2)
            parts[i] = f
        end
        return function(enabled, instant)
            safe(function()
                for i, f in ipairs(parts) do
                    local a = enabled and (.96 - i * .035) or 1
                    if instant then f.BackgroundTransparency = a
                    else self:_tween(f, {BackgroundTransparency = a}, .32, Enum.EasingStyle.Sine) end
                end
            end)
        end
    end

    function UI:_icon(parent, kind, size, role)
        local image
        if type(kind) == "number" then
            image = "rbxassetid://" .. tostring(math.floor(kind))
        elseif type(kind) == "string" then
            local raw = kind:gsub("^%s+", ""):gsub("%s+$", "")
            if raw:match("^rbxassetid://%d+$") then image = raw
            elseif raw:match("^https?://") then image = raw
            elseif raw:match("^%d+$") then image = "rbxassetid://" .. raw
            else kind = raw:lower():gsub("^lucide%-", ""); kind = iconAliases[kind] or kind end
        else
            kind = "more"
        end
        local assetId = iconAssetIds[kind]
        if not image then
            if not assetId then kind = "more"; assetId = iconAssetIds[kind] end
            image = "rbxassetid://" .. assetId
        end

        local host = parent
        local owned = {}
        local inset = parent:FindFirstChildOfClass("UIPadding")
        if inset then
            host = self:_frame(parent, {
                Name = "IconLayer", BackgroundTransparency = 1,
                BorderSizePixel = 0, Active = false, ZIndex = 5,
            })
            local function align()
                safe(function()
                    local l, r, t, b = inset.PaddingLeft, inset.PaddingRight, inset.PaddingTop, inset.PaddingBottom
                    host.Position = UDim2.new(-l.Scale, -l.Offset, -t.Scale, -t.Offset)
                    host.Size = UDim2.new(
                        1 + l.Scale + r.Scale, l.Offset + r.Offset,
                        1 + t.Scale + b.Scale, t.Offset + b.Offset
                    )
                end)
            end
            align()
            for _, property in ipairs({"PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom"}) do
                local c = self:_connect(inset:GetPropertyChangedSignal(property), align)
                if c then table.insert(owned, c) end
            end
        end

        local root = self:_frame(host, {
            Name = "Icon_" .. kind, BackgroundTransparency = 1,
            BorderSizePixel = 0, AnchorPoint = Vector2.new(.5, .5),
            Position = UDim2.fromScale(.5, .5),
            Size = UDim2.fromOffset(26, 26),
            ZIndex = 5, Active = false, ClipsDescendants = false,
        })
        create("UIScale", {Scale = (tonumber(size) or 20) / 26}, root)

        local tint = create("Color3Value", {Name = "Tint"}, root)
        self:_bind(tint, "Value", role or "muted")

        local sprite = create("ImageLabel", {
            Name = "IconImage", BackgroundTransparency = 1,
            BorderSizePixel = 0, Image = image, ImageColor3 = tint.Value,
            Size = UDim2.fromScale(1, 1), ZIndex = 5, Active = false,
        }, root)

        local c = self:_connect(tint.Changed, function(color)
            safe(function() if sprite then sprite.ImageColor3 = color end end)
        end)
        if c then table.insert(owned, c) end

        root.Destroying:Once(function()
            for _, connection in ipairs(owned) do
                pcall(function() connection:Disconnect() end)
                local index = table.find(self.connections, connection)
                if index then table.remove(self.connections, index) end
            end
            for i = #self.bindings, 1, -1 do
                if self.bindings[i].x == tint then table.remove(self.bindings, i) end
            end
        end)

        return root, function(color)
            if root.Parent then self:_tween(tint, {Value = color}, .22) end
        end
    end

    function UI:_button(parent, text)
        local b = create("TextButton", {
            BackgroundColor3 = self.colors.raised, BorderSizePixel = 0,
            Text = text or "", TextColor3 = self.colors.text,
            Font = Enum.Font.GothamBlack, TextSize = 13, AutoButtonColor = false,
        }, parent)
        round(b, 4)
        self:_bind(b, "TextColor3", "text")
        local outline = self:_stroke(b, "accent", 1)
        local scale = create("UIScale", {Scale = 1}, b)
        local owned = {}
        local function connect(signal, callback)
            if not signal then return end
            local ok, c = pcall(function() return signal:Connect(callback) end)
            if ok and c then
                table.insert(self.connections, c)
                table.insert(owned, c)
            end
        end
        local hover = false
        local function repaint()
            safe(function()
                local selected = b:GetAttribute("Selected")
                self:_tween(b, {
                    BackgroundColor3 = selected and self.colors.accent
                        or (hover and self.colors.hover or self.colors.panel),
                }, .22)
                self:_tween(outline, {Transparency = hover and .78 or 1}, .22)
            end)
        end
        connect(b.MouseEnter, function() hover = true repaint() end)
        connect(b.MouseLeave, function() hover = false repaint() self:_tween(scale, {Scale = 1}, .25) end)
        connect(b.MouseButton1Down, function() self:_tween(scale, {Scale = .985}, .12) end)
        connect(b.MouseButton1Up, function() self:_tween(scale, {Scale = 1}, .3, Enum.EasingStyle.Quart) end)
        connect(b:GetAttributeChangedSignal("Selected"), repaint)
        table.insert(self.repaint, repaint)

        b.Destroying:Once(function()
            for _, c in ipairs(owned) do
                pcall(function() c:Disconnect() end)
                local i = table.find(self.connections, c)
                if i then table.remove(self.connections, i) end
            end
            local i = table.find(self.repaint, repaint)
            if i then table.remove(self.repaint, i) end
            for index = #self.bindings, 1, -1 do
                local x = self.bindings[index].x
                if x == b or x == outline then table.remove(self.bindings, index) end
            end
        end)
        return b
    end

    function UI:_input(parent, placeholder, text)
        local x = create("TextBox", {
            BackgroundColor3 = self.colors.raised, BorderSizePixel = 0,
            ClearTextOnFocus = false, Text = tostring(text or ""),
            PlaceholderText = placeholder or "", TextSize = 13,
            Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 30),
        }, parent)
        self:_bind(x, "BackgroundColor3", "raised")
        self:_bind(x, "TextColor3", "text")
        self:_bind(x, "PlaceholderColor3", "muted")
        round(x, 4); pad(x, 12, 10)
        local s = self:_stroke(x, "accent", 1)
        self:_connect(x.Focused, function() self:_tween(s, {Transparency = .45}, .18) end)
        self:_connect(x.FocusLost, function() self:_tween(s, {Transparency = 1}, .3) end)
        return x
    end

    function UI:_hudCard(name, position, anchor, width, height)
        local panel = self:_frame(self.hudLayer, {
            Name = name, BorderSizePixel = 0, Position = position,
            AnchorPoint = anchor, Size = UDim2.fromOffset(width, height),
        }, "panel")
        round(panel, 6); self:_stroke(panel, "outline", .15)
        local header = self:_frame(panel, {
            Name = "Header", BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
        }, "raised")
        round(header, 6)
        if height > 32 then
            self:_frame(header, {
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -4),
                Size = UDim2.new(1, 0, 0, 4),
            }, "raised")
        end
        return panel, header
    end

    function UI:_createHUD(options)
        self.hudLayer = self:_frame(self.root, {
            Name = "Hud", BackgroundTransparency = 1,
            BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 250,
        })
        self.watermarkEnabled = options.Watermark ~= false
        self.keybindListEnabled = options.KeybindList ~= false
        self.targetHUDEnabled = options.TargetHud ~= false
        self.moderatorsEnabled = options.Moderators ~= false
        self.hudName = tostring(options.WatermarkName or options.Title or "Skid hub")
        self.keybindRows = {}
        self.keybindDirty = true
        self.keybindVisibleCount = 0
        self.hudStatsDirty = true
        self.frameCount = 0; self.frameElapsed = 0; self.statsElapsed = 0
        self.fps = 0
        self.playerCount = #Players:GetPlayers()
        self.clock = os.date("%H:%M:%S")
        self._targetStatusRole = "muted"

        self.watermark = self:_hudCard("Watermark", UDim2.new(.5, 0, 0, 12), Vector2.new(.5, 0), 540, 32)
        self.watermark.Visible = self.watermarkEnabled
        self.watermarkTitle = self:_text(self.watermark, self.hudName, nil, "accent")
        self.watermarkTitle.Position = UDim2.fromOffset(12, 0)
        self.watermarkTitle.Size = UDim2.fromOffset(92, 32)
        self.watermarkTitle.TextTruncate = Enum.TextTruncate.AtEnd
        self.watermarkDivider = self:_frame(self.watermark, {
            BorderSizePixel = 0, Position = UDim2.fromOffset(108, 9),
            Size = UDim2.fromOffset(1, 14),
        }, "outline")
        self.watermarkStats = self:_text(self.watermark, "", 11, "text")
        self.watermarkStats.Position = UDim2.fromOffset(120, 0)
        self.watermarkStats.Size = UDim2.new(1, -132, 1, 0)
        self.watermarkStats.TextTruncate = Enum.TextTruncate.AtEnd

        local targetHUDWidth, targetHUDHeight = 240, 92
        local tPanel, tHeader = self:_hudCard(
            "TargetHUD", UDim2.new(1, -12, .5, 0), Vector2.new(1, .5),
            targetHUDWidth, targetHUDHeight
        )
        self.targetHUD = tPanel
        self.targetHUD.Visible = self.targetHUDEnabled
        self.targetHUDHeight = targetHUDHeight

        local tIcon = self:_frame(tHeader, {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 9),
            Size = UDim2.fromOffset(14, 14),
        })
        self:_icon(tIcon, "person", 14, "accent")

        local tTitle = self:_text(tHeader, "Target HUD")
        tTitle.Position = UDim2.fromOffset(34, 0)
        tTitle.Size = UDim2.new(1, -46, 1, 0)

        self.targetAvatar = create("ImageLabel", {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 40),
            Size = UDim2.fromOffset(44, 44),
            ScaleType = Enum.ScaleType.Crop,
        }, self.targetHUD)
        round(self.targetAvatar, 7)
        self:_stroke(self.targetAvatar, "outline", 0.5)
        self.targetAvatar.Visible = false

        self.targetName = self:_text(self.targetHUD, "Player: None", 12, "text")
        self.targetName.Position = UDim2.fromOffset(66, 36)
        self.targetName.Size = UDim2.new(1, -78, 0, 18)
        self.targetName.TextTruncate = Enum.TextTruncate.AtEnd

        self.targetStatus = self:_text(self.targetHUD, "Status: None", 11, "muted")
        self.targetStatus.Position = UDim2.fromOffset(66, 54)
        self.targetStatus.Size = UDim2.new(1, -78, 0, 18)
        self.targetStatus.TextTruncate = Enum.TextTruncate.AtEnd

        self.targetHealthBg = self:_frame(self.targetHUD, {
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Position = UDim2.fromOffset(66, 76),
            Size = UDim2.new(1, -78, 0, 8),
        }, "raised")
        round(self.targetHealthBg, 4)
        self:_stroke(self.targetHealthBg, "outline", 0.5)

        self.targetHealthBar = self:_frame(self.targetHealthBg, {
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
        })
        self.targetHealthBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        round(self.targetHealthBar, 4)

        local panel, header = self:_hudCard("Keybinds", UDim2.new(0, 12, .5, 0), Vector2.new(0, .5), 240, 40)
        self.keybindPanel = panel
        panel.Visible = self.keybindListEnabled
        local title = self:_text(header, "Keybinds")
        title.Position = UDim2.fromOffset(12, 0)
        title.Size = UDim2.new(1, -60, 1, 0)
        self.keybindCount = self:_text(header, "0", 11, "muted")
        self.keybindCount.TextXAlignment = Enum.TextXAlignment.Right
        self.keybindCount.Position = UDim2.new(1, -46, 0, 0)
        self.keybindCount.Size = UDim2.fromOffset(34, 32)
        
        self.keybindBody = create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ClipsDescendants = true, Position = UDim2.fromOffset(0, 36),
            Size = UDim2.new(1, 0, 0, 0), CanvasSize = UDim2.new(),
            ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, panel)
        self:_bind(self.keybindBody, "ScrollBarImageColor3", "accent")
        layout(self.keybindBody, 0)
        
        self.keybindEmpty = self:_text(self.keybindBody, "None", 11, "muted")
        self.keybindEmpty.Position = UDim2.fromOffset(24, 0)
        self.keybindEmpty.Size = UDim2.new(1, -34, 0, 24)
        self.keybindEmpty.LayoutOrder = 1

        local modPanel, modHeader = self:_hudCard("Moderators", UDim2.new(1, -12, .5, 0), Vector2.new(1, .5), 240, 90)
        self.modPanel = modPanel
        self.modPanel.Visible = self.moderatorsEnabled
        local modTitle = self:_text(modHeader, "Moderators")
        modTitle.Position = UDim2.fromOffset(12, 0)
        modTitle.Size = UDim2.new(1, -24, 1, 0)
        
        self.modBody = create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ClipsDescendants = true, Position = UDim2.fromOffset(0, 36),
            Size = UDim2.new(1, 0, 1, -36), CanvasSize = UDim2.new(),
            ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, self.modPanel)
        self:_bind(self.modBody, "ScrollBarImageColor3", "accent")
        layout(self.modBody, 0)
        self.modListCount = 1

        local ok, stat = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        end)
        self.pingStat = ok and stat or nil

        self:_connect(Players.PlayerAdded, function()
            self.playerCount = self.playerCount + 1; self.hudStatsDirty = true
        end)
        self:_connect(Players.PlayerRemoving, function()
            self.playerCount = math.max(0, self.playerCount - 1); self.hudStatsDirty = true
        end)

        self:_makeDraggable(self.watermark, self.watermark)
        self:_makeDraggable(self.keybindPanel, header)
        self.targetDragEntry = self:_makeDraggable(self.targetHUD, tHeader)
        self:_makeDraggable(self.modPanel, modHeader)
        safe(function() self:SetModerators({}) end)
        self:_sampleHUD()
        self:_paintWatermark()
    end

    function UI:_sampleHUD()
        safe(function()
            local ok, ping = pcall(function()
                if self.pingStat then return self.pingStat:GetValue() end
                return player:GetNetworkPing() * 1000
            end)
            self.ping = ok and tonumber(ping) or nil
            if self.ping and (self.ping < 0 or self.ping ~= self.ping or self.ping == math.huge) then
                self.ping = nil
            end
            self.clock = os.date("%H:%M:%S")
            self.hudStatsDirty = true
        end)
    end

    function UI:_paintWatermark()
        self.hudStatsDirty = false
        safe(function()
            local text = string.format(
                "%s fps   |   %s ms   |   %d players   |   %s",
                self.fps > 0 and tostring(self.fps) or "--",
                self.ping and tostring(math.floor(self.ping + .5)) or "--",
                self.playerCount, self.clock
            )
            self:_changeText(self.watermarkStats, text, true)
            self:_layoutHUD()
        end)
    end

    function UI:_keybindRow(control)
        local row = {}
        row.root = self:_frame(self.keybindBody, {
            Name = "Binding", BackgroundTransparency = 1,
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 24),
        })
        row.dot = self:_frame(row.root, {
            BorderSizePixel = 0, Position = UDim2.fromOffset(12, 10),
            Size = UDim2.fromOffset(4, 4),
        }, "outline")
        pill(row.dot)
        row.name = self:_text(row.root, control.Name)
        row.name.Position = UDim2.fromOffset(24, 0)
        row.name.Size = UDim2.new(1, -126, 1, 0)
        row.name.TextTruncate = Enum.TextTruncate.AtEnd
        row.name.ZIndex = 2
        row.key = self:_text(row.root, "", 11, "muted")
        row.key.TextXAlignment = Enum.TextXAlignment.Right
        row.key.Position = UDim2.new(1, -102, 0, 0)
        row.key.Size = UDim2.fromOffset(90, 24)
        row.key.TextTruncate = Enum.TextTruncate.AtEnd
        row.key.ZIndex = 2
        row.paint = function()
            safe(function()
                local active = control:IsActive()
                self:_tween(row.dot, {BackgroundColor3 = active and self.accent or self.colors.outline}, .16)
                self:_tween(row.key, {TextColor3 = active and self.accent or self.colors.muted}, .16)
            end)
        end
        table.insert(self.repaint, row.paint)
        self.keybindRows[control] = row
        return row
    end

    function UI:_refreshKeybinds()
        self.keybindDirty = false
        safe(function()
            local count, known = 0, {}
            local function visibleInSection(control)
                if control.AlwaysInList then return true end
                local section = control._section
                local stop = section and section.tab and section.tab.body
                local node = control.Instance
                while node and node ~= stop do
                    if node:IsA("GuiObject") and not node.Visible then return false end
                    node = node.Parent
                end
                return true
            end
            for _, control in ipairs(self.keybinds) do
                if control and control.Instance then
                    known[control] = true
                    local visible = control.Instance.Parent ~= nil
                        and control.Instance.Visible
                        and control.ShowInList
                        and control:Get() ~= "None"
                        and visibleInSection(control)
                    local row = self.keybindRows[control]
                    if visible then
                        count = count + 1
                        row = row or self:_keybindRow(control)
                        if row then
                            row.root.Visible = true
                            row.root.LayoutOrder = count
                            self:_changeText(row.name, control.Name, true)
                            self:_changeText(row.key, "[" .. keyName(control:Get()) .. "]", true)
                            row.paint()
                        end
                    elseif row then
                        row.root.Visible = false
                    end
                end
            end
            for control, row in pairs(self.keybindRows) do
                if not known[control] then
                    pcall(function() row.root:Destroy() end)
                    self.keybindRows[control] = nil
                    local index = table.find(self.repaint, row.paint)
                    if index then table.remove(self.repaint, index) end
                end
            end
            self.keybindVisibleCount = count
            self.keybindEmpty.Visible = count == 0
            self:_changeText(self.keybindCount, tostring(count), true)
            self:_layoutHUD()
        end)
    end

    function UI:SetWatermarkVisible(value)
        if self.destroyed or not self.watermark then return end
        self.watermarkEnabled = value == true
        self.watermark.Visible = self.watermarkEnabled
    end

    function UI:SetKeybindListVisible(value)
        if self.destroyed or not self.keybindPanel then return end
        self.keybindListEnabled = value == true
        self.keybindPanel.Visible = self.keybindListEnabled
    end

    function UI:SetTargetHUDVisible(value)
        if self.destroyed or not self.targetHUD then return end
        self.targetHUDEnabled = value == true
        self.targetHUD.Visible = self.targetHUDEnabled
    end

    function UI:SetModeratorsVisible(value)
        if self.destroyed or not self.modPanel then return end
        self.moderatorsEnabled = value == true
        self.modPanel.Visible = self.moderatorsEnabled
    end

    function UI:SetWatermarkName(value)
        if self.destroyed or not self.watermarkTitle then return end
        self.hudName = tostring(value or "Skid hub")
        self:_changeText(self.watermarkTitle, self.hudName, true)
        self:_layoutHUD()
    end

    function UI:SetTarget(name, status, health, playerObj)
        if self.destroyed or not self.targetHUDEnabled then return end
        safe(function()
            if not name then
                if self._currentTargetName ~= nil then
                    self._currentTargetName = nil
                    self._currentStatus = nil
                    self._currentHealth = nil
                    self:_changeText(self.targetName, "Player: None", true)
                    self:_changeText(self.targetStatus, "Status: None", true)
                    self._targetStatusRole = "muted"
                    self.targetStatus.TextColor3 = self.colors.muted
                    self.targetHealthBar.Size = UDim2.new(0, 0, 1, 0)
                    self.targetAvatar.Visible = false
                end
                return
            end

            if not self.targetAvatar.Visible then
                self.targetAvatar.Visible = true
            end

            if self._currentTargetName ~= name then
                self._currentTargetName = name
                self:_changeText(self.targetName, "Player: " .. tostring(name), true)
                if playerObj then
                    local currentName = name
                    task.spawn(function()
                        local ok, image = pcall(Players.GetUserThumbnailAsync, Players, playerObj.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                        if ok and not self.destroyed and self._currentTargetName == currentName then
                            self.targetAvatar.Image = image
                        end
                    end)
                else
                    self.targetAvatar.Image = ""
                end
            end

            if self._currentStatus ~= status then
                self._currentStatus = status
                self:_changeText(self.targetStatus, "Status: " .. tostring(status), true)
                if status == "Visible" then
                    self._targetStatusRole = "accent"
                    self.targetStatus.TextColor3 = self.colors.accent
                elseif status == "Teammate" then
                    self._targetStatusRole = nil
                    self.targetStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
                else
                    self._targetStatusRole = "muted"
                    self.targetStatus.TextColor3 = self.colors.muted
                end
            end

            local clampedHealth = math.clamp(health or 0, 0, 1)
            if math.abs((self._currentHealth or -1) - clampedHealth) > 0.001 then
                self._currentHealth = clampedHealth
                self.targetHealthBar.Size = UDim2.new(clampedHealth, 0, 1, 0)
            end
        end)
    end

    function UI:SetModerators(list)
        if self.destroyed or not self.modBody then return end
        safe(function()
            list = list or {}
            local key = table.concat(list, "\0")
            if self._lastModeratorsKey == key then return end
            self._lastModeratorsKey = key

            for _, x in ipairs(self.modBody:GetChildren()) do
                if x:IsA("GuiObject") then pcall(function() x:Destroy() end) end
            end

            local mods = list
            if #mods == 0 then mods = {"None"} end
            self.modListCount = #mods

            for i, modName in ipairs(mods) do
                local row = self:_frame(self.modBody, {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    LayoutOrder = i,
                })
                local dot = self:_frame(row, {
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(12, 10),
                    Size = UDim2.fromOffset(4, 4)
                }, "outline")
                pill(dot)
                local text = self:_text(row, modName)
                text.Position = UDim2.fromOffset(24, 0)
                text.Size = UDim2.new(1, -34, 1, 0)
            end

            self:_layoutHUD()
        end)
    end

    function UI:_measureText(label)
        if not label then return 0 end
        local ok, s = pcall(function()
            return math.ceil(TextService:GetTextSize(
                label.Text, label.TextSize, label.Font, Vector2.new(100000, 100000)
            ).X)
        end)
        return ok and s or 0
    end

    function UI:_ownedConnect(root, signal, fn)
        if not signal then return nil end
        local connection = self:_connect(signal, fn)
        if connection and root then
            root.Destroying:Once(function()
                pcall(function() connection:Disconnect() end)
                local index = table.find(self.connections, connection)
                if index then table.remove(self.connections, index) end
            end)
        end
        return connection
    end

    function UI:_cancelPointers()
        for _, widget in pairs(self.widgets) do
            if widget and widget.CancelInput then safe(function() widget:CancelInput() end) end
        end
    end

    function UI:_clampDrag(frame, position)
        if not frame or not position then return position end
        local ok, result = pcall(function()
            local size = frame.AbsoluteSize / self.scale
            local a = frame.AnchorPoint
            local minX, minY = 8 + a.X * size.X, 8 + a.Y * size.Y
            local maxX = math.max(minX, self.viewport.X - 8 - (1 - a.X) * size.X)
            local maxY = math.max(minY, self.viewport.Y - 8 - (1 - a.Y) * size.Y)
            local x = math.clamp(position.X.Scale * self.viewport.X + position.X.Offset, minX, maxX)
            local y = math.clamp(position.Y.Scale * self.viewport.Y + position.Y.Offset, minY, maxY)
            return UDim2.new(
                position.X.Scale, x - position.X.Scale * self.viewport.X,
                position.Y.Scale, y - position.Y.Scale * self.viewport.Y
            )
        end)
        return ok and result or position
    end

    function UI:_makeDraggable(frame, handle, filter)
        if not frame or not handle then return {frame = frame, default = frame and frame.Position, userMoved = false} end
        local entry = {frame = frame, default = frame.Position, userMoved = false}
        self.dragItems[#self.dragItems + 1] = entry
        handle.Active = true
        self:_connect(frame:GetPropertyChangedSignal("AbsoluteSize"), function()
            if frame.Parent then entry.target = self:_clampDrag(frame, entry.target or frame.Position) end
        end)
        self:_connect(handle.InputBegan, function(input)
            if self.dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if Input:GetFocusedTextBox() or (filter and not filter(input)) then return end
            local active = self.tweens[frame]
            if active and active.Position then
                active.Position:Cancel(); active.Position = nil
            end
            entry.start = Vector2.new(input.Position.X, input.Position.Y)
            entry.origin = frame.Position
            entry.touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
            entry.target = nil
            entry.userMoved = true
            self.dragging = entry
            self:ClosePopup()
        end)
        return entry
    end

    function UI:_stepDraggables(dt)
        for _, entry in ipairs(self.dragItems) do
            local target = entry.target
            local frame = entry.frame
            if target and frame and frame.Parent and shown(frame) then
                frame.Position = target
                entry.target = nil
            end
        end
    end

    function UI:_fitDraggables()
        for _, entry in ipairs(self.dragItems or {}) do
            local frame = entry.frame
            if frame and frame.Parent then
                local current = entry.target or frame.Position
                local clamped = self:_clampDrag(frame, current)
                if clamped and (clamped.X.Offset ~= current.X.Offset or clamped.Y.Offset ~= current.Y.Offset
                    or clamped.X.Scale ~= current.X.Scale or clamped.Y.Scale ~= current.Y.Scale) then
                    entry.target = clamped
                end
            end
        end
    end

    function UI:_layoutHUD()
        if not self.watermark then return end
        safe(function()
            local brand, stats = self:_measureText(self.watermarkTitle), self:_measureText(self.watermarkStats)
            local width = math.min(brand + stats + 48, math.max(48, self.viewport.X - 24))
            local available = math.max(0, width - 48)
            if brand + stats > available then
                brand = math.min(brand, available * .3)
                stats = available - brand
            end
            self.watermark.Size = UDim2.fromOffset(width, 32)
            self.watermarkTitle.Size = UDim2.fromOffset(brand, 32)
            self.watermarkDivider.Position = UDim2.fromOffset(24 + brand, 9)
            self.watermarkStats.Position = UDim2.fromOffset(36 + brand, 0)
            self.watermarkStats.Size = UDim2.fromOffset(stats, 32)

            local keybindListHeight = math.clamp((self.keybindVisibleCount or 0) * 24, 24, 200)
            local keybindHeight = keybindListHeight + 40
            self.keybindPanel.Size = UDim2.fromOffset(240, keybindHeight)
            self.keybindBody.Size = UDim2.new(1, 0, 0, keybindListHeight)

            local moderatorCount = math.max(1, self.modListCount or 1)
            local moderatorListHeight = math.clamp(moderatorCount * 24, 24, 200)
            local modHeight = moderatorListHeight + 40
            self.modPanel.Size = UDim2.fromOffset(240, modHeight)
            self.modBody.Size = UDim2.new(1, 0, 0, moderatorListHeight)

            if not self._hudInitPos then
                self._hudInitPos = true
                self.keybindPanel.AnchorPoint = Vector2.new(0, 0.5)
                self.keybindPanel.Position = UDim2.new(0, 12, 0.5, 0)

                self.modPanel.AnchorPoint = Vector2.new(1, 0.5)
                self.modPanel.Position = UDim2.new(1, -12, 0.5, 0)

                self.targetHUD.AnchorPoint = Vector2.new(1, 0.5)
                if not (self.targetDragEntry and self.targetDragEntry.userMoved) then
                    self.targetHUD.Position = UDim2.new(
                        1, -12, 0.5,
                        modHeight / 2 + (self.targetHUDHeight or 92) / 2 + 12
                    )
                    self._lastModHeight = modHeight
                end
            end

            if not (self.targetDragEntry and self.targetDragEntry.userMoved) then
                if self._lastModHeight ~= modHeight then
                    self._lastModHeight = modHeight
                    self.targetHUD.Position = UDim2.new(
                        1, -12, 0.5,
                        modHeight / 2 + (self.targetHUDHeight or 92) / 2 + 12
                    )
                end
            end

            self:_fitDraggables()
        end)
    end

    function Section:_resizeNow()
        if self.ui.destroyed or not self.holder or not self.holder.Parent then return end
        safe(function()
            local content, count = 0, 0
            for _, child in ipairs(self.items:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then
                    local height = child.Size.Y.Offset
                    if child.Size.Y.Scale ~= 0
                        or child.AutomaticSize == Enum.AutomaticSize.Y
                        or child.AutomaticSize == Enum.AutomaticSize.XY then
                        local scale = 1
                        local parent = child
                        while parent and parent ~= self.ui.gui do
                            local modifier = parent:FindFirstChildOfClass("UIScale")
                            if modifier then scale = scale * modifier.Scale end
                            parent = parent.Parent
                        end
                        height = child.AbsoluteSize.Y / math.max(.001, scale)
                    end
                    content = content + math.max(0, height)
                    count = count + 1
                end
            end
            content = content + math.max(0, count - 1) * 8
            local height = math.min(math.max(60, tonumber(self.maxHeight) or math.huge), 60 + content)
            if self.items.Size.Y.Offset ~= content then
                self.items.Size = UDim2.new(1, -24, 0, content)
            end
            if self.holder.Size.Y.Offset ~= height then
                self.holder.Size = UDim2.new(1, -1, 0, height)
            end
            if self.scroll then
                self.scroll.CanvasSize = UDim2.fromOffset(0, content + 16)
            end
        end)
    end

    function Section:Resize()
        if self.resizeQueued then return end
        self.resizeQueued = true
        task.defer(function()
            self.resizeQueued = false
            self:_resizeNow()
        end)
    end

    function Section:_watchRows()
        if not self.items then return end
        local owned = {}
        local function forget(child)
            local connections = owned[child]
            if connections then
                for _, connection in ipairs(connections) do
                    pcall(function() connection:Disconnect() end)
                    local index = table.find(self.ui.connections, connection)
                    if index then table.remove(self.ui.connections, index) end
                end
                owned[child] = nil
            end
            self:Resize()
        end
        local function watch(child)
            if not child:IsA("GuiObject") or owned[child] then return end
            owned[child] = {}
            for _, property in ipairs({"Size", "Visible", "AutomaticSize", "AbsoluteSize"}) do
                local c = self.ui:_connect(
                    child:GetPropertyChangedSignal(property),
                    function() self:Resize() end
                )
                if c then table.insert(owned[child], c) end
            end
            self:Resize()
        end
        for _, child in ipairs(self.items:GetChildren()) do watch(child) end
        self.ui:_connect(self.items.ChildAdded, watch)
        self.ui:_connect(self.items.ChildRemoved, forget)
        self:Resize()
    end

    function UI.new(options)
        options = options or {}
        assert(player, "SkidUi must run on the roblox client")

        local self = setmetatable({
            colors        = table.clone(defaults),
            connections   = {}, bindings = {}, repaint = {},
            widgets       = {}, features = {}, pages = {},
            Tabs          = {}, Options = {}, Toggles = {},
            Labels        = {}, Buttons = {}, namedControls = {},
            configs       = {}, unloadCallbacks = {},
            keybinds      = {}, dragItems = {}, popups = {},
            colorUpdates  = {},
            tweens        = setmetatable({}, {__mode = "k"}),
            easing        = Enum.EasingStyle.Quart,
            visible       = true,
            configFolder  = options.ConfigFolder or "SkidUi",
            toggleKey     = keyOf(options.ToggleKey or "RightShift"),
            size          = options.Size or Vector2.new(720, 558),
        }, UI)

        self.colors.accent = options.Accent or self.colors.accent
        self.accent = self.colors.accent

        self.gui = create("ScreenGui", {
            Name = "SkidHub_" .. HttpService:GenerateGUID(false),
            IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        local ok = pcall(function()
            self.gui.Parent = type(gethui) == "function" and gethui() or game:GetService("CoreGui")
        end)
        if not ok or not self.gui.Parent then
            self.gui.Parent = player:WaitForChild("PlayerGui")
        end

        self.root = self:_frame(self.gui, {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
        self.rootScale = create("UIScale", {Scale = 1}, self.root)

        local function fit()
            safe(function()
                local camera = workspace.CurrentCamera
                local v = camera and camera.ViewportSize or Vector2.new(1280, 720)
                self.scale = math.min(1,
                    math.max(.2, (v.X - 24) / self.size.X),
                    math.max(.2, (v.Y - 24) / self.size.Y))
                self.rootScale.Scale = self.scale
                self.root.Size = UDim2.fromOffset(v.X / self.scale, v.Y / self.scale)
                self.viewport = v / self.scale
                self:_fitDraggables()
                if self.watermark then self:_layoutHUD() end
            end)
        end
        fit()

        local cameraConnection
        local function bindCamera()
            if cameraConnection then
                pcall(function() cameraConnection:Disconnect() end)
                local index = table.find(self.connections, cameraConnection)
                if index then table.remove(self.connections, index) end
            end
            if workspace.CurrentCamera then
                cameraConnection = self:_connect(
                    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
                    function() fit(); self:ClosePopup() end
                )
            end
            fit()
        end
        bindCamera()
        self:_connect(workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)

        self.window = create("CanvasGroup", {
            BackgroundColor3 = self.colors.background, BorderSizePixel = 0,
            Size = UDim2.fromOffset(self.size.X, self.size.Y),
            AnchorPoint = Vector2.new(.5, .5),
            Position = UDim2.fromScale(.5, .5), GroupTransparency = 1,
        }, self.root)
        self:_bind(self.window, "BackgroundColor3", "background")
        round(self.window, 8)
        self.windowOutline = self:_stroke(self.window, "outline", .15)
        self.windowScale = create("UIScale", {Scale = 1}, self.window)

        local sidebar = self:_frame(self.window, {
            BorderSizePixel = 0, Size = UDim2.new(0, 80, 1, 0),
        }, "sidebar")
        self:_frame(sidebar, {
            BorderSizePixel = 0, Position = UDim2.new(1, -1, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
        }, "outline")
        self.sideItems = self:_frame(sidebar, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, .5),
            Position = UDim2.new(0, 15, .5, 0),
            Size = UDim2.fromOffset(50, 224),
        })
        layout(self.sideItems, 8)

        local main = self:_frame(self.window, {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 0),
            Size = UDim2.new(1, -80, 1, 0),
        })
        self.toolbar = self:_frame(main, {
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 52), Active = true,
        }, "raised")
        self.tabButtons = create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.fromOffset(4, 3),
            Size = UDim2.new(1, -214, 0, 46),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            ScrollingDirection = Enum.ScrollingDirection.X,
            ScrollBarThickness = 0, ClipsDescendants = true,
        }, self.toolbar)
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        }, self.tabButtons)
        layout(self.tabButtons, 12, true)

        self.searchBox = self:_input(self.toolbar, "Search for a feature", "")
        self.searchBox.AnchorPoint = Vector2.new(1, 0)
        self.searchBox.Position = UDim2.new(1, -12, 0, 11)
        self.searchBox.Size = UDim2.fromOffset(200, 30)
        self:_bind(self.searchBox, "BackgroundColor3", "background")
        self.searchBox:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 31)
        local si = self:_icon(self.searchBox, "search", 14)
        si.Position = UDim2.new(0, 15, .5, 0)

        self.contents = self:_frame(main, {
            BackgroundTransparency = 1, ClipsDescendants = true,
            Position = UDim2.fromOffset(0, 52),
            Size = UDim2.new(1, 0, 1, -52),
        })
        self.popupLayer = self:_frame(self.root, {
            Name = "PopupLayer", BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1), ZIndex = 100, ClipsDescendants = false,
        })
        self.notifications = self:_frame(self.root, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 10, 1, -10),
            Size = UDim2.new(0, 245, 1, -20), ZIndex = 200,
        })
        local nl = layout(self.notifications, 8)
        nl.VerticalAlignment = Enum.VerticalAlignment.Bottom

        self.searchPanel = self:_makePopup(420, 180)
        self.searchList = create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(), ScrollBarThickness = 2,
        }, self.searchPanel)
        self:_bind(self.searchList, "ScrollBarImageColor3", "accent")
        pad(self.searchList, 10, 10, 7, 7)
        layout(self.searchList, 2)
        self:_connect(self.searchBox:GetPropertyChangedSignal("Text"), function()
            self:_search(self.searchBox.Text)
        end)

        self:_createHUD(options)

        self:_makeDraggable(self.window, self.toolbar, function(input)
            local p = Vector2.new(input.Position.X, input.Position.Y)
            local function inside(object)
                if not object or not object.Visible then return false end
                local q, s = object.AbsolutePosition, object.AbsoluteSize
                return p.X >= q.X and p.X <= q.X + s.X and p.Y >= q.Y and p.Y <= q.Y + s.Y
            end
            if inside(self.watermark) or inside(self.keybindPanel) or inside(self.targetHUD) or inside(self.modPanel) or inside(self.searchBox) then return false end
            for _, page in ipairs(self.pages) do
                for _, tab in ipairs(page.tabs) do
                    if tab.slot.Visible and inside(tab.button) then return false end
                end
            end
            return true
        end)

        self:_connect(Input.InputChanged, function(input)
            local entry = self.dragging
            if not entry then return end
            if (entry.touch and input == entry.touch)
                or (not entry.touch and input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = (Vector2.new(input.Position.X, input.Position.Y) - entry.start) / self.scale
                entry.target = self:_clampDrag(entry.frame,
                    UDim2.new(
                        entry.origin.X.Scale, entry.origin.X.Offset + delta.X,
                        entry.origin.Y.Scale, entry.origin.Y.Offset + delta.Y))
            end
        end)

        self:_connect(Input.InputEnded, function(input)
            local entry = self.dragging
            if entry and ((entry.touch and input == entry.touch)
                or (not entry.touch and input.UserInputType == Enum.UserInputType.MouseButton1)) then
                self.dragging = nil
            end
            local key = inputKey(input)
            if key then
                for _, control in ipairs(self.keybinds) do
                    if control:Get() == key then control:Release() end
                end
            end
        end)

        self:_connect(Input.WindowFocusReleased, function()
            self.dragging = nil
            self:_cancelPointers()
            if self.listening then
                safe(function() self.listening:CancelCapture() end)
                self.listening = nil
            end
            for _, control in ipairs(self.keybinds) do safe(function() control:Release() end) end
        end)

        self:_connect(Input.InputBegan, function(input, processed)
            safe(function()
                if self.listening then
                    local control = self.listening
                    local key = inputKey(input)
                    if key then
                        local b = control.Button
                        local p, s = b.AbsolutePosition, b.AbsoluteSize
                        local over = input.UserInputType == Enum.UserInputType.MouseButton1
                            and shown(b)
                            and input.Position.X >= p.X and input.Position.X <= p.X + s.X
                            and input.Position.Y >= p.Y and input.Position.Y <= p.Y + s.Y
                        self.listening = nil
                        if over then
                            control.SkipNextActivation = true
                            control:CancelCapture()
                        else
                            control:Set(key)
                        end
                    end
                    return
                end

                local handled = false
                if (input.UserInputType == Enum.UserInputType.Keyboard or not processed)
                    and not Input:GetFocusedTextBox() then
                    local key = inputKey(input)
                    if key then
                        for _, control in ipairs(self.keybinds) do
                            if control:Get() == key then
                                handled = true
                                control:Press()
                            end
                        end
                    end
                end

                if not handled
                    and (input.UserInputType == Enum.UserInputType.Keyboard or not processed)
                    and not Input:GetFocusedTextBox()
                    and self.toggleKey
                    and (input.KeyCode == self.toggleKey or input.UserInputType == self.toggleKey) then
                    self:Toggle()
                end

                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    local p = Vector2.new(input.Position.X, input.Position.Y)
                    local keep = 0
                    for i, entry in ipairs(self.popups) do
                        for _, x in ipairs({entry.panel, entry.anchor}) do
                            local q, s = x.AbsolutePosition, x.AbsoluteSize
                            if p.X >= q.X and p.X <= q.X + s.X and p.Y >= q.Y and p.Y <= q.Y + s.Y then
                                keep = i
                            end
                        end
                    end
                    self:_closeAfter(keep)
                end
            end)
        end)

        self:_connect(RunService.RenderStepped, function(dt)
            safe(function()
                if dt > 0 then
                    self.frameCount = self.frameCount + 1
                    self.frameElapsed = self.frameElapsed + dt
                    if self.frameElapsed >= .5 then
                        self.fps = math.floor(self.frameCount / self.frameElapsed + .5)
                        self.frameCount = 0; self.frameElapsed = 0
                        self.hudStatsDirty = true
                    end
                end
                self:_stepDraggables(dt)
            end)
        end)

        self:_connect(RunService.Heartbeat, function(dt)
            safe(function()
                for _, update in ipairs(self.colorUpdates) do safe(update, dt) end
                self.statsElapsed = self.statsElapsed + dt
                if self.statsElapsed >= 1 then
                    self.statsElapsed = self.statsElapsed % 1
                    self:_sampleHUD()
                end
                if self.keybindDirty then self:_refreshKeybinds() end
                if self.hudStatsDirty then self:_paintWatermark() end
            end)
        end)

        self:_tween(self.window, {GroupTransparency = 0}, .34)
        self:_tween(self.windowOutline, {Transparency = .15}, .34)
        return self
    end

    function UI:SetEasingStyle(name)
        if self.destroyed then return false end
        local ok, v = pcall(function() return Enum.EasingStyle[name] end)
        if not ok or not v then return false, "Unknown easing style: " .. tostring(name) end
        local changed = self.easing ~= v
        self.easing = v
        if changed and self._easingInitialized and self.notifications and self.notifications.Parent then
            safe(function() self:Notify("Easing Style", "Set to " .. tostring(name)) end)
        end
        self._easingInitialized = true
        return true
    end

    function UI:SetThemeColor(role, color)
        if not self.colors[role] or typeof(color) ~= "Color3" then return end
        safe(function()
            self.colors[role] = color
            if role == "accent" then self.accent = color end
            for i = #self.bindings, 1, -1 do
                local b = self.bindings[i]
                if not b.x or not b.x.Parent then
                    table.remove(self.bindings, i)
                elseif b.role == role then
                    self:_tween(b.x, {[b.property] = b.transform and b.transform(color) or color}, .24)
                end
            end
            for _, f in ipairs(self.repaint) do safe(f) end

            if self._targetStatusRole == role and self.targetStatus then
                self.targetStatus.TextColor3 = color
            end
        end)
    end

    function UI:SetAccent(color) self:SetThemeColor("accent", color) end

    function UI:SetVisible(visible)
        if self.destroyed then return end
        safe(function()
            if self.dragging and self.dragging.frame == self.window then self.dragging = nil end
            for _, entry in ipairs(self.dragItems) do
                if entry.frame == self.window then entry.target = nil end
            end
            if self.listening then
                safe(function() self.listening:CancelCapture() end)
                self.listening = nil
            end
            if not visible then
                self:_cancelPointers()
                if self.tooltipPanel then self.tooltipPanel.Visible = false end
            end
            self.visible = not not visible
            self.keybindDirty = true
            self.visibilityToken = (self.visibilityToken or 0) + 1
            local token = self.visibilityToken
            self:ClosePopup()

            if self.visible then
                self.window.Visible = true
                self:_tween(self.window, {GroupTransparency = 0}, .34)
                self:_tween(self.windowOutline, {Transparency = .15}, .34)
            else
                self:_tween(self.window, {GroupTransparency = 1}, .23)
                self:_tween(self.windowOutline, {Transparency = 1}, .23)
                task.delay(.24, function()
                    if not self.destroyed and token == self.visibilityToken then
                        self.window.Visible = false
                    end
                end)
            end
        end)
    end

    function UI:Toggle() self:SetVisible(not self.visible) end

    function UI:ResetPositions()
        if self.destroyed then return end
        safe(function()
            self.dragging = nil
            self:ClosePopup()

            self.window.Position = UDim2.fromScale(.5, .5)
            if self.watermark then
                self.watermark.Position = UDim2.new(.5, 0, 0, 12)
            end

            for _, entry in ipairs(self.dragItems) do
                entry.userMoved = false
                entry.target = nil
            end
            if self.targetDragEntry then
                self.targetDragEntry.userMoved = false
            end

            self._hudInitPos = false
            self._lastModHeight = nil
            self:_layoutHUD()

            if self.notifications and self.notifications.Parent then
                self:Notify("Reset Positions", "All panels returned to default")
            end
        end)
    end

    function UI:_makePopup(width, height)
        local x = create("CanvasGroup", {
            BackgroundColor3 = self.colors.raised, BorderSizePixel = 0,
            Visible = false, GroupTransparency = 1,
            Size = UDim2.fromOffset(width, height), ClipsDescendants = true,
        }, self.popupLayer)
        self:_bind(x, "BackgroundColor3", "raised")
        round(x, 5); self:_stroke(x, "outline", .25)
        return x
    end

    function UI:_closeAfter(index)
        safe(function()
            for i = #self.popups, index + 1, -1 do
                local entry = table.remove(self.popups, i)
                if entry and entry.panel then
                    entry.token = entry.token + 1
                    local token = entry.token
                    entry.panel:SetAttribute("OpenGeneration", token)
                    self:_tween(entry.panel, {
                        GroupTransparency = 1,
                        Size = UDim2.fromOffset(entry.width, math.max(0, entry.height - 8)),
                    }, .16)
                    local stroke = entry.panel:FindFirstChildOfClass("UIStroke")
                    if stroke then self:_tween(stroke, {Transparency = 1}, .16) end
                    invoke(entry.onClose)
                    task.delay(.17, function()
                        if not self.destroyed
                            and entry.panel and entry.panel.Parent
                            and entry.panel:GetAttribute("OpenGeneration") == token
                            and not entry.open then
                            entry.panel.Visible = false
                        end
                    end)
                    entry.open = false
                end
            end
        end)
    end

    function UI:ClosePopup()
        self:_cancelPointers()
        self:_closeAfter(0)
    end

    function UI:_openPopup(anchor, panel, width, height, owner, onClose)
        if not self.visible or not anchor or not panel then return false end
        return safe(function()
            for i, e in ipairs(self.popups) do
                if e.panel == panel then
                    self:_closeAfter(i - 1)
                    return false
                end
            end
            local keep = 0
            if owner then
                for i, e in ipairs(self.popups) do
                    if e.panel == owner then keep = i end
                end
            end
            self:_closeAfter(keep)
            local layerPosition = self.popupLayer.AbsolutePosition
            local q = (anchor.AbsolutePosition - layerPosition) / self.scale
            local s = anchor.AbsoluteSize / self.scale
            width = math.min(width, math.max(1, self.viewport.X - 12))
            local x = q.X
            if width > s.X then x = q.X + s.X - width end
            x = math.clamp(x, 6, math.max(6, self.viewport.X - width - 6))
            local y = q.Y + s.Y + 6
            local availableBelow = math.max(0, self.viewport.Y - y - 6)
            height = math.min(height, availableBelow)
            if height < 1 then return false end

            panel.ZIndex = 10 + #self.popups * 10
            panel.Position = UDim2.fromOffset(x, y)
            local entry = panel:GetAttribute("OpenGeneration") or 0
            panel:SetAttribute("OpenGeneration", entry + 1)
            panel.Visible = true
            panel.GroupTransparency = 1
            panel.Size = UDim2.fromOffset(width, math.max(0, height - 8))
            table.insert(self.popups, {
                panel = panel, anchor = anchor, width = width, height = height,
                open = true, token = entry + 1, onClose = onClose,
            })
            self:_tween(panel, {GroupTransparency = 0, Size = UDim2.fromOffset(width, height)}, .24)
            local stroke = panel:FindFirstChildOfClass("UIStroke")
            if stroke then self:_tween(stroke, {Transparency = .25}, .24) end
            return true
        end)
    end

    function UI:_register(section, kind, title, obj, options)
        options = options or {}
        if not obj or not obj.Instance then return obj end
        safe(function()
            local base = options.Flag or (section.path .. "/" .. kind .. "/" .. tostring(title or kind))
            local flag = base
            local i = 2
            if not options.Flag then
                while self.widgets[flag] do
                    flag = base .. "#" .. i
                    i = i + 1
                end
            end
            if self.widgets[flag] then return end

            function obj:SetVisible(value) self.Instance.Visible = value == true end
            function obj:Destroy() self.Instance:Destroy() end
            obj.Instance.Destroying:Once(function()
                if self.widgets[flag] == obj then self.widgets[flag] = nil end
                for i = #self.features, 1, -1 do
                    if self.features[i].obj == obj then table.remove(self.features, i) end
                end
                for i = #self.bindings, 1, -1 do
                    local x = self.bindings[i].x
                    if x == obj.Instance or (x and x:IsDescendantOf(obj.Instance)) then
                        table.remove(self.bindings, i)
                    end
                end
            end)
            obj.Kind = kind
            obj.Flag = flag
            obj._section = section
            obj.Save = options.Save ~= false and kind ~= "Button" and kind ~= "Label"
            self.widgets[flag] = obj
            if title and title ~= "" then
                table.insert(self.features, {name = title, section = section, obj = obj})
            end
        end)
        return obj
    end

    function UI:_search(query)
        if not self.searchList then return end
        safe(function()
            for _, x in ipairs(self.searchList:GetChildren()) do
                if x:IsA("TextButton") then pcall(function() x:Destroy() end) end
            end
            query = tostring(query or ""):lower():gsub("^%s+", "")
            if query == "" then
                if self.popups[1] and self.popups[1].panel == self.searchPanel then
                    self:ClosePopup()
                end
                return
            end
            local count = 0
            for _, feature in ipairs(self.features) do
                if feature.name:lower():find(query, 1, true) then
                    count = count + 1
                    if count > 10 then break end
                    local target = feature
                    local b = self:_button(self.searchList,
                        target.section.path:gsub("/", " > ") .. " > " .. target.name)
                    b.Size = UDim2.new(1, -2, 0, 24)
                    b.TextSize = 12
                    b.TextXAlignment = Enum.TextXAlignment.Left
                    b.TextTruncate = Enum.TextTruncate.AtEnd
                    b.BackgroundTransparency = 1
                    b.Activated:Connect(function()
                        safe(function()
                            self.searchBox.Text = ""
                            self.searchBox:ReleaseFocus()
                            self:ClosePopup()
                            self:Select(target.section.tab.page, target.section.tab)
                            task.defer(function()
                                if self.destroyed then return end
                                if target.section.reveal then target.section.reveal() end
                                local scroll = target.section.scroll or target.section.column
                                local row = target.obj.Instance
                                if scroll and row and row.Parent then
                                    local y = (row.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / self.scale
                                        + scroll.CanvasPosition.Y
                                    self:_tween(scroll, {CanvasPosition = Vector2.new(0, math.max(0, y - 14))}, .4)
                                end
                                if row then
                                    local outline = self:_stroke(row, "accent", .2)
                                    self:_tween(outline, {Transparency = 1}, 1)
                                    task.delay(1.1, function()
                                        if outline.Parent then pcall(function() outline:Destroy() end) end
                                    end)
                                end
                            end)
                        end)
                    end)
                end
            end
            if count == 0 then
                self:ClosePopup()
                return
            end
            local h = math.min(count, 10) * 26 + 14
            if self.popups[1] and self.popups[1].panel == self.searchPanel then
                local e = self.popups[1]
                e.height = h
                self:_tween(self.searchPanel, {Size = UDim2.fromOffset(420, h)}, .2)
            else
                self:_openPopup(self.searchBox, self.searchPanel, 420, h)
            end
        end)
    end

    function UI:Page(title, icon)
        title = tostring(title or "Page")
        if type(icon) == "table" then icon = icon.Icon or icon.Image or icon.Asset end
        local page = {ui = self, title = title, Name = title, tabs = {}, Tabs = {}}
        self.Tabs[title] = page
        local slot = self:_frame(self.sideItems, {
            BackgroundTransparency = 1, Size = UDim2.fromOffset(50, 50),
            LayoutOrder = #self.pages + 1,
        })
        page.glow = self:_glow(slot, 25)
        local b = create("TextButton", {
            BackgroundColor3 = self.accent, BackgroundTransparency = 1,
            AutoButtonColor = false, Text = "", BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1), ZIndex = 3,
        }, slot)
        round(b, 25)
        local root, tint = self:_icon(b, icon or "more", 26)
        page.button = b
        page.tint = tint
        local scale = root:FindFirstChildOfClass("UIScale")
        self:_connect(b.MouseEnter, function() self:_tween(scale, {Scale = 1.08}, .2, Enum.EasingStyle.Sine) end)
        self:_connect(b.MouseLeave, function() self:_tween(scale, {Scale = 1}, .24, Enum.EasingStyle.Sine) end)
        self:_connect(b.Activated, function()
            local target = page.lastTab or page.tabs[1]
            if target then self:Select(page, target) end
        end)
        table.insert(self.pages, page)
        self.sideItems.Size = UDim2.fromOffset(50, #self.pages * 58 - 8)
        table.insert(self.repaint, function()
            safe(function()
                local selected = self.selectedPage == page
                self:_tween(b, {
                    BackgroundColor3 = self.accent,
                    BackgroundTransparency = selected and 0 or 1,
                }, .28)
                tint(selected and self.colors.ink or self.colors.muted:Lerp(self.colors.text, .35))
                page.glow(selected)
            end)
        end)

        function page:Tab(name)
            name = tostring(name or "Tab")
            local ui = self.ui
            local tab = {page = self, title = name, Name = name, sections = {}, Groupboxes = {}}
            local width = math.clamp(
                TextService:GetTextSize(tostring(name), 13, Enum.Font.GothamBlack, Vector2.new(10000, 10000)).X + 26,
                64, 220
            )
            tab.slot = ui:_frame(ui.tabButtons, {
                BackgroundTransparency = 1, Size = UDim2.fromOffset(width, 30),
                LayoutOrder = #self.tabs + 1, Visible = false,
            })
            tab.glow = ui:_glow(tab.slot, 4)
            tab.button = ui:_button(tab.slot, name)
            tab.button.TextTruncate = Enum.TextTruncate.AtEnd
            tab.button.Size = UDim2.fromScale(1, 1)
            tab.button.ZIndex = 3
            tab.button.BackgroundColor3 = ui.colors.panel
            tab.body = create("CanvasGroup", {
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                Visible = false, GroupTransparency = 1,
            }, ui.contents)

            tab.columns = {}
            tab.columnLayouts = {}

            function tab:ResizeContent() end

            for i = 1, 2 do
                local col = create("ScrollingFrame", {
                    Name = "Column" .. i, BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new((i - 1) * .5, i == 1 and 12 or 6, 0, 12),
                    Size = UDim2.new(.5, -18, 1, -24),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    ScrollBarThickness = 0,
                    ScrollBarImageTransparency = 1,
                    VerticalScrollBarInset = Enum.ScrollBarInset.None,
                    HorizontalScrollBarInset = Enum.ScrollBarInset.None,
                }, tab.body)
                ui:_bind(col, "ScrollBarImageColor3", "accent")
                pad(col, 0, 1, 0, 2)
                local columnLayout = layout(col, 12)
                tab.columns[i] = col
                tab.columnLayouts[i] = columnLayout
            end

            ui:_connect(tab.button.Activated, function() ui:Select(self, tab) end)
            table.insert(ui.repaint, function()
                safe(function()
                    local selected = ui.selectedTab == tab
                    ui:_tween(tab.button, {
                        BackgroundColor3 = selected and ui.accent or ui.colors.panel,
                        TextColor3 = selected and ui.colors.ink or ui.colors.muted,
                    }, .26)
                    tab.glow(selected)
                end)
            end)
            table.insert(self.tabs, tab)
            self.Tabs[name] = tab
            self[name] = tab

            function tab:Section(sectionTitle, column, options)
                options = options or {}
                column = math.clamp(column or 1, 1, 2)
                local holder = ui:_frame(self.columns[column], {
                    BorderSizePixel = 0, Size = UDim2.new(1, -1, 0, 60),
                    LayoutOrder = #self.sections + 1,
                }, "panel")
                round(holder, 5)
                ui:_stroke(holder, "outline", .6)
                local head = ui:_frame(holder, {
                    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40),
                }, "raised")
                round(head, 5)
                ui:_frame(head, {
                    BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -4),
                    Size = UDim2.new(1, 0, 0, 4),
                }, "raised")
                local ih = ui:_frame(head, {
                    BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 13),
                    Size = UDim2.fromOffset(13, 14),
                })
                ui:_icon(ih, options.Icon or ({Configs = "folder", Menu = "sliders", Theming = "palette"})[sectionTitle] or "person", 14, "text")
                local heading = ui:_text(head, sectionTitle)
                heading.Position = UDim2.fromOffset(36, 0)
                heading.Size = UDim2.new(1, -44, 1, 0)
                local items = ui:_frame(holder, {
                    BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 48),
                    Size = UDim2.new(1, -24, 0, 0),
                })
                layout(items, 8)
                local section = setmetatable({
                    ui = ui, tab = self, title = sectionTitle,
                    path = self.page.title .. "/" .. self.title .. "/" .. sectionTitle,
                    holder = holder, items = items, column = self.columns[column],
                    scroll = nil, maxHeight = nil,
                }, Section)
                section:_watchRows()
                table.insert(self.sections, section)
                self.Groupboxes[sectionTitle] = section
                return section
            end

            function tab:AddLeftGroupbox(sectionTitle, options) return self:Section(sectionTitle, 1, options) end
            function tab:AddRightGroupbox(sectionTitle, options) return self:Section(sectionTitle, 2, options) end
            tab.AddLeftGroupBox = tab.AddLeftGroupbox
            tab.AddRightGroupBox = tab.AddRightGroupbox
            tab.AddGroupbox = tab.AddLeftGroupbox
            tab.AddGroupBox = tab.AddLeftGroupbox
            function tab:AddLeftTabbox(title, options) return ui:_createTabbox(self, 1, title, options) end
            function tab:AddRightTabbox(title, options) return ui:_createTabbox(self, 2, title, options) end
            tab.AddLeftTabBox = tab.AddLeftTabbox
            tab.AddRightTabBox = tab.AddRightTabbox

            if not ui.selectedTab then ui:Select(self, tab) end
            return tab
        end

        page.AddTab = page.Tab
        return page
    end

    function UI:CreateWindow(options) return UI.new(options) end

    function UI:Select(page, tab)
        if self.destroyed or not page or not tab or tab.page ~= page then return end
        safe(function()
            local old = self.selectedTab
            if old == tab then return end
            self:ClosePopup()
            self.selectedPage = page
            self.selectedTab = tab
            page.lastTab = tab
            self.keybindDirty = true
            self.selectToken = (self.selectToken or 0) + 1
            local pageChanged = old and old.page ~= page
            local direction = 1
            if old then
                local items = pageChanged and self.pages or page.tabs
                local from = table.find(items, pageChanged and old.page or old) or 1
                local to = table.find(items, pageChanged and page or tab) or 1
                direction = to >= from and 1 or -1
            end
            local dx, dy = pageChanged and 0 or 18 * direction, pageChanged and 14 * direction or 0
            for _, p in ipairs(self.pages) do
                for _, t in ipairs(p.tabs) do
                    t.slot.Visible = p == page
                    t.button:SetAttribute("Selected", t == tab)
                    t.transitionToken = (t.transitionToken or 0) + 1
                    local active = self.tweens[t.body]
                    if active then
                        for _, property in ipairs({"GroupTransparency", "Position"}) do
                            local tween = active[property]
                            if tween then
                                active[property] = nil
                                pcall(function() tween:Cancel() end)
                            end
                        end
                    end
                    if t ~= tab and t ~= old then
                        t.body.Visible = false
                        t.body.GroupTransparency = 1
                        t.body.Position = UDim2.fromOffset(0, 0)
                    end
                end
            end
            for _, f in ipairs(self.repaint) do safe(f) end
            if old and old.body.Visible then
                local generation = old.transitionToken
                old.body.ZIndex = 1
                self:_tween(old.body, {
                    GroupTransparency = 1,
                    Position = UDim2.fromOffset(-dx, -dy),
                }, .24, Enum.EasingStyle.Sine)
                for _, section in ipairs(old.sections) do
                    local stroke = section.holder:FindFirstChildOfClass("UIStroke")
                    if stroke then self:_tween(stroke, {Transparency = 1}, .24) end
                end
                task.delay(.26, function()
                    if not self.destroyed
                        and old.transitionToken == generation
                        and self.selectedTab ~= old
                        and old.body.Parent then
                        old.body.Visible = false
                        old.body.Position = UDim2.fromOffset(0, 0)
                    end
                end)
            end
            if not tab.body.Visible then
                tab.body.Position = UDim2.fromOffset(dx, dy)
                tab.body.GroupTransparency = old and 1 or 0
            end
            tab.body.ZIndex = 2
            tab.body.Visible = true
            for _, section in ipairs(tab.sections) do
                local stroke = section.holder:FindFirstChildOfClass("UIStroke")
                if stroke then self:_tween(stroke, {Transparency = .6}, .34) end
            end
            self:_tween(tab.body, {
                GroupTransparency = 0,
                Position = UDim2.fromOffset(0, 0),
            }, .34, Enum.EasingStyle.Quart)
        end)
    end

    function Section:_row(height, parent)
        self.counter = (self.counter or 0) + 1
        return self.ui:_frame(parent or self.items, {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 24),
            LayoutOrder = self.counter,
        })
    end

    function Section:Label(options)
        options = type(options) == "table" and options or {Text = tostring(options)}
        local row = self:_row(20)
        local text = self.ui:_text(row, options.Text)
        text.Size = UDim2.new(1, 0, 1, 0)
        text.TextWrapped = options.DoesWrap == true or options.Wrap == true
        if options.Color then text.TextColor3 = options.Color end

        local attachments = self.ui:_frame(row, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        })
        local attLayout = create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
        }, attachments)
        attLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            safe(function() text.Size = UDim2.new(1, -attachments.AbsoluteSize.X, 1, 0) end)
        end)

        local obj = {Instance = row, _ui = self.ui, Attachments = attachments}
        function obj:Set(v) self._ui:_changeText(text, v) end
        function obj:Get() return text.Text end
        return self.ui:_register(self, "Label", options.Text, obj, options)
    end

    function Section:Button(options)
        options = type(options) == "table" and options or {Text = tostring(options)}
        options.Callback = options.Callback or options.Func
        local row = self:_row(30)
        local b = self.ui:_button(row, options.Text or "Button")
        b.Size = UDim2.fromScale(1, 1)
        local obj = {Instance = row, Button = b}
        function obj:Press() if row and row.Parent then invoke(options.Callback) end end
        self.ui:_ownedConnect(row, b.Activated, function() safe(function() obj:Press() end) end)
        return self.ui:_register(self, "Button", options.Text, obj, options)
    end

    local function paired(section, method, height, a, b)
        local row = section:_row(height)
        local left, right = method(section, a), method(section, b)
        for i, obj in ipairs({left, right}) do
            if obj and obj.Instance then
                obj.Instance.Parent = row
                obj.Instance.Position = UDim2.new((i - 1) * .5, i == 1 and 0 or 6, 0, 0)
                obj.Instance.Size = UDim2.new(.5, -6, 1, 0)
            end
        end
        return left, right
    end

    function Section:ButtonPair(a, b) return paired(self, self.Button, 30, a, b) end

    function Section:Toggle(options)
        options = options or {}
        local ui = self.ui
        local row = self:_row(22)
        local track = ui:_button(row, "")
        track.Size = UDim2.fromOffset(32, 18)
        track.Position = UDim2.fromOffset(0, 2)
        pill(track); ui:_gradient(track)
        local thumb = ui:_frame(track, {
            BorderSizePixel = 0, Position = UDim2.fromOffset(3, 3),
            Size = UDim2.fromOffset(12, 12), ZIndex = 4,
        }, "muted")
        pill(thumb)
        local caption = ui:_text(row, options.Text or "Toggle")
        caption.Position = UDim2.fromOffset(42, 0)
        caption.Size = UDim2.new(1, -42, 1, 0)

        local attachments = ui:_frame(row, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        })
        local attLayout = create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        }, attachments)
        attLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            safe(function() caption.Size = UDim2.new(1, -42 - attachments.AbsoluteSize.X, 1, 0) end)
        end)

        local state, initialized = false, false
        local obj = {Instance = row, Button = track, Caption = caption, Attachments = attachments}
        local function paint(instant)
            safe(function()
                local p = {
                    Position = UDim2.fromOffset(state and 17 or 3, 3),
                    BackgroundColor3 = state and ui.colors.background or ui.colors.muted,
                }
                if instant then
                    for k, v in pairs(p) do thumb[k] = v end
                    track.BackgroundColor3 = state and ui.accent or ui.colors.raised
                else
                    ui:_tween(thumb, p, .28)
                    ui:_tween(track, {BackgroundColor3 = state and ui.accent or ui.colors.raised}, .25)
                end
            end)
        end
        function obj:Set(value, silent)
            local nextState = value == true
            local changed = state ~= nextState
            state = nextState
            ui.keybindDirty = true
            track:SetAttribute("Selected", state)
            paint(silent)
            if not silent and (changed or not initialized or options.AlwaysCallback) then
                initialized = true
                invoke(options.Callback, state)
            end
            return state
        end
        function obj:Get() return state end
        function obj:Toggle() return self:Set(not state) end
        ui:_ownedConnect(row, track.Activated, function() safe(function() obj:Toggle() end) end)
        ui:_ownedConnect(row, caption.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                safe(function() obj:Toggle() end)
            end
        end)
        local repaint = function() paint(false) end
        table.insert(ui.repaint, repaint)
        row.Destroying:Once(function()
            if state then safe(function() obj:Set(false) end) end
            local index = table.find(ui.repaint, repaint)
            if index then table.remove(ui.repaint, index) end
        end)
        safe(function() obj:Set(options.Default == true, true) end)
        ui:_register(self, "Toggle", options.Text, obj, options)
        if options.FireOnInit ~= false then
            task.defer(function()
                if not ui.destroyed and row.Parent and not initialized then
                    initialized = true
                    invoke(options.Callback, state)
                end
            end)
        else
            initialized = true
        end
        return obj
    end

    local function slider(section, options, isRange)
        options = options or {}
        local ui = section.ui
        local minimum, maximum = options.Min or 0, options.Max or 100
        if maximum <= minimum then return end
        local step = math.max(tonumber(options.Step) or 1, 1e-6)
        local compact = options.Compact == true
        local row = section:_row(compact and 40 or 48)
        local title = ui:_text(row, options.Text or "Slider")
        title.Size = UDim2.new(.65, 0, 0, 18)
        title.Visible = not compact
        local number = ui:_text(row, "")
        number.TextXAlignment = Enum.TextXAlignment.Right
        number.Position = UDim2.new(compact and 0 or .5, 0, 0, 0)
        number.Size = UDim2.new(compact and 1 or .5, 0, 0, 18)
        local bar = create("TextButton", {
            Text = "", AutoButtonColor = false, BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, compact and 18 or 26),
            Name = "SliderTrack", Size = UDim2.new(1, 0, 0, 18),
        }, row)
        ui:_bind(bar, "BackgroundColor3", "raised")
        pill(bar)
        local fill = ui:_frame(bar, {BorderSizePixel = 0, Size = UDim2.fromScale(0, 1)}, "accent")
        pill(fill); ui:_gradient(fill)
        local function handle()
            local x = ui:_frame(bar, {
                Name = "SliderHandle", BackgroundTransparency = 0,
                BorderSizePixel = 0, AnchorPoint = Vector2.new(.5, .5),
                Size = UDim2.fromOffset(12, 12), ZIndex = 3, Active = false,
            }, "background")
            pill(x)
            return x
        end
        local right, left = handle(), isRange and handle() or nil
        local lo, hi = minimum, minimum
        local obj = {Instance = row}
        local function quantize(v)
            return tonumber(string.format("%.6f",
                math.clamp(minimum + math.floor((clamp(v, minimum, maximum) - minimum) / step + .5) * step, minimum, maximum)
            ))
        end
        local function fmt(v)
            if type(options.FormatDisplayValue) == "function" then
                local ok, formatted = pcall(options.FormatDisplayValue, obj, v)
                if ok and formatted ~= nil then return tostring(formatted) end
            end
            return tostring(v) .. (options.Suffix or "")
        end
        function obj:Set(a, b, silent)
            safe(function()
                if not isRange then
                    silent = b
                    hi = quantize(a); lo = minimum
                else
                    if type(a) == "table" then
                        silent = type(b) == "boolean" and b or silent
                        b = a[2]; a = a[1]
                    end
                    lo, hi = quantize(a), quantize(b)
                    if lo > hi then lo, hi = hi, lo end
                end
                local f1, f2 = (lo - minimum) / (maximum - minimum), (hi - minimum) / (maximum - minimum)
                local function set(x, p)
                    if not x then return end
                    if silent then
                        for k, v in pairs(p) do x[k] = v end
                    else
                        ui:_tween(x, p, .115, Enum.EasingStyle.Sine)
                    end
                end
                set(fill, {
                    Position = isRange and UDim2.new(f1, -18 * f1, 0, 0) or UDim2.fromOffset(0, 0),
                    Size = isRange
                        and UDim2.new(f2 - f1, 18 - 18 * (f2 - f1), 1, 0)
                        or UDim2.new(f2, 18 - 18 * f2, 1, 0),
                })
                set(right, {Position = UDim2.new(f2, 9 - 18 * f2, .5, 0)})
                if left then set(left, {Position = UDim2.new(f1, 9 - 18 * f1, .5, 0)}) end
                ui:_changeText(number, isRange and (fmt(lo) .. " - " .. fmt(hi)) or fmt(hi), silent)
                if not silent then
                    if isRange then invoke(options.Callback, lo, hi) else invoke(options.Callback, hi) end
                end
            end)
        end
        function obj:Get() return isRange and {lo, hi} or hi end
        local active, touch
        function obj:CancelInput() active, touch = nil, nil end
        local function valueAt(input)
            local width = bar.AbsoluteSize.X
            local inset = math.min(bar.AbsoluteSize.Y / 2, width / 2)
            local fraction = math.clamp(
                (input.Position.X - bar.AbsolutePosition.X - inset) / math.max(1, width - 2 * inset),
                0, 1
            )
            return minimum + fraction * (maximum - minimum)
        end
        local function update(input)
            local n = valueAt(input)
            if active == "overlap" then
                if math.abs(n - lo) < 1e-6 then return end
                active = n < lo and "left" or "right"
            end
            if not isRange then obj:Set(n)
            elseif active == "left" then obj:Set(math.min(n, hi), hi)
            else obj:Set(lo, math.max(n, lo)) end
        end
        ui:_ownedConnect(row, bar.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local n = valueAt(input)
            active = isRange
                and (lo == hi and "overlap" or (math.abs(n - lo) <= math.abs(n - hi) and "left" or "right"))
                or "right"
            touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
            safe(function() update(input) end)
        end)
        ui:_ownedConnect(row, Input.InputChanged, function(input)
            if active and ui.visible and shown(bar)
                and ((touch and input == touch)
                    or (not touch and input.UserInputType == Enum.UserInputType.MouseMovement)) then
                safe(function() update(input) end)
            end
        end)
        ui:_ownedConnect(row, Input.InputEnded, function(input)
            if input == touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                active = nil
            end
        end)
        safe(function()
            if isRange then
                obj:Set(options.Default or {minimum, maximum}, nil, true)
            else
                obj:Set(options.Default or minimum, true)
            end
        end)
        return ui:_register(section, isRange and "Range" or "Slider", options.Text, obj, options)
    end

    function Section:Slider(options) return slider(self, options, false) end
    function Section:RangeSlider(options) return slider(self, options, true) end
    function Section:SliderPair(a, b) return paired(self, self.Slider, 48, a, b) end

    function Section:Input(options)
        options = options or {}
        local ui = self.ui
        local row = self:_row(52)
        local t = ui:_text(row, options.Text or "Input")
        t.Size = UDim2.new(1, 0, 0, 18)
        local field = ui:_input(row, options.Placeholder or "Type here...", options.Default or "")
        field.ClearTextOnFocus = options.ClearTextOnFocus == true
        field.Position = UDim2.fromOffset(0, 22)
        field:FindFirstChildOfClass("UIPadding").PaddingRight = UDim.new(0, 30)
        local icon = ui:_icon(field, "settings", 13)
        icon.Position = UDim2.new(1, -17, .5, 0)
        local obj = {Instance = row}
        local previous = field.Text
        function obj:Set(value, silent)
            safe(function()
                if options.Numeric then
                    local n = tonumber(value)
                    if not n then return end
                    value = n
                end
                field.Text = tostring(value or "")
                previous = field.Text
                if not silent then invoke(options.Callback, field.Text) end
            end)
        end
        function obj:Get() return field.Text end
        ui:_ownedConnect(row, field:GetPropertyChangedSignal("Text"), function()
            safe(function()
                if options.MaxLength and #field.Text > options.MaxLength then
                    field.Text = field.Text:sub(1, options.MaxLength)
                end
            end)
        end)
        ui:_ownedConnect(row, field.FocusLost, function(enter)
            safe(function()
                if options.Numeric and not tonumber(field.Text) then
                    field.Text = previous
                    return
                end
                previous = field.Text
                invoke(options.Callback, field.Text, enter)
            end)
        end)
        return ui:_register(self, "Input", options.Text, obj, options)
    end

    function Section:Keybind(options)
        options = options or {}
        local ui = self.ui
        local row = self:_row(24)
        local t = ui:_text(row, options.Text or "Keypicker")
        t.Size = UDim2.new(.54, 0, 1, 0)
        local b = create("TextButton", {
            Name = "KeyButton", BackgroundTransparency = 1, BorderSizePixel = 0,
            AutoButtonColor = false, Text = "", Font = Enum.Font.GothamBlack,
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(.54, 0, 0, 0),
            Size = UDim2.new(.46, 0, 1, 0), ZIndex = 3,
        }, row)
        ui:_bind(b, "TextColor3", "muted")
        local key = "None"

        local obj = {
            Instance = row, Button = b,
            Name = options.Name or options.Text or "Keybind",
            Mode = ({always = "Always", hold = "Hold", toggle = "Toggle"})[tostring(options.Mode or "Toggle"):lower()] or "Toggle",
            ShowInList = options.ShowInList ~= false,
            Active = false, Held = false,
        }

        local function draw(silent)
            safe(function()
                local display = key == "None" and "None" or ("[" .. keyName(key) .. "]")
                ui:_changeText(b, display, silent)
                ui:_tween(b, {TextColor3 = ui.colors.muted}, .18)
            end)
        end

        function obj:Set(value, silent)
            local parsed = keyOf(value)
            if value ~= "None" and not parsed then return false end
            self:Reset()
            key = parsed and parsed.Name or "None"
            self.Active = false
            self.Held = false
            ui.keybindDirty = true
            if ui.listening == self then ui.listening = nil end
            draw(silent)
            if not silent then invoke(options.Changed, key) end
            return true
        end

        function obj:Get() return key end
        function obj:IsActive()
            if self.Mode == "Always" then return true end
            if self.LinkedToggle then return self.LinkedToggle:Get() == true end
            return self.Active
        end
        function obj:SetActive(value)
            self.Active = value == true
            ui.keybindDirty = true
        end
        function obj:Clear() return self:Set("None") end

        function obj:Press()
            if key == "None" or self.Held then return end
            self.Held = true
            if self.Mode == "Toggle" and self.LinkedToggle then
                self.Active = self.LinkedToggle:Get()
            end
            self.Active = self.Mode == "Toggle" and not self.Active or (self.Mode ~= "Toggle")
            ui.keybindDirty = true
            invoke(options.Callback, key, self.Active)
        end

        function obj:Release()
            if not self.Held then return end
            self.Held = false
            if self.Mode ~= "Toggle" then self.Active = false end
            ui.keybindDirty = true
            if self.Mode == "Hold" then invoke(options.Callback, key, false) end
            invoke(options.Released, key)
        end

        function obj:Reset()
            self:Release()
            if self.Active then
                self.Active = false
                ui.keybindDirty = true
                if self.Mode == "Toggle" then invoke(options.Callback, key, false) end
            end
        end

        function obj:CancelCapture() draw(false) end

        function obj:Capture()
            if ui.listening == self then
                ui.listening = nil
                draw(false)
                return
            end
            if ui.listening then safe(function() ui.listening:CancelCapture() end) end
            local focused = Input:GetFocusedTextBox()
            if focused then focused:ReleaseFocus() end
            ui.listening = self
            ui:_changeText(b, "[...]")
            ui:_tween(b, {TextColor3 = ui.accent}, .18)
        end

        local modePopup = ui:_makePopup(140, 140)
        create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, modePopup)
        pad(modePopup, 8, 8, 8, 8)
        local modeOptions = {
            {name = "Always", apply = function() obj:Reset(); obj.Mode = "Always"; ui.keybindDirty = true; ui:Notify("Mode: Always") end},
            {name = "Toggle", apply = function() obj:Reset(); obj.Mode = "Toggle"; ui.keybindDirty = true; ui:Notify("Mode: Toggle") end},
            {name = "Hold", apply = function() obj:Reset(); obj.Mode = "Hold"; ui.keybindDirty = true; ui:Notify("Mode: Hold") end},
            {name = "Unbind key", apply = function() obj:Set("None") end},
        }
        for i, entry in ipairs(modeOptions) do
            local btn = ui:_button(modePopup, entry.name)
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.LayoutOrder = i
            btn.Activated:Connect(function()
                safe(function()
                    entry.apply()
                    ui:ClosePopup()
                end)
            end)
        end

        local owned = {}
        local function connect(signal, fn)
            local c = ui:_ownedConnect(row, signal, fn)
            if c then table.insert(owned, c) end
        end

        connect(b.Activated, function()
            if obj.SkipNextActivation then
                obj.SkipNextActivation = false
            else
                safe(function() obj:Capture() end)
            end
        end)
        connect(b.MouseEnter, function() ui:_tween(b, {TextColor3 = ui.accent}, .16) end)
        connect(b.MouseLeave, function()
            if ui.listening ~= obj then ui:_tween(b, {TextColor3 = ui.colors.muted}, .2) end
        end)
        connect(b.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                ui:_openPopup(b, modePopup, 140, 140, self.popupOwner)
            end
        end)

        row.Destroying:Once(function()
            safe(function()
                obj:Reset()
                if ui.listening == obj then ui.listening = nil end
                local index = table.find(ui.keybinds, obj)
                if index then table.remove(ui.keybinds, index) end
                for _, connection in ipairs(owned) do
                    pcall(function() connection:Disconnect() end)
                    index = table.find(ui.connections, connection)
                    if index then table.remove(ui.connections, index) end
                end
                ui.keybindDirty = true
                if modePopup then pcall(function() modePopup:Destroy() end) end
            end)
        end)

        safe(function() obj:Set(options.Default or "None", true) end)
        table.insert(ui.keybinds, obj)
        ui.keybindDirty = true
        return ui:_register(self, "Keybind", options.Text, obj, options)
    end

    function Section:Dropdown(options)
        options = options or {}
        local ui = self.ui
        local row = self:_row(50)
        local t = ui:_text(row, options.Text or "Dropdown")
        t.Size = UDim2.new(1, 0, 0, 18)
        local b = ui:_button(row, "")
        b.Position = UDim2.fromOffset(0, 21)
        b.Size = UDim2.new(1, 0, 0, 29)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        pad(b, 12, 29)
        local arrow = ui:_icon(b, "chevron", 13)
        arrow.Position = UDim2.new(1, -17, .5, 0)
        local choices = clone(options.Options or options.Values)
        local multi = options.Multi == true
        local value = multi and {} or nil
        local popup = ui:_makePopup(276, 180)
        local entries = create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.fromOffset(6, options.Searchable and 38 or 5),
            Size = UDim2.new(1, -12, 1, options.Searchable and -43 or -10),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(), ScrollBarThickness = 2,
        }, popup)
        ui:_bind(entries, "ScrollBarImageColor3", "accent")
        layout(entries, 2)
        local search
        if options.Searchable then
            search = ui:_input(popup, "Search...", "")
            search.Position = UDim2.fromOffset(6, 6)
            search.Size = UDim2.new(1, -12, 0, 27)
        end
        local obj = {Instance = row}
        local populate
        local function draw(silent)
            safe(function()
                local text
                if multi then
                    local texts = {}
                    for _, v in ipairs(value) do
                        local display = type(options.FormatDisplayValue) == "function" and options.FormatDisplayValue(v) or nil
                        table.insert(texts, tostring(display or v))
                    end
                    text = #texts > 0 and table.concat(texts, ", ") or (options.Placeholder or "Select...")
                else
                    local display = value ~= nil and type(options.FormatDisplayValue) == "function"
                        and options.FormatDisplayValue(value) or nil
                    text = value ~= nil and tostring(display or value) or (options.Placeholder or "Select...")
                end
                ui:_changeText(b, text, silent)
            end)
        end
        function obj:Set(v, silent)
            safe(function()
                if multi then
                    value = {}
                    for _, item in ipairs(type(v) == "table" and v or {}) do
                        if table.find(choices, item) and not table.find(value, item) then
                            table.insert(value, item)
                        end
                    end
                else
                    if table.find(choices, v) then value = v else value = nil end
                end
                draw(silent)
                if popup.Visible then
                    for _, choice in ipairs(entries:GetChildren()) do
                        if choice:IsA("TextButton") then
                            local item = choices[choice:GetAttribute("ChoiceIndex")]
                            local on = multi and table.find(value, item) or (not multi and value == item)
                            choice:SetAttribute("Selected", not not on)
                            ui:_tween(choice, {TextColor3 = on and ui.accent or ui.colors.muted}, .2)
                        end
                    end
                end
                if not silent then invoke(options.Callback, obj:Get()) end
            end)
        end
        function obj:Get() return multi and clone(value) or value end
        function obj:SetOptions(values, keep)
            safe(function()
                local old = obj:Get()
                choices = clone(values or {})
                if keep then obj:Set(old, true)
                else obj:Set(multi and {} or choices[1], true) end
                if popup.Visible then populate() end
            end)
        end
        populate = function()
            safe(function()
                for _, x in ipairs(entries:GetChildren()) do
                    if x:IsA("TextButton") then pcall(function() x:Destroy() end) end
                end
                local query = search and search.Text:lower() or ""
                for index, item in ipairs(choices) do
                    if tostring(item):lower():find(query, 1, true) then
                        local entry = item
                        local choice = create("TextButton", {
                            BackgroundTransparency = 1, Text = tostring(entry),
                            Font = Enum.Font.GothamBlack, TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Size = UDim2.new(1, -3, 0, 24),
                            LayoutOrder = index, AutoButtonColor = false,
                        }, entries)
                        pad(choice, 7, 7)
                        choice:SetAttribute("ChoiceIndex", index)
                        local selected = multi and table.find(value, entry) or (not multi and value == entry)
                        choice:SetAttribute("Selected", not not selected)
                        local disabledChoice = type(options.DisabledValues) == "table"
                            and table.find(options.DisabledValues, entry) ~= nil
                        choice:SetAttribute("DisabledChoice", disabledChoice)
                        choice.TextColor3 = disabledChoice and ui.colors.outline
                            or (choice:GetAttribute("Selected") and ui.accent or ui.colors.muted)
                        choice.TextTransparency = .6
                        choice.Active = not disabledChoice
                        ui:_tween(choice, {TextTransparency = 0}, .2)
                        choice.MouseEnter:Connect(function()
                            safe(function()
                                ui:_tween(choice, {
                                    TextColor3 = choice:GetAttribute("Selected") and ui.accent or ui.colors.text,
                                }, .15)
                            end)
                        end)
                        choice.MouseLeave:Connect(function()
                            safe(function()
                                ui:_tween(choice, {
                                    TextColor3 = choice:GetAttribute("Selected") and ui.accent or ui.colors.muted,
                                }, .2)
                            end)
                        end)
                        choice.Activated:Connect(function()
                            safe(function()
                                if choice:GetAttribute("DisabledChoice") then return end
                                if multi then
                                    local nextValue = clone(value)
                                    local i = table.find(nextValue, entry)
                                    if i then table.remove(nextValue, i) else table.insert(nextValue, entry) end
                                    obj:Set(nextValue)
                                else
                                    obj:Set(entry)
                                    for i, e in ipairs(ui.popups) do
                                        if e.panel == popup then
                                            ui:_closeAfter(i - 1)
                                            break
                                        end
                                    end
                                end
                            end)
                        end)
                    end
                end
            end)
        end
        if search then
            ui:_ownedConnect(row, search:GetPropertyChangedSignal("Text"), function() safe(populate) end)
        end
        ui:_ownedConnect(row, b.Activated, function()
            safe(function()
                populate()
                local maxVisible = math.max(1, tonumber(options.MaxVisibleDropdownItems) or 6)
                local h = math.max(34, math.min(#choices, maxVisible) * 26 + (search and 43 or 10))
                if ui:_openPopup(
                    b, popup, math.max(145, b.AbsoluteSize.X / ui.scale), h, self.popupOwner,
                    function() ui:_tween(arrow, {Rotation = 0}, .2) end
                ) then
                    ui:_tween(arrow, {Rotation = 180}, .24)
                end
            end)
        end)
        local initial = options.Default
        if initial == nil then initial = multi and {} or choices[1] end
        safe(function() obj:Set(initial, true) end)
        return ui:_register(self, "Dropdown", options.Text, obj, options)
    end

    function Section:List(options)
        options = options or {}
        local ui = self.ui
        local row = self:_row(options.Height or 200)
        local heading = ui:_text(row, options.Text or "List")
        heading.Size = UDim2.new(1, 0, 0, 18)
        local search
        local top = 23
        if options.Searchable ~= false then
            search = ui:_input(row, "Search...", "")
            search.Position = UDim2.fromOffset(0, 22)
            search.Size = UDim2.new(1, 0, 0, 28)
            search:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 30)
            local icon = ui:_icon(search, "search", 13)
            icon.Position = UDim2.new(0, 15, .5, 0)
            top = 55
        end
        local scroll = create("ScrollingFrame", {
            BackgroundColor3 = ui.colors.raised, BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, top),
            Size = UDim2.new(1, 0, 1, -top),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(), ScrollBarThickness = 2,
        }, row)
        ui:_bind(scroll, "BackgroundColor3", "raised")
        ui:_bind(scroll, "ScrollBarImageColor3", "accent")
        round(scroll, 3)
        pad(scroll, 5, 5, 5, 5)
        layout(scroll, 0)
        local choices = clone(options.Options)
        local value = options.Default
        if value == nil then value = choices[1] end
        local obj = {Instance = row}
        function obj:Get() return value end
        function obj:Set(v, silent)
            safe(function()
                if table.find(choices, v) then value = v else value = nil end
                for _, b in ipairs(scroll:GetChildren()) do
                    if b:IsA("TextButton") then
                        local selected = choices[b:GetAttribute("ChoiceIndex")] == value
                        b:SetAttribute("Selected", selected)
                        local props = {TextColor3 = selected and ui.accent or ui.colors.muted}
                        if silent then b.TextColor3 = props.TextColor3
                        else ui:_tween(b, props, .22) end
                    end
                end
                if not silent then invoke(options.Callback, value) end
            end)
        end
        function obj:SetOptions(values)
            safe(function()
                choices = clone(values or {})
                if not table.find(choices, value) then value = choices[1] end
                obj:Refresh()
            end)
        end
        function obj:Refresh()
            safe(function()
                for _, x in ipairs(scroll:GetChildren()) do
                    if x:IsA("TextButton") then pcall(function() x:Destroy() end) end
                end
                for i, item in ipairs(choices) do
                    if tostring(item):lower():find(search and search.Text:lower() or "", 1, true) then
                        local v = item
                        local b = create("TextButton", {
                            BackgroundTransparency = 1, Text = tostring(v),
                            Font = Enum.Font.GothamBlack, TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextColor3 = v == value and ui.accent or ui.colors.muted,
                            Size = UDim2.new(1, -3, 0, 24), LayoutOrder = i,
                        }, scroll)
                        pad(b, 8, 4)
                        b:SetAttribute("Selected", v == value)
                        b:SetAttribute("ChoiceIndex", i)
                        b.TextTransparency = .5
                        ui:_tween(b, {TextTransparency = 0}, .2)
                        b.Activated:Connect(function() safe(function() obj:Set(v) end) end)
                        b.MouseEnter:Connect(function()
                            safe(function()
                                ui:_tween(b, {
                                    TextColor3 = b:GetAttribute("Selected") and ui.accent or ui.colors.text,
                                }, .15)
                            end)
                        end)
                        b.MouseLeave:Connect(function()
                            safe(function()
                                ui:_tween(b, {
                                    TextColor3 = b:GetAttribute("Selected") and ui.accent or ui.colors.muted,
                                }, .2)
                            end)
                        end)
                    end
                end
            end)
        end
        if search then
            ui:_ownedConnect(row, search:GetPropertyChangedSignal("Text"), function() safe(function() obj:Refresh() end) end)
        end
        local repaint = function()
            safe(function()
                for _, b in ipairs(scroll:GetChildren()) do
                    if b:IsA("TextButton") then
                        ui:_tween(b, {
                            TextColor3 = b:GetAttribute("Selected") and ui.accent or ui.colors.muted,
                        }, .22)
                    end
                end
            end)
        end
        table.insert(ui.repaint, repaint)
        row.Destroying:Once(function()
            local index = table.find(ui.repaint, repaint)
            if index then table.remove(ui.repaint, index) end
        end)
        safe(function() obj:Refresh() end)
        return ui:_register(self, "List", options.Text, obj, options)
    end

    function Section:Colorpicker(options)
        options = options or {}
        local ui = self.ui
        local row = self:_row(24)
        local heading = ui:_text(row, options.Text or "Colorpicker")
        heading.Size = UDim2.new(1, -35, 1, 0)
        local swatch = create("TextButton", {
            BorderSizePixel = 0, AutoButtonColor = false, Text = "",
            Position = UDim2.new(1, -18, 0, 4),
            Size = UDim2.fromOffset(16, 16),
        }, row)
        pill(swatch); ui:_gradient(swatch)
        local outline = ui:_stroke(swatch, "text", 1)
        ui:_ownedConnect(row, swatch.MouseEnter, function() ui:_tween(outline, {Transparency = .5}, .2) end)
        ui:_ownedConnect(row, swatch.MouseLeave, function() ui:_tween(outline, {Transparency = 1}, .25) end)

        local base = options.Default or Color3.fromRGB(170, 72, 25)
        local h, s, v = base:ToHSV()
        local alpha = clamp(options.Alpha == nil and 1 or options.Alpha, 0, 1)
        local rainbow, fading = false, false
        local obj = {Instance = row, Swatch = swatch}
        local refresh
        local modeButtons = {}
        local cachedMode = "Static"

        local function computeMode()
            if rainbow then return fading and "Rainbow,Fading" or "Rainbow" end
            return fading and "Fading" or "Static"
        end
        local function paintModes()
            safe(function()
                for name, button in pairs(modeButtons) do
                    local active = (name == "Rainbow" and rainbow) or (name == "Fading" and fading)
                    button:SetAttribute("Selected", active == true)
                    ui:_tween(button, {TextColor3 = active and ui.colors.ink or ui.colors.muted}, .18)
                end
            end)
        end

        local popup = ui:_makePopup(240, 302)
        local function current()
            local hh = rainbow and (os.clock() * .1) % 1 or h
            local vv = fading and v * (.6 + .4 * (math.sin(os.clock() * 2) + 1) / 2) or v
            return Color3.fromHSV(hh, s, vv)
        end

        function obj:Get()
            return {
                r = math.round(base.R * 255), g = math.round(base.G * 255),
                b = math.round(base.B * 255), a = alpha,
                rainbow = rainbow, fading = fading, mode = cachedMode,
            }
        end

        local function changed(silent)
            safe(function()
                base = Color3.fromHSV(h, s, v)
                cachedMode = computeMode()
                local col = current()
                local trans = 1 - alpha
                if silent then
                    swatch.BackgroundColor3 = col
                    swatch.BackgroundTransparency = trans
                else
                    ui:_tween(swatch, {BackgroundColor3 = col, BackgroundTransparency = trans}, .12, Enum.EasingStyle.Sine)
                end
                if refresh and popup.Visible then refresh() end
                paintModes()
                if not silent then invoke(options.Callback, col, alpha, cachedMode) end
            end)
        end

        function obj:Set(value, silent)
            safe(function()
                if typeof(value) == "Color3" then
                    h, s, v = value:ToHSV()
                elseif type(value) == "table" then
                    h, s, v = Color3.fromRGB(
                        clamp(value.r or value[1], 0, 255),
                        clamp(value.g or value[2], 0, 255),
                        clamp(value.b or value[3], 0, 255)
                    ):ToHSV()
                    if value.a ~= nil then alpha = clamp(value.a, 0, 1) end
                    rainbow = value.rainbow == true
                        or (type(value.mode) == "string" and value.mode:find("Rainbow", 1, true) ~= nil)
                    fading = value.fading == true
                        or (type(value.mode) == "string" and value.mode:find("Fading", 1, true) ~= nil)
                else
                    return
                end
                changed(silent)
            end)
        end

        local square = ui:_frame(popup, {
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.fromOffset(190, 168), Active = true,
        })
        round(square, 3)
        local sat = create("UIGradient", {
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1)),
        }, square)
        local dark = ui:_frame(square, {
            BackgroundColor3 = Color3.new(), BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
        })
        round(dark, 3)
        create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, dark)
        local marker = ui:_frame(square, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5, .5),
            Size = UDim2.fromOffset(6, 6), ZIndex = 4,
        })
        round(marker, 3); ui:_stroke(marker, "ink", 0)

        local hue = ui:_frame(popup, {
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
            Position = UDim2.fromOffset(211, 10),
            Size = UDim2.fromOffset(18, 168), Active = true,
        })
        round(hue, 3)
        local hueColors = {}
        for i = 0, 6 do
            table.insert(hueColors, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
        end
        create("UIGradient", {Rotation = 90, Color = ColorSequence.new(hueColors)}, hue)
        local hueMarker = ui:_frame(hue, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, .5),
            Size = UDim2.new(1, 0, 0, 3), ZIndex = 4,
        })
        ui:_stroke(hueMarker, "ink", .2)

        local alphaBar = ui:_frame(popup, {
            BorderSizePixel = 0, Position = UDim2.fromOffset(10, 190),
            Size = UDim2.fromOffset(219, 15), Active = true,
        })
        round(alphaBar, 3)
        create("UIGradient", {
            Color = ColorSequence.new(Color3.new(.03, .03, .03), Color3.new(1, 1, 1)),
        }, alphaBar)
        local am = ui:_frame(alphaBar, {
            BackgroundTransparency = 1, Size = UDim2.new(0, 3, 1, 0),
            AnchorPoint = Vector2.new(.5, 0), ZIndex = 3,
        })
        ui:_stroke(am, "ink", .1)

        local rgb = ui:_input(popup, "R, G, B, A", "")
        rgb.Position = UDim2.fromOffset(10, 216)
        rgb.Size = UDim2.fromOffset(219, 28)

        local modeButton = ui:_button(popup, "Static")
        modeButton.Position = UDim2.fromOffset(10, 256)
        modeButton.Size = UDim2.fromOffset(219, 28)
        modeButton.TextXAlignment = Enum.TextXAlignment.Left
        pad(modeButton, 10, 28)
        local arrow = ui:_icon(modeButton, "chevron", 12)
        arrow.Position = UDim2.new(1, -14, .5, 0)

        local modes = ui:_makePopup(219, 58)
        for i, name in ipairs({"Rainbow", "Fading"}) do
            local nameCopy = name
            local b = ui:_button(modes, name)
            modeButtons[nameCopy] = b
            b.Position = UDim2.fromOffset(5, 4 + (i - 1) * 26)
            b.Size = UDim2.new(1, -10, 0, 24)
            b.TextXAlignment = Enum.TextXAlignment.Left
            pad(b, 7, 7)
            ui:_ownedConnect(row, b.Activated, function()
                safe(function()
                    if nameCopy == "Rainbow" then rainbow = not rainbow
                    else fading = not fading end
                    cachedMode = computeMode()
                    paintModes()
                    changed(false)
                    refresh()
                end)
            end)
        end

        refresh = function()
            safe(function()
                sat.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
                ui:_tween(marker, {Position = UDim2.fromScale(s, 1 - v)}, .09, Enum.EasingStyle.Sine)
                ui:_tween(hueMarker, {Position = UDim2.fromScale(0, h)}, .09, Enum.EasingStyle.Sine)
                ui:_tween(am, {Position = UDim2.fromScale(alpha, 0)}, .09, Enum.EasingStyle.Sine)
                ui:_tween(alphaBar, {BackgroundColor3 = current()}, .12, Enum.EasingStyle.Sine)
                if not rgb:IsFocused() then
                    local c = obj:Get()
                    rgb.Text = string.format("%d, %d, %d, %.2f", c.r, c.g, c.b, alpha)
                end
                modeButton.Text = cachedMode:gsub(",", ", ")
            end)
        end

        local active, touch
        function obj:CancelInput() active, touch = nil, nil end
        local function pick(input)
            safe(function()
                if active == "square" then
                    s = math.clamp((input.Position.X - square.AbsolutePosition.X) / square.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((input.Position.Y - square.AbsolutePosition.Y) / square.AbsoluteSize.Y, 0, 1)
                elseif active == "hue" then
                    h = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
                elseif active == "alpha" then
                    alpha = math.clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                end
                changed(false)
            end)
        end
        for _, entry in ipairs({{square, "square"}, {hue, "hue"}, {alphaBar, "alpha"}}) do
            ui:_ownedConnect(row, entry[1].InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    active = entry[2]
                    touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
                    pick(input)
                end
            end)
        end
        ui:_ownedConnect(row, Input.InputChanged, function(input)
            if active and ui.visible and shown(popup)
                and ((touch and input == touch)
                    or (not touch and input.UserInputType == Enum.UserInputType.MouseMovement)) then
                pick(input)
            end
        end)
        ui:_ownedConnect(row, Input.InputEnded, function(input)
            if input == touch or input.UserInputType == Enum.UserInputType.MouseButton1 then active = nil end
        end)
        ui:_ownedConnect(row, rgb.FocusLost, function()
            safe(function()
                local r, g, b, a = rgb.Text:match("^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,?%s*([%d%.]*)%s*$")
                if tonumber(r) and tonumber(g) and tonumber(b) then
                    obj:Set({r = r, g = g, b = b, a = tonumber(a) or alpha, rainbow = rainbow, fading = fading})
                end
                refresh()
            end)
        end)
        ui:_ownedConnect(row, modeButton.Activated, function()
            safe(function() ui:_openPopup(modeButton, modes, 219, 58, popup) end)
        end)

        local section = self
        function obj:Open()
            safe(function()
                refresh()
                ui:_openPopup(swatch, popup, 240, 302, section.popupOwner)
            end)
        end
        ui:_ownedConnect(row, swatch.Activated, function() safe(function() obj:Open() end) end)

        local elapsed = 0
        local function animate(dt)
            if not (rainbow or fading) then return end
            elapsed = elapsed + dt
            if elapsed < 1 / 15 then return end
            elapsed = 0
            safe(function()
                local c = current()
                swatch.BackgroundColor3 = c
                swatch.BackgroundTransparency = 1 - alpha
                alphaBar.BackgroundColor3 = c
                invoke(options.Callback, c, alpha, cachedMode)
            end)
        end
        table.insert(ui.colorUpdates, animate)
        table.insert(ui.repaint, paintModes)

        row.Destroying:Once(function()
            local index = table.find(ui.colorUpdates, animate)
            if index then table.remove(ui.colorUpdates, index) end
            index = table.find(ui.repaint, paintModes)
            if index then table.remove(ui.repaint, index) end
            pcall(function() popup:Destroy() end)
            pcall(function() modes:Destroy() end)
        end)

        changed(true)
        return ui:_register(self, "Color", options.Text, obj, options)
    end

    function Section:Colorpickers(options)
        options = options or {}
        local colors = options.Colors or {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)}
        local count = #colors
        local row = self:_row(24)
        local heading = self.ui:_text(row, options.Text or "Colorpickers")
        heading.Position = UDim2.fromOffset(0, 0)
        heading.Size = UDim2.new(1, -(count * 20 + 4), 1, 0)
        local result = {}
        for i, color in ipairs(colors) do
            local o = self:Colorpicker({
                Text = (options.Text or "Colorpickers") .. " " .. i,
                Default = color,
                Flag = options.Flag and (options.Flag .. "/" .. i),
                Callback = options.Callback,
            })
            if o and o.Instance then
                o.Instance.Parent = row
                o.Instance.Size = UDim2.fromOffset(18, 24)
                o.Instance.Position = UDim2.new(1, -(count - i + 1) * 20, 0, 0)
                for _, x in ipairs(o.Instance:GetChildren()) do
                    if x:IsA("TextLabel") then x.Visible = false end
                end
            end
            table.insert(result, o)
        end
        return table.unpack(result)
    end

    function Section:ToggleColor(options)
        options = options or {}
        local row = self:_row(24)
        local toggle = self:Toggle(options)
        if toggle and toggle.Instance then
            toggle.Instance.Parent = row
            toggle.Instance.Size = UDim2.new(1, -28, 1, 0)
        end
        local color = self:Colorpicker({
            Text = (options.Text or "Toggle") .. " Color",
            Default = options.Color or Color3.fromRGB(65, 136, 163),
            Flag = options.Flag and options.Flag .. "/Color",
            Callback = options.ColorCallback,
        })
        if color and color.Instance then
            color.Instance.Parent = row
            color.Instance.Position = UDim2.new(1, -26, 0, 0)
            color.Instance.Size = UDim2.fromOffset(26, 24)
            for _, x in ipairs(color.Instance:GetChildren()) do
                if x:IsA("TextLabel") then x.Visible = false end
            end
        end
        return toggle, color
    end

    function Section:ToggleKeybind(options)
        options = options or {}
        local row = self:_row(24)
        local toggle = self:Toggle(options)
        if toggle and toggle.Instance then
            toggle.Instance.Parent = row
            toggle.Instance.Size = UDim2.new(1, -94, 1, 0)
        end
        local bind
        bind = self:Keybind({
            Text = (options.Text or "Toggle") .. " Key",
            Name = options.Text or "Toggle",
            Mode = options.Mode or "Toggle",
            Default = options.Key or "None",
            Flag = options.Flag and options.Flag .. "/Key",
            Callback = function(key, active)
                local mode = bind and bind.Mode or options.Mode or "Toggle"
                if mode == "Hold" or mode == "Toggle" then safe(function() toggle:Set(active) end)
                else safe(function() toggle:Toggle() end) end
                invoke(options.KeyCallback, key, toggle:Get())
            end,
        })
        if bind then
            bind.LinkedToggle = toggle
            self.ui.keybindDirty = true
            if bind.Instance then
                bind.Instance.Parent = row
                bind.Instance.Position = UDim2.new(1, -94, 0, 0)
                bind.Instance.Size = UDim2.fromOffset(94, 24)
                bind.Button.Position = UDim2.fromScale(0, 0)
                bind.Button.Size = UDim2.fromScale(1, 1)
                for _, child in ipairs(bind.Instance:GetChildren()) do
                    if child:IsA("TextLabel") then child.Visible = false end
                end
            end
        end
        return toggle, bind
    end

    function Section:GearToggle(options)
        options = options or {}
        local ui = self.ui
        local row = self:_row(24)
        local toggle = self:Toggle(options)
        if toggle and toggle.Instance then
            toggle.Instance.Parent = row
            toggle.Instance.Size = UDim2.new(1, -26, 1, 0)
        end
        local gear = create("TextButton", {
            Text = "", BackgroundTransparency = 1,
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, -24, 0, 0),
        }, row)
        local icon, tint = ui:_icon(gear, "settings", 17)
        local popup = ui:_makePopup(250, 45)
        local items = ui:_frame(popup, {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8),
            Size = UDim2.new(1, -16, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        local ll = layout(items, 4)
        local gearSection = setmetatable({
            ui = ui, tab = self.tab,
            title = (options.Text or "Toggle") .. " Gear",
            path = self.path .. "/" .. (toggle and toggle.Flag or "gear") .. "/Gear",
            items = items, column = self.column, popupOwner = popup,
        }, Section)
        local parentSection = self
        gearSection.reveal = function()
            safe(function()
                ui:Select(parentSection.tab.page, parentSection.tab)
                ui:_openPopup(gear, popup, 250, math.max(30, ll.AbsoluteContentSize.Y + 16), parentSection.popupOwner)
            end)
        end
        if options.Build then
            invoke(options.Build, gearSection)
        else
            gearSection:Toggle({Text = "Gear toggle", Default = true, Callback = options.GearCallback})
            gearSection:Dropdown({Text = "Gear dropdown", Options = options.GearOptions or {"Option1", "Option2", "Option3"}})
            gearSection:Slider({Text = "Gear slider", Min = 0, Max = 100, Default = 25})
            gearSection:Button({Text = "Gear button", Callback = options.GearButtonCallback})
        end
        ui:_ownedConnect(row, gear.MouseEnter, function()
            ui:_tween(icon, {Rotation = 45}, .3); tint(ui.accent)
        end)
        ui:_ownedConnect(row, gear.MouseLeave, function()
            ui:_tween(icon, {Rotation = 0}, .3); tint(ui.colors.muted)
        end)
        ui:_ownedConnect(row, gear.Activated, function()
            safe(function()
                ui:_openPopup(gear, popup, 250, math.max(30, ll.AbsoluteContentSize.Y + 16), self.popupOwner)
            end)
        end)
        if toggle then toggle.Gear = gearSection end
        return toggle
    end

    local function shallowCopy(source)
        local result = {}
        for key, value in pairs(source or {}) do result[key] = value end
        return result
    end

    local function normalizeIndexedArgs(index, options, fallbackText)
        if type(index) == "table" then
            options = index
            index = options.Index or options.Idx or options.Flag or options.Text
        end
        options = shallowCopy(options)
        index = index or options.Index or options.Idx or options.Flag or options.Text or fallbackText
        if index ~= nil then index = tostring(index) end
        if options.Text == nil and index then options.Text = index end
        if index and options.Flag == nil then options.Flag = index end
        return index, options
    end

    local function multiValueToArray(value, choices)
        local result = {}
        if type(value) ~= "table" then return result end
        local isArray = #value > 0
        if isArray then
            for _, item in ipairs(value) do
                if table.find(choices, item) and not table.find(result, item) then
                    table.insert(result, item)
                end
            end
        else
            for item, enabled in pairs(value) do
                if enabled and table.find(choices, item) and not table.find(result, item) then
                    table.insert(result, item)
                end
            end
            table.sort(result, function(a, b) return tostring(a) < tostring(b) end)
        end
        return result
    end

    function UI:_publicValue(control, kind, rawValue, options)
        if rawValue == nil and control and control.Get then
            local ok, value = pcall(control.Get, control)
            if ok then rawValue = value end
        end
        if kind == "Dropdown" and options and options.Multi then
            local map = {}
            for _, item in ipairs(rawValue or {}) do map[item] = true end
            return map
        elseif kind == "Color" then
            if type(rawValue) == "table" then
                return Color3.fromRGB(
                    clamp(rawValue.r or rawValue[1], 0, 255),
                    clamp(rawValue.g or rawValue[2], 0, 255),
                    clamp(rawValue.b or rawValue[3], 0, 255)
                )
            end
        elseif kind == "Range" and type(rawValue) == "table" then
            return {rawValue[1], rawValue[2]}
        end
        return rawValue
    end

    function UI:_expose(index, control, kind, options)
        if not index or index == "" or not control then return control end
        if self.namedControls[index] then return control end

        options = options or {}
        safe(function()
            self.namedControls[index] = control
            control.Index = index
            control.Value = self:_publicValue(control, kind, nil, options)
            if kind == "Color" and control.Get then
                local colorData = control:Get()
                local alpha = type(colorData) == "table" and colorData.a or 1
                control.Transparency = options._usesTransparency and (1 - alpha) or alpha
            end
            control._changedCallbacks = control._changedCallbacks or {}
            control._clickCallbacks = control._clickCallbacks or {}
            control.Tooltip = options.Tooltip
            control.DisabledTooltip = options.DisabledTooltip

            if (type(options.Tooltip) == "string" and options.Tooltip ~= "")
                or (type(options.DisabledTooltip) == "string" and options.DisabledTooltip ~= "") then
                if not self.tooltipPanel then
                    self.tooltipPanel = self:_frame(self.root, {
                        Name = "ControlTooltip", BackgroundTransparency = 0,
                        BorderSizePixel = 0, Visible = false, ZIndex = 350,
                        Size = UDim2.fromOffset(100, 28),
                    }, "raised")
                    round(self.tooltipPanel, 4)
                    self:_stroke(self.tooltipPanel, "outline", .2)
                    self.tooltipLabel = self:_text(self.tooltipPanel, "", 11, "text")
                    self.tooltipLabel.Position = UDim2.fromOffset(8, 4)
                    self.tooltipLabel.ZIndex = 351
                    self.tooltipLabel.TextWrapped = true
                    self.tooltipLabel.TextYAlignment = Enum.TextYAlignment.Center
                end
                local tooltipPanel = self.tooltipPanel
                local tooltipLabel = self.tooltipLabel
                local function showTooltip()
                    safe(function()
                        if self.destroyed or not self.visible or not control.Instance.Parent then return end
                        local message = control.Disabled and (options.DisabledTooltip or options.Tooltip) or options.Tooltip
                        if type(message) ~= "string" or message == "" then
                            tooltipPanel.Visible = false
                            return
                        end
                        local bounds = TextService:GetTextSize(message, tooltipLabel.TextSize, tooltipLabel.Font, Vector2.new(240, 1000))
                        local width = math.clamp(bounds.X, 60, 240)
                        local height = math.max(20, bounds.Y)
                        tooltipLabel.Text = message
                        tooltipLabel.Size = UDim2.fromOffset(width, height)
                        tooltipPanel.Size = UDim2.fromOffset(width + 16, height + 8)
                        local anchor = control.Instance.AbsolutePosition + Vector2.new(0, control.Instance.AbsoluteSize.Y + 6)
                        local position = (anchor - self.root.AbsolutePosition) / self.scale
                        position = Vector2.new(
                            math.clamp(position.X, 6, math.max(6, self.viewport.X - width - 22)),
                            math.clamp(position.Y, 6, math.max(6, self.viewport.Y - height - 20))
                        )
                        tooltipPanel.Position = UDim2.fromOffset(position.X, position.Y)
                        tooltipPanel.Visible = true
                    end)
                end
                self:_ownedConnect(control.Instance, control.Instance.MouseEnter, showTooltip)
                self:_ownedConnect(control.Instance, control.Instance.MouseLeave, function()
                    safe(function()
                        if tooltipPanel.Parent then tooltipPanel.Visible = false end
                    end)
                end)
            end

            local registry = kind == "Toggle" and self.Toggles
                or kind == "Label" and self.Labels
                or kind == "Button" and self.Buttons
                or self.Options
            registry[index] = control

            local originalCallback = options.Callback
            options.Callback = function(...)
                local args = table.pack(...)
                safe(function()
                    local value
                    local finishedSuppressed = kind == "Input"
                        and options.Finished == true
                        and args.n > 1
                        and args[2] ~= true

                    if kind == "Range" then
                        value = {args[1], args[2]}
                    elseif kind == "Color" then
                        value = args[1]
                        control.Transparency = options._usesTransparency and (1 - (args[2] or 1)) or args[2]
                        control.Mode = args[3]
                    elseif kind == "Dropdown" and options.Multi then
                        value = self:_publicValue(control, kind, args[1], options)
                    elseif kind == "Keybind" then
                        value = control:Get()
                    elseif kind ~= "Button" and kind ~= "Label" then
                        value = args[1]
                    end

                    if value ~= nil then control.Value = value end
                    if kind ~= "Keybind" and not finishedSuppressed then
                        for _, callback in ipairs(control._changedCallbacks) do
                            invoke(callback, control.Value, table.unpack(args, 1, args.n))
                        end
                    end
                    if not finishedSuppressed then
                        if kind == "Color" and options._usesTransparency then
                            invoke(originalCallback, args[1], 1 - (args[2] or 1))
                        else
                            invoke(originalCallback, table.unpack(args, 1, args.n))
                        end
                    end
                    if kind == "Keybind" then
                        for _, callback in ipairs(control._clickCallbacks) do
                            invoke(callback, table.unpack(args, 1, args.n))
                        end
                    end
                end)
            end

            if kind == "Keybind" then
                local originalChanged = options.Changed
                options.Changed = function(key, ...)
                    local args = table.pack(...)
                    safe(function()
                        control.Value = key
                        for _, callback in ipairs(control._changedCallbacks) do
                            invoke(callback, key, table.unpack(args, 1, args.n))
                        end
                        invoke(originalChanged, key, table.unpack(args, 1, args.n))
                    end)
                end
            end

            function control:OnChanged(callback)
                if type(callback) ~= "function" then return self end
                table.insert(self._changedCallbacks, callback)
                return self
            end

            function control:SetValue(value, ...)
                if kind == "Dropdown" then
                    if options.Multi then
                        value = multiValueToArray(value, options.Options or options.Values or {})
                    elseif type(value) == "number" then
                        value = (options.Options or options.Values or {})[value]
                    end
                elseif kind == "Color" and type(value) == "table" and value.Color then
                    value = value.Color
                elseif kind == "Keybind" and type(value) == "table" then
                    local key, mode = value[1], value[2]
                    local result = self:Set(key)
                    if mode == "Toggle" or mode == "Hold" or mode == "Always" then
                        self.Mode = mode
                    end
                    return result
                end
                if self.Set then return self:Set(value, ...) end
            end

            if kind == "Keybind" then
                function control:OnClick(callback)
                    if type(callback) ~= "function" then return self end
                    table.insert(self._clickCallbacks, callback)
                    return self
                end
                function control:GetState() return self:IsActive() end
            end

            if kind == "Color" then
                function control:SetValueRGB(color)
                    if typeof(color) == "Color3" then return self:Set(color) end
                end
            end

            if kind == "Dropdown" and type(control.SetOptions) == "function" then
                local originalSetOptions = control.SetOptions
                function control:SetOptions(values, ...)
                    options.Options = values or {}
                    options.Values = options.Options
                    return originalSetOptions(self, options.Options, ...)
                end
                control.SetValues = control.SetOptions
            end

            local section = control._section
            if section then
                function control:AddColorPicker(childIndex, childOptions)
                    local color = section:_addIndexed("Colorpicker", childIndex, childOptions, "Color")
                    self.ColorPickers = self.ColorPickers or {}
                    table.insert(self.ColorPickers, color)

                    if self.Attachments then
                        color.Instance.Parent = self.Attachments
                        color.Instance.Size = UDim2.fromOffset(22, 22)
                        color.Instance.LayoutOrder = 10 + #self.ColorPickers
                        color.Instance.BackgroundTransparency = 1
                        for _, child in ipairs(color.Instance:GetDescendants()) do
                            if child:IsA("TextLabel") then child.Visible = false end
                        end
                        if section.Resize then safe(function() section:Resize() end) end
                    else
                        color.Instance.Parent = self.Instance
                        color.Instance.Size = UDim2.fromOffset(22, 22)
                        for _, child in ipairs(color.Instance:GetChildren()) do
                            if child:IsA("TextLabel") then child.Visible = false end
                        end
                    end
                    return self
                end
                function control:AddKeyPicker(childIndex, childOptions)
                    local keybind = section:_addIndexed("Keybind", childIndex, childOptions, "Keybind", self)
                    if childOptions and childOptions.SyncToggleState and self.Kind == "Toggle" then
                        if self.Attachments then
                            keybind.Instance.Parent = self.Attachments
                            keybind.Instance.Size = UDim2.fromOffset(64, 22)
                            keybind.Instance.LayoutOrder = 50
                            keybind.Instance.BackgroundTransparency = 1
                            if keybind.Button then
                                keybind.Button.BackgroundColor3 = section.ui.colors.panel
                                keybind.Button.BackgroundTransparency = 0.1
                                local ks = keybind.Button:FindFirstChildOfClass("UIStroke")
                                if not ks then
                                    ks = section.ui:_stroke(keybind.Button, "accent", 1)
                                else
                                    ks.Transparency = 1
                                end
                                section.ui:_ownedConnect(keybind.Button, keybind.Button.MouseEnter, function()
                                    section.ui:_tween(ks, {Transparency = .55}, .18)
                                end)
                                section.ui:_ownedConnect(keybind.Button, keybind.Button.MouseLeave, function()
                                    section.ui:_tween(ks, {Transparency = 1}, .22)
                                end)
                            end
                        else
                            keybind.Instance.Parent = self.Instance
                            keybind.Instance.Size = UDim2.fromOffset(94, 24)
                            keybind.Instance.Position = UDim2.new(1, -94, 0, 0)
                        end
                        if keybind.Button then
                            keybind.Button.Position = UDim2.fromScale(0, 0)
                            keybind.Button.Size = UDim2.fromScale(1, 1)
                        end
                        for _, child in ipairs(keybind.Instance:GetDescendants()) do
                            if child:IsA("TextLabel") and child ~= (keybind.Button and keybind.Button:FindFirstChildWhichIsA("TextLabel")) then
                                child.Visible = false
                            end
                        end
                        -- keep only the key display text on the button
                        self.KeyPicker = keybind
                        section.ui.keybindDirty = true
                        if section.Resize then safe(function() section:Resize() end) end
                    end
                    return self
                end
                function control:AddSettings(childIndex, childOptions)
                    local gear = create("TextButton", {
                        Text = "", BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(22, 22),
                    }, nil)

                    if self.Attachments then
                        local wrapper = create("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.fromOffset(22, 22),
                            LayoutOrder = 100,
                        }, self.Attachments)
                        gear.Parent = wrapper
                        gear.AnchorPoint = Vector2.new(0.5, 0.5)
                        gear.Position = UDim2.fromScale(0.5, 0.5)
                        gear.Size = UDim2.fromScale(1, 1)
                    else
                        gear.Parent = self.Instance
                        gear.AnchorPoint = Vector2.new(1, 0.5)
                        gear.Position = UDim2.new(1, -22, 0.5, 5)
                    end

                    local icon, tint = section.ui:_icon(gear, "settings", 17)
                    local gearStroke = section.ui:_stroke(gear, "accent", 1)
                    section.ui:_ownedConnect(self.Instance, gear.MouseEnter, function()
                        section.ui:_tween(gearStroke, {Transparency = .55}, .18)
                    end)
                    section.ui:_ownedConnect(self.Instance, gear.MouseLeave, function()
                        section.ui:_tween(gearStroke, {Transparency = 1}, .22)
                    end)
                    local popup = section.ui:_makePopup(250, 45)
                    local items = section.ui:_frame(popup, {
                        BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8),
                        Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    })
                    local ll = layout(items, 4)
                    local settingsSection = setmetatable({
                        ui = section.ui, tab = section.tab,
                        title = (childIndex or "Settings") .. " Settings",
                        path = section.path .. "/" .. self.Flag .. "/Settings",
                        items = items, column = section.column, popupOwner = popup,
                    }, Section)
                    settingsSection.reveal = function()
                        safe(function()
                            section.ui:Select(section.tab.page, section.tab)
                            section.ui:_openPopup(gear, popup, 250, math.max(30, ll.AbsoluteContentSize.Y + 16), section.popupOwner)
                        end)
                    end
                    childOptions = childOptions or {}
                    if childOptions.Build then
                        invoke(childOptions.Build, settingsSection)
                    else
                        settingsSection:Toggle({Text = "Enable outline", Default = true, Callback = function(v) self.OutlineEnabled = v end})
                    end
                    section.ui:_ownedConnect(self.Instance, gear.MouseEnter, function()
                        section.ui:_tween(icon, {Rotation = 45}, .3); tint(section.ui.accent)
                    end)
                    section.ui:_ownedConnect(self.Instance, gear.MouseLeave, function()
                        section.ui:_tween(icon, {Rotation = 0}, .3); tint(section.ui.colors.muted)
                    end)
                    section.ui:_ownedConnect(self.Instance, gear.Activated, function()
                        safe(function()
                            section.ui:_openPopup(gear, popup, 250, math.max(30, ll.AbsoluteContentSize.Y + 16), section.popupOwner)
                        end)
                    end)
                    self.GearButton = gear
                    return self
                end
                function control:AddDropdown(childIndex, childOptions)
                    return section:_addIndexed("Dropdown", childIndex, childOptions, "Dropdown")
                end
                function control:AddButton(childIndex, childOptions)
                    local subButton = section:AddButton(childIndex, childOptions)
                    if self.Kind == "Button" and self.Button and subButton.Button then
                        self._buttonChildren = self._buttonChildren or {self}
                        table.insert(self._buttonChildren, subButton)
                        local count = #self._buttonChildren
                        for position, item in ipairs(self._buttonChildren) do
                            item.Instance.Parent = self.Instance
                            item.Instance.Position = UDim2.new((position - 1) / count, 3 * (position - 1), 0, 0)
                            item.Instance.Size = UDim2.new(1 / count, -3 * (count - 1) / count, 1, 0)
                            item.Button.Position = UDim2.fromScale(0, 0)
                            item.Button.Size = UDim2.fromScale(1, 1)
                        end
                    end
                    return subButton
                end
            end

            if options.Visible == false then safe(function() control:SetVisible(false) end) end
            local disabledValues = {}
            local function setDisabled(disabled)
                disabled = disabled == true
                control.Disabled = disabled
                local root = control.Instance
                if not root or not root.Parent then return end
                local descendants = {root}
                for _, child in ipairs(root:GetDescendants()) do table.insert(descendants, child) end
                for _, child in ipairs(descendants) do
                    if child:IsA("GuiObject") then
                        if disabled then
                            if disabledValues[child] == nil then disabledValues[child] = child.Active end
                            child.Active = false
                            pcall(function() child.Interactable = false end)
                        else
                            if disabledValues[child] ~= nil then child.Active = disabledValues[child] end
                            pcall(function() child.Interactable = true end)
                        end
                    end
                    if child:IsA("TextBox") then
                        pcall(function() child.TextEditable = not disabled end)
                    end
                end
            end
            function control:SetDisabled(value) setDisabled(value) return self end
            if options.Disabled then setDisabled(true) end

            control.Instance.Destroying:Once(function()
                self.namedControls[index] = nil
                registry[index] = nil
            end)
        end)
        return control
    end

    function Section:_addIndexed(methodName, index, options, kind, parentControl)
        index, options = normalizeIndexedArgs(index, options, methodName)
        if methodName == "Dropdown" then
            options.Options = options.Options or options.Values or {}
            if options.SpecialType == "Player" then
                options.Options = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if not (options.ExcludeLocalPlayer and p == player) then
                        table.insert(options.Options, p.Name)
                    end
                end
            elseif options.SpecialType == "Team" then
                options.Options = {}
                for _, team in ipairs(Teams:GetTeams()) do
                    table.insert(options.Options, team.Name)
                end
            end
            if options.Multi then
                options.Default = multiValueToArray(options.Default, options.Options)
            elseif type(options.Default) == "number" then
                options.Default = options.Options[options.Default]
            end
        elseif methodName == "Colorpicker" then
            options.Text = options.Text or options.Title or index
            if options.Transparency ~= nil then
                options.Alpha = 1 - clamp(options.Transparency, 0, 1)
                options._usesTransparency = true
            end
        elseif methodName == "Input" then
            options.MaxLength = tonumber(options.MaxLength)
        elseif methodName == "Keybind" then
            options.ShowInList = options.ShowInList ~= false and options.NoUI ~= true
            options.Changed = options.Changed or options.ChangedCallback
            if parentControl and options.SyncToggleState and parentControl.Kind == "Toggle" then
                local callback = options.Callback
                options.Callback = function(key, active)
                    safe(function() parentControl:Set(active == true) end)
                    invoke(callback, key, active)
                end
            end
        end

        if methodName == "Button" then
            options.Callback = options.Callback or options.Func
            if options.DoubleClick then
                local callback = options.Callback
                local lastClick = 0
                options.Callback = function(...)
                    local now = os.clock()
                    if now - lastClick <= (tonumber(options.DoubleClickDelay) or .35) then
                        lastClick = 0
                        invoke(callback, ...)
                    else
                        lastClick = now
                    end
                end
            end
        end

        local creator = self[methodName]
        if type(creator) ~= "function" then return nil end
        local ok, control = pcall(creator, self, options)
        if not ok or not control then return nil end
        if methodName == "Keybind" and parentControl and options.SyncToggleState and parentControl.Kind == "Toggle" then
            control.LinkedToggle = parentControl
            self.ui.keybindDirty = true
        end
        safe(function() self.ui:_expose(index, control, kind, options) end)
        if methodName == "Dropdown" and options.SpecialType == "Player" then
            local function refreshPlayers()
                local values = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if not (options.ExcludeLocalPlayer and p == player) then
                        table.insert(values, p.Name)
                    end
                end
                safe(function() control:SetOptions(values) end)
                options.Options = values
            end
            self.ui:_ownedConnect(control.Instance, Players.PlayerAdded, refreshPlayers)
            self.ui:_ownedConnect(control.Instance, Players.PlayerRemoving, refreshPlayers)
        elseif methodName == "Dropdown" and options.SpecialType == "Team" then
            local function refreshTeams()
                local values = {}
                for _, team in ipairs(Teams:GetTeams()) do table.insert(values, team.Name) end
                safe(function() control:SetOptions(values) end)
                options.Options = values
            end
            self.ui:_ownedConnect(control.Instance, Teams.ChildAdded, refreshTeams)
            self.ui:_ownedConnect(control.Instance, Teams.ChildRemoved, refreshTeams)
        end
        return control
    end

    function Section:AddToggle(index, options) return self:_addIndexed("Toggle", index, options, "Toggle") end

    function Section:AddSlider(index, options)
        options = options or (type(index) == "table" and index or {})
        if options.Step == nil and tonumber(options.Rounding) then
            options.Step = 10 ^ -math.max(0, tonumber(options.Rounding))
        end
        return self:_addIndexed("Slider", index, options, "Slider")
    end

    function Section:AddRangeSlider(index, options)
        options = options or (type(index) == "table" and index or {})
        if options.Step == nil and tonumber(options.Rounding) then
            options.Step = 10 ^ -math.max(0, tonumber(options.Rounding))
        end
        return self:_addIndexed("RangeSlider", index, options, "Range")
    end

    function Section:AddInput(index, options) return self:_addIndexed("Input", index, options, "Input") end
    function Section:AddDropdown(index, options) return self:_addIndexed("Dropdown", index, options, "Dropdown") end
    function Section:AddColorPicker(index, options) return self:_addIndexed("Colorpicker", index, options, "Color") end
    function Section:AddKeyPicker(index, options, parentControl) return self:_addIndexed("Keybind", index, options, "Keybind", parentControl) end
    function Section:AddButton(index, options) return self:_addIndexed("Button", index, options, "Button") end

    function Section:AddLabel(index, options, labelIndex)
        local text, opts, finalIndex
        if type(index) == "table" then
            opts = shallowCopy(index)
            finalIndex = opts.Index or opts.Idx or opts.Flag or opts.Text
        elseif type(options) == "table" then
            opts = shallowCopy(options)
            finalIndex = tostring(index)
            opts.Text = opts.Text or tostring(index)
        elseif type(options) == "boolean" then
            opts = {Text = tostring(index), DoesWrap = options}
            finalIndex = labelIndex
        else
            opts = {Text = tostring(index or "Label")}
            finalIndex = labelIndex
        end
        if opts.DoesWrap then opts.Wrap = true end
        local control = self:Label(opts)
        if control then
            if finalIndex then safe(function() self.ui:_expose(tostring(finalIndex), control, "Label", opts) end) end
            function control:SetText(value) return self:Set(value) end
        end
        return control
    end

    function Section:AddList(index, options)
        if type(index) == "table" and options == nil then
            return self:List(index)
        end
        return self:_addIndexed("List", index, options, "List")
    end

    function Section:AddDivider()
        local row = self:_row(1)
        return self.ui:_frame(row, {
            BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 1),
        }, "outline")
    end

    function Section:AddDependencyBox()
        local tab = self.tab
        local column = self.column == tab.columns[2] and 2 or 1
        local dependency = tab:Section(self.title .. " Dependencies", column)
        dependency.ParentSection = self
        function dependency:SetupDependencies(dependencies)
            safe(function()
                dependencies = dependencies or {}
                local function readValue(control)
                    if not control then return nil end
                    if control.Get then return control:Get() end
                    return control.Value
                end
                local function matches(actual, expected)
                    if type(actual) == "table" then
                        if type(expected) == "table" then
                            for key, value in pairs(expected) do
                                if actual[key] ~= value then return false end
                            end
                            return true
                        end
                        return actual[expected] == true or table.find(actual, expected) ~= nil
                    end
                    return actual == expected
                end
                local function update()
                    safe(function()
                        local visible = true
                        for _, dependencyEntry in ipairs(dependencies) do
                            local control, expected = dependencyEntry[1], dependencyEntry[2]
                            if not matches(readValue(control), expected) then
                                visible = false
                                break
                            end
                        end
                        self.holder.Visible = visible
                        self:Resize()
                        if self.ParentSection then self.ParentSection:Resize() end
                    end)
                end
                for _, dependencyEntry in ipairs(dependencies) do
                    local control = dependencyEntry[1]
                    if control and type(control.OnChanged) == "function" then
                        control:OnChanged(update)
                    end
                end
                update()
            end)
            return self
        end
        return dependency
    end

    function UI:_createTabbox(tab, column, title, options)
        options = options or {}
        local base = tab:Section(title or "Tabbox", column, options)
        local ui = tab.page.ui
        local bar = ui:_frame(base.items, {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1,
        })
        layout(bar, 5, true)
        local content = ui:_frame(base.items, {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
        })
        layout(content, 0)
        local tabbox = {Base = base, Tabs = {}, Current = nil}
        function tabbox:AddTab(name, icon)
            name = tostring(name or ("Tab " .. tostring(#self.Tabs + 1)))
            if type(icon) == "table" then icon = icon.Icon or icon.Image or icon.Asset end
            local pane = ui:_frame(content, {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false, LayoutOrder = #self.Tabs + 1,
            })
            layout(pane, 8)
            local proxy = setmetatable({
                ui = ui, tab = tab, title = name,
                path = base.path .. "/" .. name,
                holder = base.holder, items = pane,
                column = base.column, scroll = base.scroll,
            }, Section)
            function proxy:Resize() safe(function() base:Resize() end) end
            local button = ui:_button(bar, name)
            button.Size = UDim2.fromOffset(math.max(68, math.min(140, #name * 8 + (icon and 36 or 20))), 26)
            button.LayoutOrder = #self.Tabs + 1
            if icon then
                button.TextXAlignment = Enum.TextXAlignment.Left
                pad(button, 25, 7)
                proxy.IconRoot, proxy.IconTint = ui:_icon(button, icon, 13, "muted")
                proxy.IconRoot.AnchorPoint = Vector2.new(0, .5)
                proxy.IconRoot.Position = UDim2.new(0, 8, .5, 0)
                proxy.IconRoot.Size = UDim2.fromOffset(14, 14)
            end
            proxy.Button = button
            function proxy:Select()
                safe(function()
                    for _, entry in ipairs(tabbox.Tabs) do
                        entry.Instance.Visible = entry == self
                        entry.Button:SetAttribute("Selected", entry == self)
                        if entry.IconTint then
                            entry.IconTint(entry == self and ui.accent or ui.colors.muted)
                        end
                    end
                    tabbox.Current = self
                    base:Resize()
                end)
            end
            ui:_ownedConnect(base.holder, button.Activated, function() safe(function() proxy:Select() end) end)
            proxy.Instance = pane
            table.insert(self.Tabs, proxy)
            if #self.Tabs == 1 then safe(function() proxy:Select() end) end
            return proxy
        end
        function tabbox:GetSelected() return self.Current end
        return tabbox
    end

    function UI:SetNotificationPosition(position)
        safe(function()
            local lowerPos = tostring(position or "bottom left"):lower()
            local ax = lowerPos:find("right", 1, true) and 1 or (lowerPos:find("middle", 1, true) and .5 or 0)
            local ay = lowerPos:find("top", 1, true) and 0 or 1
            self.notifications.AnchorPoint = Vector2.new(ax, ay)
            self.notifications.Position = UDim2.new(
                ax, ax == 0 and 10 or (ax == 1 and -10 or 0),
                ay, ay == 0 and 10 or -10
            )
            self.notifications:FindFirstChildOfClass("UIListLayout").VerticalAlignment =
                ay == 0 and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
        end)
    end

    function UI:Notify(title, message, duration)
        if self.destroyed then return end
        safe(function()
            local soundId
            if message == nil then
                message = tostring(title or "")
                title = "Notification"
                soundId = duration
                duration = 4
            else
                title = tostring(title or "Notification")
                message = tostring(message or "")
                duration = tonumber(duration) or 4
            end
            local slot = self:_frame(self.notifications, {
                Name = "NotificationSlot", BackgroundTransparency = 1,
                Size = UDim2.fromOffset(245, 0), ClipsDescendants = false,
            })
            local card = create("CanvasGroup", {
                Name = "NotificationCard", BackgroundColor3 = self.colors.panel,
                BorderSizePixel = 0, Size = UDim2.fromOffset(245, 52),
                Position = UDim2.fromOffset(-270, 0), GroupTransparency = 1,
                ClipsDescendants = true,
            }, slot)
            round(card, 4)
            self:_stroke(card, "outline", .4)
            local t = self:_text(card, title or "Notification", 12)
            t.Position = UDim2.fromOffset(10, 8)
            t.Size = UDim2.new(1, -20, 0, 16)
            local body = self:_text(card, message or "", 11, "text")
            body.Position = UDim2.fromOffset(10, 24)
            body.Size = UDim2.new(1, -20, 0, 20)
            body.TextTruncate = Enum.TextTruncate.AtEnd
            self:_tween(slot, {Size = UDim2.fromOffset(245, 52)}, .28)
            self:_tween(card, {
                Position = UDim2.fromOffset(0, 0), GroupTransparency = 0,
            }, .38, Enum.EasingStyle.Quint)
            if soundId ~= nil then
                local ok, sound = pcall(function()
                    local s = Instance.new("Sound")
                    s.Name = "SkidUiNotificationSound"
                    s.SoundId = tostring(soundId):match("^rbxassetid://") and tostring(soundId)
                        or ("rbxassetid://" .. tostring(soundId))
                    s.Volume = 0.65
                    s.Parent = self.gui
                    s:Play()
                    return s
                end)
                if ok and sound then
                    task.delay(6, function()
                        if sound.Parent then pcall(function() sound:Destroy() end) end
                    end)
                end
            end
            task.delay(duration or 4, function()
                if self.destroyed or not slot.Parent then return end
                local destination = -(card.AbsolutePosition.X / self.scale) - card.AbsoluteSize.X / self.scale - 24
                self:_tween(card, {Position = UDim2.fromOffset(destination, 0)}, .42, Enum.EasingStyle.Quint)
                task.delay(.43, function()
                    if self.destroyed or not slot.Parent then return end
                    self:_tween(slot, {Size = UDim2.fromOffset(245, 0)}, .22)
                    task.delay(.23, function()
                        if slot.Parent then pcall(function() slot:Destroy() end) end
                    end)
                end)
            end)
        end)
    end

    function UI:PlayerTable(tab, options)
        options = options or {}
        local ui = self
        for _, col in ipairs(tab.columns) do col.Visible = false end

        local panel = ui:_frame(tab.body, {
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.new(1, -24, 1, -24),
        }, "panel")
        round(panel, 6)
        local area = ui:_frame(panel, {
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.new(1, -24, 1, -104),
        }, "background")
        round(area, 5)
        local xPositions = {.02, .34, .67}
        for i, name in ipairs({"Username", "Team", "Status"}) do
            local t = ui:_text(area, name, 12, "muted")
            t.Position = UDim2.new(xPositions[i], 0, 0, 5)
            t.Size = UDim2.new(.3, 0, 0, 24)
        end
        local finder = ui:_input(area, "Search players...", "")
        finder.AnchorPoint = Vector2.new(1, 0)
        finder.Position = UDim2.new(1, -6, 0, 4)
        finder.Size = UDim2.fromOffset(26, 26)
        finder.TextTransparency = 1
        local fi = ui:_icon(finder, "search", 14)
        ui:_connect(finder.Focused, function()
            safe(function()
                fi.Visible = false
                finder.TextTransparency = 0
                ui:_tween(finder, {Size = UDim2.fromOffset(170, 26)}, .25)
            end)
        end)
        ui:_connect(finder.FocusLost, function()
            safe(function()
                if finder.Text == "" then
                    fi.Visible = true
                    finder.TextTransparency = 1
                    ui:_tween(finder, {Size = UDim2.fromOffset(26, 26)}, .25)
                end
            end)
        end)
        local rows = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, 34),
            Size = UDim2.new(1, -20, 1, -40),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 2,
        }, area)
        ui:_bind(rows, "ScrollBarImageColor3", "accent")
        layout(rows, 5)
        local footer = ui:_frame(panel, {
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 1, -82),
            Size = UDim2.new(1, -24, 0, 70),
        }, "raised")
        round(footer, 4)
        local portrait = create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = "",
            Position = UDim2.fromOffset(0, 3),
            Size = UDim2.fromOffset(62, 62),
        }, footer)
        round(portrait, 4)
        local nameLabel = ui:_text(footer, "Select a player", 11, "muted")
        nameLabel.Position = UDim2.fromOffset(75, 0)
        nameLabel.Size = UDim2.new(.34, 0, 0, 20)
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        local details = ui:_text(footer, "", 11, "muted")
        details.Position = UDim2.fromOffset(75, 21)
        details.Size = UDim2.new(.34, 0, 0, 40)
        details.TextYAlignment = Enum.TextYAlignment.Top

        local selected, status = nil, {}
        local api = {}
        local buttons = {}
        local thumbToken = 0
        function api:GetSelected() return selected end
        function api:GetStatus(p)
            if not p then return "Neutral" end
            return p == player and "LocalPlayer" or status[p.UserId] or "Neutral"
        end
        function api:SetStatus(value)
            if not selected or selected == player then return end
            if not table.find({"Neutral", "Enemy", "Friendly"}, value) then return end
            status[selected.UserId] = value
            api:Refresh()
            invoke(options.StatusChanged, selected, value)
        end
        function api:Refresh()
            safe(function()
                for _, x in ipairs(rows:GetChildren()) do
                    if x:IsA("TextButton") then pcall(function() x:Destroy() end) end
                end
                for index, p in ipairs(Players:GetPlayers()) do
                    if (p.Name .. " " .. p.DisplayName):lower():find(finder.Text:lower(), 1, true) then
                        local item = p
                        local b = create("TextButton", {
                            Text = "",
                            BackgroundColor3 = ui.accent,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Size = UDim2.new(1, -2, 0, 29),
                            LayoutOrder = index,
                        }, rows)
                        round(b, 4)
                        ui:_gradient(b)
                        if item == selected then ui:_tween(b, {BackgroundTransparency = 0}, .24) end
                        for i, value in ipairs({
                            item.DisplayName ~= item.Name
                                and (item.DisplayName .. " (" .. item.Name .. ")")
                                or item.Name,
                            item.Team and item.Team.Name or "None",
                            api:GetStatus(item),
                        }) do
                            local t = ui:_text(b, value, 12, "muted")
                            t.Position = UDim2.new(xPositions[i], 0, 0, 0)
                            t.Size = UDim2.new(.32, -5, 1, 0)
                            t.TextTruncate = Enum.TextTruncate.AtEnd
                            t:SetAttribute("CellRole",
                                item == selected and "selected"
                                or (i == 3 and item == player and "local" or "muted"))
                            if item == selected then
                                t.TextColor3 = ui.colors.ink
                            elseif i == 3 and item == player then
                                t.TextColor3 = Color3.fromRGB(45, 240, 188)
                            end
                        end
                        b.Activated:Connect(function() safe(function() api:Select(item) end) end)
                    end
                end
                if selected and selected.Parent then
                    nameLabel.Text = selected.DisplayName .. " (" .. selected.Name .. ")"
                    details.Text = tostring(selected.UserId) .. "\n" .. selected.AccountAge .. " days old"
                else
                    selected = nil
                    nameLabel.Text = "Select a player"
                    details.Text = ""
                    portrait.Image = ""
                end
                for value, b in pairs(buttons) do
                    local active = selected and api:GetStatus(selected) == value
                    b:SetAttribute("Selected", active == true)
                    ui:_tween(b, {TextColor3 = active and ui.colors.ink or ui.colors.muted}, .22)
                end
            end)
        end
        function api:Select(p)
            selected = p
            thumbToken = thumbToken + 1
            local token = thumbToken
            api:Refresh()
            if p then
                task.spawn(function()
                    local ok, image = pcall(
                        Players.GetUserThumbnailAsync, Players,
                        p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
                    )
                    if ok and not ui.destroyed and portrait.Parent and token == thumbToken then
                        portrait.Image = image
                    end
                end)
            end
            invoke(options.Callback, p, p and api:GetStatus(p))
        end
        for i, value in ipairs({"Neutral", "Enemy", "Friendly"}) do
            local statusValue = value
            local b = ui:_button(footer, value)
            b.Size = UDim2.new(.17, 0, 0, 26)
            b.Position = UDim2.new(.45 + (i - 1) * .185, 0, 0, 2)
            ui:_gradient(b)
            buttons[value] = b
            ui:_connect(b.Activated, function() safe(function() api:SetStatus(statusValue) end) end)
        end
        ui:_connect(finder:GetPropertyChangedSignal("Text"), function() safe(function() api:Refresh() end) end)
        local function watch(p)
            ui:_connect(p:GetPropertyChangedSignal("Team"), function() safe(function() api:Refresh() end) end)
            ui:_connect(p:GetPropertyChangedSignal("DisplayName"), function() safe(function() api:Refresh() end) end)
        end
        for _, p in ipairs(Players:GetPlayers()) do watch(p) end
        ui:_connect(Players.PlayerAdded, function(p) watch(p) safe(function() api:Refresh() end) end)
        ui:_connect(Players.PlayerRemoving, function(p)
            status[p.UserId] = nil
            if selected == p then
                selected = nil
                thumbToken = thumbToken + 1
            end
            task.defer(function()
                if not ui.destroyed and panel.Parent then safe(function() api:Refresh() end) end
            end)
        end)
        table.insert(ui.repaint, function()
            safe(function()
                for _, row in ipairs(rows:GetChildren()) do
                    if row:IsA("TextButton") then
                        row.BackgroundColor3 = ui.accent
                        for _, cell in ipairs(row:GetChildren()) do
                            if cell:IsA("TextLabel") then
                                local role = cell:GetAttribute("CellRole")
                                cell.TextColor3 = role == "selected" and ui.colors.ink
                                    or (role == "local" and Color3.fromRGB(45, 240, 188) or ui.colors.muted)
                            end
                        end
                    end
                end
            end)
        end)
        safe(function() api:Refresh() end)
        return api
    end

    function UI:_folder()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(self.configFolder) then
            safe(function() makefolder(self.configFolder) end)
        end
    end

    function UI:SaveConfig(name)
        name = cleanName(name)
        return safe(function()
            local data = {version = 2, flags = {}, theme = {}}
            for role, c in pairs(self.colors) do data.theme[role] = {c.R, c.G, c.B} end
            for flag, w in pairs(self.widgets) do
                if w.Save then
                    local ok, v = pcall(w.Get, w)
                    if ok then data.flags[flag] = v end
                end
            end
            if type(writefile) == "function" then
                self:_folder()
                writefile(self.configFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
            end
            self.configs[name] = data
            return true
        end)
    end

    function UI:LoadConfig(name)
        name = cleanName(name)
        return safe(function()
            local data = self.configs[name]
            if type(readfile) == "function" then
                local ok, text = pcall(readfile, self.configFolder .. "/" .. name .. ".json")
                if ok then
                    local decoded, value = pcall(HttpService.JSONDecode, HttpService, text)
                    if not decoded then return false, "Invalid config json" end
                    data = value
                end
            end
            if type(data) ~= "table" or type(data.flags) ~= "table" then return false, "Config not found" end
            if type(data.theme) == "table" then
                for role, c in pairs(data.theme) do
                    if type(c) == "table" then
                        safe(function()
                            self:SetThemeColor(role, Color3.new(
                                clamp(c[1], 0, 1), clamp(c[2], 0, 1), clamp(c[3], 0, 1)
                            ))
                        end)
                    end
                end
            elseif type(data.accent) == "table" then
                safe(function()
                    self:SetAccent(Color3.new(
                        clamp(data.accent[1], 0, 1), clamp(data.accent[2], 0, 1), clamp(data.accent[3], 0, 1)
                    ))
                end)
            end
            local errors = {}
            for flag, value in pairs(data.flags) do
                local w = self.widgets[flag]
                if w and w.Save and w.Set then
                    local ok, err = pcall(w.Set, w, value)
                    if not ok then table.insert(errors, flag .. ": " .. tostring(err)) end
                end
            end
            if #errors > 0 then return false, table.concat(errors, "\n") end
            return true
        end)
    end

    function UI:ListConfigs()
        local found = {}
        for name in pairs(self.configs) do found[name] = true end
        if type(listfiles) == "function" then
            local ok, files = pcall(function()
                self:_folder()
                return listfiles(self.configFolder)
            end)
            if ok and type(files) == "table" then
                for _, path in ipairs(files) do
                    local name = path:gsub("\\", "/"):match("([^/]+)%.json$")
                    if name and name ~= "auto" then found[name] = true end
                end
            end
        end
        local names = {}
        for name in pairs(found) do table.insert(names, name) end
        table.sort(names)
        return names
    end

    function UI:DeleteConfig(name)
        name = cleanName(name)
        return safe(function()
            if type(delfile) == "function" then
                local path = self.configFolder .. "/" .. name .. ".json"
                if type(isfile) ~= "function" or isfile(path) then
                    local ok, err = pcall(delfile, path)
                    if not ok then return false, tostring(err) end
                end
            end
            self.configs[name] = nil
            return true
        end)
    end

    function UI:SetAutoLoad(name)
        local value = name and cleanName(name) or nil
        return safe(function()
            if type(writefile) == "function" then
                self:_folder()
                writefile(self.configFolder .. "/auto.json", HttpService:JSONEncode({name = value}))
            end
            self.autoLoad = value
            return true
        end)
    end

    function UI:LoadAuto()
        return safe(function()
            local name = self.autoLoad
            if type(readfile) == "function" then
                local ok, text = pcall(readfile, self.configFolder .. "/auto.json")
                if ok then
                    local decoded, data = pcall(HttpService.JSONDecode, HttpService, text)
                    if decoded and type(data) == "table" then name = data.name end
                end
            end
            if type(name) ~= "string" then return false, "Auto load disabled" end
            self.autoLoad = name
            return self:LoadConfig(name)
        end)
    end

    function UI:OnUnload(callback)
        if type(callback) == "function" then table.insert(self.unloadCallbacks, callback) end
        return self
    end

    function UI:Destroy()
        if self.destroyed or self.destroying then return end
        self.destroying = true
        safe(function()
            for _, callback in ipairs(self.unloadCallbacks or {}) do invoke(callback) end
            table.clear(self.unloadCallbacks or {})
        end)
        for _, control in ipairs(self.keybinds) do safe(function() control:Reset() end) end
        for _, widget in pairs(self.widgets) do
            if widget.Kind == "Toggle" then
                local ok, v = pcall(widget.Get, widget)
                if ok and v then safe(function() widget:Set(false) end) end
            end
        end
        self.destroyed = true
        self.Unloaded = true
        for _, c in ipairs(self.connections) do pcall(function() c:Disconnect() end) end
        for _, properties in pairs(self.tweens) do
            for _, t in pairs(properties) do pcall(function() t:Cancel() end) end
        end
        table.clear(self.connections)
        table.clear(self.repaint)
        table.clear(self.colorUpdates)
        pcall(function() self.gui:Destroy() end)
        table.clear(self.bindings)
        table.clear(self.keybinds)
        table.clear(self.keybindRows)
    end

    UI.Section = Section
    UI.Version = "2.1.6"
    UI.Description = "SkidUi interface library"
    return UI
end)()

return UI
