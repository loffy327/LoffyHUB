local Players = game:GetService("Players")
local MarketPlaceService = game:GetService("MarketplaceService")

getgenv().Config = getgenv().Config or {}

local isKaitunMode = getgenv().Config.KaitunMode 
    if isKaitunMode == nil then isKaitunMode = _G.KaitunMode end
    if isKaitunMode == nil then isKaitunMode = false end
local SupportedGames = {
    [84515722934860] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Anime-Expedition.lua",
        Kaitun = ""
    },
    [4442272183] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Throw-A-Coin.lua",
        Kaitun = ""
    },
    [137233438285284] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Chicken-Farm.lua",
        Kaitun = ""
    },
    [122391683154858] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Make-HotSauce.lua"
    },
    [94735232265626] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Merge-A-Nuke.lua",
        Kaitun = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Kaitun-Merge-A-Nuke.lua"
    }
}

local UniversalScript = nil -- Đổi thành nil thay vì "none"
local function ExecuteScript(url, scriptName)
    print(string.format("[Hub Loader] Loading %s...", scriptName or "Script"))
    
    local cleanUrl = url .. "?nocache=" .. tostring(os.time())
    local success, response = pcall(function()
        return game:HttpGet(cleanUrl)
    end)

    if success and response then
        local loadedFunc, err = loadstring(response)
        if loadedFunc then
            task.spawn(loadedFunc)
            print("[Hub Loader] Script executed successfully!")
        else
            warn("[Hub Loader] Syntax Error in Raw File: " .. tostring(err))
        end
    else
        warn("[Hub Loader] Connection Failed: " .. tostring(response))
    end
end
local currentPlaceId = game.PlaceId
local gameData = SupportedGames[currentPlaceId]

if gameData then
    local gameName = "Game ID: " .. tostring(currentPlaceId)
    pcall(function()
        local gameInfo = MarketPlaceService:GetProductInfo(currentPlaceId)
        if gameInfo and gameInfo.Name then
            gameName = gameInfo.Name
        end
    end)
    
    local targetUrl = gameData.Main
    if isKaitunMode and gameData.Kaitun and gameData.Kaitun ~= "" then
        targetUrl = gameData.Kaitun
        gameName = gameName .. " [KAITUN MODE]"
    else
        gameName = gameName .. " [MAIN MODE]"
    end

    ExecuteScript(targetUrl, gameName)
else
    warn("[Hub Loader] Current Game (" .. tostring(currentPlaceId) .. ") is not configured.")
    if UniversalScript and UniversalScript ~= "" then
        ExecuteScript(UniversalScript, "Universal Script")
    end
end
