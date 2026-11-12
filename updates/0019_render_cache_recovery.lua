-- SnakeGame 0019 | recuperacao do cache de partes apos remocao externa
-- Command Bar Roblox Studio, Edit, apos 0018. Nao altera patches anteriores.
-- Se outro script destruir uma parte de segmento/alimento, 0018 mantem referencia
-- obsoleta; este patch invalida a referencia e recria a parte na proxima pintura.
-- Fontes: https://create.roblox.com/docs/reference/engine/classes/Instance#Parent
--         https://create.roblox.com/docs/reference/engine/classes/Instance#Destroy
local RunService=game:GetService("RunService")
assert(not RunService:IsRunning(),"0019: aplicar somente em Edit")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local server=SSS:FindFirstChild("SnakeGameServer")
local client=SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"),"0019: servidor ausente")
assert(client and client:IsA("LocalScript"),"0019: cliente ausente")
local old=server.Source
local marker="-- SnakeGame 0019 applied"
local segmentBefore="local p=segmentParts[i]"
local segmentAfter=[==[local p=segmentParts[i]
        -- Referencias destruídas nao podem ser reutilizadas.
        if p and p.Parent~=segments then
            segmentParts[i]=nil
            p=nil
        end]==]
local foodBefore="local food=s.foodPart"
local foodAfter=[==[local food=s.foodPart
    if food and food.Parent~=model then
        s.foodPart=nil
        food=nil
    end]==]
local function count(s,needle)
    local n,from=0,1
    while true do
        local at=s:find(needle,from,true)
        if not at then return n end
        n+=1
        from=at+#needle
    end
end
if old:find(marker,1,true) then
    assert(count(old,segmentAfter)==1 and count(old,foodAfter)==1,
        "0019: instalacao marcada, mas reparo incompleto")
    print("[SnakeGame] 0019 ja instalado")
    return
end
assert(old:find("-- SnakeGame 0018 applied",1,true),"0019: requer cache 0018")
assert(old:find("-- SnakeGame 0016 applied",1,true),"0019: requer skins canonicas")
assert(client.Source:find("-- SnakeGame 0017 applied",1,true),"0019: requer camera 0017")
assert(count(old,segmentBefore)==1 and count(old,foodBefore)==1,
    "0019: anchors ausentes ou duplicadas")
assert(count(old,segmentAfter)==0 and count(old,foodAfter)==0,
    "0019: reparo preexistente sem marcador")
local function once(s,a,b)
    local i=assert(s:find(a,1,true))
    return s:sub(1,i-1)..b..s:sub(i+#a)
end
local nextSource=once(once(old,segmentBefore,segmentAfter),foodBefore,foodAfter)
nextSource=nextSource.."\n"..marker.."\n"
assert(count(nextSource,segmentAfter)==1 and count(nextSource,foodAfter)==1,
    "0019: transformacao incompleta")
local wasEnabled=server.Enabled
local ok,err=pcall(function()
    server.Enabled=false
    server.Source=nextSource
    assert(server.Source==nextSource,"0019 postcheck: Source divergente")
    assert(server.Source:find(marker,1,true),"0019 postcheck: marcador")
    server.Enabled=wasEnabled
end)
if not ok then
    server.Enabled=false
    local restored,restoreErr=pcall(function() server.Source=old end)
    server.Enabled=wasEnabled
    assert(restored,"0019 rollback falhou: "..tostring(restoreErr))
    error("0019 rollback executado: "..tostring(err))
end
print("[SnakeGame] 0019 instalado. Testar destruicao externa de segmentos/food no Studio.")
