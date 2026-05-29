local Base = require("Common/XBigWorldCharBase")

---阿尔法邀约选项控制脚本
---@class XNPC_AlphaChoice : XBigWorldCharBase
local XNPC_AlphaChoice = XDlcScriptManager.RegCharScript(6087, "XNPC_AlphaChoice", Base)

local EAlphaInviteSaveKey = {
    Slash = 1,
    ShowOptionOne = 2,
}

function XNPC_AlphaChoice:CommonInit()
    Base.CommonInit(self)
    self._placeId = self._proxy:GetNpcPlaceId()
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractCountDownFinish)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)
    self._proxy:SetNpcInteractOptionActive(self._placeId,1,false)
    self._proxy:SetNpcInteractOptionActive(self._placeId,2,false)
    self._proxy:SetNpcInteractOptionActive(self._placeId,4,false)

    -- 保存slash和showOption记录状态
    self._proxy:RegisterBBSync(XVarDomain.Npc, self._uuid, EAlphaInviteSaveKey.Slash)
    self._proxy:RegisterBBSync(XVarDomain.Npc, self._uuid, EAlphaInviteSaveKey.ShowOptionOne)
    local _, isSlash = self._proxy:TryGetBBInt(XVarDomain.Npc, self._uuid, EAlphaInviteSaveKey.Slash)
    self._isSlash = isSlash
    local _, isShowOptionOne = self._proxy:TryGetBBInt(XVarDomain.Npc, self._uuid, EAlphaInviteSaveKey.ShowOptionOne)
    self._isShowOptionOne = isShowOptionOne
end

function XNPC_AlphaChoice:Update(dt)
    self:InteractCheck()
    if self._proxy:IsQuestObjectiveFinished(40400306) or self._proxy:IsQuestObjectiveFinished(40400206)then
        self._proxy:SetObstacleGroupActive(3700001,true)
    end

    if  self._proxy:IsQuestObjectiveFinished(40400407) then
        self._proxy:SetObstacleGroupActive(3700001,false)
    end
end

function XNPC_AlphaChoice:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractComplete and eventArgs.TargetPlaceId == self._placeId then
        if eventArgs.OptionId == 1 then
            self._proxy:PlayDramaCaption("Caption201508",true)
            self._proxy:AddTimerTask(8,function()  self._proxy:SetNpcInteractOptionActive(self._placeId,2,true) end )
        end

        if eventArgs.OptionId == 2 then
            self._proxy:PlayDramaCaption("Caption201510",true)
            self._proxy:AddTimerTask(10,function()  self._proxy:SetNpcInteractOptionActive(self._placeId,4,true) end )
        end


        if eventArgs.OptionId == 4 then
            self._proxy:PlayDramaCaption("Caption201513",true)
            --------播放字幕Caption201513
        end

    end
end


function XNPC_AlphaChoice:InteractCheck()
    if self._isShowOptionOne > 0 then
        return
    end
    if self._proxy:IsQuestObjectiveFinished(40400306)
            or self._proxy:IsQuestObjectiveFinished(40400206)
    then
        self._isShowOptionOne = 1
        self._proxy:SetNpcInteractOneOptionActive(self._placeId,1,true)
    end
end


return XNPC_AlphaChoice
