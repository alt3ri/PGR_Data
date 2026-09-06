---@class XPartnerNetWorkControl : XControl
---@field private _Model XPartnerModel
---@field private _MainControl XPartnerControl
--- 网络唯一出口：委托 XPartnerManager 已有接口，回包后走 OnXxxReply 派发事件（带 isSuccess）
local XPartnerNetWorkControl = XClass(XControl, "XPartnerNetWorkControl")

function XPartnerNetWorkControl:OnInit()
end

function XPartnerNetWorkControl:AddAgencyEvent()
end

function XPartnerNetWorkControl:RemoveAgencyEvent()
end

function XPartnerNetWorkControl:OnRelease()
end



--region 一键养成网络请求

--- 伙伴升级（喂经验）
---@param partnerId number
---@param useItems table<{Id: number, Count: number}>
function XPartnerNetWorkControl:SendLevelUpRequest(partnerId, useItems)
    XDataCenter.PartnerManager.PartnerLevelUpRequest(partnerId, useItems, function()
        self:OnLevelUpReply(true)
    end, function()
        self:OnLevelUpReply(false)
    end)
end

---@param isSuccess boolean
function XPartnerNetWorkControl:OnLevelUpReply(isSuccess)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_LEVEL_UP, isSuccess)
end

--- 伙伴突破（升阶，提升等级上限）
---@param partnerId number
function XPartnerNetWorkControl:SendBreakThroughRequest(partnerId)
    XDataCenter.PartnerManager.PartnerBreakThroughRequest(partnerId, function()
        self:OnBreakThroughReply(true)
    end, function()
        self:OnBreakThroughReply(false)
    end)
end

---@param isSuccess boolean
function XPartnerNetWorkControl:OnBreakThroughReply(isSuccess)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_BREAK_THROUGH, isSuccess)
end

--- 伙伴星数进度激活（喂狗粮，累积碎片进度）
---@param partnerId number
---@param costPartnerIds number[] 被消耗的辅助机 Id 列表
function XPartnerNetWorkControl:SendStarActivateRequest(partnerId, costPartnerIds)
    XDataCenter.PartnerManager.PartnerStarActivateRequest(partnerId, costPartnerIds, function()
        self:OnStarActivateReply(true)
    end, function()
        self:OnStarActivateReply(false)
    end)
end

---@param isSuccess boolean
function XPartnerNetWorkControl:OnStarActivateReply(isSuccess)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_STAR_ACTIVATE, isSuccess)
end

--- 伙伴进化（升星，品质提升）
---@param partnerId number
function XPartnerNetWorkControl:SendEvolutionRequest(partnerId)
    XDataCenter.PartnerManager.PartnerEvolutionRequest(partnerId, function()
        self:OnEvolutionReply(true)
    end, function()
        self:OnEvolutionReply(false)
    end)
end

---@param isSuccess boolean
function XPartnerNetWorkControl:OnEvolutionReply(isSuccess)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_EVOLUTION, isSuccess)
end

--- 伙伴技能升级
---@param partnerId number
---@param skillId number
---@param count number 升级次数
function XPartnerNetWorkControl:SendSkillUpRequest(partnerId, skillId, count)
    XDataCenter.PartnerManager.PartnerSkillUpRequest(partnerId, skillId, count, function()
        self:OnSkillUpReply(true)
    end, function(errorCode)
        self:OnSkillUpReply(false, errorCode)
    end)
end

---@param isSuccess boolean
---@param errorCode number|nil
function XPartnerNetWorkControl:OnSkillUpReply(isSuccess, errorCode)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_SKILL_UP, isSuccess, errorCode)
end

--- 伙伴技能穿戴
---@param partnerId number
---@param skillDic table<number, boolean> key 为技能 Id，value 为是否穿戴
---@param skillType number
function XPartnerNetWorkControl:SendSkillWearRequest(partnerId, skillDic, skillType)
    XDataCenter.PartnerManager.PartnerSkillWearRequest(partnerId, skillDic, skillType, function()
        self:OnSkillWearReply(false)
    end, function()
        self:OnSkillWearReply(true)
    end)
end

---@param isSuccess boolean
function XPartnerNetWorkControl:OnSkillWearReply(isSuccess)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_SKILL_WEAR, isSuccess)
end

--- 碎片合成辅助机（兑换）
---@param templateIds number[] 辅助机模板Id列表（每个元素 = 一次合成）
function XPartnerNetWorkControl:SendChipExchangeRequest(templateIds)
    XNetwork.Call("PartnerComposeRequest", { TemplateIds = templateIds, IsOneKey = false }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:OnChipExchangeReply(false)
            return
        end
        self:OnChipExchangeReply(true)
    end)
end

---@param isSuccess boolean
function XPartnerNetWorkControl:OnChipExchangeReply(isSuccess)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_CHIP_EXCHANGE, isSuccess)
end

--endregion

return XPartnerNetWorkControl
