-- SnakeGame 0009 | estado de vitoria quando o tabuleiro fica completo
-- Execute na Barra de Comandos do Roblox Studio em modo Edit apos 0008.
local RunService=game:GetService("RunService")
assert(not RunService:IsRunning(),"0009: execute em modo Edit")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local server=SSS:FindFirstChild("SnakeGameServer")
local client=SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script") and client and client:IsA("LocalScript"),"0009: scripts ausentes")
local oldS,oldC=server.Source,client.Source
local tag="-- SnakeGame 0009 applied"
if oldS:find(tag,1,true) or oldC:find(tag,1,true) then
 assert(oldS:find(tag,1,true) and oldC:find(tag,1,true),"0009: instalacao parcial")
 print("[SnakeGame] 0009 ja aplicado")
 return
end
assert(oldS:find("-- SnakeGame 0008 applied",1,true),"0009: aplique 0008")
assert(oldC:find("-- SnakeGame 0005 applied",1,true),"0009: aplique 0005")
local function once(source,before,after,label)
 local i=source:find(before,1,true)
 assert(i and not source:find(before,i+#before,true),"0009 precheck: "..label)
 return source:sub(1,i-1)..after..source:sub(i+#before)
end
local newS=once(oldS,"score=s.score,alive=s.alive,body=s.body","score=s.score,alive=s.alive,won=s.won==true,body=s.body","estado enviado")
newS=once(newS,"score=0,alive=true,model=model","score=0,alive=true,won=false,model=model","estado inicial")
newS=once(newS,"if not s.food then s.alive=false end","if not s.food then s.alive=false; s.won=true end","tabuleiro completo")
local newC=once(oldC,'hint.Text=(s.alive==false) and "FIM DE JOGO" or (UIS.TouchEnabled and "DESLIZE OU USE SETAS" or "WASD / SETAS")','hint.Text=(s.won==true) and "VITORIA! TABULEIRO COMPLETO" or ((s.alive==false) and "FIM DE JOGO" or (UIS.TouchEnabled and "DESLIZE OU USE SETAS" or "WASD / SETAS"))',"mensagem final")
newS=newS.."\n"..tag.."\n"
newC=newC.."\n"..tag.."\n"
local es,ec=server.Enabled,client.Enabled
local ok,err=pcall(function()
 server.Enabled=false;client.Enabled=false
 server.Source=newS;client.Source=newC
 assert(server.Source:find(tag,1,true) and client.Source:find(tag,1,true),"0009 postcheck")
 assert(server.Source:find("s.won=true",1,true) and client.Source:find("s.won==true",1,true),"0009 postcheck estado")
 server.Enabled=es;client.Enabled=ec
end)
if not ok then
 server.Enabled=false;client.Enabled=false
 server.Source=oldS;client.Source=oldC
 server.Enabled=es;client.Enabled=ec
 error("0009 rollback: "..tostring(err))
end
print("[SnakeGame] 0009 aplicado: vitoria distinta de derrota. Validar no Studio.")
