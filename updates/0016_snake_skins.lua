-- SnakeGame 0016 | tres skins de cobra, sob autoridade do servidor
-- Barra de Comandos em modo Edit; requer sequencia 0001-0015 da linhagem circular.
local RS=game:GetService("RunService")
assert(not RS:IsRunning(),"0016: execute fora de Play/Run")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SG=game:GetService("StarterGui")
local ss=SSS:FindFirstChild("SnakeGameServer")
local cs=SPS:FindFirstChild("SnakeGameClient")
assert(ss and ss:IsA("Script") and cs and cs:IsA("LocalScript"),"0016: scripts ausentes")
local originalS,originalC=ss.Source,cs.Source
local tag="-- SnakeGame 0016 applied"
local guiExists=SG:FindFirstChild("SnakeGameSkinSelect")
if originalS:find(tag,1,true) or originalC:find(tag,1,true) then
 assert(originalS:find(tag,1,true) and originalC:find(tag,1,true),"0016: scripts parcialmente instalados")
 assert(guiExists and guiExists:GetAttribute("SnakeGameUpdate")==16,"0016: GUI faltando")
 print("[SnakeGame] 0016 ja aplicado");return
end
assert(not guiExists,"0016: GUI preexistente; nao sobrescrever")
assert(originalS:find("-- SnakeGame 0010 applied",1,true),"0016: servidor circular requerido")
assert(originalC:find("-- SnakeGame 0015 applied",1,true),"0016: aplique 0015 primeiro")
assert(originalC:find("-- SnakeGame 0011 applied",1,true),"0016: HUD Explorer requerido")
local function once(s,a,b,why)
 local i=s:find(a,1,true)
 assert(i and not s:find(a,i+#a,true),"0016 precheck: "..why)
 return s:sub(1,i-1)..b..s:sub(i+#a)
end
local s=originalS
s=once(s,"local function paint(s)\n",[==[
local SKINS={
 Classic={Color3.fromRGB(145,255,94),Color3.fromRGB(61,202,105)},
 Ember={Color3.fromRGB(255,209,89),Color3.fromRGB(255,103,56)},
 Frost={Color3.fromRGB(224,249,255),Color3.fromRGB(73,179,241)},
}
local function paint(s)
]==],"paletas")
s=once(s,"for i,v in ipairs(s.body) do\n",[==[local palette=SKINS[s.skin] or SKINS.Classic
    for i,v in ipairs(s.body) do
]==],"cores por sessao")
s=once(s,"p.Color=(i==1) and Color3.fromRGB(145,255,94) or Color3.fromRGB(61,202,105)",
 "p.Color=(i==1) and palette[1] or palette[2]","cores")
s=once(s,"score=s.score,alive=s.alive,won=s.won==true,body=s.body,food=s.food,step=STEP,mode=s.mode",
 "score=s.score,alive=s.alive,won=s.won==true,body=s.body,food=s.food,step=STEP,mode=s.mode,skin=s.skin","estado")
s=once(s,"lastModeSwitch=old and old.lastModeSwitch or -math.huge}",
 'lastModeSwitch=old and old.lastModeSwitch or -math.huge,skin=old and old.skin or "Classic",lastSkinSwitch=old and old.lastSkinSwitch or -math.huge}',"reset")
s=once(s,'local isModeCommand = command=="ModeClassic" or command=="ModeCircular"',
 [==[local isModeCommand = command=="ModeClassic" or command=="ModeCircular"
    local isSkinCommand = command=="SkinClassic" or command=="SkinEmber" or command=="SkinFrost"]==],"identificador remoto")
s=once(s,'if command~="Restart" and directions[command]==nil and not isModeCommand then return end',
 'if command~="Restart" and directions[command]==nil and not isModeCommand and not isSkinCommand then return end',"whitelist")
s=once(s,[==[local now=os.clock()
    if command=="ModeClassic" or command=="ModeCircular" then]==],
 [==[local now=os.clock()
    if isSkinCommand then
        local chosen=(command=="SkinClassic") and "Classic"
            or ((command=="SkinEmber") and "Ember" or "Frost")
        if s.skin~=chosen and now-(s.lastSkinSwitch or -math.huge)>=0.25 then
            s.skin=chosen
            s.lastSkinSwitch=now
            paint(s)
            send(player,s)
        end
        return
    end
    if command=="ModeClassic" or command=="ModeCircular" then]==],"aplicacao autoritativa")
s=s.."\n"..tag.."\n"
local c=originalC..[==[

-- SnakeGame 0016 applied
local skinGui=player:WaitForChild("PlayerGui"):WaitForChild("SnakeGameSkinSelect")
local skinPanel=skinGui:WaitForChild("Panel")
local skinButtons={
 Classic=skinPanel:WaitForChild("Classic"),
 Ember=skinPanel:WaitForChild("Ember"),
 Frost=skinPanel:WaitForChild("Frost"),
}
for name,button in pairs(skinButtons) do
 local cmd="Skin"..name
 button.Activated:Connect(function() turn:FireServer(cmd) end)
end
local function refreshSkin(skin)
 if not skinButtons[skin] then return end
 for name,b in pairs(skinButtons) do
  local selected=name==skin
  b.BackgroundColor3=selected and Color3.fromRGB(28,195,161) or Color3.fromRGB(26,73,70)
  b.TextColor3=selected and Color3.fromRGB(12,31,31) or Color3.fromRGB(210,255,232)
 end
end
refreshSkin("Classic")
state.OnClientEvent:Connect(function(payload)
 if typeof(payload)=="table" then refreshSkin(payload.skin) end
end)
]==]
local gui=Instance.new("ScreenGui")
gui.Name="SnakeGameSkinSelect"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.DisplayOrder=8
gui:SetAttribute("SnakeGameUpdate",16)
local panel=Instance.new("Frame")
panel.Name="Panel"
panel.BackgroundTransparency=1
panel.Position=UDim2.fromScale(.025,.245)
panel.Size=UDim2.new(.70,0,0,46)
panel.Parent=gui
local size=Instance.new("UISizeConstraint")
size.MinSize=Vector2.new(210,44);size.MaxSize=Vector2.new(370,52);size.Parent=panel
for _,info in ipairs({{"Classic","CLASSICA",0},{"Ember","BRASA",.34},{"Frost","GELO",.68}}) do
 local b=Instance.new("TextButton")
 b.Name=info[1];b.Text=info[2];b.Font=Enum.Font.GothamBold;b.TextScaled=true
 b.TextColor3=Color3.fromRGB(210,255,232);b.BackgroundColor3=Color3.fromRGB(26,73,70)
 b.Position=UDim2.fromScale(info[3],0);b.Size=UDim2.new(.32,0,1,0);b.Parent=panel
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,10);corner.Parent=b
 local t=Instance.new("UITextSizeConstraint");t.MinTextSize=10;t.MaxTextSize=16;t.Parent=b
end
local eS,eC=ss.Enabled,cs.Enabled
local ok,err=pcall(function()
 ss.Enabled=false;cs.Enabled=false
 ss.Source=s;cs.Source=c;gui.Parent=SG
 assert(ss.Source:find(tag,1,true) and cs.Source:find(tag,1,true),"0016 postcheck script")
 assert(ss.Source:find("skin=s.skin",1,true) and ss.Source:find("not isModeCommand and not isSkinCommand",1,true),"0016 postcheck servidor")
 assert(gui.Parent==SG and panel:FindFirstChild("Classic") and panel:FindFirstChild("Ember") and panel:FindFirstChild("Frost"),"0016 postcheck GUI")
 ss.Enabled=eS;cs.Enabled=eC
end)
if not ok then
 ss.Enabled=false;cs.Enabled=false
 local sOk,sErr=pcall(function() ss.Source=originalS end)
 local cOk,cErr=pcall(function() cs.Source=originalC end)
 gui:Destroy()
 ss.Enabled=eS;cs.Enabled=eC
 assert(sOk and cOk,"0016 rollback falhou: "..tostring(sErr).." / "..tostring(cErr))
 error("0016 rollback: "..tostring(err))
end
print("[SnakeGame] 0016 instalado: skins Classic, Ember e Frost. Validar no Studio.")
