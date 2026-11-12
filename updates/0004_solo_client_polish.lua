-- SnakeGame 0004 | camera responsiva e personagem local invisivel
-- Execute no Roblox Studio (Edit), apos 0001, 0002 e 0003.
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SSS = game:GetService("ServerScriptService")
local client = SPS:FindFirstChild("SnakeGameClient")
local server = SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript"), "0004: cliente ausente")
assert(server and server:IsA("Script"), "0004: servidor ausente")
local old = client.Source
local marker = "-- SnakeGame 0004 applied"
if old:find(marker, 1, true) then
    print("[SnakeGame] 0004 ja aplicado")
    return
end
assert(server.Source:find("-- SnakeGame 0003 applied",1,true), "0004: instale 0003 antes")
assert(old:find("-- SnakeGame 0003 applied",1,true), "0004: cliente 0003 ausente")
local needle = 'camera.CFrame=CFrame.lookAt(Vector3.new(x,90,65),Vector3.new(x,0,0))'
assert(old:find(needle,1,true), "0004: camera original nao encontrada")
assert(not old:find(needle,old:find(needle,1,true)+#needle,true), "0004: camera duplicada")
local replacement = [==[
        -- Ajusta a altura para preservar o tabuleiro em telas estreitas.
        local viewport = camera.ViewportSize
        local aspect = viewport.Y > 0 and viewport.X / viewport.Y or 16/9
        local verticalFov = math.rad(55)
        local horizontalFov = 2 * math.atan(math.tan(verticalFov/2) * math.max(aspect,0.35))
        local distanceForWidth = 39 / math.tan(horizontalFov/2)
        local distanceForHeight = 39 / math.tan(verticalFov/2)
        local distance = math.max(distanceForWidth,distanceForHeight,90)
        camera.CFrame=CFrame.lookAt(Vector3.new(x,distance,distance*0.70),Vector3.new(x,0,0))
]==]
local first = old:find(needle,1,true)
local updated = old:sub(1,first-1)..replacement..old:sub(first+#needle)
updated = updated .. [==[

-- SnakeGame 0004 applied
-- Recalcula camera ao mudar resolucao/orientacao.
local viewportConnection
local function bindViewport()
    if viewportConnection then viewportConnection:Disconnect() end
    local active = workspace.CurrentCamera
    if active then
        viewportConnection = active:GetPropertyChangedSignal("ViewportSize"):Connect(setCamera)
    end
    setCamera()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)
bindViewport()

-- Oculta somente o avatar local, preservando a simulacao dos outros jogadores.
local function hideAvatar(character)
    local function hide(instance)
        if instance:IsA("BasePart") then
            instance.LocalTransparencyModifier = 1
        elseif instance:IsA("Decal") then
            instance.Transparency = 1
        end
    end
    for _,instance in ipairs(character:GetDescendants()) do hide(instance) end
    character.DescendantAdded:Connect(hide)
end
if player.Character then hideAvatar(player.Character) end
player.CharacterAdded:Connect(hideAvatar)
]==]
local wasEnabled = client.Enabled
local ok,err = pcall(function()
    client.Enabled = false
    client.Source = updated
    assert(client.Source:find(marker,1,true), "0004: postcheck marker")
    assert(client.Source:find("ViewportSize",1,true), "0004: postcheck viewport")
    client.Enabled = wasEnabled
end)
if not ok then
    client.Enabled = false
    client.Source = old
    client.Enabled = wasEnabled
    error("0004 rollback: "..tostring(err))
end
print("[SnakeGame] 0004 instalado. Validar camera em PC/mobile no Play Test.")
