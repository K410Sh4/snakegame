-- SnakeGame 0007 | reinicio imediato apos morte, sem alterar rate limit de direcao
-- Execute em Edit apos 0001-0006 da linha mobile-swipe/remote-input-guard.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "0007: execute fora do Play/Run")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
assert(server and server:IsA("Script"), "0007: servidor ausente")
assert(client and client:IsA("LocalScript"), "0007: cliente ausente")
local original = server.Source
local marker = "-- SnakeGame 0007 applied"
if original:find(marker, 1, true) then
    assert(original:find("if not s.alive then reset(player) end", 1, true),
        "0007: marcador presente, mas comportamento esperado ausente")
    print("[SnakeGame] 0007 ja aplicado")
    return
end
assert(original:find("-- SnakeGame 0006 applied", 1, true),
    "0007: aplique 0006 antes")
assert(client.Source:find("-- SnakeGame 0005 applied", 1, true),
    "0007: cliente 0005 ausente")
local before = 'if not s.alive and now-s.lastInput>=0.25 then reset(player) end'
local after = 'if not s.alive then reset(player) end'
local at = original:find(before, 1, true)
assert(at and not original:find(before, at + #before, true),
    "0007: trecho original ausente ou duplicado")
local revised = original:sub(1, at - 1) .. after
    .. original:sub(at + #before) .. "\n" .. marker .. "\n"
assert(revised:find('if now-s.lastInput<0.045 then return end', 1, true),
    "0007: rate limit direcional nao reconhecido")
local enabled = server.Enabled
local ok, err = pcall(function()
    server.Enabled = false
    server.Source = revised
    assert(server.Source:find(marker, 1, true), "0007: postcheck marcador")
    assert(server.Source:find(after, 1, true), "0007: postcheck reinicio")
    assert(not server.Source:find(before, 1, true), "0007: cooldown antigo permanece")
    server.Enabled = enabled
end)
if not ok then
    server.Enabled = false
    server.Source = original
    server.Enabled = enabled
    error("SnakeGame 0007 rollback: " .. tostring(err))
end
print("[SnakeGame] 0007 aplicado. Validar morte/reinicio no Roblox Studio.")
