local repo = "https://raw.githubusercontent.com/pavelsteam00-cpu/UiLibary1/refs/heads/main/"

local downloadOk, source = pcall(function()
    return game:HttpGet(repo .. "Script.Lua")
end)

if not downloadOk then
    error("SkidUi download failed: " .. tostring(source), 0)
end
if type(source) ~= "string" or #source < 1000 then
    error("SkidUi source is empty or invalid", 0)
end
if source:find("404: Not Found", 1, true) then
    error("SkidUi URL returned 404: " .. repo .. "Script.Lua", 0)
end

local function cleanLibrarySource(text)
    text = text:gsub("^\239\187\191", "")
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    local firstLine, rest = text:match("^([^\n]*)\n(.*)$")
    if firstLine and firstLine:match("^%s*```[%w_%-]*%s*$") then
        text = rest
    end
    text = text:gsub("\n%s*```%s*$", "")
    return text
end

source = cleanLibrarySource(source)

local loadLibrary, compileError = loadstring(source)
if not loadLibrary then
    error("SkidUi compile error: " .. tostring(compileError), 0)
end

local libraryOk, Library = pcall(loadLibrary)
if not libraryOk then
    error("SkidUi initialization failed: " .. tostring(Library), 0)
end
if type(Library) ~= "table" or type(Library.new) ~= "function" then
    error("Invalid SkidUi module: expected a table with Library.new", 0)
end

local environment = type(getgenv) == "function" and getgenv() or _G
if environment.SkidHub and type(environment.SkidHub.Destroy) == "function" then
    pcall(function() environment.SkidHub:Destroy() end)
end

local hub = Library:CreateWindow({
    Title = "Skid hub",
    WatermarkName = "Skid hub",
    ToggleKey = "RightShift",
    ConfigFolder = "SkidHub",
    Accent = Color3.fromRGB(110, 135, 200),
})
environment.SkidHub = hub
environment.SkidUi = Library

pcall(function() hub:SetEasingStyle("Exponential") end)
pcall(function() hub:Notify("Interface loaded successfully") end)

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local Stats       = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local function safe(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, err = pcall(fn, ...)
    if not ok then
        pcall(function() warn("[SkidHub] " .. tostring(err)) end)
    end
    return ok, err
end

local combatColor = Color3.fromRGB(255, 255, 255)
local sharedThickness = 1.5

local aimSettings = {
    enabled      = false,
    method       = "Camera",
    targetType   = "Crosshair",
    hitbox       = "Head",
    fov          = 100,
    smoothing    = 0.5,
    maxDistance  = 1000,
    visibleCheck = false,
    teamCheck    = false,
    onBot        = false,
}

local hitboxSettings = {
    enabled      = false,
    hitbox       = "Head",
    size         = 6,
    transparency = 0.5,
    maxDistance  = 1000,
    visibleCheck = false,
    teamCheck    = false,
    onBot        = false,
}

local visualsSettings = {
    masterEnabled = false,
    maxDistance = 1000,
    boxEnabled = false,
    boxColor = Color3.fromRGB(255, 255, 255),
    boxFilled = false,
    boxFillTransparency = 0.2,
    boxOutline = true,
    nameEnabled = false,
    nameColor = Color3.fromRGB(255, 255, 255),
    nameOutline = true,
    weaponEnabled = false,
    weaponColor = Color3.fromRGB(255, 255, 255),
    weaponOutline = true,
    distanceEnabled = false,
    distanceColor = Color3.fromRGB(255, 255, 255),
    distanceOutline = true,
    healthBarEnabled = false,
    healthBarOutline = true,
    healthTextEnabled = false,
    healthTextOutline = true,
    chamsEnabled = false,
    chamsColor = Color3.fromRGB(255, 255, 255),
    chamsOutline = true,
    skeletonEnabled = false,
    skeletonColor = Color3.fromRGB(255, 255, 255),
}

local visualsTargets = { Player = true, Sleeper = false, Npc = false }
local multiSelectEnabled = true
local wallcheckVisuals = false
local teamCheckVisuals = false

local visibleColorEnabled = false
local visibleColor = Color3.fromRGB(110, 135, 200)
local invisibleColor = Color3.fromRGB(255, 255, 255)

local function getActiveTargets()
    if not multiSelectEnabled then
        return { Player = false, Sleeper = false, Npc = false }
    end
    return {
        Player = visualsTargets.Player == true,
        Sleeper = visualsTargets.Sleeper == true,
        Npc = visualsTargets.Npc == true,
    }
end

local visualsRayParams = RaycastParams.new()
visualsRayParams.FilterType = Enum.RaycastFilterType.Exclude

local aimRayParams = RaycastParams.new()
aimRayParams.FilterType = Enum.RaycastFilterType.Exclude

local aimFilterCam = nil
local aimFilterChar = nil
local function updateAimRayFilter(cam)
    local char = LocalPlayer.Character
    if cam ~= aimFilterCam or char ~= aimFilterChar then
        aimFilterCam = cam
        aimFilterChar = char
        local filter = { cam }
        if char then filter[#filter + 1] = char end
        aimRayParams.FilterDescendantsInstances = filter
    end
end

local visualsFilterTmp = {}
local function updateVisualsRayFilter(cam, model)
    table.clear(visualsFilterTmp)
    visualsFilterTmp[1] = cam
    local char = LocalPlayer.Character
    if char then visualsFilterTmp[#visualsFilterTmp + 1] = char end
    if model then visualsFilterTmp[#visualsFilterTmp + 1] = model end
    visualsRayParams.FilterDescendantsInstances = visualsFilterTmp
end

local PARTS_R15 = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local PARTS_R6 = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

local BONES_R15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local BONES_R6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

local originalHitboxProps = {}
local visualCache = {}
local chamsCache = {}
local skeletonCache = {}

local sleeperVisualCache = {}
local npcVisualCache = {}
local sleeperChamsCache = {}
local sleeperSkeletonCache = {}
local npcChamsCache = {}
local npcSkeletonCache = {}

local connections = {}
local function track(c)
    if c then table.insert(connections, c) end
    return c
end

local hasDrawing = false
pcall(function()
    if Drawing and type(Drawing.new) == "function" then
        local t = Drawing.new("Line")
        if t then hasDrawing = true; t:Remove() end
    end
end)

local function lerpColor(c1, c2, t)
    t = math.clamp(t, 0, 1)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

local function removeAll(list)
    for _, d in ipairs(list) do
        pcall(function() d:Remove() end)
    end
end

local function createChams(character)
    local order = character:FindFirstChild("UpperTorso") and PARTS_R15 or PARTS_R6
    local list = {}
    for _, name in ipairs(order) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local hl = Instance.new("Highlight")
            hl.Name = "Chams_" .. name
            hl.Adornee = part
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillColor = visualsSettings.chamsColor
            hl.FillTransparency = 0.5
            hl.OutlineColor = visualsSettings.chamsColor
            hl.OutlineTransparency = visualsSettings.chamsOutline and 0 or 1
            hl.Parent = part
            list[#list + 1] = hl
        end
    end
    return list
end

local function createSkeleton(character)
    local bones = character:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
    local lines = {}
    for i = 1, #bones do
        local l = Drawing.new("Line")
        l.Color = visualsSettings.skeletonColor
        l.Thickness = 1
        l.Visible = false
        lines[i] = l
    end
    return { lines = lines, bones = bones }
end

local function removeSkeleton(skel)
    if not skel then return end
    if skel.lines then
        for _, line in ipairs(skel.lines) do
            pcall(function() line.Visible = false; line:Remove() end)
        end
    end
end

local npcKeywords = { "guard", "soldier", "scavenger" }
local animalKeywords = { "wolf", "bear", "boar", "deer" }

local function hasAnyKeyword(lower, keywords)
    for _, kw in ipairs(keywords) do
        if lower:find(kw, 1, true) then return true end
    end
    return false
end

local function isHumanoidRig(model)
    if not model or not model:IsA("Model") then return false end
    local head = model:FindFirstChild("Head")
    if not head then return false end
    local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
    if not torso then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function isInsideSleepers(model)
    local current = model.Parent
    while current and current ~= Workspace do
        if current.Name == "Sleepers" or current.Name == "Sleeper" then return true end
        current = current.Parent
    end
    return false
end

local function isNpcModel(model)
    if not model or not model:IsA("Model") then return false end
    if model == LocalPlayer.Character then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then return false end
    end
    if not isHumanoidRig(model) then return false end
    if isInsideSleepers(model) then return false end
    local lower = model.Name:lower()
    if hasAnyKeyword(lower, animalKeywords) then return false end
    if hasAnyKeyword(lower, npcKeywords) then return true end
    return false
end

local sharedBotList = {}
local sharedBotTimer = 0
local sharedBotRefresh = 0.25
local botFolderNames = { "Npc", "Npcs", "NPC", "NPCs", "Bots", "Enemies", "Mobs", "Ai", "AI" }

local function collectBotsFrom(container, list)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Model") then
            if isNpcModel(child) then table.insert(list, child) end
        elseif child:IsA("Folder") then
            collectBotsFrom(child, list)
        end
    end
end

local function refreshSharedBots()
    local now = os.clock()
    if now - sharedBotTimer < sharedBotRefresh then return sharedBotList end
    sharedBotTimer = now
    local list = {}
    pcall(function()
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") then
                if isNpcModel(child) then table.insert(list, child) end
            end
        end
        for _, name in ipairs(botFolderNames) do
            local f = Workspace:FindFirstChild(name)
            if f and f:IsA("Folder") then
                collectBotsFrom(f, list)
            end
        end
    end)
    sharedBotList = list
    return list
end

local function isValidPlayer(plr, teamCheck)
    if not plr or plr == LocalPlayer then return false end
    if teamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local hitboxNames = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

local function getAimPart(char, mousePos, cam)
    if not char then return nil end
    if aimSettings.hitbox == "Head" then
        return char:FindFirstChild("Head")
    elseif aimSettings.hitbox == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif aimSettings.hitbox == "Root" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        local best, bestDist = nil, math.huge
        for _, name in ipairs(hitboxNames) do
            local part = char:FindFirstChild(name)
            if part then
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dx = sp.X - mousePos.X
                    local dy = sp.Y - mousePos.Y
                    local d = math.sqrt(dx * dx + dy * dy)
                    if d < bestDist then bestDist = d; best = part end
                end
            end
        end
        return best
    end
end

local function evaluateAimTarget(char, mousePos, cam, camPos, fov, maxDist, checkVisible, currentBest, currentBestScore)
    local root = char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
    if not root then return currentBest, currentBestScore end
    local worldDist = (root.Position - camPos).Magnitude
    if worldDist > maxDist then return currentBest, currentBestScore end
    local aimPart = getAimPart(char, mousePos, cam)
    if not aimPart or not aimPart.Parent then return currentBest, currentBestScore end
    local sp, onScreen = cam:WorldToViewportPoint(aimPart.Position)
    if not onScreen or sp.Z <= 0 then return currentBest, currentBestScore end
    local dx = sp.X - mousePos.X
    local dy = sp.Y - mousePos.Y
    local partDist = math.sqrt(dx * dx + dy * dy)
    if partDist > fov then return currentBest, currentBestScore end
    if checkVisible then
        local dir = aimPart.Position - camPos
        if dir.Magnitude > 0.001 then
            local vres = Workspace:Raycast(camPos, dir, aimRayParams)
            if vres and not vres.Instance:IsDescendantOf(char) then
                return currentBest, currentBestScore
            end
        end
    end
    local score = (aimSettings.targetType == "Crosshair") and partDist or worldDist
    if score < currentBestScore then return aimPart, score end
    return currentBest, currentBestScore
end

local function getTarget(mousePos)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    updateAimRayFilter(cam)
    local fov = aimSettings.fov
    local maxDist = aimSettings.maxDistance
    local checkVis = aimSettings.visibleCheck
    local camPos = cam.CFrame.Position
    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValidPlayer(plr, aimSettings.teamCheck) then
            local char = plr.Character
            if char and char.Parent then
                best, bestScore = evaluateAimTarget(char, mousePos, cam, camPos, fov, maxDist, checkVis, best, bestScore)
            end
        end
    end
    if aimSettings.onBot then
        local bots = refreshSharedBots()
        for _, bot in ipairs(bots) do
            if bot and bot.Parent then
                local hum = bot:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    best, bestScore = evaluateAimTarget(bot, mousePos, cam, camPos, fov, maxDist, checkVis, best, bestScore)
                end
            end
        end
    end
    return best
end

local function aimAt(target)
    local cam = Workspace.CurrentCamera
    if not cam or not target or not target.Parent then return end
    local camPos = cam.CFrame.Position
    local delta = target.Position - camPos
    if delta.Magnitude < 0.1 then return end
    local alpha
    if aimSettings.smoothing <= 0 then
        alpha = 1
    else
        alpha = math.clamp(1 - aimSettings.smoothing, 0.05, 1)
    end
    if aimSettings.method == "Camera" then
        pcall(function()
            cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(camPos, target.Position), alpha)
        end)
    else
        if typeof(mousemoverel) ~= "function" then return end
        local sp = cam:WorldToViewportPoint(target.Position)
        if not sp or sp.Z <= 0 then return end
        local mp = UIS:GetMouseLocation()
        pcall(mousemoverel, (sp.X - mp.X) * alpha, (sp.Y - mp.Y) * alpha)
    end
end

local isRightClick = false
track(UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then isRightClick = true end
end))
track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then isRightClick = false end
end))

local function isRmbHeld()
    local ok, pressed = pcall(function()
        return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end)
    if ok and pressed ~= nil then return pressed end
    return isRightClick
end

local fovCount = 60
local fovParts = {}
local fovStyle = "Circle"
local fovColor1 = combatColor
local fovColor2 = combatColor
local fovAlpha1 = 0
local fovAlpha2 = 0
local fovCircleEnabled = true
local fovCurrentlyVisible = false
local lastFovCx, lastFovCy, lastFovR, lastFovStyle = -1, -1, -1, nil

local fovCosA0, fovSinA0, fovCosA1, fovSinA1, fovMidCos = {}, {}, {}, {}, {}
for i = 1, fovCount do
    local a0 = ((i - 1) / fovCount) * math.pi * 2
    local a1 = (i / fovCount) * math.pi * 2
    local mid = (a0 + a1) / 2
    fovCosA0[i] = math.cos(a0); fovSinA0[i] = math.sin(a0)
    fovCosA1[i] = math.cos(a1); fovSinA1[i] = math.sin(a1)
    fovMidCos[i] = math.cos(mid)
end

local function buildFov()
    removeAll(fovParts)
    fovParts = {}
    fovCurrentlyVisible = false
    lastFovCx, lastFovCy, lastFovR, lastFovStyle = -1, -1, -1, nil
    if not hasDrawing then return end
    for i = 1, fovCount do
        local ok, d
        if fovStyle == "Dotted" then
            ok, d = pcall(Drawing.new, "Circle")
            if ok and d then
                d.Filled = true; d.Thickness = 0; d.Radius = 1.5; d.Transparency = 1
                d.Color = lerpColor(fovColor1, fovColor2, (fovMidCos[i] + 1) / 2)
                d.Visible = false
                fovParts[i] = d
            end
        else
            ok, d = pcall(Drawing.new, "Line")
            if ok and d then
                d.Thickness = sharedThickness; d.Transparency = 1
                d.Color = lerpColor(fovColor1, fovColor2, (fovMidCos[i] + 1) / 2)
                d.Visible = false
                fovParts[i] = d
            end
        end
    end
end

local function applyFovAlpha()
    if not hasDrawing then return end
    local transparency = 1 - (fovAlpha1 or 0)
    pcall(function()
        for i = 1, fovCount do
            local d = fovParts[i]
            if d then
                d.Transparency = transparency
            end
        end
    end)
end

local function updateFovColors()
    if not hasDrawing then return end
    pcall(function()
        for i = 1, fovCount do
            local d = fovParts[i]
            if d then
                d.Color = lerpColor(fovColor1, fovColor2, (fovMidCos[i] + 1) / 2)
                d.Transparency = 1 - (fovAlpha1 or 0)
            end
        end
    end)
end

buildFov()
applyFovAlpha()

local function hideFov()
    if not fovCurrentlyVisible then return end
    fovCurrentlyVisible = false
    lastFovCx, lastFovCy, lastFovR, lastFovStyle = -1, -1, -1, nil
    pcall(function()
        for _, d in ipairs(fovParts) do
            if d and d.Visible then d.Visible = false end
        end
    end)
end

local function updateFov(mousePos)
    if not (aimSettings.enabled and fovCircleEnabled) then hideFov(); return end
    local r = aimSettings.fov
    local cx, cy = mousePos.X, mousePos.Y
    if fovCurrentlyVisible and lastFovCx == cx and lastFovCy == cy and lastFovR == r and lastFovStyle == fovStyle then return end
    lastFovCx, lastFovCy, lastFovR, lastFovStyle = cx, cy, r, fovStyle
    fovCurrentlyVisible = true
    if fovStyle == "Dotted" then
        pcall(function()
            for i = 1, fovCount do
                local d = fovParts[i]
                if d then
                    d.Position = Vector2.new(cx + fovCosA0[i] * r, cy + fovSinA0[i] * r)
                    if not d.Visible then d.Visible = true end
                end
            end
        end)
    else
        pcall(function()
            for i = 1, fovCount do
                local d = fovParts[i]
                if d then
                    d.From = Vector2.new(cx + fovCosA0[i] * r, cy + fovSinA0[i] * r)
                    d.To   = Vector2.new(cx + fovCosA1[i] * r, cy + fovSinA1[i] * r)
                    if not d.Visible then d.Visible = true end
                end
            end
        end)
    end
end

local targetLineEnabled = false
local targetLineColor1 = combatColor
local targetLineColor2 = combatColor
local targetLineAlpha = 0
local targetLineDrawings = {}
local targetLineSegments = 30
local lineCurrentlyVisible = false
local lastLineFromX, lastLineFromY = -1, -1
local lastLineToX, lastLineToY = -1, -1
local lastLineColor1, lastLineColor2 = nil, nil
local lastLineAlpha = 0

if hasDrawing then
    for i = 1, targetLineSegments do
        local ok, d = pcall(Drawing.new, "Line")
        if ok and d then
            d.Thickness = sharedThickness; d.Transparency = 1; d.Visible = false
            targetLineDrawings[i] = d
        end
    end
end

local function hideTargetLine()
    if not lineCurrentlyVisible then return end
    lineCurrentlyVisible = false
    lastLineFromX, lastLineFromY, lastLineToX, lastLineToY = -1, -1, -1, -1
    lastLineColor1, lastLineColor2 = nil, nil
    lastLineAlpha = 0
    pcall(function()
        for i = 1, targetLineSegments do
            local d = targetLineDrawings[i]
            if d and d.Visible then d.Visible = false end
        end
    end)
end

local function updateTargetLine(fromPos, toPos)
    local dist = (toPos - fromPos).Magnitude
    if dist < 1 then hideTargetLine(); return end
    if lineCurrentlyVisible
        and lastLineFromX == fromPos.X and lastLineFromY == fromPos.Y
        and lastLineToX == toPos.X and lastLineToY == toPos.Y
        and lastLineColor1 == targetLineColor1 and lastLineColor2 == targetLineColor2
        and lastLineAlpha == targetLineAlpha then
        return
    end
    lastLineFromX, lastLineFromY = fromPos.X, fromPos.Y
    lastLineToX, lastLineToY = toPos.X, toPos.Y
    lastLineColor1, lastLineColor2 = targetLineColor1, targetLineColor2
    lastLineAlpha = targetLineAlpha
    lineCurrentlyVisible = true
    local activeSegments = math.min(targetLineSegments, math.max(1, math.floor(dist)))
    pcall(function()
        for i = 1, targetLineSegments do
            local d = targetLineDrawings[i]
            if d then
                if i <= activeSegments then
                    local t0 = (i - 1) / activeSegments
                    local t1 = i / activeSegments
                    d.From = fromPos:Lerp(toPos, t0)
                    d.To   = fromPos:Lerp(toPos, t1)
                    d.Color = lerpColor(targetLineColor1, targetLineColor2, t0)
                    d.Transparency = 1 - targetLineAlpha
                    if not d.Visible then d.Visible = true end
                else
                    if d.Visible then d.Visible = false end
                end
            end
        end
    end)
end

local targetIconEnabled = false
local targetIconColor1 = combatColor
local targetIconColor2 = combatColor
local targetIconAlpha = 0
local targetIconLines = {}
local targetIconSegments = 24
local iconCurrentlyVisible = false
local lastIconX, lastIconY = -1, -1
local lastIconColor1, lastIconColor2 = nil, nil
local lastIconAlpha = 0
local iconRadius = 8
local iconCosA0, iconSinA0, iconCosA1, iconSinA1, iconT = {}, {}, {}, {}, {}
for i = 1, targetIconSegments do
    local a0 = ((i - 1) / targetIconSegments) * math.pi * 2
    local a1 = (i / targetIconSegments) * math.pi * 2
    iconCosA0[i] = math.cos(a0); iconSinA0[i] = math.sin(a0)
    iconCosA1[i] = math.cos(a1); iconSinA1[i] = math.sin(a1)
    iconT[i] = (math.cos((a0 + a1) / 2) + 1) / 2
end

if hasDrawing then
    for i = 1, targetIconSegments do
        local ok, d = pcall(Drawing.new, "Line")
        if ok and d then
            d.Thickness = sharedThickness; d.Transparency = 1; d.Visible = false
            targetIconLines[i] = d
        end
    end
end

local function hideTargetIcon()
    if not iconCurrentlyVisible then return end
    iconCurrentlyVisible = false
    lastIconX, lastIconY = -1, -1
    lastIconColor1, lastIconColor2 = nil, nil
    lastIconAlpha = 0
    pcall(function()
        for i = 1, targetIconSegments do
            local d = targetIconLines[i]
            if d and d.Visible then d.Visible = false end
        end
    end)
end

local function updateTargetIcon(screenPos, visible)
    if not visible then hideTargetIcon(); return end
    if iconCurrentlyVisible
        and lastIconX == screenPos.X and lastIconY == screenPos.Y
        and lastIconColor1 == targetIconColor1 and lastIconColor2 == targetIconColor2
        and lastIconAlpha == targetIconAlpha then
        return
    end
    lastIconX, lastIconY = screenPos.X, screenPos.Y
    lastIconColor1, lastIconColor2 = targetIconColor1, targetIconColor2
    lastIconAlpha = targetIconAlpha
    iconCurrentlyVisible = true
    pcall(function()
        for i = 1, targetIconSegments do
            local d = targetIconLines[i]
            if d then
                d.From  = Vector2.new(screenPos.X + iconCosA0[i] * iconRadius, screenPos.Y + iconSinA0[i] * iconRadius)
                d.To    = Vector2.new(screenPos.X + iconCosA1[i] * iconRadius, screenPos.Y + iconSinA1[i] * iconRadius)
                d.Color = lerpColor(targetIconColor1, targetIconColor2, iconT[i])
                d.Transparency = 1 - targetIconAlpha
                if not d.Visible then d.Visible = true end
            end
        end
    end)
end

local function restoreHitbox(part)
    local props = originalHitboxProps[part]
    if props then
        pcall(function()
            part.Size = props.Size
            part.Material = props.Material
            part.Color = props.Color
            part.Transparency = props.Transparency
            part.CanCollide = props.CanCollide
        end)
        originalHitboxProps[part] = nil
    end
end

local function restoreAllHitboxes()
    for part, _ in pairs(originalHitboxProps) do
        restoreHitbox(part)
    end
end

local function processHitbox()
    if not hitboxSettings.enabled then
        restoreAllHitboxes()
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local mousePos = UIS:GetMouseLocation()

    updateAimRayFilter(cam)

    local validTargets = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if isValidPlayer(plr, hitboxSettings.teamCheck) then
            table.insert(validTargets, plr.Character)
        end
    end

    if hitboxSettings.onBot then
        local bots = refreshSharedBots()
        for _, bot in ipairs(bots) do
            if bot and bot.Parent then
                local hum = bot:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(validTargets, bot)
                end
            end
        end
    end

    local targetParts = {}
    local hbMode = hitboxSettings.hitbox
    local hbMaxDist = hitboxSettings.maxDistance
    local hbVisCheck = hitboxSettings.visibleCheck

    for _, char in ipairs(validTargets) do
        if char then
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            if root then
                local dist = (root.Position - camPos).Magnitude
                if dist <= hbMaxDist then
                    local partToExpand = nil
                    if hbMode == "Head" then
                        partToExpand = char:FindFirstChild("Head")
                    elseif hbMode == "Torso" then
                        partToExpand = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                    elseif hbMode == "Root" then
                        partToExpand = char:FindFirstChild("HumanoidRootPart")
                    elseif hbMode == "Nearest" then
                        local bestPart, bestDist = nil, math.huge
                        for _, name in ipairs(hitboxNames) do
                            local p = char:FindFirstChild(name)
                            if p then
                                local sp, onScreen = cam:WorldToViewportPoint(p.Position)
                                if onScreen then
                                    local dx = sp.X - mousePos.X
                                    local dy = sp.Y - mousePos.Y
                                    local d = math.sqrt(dx*dx + dy*dy)
                                    if d < bestDist then
                                        bestDist = d
                                        bestPart = p
                                    end
                                end
                            end
                        end
                        partToExpand = bestPart
                    end

                    if partToExpand and partToExpand:IsA("BasePart") then
                        local visible = true
                        if hbVisCheck then
                            local dir = partToExpand.Position - camPos
                            if dir.Magnitude > 0.001 then
                                local vres = Workspace:Raycast(camPos, dir, aimRayParams)
                                if vres and not vres.Instance:IsDescendantOf(char) then
                                    visible = false
                                end
                            end
                        end

                        if visible then
                            targetParts[partToExpand] = true
                        end
                    end
                end
            end
        end
    end

    local hbSize = math.max(0.1, hitboxSettings.size)
    local hbTransparency = hitboxSettings.transparency
    local newSize = Vector3.new(hbSize, hbSize, hbSize)
    local whiteColor = Color3.fromRGB(255, 255, 255)
    local forceField = Enum.Material.ForceField

    for part, _ in pairs(targetParts) do
        if not originalHitboxProps[part] then
            originalHitboxProps[part] = {
                Size = part.Size,
                Material = part.Material,
                Color = part.Color,
                Transparency = part.Transparency,
                CanCollide = part.CanCollide
            }
        end
        pcall(function()
            part.Size = newSize
            part.Material = forceField
            part.Color = whiteColor
            part.Transparency = hbTransparency
            part.CanCollide = false
        end)
    end

    for part, _ in pairs(originalHitboxProps) do
        if not part or not part.Parent or not targetParts[part] then
            restoreHitbox(part)
        end
    end
end

local function makeVisualEntry(name)
    local boxFill = Drawing.new("Square")
    boxFill.Thickness = 0; boxFill.Filled = true; boxFill.Color = visualsSettings.boxColor; boxFill.Transparency = visualsSettings.boxFillTransparency; boxFill.Visible = false

    local boxBorder = Drawing.new("Square")
    boxBorder.Thickness = 1; boxBorder.Filled = false; boxBorder.Color = visualsSettings.boxColor; boxBorder.Visible = false

    local boxOutline = Drawing.new("Square")
    boxOutline.Thickness = 1; boxOutline.Filled = false; boxOutline.Color = Color3.new(0, 0, 0); boxOutline.Visible = false

    local nameText = Drawing.new("Text")
    nameText.Size = 12; nameText.Center = true; nameText.Outline = true; nameText.Color = visualsSettings.nameColor; nameText.Visible = false; nameText.Text = name

    local weaponText = Drawing.new("Text")
    weaponText.Size = 12; weaponText.Center = true; weaponText.Outline = true; weaponText.Color = visualsSettings.weaponColor; weaponText.Visible = false; weaponText.Text = "None"

    local distanceText = Drawing.new("Text")
    distanceText.Size = 12; distanceText.Center = true; distanceText.Outline = true; distanceText.Color = visualsSettings.distanceColor; distanceText.Visible = false

    local healthBg = Drawing.new("Square")
    healthBg.Thickness = 0; healthBg.Filled = true; healthBg.Color = Color3.new(0, 0, 0); healthBg.Visible = false

    local healthFill = Drawing.new("Square")
    healthFill.Thickness = 0; healthFill.Filled = true; healthFill.Visible = false

    local healthText = Drawing.new("Text")
    healthText.Size = 10; healthText.Center = false; healthText.Outline = true; healthText.Visible = false; healthText.Text = "100"

    return {
        boxFill = boxFill, boxBorder = boxBorder, boxOutline = boxOutline,
        nameText = nameText, weaponText = weaponText, distanceText = distanceText,
        healthBg = healthBg, healthFill = healthFill, healthText = healthText,
        char = nil, root = nil, hum = nil, isR15 = nil,
        lastW = "None", lastD = -1, lastHp = -1,
        lastBoxX = -9999, lastBoxY = -9999, lastBoxW = -1, lastBoxH = -1,
        lastNameX = -9999, lastNameY = -9999,
        lastWeaponX = -9999, lastWeaponY = -9999,
        lastDistX = -9999, lastDistY = -9999,
        lastHealthX = -9999, lastHealthY = -9999, lastHealthH = -1,
        isVisible = false
    }
end

local function addVisualCache(p)
    if p == LocalPlayer or visualCache[p] then return end
    if not hasDrawing then return end
    visualCache[p] = makeVisualEntry(p.Name)
end

local function removeVisualCache(p)
    local e = visualCache[p]
    if not e then return end
    pcall(function()
        e.boxFill:Remove()
        e.boxBorder:Remove()
        e.boxOutline:Remove()
        e.nameText:Remove()
        e.weaponText:Remove()
        e.distanceText:Remove()
        e.healthBg:Remove()
        e.healthFill:Remove()
        e.healthText:Remove()
    end)
    visualCache[p] = nil
end

local function addModelVisualCache(model, displayName, cacheTable)
    if cacheTable[model] then return end
    if not hasDrawing then return end
    cacheTable[model] = makeVisualEntry(displayName)
end

local function removeModelVisualCache(model, cacheTable)
    local e = cacheTable[model]
    if not e then return end
    pcall(function()
        e.boxFill:Remove()
        e.boxBorder:Remove()
        e.boxOutline:Remove()
        e.nameText:Remove()
        e.weaponText:Remove()
        e.distanceText:Remove()
        e.healthBg:Remove()
        e.healthFill:Remove()
        e.healthText:Remove()
    end)
    cacheTable[model] = nil
end

local function hideVisualCache(e)
    if not e or not e.isVisible then return end
    e.isVisible = false
    e.boxFill.Visible = false
    e.boxBorder.Visible = false
    e.boxOutline.Visible = false
    e.nameText.Visible = false
    e.weaponText.Visible = false
    e.distanceText.Visible = false
    e.healthBg.Visible = false
    e.healthFill.Visible = false
    e.healthText.Visible = false
end

local function renderEntityVisual(e, model, lp, cam, md2)
    if not e then return end
    if not model or not model.Parent then hideVisualCache(e); return end

    if e.char ~= model then
        e.char = model
        e.root = nil
        e.hum = nil
        e.isR15 = nil
        e.lastW = "None"
        e.lastD = -1
        e.lastHp = -1
        e.lastBoxX = -9999; e.lastBoxY = -9999; e.lastBoxW = -1; e.lastBoxH = -1
        e.lastNameX = -9999; e.lastNameY = -9999
        e.lastWeaponX = -9999; e.lastWeaponY = -9999
        e.lastDistX = -9999; e.lastDistY = -9999
    end

    local r = e.root
    if not r or r.Parent ~= model then
        r = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
        e.root = r
    end

    local h = e.hum
    if not h or h.Parent ~= model then
        h = model:FindFirstChildOfClass("Humanoid")
        e.hum = h
    end

    if not r or not h or h.Health <= 0 then
        hideVisualCache(e)
        return
    end

    local dx, dy, dz = lp.X - r.Position.X, lp.Y - r.Position.Y, lp.Z - r.Position.Z
    if dx * dx + dy * dy + dz * dz > md2 then
        hideVisualCache(e)
        return
    end

    local isVisible = true
    if wallcheckVisuals or visibleColorEnabled then
        local camPos = cam.CFrame.Position
        local dir = r.Position - camPos
        if dir.Magnitude > 0.001 then
            updateVisualsRayFilter(cam, model)
            local hit = Workspace:Raycast(camPos, dir, visualsRayParams)
            if hit and not hit.Instance:IsDescendantOf(model) then
                isVisible = false
            end
        end
    end

    if wallcheckVisuals and not isVisible then
        hideVisualCache(e)
        return
    end

    local currentBoxColor = visualsSettings.boxColor
    local currentNameColor = visualsSettings.nameColor
    local currentWeaponColor = visualsSettings.weaponColor
    local currentDistanceColor = visualsSettings.distanceColor

    if visibleColorEnabled then
        local col = isVisible and visibleColor or invisibleColor
        currentBoxColor = col
        currentNameColor = col
        currentWeaponColor = col
        currentDistanceColor = col
    end

    local isR15 = e.isR15
    if isR15 == nil then
        isR15 = model:FindFirstChild("UpperTorso") ~= nil
        e.isR15 = isR15
    end

    local bodyParts = isR15 and PARTS_R15 or PARTS_R6

    local minWX, minWY, minWZ = math.huge, math.huge, math.huge
    local maxWX, maxWY, maxWZ = -math.huge, -math.huge, -math.huge
    local foundAny = false

    for i = 1, #bodyParts do
        local part = model:FindFirstChild(bodyParts[i])
        if part then
            foundAny = true
            local p = part.Position
            local s = part.Size
            local hx, hy, hz = s.X * 0.5, s.Y * 0.5, s.Z * 0.5
            local px1, px2 = p.X - hx, p.X + hx
            local py1, py2 = p.Y - hy, p.Y + hy
            local pz1, pz2 = p.Z - hz, p.Z + hz
            if px1 < minWX then minWX = px1 end
            if px2 > maxWX then maxWX = px2 end
            if py1 < minWY then minWY = py1 end
            if py2 > maxWY then maxWY = py2 end
            if pz1 < minWZ then minWZ = pz1 end
            if pz2 > maxWZ then maxWZ = pz2 end
        end
    end

    if not foundAny then
        hideVisualCache(e)
        return
    end

    local minSX, minSY, maxSX, maxSY = math.huge, math.huge, -math.huge, -math.huge
    local validCount = 0

    for xi = 0, 1 do
        local wx = xi == 0 and minWX or maxWX
        for yi = 0, 1 do
            local wy = yi == 0 and minWY or maxWY
            for zi = 0, 1 do
                local wz = zi == 0 and minWZ or maxWZ
                local sp = cam:WorldToViewportPoint(Vector3.new(wx, wy, wz))
                if sp.Z > 0 then
                    validCount = validCount + 1
                    if sp.X < minSX then minSX = sp.X end
                    if sp.X > maxSX then maxSX = sp.X end
                    if sp.Y < minSY then minSY = sp.Y end
                    if sp.Y > maxSY then maxSY = sp.Y end
                end
            end
        end
    end

    if validCount < 4 then
        hideVisualCache(e)
        return
    end

    local cw = math.max(1, math.round(maxSX - minSX))
    local ch = math.max(1, math.round(maxSY - minSY))
    local x = math.round(minSX)
    local y = math.round(minSY)
    local cx = x + cw * 0.5
    local anyVisible = false

    if visualsSettings.boxEnabled then
        if e.lastBoxX ~= x or e.lastBoxY ~= y or e.lastBoxW ~= cw or e.lastBoxH ~= ch then
            e.lastBoxX, e.lastBoxY, e.lastBoxW, e.lastBoxH = x, y, cw, ch
            e.boxFill.Size = Vector2.new(cw, ch)
            e.boxFill.Position = Vector2.new(x, y)
            e.boxBorder.Size = Vector2.new(cw, ch)
            e.boxBorder.Position = Vector2.new(x, y)
            e.boxOutline.Size = Vector2.new(cw + 2, ch + 2)
            e.boxOutline.Position = Vector2.new(x - 1, y - 1)
        end
        e.boxFill.Color = currentBoxColor
        e.boxFill.Transparency = visualsSettings.boxFillTransparency

        e.boxFill.Visible = visualsSettings.boxFilled and true or false
        e.boxOutline.Visible = visualsSettings.boxOutline and true or false
        e.boxBorder.Color = currentBoxColor
        e.boxBorder.Visible = true
        anyVisible = true
    else
        if e.boxFill.Visible then e.boxFill.Visible = false end
        if e.boxBorder.Visible then e.boxBorder.Visible = false end
        if e.boxOutline.Visible then e.boxOutline.Visible = false end
    end

    if visualsSettings.weaponEnabled then
        local tool = model:FindFirstChildOfClass("Tool")
        local wname = tool and tool.Name or "None"
        if e.lastW ~= wname then e.weaponText.Text = wname; e.lastW = wname end
        local py = y + ch + 1
        if e.lastWeaponX ~= cx or e.lastWeaponY ~= py then
            e.lastWeaponX, e.lastWeaponY = cx, py
            e.weaponText.Position = Vector2.new(cx, py)
        end
        e.weaponText.Color = currentWeaponColor
        e.weaponText.Outline = visualsSettings.weaponOutline
        e.weaponText.Visible = true
        anyVisible = true
    else
        if e.weaponText.Visible then e.weaponText.Visible = false end
    end

    if visualsSettings.nameEnabled then
        local py = y - 16
        if e.lastNameX ~= cx or e.lastNameY ~= py then
            e.lastNameX, e.lastNameY = cx, py
            e.nameText.Position = Vector2.new(cx, py)
        end
        e.nameText.Color = currentNameColor
        e.nameText.Outline = visualsSettings.nameOutline
        e.nameText.Visible = true
        anyVisible = true
    else
        if e.nameText.Visible then e.nameText.Visible = false end
    end

    if visualsSettings.distanceEnabled then
        local dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
        if e.lastD ~= dist then e.distanceText.Text = dist .. "m"; e.lastD = dist end
        local py = y + ch + 14
        if e.lastDistX ~= cx or e.lastDistY ~= py then
            e.lastDistX, e.lastDistY = cx, py
            e.distanceText.Position = Vector2.new(cx, py)
        end
        e.distanceText.Color = currentDistanceColor
        e.distanceText.Outline = visualsSettings.distanceOutline
        e.distanceText.Visible = true
        anyVisible = true
    else
        if e.distanceText.Visible then e.distanceText.Visible = false end
    end

    if visualsSettings.healthBarEnabled then
        local hp = h.Health / math.max(h.MaxHealth, 1)
        if hp < 0 then hp = 0 elseif hp > 1 then hp = 1 end
        local barW = 3
        local barX = x - barW - 3
        local barY = y - 1
        local barH = ch + 2
        local fillH = barH * hp
        local fillY = barY + barH - fillH

        if e.lastHealthX ~= barX or e.lastHealthY ~= barY or e.lastHealthH ~= barH then
            e.lastHealthX, e.lastHealthY, e.lastHealthH = barX, barY, barH
            e.healthBg.Position = Vector2.new(barX - 1, barY - 1)
            e.healthBg.Size = Vector2.new(barW + 2, barH + 2)
        end
        e.healthBg.Visible = visualsSettings.healthBarOutline

        e.healthFill.Position = Vector2.new(barX, fillY)
        e.healthFill.Size = Vector2.new(barW, fillH)
        e.healthFill.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
        e.healthFill.Visible = true
        anyVisible = true
    else
        if e.healthBg.Visible then e.healthBg.Visible = false end
        if e.healthFill.Visible then e.healthFill.Visible = false end
    end

    if visualsSettings.healthTextEnabled then
        local hp = h.Health / math.max(h.MaxHealth, 1)
        if hp < 0 then hp = 0 elseif hp > 1 then hp = 1 end
        local barW = 3
        local barX = x - barW - 3
        local barY = y - 1
        local hpInt = math.floor(hp * 100 + 0.5)
        if e.lastHp ~= hpInt then e.healthText.Text = tostring(hpInt); e.lastHp = hpInt end
        e.healthText.Color = Color3.fromRGB(255, 255, 255)
        e.healthText.Position = Vector2.new(barX - 19, barY - 2)
        e.healthText.Outline = visualsSettings.healthTextOutline
        e.healthText.Visible = true
        anyVisible = true
    else
        if e.healthText.Visible then e.healthText.Visible = false end
    end

    e.isVisible = anyVisible
end

local visualsWereEnabled = false

local function updateVisuals()
    if not visualsSettings.masterEnabled then
        if visualsWereEnabled then
            for _, e in pairs(visualCache) do hideVisualCache(e) end
            for _, e in pairs(sleeperVisualCache) do hideVisualCache(e) end
            for _, e in pairs(npcVisualCache) do hideVisualCache(e) end
            visualsWereEnabled = false
        end
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then return end
    local lpc = LocalPlayer.Character
    local lpr = lpc and lpc:FindFirstChild("HumanoidRootPart")
    if not lpr then return end

    visualsWereEnabled = true

    local lp = lpr.Position
    local maxDist = visualsSettings.maxDistance
    local md2 = maxDist * maxDist
    local targets = getActiveTargets()

    if targets.Player then
        for p, e in pairs(visualCache) do
            local c = p.Character
            if c and c.Parent then
                if teamCheckVisuals and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                    hideVisualCache(e)
                else
                    renderEntityVisual(e, c, lp, cam, md2)
                end
            else
                hideVisualCache(e)
            end
        end
    elseif visualsWereEnabled then
        for _, e in pairs(visualCache) do hideVisualCache(e) end
    end

    if targets.Sleeper then
        for model, e in pairs(sleeperVisualCache) do
            if model.Parent then
                renderEntityVisual(e, model, lp, cam, md2)
            else
                hideVisualCache(e)
            end
        end
    else
        for _, e in pairs(sleeperVisualCache) do hideVisualCache(e) end
    end

    if targets.Npc then
        for model, e in pairs(npcVisualCache) do
            if model.Parent then
                renderEntityVisual(e, model, lp, cam, md2)
            else
                hideVisualCache(e)
            end
        end
    else
        for _, e in pairs(npcVisualCache) do hideVisualCache(e) end
    end
end

local function updateChamsForModel(model, e, cam)
    if not model or not model.Parent then
        if e.list then
            for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
            e.list = nil
        end
        return
    end

    local root = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")

    local lpc = LocalPlayer.Character
    local lpr = lpc and lpc:FindFirstChild("HumanoidRootPart")
    if root and lpr then
        local delta = root.Position - lpr.Position
        local md2 = visualsSettings.maxDistance * visualsSettings.maxDistance
        if delta.X * delta.X + delta.Y * delta.Y + delta.Z * delta.Z > md2 then
            if e.list then
                for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                e.list = nil
            end
            return
        end
    end

    if wallcheckVisuals and cam and root then
        local camPos = cam.CFrame.Position
        local dir = root.Position - camPos
        if dir.Magnitude > 0.001 then
            updateVisualsRayFilter(cam, model)
            local hit = Workspace:Raycast(camPos, dir, visualsRayParams)
            if hit and not hit.Instance:IsDescendantOf(model) then
                if e.list then
                    for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                    e.list = nil
                end
                return
            end
        end
    end

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        if not e.list then
            safe(function() e.list = createChams(model) end)
        end
        if e.list then
            local chamsColor = visualsSettings.chamsColor
            local outlineTransparency = visualsSettings.chamsOutline and 0 or 1
            for _, hl in ipairs(e.list) do
                hl.FillColor = chamsColor
                hl.OutlineColor = chamsColor
                hl.OutlineTransparency = outlineTransparency
            end
        end
    else
        if e.list then
            for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
            e.list = nil
        end
    end
end

local function updateChams()
    if not visualsSettings.chamsEnabled or not visualsSettings.masterEnabled then
        for p, e in pairs(chamsCache) do
            if e.list then
                for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                e.list = nil
            end
        end
        for model, e in pairs(sleeperChamsCache) do
            if e.list then
                for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                e.list = nil
            end
        end
        for model, e in pairs(npcChamsCache) do
            if e.list then
                for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                e.list = nil
            end
        end
        return
    end

    local cam = Workspace.CurrentCamera
    local targets = getActiveTargets()

    if targets.Player then
        for p, e in pairs(chamsCache) do
            local show = p.Character and p.Character.Parent
            if show and teamCheckVisuals and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                show = false
            end
            if show then
                safe(function() updateChamsForModel(p.Character, e, cam) end)
            else
                if e.list then
                    for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                    e.list = nil
                end
            end
        end
    else
        for _, e in pairs(chamsCache) do
            if e.list then
                for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                e.list = nil
            end
        end
    end

    if targets.Sleeper then
        for model, e in pairs(sleeperChamsCache) do
            safe(function() updateChamsForModel(model, e, cam) end)
        end
    else
        for _, e in pairs(sleeperChamsCache) do
            if e.list then
                for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                e.list = nil
            end
        end
    end

    if targets.Npc then
        for model, e in pairs(npcChamsCache) do
            safe(function() updateChamsForModel(model, e, cam) end)
        end
    else
        for _, e in pairs(npcChamsCache) do
            if e.list then
                for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                e.list = nil
            end
        end
    end
end

local function updateSkeletonForModel(model, e, cam)
    if not model or not model.Parent then
        if e.skel then
            for _, line in ipairs(e.skel.lines) do line.Visible = false end
        end
        return
    end

    local root = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")

    local lpc = LocalPlayer.Character
    local lpr = lpc and lpc:FindFirstChild("HumanoidRootPart")
    if root and lpr then
        local delta = root.Position - lpr.Position
        local md2 = visualsSettings.maxDistance * visualsSettings.maxDistance
        if delta.X * delta.X + delta.Y * delta.Y + delta.Z * delta.Z > md2 then
            if e.skel then
                for _, line in ipairs(e.skel.lines) do line.Visible = false end
            end
            return
        end
    end

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        if not e.skel then
            safe(function() e.skel = createSkeleton(model) end)
        end
        if e.skel then
            local skelColor = visualsSettings.skeletonColor
            for i, pair in ipairs(e.skel.bones) do
                local p1 = model:FindFirstChild(pair[1])
                local p2 = model:FindFirstChild(pair[2])
                if p1 and p2 then
                    local sp1, on1 = cam:WorldToViewportPoint(p1.Position)
                    local sp2, on2 = cam:WorldToViewportPoint(p2.Position)
                    if on1 and on2 and sp1.Z > 0 and sp2.Z > 0 then
                        local l = e.skel.lines[i]
                        l.From = Vector2.new(sp1.X, sp1.Y)
                        l.To = Vector2.new(sp2.X, sp2.Y)
                        l.Color = skelColor
                        l.Visible = true
                    else
                        e.skel.lines[i].Visible = false
                    end
                else
                    e.skel.lines[i].Visible = false
                end
            end
        end
    else
        if e.skel then
            for _, line in ipairs(e.skel.lines) do line.Visible = false end
        end
    end
end

local function updateSkeleton()
    if not visualsSettings.skeletonEnabled or not visualsSettings.masterEnabled then
        for _, e in pairs(skeletonCache) do
            if e.skel then
                for _, line in ipairs(e.skel.lines) do
                    if line.Visible then line.Visible = false end
                end
            end
        end
        for _, e in pairs(sleeperSkeletonCache) do
            if e.skel then
                for _, line in ipairs(e.skel.lines) do
                    if line.Visible then line.Visible = false end
                end
            end
        end
        for _, e in pairs(npcSkeletonCache) do
            if e.skel then
                for _, line in ipairs(e.skel.lines) do
                    if line.Visible then line.Visible = false end
                end
            end
        end
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then return end
    local targets = getActiveTargets()

    if targets.Player then
        for p, e in pairs(skeletonCache) do
            local show = p.Character and p.Character.Parent
            if show and teamCheckVisuals and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                show = false
            end
            if show then
                safe(function() updateSkeletonForModel(p.Character, e, cam) end)
            else
                if e.skel then
                    for _, line in ipairs(e.skel.lines) do line.Visible = false end
                end
            end
        end
    else
        for _, e in pairs(skeletonCache) do
            if e.skel then
                for _, line in ipairs(e.skel.lines) do line.Visible = false end
            end
        end
    end

    if targets.Sleeper then
        for model, e in pairs(sleeperSkeletonCache) do
            safe(function() updateSkeletonForModel(model, e, cam) end)
        end
    else
        for _, e in pairs(sleeperSkeletonCache) do
            if e.skel then
                for _, line in ipairs(e.skel.lines) do line.Visible = false end
            end
        end
    end

    if targets.Npc then
        for model, e in pairs(npcSkeletonCache) do
            safe(function() updateSkeletonForModel(model, e, cam) end)
        end
    else
        for _, e in pairs(npcSkeletonCache) do
            if e.skel then
                for _, line in ipairs(e.skel.lines) do line.Visible = false end
            end
        end
    end
end

local SLEEPER_NAME = "Sleeper"

local function scanSleepers()
    safe(function()
        local targets = getActiveTargets()

        if not visualsSettings.masterEnabled or not targets.Sleeper then
            for model in pairs(sleeperVisualCache) do
                removeModelVisualCache(model, sleeperVisualCache)
            end
            for model, e in pairs(sleeperChamsCache) do
                if e.list then
                    for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                end
                sleeperChamsCache[model] = nil
            end
            for model, e in pairs(sleeperSkeletonCache) do
                if e.skel then removeSkeleton(e.skel) end
                sleeperSkeletonCache[model] = nil
            end
            return
        end

        local folder = Workspace:FindFirstChild("Sleepers") or Workspace:FindFirstChild("Sleeper")
        if not folder then
            folder = Workspace:FindFirstChild("Sleepers", true) or Workspace:FindFirstChild("Sleeper", true)
        end
        local found = {}
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") and isHumanoidRig(child) then
                    found[child] = true
                end
            end
        end

        for model in pairs(sleeperVisualCache) do
            if not found[model] or not model.Parent then
                removeModelVisualCache(model, sleeperVisualCache)
            end
        end
        for model, e in pairs(sleeperChamsCache) do
            if not found[model] or not model.Parent then
                if e.list then
                    for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                end
                sleeperChamsCache[model] = nil
            end
        end
        for model, e in pairs(sleeperSkeletonCache) do
            if not found[model] or not model.Parent then
                if e.skel then removeSkeleton(e.skel) end
                sleeperSkeletonCache[model] = nil
            end
        end

        for model in pairs(found) do
            if not sleeperVisualCache[model] then
                addModelVisualCache(model, SLEEPER_NAME, sleeperVisualCache)
            end
            if not sleeperChamsCache[model] then
                sleeperChamsCache[model] = { list = nil }
            end
            if not sleeperSkeletonCache[model] then
                sleeperSkeletonCache[model] = { skel = nil }
            end
        end
    end)
end

local function scanNpcs()
    safe(function()
        local targets = getActiveTargets()

        if not visualsSettings.masterEnabled or not targets.Npc then
            for model in pairs(npcVisualCache) do
                removeModelVisualCache(model, npcVisualCache)
            end
            for model, e in pairs(npcChamsCache) do
                if e.list then
                    for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                end
                npcChamsCache[model] = nil
            end
            for model, e in pairs(npcSkeletonCache) do
                if e.skel then removeSkeleton(e.skel) end
                npcSkeletonCache[model] = nil
            end
            return
        end

        local bots = refreshSharedBots()
        local found = {}
        for _, bot in ipairs(bots) do
            if bot and bot.Parent and isHumanoidRig(bot) then
                found[bot] = true
            end
        end

        for model in pairs(npcVisualCache) do
            if not found[model] or not model.Parent then
                removeModelVisualCache(model, npcVisualCache)
            end
        end
        for model, e in pairs(npcChamsCache) do
            if not found[model] or not model.Parent then
                if e.list then
                    for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                end
                npcChamsCache[model] = nil
            end
        end
        for model, e in pairs(npcSkeletonCache) do
            if not found[model] or not model.Parent then
                if e.skel then removeSkeleton(e.skel) end
                npcSkeletonCache[model] = nil
            end
        end

        for model in pairs(found) do
            if not npcVisualCache[model] then
                addModelVisualCache(model, model.Name, npcVisualCache)
            end
            if not npcChamsCache[model] then
                npcChamsCache[model] = { list = nil }
            end
            if not npcSkeletonCache[model] then
                npcSkeletonCache[model] = { skel = nil }
            end
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    addVisualCache(p)
    if p ~= LocalPlayer then
        chamsCache[p] = { list = nil }
        skeletonCache[p] = { skel = nil }
    end
end

track(Players.PlayerAdded:Connect(function(p)
    safe(function()
        addVisualCache(p)
        if p ~= LocalPlayer then
            chamsCache[p] = { list = nil }
            skeletonCache[p] = { skel = nil }
        end
    end)
end))

track(Players.PlayerRemoving:Connect(function(p)
    safe(function()
        removeVisualCache(p)
        if chamsCache[p] then
            if chamsCache[p].list then
                for _, hl in ipairs(chamsCache[p].list) do pcall(function() hl:Destroy() end) end
            end
            chamsCache[p] = nil
        end
        if skeletonCache[p] then
            if skeletonCache[p].skel then
                removeSkeleton(skeletonCache[p].skel)
            end
            skeletonCache[p] = nil
        end
    end)
end))

local combatPage = hub:Page("Combat", "crosshair")
local aimbotTab = combatPage:Tab("Combat")

local rageGroup = aimbotTab:Section("Aimbot", 1)

rageGroup:AddToggle("Aimbot_toggle", {
    Text = "Enable aimbot",
    Default = false,
    Callback = function(Value)
        aimSettings.enabled = Value == true
        if not Value then hideFov() end
        safe(function() hub:Notify("Aimbot", "Enable aimbot: " .. (Value and "On" or "Off")) end)
    end,
}):AddKeyPicker("Aimbot_keybind", {
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Enable aimbot",
})

rageGroup:AddDropdown("Aimbot_method", {
    Values = { "Camera", "Mouse" },
    Default = 1,
    Multi = false,
    Text = "Aimbot method",
    Callback = function(Value) aimSettings.method = Value end,
})

rageGroup:AddDropdown("Aimbot_targetType", {
    Values = { "Crosshair", "Nearest" },
    Default = 1,
    Multi = false,
    Text = "Aimbot target type",
    Callback = function(Value) aimSettings.targetType = Value end,
})

rageGroup:AddDropdown("Aimbot_hitbox", {
    Values = { "Head", "Torso", "Root", "Nearest" },
    Default = 1,
    Multi = false,
    Text = "Aimbot hitbox",
    Callback = function(Value) aimSettings.hitbox = Value end,
})

rageGroup:AddSlider("Aimbot_fov", {
    Text = "Aimbot field of view",
    Default = 100,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) aimSettings.fov = Value end,
})

rageGroup:AddSlider("Aimbot_smoothing", {
    Text = "Aimbot smoothing",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,
    Callback = function(Value) aimSettings.smoothing = Value end,
})

rageGroup:AddSlider("Aimbot_maxDistance", {
    Text = "Aimbot max distance",
    Default = 1000,
    Min = 0,
    Max = 2000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) aimSettings.maxDistance = Value end,
})

rageGroup:AddToggle("Aimbot_visibleCheck", {
    Text = "Aimbot visible check",
    Default = false,
    Callback = function(Value) aimSettings.visibleCheck = Value == true end,
})

rageGroup:AddToggle("Aimbot_teamCheck", {
    Text = "Aimbot team check",
    Default = false,
    Callback = function(Value) aimSettings.teamCheck = Value == true end,
})

rageGroup:AddToggle("Aimbot_onBot", {
    Text = "Aimbot work on bot",
    Default = false,
    Callback = function(Value) aimSettings.onBot = Value == true end,
})

local settingsGroup = aimbotTab:Section("Aimbot settings", 2)

local fovToggle = settingsGroup:AddToggle("FovCircle_toggle", {
    Text = "Field of view circle",
    Default = true,
    Callback = function(Value)
        fovCircleEnabled = Value == true
        if not Value then hideFov() end
    end,
})
local fovCp1 = fovToggle:AddColorPicker("Fov_color1", {
    Default = combatColor,
    Title = "Fov color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        fovColor1 = Value
        fovAlpha1 = Alpha or 0
        updateFovColors()
    end,
})
local fovCp2 = fovToggle:AddColorPicker("Fov_color2", {
    Default = combatColor,
    Title = "Fov gradient",
    Transparency = 1,
    Callback = function(Value, Alpha)
        fovColor2 = Value
        fovAlpha2 = Alpha or 0
        updateFovColors()
    end,
})

settingsGroup:AddDropdown("Fov_style", {
    Values = { "Circle", "Dotted" },
    Default = 1,
    Multi = false,
    Text = "Field of view style",
    Callback = function(Value)
        fovStyle = Value
        buildFov()
        applyFovAlpha()
    end,
})

local lineToggle = settingsGroup:AddToggle("TargetLine_toggle", {
    Text = "Target line",
    Default = false,
    Callback = function(Value)
        targetLineEnabled = Value == true
        if not Value then hideTargetLine() end
    end,
})
local lineCp1 = lineToggle:AddColorPicker("TargetLine_color1", {
    Default = combatColor,
    Title = "Target line",
    Transparency = 1,
    Callback = function(Value, Alpha)
        targetLineColor1 = Value
        targetLineAlpha = Alpha or 0
    end,
})
local lineCp2 = lineToggle:AddColorPicker("TargetLine_color2", {
    Default = combatColor,
    Title = "Target line gradient",
    Transparency = 1,
    Callback = function(Value, Alpha)
        targetLineColor2 = Value
        if Alpha and Alpha ~= 1 then targetLineAlpha = Alpha end
    end,
})

local iconToggle = settingsGroup:AddToggle("TargetIcon_toggle", {
    Text = "Target icon",
    Default = false,
    Callback = function(Value)
        targetIconEnabled = Value == true
        if not Value then hideTargetIcon() end
    end,
})
local iconCp1 = iconToggle:AddColorPicker("TargetIcon_color1", {
    Default = combatColor,
    Title = "Target icon",
    Transparency = 1,
    Callback = function(Value, Alpha)
        targetIconColor1 = Value
        targetIconAlpha = Alpha or 0
    end,
})
local iconCp2 = iconToggle:AddColorPicker("TargetIcon_color2", {
    Default = combatColor,
    Title = "Target icon gradient",
    Transparency = 1,
    Callback = function(Value, Alpha)
        targetIconColor2 = Value
        if Alpha and Alpha ~= 1 then targetIconAlpha = Alpha end
    end,
})

local semiRageTab = combatPage:Tab("Semi-rage")

local hitboxGroup = semiRageTab:Section("Hitbox expander", 1)

hitboxGroup:AddToggle("HitboxExpander_toggle", {
    Text = "Enable hitbox expander",
    Default = false,
    Callback = function(Value)
        hitboxSettings.enabled = Value == true
        if not Value then restoreAllHitboxes() end
        safe(function() hub:Notify("Hitbox expander", "Enable hitbox expander: " .. (Value and "On" or "Off")) end)
    end,
}):AddKeyPicker("HitboxExpander_keybind", {
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Enable hitbox expander",
})

hitboxGroup:AddDropdown("HitboxExpander_hitbox", {
    Values = { "Head", "Torso", "Root", "Nearest" },
    Default = 1,
    Multi = false,
    Text = "Hitbox expander hitbox",
    Callback = function(Value) hitboxSettings.hitbox = Value end,
})

hitboxGroup:AddSlider("HitboxExpander_size", {
    Text = "Hitbox expander size",
    Default = 6,
    Min = 0,
    Max = 10,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) hitboxSettings.size = Value end,
})

hitboxGroup:AddSlider("HitboxExpander_transparency", {
    Text = "Hitbox expander transparency",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,
    Callback = function(Value) hitboxSettings.transparency = Value end,
})

hitboxGroup:AddSlider("HitboxExpander_maxDistance", {
    Text = "Hitbox expander max distance",
    Default = 1000,
    Min = 0,
    Max = 2000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) hitboxSettings.maxDistance = Value end,
})

hitboxGroup:AddToggle("HitboxExpander_visibleCheck", {
    Text = "Hitbox expander visible check",
    Default = false,
    Callback = function(Value) hitboxSettings.visibleCheck = Value == true end,
})

hitboxGroup:AddToggle("HitboxExpander_teamCheck", {
    Text = "Hitbox expander team check",
    Default = false,
    Callback = function(Value) hitboxSettings.teamCheck = Value == true end,
})

hitboxGroup:AddToggle("HitboxExpander_onBot", {
    Text = "Hitbox expander work on bot",
    Default = false,
    Callback = function(Value) hitboxSettings.onBot = Value == true end,
})

local visualsPage = hub:Page("Visuals", "eye")

local playerVisualsTab = visualsPage:Tab("Player visuals")

local pvsGroup = playerVisualsTab:Section("Player Visuals Settings", 2)

pvsGroup:AddToggle("Visuals_multiSelect_toggle", {
    Text = "Enable Multi Selection",
    Default = true,
    Callback = function(Value)
        multiSelectEnabled = Value == true
    end,
})

pvsGroup:AddDropdown("Visuals_targets_dropdown", {
    Values = { "Player", "Sleeper", "Npc" },
    Default = { "Player" },
    Multi = true,
    Text = "Target",
    Callback = function(Value)
        local newTargets = { Player = false, Sleeper = false, Npc = false }
        if type(Value) == "table" then
            for _, name in ipairs(Value) do
                if newTargets[name] ~= nil then
                    newTargets[name] = true
                end
            end
            for k, v in pairs(Value) do
                if type(k) == "string" and newTargets[k] ~= nil then
                    newTargets[k] = v and true or false
                end
            end
        elseif type(Value) == "string" then
            if newTargets[Value] ~= nil then
                newTargets[Value] = true
            end
        end
        visualsTargets = newTargets
    end,
})

pvsGroup:AddToggle("Visuals_visibleCheck_toggle", {
    Text = "Player Visuals Visible Check",
    Default = false,
    Callback = function(Value)
        wallcheckVisuals = Value == true
    end,
})

pvsGroup:AddToggle("Visuals_teamCheck_toggle", {
    Text = "Player Visuals Team Check",
    Default = false,
    Callback = function(Value)
        teamCheckVisuals = Value == true
    end,
})

local visibleColorToggle = pvsGroup:AddToggle("Visuals_visibleColor_toggle", {
    Text = "Enable Visible Color",
    Default = false,
    Callback = function(Value)
        visibleColorEnabled = Value == true
    end,
})

visibleColorToggle:AddColorPicker("Visuals_invisibleColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Invisible Color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        invisibleColor = Value
    end,
})

visibleColorToggle:AddColorPicker("Visuals_visibleColor", {
    Default = Color3.fromRGB(110, 135, 200),
    Title = "Visible Color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        visibleColor = Value
    end,
})

pvsGroup:AddSlider("Visuals_maxDistance", {
    Text = "Max distance",
    Default = 1000,
    Min = 0,
    Max = 2000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) visualsSettings.maxDistance = Value end,
})

local playerVisGroup = playerVisualsTab:Section("Player visuals", 1)

playerVisGroup:AddToggle("Visuals_master_toggle", {
    Text = "Enable player visuals",
    Default = false,
    Callback = function(Value)
        visualsSettings.masterEnabled = Value == true
        if not Value then
            for _, caches in ipairs({chamsCache, sleeperChamsCache, npcChamsCache}) do
                for _, e in pairs(caches) do
                    if e.list then
                        for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                        e.list = nil
                    end
                end
            end
            for _, caches in ipairs({skeletonCache, sleeperSkeletonCache, npcSkeletonCache}) do
                for _, e in pairs(caches) do
                    if e.skel then
                        for _, line in ipairs(e.skel.lines) do line.Visible = false end
                    end
                end
            end
        end
        safe(function() hub:Notify("Player visuals", "Enable player visuals: " .. (Value and "On" or "Off")) end)
    end,
}):AddKeyPicker("Visuals_master_keybind", {
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Enable player visuals",
})

local boxToggle = playerVisGroup:AddToggle("Visuals_box_toggle", {
    Text = "Enable box",
    Default = false,
    Callback = function(Value) visualsSettings.boxEnabled = Value == true end,
})
boxToggle:AddColorPicker("Visuals_box_color", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Box color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        visualsSettings.boxColor = Value
        safe(function()
            for _, e in pairs(visualCache) do
                e.boxFill.Color = Value
                e.boxBorder.Color = Value
            end
            for _, e in pairs(sleeperVisualCache) do
                e.boxFill.Color = Value
                e.boxBorder.Color = Value
            end
            for _, e in pairs(npcVisualCache) do
                e.boxFill.Color = Value
                e.boxBorder.Color = Value
            end
        end)
    end,
})
boxToggle:AddSettings("Box", {
    Build = function(settingsTab)
        settingsTab:Toggle({
            Text = "Enable outline",
            Default = true,
            Callback = function(Value) visualsSettings.boxOutline = Value == true end,
        })
    end,
})

playerVisGroup:AddToggle("Visuals_boxFilled_toggle", {
    Text = "Enable box filled",
    Default = false,
    Callback = function(Value) visualsSettings.boxFilled = Value == true end,
})

playerVisGroup:AddSlider("Visuals_boxFillTransparency", {
    Text = "Box filled transparency",
    Default = 0.2,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,
    Callback = function(Value) visualsSettings.boxFillTransparency = Value end,
})

local weaponToggle = playerVisGroup:AddToggle("Visuals_weapon_toggle", {
    Text = "Enable weapon",
    Default = false,
    Callback = function(Value) visualsSettings.weaponEnabled = Value == true end,
})
weaponToggle:AddColorPicker("Visuals_weapon_color", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Weapon color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        visualsSettings.weaponColor = Value
        safe(function()
            for _, e in pairs(visualCache) do e.weaponText.Color = Value end
            for _, e in pairs(sleeperVisualCache) do e.weaponText.Color = Value end
            for _, e in pairs(npcVisualCache) do e.weaponText.Color = Value end
        end)
    end,
})
weaponToggle:AddSettings("Weapon", {
    Build = function(settingsTab)
        settingsTab:Toggle({
            Text = "Enable outline",
            Default = true,
            Callback = function(Value) visualsSettings.weaponOutline = Value == true end,
        })
    end,
})

local nameToggle = playerVisGroup:AddToggle("Visuals_name_toggle", {
    Text = "Enable name",
    Default = false,
    Callback = function(Value) visualsSettings.nameEnabled = Value == true end,
})
nameToggle:AddColorPicker("Visuals_name_color", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Name color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        visualsSettings.nameColor = Value
        safe(function()
            for _, e in pairs(visualCache) do e.nameText.Color = Value end
            for _, e in pairs(sleeperVisualCache) do e.nameText.Color = Value end
            for _, e in pairs(npcVisualCache) do e.nameText.Color = Value end
        end)
    end,
})
nameToggle:AddSettings("Name", {
    Build = function(settingsTab)
        settingsTab:Toggle({
            Text = "Enable outline",
            Default = true,
            Callback = function(Value) visualsSettings.nameOutline = Value == true end,
        })
    end,
})

local distanceToggle = playerVisGroup:AddToggle("Visuals_distance_toggle", {
    Text = "Enable distance",
    Default = false,
    Callback = function(Value) visualsSettings.distanceEnabled = Value == true end,
})
distanceToggle:AddColorPicker("Visuals_distance_color", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Distance color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        visualsSettings.distanceColor = Value
        safe(function()
            for _, e in pairs(visualCache) do e.distanceText.Color = Value end
            for _, e in pairs(sleeperVisualCache) do e.distanceText.Color = Value end
            for _, e in pairs(npcVisualCache) do e.distanceText.Color = Value end
        end)
    end,
})
distanceToggle:AddSettings("Distance", {
    Build = function(settingsTab)
        settingsTab:Toggle({
            Text = "Enable outline",
            Default = true,
            Callback = function(Value) visualsSettings.distanceOutline = Value == true end,
        })
    end,
})

local healthBarToggle = playerVisGroup:AddToggle("Visuals_healthBar_toggle", {
    Text = "Enable health bar",
    Default = false,
    Callback = function(Value) visualsSettings.healthBarEnabled = Value == true end,
})
healthBarToggle:AddSettings("Health bar", {
    Build = function(settingsTab)
        settingsTab:Toggle({
            Text = "Enable outline",
            Default = true,
            Callback = function(Value) visualsSettings.healthBarOutline = Value == true end,
        })
    end,
})

local healthTextToggle = playerVisGroup:AddToggle("Visuals_healthText_toggle", {
    Text = "Enable health text",
    Default = false,
    Callback = function(Value) visualsSettings.healthTextEnabled = Value == true end,
})
healthTextToggle:AddSettings("Health text", {
    Build = function(settingsTab)
        settingsTab:Toggle({
            Text = "Enable outline",
            Default = true,
            Callback = function(Value) visualsSettings.healthTextOutline = Value == true end,
        })
    end,
})

local chamsToggle = playerVisGroup:AddToggle("Visuals_chams_toggle", {
    Text = "Enable chams",
    Default = false,
    Callback = function(Value)
        visualsSettings.chamsEnabled = Value == true
        if not Value then
            safe(function()
                for p, e in pairs(chamsCache) do
                    if e.list then
                        for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                        e.list = nil
                    end
                end
                for model, e in pairs(sleeperChamsCache) do
                    if e.list then
                        for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                        e.list = nil
                    end
                end
                for model, e in pairs(npcChamsCache) do
                    if e.list then
                        for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
                        e.list = nil
                    end
                end
            end)
        end
    end,
})

chamsToggle:AddColorPicker("Visuals_chams_color", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Chams color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        visualsSettings.chamsColor = Value
        safe(function()
            for p, e in pairs(chamsCache) do
                if e.list then
                    for _, hl in ipairs(e.list) do
                        hl.FillColor = Value
                        hl.OutlineColor = Value
                    end
                end
            end
            for model, e in pairs(sleeperChamsCache) do
                if e.list then
                    for _, hl in ipairs(e.list) do
                        hl.FillColor = Value
                        hl.OutlineColor = Value
                    end
                end
            end
            for model, e in pairs(npcChamsCache) do
                if e.list then
                    for _, hl in ipairs(e.list) do
                        hl.FillColor = Value
                        hl.OutlineColor = Value
                    end
                end
            end
        end)
    end,
})

chamsToggle:AddSettings("Chams", {
    Build = function(settingsTab)
        settingsTab:Toggle({
            Text = "Enable outline",
            Default = true,
            Callback = function(Value)
                visualsSettings.chamsOutline = Value == true
                safe(function()
                    for p, e in pairs(chamsCache) do
                        if e.list then
                            for _, hl in ipairs(e.list) do
                                hl.OutlineTransparency = Value and 0 or 1
                            end
                        end
                    end
                    for model, e in pairs(sleeperChamsCache) do
                        if e.list then
                            for _, hl in ipairs(e.list) do
                                hl.OutlineTransparency = Value and 0 or 1
                            end
                        end
                    end
                    for model, e in pairs(npcChamsCache) do
                        if e.list then
                            for _, hl in ipairs(e.list) do
                                hl.OutlineTransparency = Value and 0 or 1
                            end
                        end
                    end
                end)
            end,
        })
    end,
})

local skeletonToggle = playerVisGroup:AddToggle("Visuals_skeleton_toggle", {
    Text = "Enable skeleton",
    Default = false,
    Callback = function(Value)
        visualsSettings.skeletonEnabled = Value == true
        if not Value then
            safe(function()
                for _, e in pairs(skeletonCache) do
                    if e.skel then
                        for _, line in ipairs(e.skel.lines) do line.Visible = false end
                    end
                end
                for _, e in pairs(sleeperSkeletonCache) do
                    if e.skel then
                        for _, line in ipairs(e.skel.lines) do line.Visible = false end
                    end
                end
                for _, e in pairs(npcSkeletonCache) do
                    if e.skel then
                        for _, line in ipairs(e.skel.lines) do line.Visible = false end
                    end
                end
            end)
        end
    end,
})

skeletonToggle:AddColorPicker("Visuals_skeleton_color", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Skeleton color",
    Transparency = 1,
    Callback = function(Value, Alpha)
        visualsSettings.skeletonColor = Value
        safe(function()
            for p, e in pairs(skeletonCache) do
                if e.skel then
                    for _, line in ipairs(e.skel.lines) do
                        line.Color = Value
                    end
                end
            end
            for model, e in pairs(sleeperSkeletonCache) do
                if e.skel then
                    for _, line in ipairs(e.skel.lines) do
                        line.Color = Value
                    end
                end
            end
            for model, e in pairs(npcSkeletonCache) do
                if e.skel then
                    for _, line in ipairs(e.skel.lines) do
                        line.Color = Value
                    end
                end
            end
        end)
    end,
})

local playerPage = hub:Page("Players", "person")
local playerTab = playerPage:Tab("Players")
safe(function() hub:PlayerTable(playerTab) end)

local settingsPage = hub:Page("Settings", "settings")
local configTab = settingsPage:Tab("Config")
local configs = configTab:Section("Configs", 1)
local names = configs:List({
    Text = "Configs",
    Options = hub:ListConfigs(),
    Searchable = false,
    Height = 260,
})
local configInput = configs:Input({Text = "Config name", Placeholder = "Name...", Save = false})
local function configName()
    return configInput:Get() ~= "" and configInput:Get() or names:Get() or "default"
end
local function refreshConfigs() safe(function() names:SetOptions(hub:ListConfigs()) end) end
local function result(ok, err, message)
    safe(function() hub:Notify(ok and "Success!" or "Error", ok and message or tostring(err)) end)
end
configs:ButtonPair(
    {Text = "Save", Callback = function()
        local n = configName()
        local ok, err = hub:SaveConfig(n)
        result(ok, err, "Saved " .. n .. ".json")
        refreshConfigs()
    end},
    {Text = "Load", Callback = function()
        local n = configName()
        local ok, err = hub:LoadConfig(n)
        result(ok, err, "Loaded " .. n .. ".json successfully")
    end}
)
configs:ButtonPair(
    {Text = "Delete", Callback = function()
        local ok, err = hub:DeleteConfig(configName())
        result(ok, err, "Config deleted")
        refreshConfigs()
    end},
    {Text = "Refresh", Callback = refreshConfigs}
)
local auto = configs:Toggle({
    Text = "Auto load config",
    Save = false,
    FireOnInit = false,
    Callback = function(v)
        local ok, err = hub:SetAutoLoad(v and configName() or nil)
        if not ok then safe(function() hub:Notify("Error", err) end) end
    end,
})

local menu = configTab:Section("Menu", 2, {MaxHeight = 234})
local menuBind = menu:Keybind({
    Text = "Menu bind",
    Default = "RightShift",
    Callback = function() safe(function() hub:Toggle() end) end,
})
if menuBind then
    menuBind.AlwaysInList = true
    menuBind.IsActive = function(self) return hub.visible end
end

menu:Dropdown({
    Text = "Notification position",
    Options = {"Top left", "Top middle", "Top right", "Bottom left", "Bottom middle", "Bottom right"},
    Default = "Bottom left",
    Callback = function(v) safe(function() hub:SetNotificationPosition(v) end) end,
})
menu:Button({Text = "Reset positions", Callback = function() safe(function() hub:ResetPositions() end) end})
menu:Toggle({
    Text = "Watermark",
    Default = true,
    Flag = "hud_watermark",
    Callback = function(value) safe(function() hub:SetWatermarkVisible(value) end) end,
})
menu:Toggle({
    Text = "Keybinds list",
    Default = true,
    Flag = "hud_keybinds",
    Callback = function(value) safe(function() hub:SetKeybindListVisible(value) end) end,
})
menu:Toggle({
    Text = "Target HUD",
    Default = true,
    Flag = "hud_target",
    Callback = function(value) safe(function() hub:SetTargetHUDVisible(value) end) end,
})
menu:Toggle({
    Text = "Moderators List",
    Default = true,
    Flag = "hud_moderators",
    Callback = function(value) safe(function() hub:SetModeratorsVisible(value) end) end,
})
menu:Dropdown({
    Text = "Easing style",
    Options = {"Exponential", "Quad", "Sine", "Linear"},
    Default = "Exponential",
    Callback = function(v) safe(function() hub:SetEasingStyle(v) end) end,
})

local theme = configTab:Section("Theming", 2, {MaxHeight = 236})
for _, entry in ipairs({
    {"Accent", "accent", Color3.fromRGB(110, 135, 200)},
    {"Background", "background", Color3.fromRGB(8, 8, 8)},
    {"Section background", "panel", Color3.fromRGB(12, 12, 12)},
    {"Other backgrounds", "raised", Color3.fromRGB(19, 19, 19)},
    {"Low contrast", "hover", Color3.fromRGB(27, 27, 28)},
    {"Outline", "outline", Color3.fromRGB(26, 26, 29)},
    {"Text", "text", Color3.fromRGB(242, 242, 244)},
    {"Muted text", "muted", Color3.fromRGB(151, 151, 154)},
}) do
    local role = entry[2]
    theme:Colorpicker({
        Text = entry[1],
        Default = entry[3],
        Transparency = 1,
        Callback = function(color) safe(function() hub:SetThemeColor(role, color) end) end,
    })
end

local renderTimer = 0
local scanTimer = 0
local SCAN_INTERVAL = 0.5
local RENDER_INTERVAL = 1/144

safe(function() hub:SetModerators({}) end)

do
    local function safeDetectModerators()
        local mods = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local isMod = false
                if p:GetAttribute("IsAdmin") or p:GetAttribute("Admin") or p:GetAttribute("Moderator") or p:GetAttribute("Staff") then
                    isMod = true
                end
                if not isMod and p.Team then
                    local teamName = p.Team.Name:lower()
                    if teamName:find("mod") or teamName:find("admin") or teamName:find("staff") then
                        isMod = true
                    end
                end
                if not isMod and p.Character then
                    if p.Character:FindFirstChild("AdminTag") or p.Character:FindFirstChild("ModeratorTag") or p.Character:FindFirstChild("StaffTag") then
                        isMod = true
                    end
                    local head = p.Character:FindFirstChild("Head")
                    if head and (head:FindFirstChild("Admin") or head:FindFirstChild("Moderator") or head:FindFirstChild("Staff")) then
                        isMod = true
                    end
                end
                if isMod then
                    table.insert(mods, p.Name)
                end
            end
        end
        return mods
    end

    task.spawn(function()
        task.wait(3)
        local lastKey = ""
        while environment.SkidHub == hub and not hub.destroyed do
            local ok, mods = pcall(safeDetectModerators)
            if ok and mods then
                local key = table.concat(mods, "\0")
                if key ~= lastKey then
                    lastKey = key
                    pcall(function() hub:SetModerators(mods) end)
                end
            end
            task.wait(45)
        end
    end)
end

track(RunService.RenderStepped:Connect(function(dt)
    safe(function()
        if environment.SkidHub ~= hub then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local okMouse, mousePos = pcall(UIS.GetMouseLocation, UIS)
        if not okMouse or not mousePos then return end

        local target
        if aimSettings.enabled then
            target = getTarget(mousePos)
            if target and target.Parent and isRmbHeld() and LocalPlayer.Character then
                local myHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if myHum and myHum.Health > 0 then aimAt(target) end
            end
        end

        if target and target.Parent then
            local char = target.Parent
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local plr = Players:GetPlayerFromCharacter(char)
                local name = plr and plr.Name or char.Name
                local status = "Visible"

                local camPos = cam.CFrame.Position
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                if root then
                    local dir = root.Position - camPos
                    if dir.Magnitude > 0.001 then
                        updateVisualsRayFilter(cam, char)
                        local hit = Workspace:Raycast(camPos, dir, visualsRayParams)
                        if hit and not hit.Instance:IsDescendantOf(char) then
                            status = "Unvisible"
                        end
                    end
                end

                if plr and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                    status = "Teammate"
                end
                hub:SetTarget(name, status, hum.Health / hum.MaxHealth, plr)
            else
                hub:SetTarget(nil)
            end
        else
            hub:SetTarget(nil)
        end

        scanTimer = scanTimer + dt
        if scanTimer >= SCAN_INTERVAL then
            scanTimer = 0
            scanSleepers()
            scanNpcs()
        end

        renderTimer = renderTimer + dt
        if renderTimer < RENDER_INTERVAL then return end
        renderTimer = 0

        processHitbox()
        updateVisuals()
        updateChams()
        updateSkeleton()

        if aimSettings.enabled and fovCircleEnabled then updateFov(mousePos) else hideFov() end

        local targetScreenPos
        if target and target.Parent then
            local sp, onScreen = cam:WorldToViewportPoint(target.Position)
            if onScreen and sp.Z > 0 then
                targetScreenPos = Vector2.new(sp.X, sp.Y)
            end
        end

        if targetLineEnabled and targetScreenPos then updateTargetLine(mousePos, targetScreenPos) else hideTargetLine() end
        if targetIconEnabled and targetScreenPos then updateTargetIcon(targetScreenPos, true) else hideTargetIcon() end
    end)
end))

hub:OnUnload(function()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    safe(hideFov)
    safe(hideTargetLine)
    safe(hideTargetIcon)
    safe(restoreAllHitboxes)
    pcall(removeAll, fovParts)
    pcall(removeAll, targetLineDrawings)
    pcall(removeAll, targetIconLines)
    for p, e in pairs(visualCache) do
        safe(function() removeVisualCache(p) end)
    end
    for model, e in pairs(sleeperVisualCache) do
        safe(function() removeModelVisualCache(model, sleeperVisualCache) end)
    end
    for model, e in pairs(npcVisualCache) do
        safe(function() removeModelVisualCache(model, npcVisualCache) end)
    end
    for p, e in pairs(chamsCache) do
        if e.list then
            for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
        end
    end
    for model, e in pairs(sleeperChamsCache) do
        if e.list then
            for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
        end
    end
    for model, e in pairs(npcChamsCache) do
        if e.list then
            for _, hl in ipairs(e.list) do pcall(function() hl:Destroy() end) end
        end
    end
    for p, e in pairs(skeletonCache) do
        if e.skel then removeSkeleton(e.skel) end
    end
    for model, e in pairs(sleeperSkeletonCache) do
        if e.skel then removeSkeleton(e.skel) end
    end
    for model, e in pairs(npcSkeletonCache) do
        if e.skel then removeSkeleton(e.skel) end
    end
end)

for _, p in ipairs(hub.pages) do
    for _, t in ipairs(p.tabs) do
        t.slot.Visible = (p == hub.selectedPage)
    end
end

safe(function() hub:Select(combatPage, aimbotTab) end)
local loaded = hub:LoadAuto()
if loaded then safe(function() auto:Set(true, true) end) end

return hub
