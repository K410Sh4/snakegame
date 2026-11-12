-- SnakeGame 0008 | compatibilidade segura de comandos de modo com 0006/0007
-- Execute na Barra de Comandos do Roblox Studio em modo Edit apos 0007.
-- Mantem validacao de tipo, tamanho e whitelist; nao instala modos nem altera patches historicos.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "0008: execute fora de Play/Run")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"), "0008: servidor ausente")
assert(client and client:IsA("LocalScript"), "0008: cliente ausente")
local original = server.Source
local marker = "-- SnakeGame 0008 applied"
local before = [==[if typeof(command)~="string" or #command > 7 then return end
    -- Apenas comandos reconhecidos chegam ao estado da sessao.
    if command~="Restart" and directions[command]==nil then return end]==]
local after = [==[if typeof(command)~="string" or #command > 12 then return end
    -- Comandos de modo sao aceitos apenas quando o servidor implementa o handler.
    -- Os comandos direcionais e Restart continuam validados no servidor.
    local isModeCommand = command=="ModeClassic" or command=="ModeCircular"
    if command~="Restart" and directions[command]==nil and not isModeCommand then return end
    if isModeCommand and not hasModeHandler then return end]==]
if original:find(marker, 1, true) then
    assert(original:find(after, 1, true), "0008: marcador presente, mas validacao divergente")
    print("[SnakeGame] 0008 ja aplicado")
    return
end
assert(original:find("-- SnakeGame 0006 applied", 1, true), "0008: requer 0006")
assert(original:find("-- SnakeGame 0007 applied", 1, true), "0008: requer 0007")
assert(client.Source:find("-- SnakeGame 0005 applied", 1, true), "0008: requer cliente 0005")
local startAt = original:find(before, 1, true)
assert(startAt and not original:find(before, startAt + #before, true),
    "0008: bloco de validacao 0006 ausente ou duplicado")
-- O handler e detectado pela presenca da rotina de troca de modos, nao pelo marcador 0005
-- que foi reutilizado por tres patches concorrentes incompatíveis.
local modeHandlerNeedle = 'if command=="ModeClassic" or command=="ModeCircular" then'
local hasModeHandler = original:find(modeHandlerNeedle, 1, true) ~= nil
local declaration = "local hasModeHandler = " .. tostring(hasModeHandler) .. "\n    "
local replacement = declaration .. after
local revised = original:sub(1, startAt - 1) .. replacement
    .. original:sub(startAt + #before) .. "\n" .. marker .. "\n"
assert(revised:find("local hasModeHandler = " .. tostring(hasModeHandler), 1, true),
    "0008: postcheck declaracao")
local enabled = server.Enabled
local ok, err = pcall(function()
    server.Enabled = false
    server.Source = revised
    assert(server.Source:find(marker, 1, true), "0008: postcheck marcador")
    assert(server.Source:find(after, 1, true), "0008: postcheck whitelist")
    assert(not server.Source:find(before, 1, true), "0008: validacao antiga presente")
    server.Enabled = enabled
end)
if not ok then
    server.Enabled = false
    pcall(function() server.Source = original end)
    server.Enabled = enabled
    error("[SnakeGame] 0008 rollback: " .. tostring(err))
end
print("[SnakeGame] 0008 instalado. Modos habilitados no filtro: " .. tostring(hasModeHandler))
