pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "💥",
        Text = "D3STRUA-S4 ROBLOX",
        Duration = 7
    })
end)

local getservice    = game.GetService
local findfirstchild = game.FindFirstChild
local waitforchild  = game.WaitForChild
local getattribute  = game.GetAttribute
local players       = getservice(game, "Players")
local replicatedstorage = getservice(game, "ReplicatedStorage")
local runservice    = getservice(game, "RunService")
local uis           = getservice(game, "UserInputService")

local localplayer = players.LocalPlayer
local folders = { Events = waitforchild(replicatedstorage, "Events") }
local events = {
    HitEvent    = waitforchild(folders.Events, "HitEvent"),
    CombatEvent = waitforchild(folders.Events, "CombatEvent")
}
local HitEvent    = events.HitEvent
local CombatEvent = events.CombatEvent

getgenv().killAuraEnabled  = false
getgenv().loopGotoSelected = false
getgenv().loopGotoClosest  = false

local selectedTargetName = ""  -- persiste através de mortes/respawns
local lockedClosestPlayer = nil

-- ────────────────────────────────────────────────
--  CONFIGURAÇÃO DE ESPAÇAMENTO
-- ────────────────────────────────────────────────
local GOTO_DISTANCE   = 2.8  -- distância normal (player em pé)
local DOWNED_DISTANCE = 3.5  -- distância quando oponente está caído

-- ────────────────────────────────────────────────
--  HELPERS
-- ────────────────────────────────────────────────

-- Retorna true se o personagem está caído (saúde <= 0)
local function isPlayerDowned(character)
    if not character then return false end
    local humanoid = findfirstchild(character, "Humanoid")
    return humanoid ~= nil and humanoid.Health <= 0
end

-- Retorna o player vivo mais próximo do local player
local function getClosestTarget()
    local closestPlayer  = nil
    local closestDistance = math.huge
    local localChar = localplayer.Character
    if not localChar then return nil end
    local localRoot = findfirstchild(localChar, "HumanoidRootPart")
    if not localRoot then return nil end
    local localPos = localRoot.Position

    for _, player in players:GetPlayers() do
        if player == localplayer then continue end
        local character = player.Character
        if not character then continue end
        local humanoid = findfirstchild(character, "Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        if findfirstchild(character, "ForceField") then continue end
        if getattribute(character, "Blocking") then continue end
        local rootPart = findfirstchild(character, "HumanoidRootPart")
        if not rootPart then continue end
        local dist = (rootPart.Position - localPos).Magnitude
        if dist >= closestDistance then continue end
        closestDistance = dist
        closestPlayer   = player
    end
    return closestPlayer
end

--[[
    Posiciona o local player ATRÁS do alvo com espaço correto.
    - downed = false → usa CFrame completo (segue orientação do alvo em pé)
    - downed = true  → ignora a rotação do alvo caído; usa apenas o
                       lookvector horizontal para ficar atrás dele ereto,
                       com espaço maior (DOWNED_DISTANCE)
]]
local function positionBehindTarget(localRoot, targetRoot, downed)
    local distance = downed and DOWNED_DISTANCE or GOTO_DISTANCE

    if downed then
        -- Calcula direção horizontal do alvo (ignora inclinação por estar caído)
        local lookVec   = targetRoot.CFrame.LookVector
        local horizontal = Vector3.new(lookVec.X, 0, lookVec.Z)

        if horizontal.Magnitude < 0.01 then
            horizontal = Vector3.new(0, 0, 1)  -- fallback
        else
            horizontal = horizontal.Unit
        end

        -- "Atrás" = posição oposta ao lookVector (subtrai)
        local behindPos = Vector3.new(
            targetRoot.Position.X - horizontal.X * distance,
            targetRoot.Position.Y,  -- mantém mesmo Y (não copiar rotação lateral)
            targetRoot.Position.Z - horizontal.Z * distance
        )
        localRoot.CFrame = CFrame.new(behindPos)
    else
        -- Comportamento normal: segue o CFrame completo do alvo (fica atrás em pé)
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, distance)
    end
end

-- ────────────────────────────────────────────────
--  GUI
-- ────────────────────────────────────────────────

local old = localplayer.PlayerGui:FindFirstChild("PVCTDR_UI")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "PVCTDR_UI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = localplayer.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size                = UDim2.new(0, 200, 0, 240)
mainFrame.Position            = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3    = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel     = 0
mainFrame.Parent              = screenGui

local cornerMain = Instance.new("UICorner")
cornerMain.CornerRadius = UDim.new(0, 12)
cornerMain.Parent       = mainFrame

local strokeMain = Instance.new("UIStroke")
strokeMain.Color     = Color3.fromRGB(0, 0, 0)
strokeMain.Thickness = 2
strokeMain.Parent    = mainFrame

local topBar = Instance.new("Frame")
topBar.Size                   = UDim2.new(1, 0, 0, 32)
topBar.BackgroundColor3       = Color3.fromRGB(25, 25, 25)
topBar.BackgroundTransparency = 0.1
topBar.BorderSizePixel        = 0
topBar.Parent                 = mainFrame

local cornerTop = Instance.new("UICorner")
cornerTop.CornerRadius = UDim.new(0, 12)
cornerTop.Parent       = topBar

local fixTop = Instance.new("Frame")
fixTop.Size                   = UDim2.new(1, 0, 0, 12)
fixTop.Position               = UDim2.new(0, 0, 1, -12)
fixTop.BackgroundColor3       = Color3.fromRGB(25, 25, 25)
fixTop.BackgroundTransparency = 0.1
fixTop.BorderSizePixel        = 0
fixTop.Parent                 = topBar

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, -40, 1, 0)
title.Position         = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text             = "PVCTDR"
title.TextColor3       = Color3.fromRGB(255, 128, 0)
title.Font             = Enum.Font.GothamBold
title.TextSize         = 14
title.TextXAlignment   = Enum.TextXAlignment.Left
title.AutoLocalize     = false
title.Parent           = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size              = UDim2.new(0, 30, 0, 32)
minBtn.Position          = UDim2.new(1, -32, 0, 0)
minBtn.BackgroundTransparency = 1
minBtn.Text              = "-"
minBtn.TextColor3        = Color3.fromRGB(255, 128, 0)
minBtn.Font              = Enum.Font.GothamBold
minBtn.TextSize          = 18
minBtn.AutoLocalize      = false
minBtn.Parent            = topBar

local contentFrame = Instance.new("Frame")
contentFrame.Size                = UDim2.new(1, 0, 1, -32)
contentFrame.Position            = UDim2.new(0, 0, 0, 32)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent              = mainFrame

local selectBox = Instance.new("TextButton")
selectBox.Size                   = UDim2.new(0, 140, 0, 26)
selectBox.Position               = UDim2.new(0, 10, 0, 10)
selectBox.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
selectBox.BackgroundTransparency = 0.2
selectBox.Text                   = "Select Player"
selectBox.TextColor3             = Color3.fromRGB(200, 200, 200)
selectBox.Font                   = Enum.Font.Gotham
selectBox.TextSize               = 12
selectBox.AutoLocalize           = false
selectBox.Parent                 = contentFrame

local selectCorner = Instance.new("UICorner")
selectCorner.CornerRadius = UDim.new(0, 8)
selectCorner.Parent       = selectBox

local selectStroke = Instance.new("UIStroke")
selectStroke.Color  = Color3.fromRGB(255, 128, 0)
selectStroke.Parent = selectBox

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size             = UDim2.new(0, 30, 0, 26)
refreshBtn.Position         = UDim2.new(0, 160, 0, 10)
refreshBtn.BackgroundColor3 = Color3.fromRGB(255, 128, 0)
refreshBtn.Text             = "R"
refreshBtn.TextColor3       = Color3.fromRGB(15, 15, 15)
refreshBtn.Font             = Enum.Font.GothamBold
refreshBtn.TextSize         = 12
refreshBtn.AutoLocalize     = false
refreshBtn.Parent           = contentFrame

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent       = refreshBtn

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size                   = UDim2.new(0, 140, 0, 120)
scrollFrame.Position               = UDim2.new(0, 10, 0, 38)
scrollFrame.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
scrollFrame.BackgroundTransparency = 0.1
scrollFrame.ScrollBarThickness     = 4
scrollFrame.Visible                = false
scrollFrame.ZIndex                 = 10
scrollFrame.Parent                 = contentFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent       = scrollFrame

local scrollList = Instance.new("UIListLayout")
scrollList.Parent = scrollFrame

-- Retorna o label criado para referência externa (usado no closestLabel)
local function createToggle(name, yPos, varName)
    local frame = Instance.new("Frame")
    frame.Size                = UDim2.new(1, -20, 0, 30)
    frame.Position            = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex              = 1
    frame.Parent              = contentFrame

    local label = Instance.new("TextLabel")
    label.Size             = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text             = name
    label.TextColor3       = Color3.fromRGB(200, 200, 200)
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 12
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.AutoLocalize     = false
    label.ZIndex           = 1
    label.Parent           = frame

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 40, 0, 20)
    btn.Position         = UDim2.new(1, -40, 0.5, -10)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text             = "OFF"
    btn.TextColor3       = Color3.fromRGB(150, 150, 150)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 10
    btn.AutoLocalize     = false
    btn.ZIndex           = 1
    btn.Parent           = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent       = btn

    btn.MouseButton1Click:Connect(function()
        getgenv()[varName] = not getgenv()[varName]
        if getgenv()[varName] then
            btn.BackgroundColor3 = Color3.fromRGB(255, 128, 0)
            btn.TextColor3       = Color3.fromRGB(15, 15, 15)
            btn.Text             = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3       = Color3.fromRGB(150, 150, 150)
            btn.Text             = "OFF"
        end
    end)

    return label  -- para atualizar o texto dinamicamente
end

createToggle("Goto Selected", 50, "loopGotoSelected")
local closestLabel = createToggle("Goto Closest", 90, "loopGotoClosest")  -- label atualiza em tempo real
createToggle("Kill Aura",     130, "killAuraEnabled")

-- ────────────────────────────────────────────────
--  LISTA DE JOGADORES
-- ────────────────────────────────────────────────

local function updatePlayerList()
    for _, child in scrollFrame:GetChildren() do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in players:GetPlayers() do
        if p ~= localplayer then
            local pBtn = Instance.new("TextButton")
            pBtn.Size             = UDim2.new(1, -4, 0, 22)
            pBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            pBtn.Text             = p.Name
            pBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
            pBtn.Font             = Enum.Font.Gotham
            pBtn.TextSize         = 11
            pBtn.AutoLocalize     = false
            pBtn.ZIndex           = 11
            pBtn.Parent           = scrollFrame

            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 6)
            pCorner.Parent       = pBtn

            pBtn.MouseButton1Click:Connect(function()
                selectedTargetName = p.Name
                selectBox.Text     = p.Name
                scrollFrame.Visible = false
            end)
        end
    end
    task.wait(0.05)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollList.AbsoluteContentSize.Y)
end

selectBox.MouseButton1Click:Connect(function()
    scrollFrame.Visible = not scrollFrame.Visible
end)

refreshBtn.MouseButton1Click:Connect(updatePlayerList)

minBtn.MouseButton1Click:Connect(function()
    contentFrame.Visible = not contentFrame.Visible
    if contentFrame.Visible then
        mainFrame.Size   = UDim2.new(0, 200, 0, 240)
        fixTop.Visible   = true
        minBtn.Text      = "-"
    else
        mainFrame.Size   = UDim2.new(0, 200, 0, 32)
        fixTop.Visible   = false
        minBtn.Text      = "+"
        scrollFrame.Visible = false
    end
end)

-- ────────────────────────────────────────────────
--  DRAG
-- ────────────────────────────────────────────────

local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = mainFrame.Position
    end
end)
topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
uis.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

updatePlayerList()

-- ────────────────────────────────────────────────
--  KILL AURA LOOP
-- ────────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait()
        if getgenv().killAuraEnabled then
            local kTarget = getClosestTarget()
            if kTarget and kTarget.Character then
                CombatEvent:FireServer("Attack")
                HitEvent:FireServer({ kTarget.Character })
            end
        end
    end
end)

-- ────────────────────────────────────────────────
--  HEARTBEAT PRINCIPAL
-- ────────────────────────────────────────────────

if getgenv().pvctdrConn then getgenv().pvctdrConn:Disconnect() end

getgenv().pvctdrConn = runservice.Heartbeat:Connect(function()
    local localChar = localplayer.Character
    if not localChar then return end
    local localRoot = findfirstchild(localChar, "HumanoidRootPart")
    if not localRoot then return end

    local targetChar = nil

    -- ── GOTO CLOSEST ──────────────────────────────
    if getgenv().loopGotoClosest then
        -- Mantém locked player enquanto estiver vivo
        local lockedAlive = lockedClosestPlayer
            and lockedClosestPlayer.Parent == players
            and lockedClosestPlayer.Character
            and findfirstchild(lockedClosestPlayer.Character, "Humanoid")
            and lockedClosestPlayer.Character.Humanoid.Health > 0

        if lockedAlive then
            targetChar = lockedClosestPlayer.Character
        else
            -- Player atual morreu → busca novo mais próximo vivo
            lockedClosestPlayer = getClosestTarget()
            if lockedClosestPlayer and lockedClosestPlayer.Character then
                targetChar = lockedClosestPlayer.Character
            end
        end

        -- Atualiza o label do toggle com o nome do player sendo seguido
        closestLabel.Text = lockedClosestPlayer
            and lockedClosestPlayer.Name
            or "Goto Closest"
    else
        lockedClosestPlayer = nil
        closestLabel.Text   = "Goto Closest"
    end

    -- ── GOTO SELECTED ─────────────────────────────
    -- Só ativa se Goto Closest estiver desligado.
    -- selectedTargetName NUNCA é limpo → persiste automaticamente por morte/respawn.
    if not getgenv().loopGotoClosest and getgenv().loopGotoSelected and selectedTargetName ~= "" then
        local selPlayer = players:FindFirstChild(selectedTargetName)
        if selPlayer and selPlayer.Character then
            local selHum = findfirstchild(selPlayer.Character, "Humanoid")
            if selHum then
                -- Vai até o player mesmo se caído;
                -- quando ele respawnar o targeting retoma automaticamente.
                targetChar = selPlayer.Character
            end
        end
    end

    -- ── POSICIONAMENTO ────────────────────────────
    if targetChar then
        local targetRoot = findfirstchild(targetChar, "HumanoidRootPart")
        if targetRoot then
            local downed = isPlayerDowned(targetChar)
            positionBehindTarget(localRoot, targetRoot, downed)
        end
    end
end)
