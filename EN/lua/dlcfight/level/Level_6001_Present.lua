---@class XLevelScript6001
---@field _proxy XDlcCSharpFuncs
local XLevelScript6001 = XDlcScriptManager.RegLevelPresentScript(6001)
---@param proxy XDlcCSharpFuncs
function XLevelScript6001:Ctor(proxy)
end

function XLevelScript6001:Init()
    -- 结算Npc
    self._settleNpcPlaceId = 300002
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID(4008新手引导，4009普通)
    if self._levelId == 4008 then
        self._settleNpcPlaceId = 300002
        self.TransformBoxPlaceId = 300026
        self.SaveBoxPlaceId = 0
        self._StartPos = { x = 243.7, y = 37, z = 322.7 }
        self.TreasureChests1 = 300032
        self.TreasureChests2 = 300033
        self.TreasureChests3 = 300034
        self.WinTrigger = 300035
        self._MoveLimit = {300027,300028}
        self._rot = { x = 0, y = 73, z = 0 }
    elseif self._levelId == 4009 then
        self._settleNpcPlaceId = 400002
        self.TransformBoxPlaceId = 400004
        self.SaveBoxPlaceId = 400070
        self._StartPos = { x = 252.58, y = 38.92, z = 241.96 }
        self.TreasureChests1 = 400073
        self.TreasureChests2 = 400074
        self.TreasureChests3 = 400075
        self.WinTrigger = 400071
        self._MoveLimit = {400098,400097,400098}
        self._rot = { x = 0, y = 17, z = 0 }
        self._rot1 = { x = 0, y = -1, z = 0 }
    elseif self._levelId == 4010 then
        self._settleNpcPlaceId = 500001
        self.TransformBoxPlaceId = 500090
        self.SaveBoxPlaceId = 500092
        self._StartPos = { x = 250.82, y = 55.46, z = 270.79 }
        self.TreasureChests1 = 500094
        self.TreasureChests2 = 500095
        self.TreasureChests3 = 500096
        self.WinTrigger = 500093
        self._MoveLimit = {500165,500166,500091}
        self._RewardTrigger = 500036
        self._rot = { x = 0, y = 84, z = 0 }
        self._rot1 = { x = 0, y = 92, z = 0 }
    elseif self._levelId == 4018 then
        self._settleNpcPlaceId = 600002
        self.TransformBoxPlaceId = 600112
        self.SaveBoxPlaceId = 600142
        self.SaveBoxPlaceId1 = 600083
        self._StartPos = { x = 266.72, y = 52.77, z = 327.83 }
        self.TransformDoor3 = 600085
        self.TransformDoor1 =  600018
        self.TransformDoor6 = 600088
        self.Transform1Into = 600089
        self.Transform1Out = 600090
        self.Transform2Into = 600091
        self.Transform2Out = 600092
        self.Transform3Into = 600102
        self.Transform3Out = 600103
        self.TreasureChests1 = 600108
        self.TreasureChests2 = 600109
        self.TreasureChests3 = 600110
        self.WinTrigger = 600111
        self._MoveLimit = {600143,600144,600086}
        self._rot = { x = 0, y = -175, z = 0 }
        self._rot1 = { x = 0, y = 0, z = 0 }
        self._rot2 = { x = 0, y = 85, z = 0 }
    elseif self._levelId == 4019 then
        self._settleNpcPlaceId = 700002
        self.TransformBoxPlaceId = 700110
        self.SaveBoxPlaceId = 700109
        self.SaveBoxPlaceId1 =  700144
        self._StartPos = { x = 378.57, y = 54.64, z = 290.85 }
        self.TreasureChests1 = 700094
        self.TreasureChests2 = 700095
        self.TreasureChests3 = 700096
        self.WinTrigger = 700111
        self._MoveLimit = {700112,700113,700143}
        self._rot = { x = 0, y = -95, z = 0 }
        self._rot1 = { x = 0, y = -95, z = 0 }
        self._rot2 = { x = 0, y = -80, z = 0 }
    elseif self._levelId == 4020 then
        self._settleNpcPlaceId = 800002
        self.TransformBoxPlaceId = 800107
        self.SaveBoxPlaceId = 800126
        self._StartPos = { x = 270.39, y = 50.61, z = 238.81 }
        self.TransformDoor1 = 800046
        self.TransformDoor3 = 800045
        self.TransformDoor5 = 800044 
        self.Transform1Into = 800129
        self.Transform1Out = 800132
        self.Transform2Into = 800130
        self.Transform2Out = 800133
        self.Transform3Into = 800131
        self.Transform3Out = 800134
        self.TreasureChests1 = 800111
        self.TreasureChests2 = 800112
        self.TreasureChests3 = 800113
        self.WinTrigger = 800157
        self._MoveLimit = {800009,800010,800124,800066}
        self.SaveBoxPlaceId1 = 800042
        self._rot = { x = 0, y = -1, z = 0 }
        self._rot1 = { x = 0, y = 0, z = 0 }
        self._rot2 = { x = 0, y = 0, z = 0 }
    elseif self._levelId == 4025 then
        self._settleNpcPlaceId = 900002
        self.TransformBoxPlaceId = 900030
        self.SaveBoxPlaceId =0
        self._StartPos = { x = 243.7, y = 37, z = 322.7 }
        self.WinTrigger = 900027
        self._MoveLimit = {900025}
        self._rot = { x = 0, y = -175, z = 0 }
    end
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)

    -- 1.5秒后提示引导
    self._proxy:AddTimerTask(1.5, function()
        if self._levelId == 4008 then
            self._proxy:ShowBigWorldTeach(2001)
        elseif self._levelId == 4009 then
            self._proxy:ShowBigWorldTeach(2002)
        elseif self._levelId == 4010 then
            self._proxy:ShowBigWorldTeach(2003)
        elseif self._levelId == 4018 then
            self._proxy:ShowBigWorldTeach(2004)
        end
    end)
    self._proxy:SetNpcActive(self._proxy:GetNpcUUID(self._settleNpcPlaceId), false)
    self:SetMoveLimitActive(false)
    self._proxy:SetPlayerFirstPersonMode(false)
    self._proxy:SetSceneObjectActive(self.WinTrigger, true)
    self.WinTriggerNum = true
    self._proxy:ControlSystemFunction(ESystemFunctionType.Map, { true })         --地图不能点击
    self._proxy:ControlSystemFunction(ESystemFunctionType.Task, { 1 }) --任务不能点击
end

function XLevelScript6001:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XLevelScript6001:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Enter then
        if eventArgs.HostSceneObjectPlaceId == self.SaveBoxPlaceId then
            --保存点
            self._StartPos = self._proxy:GetSceneObjectPositionByPlaceId(self.SaveBoxPlaceId)
            self._rot=self._rot1
        elseif eventArgs.HostSceneObjectPlaceId == self.SaveBoxPlaceId1 then
            self._StartPos = self._proxy:GetSceneObjectPositionByPlaceId(self.SaveBoxPlaceId1)
            self._rot = self._rot2
        elseif eventArgs.HostSceneObjectPlaceId == self.TransformBoxPlaceId then
            --死区传送回出发点
            self._proxy:TeleportWithBlackUi(self._proxy:GetLocalPlayerNpcId(), self._StartPos, self._rot)
            self:SetMoveLimitActive(true)
            if self.WinTriggerNum == true then
                self._proxy:AddTimerTask(2.5, function()
                    self:SetMoveLimitActive(false)
                end)
            end
        elseif eventArgs.HostSceneObjectPlaceId == self.TransformDoor1 then
            self._Transform = self._proxy:GetSceneObjectPositionByPlaceId(self.Transform1Into)
            self:DoTeleportWithCouple(self.TransformDoor1, self._Transform)
        elseif eventArgs.HostSceneObjectPlaceId == self.TransformDoor3 then
            --传送门合集
            self._Transform = self._proxy:GetSceneObjectPositionByPlaceId(self.Transform2Into)
            if self._levelId == 4018 then
                self:DoTeleportWithCouple(self.TransformDoor3, self._Transform, { x = 0, y = 0, z = 0 }, function()
                    self._proxy:ResetCamera(false,0, true)
                end)
            else
                self:DoTeleportWithCouple(self.TransformDoor3, self._Transform)
            end
        elseif eventArgs.HostSceneObjectPlaceId == self.TransformDoor5 then 
            --传送门合集
            self._Transform = self._proxy:GetSceneObjectPositionByPlaceId(self.Transform3Into)
            self:DoTeleportWithCouple(self.TransformDoor5, self._Transform)
        elseif eventArgs.HostSceneObjectPlaceId == self.TransformDoor6 then
            --传送门合集
            self._Transform = self._proxy:GetSceneObjectPositionByPlaceId(self.Transform3Out)
            self:DoTeleportWithCouple(self.TransformDoor3, self._Transform, { x = 0, y = -80, z = 0 }, function()
                self._proxy:ResetCamera(false,0, true)
            end)
        elseif eventArgs.HostSceneObjectPlaceId == self.WinTrigger then
            self._proxy:SetNpcActive(self._proxy:GetNpcUUID(self._settleNpcPlaceId), true)
            self._StartPos = self._proxy:GetSceneObjectPositionByPlaceId(self.WinTrigger)          --到终点了摔落返回终点
            self:SetMoveLimitActive(true)
            self.WinTriggerNum = false
        end
    --elseif eventType == EWorldEvent.NpcInteractStart then
    --    if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then
    --        --是玩家发起的交互
    --        if eventArgs.TargetPlaceId == self._settleNpcPlaceId then
    --            self._proxy:RequestLeaveInstanceLevel(false)
    --        end
    --    end
    end
end

function XLevelScript6001:Terminate()
        self._proxy:ControlSystemFunction(ESystemFunctionType.Map, { false })         --地图不能点击
    self._proxy:ControlSystemFunction(ESystemFunctionType.Task, { 0 })            --任务不能点击
end

function XLevelScript6001:DoTeleportWithCouple(teleportPlaceId1, pos, rot, cb)
    self._proxy:SetSceneObjectActive(teleportPlaceId1, false)
    self._proxy:AddTimerTask(2, function()
        self._proxy:SetSceneObjectActive(teleportPlaceId1, true)
    end)
    if rot then
        XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(self._proxy, self._proxy:GetLocalPlayerNpcId(), pos, rot, 0.5, 0, 300012, cb)
    else
        XScriptTool.DoTeleportNpcPosWithBlackScreen(self._proxy, self._proxy:GetLocalPlayerNpcId(), pos, 0.5, 0, 300012)
    end
end

function XLevelScript6001:SetMoveLimitActive(active)
    for _, Limit in pairs(self._MoveLimit) do
        self._proxy:SetSceneObjectActive(Limit,active)
    end
end

return XLevelScript6001
