-- SnakeGame 0016 | selecao de skins de cor com validacao no servidor
-- Instalar via Barra de Comandos do Roblox Studio, modo Edit, depois de 0001-0015.
-- Linhagem canonica: 0005_mobile_swipe, 0010_circular_mode_integration, 0011_HUD_Explorer.
-- Preserva os scripts, os HUDs editaveis e os patches historicos.
-- Fontes: https://create.roblox.com/docs/scripting/security/client-server-boundary
--         https://create.roblox.com/docs/reference/engine/datatypes/Color3
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "0016: execute no modo Edit, fora do Play/Run")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local StarterGui = game:GetService("StarterGui")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"), "0016: servidor SnakeGameServer ausente")
assert(client and client:IsA("LocalScript"), "0016: cliente SnakeGameClient ausente")
local marker = "-- SnakeGame 0016 applied"
local previousS, previousC = server.Source, client.Source
local existing = StarterGui:FindFirstChild("SnakeGameSkinSelect")
if previousS:find(marker,1,true) or previousC:find(marker,1,true) then
    assert(previousS:find(marker,1,true) and previousC:find(marker,1,true),
        "0016: instalacao parcial entre servidor e cliente")
    assert(existing and existing:IsA("ScreenGui")
        and existing:GetAttribute("SnakeGameUpdate")==16,
        "0016: GUI de skins ausente ou divergente")
    assert(previousS:find("skinPalettes[s.skin]",1,true)
        and previousC:find("SnakeGameSkinSelect",1,true),
        "0016: instalacao marcada mas scripts divergentes")
    print("[SnakeGame] 0016 ja instalado; preservando personalizacoes do Explorer")
    return
end
assert(not existing, "0016: SnakeGameSkinSelect ja existe; nao sobrescrever")
assert(previousS:find("-- SnakeGame 0010 applied",1,true)
    and previousS:find("-- SnakeGame 0009 applied",1,true),
    "0016: servidor requer patches 0009 e 0010")
assert(previousC:find("-- SnakeGame 0015 applied",1,true)
    and previousC:find("-- SnakeGame 0011 applied",1,true),
    "0016: cliente requer patches 0011 ate 0015")
local modeGui=StarterGui:FindFirstChild("SnakeGameModeSelect")
local hudGui=StarterGui:FindFirstChild("SnakeGameHUD")
assert(modeGui and modeGui:IsA("ScreenGui")
    and modeGui:GetAttribute("SnakeGameUpdate")==10,
    "0016: seletor de arenas 0010 ausente")
assert(hudGui and hudGui:IsA("ScreenGui")
    and hudGui:GetAttribute("SnakeGameUpdate")==11,
    "0016: HUD 0011 ausente")
local function once(src,before,after,label)
    local first=src:find(before,1,true)
    assert(first and not src:find(before,first+#before,true),
        "0016 precheck falhou: "..label)
    return src:sub(1,first-1)..after..src:sub(first+#before)
end

-- As cores e o estado canonico pertencem ao servidor. O cliente envia apenas um nome fixo.
local nextS=previousS
nextS=once(nextS,
    'local function key(v) return tostring(v.X)..":"..tostring(v.Y) end',
    [==[local skinPalettes={
    Classic={head=Color3.fromRGB(145,255,94),body=Color3.fromRGB(61,202,105)},
    Ember={head=Color3.fromRGB(255,201,88),body=Color3.fromRGB(255,92,66)},
    Frost={head=Color3.fromRGB(188,250,255),body=Color3.fromRGB(65,167,231)}
}
local skinCommands={SkinClassic="Classic",SkinEmber="Ember",SkinFrost="Frost"}
local function key(v) return tostring(v.X)..":"..tostring(v.Y) end]==],
    "paletas")
nextS=once(nextS,
    'score=s.score,alive=s.alive,won=s.won==true,body=s.body,food=s.food,step=STEP,mode=s.mode',
    'score=s.score,alive=s.alive,won=s.won==true,body=s.body,food=s.food,step=STEP,mode=s.mode,skin=s.skin',
    "replicacao do estado visual")
nextS=once(nextS,
    'for i,v in ipairs(s.body) do\n        local p=segments:FindFirstChild(tostring(i))',
    'local palette=skinPalettes[s.skin] or skinPalettes.Classic\n    for i,v in ipairs(s.body) do\n        local p=segments:FindFirstChild(tostring(i))',
    "lookup unico da paleta por renderizacao")
nextS=once(nextS,
    'p.Color=(i==1) and Color3.fromRGB(145,255,94) or Color3.fromRGB(61,202,105)',
    'p.Color=(i==1) and palette.head or palette.body',
    "pintura por skin")
nextS=once(nextS,
    'local mode = selectedMode or (old and old.mode) or "Classic"',
    [==[local mode = selectedMode or (old and old.mode) or "Classic"
    local skin = old and old.skin or "Classic"]==],
    "persistencia da skin em reinicios e troca de arena")
nextS=once(nextS,
    'score=0,alive=true,won=false,model=model,lastInput=0,slot=slot,origin=origin,mode=mode,lastModeSwitch=old and old.lastModeSwitch or -math.huge}',
    'score=0,alive=true,won=false,model=model,lastInput=0,slot=slot,origin=origin,mode=mode,lastModeSwitch=old and old.lastModeSwitch or -math.huge,skin=skin,lastSkinSwitch=old and old.lastSkinSwitch or -math.huge}',
    "estado e limite de troca")
nextS=once(nextS,
    [==[local isModeCommand = command=="ModeClassic" or command=="ModeCircular"
    if command~="Restart" and directions[command]==nil and not isModeCommand then return end
    if isModeCommand and not hasModeHandler then return end]==],
    [==[local isModeCommand = command=="ModeClassic" or command=="ModeCircular"
    local isSkinCommand = skinCommands[command]~=nil
    if command~="Restart" and directions[command]==nil and not isModeCommand and not isSkinCommand then return end
    if isModeCommand and not hasModeHandler then return end]==],
    "whitelist de comandos remotos")
nextS=once(nextS,
    [==[local now=os.clock()
    if command=="ModeClassic" or command=="ModeCircular" then]==],
    [==[local now=os.clock()
    local desiredSkin=skinCommands[command]
    if desiredSkin then
        if s.skin~=desiredSkin and now-(s.lastSkinSwitch or -math.huge)>=0.75 then
            s.skin=desiredSkin
            s.lastSkinSwitch=now
            paint(s)
            send(player,s)
        end
        return
    end
    if command=="ModeClassic" or command=="ModeCircular" then]==],
    "troca de skin com cooldown no servidor")
nextS=nextS.."\n"..marker.."\n"

local nextC=previousC..[==[

-- SnakeGame 0016 applied
-- A posicao, o tamanho e a aparencia dos botoes sao editaveis em StarterGui.
local skinGui=player:WaitForChild("PlayerGui"):WaitForChild("SnakeGameSkinSelect")
local skinPanel=skinGui:WaitForChild("Panel")
local skinButtons={}
for _,entry in ipairs({
    {"Classic","SkinClassic"},{"Ember","SkinEmber"},{"Frost","SkinFrost"}
}) do
    local skinName,command=entry[1],entry[2]
    local button=skinPanel:WaitForChild(skinName)
    skinButtons[skinName]=button
    button.Activated:Connect(function() turn:FireServer(command) end)
end
local function highlightSkin(skinName)
    for name,button in pairs(skinButtons) do
        local stroke=button:FindFirstChild("SelectedStroke")
        if stroke then stroke.Enabled=(name==skinName) end
    end
end
highlightSkin("Classic")
state.OnClientEvent:Connect(function(s)
    if typeof(s)=="table" and skinButtons[s.skin] then
        highlightSkin(s.skin)
    end
end)
]==]

local template=Instance.new("ScreenGui")
template.Name="SnakeGameSkinSelect"
template.ResetOnSpawn=false
template.IgnoreGuiInset=false
template.DisplayOrder=8
template.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
template:SetAttribute("SnakeGameUpdate",16)
local panel=Instance.new("Frame")
panel.Name="Panel"
panel.BackgroundTransparency=1
panel.Position=UDim2.fromScale(0.025,0.23)
panel.Size=UDim2.new(0.48,0,0,46)
panel.Parent=template
local panelLimit=Instance.new("UISizeConstraint")
panelLimit.MinSize=Vector2.new(210,44)
panelLimit.MaxSize=Vector2.new(348,52)
panelLimit.Parent=panel
local definitions={
    {"Classic","CLASSICA",0,Color3.fromRGB(43,104,62)},
    {"Ember","EMBER",0.345,Color3.fromRGB(133,56,42)},
    {"Frost","FROST",0.690,Color3.fromRGB(35,87,124)}
}
for _,item in ipairs(definitions) do
    local button=Instance.new("TextButton")
    button.Name=item[1]
    button.Text=item[2]
    button.Font=Enum.Font.GothamBold
    button.TextScaled=true
    button.BorderSizePixel=0
    button.TextColor3=Color3.fromRGB(235,255,250)
    button.BackgroundColor3=item[4]
    button.Position=UDim2.fromScale(item[3],0)
    button.Size=UDim2.new(0.31,0,1,0)
    button.Parent=panel
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,10)
    corner.Parent=button
    local textLimit=Instance.new("UITextSizeConstraint")
    textLimit.MinTextSize=10
    textLimit.MaxTextSize=16
    textLimit.Parent=button
    local stroke=Instance.new("UIStroke")
    stroke.Name="SelectedStroke"
    stroke.Color=Color3.fromRGB(240,255,214)
    stroke.Thickness=2.4
    stroke.Transparency=0
    stroke.Enabled=(item[1]=="Classic")
    stroke.Parent=button
end
local enabledS,enabledC=server.Enabled,client.Enabled
local ok,err=pcall(function()
    server.Enabled=false
    client.Enabled=false
    server.Source=nextS
    client.Source=nextC
    template.Parent=StarterGui
    assert(server.Source==nextS and client.Source==nextC,
        "0016: postcheck fontes divergentes")
    assert(server.Source:find(marker,1,true)
        and client.Source:find(marker,1,true),
        "0016: postcheck marcador")
    assert(server.Source:find("skinCommands[command]",1,true)
        and server.Source:find("lastSkinSwitch",1,true),
        "0016: postcheck validacao remota")
    assert(StarterGui:FindFirstChild("SnakeGameSkinSelect")==template,
        "0016: postcheck GUI")
    for _,item in ipairs(definitions) do
        assert(panel:FindFirstChild(item[1]),"0016: botao ausente "..item[1])
    end
    server.Enabled=enabledS
    client.Enabled=enabledC
end)
if not ok then
    server.Enabled=false
    client.Enabled=false
    local restoredS,restoreErrS=pcall(function() server.Source=previousS end)
    local restoredC,restoreErrC=pcall(function() client.Source=previousC end)
    template:Destroy()
    server.Enabled=enabledS
    client.Enabled=enabledC
    assert(restoredS and restoredC,
        "0016: rollback de fontes falhou: "..tostring(restoreErrS or restoreErrC))
    error("[SnakeGame] 0016 rollback executado: "..tostring(err))
end
print("[SnakeGame] 0016 aplicado: Classic, Ember, Frost. Teste no Studio.")
