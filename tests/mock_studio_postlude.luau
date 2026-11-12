
-- Assert the outcome of the consecutive 0001-0018 patch INSTALLERS.
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local SG = game:GetService("StarterGui")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local server = SSS:FindFirstChild("SnakeGameServer")
local client = SPS:FindFirstChild("SnakeGameClient")
assert(server and client and server.Source and client.Source, "Scripts were not installed")
assert(RS:FindFirstChild("SnakeGame"), "Remote folder missing")
assert(WS:FindFirstChild("SnakeGameArena"), "Arena missing")
for i = 2, 18 do
    local marker = string.format("-- SnakeGame %04d applied", i)
    assert(
        server.Source:find(marker,1,true) or client.Source:find(marker,1,true),
        "Patch marker missing in installed scripts: " .. marker
    )
end
assert(server.Source:find("local hasModeHandler = true",1,true), "Mode handler not enabled")
assert(server.Source:find("won=s.won==true",1,true), "Victory state lost")
assert(server.Source:find("skinCommands[command]",1,true), "Skin whitelist lost")
assert(server.Source:find("segmentParts[i]=p",1,true), "Server render cache missing")
assert(client.Source:find("camera.Focus=CFrame.new(target)",1,true), "Camera focus missing")
assert(client.Source:find("UIS.WindowFocusReleased:Connect",1,true), "Mobile focus reset missing")
assert(SG:FindFirstChild("SnakeGameModeSelect"), "Mode selector missing")
assert(SG:FindFirstChild("SnakeGameHUD"), "HUD template missing")
assert(SG:FindFirstChild("SnakeGameSkinSelect"), "Skin selector missing")
print("[MockStudio] PASS: consecutive installers 0001-0018 and final postchecks")
