-- SnakeGame 0002: isolamento visual do Solo e endurecimento de entradas.
-- Execute na Barra de Comandos em modo Edit, APOS o patch 0001.
-- Preserva o patch historico e modifica apenas os scripts instalados.
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS = game:GetService("ReplicatedStorage")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
local net = RS:FindFirstChild("SnakeGame")
assert(server and server:IsA("Script"), "0001: servidor ausente")
assert(client and client:IsA("LocalScript"), "0001: cliente ausente")
assert(net and net:FindFirstChild("Turn") and net:FindFirstChild("State"), "0001: rede ausente")
local marker = "-- SnakeGame 0002 applied"
local oldServer, oldClient = server.Source, client.Source
if string.find(oldServer, marker, 1, true) and string.find(oldClient, marker, 1, true) then
    print("[SnakeGame] 0002 ja aplicado; nenhuma alteracao")
    return
end
assert(not string.find(oldServer, marker, 1, true) and not string.find(oldClient, marker, 1, true),
    "Instalacao parcial 0002: corrija manualmente antes de reaplicar")
local function replaceOnce(source, before, after, description)
    local first = string.find(source, before, 1, true)
    assert(first, "Precheck 0002: trecho ausente: "..description)
    assert(not string.find(source, before, first + #before, true), "Precheck 0002: trecho duplicado: "..description)
    return string.sub(source, 1, first - 1)..after..string.sub(source, first + #before)
end
-- Evita aceitar reversao baseada em um comando pendente; somente a direcao
-- efetiva do tick pode ser usada para verificar a manobra.
local newServer = replaceOnce(oldServer,
    "local reference=s.pending or s.dir\n    if dir~=reference and dir~=-s.dir then s.pending=dir end",
    "if dir~=s.dir and dir~=-s.dir then s.pending=dir end",
    "validacao de direcao")
-- Um reset imediato depois de morrer nao pode depender do rate-limit de
-- direcao: o jogador precisa conseguir recomecar sem atraso artificial.
newServer = replaceOnce(newServer,
    "if now-s.lastInput<0.045 then return end\n    s.lastInput=now\n    if command==\"Restart\" then if not s.alive then reset(player) end; return end",
    "if command==\"Restart\" then\n        if not s.alive and now-s.lastInput>=0.25 then reset(player) end\n        return\n    end\n    if now-s.lastInput<0.045 then return end\n    s.lastInput=now",
    "rate limit e reinicio")
-- Cada cliente ve apenas a propria cobra. O servidor continua controlando
-- todas as sessoes e os jogadores nao podem alterar pontuacoes alheias.
local clientAddon = [==[
-- SnakeGame 0002 applied
local arena = workspace:WaitForChild("SnakeGameArena")
local ownName = "Snake_" .. tostring(player.UserId)
local function filterModel(model)
    if not model:IsA("Model") or not string.match(model.Name, "^Snake_%d+$") then return end
    local hidden = model.Name ~= ownName
    local function filterPart(part)
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = hidden and 1 or 0
        end
    end
    for _,part in ipairs(model:GetDescendants()) do filterPart(part) end
    model.DescendantAdded:Connect(filterPart)
end
for _,model in ipairs(arena:GetChildren()) do filterModel(model) end
arena.ChildAdded:Connect(filterModel)
]==]
local newClient = oldClient .. "\n" .. clientAddon
newServer = newServer .. "\n" .. marker .. "\n"
local wasServerEnabled, wasClientEnabled = server.Enabled, client.Enabled
local ok, err = pcall(function()
    server.Enabled = false
    client.Enabled = false
    server.Source = newServer
    client.Source = newClient
    assert(string.find(server.Source, marker, 1, true), "Postcheck servidor")
    assert(string.find(client.Source, marker, 1, true), "Postcheck cliente")
    server.Enabled = wasServerEnabled
    client.Enabled = wasClientEnabled
end)
if not ok then
    server.Enabled = false
    client.Enabled = false
    server.Source = oldServer
    client.Source = oldClient
    server.Enabled = wasServerEnabled
    client.Enabled = wasClientEnabled
    error("SnakeGame 0002 rollback: "..tostring(err))
end
print("[SnakeGame] 0002 instalado: visibilidade individual, direcao segura, reinicio revisado.")
