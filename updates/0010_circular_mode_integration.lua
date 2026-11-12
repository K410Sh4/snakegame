-- SnakeGame 0010 | modo Solo circular integrado a linha 0005-0009
-- Barra de Comandos Roblox Studio / modo Edit. Execute apos 0009.
-- Preserva os patches historicos 0005 concorrentes; este patch usa a linha mobile-swipe.
-- O servidor valida limites, alimentos e troca de modo; botoes editaveis no Explorer.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "0010: execute fora do Play/Run")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local StarterGui = game:GetService("StarterGui")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"), "0010: SnakeGameServer ausente")
assert(client and client:IsA("LocalScript"), "0010: SnakeGameClient ausente")
local beforeS, beforeC = server.Source, client.Source
local marker = "-- SnakeGame 0010 applied"
local installed = StarterGui:FindFirstChild("SnakeGameModeSelect")
if beforeS:find(marker,1,true) or beforeC:find(marker,1,true) then
    assert(beforeS:find(marker,1,true) and beforeC:find(marker,1,true),
        "0010: instalacao parcial dos scripts")
    assert(installed and installed:IsA("ScreenGui") and
        installed:GetAttribute("SnakeGameUpdate")==10, "0010: GUI ausente ou divergente")
    print("[SnakeGame] 0010 ja aplicado")
    return
end
assert(not installed, "0010: SnakeGameModeSelect preexistente; nao sobrescrever")
assert(beforeS:find("-- SnakeGame 0009 applied",1,true), "0010: servidor requer 0009")
assert(beforeS:find("-- SnakeGame 0008 applied",1,true), "0010: servidor requer 0008")
assert(beforeC:find("-- SnakeGame 0009 applied",1,true), "0010: cliente requer 0009")
assert(beforeC:find("-- SnakeGame 0005 applied",1,true), "0010: cliente requer controles mobile")

local function once(src, from, to, reason)
    local pos = src:find(from,1,true)
    assert(pos and not src:find(from,pos+#from,true), "0010 precheck: "..reason)
    return src:sub(1,pos-1)..to..src:sub(pos+#from)
end

local revisedS = beforeS
revisedS = once(revisedS,
    'local function key(v) return tostring(v.X)..":"..tostring(v.Y) end',
    [==[local function key(v) return tostring(v.X)..":"..tostring(v.Y) end
local CIRCLE_RADIUS_CELLS = 8
local function validCell(mode, v)
    if v.X < 0 or v.X >= SIZE or v.Y < 0 or v.Y >= SIZE then return false end
    if mode ~= "Circular" then return true end
    local dx, dy = v.X-(SIZE-1)/2, v.Y-(SIZE-1)/2
    return dx*dx+dy*dy <= CIRCLE_RADIUS_CELLS*CIRCLE_RADIUS_CELLS
end]==], "funcao de limite")
revisedS = once(revisedS,
    'score=s.score,alive=s.alive,won=s.won==true,body=s.body,food=s.food,step=STEP',
    'score=s.score,alive=s.alive,won=s.won==true,body=s.body,food=s.food,step=STEP,mode=s.mode',
    "estado de modo")
revisedS = once(revisedS,
    'if not occupied[key(v)] then table.insert(free,v) end',
    'if validCell(s.mode,v) and not occupied[key(v)] then table.insert(free,v) end',
    "comida restrita a arena")
revisedS = once(revisedS,
    'local function reset(player)',
    'local function reset(player, selectedMode)',
    "assinatura do reset")
revisedS = once(revisedS,
    [==[local old=sessions[player]
    if old and old.model then]==],
    [==[local old=sessions[player]
    local mode = selectedMode or (old and old.mode) or "Classic"
    if old and old.model then]==],
    "modo persistente no reset")
revisedS = once(revisedS,
    'score=0,alive=true,won=false,model=model,lastInput=0,slot=slot,origin=origin}',
    'score=0,alive=true,won=false,model=model,lastInput=0,slot=slot,origin=origin,mode=mode,lastModeSwitch=old and old.lastModeSwitch or -math.huge}',
    "estado inicial")
revisedS = once(revisedS,
    's.food=spawnFood(s); sessions[player]=s',
    [==[if mode == "Circular" then
        local boundary = Instance.new("Folder")
        boundary.Name = "CircularBoundary"
        boundary.Parent = model
        local radius = (CIRCLE_RADIUS_CELLS + 0.5) * CELL
        local sides = 40
        for i=1,sides do
            local a,b = (i-1)*2*math.pi/sides, i*2*math.pi/sides
            local p0 = Vector3.new(origin+math.cos(a)*radius,2.1,math.sin(a)*radius)
            local p1 = Vector3.new(origin+math.cos(b)*radius,2.1,math.sin(b)*radius)
            local rim = Instance.new("Part")
            rim.Name = "Rim"
            rim.Anchored = true
            rim.CanCollide = false
            rim.CanQuery = false
            rim.CanTouch = false
            rim.CastShadow = false
            rim.Material = Enum.Material.Neon
            rim.Color = Color3.fromRGB(28,195,161)
            rim.Size = Vector3.new((p1-p0).Magnitude,2.2,0.45)
            rim.CFrame = CFrame.lookAt((p0+p1)/2,p1)*CFrame.Angles(0,math.pi/2,0)
            rim.Parent = boundary
        end
    end
    s.food=spawnFood(s); sessions[player]=s]==],
    "borda circular")
revisedS = once(revisedS,
    'head.X<0 or head.X>=SIZE or head.Y<0 or head.Y>=SIZE or occupied[key(head)]',
    'not validCell(s.mode,head) or occupied[key(head)]',
    "colisao circular")
revisedS = once(revisedS,
    'local hasModeHandler = false',
    'local hasModeHandler = true',
    "compatibilidade do filtro remoto 0008")
revisedS = once(revisedS,
    [==[local now=os.clock()
    if command=="Restart" then]==],
    [==[local now=os.clock()
    if command=="ModeClassic" or command=="ModeCircular" then
        local selected = command=="ModeCircular" and "Circular" or "Classic"
        if s.mode~=selected and now-(s.lastModeSwitch or -math.huge)>=1 then
            s.lastModeSwitch=now
            reset(player,selected)
        end
        return
    end
    if command=="Restart" then]==],
    "handler de modos")
revisedS = revisedS.."\n"..marker.."\n"

local revisedC = beforeC..[==[

-- SnakeGame 0010 applied
-- Layout dos botoes: StarterGui > SnakeGameModeSelect (editavel no Explorer).
local modeGui = player:WaitForChild("PlayerGui"):WaitForChild("SnakeGameModeSelect")
local modePanel = modeGui:WaitForChild("Panel")
local classicButton = modePanel:WaitForChild("Classic")
local circularButton = modePanel:WaitForChild("Circular")
classicButton.Activated:Connect(function() turn:FireServer("ModeClassic") end)
circularButton.Activated:Connect(function() turn:FireServer("ModeCircular") end)
local function refreshMode(mode)
    local circular = mode=="Circular"
    classicButton.BackgroundColor3 = circular and Color3.fromRGB(26,73,70) or Color3.fromRGB(28,195,161)
    classicButton.TextColor3 = circular and Color3.fromRGB(210,255,232) or Color3.fromRGB(12,31,31)
    circularButton.BackgroundColor3 = circular and Color3.fromRGB(28,195,161) or Color3.fromRGB(26,73,70)
    circularButton.TextColor3 = circular and Color3.fromRGB(12,31,31) or Color3.fromRGB(210,255,232)
end
refreshMode("Classic")
state.OnClientEvent:Connect(function(s)
    if typeof(s)=="table" and (s.mode=="Classic" or s.mode=="Circular") then
        refreshMode(s.mode)
    end
end)
]==]

local template = Instance.new("ScreenGui")
template.Name = "SnakeGameModeSelect"
template.ResetOnSpawn = false
template.IgnoreGuiInset = false
template.DisplayOrder = 7
template:SetAttribute("SnakeGameUpdate",10)
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.BackgroundTransparency = 1
panel.Position = UDim2.fromScale(0.025,0.14)
panel.Size = UDim2.new(0.46,0,0,48)
panel.Parent = template
local limit = Instance.new("UISizeConstraint")
limit.MinSize = Vector2.new(190,46)
limit.MaxSize = Vector2.new(330,54)
limit.Parent = panel
local function button(name,label,x)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = label
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.TextColor3 = Color3.fromRGB(210,255,232)
    b.BackgroundColor3 = Color3.fromRGB(26,73,70)
    b.AnchorPoint = Vector2.new(0,0)
    b.Position = UDim2.fromScale(x,0)
    b.Size = UDim2.new(0.48,0,1,0)
    b.Parent = panel
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0,10)
    round.Parent = b
    local textLimit = Instance.new("UITextSizeConstraint")
    textLimit.MinTextSize = 10
    textLimit.MaxTextSize = 17
    textLimit.Parent = b
end
button("Classic","CLASSICA",0)
button("Circular","CIRCULAR",0.52)

local serverOn, clientOn = server.Enabled, client.Enabled
local ok, err = pcall(function()
    server.Enabled = false
    client.Enabled = false
    server.Source = revisedS
    client.Source = revisedC
    template.Parent = StarterGui
    assert(server.Source:find(marker,1,true) and client.Source:find(marker,1,true),
        "0010 postcheck: marcadores de origem")
    assert(server.Source:find("local hasModeHandler = true",1,true),
        "0010 postcheck: filtro de modos")
    assert(server.Source:find("validCell(s.mode,head)",1,true),
        "0010 postcheck: colisao")
    assert(StarterGui:FindFirstChild("SnakeGameModeSelect")==template,
        "0010 postcheck: template")
    assert(panel:FindFirstChild("Classic") and panel:FindFirstChild("Circular"),
        "0010 postcheck: botoes")
    server.Enabled = serverOn
    client.Enabled = clientOn
end)
if not ok then
    server.Enabled = false
    client.Enabled = false
    pcall(function() server.Source = beforeS end)
    pcall(function() client.Source = beforeC end)
    template:Destroy()
    server.Enabled = serverOn
    client.Enabled = clientOn
    error("[SnakeGame] 0010 rollback: "..tostring(err))
end
print("[SnakeGame] 0010 instalado. Validar troca de modo e colisao no Studio.")
