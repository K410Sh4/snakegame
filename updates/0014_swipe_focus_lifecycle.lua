-- SnakeGame 0014 | ciclo de foco para gestos mobile
-- Aplicar na Barra de Comandos do Roblox Studio em Edit, apos 0013.
-- Preserva o historico; altera somente o LocalScript instalado.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "0014: execute fora do Play/Run")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SSS = game:GetService("ServerScriptService")
local client = SPS:FindFirstChild("SnakeGameClient")
local server = SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript"), "0014: cliente ausente")
assert(server and server:IsA("Script"), "0014: servidor ausente")
local original = client.Source
local marker = "-- SnakeGame 0014 applied"
local oldStart = "    if processed or swipeFinger ~= nil then return end"
local newStart = "    if processed or swipeFinger ~= nil or UIS:GetFocusedTextBox() ~= nil then return end"
local anchor = "UIS.TouchStarted:Connect(function(input, processed)"
local oldEnd = "    if processed or origin == nil or UIS:GetFocusedTextBox() ~= nil then return end"
local function occurrences(s, needle)
    local count, from = 0, 1
    while true do
        local at = s:find(needle, from, true)
        if not at then return count end
        count += 1
        from = at + #needle
    end
end
if original:find(marker, 1, true) then
    assert(occurrences(original, newStart) == 1
        and occurrences(original, "UIS.TextBoxFocused:Connect(function()") == 1,
        "0014: instalacao parcial ou alterada")
    print("[SnakeGame] 0014 ja aplicado")
    return
end
assert(original:find("-- SnakeGame 0013 applied", 1, true), "0014: requer 0013")
assert(server.Source:find("-- SnakeGame 0010 applied", 1, true), "0014: requer servidor circular")
assert(occurrences(original, oldStart) == 1 and occurrences(original, newStart) == 0,
    "0014: precheck inicio de toque")
assert(occurrences(original, anchor) == 1 and occurrences(original, oldEnd) == 1,
    "0014: precheck ciclo de toque")
assert(occurrences(original, "UIS.TextBoxFocused:Connect(function()") == 0,
    "0014: outro listener de foco ja instalado")
local at = assert(original:find(oldStart, 1, true))
local revised = original:sub(1, at - 1) .. newStart .. original:sub(at + #oldStart)
local atStart = assert(revised:find(anchor, 1, true))
local listener = [==[
-- Cancela o gesto iniciado antes de um campo de texto receber foco.
UIS.TextBoxFocused:Connect(function()
    swipeFinger = nil
    swipeOrigin = nil
end)
]==]
revised = revised:sub(1, atStart - 1) .. listener .. revised:sub(atStart)
revised ..= "\n" .. marker .. "\n"
assert(occurrences(revised, newStart) == 1
    and occurrences(revised, oldStart) == 0
    and occurrences(revised, oldEnd) == 1
    and occurrences(revised, "UIS.TextBoxFocused:Connect(function()") == 1,
    "0014: revisao estatica da transformacao")
local enabled = client.Enabled
local ok, err = pcall(function()
    client.Enabled = false
    client.Source = revised
    assert(client.Source:find(marker, 1, true), "0014 postcheck: marcador")
    assert(occurrences(client.Source, newStart) == 1, "0014 postcheck: filtro inicial")
    assert(occurrences(client.Source, "UIS.TextBoxFocused:Connect(function()") == 1,
        "0014 postcheck: cancelamento")
    client.Enabled = enabled
end)
if not ok then
    client.Enabled = false
    local restored, restoreError = pcall(function() client.Source = original end)
    client.Enabled = enabled
    assert(restored, "0014: rollback falhou: " .. tostring(restoreError))
    error("0014: rollback executado: " .. tostring(err))
end
print("[SnakeGame] 0014 aplicado; validar foco durante swipe no Studio.")
