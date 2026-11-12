-- SnakeGame 0003 | independent Solo arenas, requires 0002
local ss=game:GetService("ServerScriptService"):FindFirstChild("SnakeGameServer")
local cs=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):FindFirstChild("SnakeGameClient")
assert(ss and cs,"0003 requires installed scripts")
local a,b=ss.Source,cs.Source
local tag="-- SnakeGame 0003 applied"
if a:find(tag,1,true) and b:find(tag,1,true) then print("0003 already applied");return end
assert(not a:find(tag,1,true) and not b:find(tag,1,true),"0003 partial install")
assert(a:find("-- SnakeGame 0002 applied",1,true) and b:find("-- SnakeGame 0002 applied",1,true),"Apply 0002 first")
local function sub(s,old,new,label)
 local i=s:find(old,1,true)
 assert(i and not s:find(old,i+#old,true),"0003 precheck "..label)
 return s:sub(1,i-1)..new..s:sub(i+#old)
end
local n=a
n=sub(n,"local sessions = {}",[==[local sessions = {}
local slots={}
local function reserve(player)
 local i=0
 while slots[i] do i+=1 end
 slots[i]=player
 return i
end]==],"slots")
n=sub(n,"local function point(v) return Vector3.new((v.X-(SIZE-1)/2)*CELL, 3, (v.Y-(SIZE-1)/2)*CELL) end","local function point(v,origin) return Vector3.new(origin+(v.X-(SIZE-1)/2)*CELL,3,(v.Y-(SIZE-1)/2)*CELL) end","point")
n=sub(n,"p.Position=point(v)","p.Position=point(v,s.origin)","body")
n=sub(n,"food.Position=point(s.food)","food.Position=point(s.food,s.origin)","food")
n=sub(n,[==[local model=Instance.new("Model"); model.Name="Snake_"..player.UserId; model.Parent=arena]==],[==[local slot=old and old.slot or reserve(player)
    local origin=slot*96
    local model=Instance.new("Model")
    model.Name="Snake_"..player.UserId
    model:SetAttribute("ArenaX",origin)
    if slot~=0 then
        local terrain=Instance.new("Model"); terrain.Name="Terrain"; terrain.Parent=model
        for _,piece in ipairs(arena:GetChildren()) do
            if piece:IsA("BasePart") then
                local copy=piece:Clone()
                copy.Position=piece.Position+Vector3.new(origin,0,0)
                copy.Parent=terrain
            end
        end
    end
    model.Parent=arena]==],"reset model")
n=sub(n,"alive=true,model=model,lastInput=0}","alive=true,model=model,lastInput=0,slot=slot,origin=origin}","session")
n=sub(n,"local s=sessions[p]; if s and s.model then s.model:Destroy() end; sessions[p]=nil","local s=sessions[p]; if s and s.model then s.model:Destroy() end; if s then slots[s.slot]=nil end; sessions[p]=nil","cleanup")
local m=sub(b,"camera.CFrame=CFrame.lookAt(Vector3.new(0,90,65),Vector3.new(0,0,0))",[==[local root=workspace:FindFirstChild("SnakeGameArena")
        local own=root and root:FindFirstChild("Snake_"..tostring(player.UserId))
        local x=own and own:GetAttribute("ArenaX") or 0
        if typeof(x)~="number" then x=0 end
        camera.CFrame=CFrame.lookAt(Vector3.new(x,90,65),Vector3.new(x,0,0))]==],"camera")
m=m..[==[
-- SnakeGame 0003 applied
local function watchOwn(model)
 if model.Name~="Snake_"..tostring(player.UserId) then return end
 setCamera()
 model:GetAttributeChangedSignal("ArenaX"):Connect(setCamera)
end
for _,model in ipairs(arena:GetChildren()) do watchOwn(model) end
arena.ChildAdded:Connect(watchOwn)
]==]
n=n.."\n"..tag
local es,ec=ss.Enabled,cs.Enabled
local ok,err=pcall(function()
 ss.Enabled=false;cs.Enabled=false
 ss.Source=n;cs.Source=m
 assert(ss.Source:find(tag,1,true) and cs.Source:find(tag,1,true),"0003 postcheck")
 ss.Enabled=es;cs.Enabled=ec
end)
if not ok then
 ss.Enabled=false;cs.Enabled=false
 ss.Source=a;cs.Source=b
 ss.Enabled=es;cs.Enabled=ec
 error("0003 rollback: "..tostring(err))
end
print("[SnakeGame] 0003 installed; verify two-player Play Test")
