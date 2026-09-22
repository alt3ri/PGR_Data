---@class XPartnerAgency : XAgency
---@field private _Model XPartnerModel
---@field public EventIds XPartnerEventId
---@field public Enum XPartnerEnum
---@field public Util XPartnerUtil
---@field private _OneKeyCultureAgency XPartnerOneKeyCultureAgency
---@field private _ConfigAgency XPartnerConfigAgency
local XPartnerAgency = XClass(XAgency, "XPartnerAgency")

function XPartnerAgency:OnInit()
    --挂载枚举/事件/工具
    self.EventIds = require('XModule/XPartner/XPartnerEventId')
    self.Enum     = require('XModule/XPartner/XPartnerEnum')
    self.Util     = require('XModule/XPartner/XPartnerUtil')

    --子Agency
    self._ConfigAgency = self:AddSubAgency(require("XModule/XPartner/Agency/XPartnerConfigAgency"))
    self._OneKeyCultureAgency = self:AddSubAgency(require("XModule/XPartner/Agency/XPartnerOneKeyCultureAgency"))
end


function XPartnerAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX or self:AddRpc
end

function XPartnerAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end


--region ----------public start----------

--- 获取配置子Agency
---@return XPartnerConfigAgency
function XPartnerAgency:GetConfigAgency()
    return self._ConfigAgency
end

--- 获取一键培养子Agency
---@return XPartnerOneKeyCultureAgency
function XPartnerAgency:GetOneKeyCultureAgency()
    return self._OneKeyCultureAgency
end

--- 打开辅助机一键培养界面（先预拉取自动兑换涉及的商店数据，兑换代币配置在商店商品的 ConsumeList 上，无商店数据无法计算兑换）
---@param partnerId number 辅助机实例 Id
function XPartnerAgency:OpenOneKeyCultureUI(partnerId)
    if partnerId then
        self._Model:GetOneKeyCultureModel():SetCurPartnerId(partnerId)
    end
    local allShopIds = { XShopManager.MaterialShopId }
    self:_CollectChipExchangeShopId(allShopIds)
    --先拉商店基础信息(含 ConditionIds),才能判断玩家是否满足商店开放条件
    XShopManager.GetBaseInfo(function()
        local shopIds = {}
        for _, shopId in ipairs(allShopIds) do
            if XShopManager.IsShopUnlock(shopId) then
                table.insert(shopIds, shopId)
            end
        end
        if #shopIds == 0 then
            XLuaUiManager.Open("UiEquipOneClickCulturePartnerMain")
            return
        end
        --只对玩家已满足开放条件的商店请求有效信息,避免未解锁商店触发服务器异常
        XShopManager.RequestShopValidInfo(shopIds, function()
            XShopManager.GetShopInfoList(shopIds, function()
                XLuaUiManager.Open("UiEquipOneClickCulturePartnerMain")
            end, XShopManager.ShopType.Common, true)
        end)
    end)
end

--endregion ----------public end----------


--region ----------private start----------

--- 收集当前辅助机碎片自动兑换（矿石换碎片）所在商店 Id，加入预拉列表
---@param shopIds number[]
function XPartnerAgency:_CollectChipExchangeShopId(shopIds)
    local curPartnerId = self._Model:GetOneKeyCultureModel():GetCurPartnerId()
    if not XTool.IsNumberValid(curPartnerId) then
        return
    end
    local partner = XDataCenter.PartnerManager.GetPartnerEntityById(curPartnerId)
    if not partner then
        return
    end
    local cfg = XItemConfigs.GetItemAutoExchangeById(partner:GetChipItemId())
    if not cfg or not XTool.IsNumberValid(cfg.ShopId) then
        return
    end
    for _, shopId in ipairs(shopIds) do
        if shopId == cfg.ShopId then
            return
        end
    end
    table.insert(shopIds, cfg.ShopId)
end

--endregion ----------private end----------

return XPartnerAgency