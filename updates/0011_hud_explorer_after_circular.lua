-- SnakeGame 0011 | HUD Explorer apos 0010 circular: preserva gestos, modos e vitoria
-- Execute no Roblox Studio pela Barra de Comandos, em modo Edit, apos 0010_circular_mode_integration.lua.
-- NAO aplique sobre as outras variantes concorrentes 0005 (circular / explorer).
-- Compatibilidade explicita com a linhagem 0005_mobile_swipe_controls.
-- Nao altera os patches historicos.
local RunService=game:GetService("RunService")
assert(not RunService:IsRunning(),"0011: execute fora do Play/Run")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local StarterGui=game:GetService("StarterGui")
local server=SSS:FindFirstChild("SnakeGameServer")
local client=SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"),"0011: servidor ausente")
assert(client and client:IsA("LocalScript"),"0011: cliente ausente")
local marker="-- SnakeGame 0011 applied"
local original=client.Source
local existing=StarterGui:FindFirstChild("SnakeGameHUD")
if original:find(marker,1,true) then
    assert(existing and existing:IsA("ScreenGui") and existing:GetAttribute("SnakeGameUpdate")==11,
        "0011: marcador presente, mas HUD Explorer ausente")
    print("[SnakeGame] 0011 ja instalado; layout preservado")
    return
end
assert(not existing,"0011: StarterGui.SnakeGameHUD ja existe; nao sobrescrever")
assert(server.Source:find("-- SnakeGame 0009 applied",1,true),
    "0011: aplique os patches da linhagem 0005-swipe ate 0009")
assert(original:find("-- SnakeGame 0009 applied",1,true),"0011: cliente 0009 ausente")
assert(original:find("SWIPE_THRESHOLD = 40",1,true)
    and original:find("UIS.TouchEnded:Connect",1,true),
    "0011: linhagem inesperada; nao confundir as tres variantes 0005")
-- Reconciliacao: sequencia canonica usa somente a variante 0010 circular.
assert(server.Source:find("-- SnakeGame 0010 applied",1,true)
    and original:find("-- SnakeGame 0010 applied",1,true),
    "0011: instale a variante 0010 circular primeiro")
local modeSelect=StarterGui:FindFirstChild("SnakeGameModeSelect")
assert(modeSelect and modeSelect:IsA("ScreenGui")
    and modeSelect:GetAttribute("SnakeGameUpdate")==10,
    "0011: seletor circular 0010 ausente")
assert(original:find('local modeGui = player:WaitForChild("PlayerGui")',1,true),
    "0011: bindings circulares 0010 ausentes")
local beforeGui='local gui=Instance.new("ScreenGui")\n'
local afterGui='local keys={\n'
local startAt=original:find(beforeGui,1,true)
local finishAt=original:find(afterGui,1,true)
assert(startAt and finishAt and startAt<finishAt,"0011: construtor de HUD original nao identificado")
assert(not original:find(beforeGui,startAt+#beforeGui,true),"0011: GUI duplicada")
assert(not original:find(afterGui,finishAt+#afterGui,true),"0011: teclas duplicadas")
local bindings=[==[
-- UI editavel no Explorer. O cliente atualiza apenas texto/estado e gestos.
local gui=player:WaitForChild("PlayerGui"):WaitForChild("SnakeGameHUD")
local score=gui:WaitForChild("Score")
local hint=gui:WaitForChild("Hint")
local retry=gui:WaitForChild("Retry")
local controls=gui:WaitForChild("Controls")
controls.Visible=UIS.TouchEnabled
retry.Activated:Connect(function() turn:FireServer("Restart") end)
for _,direction in ipairs({"Up","Left","Down","Right"}) do
    controls:WaitForChild(direction).Activated:Connect(function()
        turn:FireServer(direction)
    end)
end
]==]
local revised=original:sub(1,startAt-1)..bindings..original:sub(finishAt)
local oldSwipe=[==[for _,button in ipairs(buttons) do
    button.Visible = UIS.TouchEnabled
end]==]
local swipeAt=revised:find(oldSwipe,1,true)
assert(swipeAt and not revised:find(oldSwipe,swipeAt+#oldSwipe,true),
    "0011: loop de botoes da variante 0005-swipe ausente/duplicado")
revised=revised:sub(1,swipeAt-1)..revised:sub(swipeAt+#oldSwipe)
revised=revised.."\n"..marker.."\n"
assert(not revised:find("local buttons=",1,true),"0011: construtor anterior ainda presente")
assert(revised:find("SWIPE_THRESHOLD = 40",1,true),"0011: gesto removido acidentalmente")
assert(revised:find("s.won==true",1,true),"0011: status de vitoria removido")
assert(revised:find("local modeGui = player:WaitForChild",1,true),"0011: seletor de modo removido")

local template=Instance.new("ScreenGui")
template.Name="SnakeGameHUD"
template.ResetOnSpawn=false
template.IgnoreGuiInset=false
template.DisplayOrder=7
template.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
template:SetAttribute("SnakeGameUpdate",11)
local function corner(parent,radius)
    local x=Instance.new("UICorner")
    x.CornerRadius=UDim.new(0,radius)
    x.Parent=parent
end
local function textSize(parent,min,max)
    local x=Instance.new("UITextSizeConstraint")
    x.MinTextSize=min; x.MaxTextSize=max; x.Parent=parent
end
local function outline(parent)
    local x=Instance.new("UIStroke")
    x.Color=Color3.fromRGB(28,195,161)
    x.Transparency=0.28
    x.Thickness=1.4
    x.Parent=parent
end
local function makeText(class,name,caption,parent)
    local x=Instance.new(class)
    x.Name=name
    x.Text=caption
    x.Font=Enum.Font.GothamBold
    x.TextScaled=true
    x.TextColor3=Color3.fromRGB(235,255,250)
    x.BorderSizePixel=0
    x.Parent=parent
    return x
end
local score=makeText("TextLabel","Score","PONTOS  0",template)
score.AnchorPoint=Vector2.new(.5,0)
score.Position=UDim2.new(.5,0,0,14)
score.Size=UDim2.new(.46,0,0,50)
score.BackgroundColor3=Color3.fromRGB(15,44,46)
corner(score,12);outline(score);textSize(score,12,28)
local scoreLimit=Instance.new("UISizeConstraint")
scoreLimit.MinSize=Vector2.new(140,44)
scoreLimit.MaxSize=Vector2.new(345,54)
scoreLimit.Parent=score

local hint=makeText("TextLabel","Hint","WASD / SETAS",template)
hint.BackgroundTransparency=1
hint.AnchorPoint=Vector2.new(.5,0)
hint.Position=UDim2.new(.5,0,0,70)
hint.Size=UDim2.new(.8,0,0,27)
textSize(hint,10,17)

local retry=makeText("TextButton","Retry","RECOMEÇAR",template)
retry.AnchorPoint=Vector2.new(.5,.5)
retry.Position=UDim2.fromScale(.5,.5)
retry.Size=UDim2.new(.42,0,0,54)
retry.Visible=false
retry.TextColor3=Color3.fromRGB(9,32,31)
retry.BackgroundColor3=Color3.fromRGB(28,195,161)
corner(retry,13);textSize(retry,13,24)
local retryLimit=Instance.new("UISizeConstraint")
retryLimit.MinSize=Vector2.new(150,48)
retryLimit.MaxSize=Vector2.new(295,60)
retryLimit.Parent=retry

local controls=Instance.new("Frame")
controls.Name="Controls"
controls.AnchorPoint=Vector2.new(1,1)
controls.Position=UDim2.new(1,-14,1,-135)
controls.Size=UDim2.fromOffset(168,148)
controls.BackgroundTransparency=1
controls.Parent=template
local layout={
    {"Up","↑",.5,.18},
    {"Left","←",.18,.62},
    {"Down","↓",.5,.62},
    {"Right","→",.82,.62},
}
for _,item in ipairs(layout) do
    local button=makeText("TextButton",item[1],item[2],controls)
    button.AnchorPoint=Vector2.new(.5,.5)
    button.Position=UDim2.fromScale(item[3],item[4])
    button.Size=UDim2.fromOffset(50,50)
    button.TextColor3=Color3.fromRGB(226,255,242)
    button.BackgroundColor3=Color3.fromRGB(23,82,79)
    corner(button,11);outline(button);textSize(button,19,30)
end
assert(#controls:GetChildren()==4,"0011: faltam botoes direcionais")
local wasEnabled=client.Enabled
local ok,err=pcall(function()
    client.Enabled=false
    client.Source=revised
    template.Parent=StarterGui
    assert(template.Parent==StarterGui,"0011: template nao instalado")
    assert(client.Source:find(marker,1,true),"0011: fonte nao persistida")
    assert(client.Source:find('gui:WaitForChild("Score")',1,true),"0011: binding ausente")
    assert(template:FindFirstChild("Retry") and template:FindFirstChild("Controls"),
        "0011: HUD incompleto")
    client.Enabled=wasEnabled
end)
if not ok then
    client.Enabled=false
    pcall(function() client.Source=original end)
    template:Destroy()
    client.Enabled=wasEnabled
    error("SnakeGame 0011 rollback: "..tostring(err))
end
print("[SnakeGame] 0011 instalado: HUD editavel no Explorer, gestos e estado de vitoria preservados.")
