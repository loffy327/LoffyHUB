local PremiumLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/loffy327/Mainscript/refs/heads/main/Lib2.lua"
))()

local Window = PremiumLib:CreateWindow({
    Title        = "Loffy Hub - Make HotSauce [Beta] ",
    TutorialMode = false,
    AccentColor  = Color3.fromRGB(99, 102, 241),
})

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Complete seed list
local SeedOptions = {
    "Eclipse Seed", "Lunar Seed", "Meteor Seed", "Dark Matter Seed", 
    "Nebula Seed", "Deadly Seed", "Surge Seed", "Wildfire Seed", 
    "Inferno Seed", "Secret Seed", "Liberty Seed", "Unholy Seed", 
    "Painful Seed", "Tame Seed", "Spicy Seed"
}

local SelectedSeeds = {}
for _, seedName in ipairs(SeedOptions) do
    SelectedSeeds[seedName] = false
end

local SeedMachineFolder = workspace:WaitForChild("PlayerLots"):WaitForChild(LocalPlayer.Name):WaitForChild("Important"):WaitForChild("SeedMachine") 
local RollEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SeedMachine"):WaitForChild("SpawnSeed")
local BuyEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SeedMachine"):WaitForChild("PickupSeed")

local function checkAndBuySeed(Item)
    if Item:IsA("Model") then
        local actualSeedName = Item:GetAttribute("SeedName") or Item:GetAttribute("ItemType") or Item.Name
        if SelectedSeeds[actualSeedName] == true or SelectedSeeds[Item.Name] == true then
            BuyEvent:FireServer()
        end
    end
end

local function isPepperInMyPlot(object)
    local path = object:GetFullName()
    if string.find(path, LocalPlayer.Name) or string.find(path, tostring(LocalPlayer.UserId)) then
        return true
    end
    
    local current = object.Parent
    while current and current ~= workspace do
        if string.find(string.lower(current.Name), "garden") or string.find(string.lower(current.Name), "plot") or string.find(string.lower(current.Name), "crop") then
            if string.find(current.Name, LocalPlayer.Name) then
                return true
            end
        end
        current = current.Parent
    end
    return false
end

-- ==================== MAIN TAB ====================
local Tab = Window:CreateTab({ Name = "Main", Icon = "⚡" })
Tab:CreateSection("Automation Controls")

-- 1. Auto Roll Seed Toggle
_G.AutoRollSeed = false
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Camera lock state
local lockedCFrame = nil
local initialLockedCFrame = nil
local lockedFocusPos = nil
local lockedFOV = nil
local zoomConnection = nil
local disabledConnections = {}

Tab:CreateToggle({ 
    Name = "Auto Roll Seed", 
    Callback = function(Value) 
        _G.AutoRollSeed = Value
        
        if _G.AutoRollSeed then
            -- === SAVE CAMERA STATE ===
            local cam = workspace.CurrentCamera
            lockedCFrame = cam.CFrame
            initialLockedCFrame = cam.CFrame
            lockedFocusPos = cam.Focus.Position
            lockedFOV = cam.FieldOfView
            
            -- ============================================================
            -- METHOD: Kill the animation at its SOURCE using getconnections
            -- Instead of fighting camera changes, we PREVENT them from happening
            -- by disabling the game's event handlers that trigger the animation
            -- ============================================================
            disabledConnections = {}
            
            -- Disable all OnClientEvent handlers on the SpawnSeed remote
            pcall(function()
                for _, conn in pairs(getconnections(RollEvent.OnClientEvent)) do
                    conn:Disable()
                    table.insert(disabledConnections, conn)
                end
            end)
            
            -- Also try to find and disable camera-related BindToRenderStep/RenderStepped
            pcall(function()
                for _, conn in pairs(getconnections(cam:GetPropertyChangedSignal("CFrame"))) do
                    conn:Disable()
                    table.insert(disabledConnections, conn)
                end
            end)
            pcall(function()
                for _, conn in pairs(getconnections(cam:GetPropertyChangedSignal("CameraType"))) do
                    conn:Disable()
                    table.insert(disabledConnections, conn)
                end
            end)
            
            -- Set camera to Scriptable
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CameraSubject = nil
            
            -- Tight render loop: lock CFrame + FOV every single frame
            task.spawn(function()
                while _G.AutoRollSeed do
                    local c = workspace.CurrentCamera
                    if lockedCFrame then
                        c.CFrame = lockedCFrame
                        c.FieldOfView = lockedFOV
                        c.CameraType = Enum.CameraType.Scriptable
                    end
                    RunService.RenderStepped:Wait()
                end
                -- Restore when loop ends
                local c = workspace.CurrentCamera
                c.CameraType = Enum.CameraType.Custom
                if initialLockedCFrame then
                    c.CFrame = initialLockedCFrame
                end
                c.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                c.FieldOfView = 70
            end)
            
            -- Allow user to zoom in/out with mouse wheel
            if zoomConnection then zoomConnection:Disconnect() end
            zoomConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
                if not _G.AutoRollSeed or not lockedCFrame or not lockedFocusPos then return end
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    local direction = (lockedCFrame.Position - lockedFocusPos).Unit
                    local currentDist = (lockedCFrame.Position - lockedFocusPos).Magnitude
                    local zoomDelta = input.Position.Z * 3
                    local newDist = math.clamp(currentDist - zoomDelta, 2, 200)
                    local newPos = lockedFocusPos + direction * newDist
                    
                    local rotation = lockedCFrame - lockedCFrame.Position
                    lockedCFrame = rotation + newPos
                end
            end)
            
            -- Auto roll loop
            task.spawn(function()
                while _G.AutoRollSeed do
                    RollEvent:FireServer()
                    task.wait(0.05)
                end
            end)
        else
            -- === UNLOCK ===
            -- Re-enable all disabled game connections
            for _, conn in pairs(disabledConnections) do
                pcall(function() conn:Enable() end)
            end
            disabledConnections = {}
            
            -- Disconnect zoom
            if zoomConnection then
                zoomConnection:Disconnect()
                zoomConnection = nil
            end
            
            -- Note: c.CFrame is restored in the while loop task.spawn above
            
            lockedCFrame = nil
            lockedFocusPos = nil
            lockedFOV = nil
            -- Don't set initialLockedCFrame = nil yet because the render loop might need it right after this runs
            task.delay(0.1, function() initialLockedCFrame = nil end)
        end
    end 
})

-- 2. Auto Buy Toggle
_G.AutoBuySeed = false
local BuyConnection = nil

Tab:CreateToggle({
    Name = "Auto Buy Filtered",
    Callback = function(Value)
        _G.AutoBuySeed = Value
        
        if _G.AutoBuySeed then
            if BuyConnection then BuyConnection:Disconnect() end
            
            BuyConnection = SeedMachineFolder.ChildAdded:Connect(function(Item)
                if _G.AutoBuySeed then
                    checkAndBuySeed(Item)
                end
            end)
            
            task.spawn(function()
                for _, Item in ipairs(SeedMachineFolder:GetChildren()) do
                    if not _G.AutoBuySeed then break end
                    checkAndBuySeed(Item)
                end
            end)
        else
            if BuyConnection then
                BuyConnection:Disconnect()
                BuyConnection = nil
            end
        end
    end
})

-- 3. Auto Pick Up
_G.AutoPickPepper = false
Tab:CreateToggle({
    Name = "Auto Pick Up",
    Callback = function(Value)
        _G.AutoPickPepper = Value
        if _G.AutoPickPepper then
            task.spawn(function()
                local PickEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Pepper"):WaitForChild("PickupPepper")
                
                while _G.AutoPickPepper do
                    local peppersFound = 0
                    
                    for _, Object in ipairs(workspace:GetDescendants()) do
                        if not _G.AutoPickPepper then break end
                        
                        if string.lower(Object.Name) == "pepper" and (Object:IsA("Model") or Object:IsA("BasePart")) then
                            if isPepperInMyPlot(Object) then
                                peppersFound = peppersFound + 1
                                
                                task.spawn(function()
                                    PickEvent:InvokeServer(Object)
                                end)
                                
                                task.wait(0.05)
                            end
                        end
                    end
                    
                    if peppersFound == 0 then
                        task.wait(0.05)
                    else
                        task.wait(0.05)
                    end
                end
            end)
        end
    end
})

Tab:CreateSection("--- Seed Filters ---")
for _, seedName in ipairs(SeedOptions) do
    Tab:CreateToggle({
        Name = seedName,
        Callback = function(Value)
            SelectedSeeds[seedName] = Value
        end
    })
end

-- ==================== BREWING TAB ====================
local BrewTab = Window:CreateTab({ Name = "Brewing", Icon = "🧪" })
BrewTab:CreateSection("Brewing Automation")

local PepperAmount = 1
_G.AutoAddPepper = false
_G.AutoClaimSauce = true

-- === Mutation Setup ===
-- Load available mutations from ReplicatedStorage.Assets.Mutations
local MutationsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Mutations")
local MutationOptions = {} -- List of mutation names (e.g. "Solar", "Lunar", ...)
local SelectedMutations = {} -- Filter: which mutations are allowed

for _, mutation in ipairs(MutationsFolder:GetChildren()) do
    table.insert(MutationOptions, mutation.Name)
    SelectedMutations[mutation.Name] = true -- All enabled by default
end
-- "None" represents peppers with no mutation
SelectedMutations["None"] = true

-- Detect the mutation of a pepper tool in the backpack
local function GetPepperMutation(Item)
    -- Method 1: Check common attribute names
    for _, attrName in ipairs({"Mutation", "MutationName", "Variant", "MutationType", "Line"}) do
        local val = Item:GetAttribute(attrName)
        if val and typeof(val) == "string" and val ~= "" then
            return val
        end
    end
    
    -- Method 2: Check StringValue children
    for _, child in ipairs(Item:GetChildren()) do
        if child:IsA("StringValue") then
            if string.find(string.lower(child.Name), "mutation") or string.find(string.lower(child.Name), "variant") or string.find(string.lower(child.Name), "line") then
                if child.Value ~= "" then
                    return child.Value
                end
            end
        end
    end
    
    -- Method 3: Check Handle's children for mutation info
    local Handle = Item:FindFirstChild("Handle")
    if Handle then
        for _, child in ipairs(Handle:GetChildren()) do
            if child:IsA("StringValue") and child.Value ~= "" then
                -- Check if this value matches any known mutation
                for _, mutRef in ipairs(MutationsFolder:GetChildren()) do
                    if child.Value == mutRef.Name then
                        return child.Value
                    end
                end
            end
        end
    end
    
    -- Method 4: Check ALL attributes for values matching known mutation names
    pcall(function()
        local attrs = Item:GetAttributes()
        for _, attrValue in pairs(attrs) do
            if typeof(attrValue) == "string" and attrValue ~= "" then
                for _, mutRef in ipairs(MutationsFolder:GetChildren()) do
                    if attrValue == mutRef.Name then
                        return attrValue
                    end
                end
            end
        end
    end)
    
    -- Method 5: Check item name for known mutation names
    for _, mutRef in ipairs(MutationsFolder:GetChildren()) do
        if string.find(Item.Name, mutRef.Name) then
            return mutRef.Name
        end
    end
    
    return nil
end

-- Get the heat level of a pepper tool using multiple detection methods
local function GetPepperHeat(Item)
    -- Method 1: Check attributes (most reliable)
    for _, attrName in ipairs({"Heat", "HeatLevel", "SHU", "PepperHeat", "Scoville"}) do
        local val = Item:GetAttribute(attrName)
        if val and tonumber(val) then
            return tonumber(val)
        end
    end
    
    -- Method 2: Check for NumberValue / IntValue children named Heat
    for _, child in ipairs(Item:GetChildren()) do
        if (child:IsA("NumberValue") or child:IsA("IntValue")) then
            if string.find(string.lower(child.Name), "heat") or string.find(string.lower(child.Name), "shu") then
                return child.Value
            end
        end
    end
    
    -- Method 3: Search ALL descendant TextLabels for heat text
    for _, desc in ipairs(Item:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local text = desc.Text or ""
            local numStr = string.gsub(text, ",", "")
            local num, suffix = string.match(numStr, "([%d%.]+)([KkMm]?)")
            if num then
                local value = tonumber(num)
                if value then
                    if suffix == "K" or suffix == "k" then
                        value = value * 1000
                    elseif suffix == "M" or suffix == "m" then
                        value = value * 1000000
                    end
                    if value > 0 then
                        return value
                    end
                end
            end
        end
    end
    
    return 0
end

-- Find the base pepper name by matching against ReplicatedStorage.Peppers
local PeppersFolder = ReplicatedStorage:WaitForChild("Peppers")

local function GetBasePepperName(Item)
    -- Direct match
    if PeppersFolder:FindFirstChild(Item.Name) then
        return Item.Name
    end
    
    -- Partial match: check if any pepper name is contained in the item name
    for _, pepperRef in ipairs(PeppersFolder:GetChildren()) do
        if string.find(Item.Name, pepperRef.Name, 1, true) then
            return pepperRef.Name
        end
    end
    
    -- Check "PepperName" or "ItemType" attribute
    local pepperAttr = Item:GetAttribute("PepperName") or Item:GetAttribute("ItemType") or Item:GetAttribute("PepperType")
    if pepperAttr and PeppersFolder:FindFirstChild(pepperAttr) then
        return pepperAttr
    end
    
    return nil
end

-- Collect all peppers from backpack, sort by Heat descending, include mutation info
local function GetSortedPeppers()
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Backpack then return {} end

    local validPeppers = {}

    for _, Item in ipairs(Backpack:GetChildren()) do
        local baseName = GetBasePepperName(Item)
        
        if baseName then
            local currentHeat = GetPepperHeat(Item)
            
            -- Detect mutation line
            local mutation = GetPepperMutation(Item)
            
            -- Fallback: if no mutation found, see if the item name contains extra words
            if not mutation and Item.Name ~= baseName then
                -- Extract whatever is in the item name that IS NOT the base name
                local leftover = string.gsub(Item.Name, baseName, "")
                -- Trim whitespace
                leftover = string.gsub(leftover, "^%s*(.-)%s*$", "%1")
                if leftover ~= "" then
                    -- Special case: ignore generic words if they appear
                    if leftover ~= "Pepper" and leftover ~= "Seed" then
                        mutation = leftover
                    end
                end
            end
            
            local mutationKey = mutation or "None"
            
            -- Check mutation filter (unknown mutations are auto-allowed)
            local allowed = true
            if SelectedMutations[mutationKey] ~= nil then
                -- Known mutation or "None" → respect the toggle
                allowed = SelectedMutations[mutationKey]
            end
            -- If mutationKey is not in SelectedMutations at all, it's unknown → allow it
            
            if allowed then
                -- Build the full name: "BasePepperName|Mutation" or just "BasePepperName"
                local fullName = baseName
                if mutation then
                    fullName = baseName .. "|" .. mutation
                end
                
                table.insert(validPeppers, {
                    Name = baseName,
                    Mutation = mutation,
                    MutationKey = mutationKey,
                    FullName = fullName,
                    Heat = currentHeat
                })
            end
        end
    end
    
    -- Sort by Heat: Highest → Lowest
    table.sort(validPeppers, function(a, b)
        return a.Heat > b.Heat
    end)
    
    return validPeppers
end

BrewTab:CreateInput({
    Name = "Amount to Add (1-1000)",
    Placeholder = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            PepperAmount = math.clamp(num, 1, 1000)
        end
    end,
})

BrewTab:CreateToggle({
    Name = "Auto Add Peppers",
    Callback = function(Value)
        _G.AutoAddPepper = Value
        if _G.AutoAddPepper then
            task.spawn(function()
                local AddPepperEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Brewing"):WaitForChild("AddPepper")
                local BrewEventsFolder = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Brewing")
                local BrewEvent = BrewEventsFolder:WaitForChild("Brew")
                local ClaimEvent = BrewEventsFolder:WaitForChild("ClaimHotsauce")
                
                while _G.AutoAddPepper do
                    -- === PHASE 1: Get ALL peppers sorted by heat (highest → lowest) ===
                    -- Fetch once per cycle, then iterate in order
                    local sortedPeppers = GetSortedPeppers()
                    local currentBatchAdded = 0
                    local pepperIndex = 1
                    
                    -- Add peppers in order: highest heat first → lowest heat
                    while _G.AutoAddPepper and currentBatchAdded < PepperAmount do
                        if pepperIndex <= #sortedPeppers then
                            -- Take the next pepper in heat order (highest first)
                            local pepper = sortedPeppers[pepperIndex]
                            AddPepperEvent:InvokeServer(false, pepper.FullName)
                            currentBatchAdded = currentBatchAdded + 1
                            pepperIndex = pepperIndex + 1
                            task.wait(0.05)
                        else
                            -- Ran out of peppers in the list, re-fetch fresh list
                            -- (new peppers may have been picked up since last fetch)
                            task.wait(0.05)
                            sortedPeppers = GetSortedPeppers()
                            pepperIndex = 1
                            
                            if #sortedPeppers == 0 then
                                -- Still no peppers, keep waiting
                                task.wait(0.05)
                            end
                        end
                    end
                    
                    -- === PHASE 2: Amount reached — decide whether to claim ===
                    if not _G.AutoAddPepper then break end
                    
                    if _G.AutoClaimSauce then
                        -- Auto Claim is ON → Brew + Claim → then loop back to add next batch
                        BrewEvent:InvokeServer()
                        task.wait(0.05)
                        ClaimEvent:FireServer()
                        task.wait(0.05)
                        -- Loop continues → fresh GetSortedPeppers() at top of next cycle
                    else
                        -- Auto Claim is OFF → Stop completely, wait for user to claim manually
                        _G.AutoAddPepper = false
                        break
                    end
                end
            end)
        end
    end
})
-- ==================== SELL TAB ====================
local SellTab = Window:CreateTab({ Name = "Sell", Icon = "💰" })
SellTab:CreateSection("Selling Options")

local SellAmountPerBatch = 1
_G.AutoSellSauce = false

SellTab:CreateInput({
    Name = "Amount per time (1-5)",
    Placeholder = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            SellAmountPerBatch = math.clamp(num, 1, 5)
        end
    end,
})

SellTab:CreateToggle({
    Name = "Auto Sell",
    Callback = function(Value)
        _G.AutoSellSauce = Value
        if _G.AutoSellSauce then
            task.spawn(function()
                local SellEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Selling"):WaitForChild("PlaceHotsauce")
                local PlacementFolder = workspace:WaitForChild("PlayerLots"):WaitForChild(LocalPlayer.Name):WaitForChild("Important"):WaitForChild("Selling"):WaitForChild("Placements")
                
                while _G.AutoSellSauce do
                    local Backpack = LocalPlayer:FindFirstChild("Backpack")
                    local PlacementsList = PlacementFolder:GetChildren()
                    
                    if Backpack and #PlacementsList > 0 then
                        local itemsSentThisBatch = 0
                        
                        for _, Tool in ipairs(Backpack:GetChildren()) do
                            if itemsSentThisBatch >= SellAmountPerBatch or not _G.AutoSellSauce then 
                                break 
                            end
                            
                            local sauceId = Tool:GetAttribute("HotsauceId")
                            if sauceId then
                                local targetSlot = PlacementsList[itemsSentThisBatch + 1] or PlacementsList[1]
                                
                                if targetSlot then
                                    SellEvent:InvokeServer(targetSlot, sauceId)
                                    itemsSentThisBatch = itemsSentThisBatch + 1
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                    task.wait(0.05)
                end
            end)
        end
    end
})

-- ==================== SETTINGS TAB ====================
local SettingsTab = Window:CreateTab({ Name = "Setting", Icon = "⚙️" })
local targetLink = "https://discord.gg/dCnYaQjG3"

SettingsTab:CreateSection("Socials")
SettingsTab:CreateToggle({
    Name = "Join My discord",
    Callback = function(Value)
        if Value then
            if setclipboard then
                setclipboard(targetLink)
            elseif toclipboard then
                toclipboard(targetLink)
            end
        end
    end
})

SettingsTab:CreateSection("Menu Config")
SettingsTab:CreateToggle({
    Name = "Unload UI",
    Callback = function(Value)
        if Value then
            if BuyConnection then BuyConnection:Disconnect() end
        end
    end
})

-- Background Copy Link
if setclipboard then
    setclipboard(targetLink)
elseif toclipboard then
    toclipboard(targetLink)
end