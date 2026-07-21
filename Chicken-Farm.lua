-- ==========================================
-- 1. INITIALIZE SERVICES & LIBRARIES
-- ==========================================
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- AUTO COPY DISCORD LINK ON EXECUTE
-- ==========================================
pcall(function()
    if setclipboard then
        setclipboard("https://discord.gg/55ep7Wf5D")
    elseif toclipboard then
        toclipboard("https://discord.gg/55ep7Wf5D")
    end
end)

-- ==========================================
-- ANTI AFK (Prevent 20-minute Idle Kick)
-- ==========================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Load UI Library
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/test12for/BF-by-CongDanh/refs/heads/main/Libv2_non_release.lua"))()

local Window = Lib:CreateWindow({
    Title        = "Loffy Hub | Chicken Farm [Beta]",
    Subtitle     = " Join My Discord .gg/55ep7Wf5D",
    LogoText     = "L", 
    AvatarImage  = "rbxassetid://81175980653693", 
    AccentColor  = Color3.fromRGB(114, 137, 218),
    ToggleKey    = Enum.KeyCode.RightShift,
    TutorialMode = false,
})

-- ==========================================
-- SMOOTH TWEEN FUNCTION (FIXED PHYSICS)
-- ==========================================
local function TweenTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Khóa trọng lực để bay không bị giật hoặc rớt
    hrp.Anchored = true 
    
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local tweenTime = distance / 150 
    
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait() 
    
    -- Xóa sạch quán tính để không bị lăn lộn khi tới nơi
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
end

-- ==========================================
-- 2. CREATE TABS & SUBTABS
-- ==========================================
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "" 
})

-- Create 6 SubTabs for Main Tab
local FarmSub = MainTab:CreateSubTab({ Name = "Egg Farm" })
local SellSub = MainTab:CreateSubTab({ Name = "Sell Eggs" })
local CollectMoneySub = MainTab:CreateSubTab({ Name = "Collect Cash" })
local LuckyBlockSub = MainTab:CreateSubTab({ Name = "Lucky Block" })
local MergeSub = MainTab:CreateSubTab({ Name = "Auto Merge" })
local BuySub = MainTab:CreateSubTab({ Name = "Buy Chickens" })

-- Create Separate Main Tabs
local UpgradeTab = Window:CreateTab({
    Name = "Upgrades",
    Icon = "" 
})

local DiscordTab = Window:CreateTab({
    Name = "Join My Discord!",
    Icon = "" 
})

-- ==========================================
-- 3. SUBTAB: EGG FARM
-- ==========================================
FarmSub:CreateSection("--- Egg Collection Settings ---")

local _G_AutoEggs = false
FarmSub:CreateToggle({
    Name = "Enable Auto Collect Eggs",
    Description = "Collect eggs -> Fly up 20 studs -> Return to base",
    Default = false,
    Callback = function(Value)
        _G_AutoEggs = (Value == true)
        
        -- Mở khóa nhân vật khi người chơi TẮT tính năng để có thể rớt xuống đất đi lại
        if _G_AutoEggs == false then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Anchored = false
            end
        end

        if _G_AutoEggs == true then
            task.spawn(function()
                while _G_AutoEggs == true do
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local hrp = char.HumanoidRootPart
                        
                        if workspace:FindFirstChild("Eggs") then
                            local eggsList = workspace.Eggs:GetChildren()
                            
                            if #eggsList > 0 then
                                -- Mở khóa tạm thời để lụm trứng không bị kẹt Touched
                                hrp.Anchored = false 
                                
                                for _, egg in pairs(eggsList) do
                                    if _G_AutoEggs ~= true then break end 
                                    if egg:IsA("BasePart") or egg:IsA("UnionOperation") then
                                        hrp.CFrame = egg.CFrame
                                        task.wait(0.1) 
                                    elseif egg:IsA("Model") and egg.PrimaryPart then
                                        hrp.CFrame = egg.PrimaryPart.CFrame
                                        task.wait(0.1)
                                    end
                                end
                                
                                if _G_AutoEggs == true then
                                    local currentPos = hrp.Position
                                    local flyUpPos = Vector3.new(currentPos.X, 22.5, currentPos.Z)
                                    TweenTo(CFrame.new(flyUpPos))
                                end
                            end
                        end
                        
                        if _G_AutoEggs == true then
                            local targetPos = Vector3.new(-114.46, 22.5, -66.64)
                            TweenTo(CFrame.new(targetPos))
                            -- Lúc này TweenTo đã tự động khóa Anchored = true, nhân vật sẽ lơ lửng an toàn
                            task.wait(1) 
                        end
                    else
                        task.wait(1) 
                    end
                end
            end)
        end
    end
})

-- ==========================================
-- 4. SUBTAB: SELL EGGS
-- ==========================================
SellSub:CreateSection("--- Egg Selling Settings ---")

local _G_TargetMultiplier = 0
local _G_AutoSell_Multi = false
local _G_AutoSell_Always = false
local ToggleMulti, ToggleAlways 

SellSub:CreateInput({
    Name = "Multiplier Target for Auto Sell",
    Placeholder = "Enter number (e.g., 0 or 1.5)...",
    Callback = function(Text) 
        _G_TargetMultiplier = tonumber(Text) or 0
    end
})

ToggleMulti = SellSub:CreateToggle({
    Name = "Auto Sell (Check Multiplier)",
    Description = "Sell only when the target Multiplier is reached",
    Default = false,
    Callback = function(Value)
        _G_AutoSell_Multi = (Value == true)
        if _G_AutoSell_Multi == true and _G_AutoSell_Always == true then
            _G_AutoSell_Always = false
            pcall(function() ToggleAlways:Set(false) end) 
        end
    end
})

ToggleAlways = SellSub:CreateToggle({
    Name = "Auto Sell (Continuous)",
    Description = "Sell continuously IGNORING Multiplier",
    Default = false,
    Callback = function(Value)
        _G_AutoSell_Always = (Value == true)
        if _G_AutoSell_Always == true and _G_AutoSell_Multi == true then
            _G_AutoSell_Multi = false
            pcall(function() ToggleMulti:Set(false) end) 
        end
    end
})

SellSub:CreateButton({
    Name = "Sell Eggs (Once)",
    Callback = function() 
        local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
        if paperPath then
            local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
            if remote then remote:InvokeServer("Deposit Eggs") end
        end
    end
})

task.spawn(function()
    while true do
        task.wait(0.5) 
        if _G_AutoSell_Multi == true or _G_AutoSell_Always == true then
            local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
            local remote = paperPath and paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
            
            if remote then
                if _G_AutoSell_Always == true then
                    remote:InvokeServer("Deposit Eggs")
                elseif _G_AutoSell_Multi == true then
                    local multiPath = game:GetService("ReplicatedStorage"):FindFirstChild("Values")
                    if multiPath and multiPath:FindFirstChild("EggMultiplier") then
                        if multiPath.EggMultiplier.Value >= _G_TargetMultiplier then
                            remote:InvokeServer("Deposit Eggs")
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- 5. SUBTAB: COLLECT CASH
-- ==========================================
CollectMoneySub:CreateSection("--- Auto Collect Cash ---")

local _G_AutoCollectCash = false
CollectMoneySub:CreateToggle({
    Name = "Auto Collect Cash",
    Description = "Automatically collect cash every second",
    Default = false,
    Callback = function(Value)
        _G_AutoCollectCash = (Value == true)
        if _G_AutoCollectCash == true then
            task.spawn(function()
                while _G_AutoCollectCash == true do
                    task.wait(1) 
                    local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
                    if paperPath then
                        local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
                        if remote then remote:InvokeServer("Collect Cash") end
                    end
                end
            end)
        end
    end
})

CollectMoneySub:CreateButton({
    Name = "Collect Cash (Once)",
    Callback = function()
        local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
        if paperPath then
            local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
            if remote then remote:InvokeServer("Collect Cash") end
        end
    end
})

-- ==========================================
-- 6. SUBTAB: LUCKY BLOCK
-- ==========================================
LuckyBlockSub:CreateSection("--- Open Lucky Block ---")

local _G_AutoLuckyBlock = false
LuckyBlockSub:CreateToggle({
    Name = "Auto Open Lucky Block",
    Description = "Open a box every 1 second",
    Default = false,
    Callback = function(Value)
        _G_AutoLuckyBlock = (Value == true)
        if _G_AutoLuckyBlock == true then
            task.spawn(function()
                while _G_AutoLuckyBlock == true do
                    task.wait(1) 
                    local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
                    if paperPath then
                        local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
                        if remote then remote:InvokeServer("Open Lucky Block") end
                    end
                end
            end)
        end
    end
})

LuckyBlockSub:CreateButton({
    Name = "Open Lucky Block (Once)",
    Callback = function()
        local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
        if paperPath then
            local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
            if remote then remote:InvokeServer("Open Lucky Block") end
        end
    end
})

-- ==========================================
-- 7. SUBTAB: AUTO MERGE
-- ==========================================
MergeSub:CreateSection("--- Merge Chickens ---")

local _G_AutoMerge = false
MergeSub:CreateToggle({
    Name = "Auto Merge Chickens",
    Description = "Automatically merge chickens continuously",
    Default = false,
    Callback = function(Value)
        _G_AutoMerge = (Value == true)
        if _G_AutoMerge == true then
            task.spawn(function()
                while _G_AutoMerge == true do
                    task.wait(1) 
                    local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
                    if paperPath then
                        local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
                        if remote then remote:InvokeServer("Merge Chickens") end
                    end
                end
            end)
        end
    end
})

MergeSub:CreateButton({
    Name = "Merge Chickens (Once)",
    Callback = function()
        local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
        if paperPath then
            local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
            if remote then remote:InvokeServer("Merge Chickens") end
        end
    end
})

-- ==========================================
-- 8. SUBTAB: BUY CHICKENS
-- ==========================================
BuySub:CreateSection("--- Auto Buy Chickens ---")

local _G_BuyAmount = 1

BuySub:CreateDropdown({
    Name = "Select Chicken Amount",
    Items = {"1", "5", "25", "100"},
    Default = "1",
    Callback = function(Value) 
        _G_BuyAmount = tonumber(Value) or 1
    end
})

local _G_AutoBuy = false
BuySub:CreateToggle({
    Name = "Auto Buy Chickens",
    Description = "Automatically buy based on selected amount",
    Default = false,
    Callback = function(Value)
        _G_AutoBuy = (Value == true)
        if _G_AutoBuy == true then
            task.spawn(function()
                while _G_AutoBuy == true do
                    task.wait(1) 
                    local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
                    if paperPath then
                        local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
                        if remote then 
                            remote:InvokeServer("Buy Chickens", _G_BuyAmount) 
                        end
                    end
                end
            end)
        end
    end
})

BuySub:CreateButton({
    Name = "Buy Chickens (Once)",
    Callback = function()
        local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
        if paperPath then
            local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
            if remote then 
                remote:InvokeServer("Buy Chickens", _G_BuyAmount) 
            end
        end
    end
})

-- ==========================================
-- 9. MAIN TAB: UPGRADES
-- ==========================================
UpgradeTab:CreateSection("--- Upgrade Egg Selling (Process Level) ---")

local _G_AutoUpgradeProcess = false
UpgradeTab:CreateToggle({
    Name = "Auto Upgrade Process Level",
    Description = "Automatically upgrade continuously",
    Default = false,
    Callback = function(Value)
        _G_AutoUpgradeProcess = (Value == true)
        if _G_AutoUpgradeProcess == true then
            task.spawn(function()
                while _G_AutoUpgradeProcess == true do
                    task.wait(1) 
                    local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
                    if paperPath then
                        local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
                        if remote then remote:InvokeServer("Upgrade Process Level") end
                    end
                end
            end)
        end
    end
})

UpgradeTab:CreateButton({
    Name = "Upgrade (Once)",
    Callback = function()
        local paperPath = game:GetService("ReplicatedStorage"):FindFirstChild("Paper")
        if paperPath then
            local remote = paperPath:FindFirstChild("Remotes") and paperPath.Remotes:FindFirstChild("__remotefunction")
            if remote then remote:InvokeServer("Upgrade Process Level") end
        end
    end
})

-- ==========================================
-- 10. MAIN TAB: DISCORD
-- ==========================================
DiscordTab:CreateSection("--- Official Discord ---")

DiscordTab:CreateButton({
    Name = "Join My discord sever",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/55ep7Wf5D")
            elseif toclipboard then
                toclipboard("https://discord.gg/55ep7Wf5D")
            end
        end)
        
        Window.Notify({
            Title = "System",
            Content = "Discord link copied to clipboard!",
            Type = "Success",
            Duration = 3
        })
    end
})

-- Notification for Anti AFK
Window.Notify({
    Title = "System",
    Content = "Silent Anti AFK has been activated! Discord link copied.",
    Type = "Info",
    Duration = 3
})