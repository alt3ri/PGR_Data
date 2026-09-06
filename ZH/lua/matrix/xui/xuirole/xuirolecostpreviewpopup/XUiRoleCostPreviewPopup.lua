--[[
-- XUiRoleCostPreviewPopup.lua
-- 通用消耗预览弹窗：按"角色等级/角色晋升/技能提升"分块展示消耗 + 自动兑换明细
-- 输入契约（OnStart 参数）：
--   { Sections = { {Title, CostList={{Id,Count,IsExchange},...}}, ... },
--     ExchangeList = { {ItemId, RewardCount, ConsumeList={{Id,Count},...}}, ... } }
-- 调用方负责把领域数据适配成上述格式，弹窗只做渲染。
--]]

local XUiPanelConsume = require("XUi/XUiRole/XUiRoleCostPreviewPopup/XUiPanelConsume")
local XUiRoleCostPreviewPopupGridExchange = require("XUi/XUiRole/XUiRoleCostPreviewPopup/XUiRoleCostPreviewPopupGridExchange")

local MAX_ASSET_COUNT = 3

-- 按 ConsumeList[1].Id 分组合并：同代币多项合并到一个 GridExchange，产出用多个 Grid256 展示
local function BuildExchangeList(exchangeList)
    local groupDic = {}
    local groupOrder = {}
    for _, info in ipairs(exchangeList or {}) do
        local consume = info.ConsumeList and info.ConsumeList[1]
        local consumeId = consume and consume.Id or 0
        local group = groupDic[consumeId]
        if not group then
            group = { ConsumeId = consumeId, ConsumeCount = 0, Rewards = {} }
            groupDic[consumeId] = group
            table.insert(groupOrder, group)
        end
        group.ConsumeCount = group.ConsumeCount + (consume and consume.Count or 0)
        table.insert(group.Rewards, { ItemId = info.ItemId, RewardCount = info.RewardCount })
    end
    table.sort(groupOrder, function(a, b) return a.ConsumeId < b.ConsumeId end)
    return groupOrder
end

---@class XUiRoleCostPreviewPopup : XLuaUi
---@field BtnCloseMask XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field PanelCost UnityEngine.RectTransform
---@field ListCost UnityEngine.RectTransform
---@field PanelConsume UnityEngine.RectTransform
---@field PanelExchange UnityEngine.RectTransform
---@field GridExchange UnityEngine.RectTransform
local XUiRoleCostPreviewPopup = XLuaUiManager.Register(XLuaUi, "UiRoleCostPreviewPopup")

function XUiRoleCostPreviewPopup:OnAwake()
    self:InitComponents()
end

function XUiRoleCostPreviewPopup:InitComponents()
    self.ConsumePanels = {}
    self.ExchangeGrids = {}

    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)

    -- PanelConsume 作为 template 隐藏,代码 Instantiate 三份
    self.PanelConsume.gameObject:SetActiveEx(false)
    self.GridExchange.gameObject:SetActiveEx(false)
end

function XUiRoleCostPreviewPopup:RefreshAssetPanel(exchangeList)
    if not self.PanelAsset then
        return
    end
    local consumeItemIds = {}
    for _, exchange in ipairs(exchangeList) do
        if XTool.IsNumberValid(exchange.ConsumeId) then
            table.insert(consumeItemIds, exchange.ConsumeId)
        end
    end
    if #consumeItemIds > MAX_ASSET_COUNT then
        XLog.Warning("XUiRoleCostPreviewPopup: Consume token count exceeds asset panel capacity.", consumeItemIds)
    end
    if self.AssetPanel then
        self.AssetPanel:RefreshBindItem(table.unpack(consumeItemIds))
    else
        self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset, table.unpack(consumeItemIds))
    end
end

--- @param data {Sections, ExchangeList}
function XUiRoleCostPreviewPopup:OnStart(data)
    self.Sections = (data and data.Sections) or table.empty
    self.ExchangeList = (data and data.ExchangeList) or table.empty
    self:Refresh()
end

function XUiRoleCostPreviewPopup:Refresh()
    local exchangeList = BuildExchangeList(self.ExchangeList)
    self:RefreshAssetPanel(exchangeList)
    self:RefreshConsumePanels(self.Sections)
    self:RefreshExchangeGrids(exchangeList)

    local hasExchange = not XTool.IsTableEmpty(exchangeList)
    self.PanelExchange.gameObject:SetActiveEx(hasExchange)
end

function XUiRoleCostPreviewPopup:RefreshConsumePanels(sections)
    XTool.UpdateDynamicItem(self.ConsumePanels, sections or {}, self.PanelConsume, XUiPanelConsume, self)
end

function XUiRoleCostPreviewPopup:RefreshExchangeGrids(exchangeList)
    XTool.UpdateDynamicItem(self.ExchangeGrids, exchangeList or {}, self.GridExchange, XUiRoleCostPreviewPopupGridExchange, self)
end

function XUiRoleCostPreviewPopup:OnBtnCloseClick()
    self:Close()
end

return XUiRoleCostPreviewPopup
