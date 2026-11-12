-- SnakeGame 0017 | camera Focus e isolamento visual da base de arenas Solo
-- Barra de Comandos Roblox Studio: execute no modo Edit apos a variante canonica 0016_server_validated_skins.lua.
-- Nao modifica patches historicos, HUD ou servidor; altera apenas SnakeGameClient.
-- Referencias: https://create.roblox.com/docs/workspace/camera
-- https://create.roblox.com/docs/reference/engine/classes/Camera
-- https://create.roblox.com/docs/reference/engine/classes/BasePart

local RunService=game:GetService("RunService")
assert(not RunService:IsRunning(),"0017: execute fora de Play/Run")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SSS=game:GetService("ServerScriptService")
local StarterGui=game:GetService("StarterGui")
local WS=game:GetService("Workspace")
local client=SPS:FindFirstChild("SnakeGameClient")
local server=SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript"),"0017: SnakeGameClient ausente")
assert(server and server:IsA("Script"),"0017: SnakeGameServer ausente")
assert(WS:FindFirstChild("SnakeGameArena"),"0017: arena Solo ausente")
local original=client.Source
local marker="-- SnakeGame 0017 applied"
local before='camera.CFrame=CFrame.lookAt(Vector3.new(x,distance,distance*0.70),Vector3.new(x,0,0))'
local after=[==[local target=Vector3.new(x,0,0)
        camera.CFrame=CFrame.lookAt(Vector3.new(x,distance,distance*0.70),target)
        -- CameraType.Scriptable nao atualiza Focus automaticamente.
        -- A camera e estatica entre chamadas de setCamera (troca de slot/tela).
        camera.Focus=CFrame.new(target)
        -- As partes diretas de SnakeGameArena representam o piso do slot zero.
        -- Slots secundarios possuem copias dentro do proprio modelo Snake_<id>.
        -- Nao altere outros modelos nem as geometrias de seus jogadores.
        local arenaRoot=workspace:FindFirstChild("SnakeGameArena")
        if arenaRoot then
            local own=arenaRoot:FindFirstChild("Snake_"..tostring(player.UserId))
            local origin=own and own:GetAttribute("ArenaX")
            if typeof(origin)=="number" then
                local hideBase=(origin~=0)
                for _,piece in ipairs(arenaRoot:GetChildren()) do
                    if piece:IsA("BasePart") then
                        piece.LocalTransparencyModifier=hideBase and 1 or 0
                    end
                end
            end
        end]==]
local function count(source,needle)
    local n,from=0,1
    while true do
        local at=source:find(needle,from,true)
        if not at then return n end
        n+=1
        from=at+#needle
    end
end
if original:find(marker,1,true) then
    assert(count(original,after)==1 and count(original,before)==0,
        "0017: marcador presente mas codigo esperado ausente")
    print("[SnakeGame] 0017 ja aplicado")
    return
end
assert(original:find("-- SnakeGame 0016 applied",1,true)
    and original:find("-- SnakeGame 0015 applied",1,true),
    "0017: requer instalacao sequencial ate 0016")
assert(server.Source:find("skinCommands[command]",1,true),
    "0017: requer variante 0016_server_validated_skins.lua; ha outra 0016 concorrente")
local skinGui=StarterGui:FindFirstChild("SnakeGameSkinSelect")
assert(skinGui and skinGui:IsA("ScreenGui")
    and skinGui:GetAttribute("SnakeGameUpdate")==16,
    "0017: GUI de skins 0016 ausente")
assert(original:find("-- SnakeGame 0003 applied",1,true)
    and original:find("-- SnakeGame 0004 applied",1,true),
    "0017: cameras e slots Solo anteriores ausentes")
assert(original:find('model:GetAttributeChangedSignal("ArenaX"):Connect(setCamera)',1,true),
    "0017: atualizacao de camera ao trocar slot ausente")
assert(count(original,before)==1 and count(original,after)==0,
    "0017: ponto de camera ausente ou duplicado")
local at=assert(original:find(before,1,true))
local revised=original:sub(1,at-1)..after..original:sub(at+#before)
    .."\n"..marker.."\n"
assert(count(revised,after)==1 and count(revised,before)==0,
    "0017: transformacao textual inconsistente")
assert(revised:find("camera.Focus=CFrame.new(target)",1,true)
    and revised:find("piece.LocalTransparencyModifier=hideBase and 1 or 0",1,true),
    "0017: foco/isolamento ausentes")
local enabled=client.Enabled
local ok,err=pcall(function()
    client.Enabled=false
    client.Source=revised
    assert(client.Source==revised,"0017 postcheck: fonte divergente")
    assert(client.Source:find(marker,1,true),"0017 postcheck: marcador")
    assert(client.Source:find("-- SnakeGame 0016 applied",1,true),
        "0017 postcheck: historico de patches alterado")
    client.Enabled=enabled
end)
if not ok then
    client.Enabled=false
    local restored,restoreError=pcall(function() client.Source=original end)
    client.Enabled=enabled
    assert(restored,"0017: falha no rollback: "..tostring(restoreError))
    error("[SnakeGame] 0017 rollback: "..tostring(err))
end
print("[SnakeGame] 0017 instalado. Testar Focus e isolamento com 2+ jogadores no Studio.")
