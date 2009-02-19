--[[
ChannelLock/ChannelLock.lua

Copyright 2008 Quaiche

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

ChannelLock = LibStub("AceAddon-3.0"):NewAddon("ChannelLock", "AceConsole-3.0", "AceTimer-3.0")
ChannelLock.revision = tonumber(("$Revision$"):match("%d+"))
ChannelLock.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")

ChannelLock.debug = false

local timerDelay = 1

local TRADE_CHANNEL_NAME = "Trade - City"
local LFG_CHANNEL_NAME = "LookingForGroup"

local debugf = tekDebug and tekDebug:GetFrame("ChannelLock")

local knownTradeZones = {
	['Orgrimmar'] = 1,
	['Thunder Bluff'] = 1,
	['Undercity'] = 1,
	['Stormwind City'] = 1,
	['Darnassus'] = 1,
	['Ironforge'] = 1,
	['Shattrath City'] = 1,
	['Silvermoon City'] = 1,
	['The Exodar'] = 1,
	['Dalaran'] = 1,
}

function ChannelLock:OnInitialize()
	self.defaults = self:GetDefaults()
	self.db = LibStub("AceDB-3.0"):New("ChannelLockDB", self.defaults, "Default")

	LibStub("tekKonfig-AboutPanel").new(nil, "ChannelLock")

	self.options = self:GetOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ChannelLock", self.options )
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Channels", "ChannelLock", "channels")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Profiles", "ChannelLock", "profiles")


	self:RegisterChatCommand("channellock", "OpenConfig")
	self:RegisterChatCommand("cl", "OpenConfig")
end

function ChannelLock:OpenConfig()
	InterfaceOptionsFrame_OpenToCategory("ChannelLock")
end

function ChannelLock:OnEnable()
	self.commandQueue = {}
	self.deferredCommands = {}

	self:Debug( "Enable - Scheduling channel check")
	self:ScheduleTimer("CheckChannels", timerDelay)
end

function ChannelLock:Debug(...)
	if debugf then
		self:Print(debugf, ...)
	end
end

function ChannelLock:DebugF(...)
	if debugf then
		self:Print(debugf, string.format(...))
	end
end

function ChannelLock:IsTradeChannelAndNotTradeZone(channel)
	local currentZone = GetRealZoneText()
	return channel == TRADE_CHANNEL_NAME and not knownTradeZones[currentZone]
end

function ChannelLock:MakeCommandQueue(source, goal) 
	local commandQueue = {} 
	local cleanupQueue = {} 

	for i = 1, #source do 
		if source[i].name ~= goal[i].name and not source[i].empty and not self:IsTradeChannelAndNotTradeZone(source[i].name) then 
			if source[i].name == LFG_CHANNEL_NAME then table.insert(commandQueue, { action="set_lfg" }) end
			table.insert(commandQueue, { action="leave", channelName=source[i].name }) 
			if source[i].name == LFG_CHANNEL_NAME then table.insert(commandQueue, { action="clear_lfg" }) end
		end 
	end 

	for i = 1, #source do 
		if goal[i].empty then 
			if self:IsTradeChannelAndNotTradeZone(source[i].name) then
				table.insert(commandQueue, { action="warning", message="Unable to leave Trade channel because you are not in a trade zone." })
			else
				table.insert(commandQueue, { action="join", channelName="temp"..i, frameIndex=goal.frameIndex }) 
				table.insert(cleanupQueue, { action="leave", channelName="temp"..i }) 
			end
		elseif (source[i].name ~= goal[i].name) and not goal[i].empty then 
			if self:IsTradeChannelAndNotTradeZone(source[i].name) then
				table.insert(commandQueue, { action="warning", message="Unable to replace Trade channel because you are in a trade zone." })
			else
				table.insert(commandQueue, { action="join", channelName=goal[i].name, frameIndex=goal.frameIndex }) 
			end
		end 
	end 

	for i = 1,#cleanupQueue do 
		table.insert(commandQueue, cleanupQueue[i]) 
	end 

	for i = 1,#goal do
		if not goal[i].empty and goal[i].name then
			local frameIndex = goal[i].frameIndex or 1
			table.insert(commandQueue, { action="setframe", frameIndex=frameIndex, channelName=goal[i].name })
		end
	end

	return commandQueue 
end  

function ChannelLock:GetSourceList()
	local source = {}

	for i = 1,10 do
		local id, name = GetChannelName(i)
		name = self:CleanChannelName(name)

		if not name then
			source[i] = { empty = true }
		else
			source[i] = { name = name }
		end
	end

	local lfgid, lfgname = GetChannelName(LFG_CHANNEL_NAME)
	local tradeid, tradename = GetChannelName(TRADE_CHANNEL_NAME) 

	if lfgname then
		source[lfgid] = { name = lfgname }
	end
	if tradename then
		source[tradeid] = { name = tradename }
	end

	return source
end

function ChannelLock:CheckChannels()
	local goal = self.db.profile.channels
	local source = self:GetSourceList()
	self.commandQueue = self:MakeCommandQueue(source, goal)
	self.processingTimer = self:ScheduleRepeatingTimer("PopCommand", timerDelay)
end

function ChannelLock:HandleCommand(cmd)
	if cmd.action == "join" then
		self:JoinChannel(cmd.channelName, cmd.frameIndex)
	elseif cmd.action == "leave" then
		self:LeaveChannel(cmd.channelName)
	elseif cmd.action == "set_lfg" then
		SetLookingForGroup(3,5,1)
	elseif cmd.action == "clear_lfg" then
		SetLookingForGroup(3,1,1)
	elseif cmd.action == "warning" then
		self:Print("Warning - " .. cmd.message)
	elseif cmd.action == "setframe" then
		local frame = getglobal("ChatFrame"..cmd.frameIndex)
		ChatFrame_AddChannel(frame, cmd.channelName)
	else
		self:Debug("Unknown command: " .. cmd.action)
	end
end

function ChannelLock:PopCommand()
	local command = nil
	for i,v in ipairs(self.commandQueue) do
		if not v.popped then
			command = v
			break
		end
	end

	if command then
		command.popped = true
		self:HandleCommand(command)
	else
		self:CancelTimer(self.processingTimer)
		self:Print("Channel setup complete! You are ready to go.")
	end
end

-- this reduces server zone channels (general, trade, etc to their base parts with no zone info)
function ChannelLock:CleanChannelName(channel)
	if (channel == nil) then return nil; end
	local spaceFound = string.find(channel, " ");
	if (spaceFound) then
		channel = string.sub(channel, 1, spaceFound - 1);
	end
	return channel;
end

local function NoopFilter() return true end

function ChannelLock:JoinChannel(channel, frameIndex)
	if not channel then return end
	if not frameIndex then frameIndex = 1 end

	-- We may be able to use something like this to prevent the "Joining" and "Leaving" messages
	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
	JoinPermanentChannel(channel, nil, frameIndex, nil)
	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
end

function ChannelLock:LeaveChannel(channel, frameIndex)
	if not channel then return end
	if not frameIndex then frameIndex = 1 end

	-- We may be able to use something like this to prevent the "Joining" and "Leaving" messages
	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
	LeaveChannelByName(channel);
	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
end

