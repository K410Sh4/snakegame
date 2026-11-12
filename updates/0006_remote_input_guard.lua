-- SnakeGame 0006 | validacao antecipada de comandos remotos
-- Execute na Barra de Comandos do Roblox Studio (Edit) apos 0001-0005.
-- Endurece o servidor sem alterar o protocolo, os controles ou as regras existentes.
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"), "0006: servidor ausente")
assert(client and client:IsA("LocalScript"), "0006: cliente ausente")
local original = server.Source
local marker = "-- SnakeGame 0006 applied"
if original:find(marker, 1, true) then
    print("[SnakeGame] 0006 ja aplicado")
    return
end
assert(original:find("-- SnakeGame 0003 applied", 1, true),
    "0006: servidor precisa dos patches anteriores")
assert(client.Source:find("-- SnakeGame 0005 applied", 1, true),
    "0006: aplique 0005 no cliente primeiro")
local before = 'if typeof(command)~="string" then return end'
local after = [==[if typeof(command)~="string" or #command > 7 then return end
    -- Apenas comandos reconhecidos chegam ao estado da sessao.
    if command~="Restart" and directions[command]==nil then return end]==]
local startAt = original:find(before, 1, true)
assert(startAt, "0006 precheck: validacao original nao encontrada")
assert(not original:find(before, startAt + #before, true),
    "0006 precheck: trecho de validacao duplicado")
local revised = original:sub(1, startAt - 1)
    .. after .. original:sub(startAt + #before)
    .. "\n" .. marker .. "\n"
local wasEnabled = server.Enabled
local ok, err = pcall(function()
    server.Enabled = false
    server.Source = revised
    assert(server.Source:find(marker, 1, true), "0006 postcheck: marker")
    assert(server.Source:find("#command > 7", 1, true),
        "0006 postcheck: limite de payload")
    assert(server.Source:find("directions[command]==nil", 1, true),
        "0006 postcheck: whitelist")
    server.Enabled = wasEnabled
end)
if not ok then
    server.Enabled = false
    server.Source = original
    server.Enabled = wasEnabled
    error("SnakeGame 0006 rollback: " .. tostring(err))
end
print("[SnakeGame] 0006 instalado: comandos remotos limitados e validados.")
