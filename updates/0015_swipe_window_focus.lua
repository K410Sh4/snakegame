-- SnakeGame 0015 | cancelamento de swipe ao perder foco da janela
-- Aplicar no Roblox Studio em modo Edit apos o patch 0014.
local RunService=game:GetService("RunService")
assert(not RunService:IsRunning(),"0015: execute em Edit")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SSS=game:GetService("ServerScriptService")
local client=SPS:FindFirstChild("SnakeGameClient")
local server=SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript"),"0015: cliente ausente")
assert(server and server:IsA("Script"),"0015: servidor ausente")
local original=client.Source
local marker="-- SnakeGame 0015 applied"
local anchor="UIS.TextBoxFocused:Connect(function()"
local focusListener=[==[
-- Cancela gesto incompleto quando a janela perde foco (minimizar/alternar app).
UIS.WindowFocusReleased:Connect(function()
    swipeFinger = nil
    swipeOrigin = nil
end)
]==]
local function count(s,needle)
    local n,start=0,1
    while true do
        local i=s:find(needle,start,true)
        if not i then return n end
        n+=1
        start=i+#needle
    end
end
if original:find(marker,1,true) then
    assert(count(original,"UIS.WindowFocusReleased:Connect(function()")==1,"0015: instalacao parcial")
    print("[SnakeGame] 0015 ja aplicado")
    return
end
assert(original:find("-- SnakeGame 0014 applied",1,true),"0015: requer 0014")
assert(server.Source:find("-- SnakeGame 0010 applied",1,true),"0015: requer servidor circular")
assert(count(original,anchor)==1,"0015: ponto de insercao alterado")
assert(count(original,"UIS.WindowFocusReleased:Connect(function()")==0,"0015: listener existente")
assert(count(original,"local swipeFinger = nil")==1 and count(original,"local swipeOrigin = nil")==1,"0015: estado de toque alterado")
local at=assert(original:find(anchor,1,true))
local revised=original:sub(1,at-1)..focusListener..original:sub(at)
revised=revised.."\n"..marker.."\n"
assert(count(revised,marker)==1 and count(revised,"UIS.WindowFocusReleased:Connect(function()")==1,"0015: transformacao invalida")
local wasEnabled=client.Enabled
local ok,err=pcall(function()
    client.Enabled=false
    client.Source=revised
    assert(client.Source==revised,"0015: postcheck falhou")
    client.Enabled=wasEnabled
end)
if not ok then
    client.Enabled=false
    local restored,restoreErr=pcall(function() client.Source=original end)
    client.Enabled=wasEnabled
    assert(restored,"0015: rollback falhou: "..tostring(restoreErr))
    error("0015: rollback executado: "..tostring(err))
end
print("[SnakeGame] 0015 instalado. Testar minimizar app durante swipe.")
