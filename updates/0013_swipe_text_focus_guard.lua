-- SnakeGame 0013 | nao enviar gestos enquanto jogador digita
-- Barra de Comandos, modo Edit; aplicar depois de 0012 na linhagem canonica.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "0013: execute em Edit")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SSS = game:GetService("ServerScriptService")
local client = SPS:FindFirstChild("SnakeGameClient")
local server = SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript"), "0013: cliente ausente")
assert(server and server:IsA("Script"), "0013: servidor ausente")
local old = client.Source
local marker = "-- SnakeGame 0013 applied"
local needle = "    if processed or origin == nil then return end"
local replacement = "    if processed or origin == nil or UIS:GetFocusedTextBox() ~= nil then return end"
local function count(source, target)
    local n, start = 0, 1
    while true do
        local at = source:find(target, start, true)
        if not at then return n end
        n, start = n + 1, at + #target
    end
end
if old:find(marker, 1, true) then
    assert(count(old, replacement) == 1 and count(old, needle) == 0,
        "0013: marcador presente mas alteracao incompleta")
    print("[SnakeGame] 0013 ja instalado")
    return
end
assert(old:find("-- SnakeGame 0012 applied", 1, true), "0013: requer 0012")
assert(server.Source:find("-- SnakeGame 0010 applied", 1, true), "0013: requer servidor circular 0010")
assert(count(old, needle) == 1, "0013: ponto de edicao ausente ou duplicado")
assert(count(old, replacement) == 0, "0013: alteracao ja presente sem marcador")
assert(old:find("UIS.TouchStarted:Connect", 1, true)
    and old:find("UIS.TouchEnded:Connect", 1, true)
    and old:find("swipeThreshold()", 1, true), "0013: controles esperados ausentes")
local at = assert(old:find(needle, 1, true))
local revised = old:sub(1, at - 1) .. replacement .. old:sub(at + #needle)
    .. "\n" .. marker .. "\n"
assert(count(revised, replacement) == 1 and count(revised, needle) == 0,
    "0013: precheck de substituicao falhou")
local enabled = client.Enabled
local ok, err = pcall(function()
    client.Enabled = false
    client.Source = revised
    assert(client.Source:find(marker, 1, true), "0013 postcheck: marcador")
    assert(count(client.Source, replacement) == 1, "0013 postcheck: filtro")
    assert(client.Source:find("swipeThreshold()", 1, true), "0013 postcheck: limiar")
    client.Enabled = enabled
end)
if not ok then
    client.Enabled = false
    local restored, restoreError = pcall(function() client.Source = old end)
    client.Enabled = enabled
    assert(restored, "0013: rollback falhou: " .. tostring(restoreError))
    error("0013: rollback executado: " .. tostring(err))
end
print("[SnakeGame] 0013 aplicado; validar toque em TextBox no Studio.")
