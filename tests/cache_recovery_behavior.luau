-- Deterministic behavioral harness for the EXACT installed server paint(s) function.
-- CI extracts paint(s) from the mock-installed Script.Source (0001-0019).
-- Not Roblox Studio: this checks cache lifecycle with lightweight fake Instances.
local created=0
local function node(kind)
    local obj={ClassName=kind,Name="",Parent=nil,Destroyed=false}
    function obj:Destroy()
        self.Parent=nil
        self.Destroyed=true
    end
    return obj
end
local Instance={new=function(kind) return node(kind) end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local Enum={Material={Neon="Neon",SmoothPlastic="SmoothPlastic"},PartType={Ball="Ball"}}
local skinPalettes={Classic={head="head",body="body"}}
local function makePart(parent,name,size,color,material)
    created+=1
    local p=node("Part")
    p.Name=name
    p.Parent=parent
    p.Size=size
    p.Color=color
    p.Material=material
    return p
end
local function point(v,origin) return {v=v,origin=origin} end

-- Extracted paint(s) is inserted here by the workflow.

local model=node("Model")
local s={model=model,body={{1,1},{2,1},{3,1}},food={4,4},origin=0,skin="Classic"}
paint(s)
assert(created==4,"initial paint should create three segments and food")
local segments=s.segments
assert(segments and segments.Parent==model,"segment folder not created")
local first=s.segmentParts[1]
local food=s.foodPart
for i=1,10 do
    -- Remove a cached segment and cached food without changing the session.
    first:Destroy()
    food:Destroy()
    assert(first.Parent==nil and food.Parent==nil,"test setup failed")
    paint(s)
    assert(s.segmentParts[1]~=first and s.segmentParts[1].Parent==segments,
        "segment cache failed to recover on iteration "..i)
    assert(s.foodPart~=food and s.foodPart.Parent==model,
        "food cache failed to recover on iteration "..i)
    first=s.segmentParts[1]
    food=s.foodPart
end
assert(created==24,"expected 4 initial + 20 recovered parts")
local count=created
paint(s)
assert(created==count,"stable cache should not create extra parts")
-- Shrinking the body must release surplus cached segments.
s.body={{1,1},{2,1}}
paint(s)
assert(s.segmentParts[3]==nil,"stale third segment after shrink")
assert(created==count,"shrinking body should not create new parts")
s.food=nil
paint(s)
assert(s.foodPart==nil,"food cache not cleared when food removed")
s.food={5,5}
paint(s)
assert(s.foodPart and s.foodPart.Parent==model,"food not recreated after nil")
assert(created==count+1,"food recreation should create one part")
print("[CacheBehavior] PASS: ten destructive recoveries, stable reuse, shrink, food lifecycle")

-- Regression: losing the entire Segments folder must invalidate every cached part.
-- The fake Instance model does not cascade Destroy() to children; this test checks
-- cache ownership and reconstruction, not Roblox engine destruction semantics.
s.body={{1,1},{2,1},{3,1}}
paint(s)
local oldFolder=s.segments
local oldParts={s.segmentParts[1],s.segmentParts[2],s.segmentParts[3]}
local beforeFolderRecovery=created
oldFolder:Destroy()
paint(s)
assert(s.segments~=oldFolder and s.segments.Parent==model,
    "destroyed Segments folder was not replaced")
assert(#s.segmentParts==3 and created==beforeFolderRecovery+3,
    "folder loss should recreate exactly three cached parts")
for i=1,3 do
    assert(s.segmentParts[i]~=oldParts[i] and s.segmentParts[i].Parent==s.segments,
        "old cached segment reused after folder loss: "..i)
end
local stableAfterFolder=created
paint(s)
assert(created==stableAfterFolder,"folder recovery leaked parts on stable repaint")

-- Characterization: external reparenting is NOT destruction.
-- Do not silently destroy an object another script may have taken ownership of.
local quarantine=node("Folder")
local movedFolder=s.segments
local movedParts={s.segmentParts[1],s.segmentParts[2],s.segmentParts[3]}
movedFolder.Parent=quarantine
local beforeMoveRecovery=created
paint(s)
assert(s.segments~=movedFolder and s.segments.Parent==model,
    "reparented Segments folder was not replaced")
assert(#s.segmentParts==3 and created==beforeMoveRecovery+3,
    "reparenting should create exactly three replacement segments")
for i=1,3 do
    assert(s.segmentParts[i]~=movedParts[i] and s.segmentParts[i].Parent==s.segments,
        "reparented segment reused: "..i)
    assert(movedParts[i].Parent==movedFolder and not movedParts[i].Destroyed,
        "mock changed ownership of externally moved parts: "..i)
end
assert(movedFolder.Parent==quarantine and not movedFolder.Destroyed,
    "reparented folder was destroyed or moved without an ownership policy")
local afterMoveRecovery=created
paint(s)
assert(created==afterMoveRecovery,"reparent recovery leaked parts on stable repaint")
print("[CacheBehavior] PASS: destroyed folder rebuild, moved folder characterization")
