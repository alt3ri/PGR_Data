---@class XSGCafeBuff : XEntity 咖啡厅的Buff基类
---@field _BuffId number
---@field _Card XSkyGardenCafeCardEntity
---@field _OwnControl XSGCafeBuffFactory
---@field _Model XSkyGardenCafeModel
---@field _Params number[]
local XSGCafeBuff = XClass(XEntity, "XSGCafeBuff")

local CardContainer = XMVCA.XSkyGardenCafe.CardContainer
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

local tableUnpack = table.unpack

function XSGCafeBuff:OnInit(buffId, card)
    self._BuffId = buffId
    self._Card = card
    
    --buff执行的次数
    self._EffectCount = 0
    --buff最大执行次数
    self._MaxEffectCount = 1
    
    --buff预览的次数
    self._PreviewCount = 0
    --buff最大预览次数
    self._MaxPreviewCount = 1
    
    self._IsRunning = false
    
    self._TriggerId = self._Model:GetEffectTriggerId(buffId)
    self._Params = self._Model:GetEffectParams(buffId)

    local agency = XMVCA.XSkyGardenCafe
    agency:AddInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_RESET_BUFF_PREVIEW, self.DoPreviewReset, self)
    agency:AddInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.DoPreviewReset, self)
    
    self:OnAwake()
end

function XSGCafeBuff:OnAwake()
end

function XSGCafeBuff:OnDestroy()
end

function XSGCafeBuff:OnRelease()
    self:DoDismiss()
    local agency = XMVCA.XSkyGardenCafe
    agency:RemoveInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_RESET_BUFF_PREVIEW, self.DoPreviewReset, self)
    agency:RemoveInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.DoPreviewReset, self)
    self:OnDestroy()
    
    self._BuffId = 0
    self._TriggerId = 0
    self._Card = nil
    self._EffectCount = 0
    self._PreviewCount = 0
end

function XSGCafeBuff:IsDisposed()
    return self._BuffId == 0
end

function XSGCafeBuff:DoApply(triggerDict, triggerArgDict)
    if XTool.IsTableEmpty(triggerDict) then
        return
    end
    if not triggerDict[self._TriggerId] then
        return
    end
    --已经触发了
    if self._EffectCount >= self._MaxEffectCount then
        return
    end
    if self._IsRunning then
        return
    end
    local args = triggerArgDict and triggerArgDict[self._TriggerId] or nil
    if not self:CheckCondition(false, args) then
        return
    end
    self._Args = args
    self._IsRunning = true
    for _ = 1, self._MaxEffectCount do
        self:OnApply()
    end
    if self._EffectCount > 0 then
        self:AddBuffArgs()
    end
    self._IsRunning = false

    self:DoPreviewReset()
    self._OwnControl:GetMainControl():RefreshContainer(CardContainer.Deck)
    self._OwnControl:GetMainControl():RefreshContainer(CardContainer.Deal)

    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD)
end

--- 不检查直接触发
function XSGCafeBuff:DoApplyNoCheck()
    --已经触发了
    if self._EffectCount >= self._MaxEffectCount then
        return
    end
    if self._IsRunning then
        return
    end
    for _ = 1, self._MaxEffectCount do
        self:OnApply()
    end
    if self._EffectCount > 0 then
        self:AddBuffArgs()
    end
    self._IsRunning = false

    self:DoPreviewReset()
    self._OwnControl:GetMainControl():RefreshContainer(CardContainer.Deck)
    self._OwnControl:GetMainControl():RefreshContainer(CardContainer.Deal)

    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD)
end

function XSGCafeBuff:DoDismiss()
    if self._EffectCount <= 0 then
        return
    end
    self._IsRunning = true
    for _ = 1, self._EffectCount do
        self:OnDismiss()
    end
    self._IsRunning = false
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD)
end

function XSGCafeBuff:DoPreview(triggerDict, triggerArgDict)
    if XTool.IsTableEmpty(triggerDict) then
        return
    end
    if not triggerDict[self._TriggerId] then
        return
    end
    --已经预览了 || 已经触发了
    if self._PreviewCount >= self._MaxPreviewCount
            or self._EffectCount >= self._MaxEffectCount then
        return
    end
    if self._IsRunning then
        return
    end
    local args = triggerArgDict and triggerArgDict[self._TriggerId] or nil
    if not self:CheckCondition(true, args) then
        return
    end
    self._IsRunning = true
    for _ = 1, self._MaxPreviewCount do
        self:OnPreview()
    end
    if self._PreviewCount > 0 then
        self:AddBuffArgs()
    end
    self._IsRunning = false

    self._OwnControl:GetMainControl():RefreshContainer(CardContainer.Deck)
end

function XSGCafeBuff:OnApply()
end

function XSGCafeBuff:OnDismiss()
end

function XSGCafeBuff:OnPreview()
end

function XSGCafeBuff:OnPreviewReset()
end

function XSGCafeBuff:DoPreviewReset()
    self._PreviewCount = self._EffectCount
    self._MaxPreviewCount = self._MaxEffectCount
    
    self:OnPreviewReset()
end

function XSGCafeBuff:AddBuffArgs()
end

--- buff当前回合不执行时，添加到下回合再执行
function XSGCafeBuff:TryAddNextRoundBuff()
    if not self._LeftRound then
        return false
    end
    local round = self._Model:GetBattleInfo():GetRound()
    --当前回合已经添加了
    if round == self._AddRound then
        return true
    end
    --可以执行具体Buff逻辑
    if self._LeftRound <= 0 then
        return false
    end
    self._LeftRound = self._LeftRound - 1
    --添加到下回合执行
    --如何buff绑定在卡牌上，buff会在卡牌销毁时被移除掉，所以这里重新创建
    self._OwnControl:GetMainControl():AddNextRoundBuff(self._BuffId, self._Card)
    self._AddRound = round
    return true
end

function XSGCafeBuff:SubLeftRound()
    if not self._LeftRound then
        return
    end
    self._LeftRound = math.min(self._LeftRound - 1, 0)
end

--- 检测Buff能否被触发
---@param isPreview boolean 是否为预览
---@return boolean
function XSGCafeBuff:CheckCondition(isPreview, args)
    local conditions = self._Model:GetEffectConditions(self._BuffId)
    if XTool.IsTableEmpty(conditions) then
        return true
    end
    local success = true
    local control = self._OwnControl:GetMainControl():GetMainControl()
    for _, conditionId in pairs(conditions) do
        local res, _ = control:CheckCondition(conditionId, self._Card, isPreview, args)
        if not res then
            success = false
            break
        end
    end
    return success
end

function XSGCafeBuff:ChangeEffectCount(isPreview, cnt)
    if isPreview then
        self._PreviewCount = self._PreviewCount + cnt
    else
        self._EffectCount = self._EffectCount + cnt
    end
end

function XSGCafeBuff:ChangeMaxEffectCount(isPreview, cnt)
    if isPreview then
        self._MaxPreviewCount = cnt
    else
        self._MaxEffectCount = cnt
    end
end

function XSGCafeBuff:GetEffectCount(isPreview)
    return isPreview and self._PreviewCount or self._EffectCount
end

function XSGCafeBuff:GetMaxEffectCount(isPreview)
    return isPreview and self._MaxPreviewCount or self._MaxEffectCount
end

function XSGCafeBuff:GetExtraValue()
end

function XSGCafeBuff:GetBuffId()
    return self._BuffId
end

function XSGCafeBuff:GetCardId()
    if self._Card then
        return self._Card:GetCardId()
    end
    return 0
end

function XSGCafeBuff:GetParamList(startIndex, check)
    local list = {}
    while true do
        local value = self._Params[startIndex]
        if not check(value) then
            break
        end
        list[#list + 1] = value
        startIndex = startIndex + 1
    end
    return list
end

function XSGCafeBuff:GetParamDict(startIndex, check)
    local dict = {}
    while true do
        local value = self._Params[startIndex]
        if not check(value) then
            break
        end
        dict[value] = true
        startIndex = startIndex + 1
    end
    return dict
end

return XSGCafeBuff