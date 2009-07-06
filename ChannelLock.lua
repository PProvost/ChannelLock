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
ChannelLock.revision = tonumber(("$Revision: 27 $"):match("%d+"))
ChannelLock.date = ("$Date: 2009-02-19 12:21:51 -0700 (Thu, 19 Feb 2009) $"):match("%d%d%d%d%-%d%d%-%d%d")
ChannelLock.tempChannels = {}

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
	self.db = LibStub("AceDB-3.0"):New("ChannelLockDB", self:GetDefaults(), "Default")

	LibStub("tekKonfig-AboutPanel").new(nil, "ChannelLock")

	LibStub("AceConfig-3.0"):RegisterOptionsTable("ChannelLock", self:GetOptions() )
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Channels", "ChannelLock", "channels")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Profiles", "ChannelLock", "profiles")

	self:RegisterChatCommand("channellock", "OpenConfig")
	self:RegisterChatCommand("cl", "OpenConfig")
end

function ChannelLock:OpenConfig()
	InterfaceOptionsFrame_OpenToCategory("ChannelLock")
end

function ChannelLock:OnEnable()
	-- Clean up database
	local channels = self.db.profile.channels
	for i = 1,10 do
		if channels[i].name == nil or channels[i].name == "" or channels[i].empty then
			channels[i].name = ""; channels[i].empty = true
		end
	end

	-- Kick it off
	self.state = "CheckChannels"
	self.stateTimer = self:ScheduleRepeatingTimer("StateMachine", 3.0)
end

function ChannelLock:StateMachine()
	if self.state == "CheckChannels" then
		self.state = (self:CheckChannels() and "SetupChannelFrames") or "DropAllChannels"
	elseif self.state == "DropAllChannels" then
		self:Print("Channels need adjusting. One moment...")
		self:DropAllChannels()
		self.state = "JoinAllChannels"
	elseif self.state == "JoinAllChannels" then
		self:JoinAllChannels()
		self.state = "DropTempChannels"
	elseif self.state == "DropTempChannels" then
		self:DropTempChannels()
		self.state = "SetupChannelFrames"
	elseif self.state == "SetupChannelFrames" then
		self:SetupChannelFrames()
		self.state = "End"
	else
		self:CancelTimer(self.stateTimer)
		self:Print("Channels setup correctly. Enjoy!")
		self.state = "End"
	end
end

function ChannelLock:IsTradeChannelAndNotTradeZone(channel)
	local currentZone = GetRealZoneText()
	return channel == TRADE_CHANNEL_NAME and not knownTradeZones[currentZone]
end

function ChannelLock:GetSourceList()
	local source = {}

	for i = 1,10 do
		local id, name = GetChannelName(i)
		name = self:CleanChannelName(name)

		if not name then
			source[i] = { empty = true, name = "" }
		else
			source[i] = { empty = nil, name = string.lower(name) }
		end
	end

	local lfgid, lfgname = GetChannelName(LFG_CHANNEL_NAME)
	local tradeid, tradename = GetChannelName(TRADE_CHANNEL_NAME) 

	if lfgname then
		source[lfgid] = { empty = nil, name = lfgname }
	end
	if tradename then
		source[tradeid] = { empty = nil, name = "Trade" }
	end

	return source
end

function ChannelLock:CheckChannels()
	local goal = self.db.profile.channels
	local source = self:GetSourceList()
	return self:IsChannelListCorrect(source,goal)
end

function ChannelLock:JoinAllChannels()
	local channels = self.db.profile.channels
	for i = 1,10 do
		if channels[i].empty then
			self:JoinTempChannel(i)
		else
			self:JoinChannel(channels[i].name, channels[i].frameIndex)
		end
	end
end

function ChannelLock:DropAllChannels()
	for i = 1,10 do
		local id, name = GetChannelName(i)
		self:LeaveChannel(name)
	end
end

function ChannelLock:DropTempChannels()
	for i,name in ipairs(self.tempChannels) do
		self:LeaveChannel(name)
	end
end

function ChannelLock:SetupChannelFrames()
	local channels = self.db.profile.channels
	for i = 1,10 do
		if not channels[i].empty then
			if not channels[i].frameIndex then channels[i].frameIndex = 1 end
			ChatFrame_AddChannel(_G["ChatFrame"..channels[i].frameIndex], channels[i].name)
		end
	end
		
end

function ChannelLock:CompareChannelInfo( source, goal )
   return (source.empty == goal.empty) and 
   (string.lower(source.name) == string.lower(goal.name))
end

function ChannelLock:IsChannelListCorrect(source, goal)
   for i = 1,10 do
      if not self:CompareChannelInfo(source[i], goal[i]) then
				return false
      end
   end
	 return true
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

function ChannelLock:JoinChannel(channel, frameIndex)
	if not channel then return end
	if not frameIndex then frameIndex = 1 end
	JoinPermanentChannel(channel, nil, frameIndex, nil)
end

function ChannelLock:JoinTempChannel(index)
	local name = "Temp_" .. index
	self:JoinChannel(name)
	table.insert(self.tempChannels, name)
end

function ChannelLock:LeaveChannel(channel)
	if not channel then return end
	LeaveChannelByName(channel);
end

