-- SnakeGame 0018 | cache de segmentos no servidor (Classic/Circular + skins)
-- Barra de Comandos do Roblox Studio, em modo Edit, depois da linhagem 0001-0016.
-- Base desta versao: 0016_server_validated_skins.lua (branch feature/0016-skin-palettes-manual).
-- Nao modifica os patches historicos, o HUD ou as regras de simulacao.
-- Pesquisa: https://create.roblox.com/docs/performance-optimization/improve
--           https://create.roblox.com/docs/performance-optimization/microprofiler
-- Este patch otimiza o caminho de renderizacao; FPS/tempo real exigem Play Test.

local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "0018: execute em Edit, fora do Play/Run")

local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local StarterGui = game:GetService("StarterGui")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"), "0018: servidor ausente")
assert(client and client:IsA("LocalScript"), "0018: cliente ausente")

local original = server.Source
local marker = "-- SnakeGame 0018 applied"
if original:find(marker, 1, true) then
    assert(original:find("s.segmentParts", 1, true)
        and original:find("s.foodPart", 1, true)
        and original:find("segmentParts[i]=p", 1, true),
        "0018: marcador presente, mas cache incompleto")
    print("[SnakeGame] 0018 ja instalado")
    return
end

assert(original:find("-- SnakeGame 0010 applied", 1, true),
    "0018: requer servidor 0010 circular")
assert(original:find("-- SnakeGame 0016 applied", 1, true)
    and original:find("skinPalettes[s.skin]", 1, true),
    "0018: requer variante 0016_server_validated_skins; nao misture variantes")
assert(client.Source:find("-- SnakeGame 0015 applied", 1, true)
    and client.Source:find("-- SnakeGame 0016 applied", 1, true),
    "0018: requer cliente da linha canonica ate 0016")
local skins = StarterGui:FindFirstChild("SnakeGameSkinSelect")
assert(skins and skins:IsA("ScreenGui")
    and skins:GetAttribute("SnakeGameUpdate") == 16,
    "0018: GUI de skins 0016 ausente")

local function replaceOne(source, before, after, name)
    local at = source:find(before, 1, true)
    assert(at and not source:find(before, at + #before, true),
        "0018 precheck: ancora ausente/duplicada: " .. name)
    return source:sub(1, at-1) .. after .. source:sub(at+#before)
end

local revised = original
revised = replaceOne(revised,
    [==[local segments=model:FindFirstChild("Segments")
    if not segments then segments=Instance.new("Folder"); segments.Name="Segments"; segments.Parent=model end]==],
    [==[local segments=s.segments
    if not segments or segments.Parent~=model or not s.segmentParts then
        segments=Instance.new("Folder")
        segments.Name="Segments"
        segments.Parent=model
        s.segments=segments
        s.segmentParts={}
    end
    local segmentParts=s.segmentParts]==],
    "cache de pasta e referencias")

revised = replaceOne(revised,
    'local p=segments:FindFirstChild(tostring(i))',
    'local p=segmentParts[i]',
    "lookup por indice")
revised = replaceOne(revised,
    'if not p then p=makePart(segments,tostring(i),Vector3.new(3.35,2.5,3.35),Color3.fromRGB(61,202,105),Enum.Material.Neon) end',
    [==[if not p then
            p=makePart(segments,tostring(i),Vector3.new(3.35,2.5,3.35),Color3.fromRGB(61,202,105),Enum.Material.Neon)
            segmentParts[i]=p
        end]==],
    "criacao de segmento")
revised = replaceOne(revised,
    [==[for _,p in ipairs(segments:GetChildren()) do
        if tonumber(p.Name) and tonumber(p.Name)>#s.body then p:Destroy() end
    end]==],
    [==[-- Percorre apenas o excedente quando o corpo diminui; sem GetChildren por tick.
    for i=#segmentParts,#s.body+1,-1 do
        segmentParts[i]:Destroy()
        segmentParts[i]=nil
    end]==],
    "limpeza indexada")
revised = replaceOne(revised,
    'local food=model:FindFirstChild("Food")',
    'local food=s.foodPart',
    "cache do alimento")
revised = replaceOne(revised,
    'if not food then food=makePart(model,"Food",Vector3.new(2.8,2.8,2.8),Color3.fromRGB(255,102,109),Enum.Material.Neon); food.Shape=Enum.PartType.Ball end',
    [==[if not food then
            food=makePart(model,"Food",Vector3.new(2.8,2.8,2.8),Color3.fromRGB(255,102,109),Enum.Material.Neon)
            food.Shape=Enum.PartType.Ball
            s.foodPart=food
        end]==],
    "criacao de alimento")
revised = replaceOne(revised,
    'elseif food then food:Destroy() end',
    'elseif food then food:Destroy(); s.foodPart=nil end',
    "liberacao do cache de alimento")

revised ..= "\n" .. marker .. "\n"
assert(revised:find("local palette=skinPalettes[s.skin] or skinPalettes.Classic",1,true),
    "0018: selecao de paleta foi alterada")
assert(revised:find("p.Color=(i==1) and palette.head or palette.body",1,true),
    "0018: cores das skins foram alteradas")
assert(revised:find("p.Position=point(v,s.origin)",1,true)
    and revised:find("food.Position=point(s.food,s.origin)",1,true),
    "0018: posicionamento da arena nao reconhecido")
assert(revised:find("s.segmentParts={}",1,true)
    and revised:find("segmentParts[i]=p",1,true)
    and revised:find("segmentParts[i]=nil",1,true),
    "0018: invariantes de cache ausentes")

local previousEnabled = server.Enabled
local ok, err = pcall(function()
    server.Enabled=false
    server.Source=revised
    assert(server.Source == revised, "0018 postcheck: fonte divergente")
    assert(server.Source:find(marker,1,true), "0018 postcheck: marcador ausente")
    server.Enabled=previousEnabled
end)
if not ok then
    server.Enabled=false
    local restored, restoreErr = pcall(function() server.Source=original end)
    server.Enabled=previousEnabled
    assert(restored, "0018: rollback falhou: "..tostring(restoreErr))
    error("0018 rollback: "..tostring(err))
end
print("[SnakeGame] 0018 instalado: cache de partes/food. Medir no MicroProfiler do Studio.")