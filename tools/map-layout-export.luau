-- One-shot, read-only map layout export. No remotes, hooks or game modules run.
local players=game:GetService("Players")
local player=players.LocalPlayer
local gui=player:WaitForChild("PlayerGui")
local http=game:GetService("HttpService")
assert(type(writefile)=="function","Oktan: writefile недоступен")
local report={version=1,placeId=game.PlaceId,mapName=workspace:GetAttribute("MapName"),gui={},world={},truncated=false}
local function serial(value)
    local kind=typeof(value)
    if kind=="number" or kind=="boolean" then return value end
    if kind=="string" then return value:sub(1,256) end
    if kind=="Vector2" then return {x=value.X,y=value.Y} end
    if kind=="Vector3" then return {x=value.X,y=value.Y,z=value.Z} end
    if kind=="UDim2" then return {xs=value.X.Scale,xo=value.X.Offset,ys=value.Y.Scale,yo=value.Y.Offset} end
    if kind=="CFrame" then return {value:GetComponents()} end
end
local function attributes(object)
    local result={}
    for name,value in pairs(object:GetAttributes()) do result[name]=serial(value) end
    return result
end
local function visible(object)
    while object and object~=gui do
        if object:IsA("GuiObject") and not object.Visible or object:IsA("ScreenGui") and not object.Enabled then return false end
        object=object.Parent
    end
    return true
end
local roots={}
for _,object in ipairs(gui:GetDescendants()) do
    if object:IsA("GuiObject") and object.Name:lower():find("map",1,true) then
        local ancestor=object; local depth=0
        while ancestor.Parent and ancestor.Parent~=gui and not ancestor.Parent:IsA("ScreenGui") and depth<2 do ancestor=ancestor.Parent; depth+=1 end
        roots[ancestor]=true
    end
end
local seen={}
local function addGui(object)
    if seen[object] then return end; seen[object]=true
    if #report.gui>=1800 then report.truncated=true; return end
    local entry={path=object:GetFullName(),class=object.ClassName,attributes=attributes(object),visible=visible(object)}
    if object:IsA("GuiObject") then
        entry.position=serial(object.Position); entry.size=serial(object.Size); entry.anchor=serial(object.AnchorPoint)
        entry.absolutePosition=serial(object.AbsolutePosition); entry.absoluteSize=serial(object.AbsoluteSize); entry.rotation=object.Rotation
    end
    if object:IsA("ImageLabel") or object:IsA("ImageButton") then
        entry.image=object.Image; entry.rectOffset=serial(object.ImageRectOffset); entry.rectSize=serial(object.ImageRectSize); entry.scaleType=object.ScaleType.Name
    end
    if object:IsA("ScrollingFrame") then entry.canvasPosition=serial(object.CanvasPosition); entry.canvasSize=serial(object.CanvasSize) end
    -- No text/chat contents or key values are collected.
    table.insert(report.gui,entry)
end
for root in pairs(roots) do addGui(root); for _,object in ipairs(root:GetDescendants()) do addGui(object) end end
for _,parent in ipairs({workspace,game:GetService("ReplicatedStorage")}) do
    for _,object in ipairs(parent:GetChildren()) do
        local name=object.Name:lower()
        if name:find("map",1,true) or name:find("bound",1,true) then
            table.insert(report.world,{path=object:GetFullName(),class=object.ClassName,attributes=attributes(object)})
            for _,child in ipairs(object:GetChildren()) do
                if #report.world>=250 then break end
                local value
                if child:IsA("Vector3Value") or child:IsA("Vector2Value") or child:IsA("CFrameValue") or child:IsA("NumberValue") then value=serial(child.Value) end
                table.insert(report.world,{path=child:GetFullName(),class=child.ClassName,attributes=attributes(child),value=value})
            end
        end
    end
end
local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
report.localPosition=root and serial(root.Position)
writefile("Oktan-map-layout.json",http:JSONEncode(report))
warn("Oktan: карта сохранена в Oktan-map-layout.json; найдено UI-объектов: "..#report.gui)
