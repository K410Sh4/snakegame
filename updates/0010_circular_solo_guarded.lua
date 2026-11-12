-- SnakeGame 0010 | modo circular Solo com colisao validada no servidor
-- Execute na Barra de Comandos do Roblox Studio em modo Edit, apos 0001-0009.
-- Integracao sobre linha 0005_swipe, 0006_guard, 0007_restart, 0008_compat e 0009_win.
-- Nao altera patches historicos. Idempotente; rollback de ambos os scripts.
local RunService=game:GetService("RunService")
assert(not RunService:IsRunning(),"0010: execute fora de Play/Run")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local server=SSS:FindFirstChild("SnakeGameServer")
local client=SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"),"0010 requer SnakeGameServer")
assert(client and client:IsA("LocalScript"),"0010 requer SnakeGameClient")
local marker="-- SnakeGame 0010 applied"
local priorServer,priorClient=server.Source,client.Source
if priorServer:find(marker,1,true) and priorClient:find(marker,1,true) then
    print("[SnakeGame] 0010 ja aplicado")
    return
end
assert(not priorServer:find(marker,1,true) and not priorClient:find(marker,1,true),
    "0010 parcialmente instalado; verificar antes de reaplicar")
assert(priorServer:find("-- SnakeGame 0003 applied",1,true),"0010: falta 0003 servidor")
assert(priorClient:find("-- SnakeGame 0009 applied",1,true),"0010: requer cliente 0009")
assert(priorServer:find("-- SnakeGame 0009 applied",1,true),"0010: requer servidor 0009")
assert(priorServer:find("-- SnakeGame 0008 applied",1,true),"0010: requer whitelist do 0008")
assert(not priorServer:find("local function validCell(",1,true),"0010: geometria circular existente; nao duplicar")
local function replaceOnce(source,before,after,label)
    local start=source:find(before,1,true)
    assert(start,"0010 precheck falhou: "..label)
    assert(not source:find(before,start+#before,true),"0010 trecho duplicado: "..label)
    return source:sub(1,start-1)..after..source:sub(start+#before)
end
local nextServer=priorServer
nextServer=replaceOnce(nextServer,[[local function key(v) return tostring(v.X)..":"..tostring(v.Y) end]],[[local function key(v) return tostring(v.X)..":"..tostring(v.Y) end
local CIRCLE_RADIUS_CELLS = 8
local function validCell(mode, v)
    if v.X < 0 or v.X >= SIZE or v.Y < 0 or v.Y >= SIZE then return false end
    if mode ~= "Circular" then return true end
    local dx = v.X - (SIZE - 1) / 2
    local dy = v.Y - (SIZE - 1) / 2
    return dx * dx + dy * dy <= CIRCLE_RADIUS_CELLS * CIRCLE_RADIUS_CELLS
end]],"validCell")
nextServer=replaceOnce(nextServer,[[score=s.score,alive=s.alive,won=s.won==true,body=s.body,food=s.food,step=STEP]],[[score=s.score,alive=s.alive,body=s.body,food=s.food,step=STEP,mode=s.mode]],"send mode")
nextServer=replaceOnce(nextServer,[[if not occupied[key(v)] then table.insert(free,v) end]],[[if validCell(s.mode,v) and not occupied[key(v)] then table.insert(free,v) end]],"spawnFood circular filter")
nextServer=replaceOnce(nextServer,[[local function reset(player)]],[[local function reset(player,selectedMode)]],"reset signature")
nextServer=replaceOnce(nextServer,[[local old=sessions[player]
    if old and old.model then]],[[local old=sessions[player]
    local mode=selectedMode or (old and old.mode) or "Classic"
    if old and old.model then]],"keep selected mode")
nextServer=replaceOnce(nextServer,[[alive=true,won=false,model=model,lastInput=0,slot=slot,origin=origin}]],[[alive=true,model=model,lastInput=0,slot=slot,origin=origin,mode=mode,lastModeSwitch=old and old.lastModeSwitch or -math.huge}]],"session mode")
nextServer=replaceOnce(nextServer,[[s.food=spawnFood(s); sessions[player]=s]],[[if mode == "Circular" then
        local ring=Instance.new("Folder")
        ring.Name="CircularBoundary"
        ring.Parent=model
        local radius=(CIRCLE_RADIUS_CELLS+0.5)*CELL
        local steps=48
        for i=1,steps do
            local a=(i-1)*math.pi*2/steps
            local b=i*math.pi*2/steps
            local p0=Vector3.new(origin+math.cos(a)*radius,2.1,math.sin(a)*radius)
            local p1=Vector3.new(origin+math.cos(b)*radius,2.1,math.sin(b)*radius)
            local edge=Instance.new("Part")
            edge.Name="Rim"
            edge.Anchored=true
            edge.CanCollide=false
            edge.CanTouch=false
            edge.CanQuery=false
            edge.CastShadow=false
            edge.Material=Enum.Material.Neon
            edge.Color=Color3.fromRGB(28,195,161)
            edge.Transparency=0.12
            edge.Size=Vector3.new((p1-p0).Magnitude,2.2,0.45)
            edge.CFrame=CFrame.lookAt((p0+p1)/2,p1)*CFrame.Angles(0,math.pi/2,0)
            edge.Parent=ring
        end
    end
    s.food=spawnFood(s); sessions[player]=s]],"circular boundary")
nextServer=replaceOnce(nextServer,[[head.X<0 or head.X>=SIZE or head.Y<0 or head.Y>=SIZE or occupied[key(head)]]],[[not validCell(s.mode,head) or occupied[key(head)]]],"circular collision")
nextServer=replaceOnce(nextServer,[[local now=os.clock()
    if command=="Restart" then]],[[local now=os.clock()
    if command=="ModeClassic" or command=="ModeCircular" then
        local chosen=(command=="ModeCircular") and "Circular" or "Classic"
        if s.mode~=chosen and now-(s.lastModeSwitch or -math.huge)>=1 then
            s.lastModeSwitch=now
            reset(player,chosen)
        end
        return
    end
    if command=="Restart" then]],"validated mode commands")
-- O reinicio imediato ja foi instalado no patch 0007.
nextServer=replaceOnce(nextServer,[[local hasModeHandler = false]],[[local hasModeHandler = true]],"habilita whitelist circular 0008")
nextServer=nextServer..[[
-- SnakeGame 0010 applied
]]
local nextClient=priorClient..[[
-- SnakeGame 0010 applied
-- Controles editaveis via Explorer, sem sobrescrever propriedades em runtime.
local function arenaModeButton(name, text, x, command)
    local button=Instance.new("TextButton")
    button.Name=name
    button.Text=text
    button.Font=Enum.Font.GothamBold
    button.TextScaled=true
    button.TextColor3=Color3.fromRGB(210,255,232)
    button.BackgroundColor3=Color3.fromRGB(26,73,70)
    button.Position=UDim2.fromScale(x,0.79)
    button.Size=UDim2.fromScale(0.21,0.07)
    button.Parent=gui
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,10)
    corner.Parent=button
    local textSize=Instance.new("UITextSizeConstraint")
    textSize.MinTextSize=10
    textSize.MaxTextSize=17
    textSize.Parent=button
    local constraints=Instance.new("UISizeConstraint")
    constraints.MinSize=Vector2.new(80,42)
    constraints.MaxSize=Vector2.new(154,56)
    constraints.Parent=button
    button.Activated:Connect(function()
        turn:FireServer(command)
    end)
    return button
end

local classicButton=arenaModeButton("ArenaClassic","CLÁSSICA",0.025,"ModeClassic")
local circleButton=arenaModeButton("ArenaCircular","CIRCULAR",0.31,"ModeCircular")
local function applyModeHighlight(mode)
    local classic=mode~="Circular"
    classicButton.BackgroundColor3=classic and Color3.fromRGB(28,195,161) or Color3.fromRGB(26,73,70)
    circleButton.BackgroundColor3=(not classic) and Color3.fromRGB(28,195,161) or Color3.fromRGB(26,73,70)
    classicButton.TextColor3=classic and Color3.fromRGB(12,31,31) or Color3.fromRGB(210,255,232)
    circleButton.TextColor3=(not classic) and Color3.fromRGB(12,31,31) or Color3.fromRGB(210,255,232)
end
applyModeHighlight("Classic")
state.OnClientEvent:Connect(function(s)
    if typeof(s)=="table" and (s.mode=="Classic" or s.mode=="Circular") then
        applyModeHighlight(s.mode)
    end
end)
]]
local serverEnabled,clientEnabled=server.Enabled,client.Enabled
local ok,err=pcall(function()
    server.Enabled=false
    client.Enabled=false
    server.Source=nextServer
    client.Source=nextClient
    assert(server.Source:find(marker,1,true),"0010 postcheck servidor")
    assert(client.Source:find(marker,1,true),"0010 postcheck cliente")
    assert(server.Source:find("validCell(s.mode,head)",1,true),"0010 postcheck colisao")
    assert(client.Source:find("ModeCircular",1,true),"0010 postcheck UI")
    server.Enabled=serverEnabled
    client.Enabled=clientEnabled
end)
if not ok then
    server.Enabled=false
    client.Enabled=false
    server.Source=priorServer
    client.Source=priorClient
    server.Enabled=serverEnabled
    client.Enabled=clientEnabled
    error("[SnakeGame] 0010 rollback: "..tostring(err))
end
print("[SnakeGame] 0010 instalado: modo circular e classico. Execute Play Test PC/mobile.")
