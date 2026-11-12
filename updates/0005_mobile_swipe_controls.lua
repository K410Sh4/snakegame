-- SnakeGame 0005 | comandos por gesto no mobile
-- Execute na Barra de Comandos do Roblox Studio (Edit) apos 0001-0004.
-- Modifica somente SnakeGameClient. Reaplicacao e segura e nao sobrescreve edicoes desconhecidas.
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SSS = game:GetService("ServerScriptService")
local client = SPS:FindFirstChild("SnakeGameClient")
local server = SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript"), "0005: cliente ausente")
assert(server and server:IsA("Script"), "0005: servidor ausente")
local previous = client.Source
local marker = "-- SnakeGame 0005 applied"
if previous:find(marker, 1, true) then
    print("[SnakeGame] 0005 ja aplicado")
    return
end
assert(previous:find("-- SnakeGame 0004 applied", 1, true), "0005: execute 0004 antes")
assert(server.Source:find("-- SnakeGame 0003 applied", 1, true), "0005: servidor 0003 ausente")
local function replaceExactlyOnce(source, needle, replacement, label)
    local at = source:find(needle, 1, true)
    assert(at, "0005 precheck: trecho ausente: "..label)
    assert(not source:find(needle, at + #needle, true), "0005 precheck: trecho duplicado: "..label)
    return source:sub(1, at - 1)..replacement..source:sub(at + #needle)
end
local newer = replaceExactlyOnce(previous,
    'hint.Text=(s.alive==false) and "FIM DE JOGO" or "WASD / SETAS  •  TOQUE PARA VIRAR"',
    'hint.Text=(s.alive==false) and "FIM DE JOGO" or (UIS.TouchEnabled and "DESLIZE OU USE SETAS" or "WASD / SETAS")',
    "hint do estado")
newer = newer .. [==[

-- SnakeGame 0005 applied
-- Botao virtual so ocupa espaco em dispositivos que aceitam toque.
for _,button in ipairs(buttons) do
    button.Visible = UIS.TouchEnabled
end
hint.Text = UIS.TouchEnabled and "DESLIZE OU USE SETAS" or "WASD / SETAS"

-- O Roblox informa quando a interacao ja foi processada pela interface.
-- Rastreia no maximo um gesto de cada vez para evitar direcoes simultaneas.
local swipeFinger = nil
local swipeOrigin = nil
local SWIPE_THRESHOLD = 40
UIS.TouchStarted:Connect(function(input, processed)
    if processed or swipeFinger ~= nil then return end
    swipeFinger = input
    swipeOrigin = input.Position
end)
UIS.TouchEnded:Connect(function(input, processed)
    if input ~= swipeFinger then return end
    local origin = swipeOrigin
    swipeFinger = nil
    swipeOrigin = nil
    if processed or origin == nil then return end
    local delta = input.Position - origin
    local dx, dy = delta.X, delta.Y
    if math.max(math.abs(dx), math.abs(dy)) < SWIPE_THRESHOLD then return end
    local direction
    if math.abs(dx) >= math.abs(dy) then
        direction = dx > 0 and "Right" or "Left"
    else
        direction = dy > 0 and "Down" or "Up"
    end
    turn:FireServer(direction)
end)
]==]
local wasEnabled = client.Enabled
local ok, err = pcall(function()
    client.Enabled = false
    client.Source = newer
    assert(client.Source:find(marker, 1, true), "0005 postcheck: marker ausente")
    assert(client.Source:find("UIS.TouchEnded:Connect", 1, true), "0005 postcheck: gesto ausente")
    assert(client.Source:find("SWIPE_THRESHOLD = 40", 1, true), "0005 postcheck: limite ausente")
    client.Enabled = wasEnabled
end)
if not ok then
    client.Enabled = false
    client.Source = previous
    client.Enabled = wasEnabled
    error("SnakeGame 0005 rollback: "..tostring(err))
end
print("[SnakeGame] 0005 instalado: gestos por deslize e HUD contextual PC/mobile.")
