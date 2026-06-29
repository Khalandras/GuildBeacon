--- Startup sequence.

local GB = GuildBeacon
local Internal = GB.Internal
local API = GB.API

local Bootstrap = {}
Internal.Bootstrap = Bootstrap

local bootFrame
local initialized = false
local playerLoggedIn = false

function Bootstrap:Start(addonName)
    if bootFrame then
        return
    end
    bootFrame = CreateFrame("Frame")
    bootFrame:RegisterEvent("ADDON_LOADED")
    bootFrame:RegisterEvent("PLAYER_LOGIN")
    bootFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" then
            local loaded = ...
            if loaded ~= addonName and loaded ~= (GB.ADDON_NAME or "GuildBeacon") then
                return
            end
            Bootstrap:OnAddonLoaded()
        elseif event == "PLAYER_LOGIN" then
            Bootstrap:OnPlayerLogin()
        end
    end)
end

local function SafeInitDashboard()
    if not GB.UI or not GB.UI.Dashboard then
        return
    end
    local ok, err = pcall(GB.UI.Dashboard.Initialize, GB.UI.Dashboard)
    if not ok and Internal.Logger then
        Internal.Logger:Log(Internal.Logger.LEVEL.ERROR, "Dashboard", "Initialize failed: %s", GB.SafeToString(err))
    end
end

function Bootstrap:OnAddonLoaded()
    if initialized then
        return
    end
    Internal.ProfileManager:Initialize()
    Internal.Logger:Initialize()
    Internal.EventBus:Initialize()
    Internal.ModuleManager:Initialize()
    if GB.UI and GB.UI.SlashCommands then
        GB.UI.SlashCommands:Initialize()
    end
    SafeInitDashboard()
    initialized = true
end

function Bootstrap:OnPlayerLogin()
    if playerLoggedIn then
        return
    end
    playerLoggedIn = true
    Internal.ProfileManager:EnsureProfileForPlayer()
    if GB.UI and GB.UI.SlashCommands and not SlashCmdList.GUILDBEACON then
        GB.UI.SlashCommands:Initialize()
    end
    if not initialized then
        Bootstrap:OnAddonLoaded()
    end
    API:Print(GB.L("ADDON_LOADED"), GB.ADDON_NAME or "GuildBeacon", GB.Version or "?")
    if GB.WIDGETS_BUILD then
        API:Print("|cff6b6178Widgets build:|r %s", GB.WIDGETS_BUILD)
    end
    API:Print(GB.L("TYPE_HELP"))
end
