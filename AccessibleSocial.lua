local ENABLED = "enabled"
local ENABLE = "enable"
local DISABLED = "disabled"
local DISABLE = "disable"
local VOICE = "voice"
local NOVOICE = "novoice"
local REPLAY = "replay"
local GUILD = "guild"
local ONLINE = "online"
local OFFLINE = "offline"
local friends = {}

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
local function AccessiblePrintWithPrefix(printString1, ...)
    if IsPrintEnabled() then
        AS:Print(printString1, ...)
        TextToSpeech_Speak("AccessibleSocial " .. printString1.. ..., TextToSpeech_GetSelectedVoice(0))
    end
end

local function AccessiblePrint(printString1, ...)
    if IsPrintEnabled() then
        AS:Print(printString1, ...)
        TextToSpeech_Speak(printString1.. ..., TextToSpeech_GetSelectedVoice(0))
    end
end

local function PrintAddonStatus()
    local enabledString = ENABLED

    if not IsPrintEnabled() then
        enabledString = DISABLED
        AS:Print(enabledString)
    end

    AccessiblePrintWithPrefix(enabledString, "")
end

--- Determine if we should be printing, then get the achievement info and call our print function.
local function PrintFriend(accountInfo)
    if (IsPrintEnabled() and accountInfo ~= nil) then
            local battleTag = accountInfo.battleTag
            local isOnline = accountInfo.gameAccountInfo.isOnline
            local characterName = accountInfo.gameAccountInfo.characterName
            local skipPrint = false

            local oldStatus = friends[battleTag]

            if oldStatus ~= nil then
                if oldStatus.charName == characterName then
                    if oldStatus.isOnline == isOnline then
                        -- Same character, same status, don't print
                        skipPrint = true
                    end
                end
            end

            if skipPrint == false then
                friends[battleTag] = {
                    charName = characterName,
                    isOnline = isOnline
                }
                local onlineStatus = (isOnline == true and ONLINE) or OFFLINE
                if isOnline == true and characterName ~= nil then
                    AccessiblePrintWithPrefix("BattleNet: "..battleTag, "is "..onlineStatus.." on "..characterName)
                else
                    AccessiblePrintWithPrefix("BattleNet: "..battleTag, "is "..onlineStatus)
                end
            end
    end
end

function PrintGuild()
    local numTotalGuildMembers, numOnlineGuildMembers, _ = GetNumGuildMembers()

    AccessiblePrintWithPrefix(numOnlineGuildMembers.." guildies online out of", numTotalGuildMembers.." total members")
    for gIndex=1, numTotalGuildMembers do
        local name, rankName, _, level, classDisplayName, zone, _, _, isOnline, _ = GetGuildRosterInfo(gIndex)
        if(isOnline) then
            PrintGuildie(name, rankName, level, classDisplayName, zone)
        end
    end
end

function PrintGuildie(name, rankName, level, classDisplayName, zone)
    AccessiblePrint(rankName.." "..name, "level " .. level.." "..classDisplayName.." location: "..zone)
end

function AS:OnInitialize()
    AS:Print("OnInitialize")

    local defaults = {
        enabled = true,
    }

    if (ASDB == nil) then
        ASDB = defaults
    end

    AS:RegisterChatCommand("as", "SlashCommand")
    AS:RegisterChatCommand("accessiblesocial", "SlashCommand")
end

function AS:OnEnable()
    AS:Print("OnEnable")
    AS:RegisterEvent("AUTOFOLLOW_BEGIN")
    AS:RegisterEvent("AUTOFOLLOW_END")
    AS:RegisterEvent("BN_FRIEND_INFO_CHANGED")
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

function AS:BN_FRIEND_INFO_CHANGED(eventName, friendIndex)
    if friendIndex ~= nil then
        local accountInfo = C_BattleNet.GetFriendAccountInfo(friendIndex)
        PrintFriend(accountInfo)
    end
end

function AS:AUTOFOLLOW_BEGIN(event, name)
    AccessiblePrintWithPrefix("Autofollowing ", name)
end

function AS:AUTOFOLLOW_END(event)
    AccessiblePrintWithPrefix("No longer Autofollowing", "anyone")
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
        AccessiblePrintWithPrefix("Enter a command: /as "..ENABLE.." or /as "..DISABLE, " or /as "..VOICE.." or /as "..NOVOICE.." or /as "..GUILD)
    end
end


