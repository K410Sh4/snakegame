-- Minimal mock of Studio objects used by the INSTALLERS, not Roblox gameplay.
-- Executing concatenated patches tests Source anchor replacement and postchecks.
local function newObject(className)
    local object = {
        _class = className,
        _props = { Name = className, Enabled = true },
        _children = {},
        _attrs = {},
    }
    local methods = {}
    function methods:IsA(name)
        return self._class == name or (name == "Instance")
    end
    function methods:FindFirstChild(name)
        for _, child in ipairs(self._children) do
            if child.Name == name then return child end
        end
        return nil
    end
    function methods:WaitForChild(name)
        local child = self:FindFirstChild(name)
        assert(child ~= nil, "Mock WaitForChild missing: " .. tostring(name))
        return child
    end
    function methods:GetChildren()
        local copy = {}
        for i, child in ipairs(self._children) do copy[i] = child end
        return copy
    end
    function methods:SetAttribute(name, value)
        self._attrs[name] = value
    end
    function methods:GetAttribute(name)
        return self._attrs[name]
    end
    function methods:Destroy()
        self.Parent = nil
        for _, child in ipairs(self:GetChildren()) do child:Destroy() end
    end
    function methods:IsRunning()
        return false
    end
    return setmetatable(object, {
        __index = function(self, key)
            if methods[key] then return methods[key] end
            return self._props[key]
        end,
        __newindex = function(self, key, value)
            if key == "Parent" then
                local old = self._props.Parent
                if old then
                    for i = #old._children, 1, -1 do
                        if old._children[i] == self then
                            table.remove(old._children, i)
                            break
                        end
                    end
                end
                self._props.Parent = value
                if value then table.insert(value._children, self) end
            else
                self._props[key] = value
            end
        end,
    })
end

Instance = {
    new = function(className, parent)
        local obj = newObject(className)
        if parent then obj.Parent = parent end
        return obj
    end,
}
local serviceNames = {
    "ReplicatedStorage",
    "ServerScriptService",
    "StarterPlayer",
    "Workspace",
    "RunService",
    "StarterGui",
}
local services = {}
for _, name in ipairs(serviceNames) do
    services[name] = newObject(name)
end
Instance.new("Folder", services.StarterPlayer).Name = "StarterPlayerScripts"
game = {
    GetService = function(_, name)
        local result = services[name]
        assert(result ~= nil, "Unknown service: " .. tostring(name))
        return result
    end,
}
workspace = services.Workspace
local function constructXYZ(x,y,z)
    return { X=x or 0, Y=y or 0, Z=z or 0 }
end
Vector2 = { new = function(x,y) return constructXYZ(x,y,0) end }
Vector3 = { new = constructXYZ }
Color3 = { fromRGB = function(r,g,b) return {R=r,G=g,B=b} end }
UDim2 = {
    new = function(...) return {...} end,
    fromScale = function(...) return {...} end,
    fromOffset = function(...) return {...} end,
}
UDim = { new = function(...) return {...} end }
CFrame = {
    new = function(...) return {...} end,
    lookAt = function(...) return {...} end,
    Angles = function(...) return {...} end,
}
Enum = setmetatable({}, {
    __index = function(_, group)
        return setmetatable({}, {__index = function(_, member)
            return group .. "." .. member
        end})
    end,
})
print("[MockStudio] Installer sequence started")
