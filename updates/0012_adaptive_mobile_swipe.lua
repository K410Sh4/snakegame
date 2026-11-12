-- SnakeGame 0012 | limiar de swipe adaptativo, linhagem 0011 circular
-- Barra de Comandos do Roblox Studio, modo Edit. Nao altera patches historicos.
local RunService=game:GetService("RunService")
assert(not RunService:IsRunning(),"0012: execute fora do Play/Run")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SSS=game:GetService("ServerScriptService")
local StarterGui=game:GetService("StarterGui")
local client=SPS:FindFirstChild("SnakeGameClient")
local server=SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript") and server and server:IsA("Script"),"0012: scripts ausentes")
local original=client.Source
local marker="-- SnakeGame 0012 applied"
if original:find(marker,1,true) then
 assert(original:find("local function swipeThreshold()",1,true),"0012: instalacao parcial")
 print("[SnakeGame] 0012 ja instalado")
 return
end
assert(original:find("-- SnakeGame 0011 applied",1,true),"0012: requer 0011")
assert(original:find("-- SnakeGame 0010 applied",1,true) and server.Source:find("-- SnakeGame 0010 applied",1,true),"0012: requer modo circular 0010")
local hud=StarterGui:FindFirstChild("SnakeGameHUD")
assert(hud and hud:IsA("ScreenGui") and hud:GetAttribute("SnakeGameUpdate")==11,"0012: HUD Explorer 0011 ausente")
local function once(source,needle,replacement,label)
 local i=source:find(needle,1,true)
 assert(i and not source:find(needle,i+#needle,true),"0012 precheck: "..label)
 return source:sub(1,i-1)..replacement..source:sub(i+#needle)
end
local revised=once(original,"local SWIPE_THRESHOLD = 40",[==[
-- Adapta a distancia minima do gesto ao lado mais curto da tela.
local function swipeThreshold()
 local camera=workspace.CurrentCamera
 local viewport=camera and camera.ViewportSize or Vector2.new(720,1280)
 local shortSide=math.min(viewport.X,viewport.Y)
 if shortSide<=0 then return 40 end
 return math.clamp(shortSide*0.055,24,56)
end]==],"limiar")
revised=once(revised,
 "if math.max(math.abs(dx), math.abs(dy)) < SWIPE_THRESHOLD then return end",
 "if math.max(math.abs(dx), math.abs(dy)) < swipeThreshold() then return end",
 "comparacao")
revised=revised.."\n"..marker.."\n"
assert(revised:find("UIS.TouchEnded:Connect",1,true),"0012: gesto perdido")
assert(revised:find('gui:WaitForChild("Score")',1,true),"0012: HUD perdido")
assert(revised:find("local modeGui = player:WaitForChild",1,true),"0012: seletor circular perdido")
assert(not revised:find("SWIPE_THRESHOLD = 40",1,true),"0012: limiar antigo permanece")
local enabled=client.Enabled
local ok,err=pcall(function()
 client.Enabled=false
 client.Source=revised
 assert(client.Source:find(marker,1,true),"0012 postcheck: marcador")
 assert(client.Source:find("math.clamp(shortSide*0.055,24,56)",1,true),"0012 postcheck: formula")
 client.Enabled=enabled
end)
if not ok then
 client.Enabled=false
 pcall(function() client.Source=original end)
 client.Enabled=enabled
 error("[SnakeGame] 0012 rollback: "..tostring(err))
end
print("[SnakeGame] 0012 instalado. Validar sensibilidade mobile no Studio.")
