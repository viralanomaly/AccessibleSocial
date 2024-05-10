local ENABLED = "enabled"
local ENABLE = "enable"
local DISABLED = "disabled"
local DISABLE = "disable"
local VOICE = "voice"
local NOVOICE = "novoice"
local REPLAY = "replay"
local GUILD = "guild"

AccessibleSocial = LibStub("AceAddon-3.0"):NewAddon("AccessibleSocial", "AceConsole-3.0", "AceEvent-3.0")
AS = AccessibleSocial

--- Determine if our settings allow printing
---@return boolean
local function IsPrintEnabled()
    local enablement = ASDB ~= nil and ASDB.enabled == true
    return enablement
end

--- Our custom print function.  Will print to screen and check the addon voice setting before concatenating the strings to text-to-speech.
---@param printString1 string First string to print/read
---@param ... string Additional strings to print/read
local function AccessiblePrint(printString1, ...)
    AS:Print(printString1, ...)
    if IsPrintEnabled() then
        TextToSpeech_Speak("AccessibleSocial " .. printString1.. ..., TextToSpeech_GetSelectedVoice(0))
    end
end

local function PrintAddonStatus()
    local enabledString = ENABLED

    if not IsPrintEnabled() then
        enabledString = DISABLED
    end

    AccessiblePrint(enabledString, "")
end

--- Determine if we should be printing, then get the achievement info and call our print function.
local function PrintFriend(friendId, isCompanionApp)
    if IsPrintEnabled() then
        -- if self == "CHAT_MSG_BN_INLINE_TOAST_ALERT" then   
            -- 1. text: string  
            -- 2. playerName: string  
            -- 3. languageName: string  
            -- 4. channelName: string  
            -- 5. playerName2: string  
            -- 6. specialFlags: string  
            -- 7. zoneChannelID: number  
            -- 8. channelIndex: number  
            -- 9. channelBaseName: string  
            -- 10. languageID: number  
            -- 11. lineID: number  
            -- 12. guid: WOWGUID  
            -- 13. bnSenderID: number  
            -- 14. isMobile: boolean  
            -- 15. isSubtitle: boolean  
            -- 16. hideSenderInLetterbox: boolean  
            -- 17. supressRaidIcons: boolean 
            local _, accountName, battleTag, _, characterName, _, client, isOnline = BNGetFriendInfo(friendId)

            local onlineStatus = "offline"
            if isOnline == true then
                onlineStatus = "online"
            end

            AccessiblePrint("BattleNet: "..accountName.." also known as "..battleTag.." ", "is "..onlineStatus.." on "..characterName)
        -- end
    end
end

function PrintGuild()
    local ginfo = GuildInfo()
    local groster = GuildRoster()
end

function AS:OnInitialize()
    AS:Print("OnInitialize")
    ASDB = ASDB or {}

    if ASDB.enabled == nil then
        ASDB.enabled = true
    end

    AS:RegisterChatCommand("as", "SlashCommand")
    AS:RegisterChatCommand("accessiblesocial", "SlashCommand")
end

function AS:OnEnable()
    AS:Print("OnEnable")
    AS:RegisterEvent("AUTOFOLLOW_BEGIN")
    AS:RegisterEvent("AUTOFOLLOW_END")
    -- f:RegisterEvent("CHAT_MSG_BN_INLINE_TOAST_ALERT")
    AS:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
    -- f:RegisterEvent("CHAT_MSG_BN_WHISPER")
    -- f:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
    -- f:RegisterEvent("CHAT_MSG_RAID")
    -- f:RegisterEvent("CHAT_MSG_WHISPER")
    -- f:RegisterEvent("CHAT_MSG_BN")
    -- f:RegisterEvent("CHAT_MSG_SKILL") -- Profession?
    -- f:RegisterEvent("CHAT_MSG_PARTY")
    -- Send on BN whisper, read it back
    -- Read who is doing what on battlenet

    PrintAddonStatus()
end

--- Handler for Battlenet friend logging on event.
---@param self any
---@param event any
---@param ... unknown
function AS:BN_FRIEND_ACCOUNT_ONLINE(eventName, friendId, isCompanionApp)
    AS:Print("Friend!!!")
    PrintFriend(friendId, isCompanionApp)
end

function AS:AUTOFOLLOW_BEGIN(event, name)
    AccessiblePrint("Autofollowing ", name)
end

function AS:AUTOFOLLOW_END(event)
    AccessiblePrint("No longer Autofollowing anyone")
end

-- Configure slash commands for enable and disable of the printing

function AS:SlashCommand(msg)
    local cmd1 = strsplit(" ", msg)
    
    if #cmd1 > 0 then
        cmd1 = strlower(cmd1)

        if cmd1 == ENABLED or cmd1 == ENABLE or cmd1 == VOICE then
            ASDB.enabled = true
            PrintAddonStatus()
        elseif cmd1 == DISABLED or cmd1 == DISABLE or cmd1 == NOVOICE then
            ASDB.enabled = false
            PrintAddonStatus()
        elseif cmd1 == GUILD then
            PrintGuild()
        end
    else
        AccessiblePrint("Enter a command: /as "..ENABLE.." or /aa "..DISABLE, " or /aa "..VOICE.." or /aa "..NOVOICE.." or /aa "..REPLAY)
    end
end


