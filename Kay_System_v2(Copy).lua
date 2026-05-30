-- ╔══════════════════════════════════════════════════════╗
-- ║       CoiledTom Hub — Key System v6.0               ║
-- ║       GUI Própria + Panda Auth                      ║
-- ║       Provider Selector: Linkvertise / Lootlabs     ║
-- ╚══════════════════════════════════════════════════════╝

local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local Player       = Players.LocalPlayer
local PlayerGui    = Player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════
--  CONFIG — dois services no Panda
-- ══════════════════════════════════════════════

local PROVIDERS = {
    linkvertise = {
        label     = "Linkvertise",
        emoji     = "🟠",
        color     = Color3.fromRGB(255, 140, 30),     -- laranja
        glowColor = Color3.fromRGB(255, 100, 0),
        ServiceID = "tom",                             -- identifier da foto 2
        KeyURL    = "https://new.pandadevelopment.net/getkey/tom",
        APIKey    = "243561ea-320b-48de-ad49-28ed87410065",
        provider  = "linkvertise",
    },
    lootlabs = {
        label     = "Lootlabs",
        emoji     = "🟣",
        color     = Color3.fromRGB(150, 80, 255),      -- roxo
        glowColor = Color3.fromRGB(120, 60, 220),
        ServiceID = "getkeylot",                       -- identifier da foto 1
        KeyURL    = "https://new.pandadevelopment.net/getkey/getkeylot",
        APIKey    = "e1522a9e-8444-4841-83d4-138688b5ca67",
        provider  = "lootlabs",
    },
}

local SCRIPT_URL = "https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/loader.lua"
local SAVE_FILE  = "CoiledTomHub_v6.key"    -- arquivo salva provider+key

-- provider ativo (nil = nenhum selecionado)
local activeProvider = nil

-- ══════════════════════════════════════════════
--  HWID + HTTP
-- ══════════════════════════════════════════════

local function getHWID()
    local ok, hwid = pcall(gethwid)
    if ok and hwid then return hwid end
    return tostring(
        game:GetService("RbxAnalyticsService"):GetClientId()
    ):gsub("-", "")
end

local function HttpRequest(opts)
    if syn and syn.request then
        return syn.request(opts)
    elseif http and http.request then
        return http.request(opts)
    elseif http_request then
        return http_request(opts)
    elseif request then
        return request(opts)
    end
end

-- ══════════════════════════════════════════════
--  VALIDAR KEY NO PANDA
-- ══════════════════════════════════════════════

local function ValidatePanda(key, providerCfg)
    local ok, res = pcall(HttpRequest, {
        Url    = "https://new.pandadevelopment.net/api/v1/keys/validate",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            ServiceID = providerCfg.ServiceID,
            HWID      = getHWID(),
            Key       = key,
        }),
    })

    if not ok or not res then return false end

    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not ok2 or type(data) ~= "table" then return false end

    return data.Authenticated_Status == "Success"
end

-- ══════════════════════════════════════════════
--  SAVE / LOAD  (salva "provider:key")
-- ══════════════════════════════════════════════

local function SaveKey(key, providerName)
    pcall(writefile, SAVE_FILE, providerName .. ":" .. key)
end

local function LoadKey()
    local ok, v = pcall(readfile, SAVE_FILE)
    if not ok or not v or v == "" then return nil, nil end

    local prov, key = v:match("^(.-):(.*)")
    if not prov or not key or key == "" then return nil, nil end
    if not PROVIDERS[prov] then return nil, nil end

    return key, prov
end

-- ══════════════════════════════════════════════
--  GUI — ScreenGui
-- ══════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CoiledTomKeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Card principal
local Card = Instance.new("Frame")
Card.Size = UDim2.fromOffset(420, 310)
Card.Position = UDim2.fromScale(0.5, 0.5)
Card.AnchorPoint = Vector2.new(0.5, 0.5)
Card.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Card.BorderSizePixel = 0
Card.ZIndex = 2
Card.Parent = ScreenGui

Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 16)

local CardStroke = Instance.new("UIStroke")
CardStroke.Color = Color3.fromRGB(120, 60, 220)
CardStroke.Thickness = 1.5
CardStroke.Parent = Card

-- ── Título ──────────────────────────────────────────────
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 42)
Title.Position = UDim2.fromOffset(0, 16)
Title.BackgroundTransparency = 1
Title.Text = "CoiledTom Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 21
Title.ZIndex = 3
Title.Parent = Card

-- ── Sub ─────────────────────────────────────────────────
local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -40, 0, 18)
Sub.Position = UDim2.fromOffset(20, 58)
Sub.BackgroundTransparency = 1
Sub.Text = "Selecione o provider para obter sua key:"
Sub.TextColor3 = Color3.fromRGB(150, 150, 170)
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 13
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.ZIndex = 3
Sub.Parent = Card

-- ══════════════════════════════════════════════
--  BOTÕES DE SELEÇÃO DE PROVIDER
-- ══════════════════════════════════════════════

-- Botão Linkvertise
local BtnLinkvertise = Instance.new("TextButton")
BtnLinkvertise.Size = UDim2.fromOffset(178, 52)
BtnLinkvertise.Position = UDim2.fromOffset(20, 86)
BtnLinkvertise.BackgroundColor3 = Color3.fromRGB(28, 20, 12)
BtnLinkvertise.BorderSizePixel = 0
BtnLinkvertise.Text = "🟠  Linkvertise"
BtnLinkvertise.TextColor3 = Color3.fromRGB(255, 140, 30)
BtnLinkvertise.Font = Enum.Font.GothamBold
BtnLinkvertise.TextSize = 14
BtnLinkvertise.ZIndex = 3
BtnLinkvertise.Parent = Card

Instance.new("UICorner", BtnLinkvertise).CornerRadius = UDim.new(0, 10)

local StrokeLV = Instance.new("UIStroke")
StrokeLV.Color = Color3.fromRGB(100, 60, 10)
StrokeLV.Thickness = 1.2
StrokeLV.Parent = BtnLinkvertise

-- Botão Lootlabs
local BtnLootlabs = Instance.new("TextButton")
BtnLootlabs.Size = UDim2.fromOffset(178, 52)
BtnLootlabs.Position = UDim2.fromOffset(222, 86)
BtnLootlabs.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
BtnLootlabs.BorderSizePixel = 0
BtnLootlabs.Text = "🟣  Lootlabs"
BtnLootlabs.TextColor3 = Color3.fromRGB(150, 80, 255)
BtnLootlabs.Font = Enum.Font.GothamBold
BtnLootlabs.TextSize = 14
BtnLootlabs.ZIndex = 3
BtnLootlabs.Parent = Card

Instance.new("UICorner", BtnLootlabs).CornerRadius = UDim.new(0, 10)

local StrokeLL = Instance.new("UIStroke")
StrokeLL.Color = Color3.fromRGB(60, 30, 100)
StrokeLL.Thickness = 1.2
StrokeLL.Parent = BtnLootlabs

-- ── Separador ────────────────────────────────────────────
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, -40, 0, 1)
Sep.Position = UDim2.fromOffset(20, 152)
Sep.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
Sep.BorderSizePixel = 0
Sep.ZIndex = 3
Sep.Parent = Card

-- ── Sub2 (instrução input) ────────────────────────────────
local Sub2 = Instance.new("TextLabel")
Sub2.Size = UDim2.new(1, -40, 0, 18)
Sub2.Position = UDim2.fromOffset(20, 162)
Sub2.BackgroundTransparency = 1
Sub2.Text = "Digite sua key para continuar"
Sub2.TextColor3 = Color3.fromRGB(150, 150, 170)
Sub2.Font = Enum.Font.Gotham
Sub2.TextSize = 13
Sub2.TextXAlignment = Enum.TextXAlignment.Left
Sub2.ZIndex = 3
Sub2.Parent = Card

-- ── Input ─────────────────────────────────────────────────
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -40, 0, 42)
InputBox.Position = UDim2.fromOffset(20, 188)
InputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
InputBox.BorderSizePixel = 0
InputBox.PlaceholderText = "COILEDTOM-XXXX-XXXX-XXXX"
InputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
InputBox.Text = ""
InputBox.TextColor3 = Color3.fromRGB(220, 220, 255)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 14
InputBox.ClearTextOnFocus = false
InputBox.ZIndex = 3
InputBox.Parent = Card

Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 9)

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(55, 55, 80)
InputStroke.Thickness = 1
InputStroke.Parent = InputBox

local InputPad = Instance.new("UIPadding")
InputPad.PaddingLeft = UDim.new(0, 12)
InputPad.Parent = InputBox

-- ── Botões de ação ─────────────────────────────────────────

-- GET KEY
local BtnGet = Instance.new("TextButton")
BtnGet.Size = UDim2.fromOffset(108, 40)
BtnGet.Position = UDim2.fromOffset(20, 248)
BtnGet.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
BtnGet.BorderSizePixel = 0
BtnGet.Text = "🔗 Get Key"
BtnGet.TextColor3 = Color3.fromRGB(180, 130, 255)
BtnGet.Font = Enum.Font.GothamBold
BtnGet.TextSize = 13
BtnGet.ZIndex = 3
BtnGet.Parent = Card

Instance.new("UICorner", BtnGet).CornerRadius = UDim.new(0, 9)

-- SUBMIT
local BtnSubmit = Instance.new("TextButton")
BtnSubmit.Size = UDim2.fromOffset(130, 40)
BtnSubmit.Position = UDim2.fromOffset(140, 248)
BtnSubmit.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
BtnSubmit.BorderSizePixel = 0
BtnSubmit.Text = "✔ Submit"
BtnSubmit.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnSubmit.Font = Enum.Font.GothamBold
BtnSubmit.TextSize = 13
BtnSubmit.ZIndex = 3
BtnSubmit.Parent = Card

Instance.new("UICorner", BtnSubmit).CornerRadius = UDim.new(0, 9)

-- EXIT
local BtnExit = Instance.new("TextButton")
BtnExit.Size = UDim2.fromOffset(90, 40)
BtnExit.Position = UDim2.fromOffset(290, 248)
BtnExit.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
BtnExit.BorderSizePixel = 0
BtnExit.Text = "✖ Exit"
BtnExit.TextColor3 = Color3.fromRGB(255, 80, 80)
BtnExit.Font = Enum.Font.GothamBold
BtnExit.TextSize = 13
BtnExit.ZIndex = 3
BtnExit.Parent = Card

Instance.new("UICorner", BtnExit).CornerRadius = UDim.new(0, 9)

-- ── Status ────────────────────────────────────────────────
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -40, 0, 22)
Status.Position = UDim2.fromOffset(20, 294)
Status.BackgroundTransparency = 1
Status.Text = "⬆ Selecione um provider acima"
Status.TextColor3 = Color3.fromRGB(130, 130, 160)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.ZIndex = 3
Status.Parent = Card

-- ══════════════════════════════════════════════
--  NOTIFY
-- ══════════════════════════════════════════════

local function Notify(msg, color)
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.fromOffset(290, 46)
    Notif.Position = UDim2.new(1, -310, 1, 60)
    Notif.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
    Notif.BorderSizePixel = 0
    Notif.ZIndex = 10
    Notif.Parent = ScreenGui

    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 10)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = color or Color3.fromRGB(120, 60, 220)
    Stroke.Thickness = 1.2
    Stroke.Parent = Notif

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -16, 1, 0)
    Lbl.Position = UDim2.fromOffset(8, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = msg
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 255)
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.ZIndex = 11
    Lbl.Parent = Notif

    TweenService:Create(Notif, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -310, 1, -60)
    }):Play()

    task.delay(3.2, function()
        TweenService:Create(Notif, TweenInfo.new(0.3), {
            Position = UDim2.new(1, -310, 1, 60)
        }):Play()
        task.wait(0.35)
        Notif:Destroy()
    end)
end

-- ══════════════════════════════════════════════
--  LÓGICA DE SELEÇÃO DE PROVIDER
-- ══════════════════════════════════════════════

--[[
    Atualiza o visual dos botões de provider e o CardStroke
    conforme qual foi selecionado.
--]]
local function SelectProvider(name)
    activeProvider = name
    local cfg = PROVIDERS[name]

    -- Muda borda do card para a cor do provider
    TweenService:Create(CardStroke, TweenInfo.new(0.3), {
        Color = cfg.color
    }):Play()

    -- Destaca botão selecionado, apaga o outro
    if name == "linkvertise" then
        TweenService:Create(StrokeLV, TweenInfo.new(0.25), {
            Color = PROVIDERS.linkvertise.color, Thickness = 2
        }):Play()
        TweenService:Create(BtnLinkvertise, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(50, 30, 10)
        }):Play()

        TweenService:Create(StrokeLL, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(60, 30, 100), Thickness = 1.2
        }):Play()
        TweenService:Create(BtnLootlabs, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(18, 12, 30)
        }):Play()
    else
        TweenService:Create(StrokeLL, TweenInfo.new(0.25), {
            Color = PROVIDERS.lootlabs.color, Thickness = 2
        }):Play()
        TweenService:Create(BtnLootlabs, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(30, 15, 50)
        }):Play()

        TweenService:Create(StrokeLV, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(100, 60, 10), Thickness = 1.2
        }):Play()
        TweenService:Create(BtnLinkvertise, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(28, 20, 12)
        }):Play()
    end

    -- Atualiza cor do botão Submit para a cor do provider
    TweenService:Create(BtnSubmit, TweenInfo.new(0.25), {
        BackgroundColor3 = cfg.color
    }):Play()

    -- Atualiza placeholder e status
    InputBox.PlaceholderText = "COILEDTOM-XXXX-XXXX-XXXX"
    Status.Text = cfg.emoji .. " " .. cfg.label .. " selecionado — clique em Get Key ou cole sua key"
    Status.TextColor3 = cfg.color

    Notify(cfg.emoji .. " " .. cfg.label .. " selecionado!", cfg.color)
end

-- Cliques nos botões de provider
BtnLinkvertise.MouseButton1Click:Connect(function()
    SelectProvider("linkvertise")
end)

BtnLootlabs.MouseButton1Click:Connect(function()
    SelectProvider("lootlabs")
end)

-- ══════════════════════════════════════════════
--  BOTÃO GET KEY
-- ══════════════════════════════════════════════

BtnGet.MouseButton1Click:Connect(function()
    if not activeProvider then
        Notify("⚠️ Selecione Linkvertise ou Lootlabs primeiro!", Color3.fromRGB(220, 150, 0))
        return
    end

    local cfg = PROVIDERS[activeProvider]
    -- Monta URL com HWID + provider
    local url = cfg.KeyURL .. "?hwid=" .. getHWID() .. "&provider=" .. cfg.provider

    pcall(setclipboard, url)
    Notify("🔗 URL copiada! Cole no navegador.", cfg.color)
end)

-- ══════════════════════════════════════════════
--  EXIT
-- ══════════════════════════════════════════════

BtnExit.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ══════════════════════════════════════════════
--  FUNÇÃO DE CARREGAMENTO DO SCRIPT PRINCIPAL
-- ══════════════════════════════════════════════

local function LaunchMain()
    ScreenGui:Destroy()
    loadstring(game:HttpGet(SCRIPT_URL))()
end

-- ══════════════════════════════════════════════
--  BOTÃO SUBMIT
-- ══════════════════════════════════════════════

BtnSubmit.MouseButton1Click:Connect(function()
    if not activeProvider then
        Notify("⚠️ Selecione Linkvertise ou Lootlabs primeiro!", Color3.fromRGB(220, 150, 0))
        return
    end

    local key = InputBox.Text:gsub("%s+", "")

    if key == "" then
        Notify("⚠️ Digite uma key primeiro!", Color3.fromRGB(220, 150, 0))
        return
    end

    Status.Text = "⏳ Validando..."
    Status.TextColor3 = Color3.fromRGB(180, 180, 200)
    BtnSubmit.Active = false

    task.spawn(function()
        local cfg = PROVIDERS[activeProvider]
        local valid = ValidatePanda(key, cfg)

        if valid then
            SaveKey(key, activeProvider)
            Status.Text = "✅ Key válida!"
            Status.TextColor3 = Color3.fromRGB(80, 220, 120)
            Notify("✅ Key válida! Carregando...", Color3.fromRGB(60, 180, 100))
            task.wait(1)
            LaunchMain()
        else
            Status.Text = "❌ Key inválida ou provider errado!"
            Status.TextColor3 = Color3.fromRGB(255, 80, 80)
            Notify("❌ Key inválida! Verifique o provider.", Color3.fromRGB(200, 50, 50))
            BtnSubmit.Active = true
        end
    end)
end)

-- ══════════════════════════════════════════════
--  AUTO LOGIN (verifica key salva)
-- ══════════════════════════════════════════════

task.spawn(function()
    local saved, provName = LoadKey()

    if not saved then return end

    local cfg = PROVIDERS[provName]
    SelectProvider(provName)   -- destaca o provider correto na UI
    InputBox.Text = saved

    Status.Text = "⏳ Verificando key salva (" .. cfg.label .. ")..."

    local valid = ValidatePanda(saved, cfg)

    if valid then
        Status.Text = "✅ Key válida!"
        Notify("✅ Key salva válida! Carregando...", Color3.fromRGB(60, 180, 100))
        task.wait(1)
        LaunchMain()
    else
        -- key expirada, limpa arquivo
        pcall(writefile, SAVE_FILE, "")
        InputBox.Text = ""
        activeProvider = nil
        Status.Text = "⬆ Selecione um provider acima"
        Status.TextColor3 = Color3.fromRGB(130, 130, 160)
        Notify("⚠️ Key salva expirada. Gere uma nova.", Color3.fromRGB(220, 150, 0))
    end
end)
