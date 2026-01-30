---@class XSkyGardenCafeCardEntity : XEntity 卡牌
---@field _OwnControl XSkyGardenCafeCardFactory
---@field _Model XSkyGardenCafeModel
---@field _Id number
---@field _BuffEntities XSGCafeBuff[]
---@field _AttachBuffEntities table[]
---@field _ChildCard XSkyGardenCafeCardEntity[] 携带的子牌
local XSkyGardenCafeCardEntity = XClass(XEntity, "XSkyGardenCafeCardEntity")

local DlcEventId = XMVCA.XBigWorldService.DlcEventId

local Pattern = XMVCA.XSkyGardenCafe.Pattern

local IsDebugBuild = CS.XApplication.Debug

local CardResourceChangedTriggerId = { [XMVCA.XSkyGardenCafe.EffectTriggerId.CardResourceChanged] = true }

local NotDisplayResourceType = -1

function XSkyGardenCafeCardEntity:OnInit(id)
    self._Id = id
    --当前coffee量
    self._CurrentCoffee = self._Model:GetCustomerCoffee(id)
    --buff实际增加的coffee
    self._BuffCoffee = 0
    --buff预览增加的coffee
    self._PreviewBuffCoffee = 0
    --当前预览coffee
    self._PreviewCurCoffee = self._Model:GetCustomerCoffee(id)

    --当前review量
    self._CurrentReview = self._Model:GetCustomerReview(id)
    --buff增加的review
    self._BuffReview = 0
    --buff预览增加的review
    self._PreviewBuffReview = 0
    --当前预览coffee
    self._PreviewCurReview = self._Model:GetCustomerReview(id)

    self._BuffEntities = {}
    
    self._NpcUUId = 0

    self._ChildCard = {}
    self._BuffArgs = {}
    self._ReplaceHandler = handler(self, self.ReplaceHandler)
    local agency = XMVCA.XSkyGardenCafe
    agency:AddInnerEvent(DlcEventId.EVENT_CAFE_RESET_BUFF_PREVIEW, self.OnPreviewReset, self)
    agency:AddInnerEvent(DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.OnPreviewReset, self)

    self:InitBuff()
end

function XSkyGardenCafeCardEntity:IsDisposed()
    return self._Id <= 0
end

function XSkyGardenCafeCardEntity:OnRelease()
    self._NpcUUId = 0
    local agency = XMVCA.XSkyGardenCafe
    agency:RemoveInnerEvent(DlcEventId.EVENT_CAFE_RESET_BUFF_PREVIEW, self.OnPreviewReset, self)
    agency:RemoveInnerEvent(DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.OnPreviewReset, self)
    self:ReleaseBuff()
    self:ClearBuffArgs()
    self._Id = 0
end


--region 配置获取

function XSkyGardenCafeCardEntity:GetCardId()
    return self._Id
end

function XSkyGardenCafeCardEntity:GetCardType()
    return self._Model:GetCustomerType(self._Id)
end

function XSkyGardenCafeCardEntity:IsNotDisplayResourceType()
    return self:GetCardType() == NotDisplayResourceType
end

function XSkyGardenCafeCardEntity:GetCardQuality()
    return self._Model:GetCustomerQuality(self._Id)
end

function XSkyGardenCafeCardEntity:IsMaxQuality()
    return self._Model:IsMaxQuality(self._Id)
end

function XSkyGardenCafeCardEntity:IsReDrawCard()
    return self._Model:IsReDrawCustomer(self._Id)
end

--- 获取卡牌的细节描述
---@return string
function XSkyGardenCafeCardEntity:GetCustomerDetails()
    local detail
    if self._DetailDesc then
        detail = self._DetailDesc
    else
        detail = self._Model:GetCustomerDetails(self._Id)
    end
    return XUiHelper.ReplaceTextNewLine(detail:gsub(Pattern, self._ReplaceHandler))
end

--- 获取卡牌的配置描述
---@return string
function XSkyGardenCafeCardEntity:GetCustomerDesc()
    local desc = self._Model:GetCustomerDesc(self._Id)
    return XUiHelper.ReplaceTextNewLine(desc)
end

--endregion


--region 销量

function XSkyGardenCafeCardEntity:GetTotalCoffee(isPreview)
    return self:GetOriginCoffee(isPreview) + self:GetAddCoffee(isPreview)
end

--- 该卡牌基础销量
---@return number
function XSkyGardenCafeCardEntity:GetOriginCoffee(isPreview)
    return isPreview and math.floor(self._PreviewCurCoffee) or math.floor(self._CurrentCoffee)
end

--- 该卡牌增益销量
---@return number
function XSkyGardenCafeCardEntity:GetAddCoffee(isPreview)
    local own
    if isPreview then
        own = self._PreviewBuffCoffee
    else
        own = self._BuffCoffee
    end
    if not XTool.IsTableEmpty(self._ChildCard) then
        for _, child in pairs(self._ChildCard) do
            own = own + child:GetTotalCoffee(isPreview)
        end
    end
    local value = self._Model:GetBattleInfo():GetCardForeverData(self:GetCardId(), true)
    return math.floor(own + value)
end

--- 根据百分比获取基础增益销量
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddBasicCoffeeByPercent(percent, isPreview)
    local oldValue = self:GetOriginCoffee(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 根据百分比获取最终增益销量
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddFinalCoffeeByPercent(percent, isPreview)
    local oldValue = self:GetTotalCoffee(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 增加基础销量
---@param value number
function XSkyGardenCafeCardEntity:AddBasicCoffee(value, isPreview)
    if not value or value == 0 then
        return
    end

    if isPreview then
        self._PreviewCurCoffee = self._PreviewCurCoffee + value
        self:DoPreviewBuff(CardResourceChangedTriggerId)
    else
        self._CurrentCoffee = self._CurrentCoffee + value
        self:OnPreviewReset()
        self:DoApplyBuff(CardResourceChangedTriggerId)
        self._OwnControl:GetMainControl():PlayResourceChange(self, value, 0)
    end

end

--- 增加最终销量
---@param value number
function XSkyGardenCafeCardEntity:AddFinalCoffee(value, isPreview)
    if not value or value == 0 then
        return
    end

    if isPreview then
        self._PreviewBuffCoffee = self._PreviewBuffCoffee + value
        self:DoPreviewBuff(CardResourceChangedTriggerId)
    else
        self._BuffCoffee = self._BuffCoffee + value
        self:OnPreviewReset()
        self:DoApplyBuff(CardResourceChangedTriggerId)
        self._OwnControl:GetMainControl():PlayResourceChange(self, value, 0)
    end
end

--- 添加永久销量
---@param value number
function XSkyGardenCafeCardEntity:AddForeverCoffee(value)
    local battleInfo = self._Model:GetBattleInfo()
    battleInfo:ChangeCardForeverData(self._Id, true, value)
    self._OwnControl:GetMainControl():PlayResourceChange(self, value, 0)
end

--endregion


--region 好评

--- 该卡牌实际总好评
---@return number
function XSkyGardenCafeCardEntity:GetTotalReview(isPreview)
    return self:GetOriginReview(isPreview) + self:GetAddReview(isPreview)
end

--- 该卡牌基础好评
---@return number
function XSkyGardenCafeCardEntity:GetOriginReview(isPreview)
    return isPreview and math.floor(self._PreviewCurReview)
            or math.floor(self._CurrentReview)
end

--- 该卡牌增益好评
---@return number
function XSkyGardenCafeCardEntity:GetAddReview(isPreview)
    local own
    if isPreview then
        own = self._PreviewBuffReview
    else
        own = self._BuffReview
    end
    if not XTool.IsTableEmpty(self._ChildCard) then
        for _, child in pairs(self._ChildCard) do
            own = own + child:GetTotalReview(isPreview)
        end
    end
    local value = self._Model:GetBattleInfo():GetCardForeverData(self:GetCardId(), false)
    return math.floor(own + value)
end

--- 根据百分比获取基础增益好评
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddBasicReviewByPercent(percent, isPreview)
    local oldValue = self:GetOriginReview(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 根据百分比获取最终增益好评
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddFinalReviewByPercent(percent, isPreview)
    local oldValue = self:GetTotalReview(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 增加基础好评
---@param value number
function XSkyGardenCafeCardEntity:AddBasicReview(value, isPreview)
    if not value or value == 0 then
        return
    end
    if isPreview then
        self._PreviewCurReview = self._PreviewCurReview + value
        self:DoPreviewBuff(CardResourceChangedTriggerId)
    else
        self._CurrentReview = self._CurrentReview + value
        self:OnPreviewReset()
        self:DoApplyBuff(CardResourceChangedTriggerId)
        self._OwnControl:GetMainControl():PlayResourceChange(self, 0, value)
    end
end

--- 增加最终好评
---@param value number
function XSkyGardenCafeCardEntity:AddFinalReview(value, isPreview)
    if not value or value == 0 then
        return
    end
    if isPreview then
        self._PreviewBuffReview = self._PreviewBuffReview + value
        self:DoPreviewBuff(CardResourceChangedTriggerId)
    else
        self._BuffReview = self._BuffReview + value
        self:OnPreviewReset()
        self:DoApplyBuff(CardResourceChangedTriggerId)
        self._OwnControl:GetMainControl():PlayResourceChange(self, 0, value)
    end
end

--- 添加永久销量
---@param value number
function XSkyGardenCafeCardEntity:AddForeverReview(value)
    local battleInfo = self._Model:GetBattleInfo()
    battleInfo:ChangeCardForeverData(self._Id, false, value)
    self._OwnControl:GetMainControl():PlayResourceChange(self, 0, value)
end

--endregion


--region Buff操作

function XSkyGardenCafeCardEntity:InitBuff()
    local buffIds = self._Model:GetCustomerBuffIds(self._Id)
    if XTool.IsTableEmpty(buffIds) then
        return
    end
    local factory = self._OwnControl:GetMainControl():GetBuffFactory()
    for _, buffId in pairs(buffIds) do
        local buff = factory:CreateBuff(buffId, self)
        self._BuffEntities[#self._BuffEntities + 1] = buff
    end
end

function XSkyGardenCafeCardEntity:ReleaseBuff()
    if XTool.IsTableEmpty(self._BuffEntities) then
        return
    end
    local factory = self._OwnControl:GetMainControl():GetBuffFactory()
    for _, buff in pairs(self._BuffEntities) do
        factory:RemoveEntity(buff)
    end
    self._BuffEntities = nil
end

function XSkyGardenCafeCardEntity:DoPreviewBuff(triggerDict, triggerArgDict)
    if XTool.IsTableEmpty(self._BuffEntities) then
        return
    end
    for _, buff in pairs(self._BuffEntities) do
        buff:DoPreview(triggerDict, triggerArgDict)
    end
end

function XSkyGardenCafeCardEntity:DoApplyBuff(triggerDict, triggerArgDict)
    if XTool.IsTableEmpty(self._BuffEntities) then
        return
    end
    for _, buff in pairs(self._BuffEntities) do
        buff:DoApply(triggerDict, triggerArgDict)
    end
end

--- 给卡牌附加Buff
---@param buff XSGCafeBuff
function XSkyGardenCafeCardEntity:AttachBuff(buff, count)
    if not count or count <= 0 then
        return
    end
    buff:ChangeMaxEffectCount(true, count)
    buff:ChangeMaxEffectCount(false, count)
    self._BuffEntities[#self._BuffEntities + 1] = buff
end

function XSkyGardenCafeCardEntity:IsBuffApply(buffId, count, isPreview)
    if XTool.IsTableEmpty(self._BuffEntities) then
        return false
    end
    for _, buff in pairs(self._BuffEntities) do
        if buff:GetBuffId() == buffId then
            return buff:GetEffectCount(isPreview) == count
        end
    end
    return false
end

function XSkyGardenCafeCardEntity:AttachChildCard(card)
    if not card then
        return
    end
    self._ChildCard[#self._ChildCard + 1] = card
end

function XSkyGardenCafeCardEntity:PrintBuff()
    if not IsDebugBuild then
        return
    end
    local log = {}
    for _, buff in pairs(self._BuffEntities) do
        log[#log + 1] = string.format("[Id = %s, 执行次数: %s, 预览次数: %s]", buff:GetBuffId(), buff:GetEffectCount(false),
                buff:GetEffectCount(true))
    end
    XLog.Warning(string.format("[%s(%s)]:\n\t最终\t基础\n销量:\t%s\t%s\n好评:\t%s\t%s\nBuff信息: \n%s",
            self._OwnControl:GetMainControl():GetMainControl():GetCustomerName(self._Id), self._Id,
            self:GetTotalCoffee(true), self._Model:GetCustomerCoffee(self._Id),
            self:GetTotalReview(true), self._Model:GetCustomerReview(self._Id),
            table.concat(log, "\n")))
end

--endregion


--region Buff参数

function XSkyGardenCafeCardEntity:OnPreviewReset()
    self._PreviewBuffCoffee = self._BuffCoffee
    self._PreviewCurCoffee = self._CurrentCoffee

    self._PreviewBuffReview = self._BuffReview
    self._PreviewCurReview = self._CurrentReview
end

function XSkyGardenCafeCardEntity:AddBuffArgs(key, value)
    self._BuffArgs[key] = value
end

function XSkyGardenCafeCardEntity:ClearBuffArgs()
    if XTool.IsTableEmpty(self._BuffArgs) then
        return
    end
    for key, _ in pairs(self._BuffArgs) do
        self._BuffArgs[key] = nil
    end
    self._DetailDesc = false
end

function XSkyGardenCafeCardEntity:SetCustomerDetails(value)
    self._DetailDesc = value
end
--endregion


--region 工具函数

function XSkyGardenCafeCardEntity:ReplaceHandler(strKey)
    if XTool.IsTableEmpty(self._BuffArgs) then
        return 0
    end
    local v = self._BuffArgs[tonumber(strKey)]
    if not v then
        return 0
    end
    return v
end

function XSkyGardenCafeCardEntity:IsResourceChanged()
    local total = self:GetTotalReview(false)
    local config = self._Model:GetCustomerCoffee(self._Id)
    if total ~= config then
        return true
    end
    total = self:GetTotalCoffee(false)
    config = self._Model:GetCustomerReview(self._Id)
    return total ~= config
end

function XSkyGardenCafeCardEntity:SetNpcUUId(uuId)
    self._NpcUUId = uuId
end

function XSkyGardenCafeCardEntity:GetNpcUUId()
    return self._NpcUUId
end

--endregion



---@class XSkyGardenCafeCardFactory : XEntityControl 卡牌管理
---@field _MainControl XSkyGardenCafeBattle
---@field _Model XSkyGardenCafeModel
local XSkyGardenCafeCardFactory = XClass(XEntityControl, "XSkyGardenCafeCardFactory")

function XSkyGardenCafeCardFactory:OnInit()
end

function XSkyGardenCafeCardFactory:OnRelease()
end

function XSkyGardenCafeCardFactory:CreateCard(id)
    return self:AddEntity(XSkyGardenCafeCardEntity, id)
end

function XSkyGardenCafeCardFactory:GetMainControl()
    return self._MainControl
end

return XSkyGardenCafeCardFactory