-- SnakeGame 0005 | HUD editavel pelo Explorer / controles mobile
-- Execute na Barra de Comandos do Roblox Studio, no modo Edit, apos 0001-0004.
-- Criacao transacional do template StarterGui e migracao do cliente.
-- Referencias tecnicas verificadas em 12/11/2026:
-- https://create.roblox.com/docs/ui/on-screen-containers
-- https://create.roblox.com/docs/ui/position-and-size
-- https://create.roblox.com/docs/reference/engine/classes/GuiObject

local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

assert(not RunService:IsRunning(), "0005: execute em modo Edit, fora de Play/Run")
local client = SPS:FindFirstChild("SnakeGameClient")
local server = SSS:FindFirstChild("SnakeGameServer")
assert(client and client:IsA("LocalScript"), "0005: cliente SnakeGame nao encontrado")
assert(server and server:IsA("Script"), "0005: servidor SnakeGame nao encontrado")
local oldSource = client.Source
local marker = "-- SnakeGame 0005 applied"
local existing = StarterGui:FindFirstChild("SnakeGameHUD")
if oldSource:find(marker, 1, true) then
    assert(existing and existing:IsA("ScreenGui") and existing:GetAttribute("SnakeGameUpdate") == 5,
        "0005: fonte marcada, mas template do HUD ausente/invalido")
    print("[SnakeGame] 0005 ja instalado; preservando layout editado no Explorer")
    return
end
assert(not existing, "0005: StarterGui.SnakeGameHUD ja existe; nao sobrescrever configuracao")
for _,tag in ipairs({"-- SnakeGame 0002 applied", "-- SnakeGame 0003 applied", "-- SnakeGame 0004 applied"}) do
    assert(oldSource:find(tag, 1, true), "0005: cliente precisa do patch "..tag)
end
assert(server.Source:find("-- SnakeGame 0003 applied", 1, true), "0005: servidor precisa do patch 0003")

local first = 'local gui=Instance.new("ScreenGui")\n'
local after = 'local keys={\n'
local beginAt = oldSource:find(first, 1, true)
local afterAt = oldSource:find(after, 1, true)
assert(beginAt and afterAt and beginAt < afterAt, "0005: bloco antigo da interface nao reconhecido")
assert(not oldSource:find(first, beginAt + #first, true), "0005: bloco UI duplicado")
assert(not oldSource:find(after, afterAt + #after, true), "0005: tabela de teclas duplicada")
local newBindings = [==[
-- HUD definido em StarterGui; propriedades visuais pertencem ao Explorer.
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SnakeGameHUD")
local score = gui:WaitForChild("Score")
local hint = gui:WaitForChild("Hint")
local retry = gui:WaitForChild("Retry")
local controls = gui:WaitForChild("Controls")
controls.Visible = UIS.TouchEnabled
retry.Activated:Connect(function() turn:FireServer("Restart") end)
for _,direction in ipairs({"Up", "Left", "Down", "Right"}) do
    local button = controls:WaitForChild(direction)
    button.Activated:Connect(function() turn:FireServer(direction) end)
end
]==]
local updated = oldSource:sub(1, beginAt - 1) .. newBindings .. oldSource:sub(afterAt) .. "\n" .. marker .. "\n"
assert(updated:find("gui:WaitForChild(\"Score\")", 1, true), "0005: bindings invalidos")
assert(not updated:find(first, 1, true), "0005: antigo construtor ainda presente")

local template = Instance.new("ScreenGui")
template.Name = "SnakeGameHUD"
template.ResetOnSpawn = false
template.IgnoreGuiInset = false
template.DisplayOrder = 6
template.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
template:SetAttribute("SnakeGameUpdate", 5)

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end
local function stroke(parent, color, transparency, thickness)
    local line = Instance.new("UIStroke")
    line.Color = color
    line.Transparency = transparency
    line.Thickness = thickness
    line.Parent = parent
end
local function textLimit(parent, low, high)
    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = low
    constraint.MaxTextSize = high
    constraint.Parent = parent
end
local function sizeLimit(parent, minimum, maximum)
    local constraint = Instance.new("UISizeConstraint")
    constraint.MinSize = minimum
    constraint.MaxSize = maximum
    constraint.Parent = parent
end
local function addLabel(name, caption)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Text = caption
    item.Font = Enum.Font.GothamBold
    item.TextScaled = true
    item.TextColor3 = Color3.fromRGB(229, 255, 246)
    item.BorderSizePixel = 0
    item.AnchorPoint = Vector2.new(0.5, 0)
    item.Parent = template
    return item
end
local score = addLabel("Score", "PONTOS  0")
score.Position = UDim2.new(0.5, 0, 0, 14)
score.Size = UDim2.new(0.42, 0, 0, 52)
score.BackgroundColor3 = Color3.fromRGB(13, 43, 45)
score.BackgroundTransparency = 0.08
round(score, 15)
stroke(score, Color3.fromRGB(28, 195, 161), 0.22, 1.5)
textLimit(score, 14, 30)
sizeLimit(score, Vector2.new(144, 44), Vector2.new(350, 56))

local hint = addLabel("Hint", "WASD / SETAS  •  TOQUE PARA VIRAR")
hint.Position = UDim2.new(0.5, 0, 0, 74)
hint.Size = UDim2.new(0.82, 0, 0, 28)
hint.BackgroundTransparency = 1
hint.TextTransparency = 0.12
textLimit(hint, 10, 18)
sizeLimit(hint, Vector2.new(190, 24), Vector2.new(490, 30))

local retry = Instance.new("TextButton")
retry.Name = "Retry"
retry.Text = "RECOMEÇAR"
retry.Font = Enum.Font.GothamBold
retry.TextScaled = true
retry.TextColor3 = Color3.fromRGB(9, 32, 31)
retry.BackgroundColor3 = Color3.fromRGB(28, 195, 161)
retry.BorderSizePixel = 0
retry.AnchorPoint = Vector2.new(0.5, 0.5)
retry.Position = UDim2.fromScale(0.5, 0.5)
retry.Size = UDim2.new(0.43, 0, 0, 54)
retry.Visible = false
retry.Parent = template
round(retry, 14)
textLimit(retry, 14, 24)
sizeLimit(retry, Vector2.new(155, 48), Vector2.new(300, 60))

-- Controles movidos para um container independente do HUD de teclado.
-- Posicionados acima da zona inferior reservada para os controles padrao Roblox.
local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.AnchorPoint = Vector2.new(1, 1)
controls.Position = UDim2.new(1, -16, 0.79, 0)
controls.Size = UDim2.fromOffset(184, 164)
controls.BackgroundTransparency = 1
controls.Visible = true -- Cliente alterna visibilidade conforme TouchEnabled.
controls.Parent = template

for _,definition in ipairs({
    {"Up", "↑", 0.50, 0.20},
    {"Left", "←", 0.18, 0.62},
    {"Down", "↓", 0.50, 0.62},
    {"Right", "→", 0.82, 0.62},
}) do
    local button = Instance.new("TextButton")
    button.Name = definition[1]
    button.Text = definition[2]
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.TextColor3 = Color3.fromRGB(234, 255, 242)
    button.BackgroundColor3 = Color3.fromRGB(23, 82, 79)
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = UDim2.fromScale(definition[3], definition[4])
    button.Size = UDim2.fromOffset(54, 54)
    button.Parent = controls
    round(button, 12)
    stroke(button, Color3.fromRGB(28, 195, 161), 0.45, 1)
    textLimit(button, 20, 32)
end

local wasEnabled = client.Enabled
local success, failure = pcall(function()
    client.Enabled = false
    client.Source = updated
    template.Parent = StarterGui
    assert(StarterGui:FindFirstChild("SnakeGameHUD") == template, "0005: template ausente")
    assert(template:FindFirstChild("Score") and template:FindFirstChild("Hint") and template:FindFirstChild("Retry"), "0005: HUD incompleto")
    for _,direction in ipairs({"Up", "Left", "Down", "Right"}) do
        assert(controls:FindFirstChild(direction), "0005: controle ausente: "..direction)
    end
    assert(client.Source:find(marker, 1, true), "0005: fonte nao persistida")
    client.Enabled = wasEnabled
end)
if not success then
    client.Enabled = false
    pcall(function() client.Source = oldSource end)
    template:Destroy()
    client.Enabled = wasEnabled
    error("SnakeGame 0005 rollback: "..tostring(failure))
end
print("[SnakeGame] 0005 instalado. HUD editavel em StarterGui > SnakeGameHUD; valide PC/mobile no Play Test.")
