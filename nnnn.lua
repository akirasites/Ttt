--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    SHADOW OPS HUB v6.0                       ║
    ║                   Author: CoiledTom                          ║
    ║              Universal Script Hub - WindUI v2                ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════
--              SERVICES
-- ═══════════════════════════════════════════
local cloneref = cloneref or clonereference or function(x) return x end
local Players        = cloneref(game:GetService("Players"))
local RunService     = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService    = cloneref(game:GetService("HttpService"))
local TweenService   = cloneref(game:GetService("TweenService"))
local Workspace      = cloneref(game:GetService("Workspace"))
local Lighting       = cloneref(game:GetService("Lighting"))
local PhysicsService = cloneref(game:GetService("PhysicsService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local CoreGui        = cloneref(game:GetService("CoreGui"))
local StarterGui     = cloneref(game:GetService("StarterGui"))
local Camera         = Workspace.CurrentCamera

-- ═══════════════════════════════════════════
--              LOAD WINDUI
-- ═══════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ═══════════════════════════════════════════
--              CORE VARIABLES
-- ═══════════════════════════════════════════
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- State flags
local State = {
    Noclip        = false,
    Fly           = false,
    Fling         = false,
    AntiFling     = false,
    GodMode       = false,
    AntiVoid      = false,
    AntiStun      = false,
    AntiKnockback = false,
    AntiSlow      = false,
    AntiAFK       = false,
    AntiKick      = false,
    AutoRejoin    = false,
    ServerHop     = false,
    ESPBox        = false,
    ESPChams      = false,
    ESPTracers    = false,
    ESPDist       = false,
    ESPHealth     = false,
    Hitbox        = false,
    Aimbot        = false,
    AimTeamCheck  = false,
    AimVisible    = false,
    FullBright    = false,
    NoFog         = false,
    NightMode     = false,
    FreeCamera    = false,
    LunarGravity  = false,
    HideName      = false,
    CamButton     = false,
    AntiLag       = false,
    FPSBoost      = false,
    LowPoly       = false,
    DisableParticles = false,
    TextureLow    = false,
    RemoveDecals  = false,
    DynRender     = false,
    EntityLimiter = false,
    LightingCleaner = false,
    InfiniteJump  = false,
    JumpHack      = false,
    SpeedHack     = false,
    ShiftLock     = false,
}

-- Settings
local Settings = {
    WalkSpeed     = 16,
    JumpPower     = 50,
    FlySpeed      = 50,
    FreeCamSpeed  = 25,
    FOV           = 70,
    AimFOV        = 120,
    AimSmooth     = 0.25,
    HitboxSize    = 5,
    HitboxTrans   = 0.5,
    HitboxColor   = Color3.fromRGB(255, 50, 50),
    ESPBoxColor   = Color3.fromRGB(255, 255, 255),
    ESPFillColor  = Color3.fromRGB(255, 255, 255),
    ESPFillAlpha  = 0.5,
    ChamsColor    = Color3.fromRGB(255, 0, 0),
    TracerColor   = Color3.fromRGB(255, 255, 0),
    ObjTransparency = 0.5,
    PanicKey      = Enum.KeyCode.RightShift,
}

-- Connections storage
local Connections  = {}
local ESPObjects   = {}
local HitboxParts  = {}
local FlyBodyVelocity = nil
local FlyBodyAngVelocity = nil
local NoclipConn  = nil
local FlyConn     = nil
local FlingConn   = nil
local AntiFlingConn = nil
local AntiVoidConn = nil
local AntiStunConn = nil
local AimConn     = nil
local FreeCamConn = nil
local DeathConn   = nil

-- ═══════════════════════════════════════════
--              HELPER FUNCTIONS
-- ═══════════════════════════════════════════
local function getChar()
    return LocalPlayer.Character
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if myTeam == nil or theirTeam == nil then return true end
    return myTeam ~= theirTeam
end

local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() conn:Disconnect() end)
    end
end

local function notify(title, content, icon, duration)
    WindUI:Notify({
        Title   = title or "ShadowOps Hub",
        Content = content or "",
        Icon    = icon or "bell",
        Duration = duration or 4,
    })
end

local function getPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

-- ═══════════════════════════════════════════
--          MOVEMENT FUNCTIONS
-- ═══════════════════════════════════════════

-- NOCLIP
local function startNoclip()
    State.Noclip = true
    NoclipConn = RunService.Stepped:Connect(function()
        local c = getChar()
        if not c then return end
        for _, v in pairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    State.Noclip = false
    safeDisconnect(NoclipConn)
    NoclipConn = nil
end

-- FLY
local function startFly()
    State.Fly = true
    local root = getRoot()
    local hum  = getHum()
    if not root or not hum then return end

    hum.PlatformStand = true

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyVelocity.P = 1e4
    FlyBodyVelocity.Parent = root

    FlyBodyAngVelocity = Instance.new("BodyAngularVelocity")
    FlyBodyAngVelocity.AngularVelocity = Vector3.zero
    FlyBodyAngVelocity.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyAngVelocity.P = 1e4
    FlyBodyAngVelocity.Parent = root

    FlyConn = RunService.RenderStepped:Connect(function()
        if not State.Fly then return end
        local spd = Settings.FlySpeed
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        if FlyBodyVelocity then
            FlyBodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        end
    end)
end

local function stopFly()
    State.Fly = false
    safeDisconnect(FlyConn)
    FlyConn = nil
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
    if FlyBodyAngVelocity then FlyBodyAngVelocity:Destroy() FlyBodyAngVelocity = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- FLING
local function startFling()
    State.Fling = true
    FlingConn = RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if not root then return end
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v ~= root then
                local dist = (v.Position - root.Position).Magnitude
                if dist < 15 then
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = (v.Position - root.Position).Unit * 500
                    bv.MaxForce = Vector3.new(1e8,1e8,1e8)
                    bv.Parent = v
                    game:GetService("Debris"):AddItem(bv, 0.1)
                end
            end
        end
    end)
end

local function stopFling()
    State.Fling = false
    safeDisconnect(FlingConn)
    FlingConn = nil
end

-- ANTI-FLING
local function startAntiFling()
    State.AntiFling = true
    AntiFlingConn = RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if not root then return end
        if root.Velocity.Magnitude > 200 then
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function stopAntiFling()
    State.AntiFling = false
    safeDisconnect(AntiFlingConn)
    AntiFlingConn = nil
end

-- GOD MODE
local function applyGodMode()
    State.GodMode = true
    local hum = getHum()
    if hum then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
    end
    if DeathConn then safeDisconnect(DeathConn) end
    DeathConn = RunService.Heartbeat:Connect(function()
        if not State.GodMode then return end
        local h = getHum()
        if h and h.Health < h.MaxHealth then
            h.Health = h.MaxHealth
        end
    end)
end

local function removeGodMode()
    State.GodMode = false
    safeDisconnect(DeathConn)
    DeathConn = nil
    local hum = getHum()
    if hum then
        hum.MaxHealth = 100
        hum.Health = 100
    end
end

-- ANTI-VOID
local function startAntiVoid()
    State.AntiVoid = true
    Connections["AntiVoid"] = RunService.Heartbeat:Connect(function()
        if not State.AntiVoid then return end
        local root = getRoot()
        if root and root.Position.Y < -100 then
            local spawnLoc = LocalPlayer.RespawnLocation
            if spawnLoc then
                root.CFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
            else
                root.CFrame = CFrame.new(0, 10, 0)
            end
        end
    end)
end

local function stopAntiVoid()
    State.AntiVoid = false
    safeDisconnect(Connections["AntiVoid"])
    Connections["AntiVoid"] = nil
end

-- ANTI-STUN
local function startAntiStun()
    State.AntiStun = true
    Connections["AntiStun"] = RunService.Heartbeat:Connect(function()
        if not State.AntiStun then return end
        local hum = getHum()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        end
    end)
end

local function stopAntiStun()
    State.AntiStun = false
    safeDisconnect(Connections["AntiStun"])
    Connections["AntiStun"] = nil
    local hum = getHum()
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end
end

-- ANTI-KNOCKBACK
local function startAntiKnockback()
    State.AntiKnockback = true
    Connections["AntiKB"] = RunService.Heartbeat:Connect(function()
        if not State.AntiKnockback then return end
        local root = getRoot()
        if root then
            if math.abs(root.AssemblyLinearVelocity.X) > 50 or math.abs(root.AssemblyLinearVelocity.Z) > 50 then
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end
    end)
end

local function stopAntiKnockback()
    State.AntiKnockback = false
    safeDisconnect(Connections["AntiKB"])
    Connections["AntiKB"] = nil
end

-- ANTI-SLOW
local function startAntiSlow()
    State.AntiSlow = true
    Connections["AntiSlow"] = RunService.Heartbeat:Connect(function()
        if not State.AntiSlow then return end
        local hum = getHum()
        if hum and hum.WalkSpeed < Settings.WalkSpeed then
            hum.WalkSpeed = Settings.WalkSpeed
        end
    end)
end

local function stopAntiSlow()
    State.AntiSlow = false
    safeDisconnect(Connections["AntiSlow"])
    Connections["AntiSlow"] = nil
end

-- DELETE RAGDOLL
local function deleteRagdoll()
    local c = getChar()
    if not c then return end
    for _, v in pairs(c:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") or
           v:IsA("NoCollisionConstraint") or v:IsA("WeldConstraint") then
            pcall(function() v:Destroy() end)
        end
    end
    notify("ShadowOps Hub", "Ragdoll parts deleted!", "trash-2")
end

-- ANTI-AFK
local function startAntiAFK()
    State.AntiAFK = true
    Connections["AntiAFK"] = RunService.Heartbeat:Connect(function()
        if not State.AntiAFK then return end
        LocalPlayer.Idled:Connect(function() end)
    end)
    -- Virtual input simulation
    local VIM = game:GetService("VirtualInputManager")
    Connections["AntiAFKKey"] = RunService.Stepped:Connect(function()
        if not State.AntiAFK then return end
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end)
    end)
end

local function stopAntiAFK()
    State.AntiAFK = false
    safeDisconnect(Connections["AntiAFK"])
    safeDisconnect(Connections["AntiAFKKey"])
    Connections["AntiAFK"] = nil
    Connections["AntiAFKKey"] = nil
end

-- ANTI-KICK
local function hookAntiKick()
    State.AntiKick = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and typeof(self) == "Instance" and self:IsA("Player") then
            if State.AntiKick then
                return
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- AUTO-REJOIN
local function setupAutoRejoin()
    State.AutoRejoin = true
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        if player == LocalPlayer and State.AutoRejoin then
            task.wait(2)
            local teleportService = game:GetService("TeleportService")
            teleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end

-- SERVER HOP
local function startServerHop()
    local HttpSvc = cloneref(game:GetService("HttpService"))
    local TpSvc   = game:GetService("TeleportService")
    local placeId  = game.PlaceId
    local url      = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
    local ok, result = pcall(function()
        return HttpSvc:JSONDecode(game:HttpGet(url))
    end)
    if not ok or not result or not result.data then
        notify("Server Hop", "Could not fetch server list.", "alert-triangle")
        return
    end
    local servers = result.data
    table.sort(servers, function(a,b) return (a.ping or 999) < (b.ping or 999) end)
    for _, srv in ipairs(servers) do
        if srv.id and srv.playing and srv.playing < (srv.maxPlayers or 20) then
            TpSvc:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
            return
        end
    end
    notify("Server Hop", "No better server found.", "search")
end

-- SPEED HACK
local function setSpeed(spd)
    Settings.WalkSpeed = spd
    local hum = getHum()
    if hum then hum.WalkSpeed = spd end
end

local function setJumpPower(jp)
    Settings.JumpPower = jp
    local hum = getHum()
    if hum then hum.JumpPower = jp end
end

-- INFINITE JUMP
local function startInfiniteJump()
    State.InfiniteJump = true
    Connections["InfJump"] = UserInputService.JumpRequest:Connect(function()
        if not State.InfiniteJump then return end
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local function stopInfiniteJump()
    State.InfiniteJump = false
    safeDisconnect(Connections["InfJump"])
    Connections["InfJump"] = nil
end

-- LUNAR GRAVITY
local function setLunarGravity(enabled)
    State.LunarGravity = enabled
    Workspace.Gravity = enabled and 10 or 196.2
end

-- SHIFT LOCK
local function setShiftLock(enabled)
    State.ShiftLock = enabled
    StarterGui:SetCore("AvatarContextMenuEnabled", not enabled)
    pcall(function()
        LocalPlayer.DevEnableMouseLock = enabled
        game:GetService("PlayerModule"):FindFirstChild("CameraModule"):FindFirstChild("MouseLockController"):setEnabled(enabled)
    end)
end

-- ═══════════════════════════════════════════
--          FREE CAMERA
-- ═══════════════════════════════════════════
local FreeCamPart = nil

local function startFreeCamera()
    State.FreeCamera = true
    FreeCamPart = Instance.new("Part")
    FreeCamPart.Anchored = true
    FreeCamPart.CanCollide = false
    FreeCamPart.Transparency = 1
    FreeCamPart.Size = Vector3.new(1,1,1)
    FreeCamPart.CFrame = Camera.CFrame
    FreeCamPart.Parent = Workspace

    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = FreeCamPart.CFrame

    FreeCamConn = RunService.RenderStepped:Connect(function()
        if not State.FreeCamera or not FreeCamPart then return end
        local spd = Settings.FreeCamSpeed
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then
            FreeCamPart.CFrame = FreeCamPart.CFrame + dir.Unit * spd * RunService.RenderStepped:Wait()
        end
        Camera.CFrame = FreeCamPart.CFrame
    end)
end

local function stopFreeCamera()
    State.FreeCamera = false
    safeDisconnect(FreeCamConn)
    FreeCamConn = nil
    if FreeCamPart then FreeCamPart:Destroy() FreeCamPart = nil end
    Camera.CameraType = Enum.CameraType.Custom
end

-- ═══════════════════════════════════════════
--          VISUAL / WORLD
-- ═══════════════════════════════════════════

local function setFullBright(enabled)
    State.FullBright = enabled
    if enabled then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
    else
        Lighting.Ambient = Color3.fromRGB(127,127,127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
    end
end

local function setNoFog(enabled)
    State.NoFog = enabled
    Lighting.FogEnd = enabled and 1e9 or 1000
    Lighting.FogStart = enabled and 1e9 or 0
end

local function setNightMode(enabled)
    State.NightMode = enabled
    Lighting.ClockTime = enabled and 0 or 14
end

local function setFOV(fov)
    Settings.FOV = fov
    Camera.FieldOfView = fov
end

local function resetFOV()
    Camera.FieldOfView = 70
    Settings.FOV = 70
end

local function setObjTransparency(value)
    Settings.ObjTransparency = value
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character or Instance.new("Folder")) then
            pcall(function() part.LocalTransparencyModifier = value end)
        end
    end
end

local function cleanLighting()
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or
           effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then
            pcall(function() effect.Enabled = false end)
        end
    end
    notify("Lighting Cleaner", "Post-processing effects disabled!", "sun")
end

-- ═══════════════════════════════════════════
--          PERFORMANCE / FPS
-- ═══════════════════════════════════════════

local function disableParticles()
    State.DisableParticles = true
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            pcall(function() v.Enabled = false end)
        end
    end
    notify("Particles", "Particle effects disabled!", "wind")
end

local function setTextureLow()
    State.TextureLow = true
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function() v.Material = Enum.Material.SmoothPlastic end)
        end
    end
    notify("Textures", "Low texture mode applied!", "image")
end

local function removeDecals()
    State.RemoveDecals = true
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") or v:IsA("SpecialMesh") then
            pcall(function() v:Destroy() end)
        end
    end
    notify("Decals", "Decals removed!", "eraser")
end

local function applyFPSBoost()
    State.FPSBoost = true
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    notify("FPS Boost", "Max performance mode activated!", "zap")
end

local function applyAntiLag()
    State.AntiLag = true
    Workspace.StreamingEnabled = false
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function()
                v.CastShadow = false
            end)
        end
    end
    notify("Anti-Lag", "Physics lag reduction applied!", "activity")
end

local function setEntityLimiter()
    State.EntityLimiter = true
    local limit = 80
    local count = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character or Instance.new("Folder")) then
            count = count + 1
            if count > limit then
                pcall(function() v.Anchored = true end)
            end
        end
    end
    notify("Entity Limiter", ("Limited to %d entities!"):format(limit), "layers")
end

local function setLowPoly()
    State.LowPoly = true
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("SpecialMesh") then
            pcall(function() v.MeshType = Enum.MeshType.Brick end)
        end
    end
    notify("Low Poly", "Low poly mode active!", "triangle")
end

local function setDynRender()
    State.DynRender = true
    local ping = LocalPlayer.GetNetworkPing and LocalPlayer:GetNetworkPing() * 1000 or 0
    local level = ping < 100 and Enum.QualityLevel.Level10 or ping < 200 and Enum.QualityLevel.Level05 or Enum.QualityLevel.Level01
    settings().Rendering.QualityLevel = level
    notify("Dynamic Render", "Render adjusted by network quality!", "wifi")
end

-- ═══════════════════════════════════════════
--          ESP / COMBAT
-- ═══════════════════════════════════════════

local function getWorldToViewportPoint(pos)
    local result, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(result.X, result.Y), onScreen, result.Z
end

local function getBox(character)
    local parts = {}
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local pos, onScreen = getWorldToViewportPoint(part.Position)
            if onScreen then
                table.insert(parts, pos)
                minX = math.min(minX, pos.X)
                minY = math.min(minY, pos.Y)
                maxX = math.max(maxX, pos.X)
                maxY = math.max(maxY, pos.Y)
            end
        end
    end
    return minX, minY, maxX, maxY, #parts > 0
end

local function buildESP(player)
    if ESPObjects[player] then return end
    local espData = {}

    -- Box
    local box = Drawing.new("Square")
    box.Filled = false
    box.Color = Settings.ESPBoxColor
    box.Thickness = 1.5
    box.Visible = false
    espData.Box = box

    -- Box Fill
    local fill = Drawing.new("Square")
    fill.Filled = true
    fill.Color = Settings.ESPFillColor
    fill.Transparency = Settings.ESPFillAlpha
    fill.Visible = false
    espData.Fill = fill

    -- Name
    local nameLabel = Drawing.new("Text")
    nameLabel.Text = player.Name
    nameLabel.Color = Color3.fromRGB(255,255,255)
    nameLabel.Size = 14
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Visible = false
    espData.Name = nameLabel

    -- Distance
    local distLabel = Drawing.new("Text")
    distLabel.Color = Color3.fromRGB(200,200,200)
    distLabel.Size = 12
    distLabel.Center = true
    distLabel.Outline = true
    distLabel.Visible = false
    espData.Dist = distLabel

    -- Health Bar
    local hpBg = Drawing.new("Square")
    hpBg.Filled = true
    hpBg.Color = Color3.fromRGB(0,0,0)
    hpBg.Visible = false
    espData.HPBg = hpBg

    local hpBar = Drawing.new("Square")
    hpBar.Filled = true
    hpBar.Color = Color3.fromRGB(0,255,0)
    hpBar.Visible = false
    espData.HP = hpBar

    -- Tracer
    local tracer = Drawing.new("Line")
    tracer.Color = Settings.TracerColor
    tracer.Thickness = 1
    tracer.Visible = false
    espData.Tracer = tracer

    ESPObjects[player] = espData
end

local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not isEnemy(player) then continue end
        local char = player.Character
        if not char then
            removeESP(player)
            continue
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            removeESP(player)
            continue
        end

        buildESP(player)
        local espData = ESPObjects[player]
        if not espData then continue end

        local myRoot = getRoot()
        local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
        local screenPos, onScreen = getWorldToViewportPoint(root.Position)
        local minX, minY, maxX, maxY, hasBox = getBox(char)

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hp = hum and hum.Health or 0
        local maxHp = hum and hum.MaxHealth or 100

        -- BOX
        if State.ESPBox and hasBox then
            local w = maxX - minX
            local h = maxY - minY
            espData.Box.Position = Vector2.new(minX, minY)
            espData.Box.Size = Vector2.new(w, h)
            espData.Box.Visible = onScreen

            espData.Fill.Position = Vector2.new(minX, minY)
            espData.Fill.Size = Vector2.new(w, h)
            espData.Fill.Visible = onScreen

            -- Name above box
            espData.Name.Text = player.Name
            espData.Name.Position = Vector2.new((minX + maxX)/2, minY - 16)
            espData.Name.Visible = onScreen

            -- Health bar
            local barH = h
            local barW = 4
            espData.HPBg.Position = Vector2.new(minX - 7, minY)
            espData.HPBg.Size = Vector2.new(barW, barH)
            espData.HPBg.Visible = onScreen and State.ESPHealth

            local hpRatio = math.clamp(hp / math.max(maxHp,1), 0, 1)
            espData.HP.Position = Vector2.new(minX - 7, minY + barH * (1 - hpRatio))
            espData.HP.Size = Vector2.new(barW, barH * hpRatio)
            local r = 1 - hpRatio
            local g = hpRatio
            espData.HP.Color = Color3.fromRGB(r*255, g*255, 0)
            espData.HP.Visible = onScreen and State.ESPHealth

            -- Distance
            espData.Dist.Text = math.floor(dist) .. " studs"
            espData.Dist.Position = Vector2.new((minX+maxX)/2, maxY + 2)
            espData.Dist.Visible = onScreen and State.ESPDist
        else
            espData.Box.Visible = false
            espData.Fill.Visible = false
            espData.Name.Visible = false
            espData.HPBg.Visible = false
            espData.HP.Visible = false
            espData.Dist.Visible = false
        end

        -- CHAMS (highlight)
        if State.ESPChams then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    local sel = char:FindFirstChildOfClass("SelectionBox")
                    if not sel then
                        local s = Instance.new("SelectionBox")
                        s.SurfaceColor3 = Settings.ChamsColor
                        s.SurfaceTransparency = 0.5
                        s.Color3 = Settings.ChamsColor
                        s.LineThickness = 0.05
                        s.Adornee = char
                        s.Parent = CoreGui
                    end
                    break
                end
            end
        else
            for _, s in pairs(CoreGui:GetChildren()) do
                if s:IsA("SelectionBox") and s.Adornee == char then
                    s:Destroy()
                end
            end
        end

        -- TRACERS
        if State.ESPTracers then
            local vp = Camera.ViewportSize
            espData.Tracer.From = Vector2.new(vp.X/2, vp.Y)
            espData.Tracer.To = screenPos
            espData.Tracer.Visible = onScreen
        else
            espData.Tracer.Visible = false
        end
    end
end

-- Start ESP loop
Connections["ESPLoop"] = RunService.RenderStepped:Connect(function()
    if State.ESPBox or State.ESPChams or State.ESPTracers then
        updateESP()
    end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ═══════════════════════════════════════════
--          HITBOX EXPANDER
-- ═══════════════════════════════════════════

local function startHitbox()
    State.Hitbox = true
    Connections["HitboxLoop"] = RunService.Heartbeat:Connect(function()
        if not State.Hitbox then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if not isEnemy(player) then continue end
            local char = player.Character
            if not char then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            local existing = root:FindFirstChild("HitboxPart")
            if not existing then
                local hp = Instance.new("Part")
                hp.Name = "HitboxPart"
                hp.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                hp.Transparency = Settings.HitboxTrans
                hp.Color = Settings.HitboxColor
                hp.CanCollide = false
                hp.Anchored = false
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = root
                weld.Part1 = hp
                weld.Parent = hp
                hp.Parent = root
                table.insert(HitboxParts, hp)
            end
        end
    end)
end

local function removeHitbox()
    State.Hitbox = false
    safeDisconnect(Connections["HitboxLoop"])
    Connections["HitboxLoop"] = nil
    for _, part in ipairs(HitboxParts) do
        pcall(function() part:Destroy() end)
    end
    HitboxParts = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local hp = root:FindFirstChild("HitboxPart")
                if hp then hp:Destroy() end
            end
        end
    end
end

-- ═══════════════════════════════════════════
--          AIMBOT
-- ═══════════════════════════════════════════

local function getTarget()
    local bestDist = Settings.AimFOV
    local bestTarget = nil
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if State.AimTeamCheck and not isEnemy(player) then continue end
        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end

        -- Visible check
        if State.AimVisible then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local ray = Workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 1000, rayParams)
            if ray then continue end
        end

        local screenPos, onScreen = getWorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist = (screenPos - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestTarget = head
        end
    end
    return bestTarget
end

local function startAimbot()
    AimConn = RunService.RenderStepped:Connect(function()
        if not State.Aimbot then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local target = getTarget()
        if not target then return end
        local targetPos = target.Position
        local smooth = Settings.AimSmooth
        local currentCF = Camera.CFrame
        local goalCF = CFrame.lookAt(currentCF.Position, targetPos)
        Camera.CFrame = currentCF:Lerp(goalCF, smooth)
    end)
end

local function stopAimbot()
    safeDisconnect(AimConn)
    AimConn = nil
end

-- ═══════════════════════════════════════════
--          HIDE NAME
-- ═══════════════════════════════════════════

local function setHideName(enabled)
    State.HideName = enabled
    local billboard = LocalPlayer.Character and
        LocalPlayer.Character:FindFirstChild("Head") and
        LocalPlayer.Character.Head:FindFirstChild("PlayerNameGui")
    if billboard then
        billboard.Enabled = not enabled
    end
end

-- ═══════════════════════════════════════════
--          CAMERA BUTTON (1st / 3rd)
-- ═══════════════════════════════════════════

local CamButtonGui = nil

local function toggleCameraButton(enabled)
    State.CamButton = enabled
    if enabled then
        CamButtonGui = Instance.new("ScreenGui")
        CamButtonGui.Name = "CamButton"
        CamButtonGui.ResetOnSpawn = false
        CamButtonGui.Parent = CoreGui

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,80,0,30)
        btn.Position = UDim2.new(0.5,-40,0,10)
        btn.Text = "3rd→1st"
        btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = CamButtonGui

        local isFirst = false
        btn.MouseButton1Click:Connect(function()
            isFirst = not isFirst
            Camera.CameraType = Enum.CameraType.Custom
            if isFirst then
                local hum = getHum()
                if hum then hum.CameraOffset = Vector3.new(0,0,-1.5) end
                btn.Text = "1st→3rd"
            else
                local hum = getHum()
                if hum then hum.CameraOffset = Vector3.zero end
                btn.Text = "3rd→1st"
            end
        end)
    else
        if CamButtonGui then CamButtonGui:Destroy() CamButtonGui = nil end
    end
end

-- ═══════════════════════════════════════════
--              SCRIPTS LOADER
-- ═══════════════════════════════════════════

local ScriptURLs = {
    ["Fly GUI"]        = "https://raw.githubusercontent.com/httpsidk/FlyGUI/main/FlyGUI.lua",
    ["Speed GUI"]      = "loadstring(game:HttpGet('https://raw.githubusercontent.com/httpsidk/SpeedGUI/main/SpeedGUI.lua'))()",
    ["Infinite Yield"] = "https://raw.githubusercontent.com/EdgeIY/infinite-yield/master/source",
    ["CMD-X"]          = "https://raw.githubusercontent.com/devSparkle/cmd-x/main/CmdX.lua",
    ["Dark Dex"]       = "https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/DexV4.lua",
}

local function loadScript(name)
    notify("Script Loader", "Loading " .. name .. "...", "terminal")
    task.spawn(function()
        pcall(function()
            if name == "Fly GUI" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/httpsidk/FlyGUI/main/FlyGUI.lua"))()
            elseif name == "Refast GUI" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/0x45io/refast/main/loader"))()
            elseif name == "Speed GUI" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/sgui.lua"))()
            elseif name == "Waypoint GUI" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/AR-DEV-1/AR-DEV-1.github.io/master/GUI/WaypointGui.lua"))()
            elseif name == "Speed X Hub" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Speed-X/main/Source.lua"))()
            elseif name == "Infinite Yield" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infinite-yield/master/source"))()
            elseif name == "Reverse" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/acsu/reverse-script/main/reverse.lua"))()
            elseif name == "Speed CoiledTom" then
                -- CoiledTom Custom Speed
                local hum = getHum()
                if hum then hum.WalkSpeed = 80 end
                notify("Speed CoiledTom", "CoiledTom speed mode: 80!", "zap")
            elseif name == "Platform" then
                local root = getRoot()
                if root then
                    local plat = Instance.new("Part")
                    plat.Anchored = true
                    plat.Size = Vector3.new(10,1,10)
                    plat.CFrame = root.CFrame - Vector3.new(0,3,0)
                    plat.Parent = Workspace
                    game:GetService("Debris"):AddItem(plat, 10)
                    notify("Platform", "Platform created under you!", "layers")
                end
            elseif name == "Desync" then
                local root = getRoot()
                if root then
                    root.CFrame = root.CFrame * CFrame.new(0,100,0)
                    notify("Desync", "Desync applied!", "shuffle")
                end
            elseif name == "Invis Desync" then
                local char = getChar()
                if char then
                    for _, v in pairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then v.LocalTransparencyModifier = 1 end
                    end
                    notify("Invis Desync", "Invisible desync applied!", "eye-off")
                end
            elseif name == "CMD-X" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/devSparkle/cmd-x/main/CmdX.lua"))()
            elseif name == "Dark Dex" then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/DexV4.lua"))()
            end
        end)
    end)
end

-- ═══════════════════════════════════════════
--          SPECTATE SYSTEM
-- ═══════════════════════════════════════════

local SpectateTarget = nil

local function spectatePlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target or not target.Character then
        notify("Spectate", "Player not found!", "alert-circle")
        return
    end
    SpectateTarget = target
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if root then
        Camera.CameraType = Enum.CameraType.Attach
        Camera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid")
        notify("Spectate", "Now spectating " .. playerName, "eye")
    end
end

local function restoreCamera()
    SpectateTarget = nil
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    notify("Spectate", "Camera restored!", "camera")
end

local function teleportToTarget(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target or not target.Character then
        notify("Teleport", "Player not found!", "alert-circle")
        return
    end
    local root = getRoot()
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if root and tRoot then
        root.CFrame = tRoot.CFrame + Vector3.new(0,3,0)
        notify("Teleport", "Teleported to " .. playerName, "map-pin")
    end
end

-- ═══════════════════════════════════════════
--          WEBHOOK FEEDBACK
-- ═══════════════════════════════════════════

local WEBHOOK_URL = "https://discord.com/api/webhooks/1493009540596240504/5-qi3pPMyYUJAlnPmTyTQRC_c-hYLRIKkzyJfY6wi6YN4oXay4iWIlFygtNIVAy0p65I"

local function sendFeedback(message)
    if not message or message == "" then
        notify("Feedback", "Por favor escreva uma mensagem!", "alert-circle")
        return
    end
    task.spawn(function()
        local ok, err = pcall(function()
            local HttpSvc = cloneref(game:GetService("HttpService"))
            local payload = HttpSvc:JSONEncode({
                content = message,
                username = "ShadowOps Hub | Feedback",
                avatar_url = "https://tr.rbxcdn.com/180DAY-53cbf4f9a55bcb38bce64fcac7de2b34/420/420/Image/Webp/noFilter"
            })
            HttpSvc:PostAsync(WEBHOOK_URL, payload, Enum.HttpContentType.ApplicationJson)
        end)
        if ok then
            notify("Feedback", "Mensagem enviada com sucesso! ✅", "check-circle")
        else
            notify("Feedback", "Erro ao enviar: " .. tostring(err), "x-circle")
        end
    end)
end

-- ═══════════════════════════════════════════
--          PANIC / HIDE
-- ═══════════════════════════════════════════

local function panic()
    -- Stop everything
    if State.Fly then stopFly() end
    if State.Noclip then stopNoclip() end
    if State.Fling then stopFling() end
    if State.Aimbot then stopAimbot() end
    if State.FreeCamera then stopFreeCamera() end

    -- Remove all drawings
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
    end

    -- Hide GUI
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui.Name == "WindUI" or gui.Name == "ShadowOpsHub" then
            gui.Enabled = false
        end
    end
    notify("PANIC", "All hacks stopped! GUI hidden.", "shield")
end

-- ═══════════════════════════════════════════
--          DEATH / RESPAWN HANDLER
-- ═══════════════════════════════════════════

local function onCharacterAdded(char)
    char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.5)
    -- Reapply persistent settings
    if State.SpeedHack then
        local hum = getHum()
        if hum then hum.WalkSpeed = Settings.WalkSpeed end
    end
    if State.GodMode then applyGodMode() end
    if State.AntiVoid then stopAntiVoid() startAntiVoid() end
    if State.AntiStun then stopAntiStun() startAntiStun() end
    if State.Fly then stopFly() end
    if State.Noclip then stopNoclip() startNoclip() end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ═══════════════════════════════════════════
--          BUILD WINDUI WINDOW
-- ═══════════════════════════════════════════

local Window = WindUI:CreateWindow({
    Title  = "ShadowOps Hub",
    Author = "by CoiledTom",
    Icon   = "rocket",
    Folder = "ShadowOpsHub",
    Theme  = "Dark",
    NewElements = true,
    OpenButton = {
        Title     = "ShadowOps Hub",
        Enabled   = true,
        Draggable = true,
        Scale     = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#7F00FF"),
            Color3.fromHex("#E100FF")
        ),
    },
    Topbar = {
        Height      = 44,
        ButtonsType = "Default",
    },
})

Window:Tag({
    Title = "v6.0",
    Icon  = "rocket",
    Color = Color3.fromHex("#7F00FF"),
    Border = true,
})

-- ═══════════════════════════════════════════
--          TAB: LOGS
-- ═══════════════════════════════════════════

local LogsTab = Window:Tab({
    Title = "Logs",
    Icon  = "scroll-text",
})

do
    local s1 = LogsTab:Section({ Title = "Support & Info" })

    s1:Section({
        Title = "⚠️ Suporte: Entre no servidor do Discord para ajuda, reportar bugs e receber atualizações.",
        TextSize = 14,
        TextTransparency = 0.2,
    })

    s1:Button({
        Title    = "📋 Copiar Link do Discord",
        Icon     = "copy",
        Color    = Color3.fromHex("#5865F2"),
        Justify  = "Center",
        Callback = function()
            pcall(function() setclipboard("https://discord.gg/shadowopshub") end)
            notify("Discord", "Link copiado!", "copy")
        end,
    })

    local s2 = LogsTab:Section({ Title = "Changelog — ShadowOps Hub" })

    s2:Section({
        Title = [[v6.0 — Release Atual
• Sistema WindUI v2 completo
• ESP Box 2D, Chams, Tracers, Distance, Health
• Hitbox Expander com cor e transparência
• Aimbot com FOV, Smooth, Visible Check
• Anti-Fling, Anti-Knockback, Anti-Stun, Anti-Slow
• God Mode, Anti-Void, Delete Ragdoll
• Noclip, Fly, FreeCamera
• Server Hop, Auto Rejoin, Anti-AFK, Anti-Kick
• FPS Boost, Anti-Lag, Low Poly, Texture Low, Decals
• Scripts externos integrados
• Sistema de Feedback com Webhook
• FullBright, No Fog, Night Mode, FOV, Mapa Transparente
• Spectate, Teleporte, Câmera 1ª/3ª pessoa
• Gravidade Lunar, Hide Name, Shift Lock
• Sistema de Pânico (panic button)
• Salvar / Carregar / Resetar Config
v5.0 — Aimbot reworked
v4.0 — ESP completo adicionado
v3.0 — Performance tab adicionada
v2.0 — WindUI integrado
v1.0 — Release inicial]],
        TextSize = 13,
        TextTransparency = 0.3,
    })
end

-- ═══════════════════════════════════════════
--          TAB: USEFUL
-- ═══════════════════════════════════════════

local UsefulTab = Window:Tab({
    Title = "Useful",
    Icon  = "star",
})

do
    local sFling = UsefulTab:Section({ Title = "Fling" })

    sFling:Toggle({
        Title    = "Touch Fling",
        Desc     = "Empurra objetos e players próximos violentamente",
        Icon     = "wind",
        Value    = false,
        Callback = function(v)
            if v then startFling() else stopFling() end
        end,
    })

    sFling:Toggle({
        Title    = "Anti-Fling",
        Desc     = "Impede que você seja arremessado",
        Icon     = "shield",
        Value    = false,
        Callback = function(v)
            if v then startAntiFling() else stopAntiFling() end
        end,
    })

    local sProt = UsefulTab:Section({ Title = "Proteções Básicas" })

    sProt:Toggle({
        Title    = "God Mode",
        Desc     = "Vida infinita",
        Icon     = "heart",
        Value    = false,
        Callback = function(v)
            if v then applyGodMode() else removeGodMode() end
        end,
    })

    sProt:Toggle({
        Title    = "Anti-Void",
        Desc     = "Teleporta de volta ao cair do mapa",
        Icon     = "anchor",
        Value    = false,
        Callback = function(v)
            if v then startAntiVoid() else stopAntiVoid() end
        end,
    })

    sProt:Button({
        Title    = "Delete Ragdoll",
        Desc     = "Apaga partes físicas de morte",
        Icon     = "trash-2",
        Callback = function() deleteRagdoll() end,
    })

    local sTools = UsefulTab:Section({ Title = "Tools" })

    sTools:Toggle({
        Title    = "Instant Interact",
        Desc     = "Interage com objetos instantaneamente",
        Icon     = "mouse-pointer",
        Value    = false,
        Callback = function(v)
            if v then
                Connections["InstantInteract"] = RunService.Heartbeat:Connect(function()
                    local hum = getHum()
                    if hum then
                        local char = getChar()
                        for _, obj in pairs(Workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") then
                                local dist = obj.MaxActivationDistance
                                obj.MaxActivationDistance = 1e6
                            end
                        end
                    end
                end)
            else
                safeDisconnect(Connections["InstantInteract"])
                Connections["InstantInteract"] = nil
            end
        end,
    })

    sTools:Button({
        Title    = "Destroy Tool",
        Desc     = "Remove a tool equipada",
        Icon     = "hammer",
        Callback = function()
            local char = getChar()
            if char then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then tool:Destroy() end
                end
            end
        end,
    })

    sTools:Toggle({
        Title    = "Fly Tool",
        Desc     = "Ativa o voo integrado",
        Icon     = "plane",
        Value    = false,
        Callback = function(v)
            if v then startFly() else stopFly() end
        end,
    })

    sTools:Toggle({
        Title    = "Shift Lock",
        Desc     = "Ativa travamento de visão no mouse",
        Icon     = "lock",
        Value    = false,
        Callback = function(v) setShiftLock(v) end,
    })
end

-- ═══════════════════════════════════════════
--          TAB: SCRIPTS
-- ═══════════════════════════════════════════

local ScriptsTab = Window:Tab({
    Title = "Scripts",
    Icon  = "terminal",
})

do
    local scriptList = {
        { name = "Fly GUI",         desc = "GUI completa de voo",                icon = "plane" },
        { name = "Refast GUI",      desc = "GUI de velocidade Refast",            icon = "zap" },
        { name = "Speed GUI",       desc = "Interface de velocidade",             icon = "gauge" },
        { name = "Waypoint GUI",    desc = "Sistema de waypoints no mapa",        icon = "map-pin" },
        { name = "Speed X Hub",     desc = "Hub de velocidade avançado",          icon = "fast-forward" },
        { name = "Infinite Yield",  desc = "Admin commands poderoso",             icon = "command" },
        { name = "Reverse",         desc = "Reverse engineering script",          icon = "rotate-ccw" },
        { name = "Speed CoiledTom", desc = "Modo velocidade do CoiledTom (80)",  icon = "rocket" },
        { name = "Platform",        desc = "Cria plataforma abaixo de você",      icon = "layers" },
        { name = "Desync",          desc = "Aplica desync de posição",            icon = "shuffle" },
        { name = "Invis Desync",    desc = "Torna invisível + desync",            icon = "eye-off" },
        { name = "CMD-X",           desc = "Admin commands CMD-X",                icon = "terminal" },
        { name = "Dark Dex",        desc = "Explorador de instâncias",            icon = "search" },
    }

    local sec = ScriptsTab:Section({ Title = "Script Loader — Toggle para carregar" })

    for _, script in ipairs(scriptList) do
        local scriptName = script.name
        sec:Button({
            Title    = "▶ " .. scriptName,
            Desc     = script.desc,
            Icon     = script.icon,
            Callback = function()
                loadScript(scriptName)
            end,
        })
    end
end

-- ═══════════════════════════════════════════
--          TAB: PLAYER
-- ═══════════════════════════════════════════

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon  = "user",
})

do
    local sMove = PlayerTab:Section({ Title = "Movimento" })

    local speedToggle
    speedToggle = sMove:Toggle({
        Title    = "Speed Hack",
        Desc     = "Ativa velocidade customizada",
        Icon     = "gauge",
        Value    = false,
        Flag     = "SpeedHack",
        Callback = function(v)
            State.SpeedHack = v
            local hum = getHum()
            if hum then hum.WalkSpeed = v and Settings.WalkSpeed or 16 end
        end,
    })

    sMove:Slider({
        Title    = "WalkSpeed",
        Desc     = "Velocidade de caminhada",
        Flag     = "WalkSpeed",
        Step     = 1,
        IsTextbox = true,
        Value    = { Min = 0, Max = 500, Default = 16 },
        Callback = function(v)
            Settings.WalkSpeed = v
            if State.SpeedHack then setSpeed(v) end
        end,
    })

    sMove:Slider({
        Title    = "JumpPower",
        Desc     = "Força do pulo",
        Flag     = "JumpPower",
        Step     = 1,
        IsTextbox = true,
        Value    = { Min = 0, Max = 500, Default = 50 },
        Callback = function(v)
            Settings.JumpPower = v
            local hum = getHum()
            if hum then hum.JumpPower = v end
        end,
    })

    sMove:Toggle({
        Title    = "Jump Hack",
        Desc     = "Aumenta força do pulo",
        Icon     = "chevrons-up",
        Value    = false,
        Callback = function(v)
            State.JumpHack = v
            local hum = getHum()
            if hum then hum.JumpPower = v and 200 or Settings.JumpPower end
        end,
    })

    sMove:Toggle({
        Title    = "Infinite Jump",
        Desc     = "Pule infinitamente no ar",
        Icon     = "arrow-up",
        Value    = false,
        Flag     = "InfiniteJump",
        Callback = function(v)
            if v then startInfiniteJump() else stopInfiniteJump() end
        end,
    })

    local sAdv = PlayerTab:Section({ Title = "Movimento Avançado" })

    sAdv:Toggle({
        Title    = "Noclip",
        Desc     = "Atravessa paredes",
        Icon     = "ghost",
        Value    = false,
        Flag     = "Noclip",
        Callback = function(v)
            if v then startNoclip() else stopNoclip() end
        end,
    })

    sAdv:Toggle({
        Title    = "Fly",
        Desc     = "Voo livre com WASD + Space/Ctrl",
        Icon     = "feather",
        Value    = false,
        Flag     = "Fly",
        Callback = function(v)
            if v then startFly() else stopFly() end
        end,
    })

    sAdv:Slider({
        Title    = "Fly Speed",
        Desc     = "Velocidade do voo",
        Flag     = "FlySpeed",
        Step     = 1,
        IsTextbox = true,
        Value    = { Min = 5, Max = 500, Default = 50 },
        Callback = function(v) Settings.FlySpeed = v end,
    })

    local sDef = PlayerTab:Section({ Title = "Defesas / Proteções" })

    sDef:Toggle({
        Title    = "Anti Knockback",
        Desc     = "Evita ser empurrado por ataques",
        Icon     = "shield",
        Value    = false,
        Flag     = "AntiKB",
        Callback = function(v)
            if v then startAntiKnockback() else stopAntiKnockback() end
        end,
    })

    sDef:Toggle({
        Title    = "Anti Stun",
        Desc     = "Impede atordoamento e ragdoll",
        Icon     = "shield-check",
        Value    = false,
        Flag     = "AntiStun",
        Callback = function(v)
            if v then startAntiStun() else stopAntiStun() end
        end,
    })

    sDef:Toggle({
        Title    = "Anti Slow",
        Desc     = "Mantém velocidade normal sem slow",
        Icon     = "shield-alert",
        Value    = false,
        Flag     = "AntiSlow",
        Callback = function(v)
            if v then startAntiSlow() else stopAntiSlow() end
        end,
    })

    local sGrav = PlayerTab:Section({ Title = "Gravidade" })

    sGrav:Toggle({
        Title    = "Lunar Gravity",
        Desc     = "Gravidade baixa para pulos altos",
        Icon     = "moon",
        Value    = false,
        Callback = function(v) setLunarGravity(v) end,
    })

    sGrav:Slider({
        Title    = "Gravity Value",
        Desc     = "Valor da gravidade do Workspace",
        Step     = 1,
        IsTextbox = true,
        Value    = { Min = 0, Max = 400, Default = 196 },
        Callback = function(v) Workspace.Gravity = v end,
    })

    local sFreeCam = PlayerTab:Section({ Title = "Free Camera" })

    sFreeCam:Toggle({
        Title    = "Free Camera",
        Desc     = "Câmera livre pelo mapa (WASD + Q/E)",
        Icon     = "camera",
        Value    = false,
        Callback = function(v)
            if v then startFreeCamera() else stopFreeCamera() end
        end,
    })

    sFreeCam:Slider({
        Title    = "FreeCam Speed",
        Desc     = "Velocidade da câmera livre",
        Step     = 1,
        IsTextbox = true,
        Value    = { Min = 5, Max = 300, Default = 25 },
        Callback = function(v) Settings.FreeCamSpeed = v end,
    })
end

-- ═══════════════════════════════════════════
--          TAB: COMBAT
-- ═══════════════════════════════════════════

local CombatTab = Window:Tab({
    Title = "Combat",
    Icon  = "crosshair",
})

do
    -- AIMBOT
    local sAim = CombatTab:Section({ Title = "Aimbot" })

    sAim:Toggle({
        Title    = "Aimbot",
        Desc     = "Mira automática no inimigo (segure botão direito)",
        Icon     = "crosshair",
        Value    = false,
        Flag     = "Aimbot",
        Callback = function(v)
            State.Aimbot = v
            if v then startAimbot() else stopAimbot() end
        end,
    })

    sAim:Toggle({
        Title    = "Team Check",
        Desc     = "Ignora membros do próprio time",
        Icon     = "users",
        Value    = false,
        Flag     = "AimTeamCheck",
        Callback = function(v) State.AimTeamCheck = v end,
    })

    sAim:Toggle({
        Title    = "Visible Check",
        Desc     = "Mira apenas em inimigos visíveis",
        Icon     = "eye",
        Value    = false,
        Callback = function(v) State.AimVisible = v end,
    })

    sAim:Slider({
        Title    = "FOV Size",
        Desc     = "Raio do campo de mira em pixels",
        Flag     = "AimFOV",
        Step     = 5,
        IsTextbox = true,
        Value    = { Min = 10, Max = 500, Default = 120 },
        Callback = function(v) Settings.AimFOV = v end,
    })

    sAim:Slider({
        Title    = "Smooth",
        Desc     = "Suavidade do aimbot (0.01 = máx suave)",
        Flag     = "AimSmooth",
        Step     = 0.01,
        IsTextbox = true,
        Value    = { Min = 0.01, Max = 1, Default = 0.25 },
        Callback = function(v) Settings.AimSmooth = v end,
    })

    -- ESP BOX
    local sESP = CombatTab:Section({ Title = "ESP Box 2D" })

    sESP:Toggle({
        Title    = "ESP Box",
        Desc     = "Caixa 2D ao redor dos inimigos",
        Icon     = "box",
        Value    = false,
        Flag     = "ESPBox",
        Callback = function(v) State.ESPBox = v end,
    })

    sESP:Toggle({
        Title    = "ESP Fill",
        Desc     = "Preencher a caixa ESP",
        Icon     = "square",
        Value    = false,
        Callback = function(v)
            -- Fill is controlled via opacity in ESP
        end,
    })

    sESP:Slider({
        Title    = "Fill Opacity",
        Desc     = "Transparência do preenchimento",
        Step     = 0.05,
        IsTextbox = true,
        Value    = { Min = 0, Max = 1, Default = 0.5 },
        Callback = function(v)
            Settings.ESPFillAlpha = v
            for _, esp in pairs(ESPObjects) do
                if esp.Fill then esp.Fill.Transparency = v end
            end
        end,
    })

    sESP:Toggle({
        Title    = "Distance ESP",
        Desc     = "Mostra distância dos inimigos",
        Icon     = "ruler",
        Value    = false,
        Callback = function(v) State.ESPDist = v end,
    })

    sESP:Toggle({
        Title    = "Health ESP",
        Desc     = "Mostra barra de vida dos inimigos",
        Icon     = "heart-pulse",
        Value    = false,
        Callback = function(v) State.ESPHealth = v end,
    })

    -- CHAMS
    local sChams = CombatTab:Section({ Title = "Chams" })

    sChams:Toggle({
        Title    = "Chams",
        Desc     = "Destaque colorido nos personagens",
        Icon     = "paintbrush",
        Value    = false,
        Callback = function(v) State.ESPChams = v end,
    })

    -- TRACERS
    local sTracers = CombatTab:Section({ Title = "Tracers" })

    sTracers:Toggle({
        Title    = "Tracers",
        Desc     = "Linha da tela até o inimigo",
        Icon     = "git-merge",
        Value    = false,
        Callback = function(v) State.ESPTracers = v end,
    })

    -- HITBOX
    local sHitbox = CombatTab:Section({ Title = "Hitbox Expander" })

    sHitbox:Toggle({
        Title    = "Hitbox Expander",
        Desc     = "Aumenta hitbox invisível dos inimigos",
        Icon     = "maximize",
        Value    = false,
        Flag     = "Hitbox",
        Callback = function(v)
            if v then startHitbox() else removeHitbox() end
        end,
    })

    sHitbox:Slider({
        Title    = "Hitbox Size",
        Desc     = "Tamanho da hitbox expandida",
        Flag     = "HitboxSize",
        Step     = 0.5,
        IsTextbox = true,
        Value    = { Min = 1, Max = 30, Default = 5 },
        Callback = function(v)
            Settings.HitboxSize = v
            -- Update existing hitboxes
            for _, part in ipairs(HitboxParts) do
                pcall(function() part.Size = Vector3.new(v,v,v) end)
            end
        end,
    })

    sHitbox:Slider({
        Title    = "Hitbox Transparency",
        Desc     = "Transparência da hitbox expandida",
        Step     = 0.05,
        IsTextbox = true,
        Value    = { Min = 0, Max = 1, Default = 0.5 },
        Callback = function(v)
            Settings.HitboxTrans = v
            for _, part in ipairs(HitboxParts) do
                pcall(function() part.Transparency = v end)
            end
        end,
    })
end

-- ═══════════════════════════════════════════
--          TAB: DESEMPENHO
-- ═══════════════════════════════════════════

local PerfTab = Window:Tab({
    Title = "Desempenho",
    Icon  = "cpu",
})

do
    local sPerfMain = PerfTab:Section({ Title = "Otimizações" })

    sPerfMain:Toggle({
        Title    = "FPS Boost",
        Desc     = "Modo máximo de desempenho",
        Icon     = "zap",
        Value    = false,
        Callback = function(v)
            if v then applyFPSBoost()
            else settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Anti-Lag",
        Desc     = "Reduz física do ambiente",
        Icon     = "activity",
        Value    = false,
        Callback = function(v)
            if v then applyAntiLag()
            else
                for _, part in pairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CastShadow = true end)
                    end
                end
            end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Disable Particles",
        Desc     = "Remove fumaça, fogo e efeitos",
        Icon     = "wind",
        Value    = false,
        Callback = function(v)
            if v then disableParticles() end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Texture Low",
        Desc     = "Troca texturas por plástico liso",
        Icon     = "image-off",
        Value    = false,
        Callback = function(v)
            if v then setTextureLow() end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Remove Decals",
        Desc     = "Remove adesivos e imagens das paredes",
        Icon     = "eraser",
        Value    = false,
        Callback = function(v)
            if v then removeDecals() end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Dynamic Render Distance",
        Desc     = "Ajusta gráficos baseado na internet",
        Icon     = "wifi",
        Value    = false,
        Callback = function(v)
            if v then setDynRender()
            else settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Entity Limiter",
        Desc     = "Limita objetos soltos (máx 80)",
        Icon     = "layers",
        Value    = false,
        Callback = function(v)
            if v then setEntityLimiter() end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Lighting Cleaner",
        Desc     = "Remove sombras e efeitos de câmera",
        Icon     = "sun",
        Value    = false,
        Callback = function(v)
            if v then cleanLighting() end
        end,
    })

    sPerfMain:Toggle({
        Title    = "Low Poly Mode",
        Desc     = "Diminui qualidade 3D do mapa",
        Icon     = "triangle",
        Value    = false,
        Callback = function(v)
            if v then setLowPoly() end
        end,
    })

    local sPerfStats = PerfTab:Section({ Title = "Render Quality" })

    sPerfStats:Slider({
        Title    = "Quality Level",
        Desc     = "Nível de qualidade 1-21",
        Step     = 1,
        IsTextbox = true,
        Value    = { Min = 1, Max = 21, Default = 10 },
        Callback = function(v)
            settings().Rendering.QualityLevel = v
        end,
    })
end

-- ═══════════════════════════════════════════
--          TAB: SETTINGS
-- ═══════════════════════════════════════════

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon  = "settings",
})

do
    -- Sistemas v6.0
    local sSys = SettingsTab:Section({ Title = "Sistemas v6.0" })

    sSys:Toggle({
        Title    = "Ocultar Próprio Nome",
        Desc     = "Esconde seu nick no jogo",
        Icon     = "user-x",
        Value    = false,
        Callback = function(v) setHideName(v) end,
    })

    sSys:Toggle({
        Title    = "Botão 1ª/3ª Pessoa",
        Desc     = "Adiciona botão de câmera na tela",
        Icon     = "camera",
        Value    = false,
        Callback = function(v) toggleCameraButton(v) end,
    })

    -- Spectate
    local sSpec = SettingsTab:Section({ Title = "Visualizar Players (Spectate)" })

    local spectateDropdown
    spectateDropdown = sSpec:Dropdown({
        Title    = "Selecionar Jogador",
        Desc     = "Escolha quem spectatar",
        Values   = getPlayers(),
        Value    = 1,
        Callback = function(v) end,
    })

    sSpec:Button({
        Title    = "🔄 Atualizar Lista",
        Icon     = "refresh-cw",
        Callback = function()
            spectateDropdown:Refresh(getPlayers())
            notify("Spectate", "Lista atualizada!", "refresh-cw")
        end,
    })

    local selectedSpectate = nil
    sSpec:Button({
        Title    = "👁 Câmera no Player",
        Icon     = "eye",
        Callback = function()
            if spectateDropdown then
                spectatePlayer(tostring(spectateDropdown.Value or ""))
            end
        end,
    })

    sSpec:Button({
        Title    = "📷 Restaurar Câmera",
        Icon     = "camera-off",
        Callback = function() restoreCamera() end,
    })

    sSpec:Button({
        Title    = "📍 Teleporte até Alvo",
        Icon     = "map-pin",
        Callback = function()
            if spectateDropdown then
                teleportToTarget(tostring(spectateDropdown.Value or ""))
            end
        end,
    })

    -- Proteções
    local sProt = SettingsTab:Section({ Title = "Proteções" })

    sProt:Toggle({
        Title    = "Anti-AFK",
        Desc     = "Evita ser desconectado por inatividade",
        Icon     = "clock",
        Value    = false,
        Callback = function(v)
            if v then startAntiAFK() else stopAntiAFK() end
        end,
    })

    sProt:Toggle({
        Title    = "Anti-Kick / Anti-Ban",
        Desc     = "Bloqueia comandos de kick do servidor",
        Icon     = "shield-ban",
        Value    = false,
        Callback = function(v)
            State.AntiKick = v
            if v then
                pcall(function() hookAntiKick() end)
                notify("Anti-Kick", "Proteção ativada!", "shield")
            else
                notify("Anti-Kick", "Proteção desativada!", "shield-off")
            end
        end,
    })

    -- Servidor
    local sSrv = SettingsTab:Section({ Title = "Servidor" })

    sSrv:Button({
        Title    = "🔁 Rejoin Manual",
        Desc     = "Reconecta no servidor atual",
        Icon     = "rotate-cw",
        Callback = function()
            local TpSvc = game:GetService("TeleportService")
            TpSvc:Teleport(game.PlaceId, LocalPlayer)
        end,
    })

    sSrv:Toggle({
        Title    = "Auto Rejoin",
        Desc     = "Reconecta automaticamente se cair",
        Icon     = "refresh-ccw",
        Value    = false,
        Callback = function(v)
            State.AutoRejoin = v
            if v then setupAutoRejoin() end
        end,
    })

    sSrv:Button({
        Title    = "🌐 Server Hopper",
        Desc     = "Pula para servidor menos cheio e com menor ping",
        Icon     = "arrow-right-left",
        Callback = function() startServerHop() end,
    })

    -- Atalhos
    local sKeys = SettingsTab:Section({ Title = "Atalhos" })

    sKeys:Section({
        Title = "Tecla de Pânico: " .. tostring(Settings.PanicKey.Name) .. " (configurável abaixo)",
        TextSize = 13,
        TextTransparency = 0.3,
    })

    sKeys:Dropdown({
        Title    = "Tecla Pânico",
        Desc     = "Tecla para esconder o menu e parar tudo",
        Values   = {"RightShift", "F9", "Delete", "Insert", "End", "Home", "PageUp", "PageDown"},
        Value    = 1,
        Callback = function(v)
            Settings.PanicKey = Enum.KeyCode[v] or Enum.KeyCode.RightShift
            notify("Atalho", "Tecla de pânico: " .. v, "keyboard")
        end,
    })

    -- Configurações Globais
    local sCfg = SettingsTab:Section({ Title = "Configurações Globais" })

    sCfg:Button({
        Title    = "💾 Salvar Config",
        Icon     = "save",
        Color    = Color3.fromHex("#22c55e"),
        Justify  = "Center",
        Callback = function()
            Window:SaveConfig("default")
            notify("Config", "Configurações salvas!", "save")
        end,
    })

    sCfg:Button({
        Title    = "📂 Carregar Config",
        Icon     = "folder-open",
        Color    = Color3.fromHex("#3b82f6"),
        Justify  = "Center",
        Callback = function()
            Window:LoadConfig("default")
            notify("Config", "Configurações carregadas!", "folder-open")
        end,
    })

    sCfg:Button({
        Title    = "🔄 Resetar Config",
        Icon     = "refresh-cw",
        Color    = Color3.fromHex("#f59e0b"),
        Justify  = "Center",
        Callback = function()
            Window:ResetConfig()
            notify("Config", "Configurações resetadas!", "refresh-cw")
        end,
    })

    sCfg:Button({
        Title    = "🚨 PANIC",
        Desc     = "Para tudo e esconde o menu",
        Icon     = "alert-octagon",
        Color    = Color3.fromHex("#ef4444"),
        Justify  = "Center",
        Callback = function() panic() end,
    })
end

-- ═══════════════════════════════════════════
--          TAB: SERVER INFO
-- ═══════════════════════════════════════════

local ServerTab = Window:Tab({
    Title = "Server Info",
    Icon  = "server",
})

do
    local sGame = ServerTab:Section({ Title = "Game Info" })

    sGame:Section({
        Title = "🎮 Game: " .. tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"),
        TextSize = 14,
    })

    sGame:Section({
        Title = "📋 Place ID: " .. tostring(game.PlaceId) ..
                "\n🆔 Job ID: " .. tostring(game.JobId):sub(1, 18) .. "..." ..
                "\n👥 Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers),
        TextSize = 13,
        TextTransparency = 0.3,
    })

    sGame:Button({
        Title    = "📋 Copiar Job ID",
        Icon     = "copy",
        Callback = function()
            pcall(function() setclipboard(game.JobId) end)
            notify("Server Info", "Job ID copiado!", "copy")
        end,
    })

    local sLive = ServerTab:Section({ Title = "Live Stats" })

    local fpsLabel = sLive:Section({
        Title = "FPS: carregando...",
        TextSize = 14,
    })

    local pingLabel = sLive:Section({
        Title = "Ping: carregando...",
        TextSize = 14,
    })

    local playersLabel = sLive:Section({
        Title = "Players Online: carregando...",
        TextSize = 14,
    })

    -- Live stats updater
    local lastUpdate = 0
    local frameCount = 0
    local lastFPS = 0

    Connections["LiveStats"] = RunService.RenderStepped:Connect(function(dt)
        frameCount = frameCount + 1
        lastUpdate = lastUpdate + dt
        if lastUpdate >= 1 then
            lastFPS = frameCount
            frameCount = 0
            lastUpdate = 0

            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)

            pcall(function()
                fpsLabel.Title = "⚡ FPS: " .. tostring(lastFPS)
                pingLabel.Title = "📡 Ping: " .. tostring(ping) .. "ms"
                playersLabel.Title = "👥 Players: " .. tostring(#Players:GetPlayers())
            end)
        end
    end)

    local sDeaths = ServerTab:Section({ Title = "Player Stats" })
    local deathCount = 0

    local deathLabel = sDeaths:Section({
        Title = "💀 Mortes: 0",
        TextSize = 14,
    })

    local function trackDeaths(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.Died:Connect(function()
            deathCount = deathCount + 1
            pcall(function()
                deathLabel.Title = "💀 Mortes: " .. tostring(deathCount)
            end)
        end)
    end

    if LocalPlayer.Character then trackDeaths(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(trackDeaths)

    sDeaths:Button({
        Title    = "🔄 Resetar Mortes",
        Icon     = "refresh-cw",
        Callback = function()
            deathCount = 0
            pcall(function() deathLabel.Title = "💀 Mortes: 0" end)
        end,
    })
end

-- ═══════════════════════════════════════════
--          TAB: GUI / UI
-- ═══════════════════════════════════════════

local GUITab = Window:Tab({
    Title = "GUI / UI",
    Icon  = "palette",
})

do
    local sVisuals = GUITab:Section({ Title = "Visuais do Mundo" })

    sVisuals:Toggle({
        Title    = "FullBright",
        Desc     = "Mapa sempre iluminado",
        Icon     = "sun",
        Value    = false,
        Flag     = "FullBright",
        Callback = function(v) setFullBright(v) end,
    })

    sVisuals:Toggle({
        Title    = "No Fog",
        Desc     = "Remove névoa do mapa",
        Icon     = "cloud-off",
        Value    = false,
        Callback = function(v) setNoFog(v) end,
    })

    sVisuals:Toggle({
        Title    = "Night Mode",
        Desc     = "Deixa o mapa no período da noite",
        Icon     = "moon",
        Value    = false,
        Callback = function(v) setNightMode(v) end,
    })

    sVisuals:Slider({
        Title    = "Custom FOV",
        Desc     = "Campo de visão customizado",
        Flag     = "CustomFOV",
        Step     = 1,
        IsTextbox = true,
        Value    = { Min = 30, Max = 120, Default = 70 },
        Callback = function(v) setFOV(v) end,
    })

    sVisuals:Slider({
        Title    = "Map Transparency",
        Desc     = "Transparência dos objetos do mapa",
        Step     = 0.05,
        IsTextbox = true,
        Value    = { Min = 0, Max = 1, Default = 0 },
        Callback = function(v) setObjTransparency(v) end,
    })

    sVisuals:Button({
        Title    = "Reset FOV",
        Icon     = "rotate-ccw",
        Callback = function() resetFOV() end,
    })

    local sTheme = GUITab:Section({ Title = "Tema / Aparência" })

    sTheme:Dropdown({
        Title    = "Tema",
        Desc     = "Escolha o tema da interface",
        Values   = {"Dark", "Light", "Rose", "Plant", "Indigo", "Sky", "Violet", "Amber", "Aqua"},
        Value    = "Dark",
        Callback = function(v)
            Window:SetTheme(v)
        end,
    })

    sTheme:Button({
        Title    = "Reset Tema",
        Icon     = "rotate-ccw",
        Callback = function()
            Window:SetTheme("Dark")
            notify("Theme", "Tema resetado para Dark!", "palette")
        end,
    })

    local sEspColors = GUITab:Section({ Title = "Cores do ESP" })

    sEspColors:Section({
        Title = "Ajuste as cores dos elementos de ESP e Hitbox abaixo:",
        TextSize = 13,
        TextTransparency = 0.3,
    })

    sEspColors:Button({
        Title    = "ESP Box: Branco",
        Icon     = "box",
        Callback = function()
            Settings.ESPBoxColor = Color3.fromRGB(255,255,255)
            for _, esp in pairs(ESPObjects) do
                if esp.Box then esp.Box.Color = Settings.ESPBoxColor end
            end
            notify("ESP", "Cor da caixa: Branco", "box")
        end,
    })

    sEspColors:Button({
        Title    = "ESP Box: Vermelho",
        Color    = Color3.fromHex("#ef4444"),
        Icon     = "box",
        Callback = function()
            Settings.ESPBoxColor = Color3.fromRGB(255,50,50)
            for _, esp in pairs(ESPObjects) do
                if esp.Box then esp.Box.Color = Settings.ESPBoxColor end
            end
        end,
    })

    sEspColors:Button({
        Title    = "ESP Box: Verde",
        Color    = Color3.fromHex("#22c55e"),
        Icon     = "box",
        Callback = function()
            Settings.ESPBoxColor = Color3.fromRGB(50,255,100)
            for _, esp in pairs(ESPObjects) do
                if esp.Box then esp.Box.Color = Settings.ESPBoxColor end
            end
        end,
    })

    sEspColors:Button({
        Title    = "Tracer: Amarelo",
        Icon     = "git-merge",
        Callback = function()
            Settings.TracerColor = Color3.fromRGB(255,255,0)
            for _, esp in pairs(ESPObjects) do
                if esp.Tracer then esp.Tracer.Color = Settings.TracerColor end
            end
        end,
    })

    sEspColors:Button({
        Title    = "Tracer: Ciano",
        Color    = Color3.fromHex("#06b6d4"),
        Icon     = "git-merge",
        Callback = function()
            Settings.TracerColor = Color3.fromRGB(0,200,255)
            for _, esp in pairs(ESPObjects) do
                if esp.Tracer then esp.Tracer.Color = Settings.TracerColor end
            end
        end,
    })

    sEspColors:Button({
        Title    = "Chams: Vermelho",
        Color    = Color3.fromHex("#ef4444"),
        Icon     = "paintbrush",
        Callback = function()
            Settings.ChamsColor = Color3.fromRGB(255,0,0)
        end,
    })

    sEspColors:Button({
        Title    = "Chams: Roxo",
        Color    = Color3.fromHex("#a855f7"),
        Icon     = "paintbrush",
        Callback = function()
            Settings.ChamsColor = Color3.fromRGB(170,0,255)
        end,
    })
end

-- ═══════════════════════════════════════════
--          TAB: FEEDBACK
-- ═══════════════════════════════════════════

local FeedbackTab = Window:Tab({
    Title = "Feedback",
    Icon  = "message-square",
})

do
    local sFB = FeedbackTab:Section({ Title = "Enviar Feedback" })

    sFB:Section({
        Title = "💬 Deixe sua mensagem, sugestão ou reporte um bug. Será enviado diretamente para o Discord do desenvolvedor!",
        TextSize = 13,
        TextTransparency = 0.2,
    })

    local feedbackInput = sFB:Input({
        Title       = "Mensagem",
        Desc        = "Escreva seu feedback aqui",
        Icon        = "message-circle",
        Type        = "Textarea",
        Placeholder = "Digite sua mensagem, sugestão ou bug report...",
        Value       = "",
        Callback    = function(text)
            -- stored on change
        end,
    })

    sFB:Button({
        Title    = "📤 Enviar Feedback",
        Desc     = "Envia sua mensagem para o Discord",
        Icon     = "send",
        Color    = Color3.fromHex("#5865F2"),
        Justify  = "Center",
        Callback = function()
            local msg = feedbackInput and feedbackInput.Value or ""
            sendFeedback(msg)
        end,
    })

    sFB:Section({
        Title = "⚠️ Não envie informações pessoais. Feedbacks são anônimos (sem seu username Roblox).",
        TextSize = 12,
        TextTransparency = 0.4,
    })
end

-- ═══════════════════════════════════════════
--          PANIC KEY LISTENER
-- ═══════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.PanicKey then
        panic()
    end
    -- Toggle menu with RightAlt
    if input.KeyCode == Enum.KeyCode.RightAlt then
        Window:Toggle()
    end
end)

-- ═══════════════════════════════════════════
--          STARTUP NOTIFICATION
-- ═══════════════════════════════════════════

task.wait(1)
WindUI:Notify({
    Title   = "ShadowOps Hub v6.0",
    Content = "Carregado com sucesso! Autor: CoiledTom\nPanik: " .. Settings.PanicKey.Name .. " | Menu: RightAlt",
    Icon    = "rocket",
    Duration = 6,
})

-- ═══════════════════════════════════════════
--          CLEANUP ON CLOSE
-- ═══════════════════════════════════════════

game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    if State.Fly then stopFly() end
    if State.FreeCamera then stopFreeCamera() end
end)

print([[
╔══════════════════════════════════════════╗
║        SHADOW OPS HUB v6.0              ║
║         Author: CoiledTom               ║
║       WindUI v2 | Universal             ║
╚══════════════════════════════════════════╝
]])
