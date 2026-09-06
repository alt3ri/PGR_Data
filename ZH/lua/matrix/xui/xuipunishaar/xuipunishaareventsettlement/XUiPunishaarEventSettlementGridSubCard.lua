-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarEventSettlementGridSubCard : XUiNode
---@field PanelNone UnityEngine.RectTransform
---@field PanelSubCard UnityEngine.RectTransform
---@field IconSubCardRole UnityEngine.RectTransform
---@field BtnClick XUiComponent.XUiButton
---@field GridSubCard UnityEngine.RectTransform
---@field GridSubCardPets UnityEngine.UI.RawImage
---@field IconSubCardPats UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- v2 奖励阶段副卡 grid：纯展示奖励副卡。
--- 副卡奖励无装备/锁定/选中态，仅显 PanelSubCard 内容、隐 PanelNone 及交互/选中节点。
--- 副卡图标走 cardCfg.Icon，设置在可用的 RawImage（GridSubCardPets）上；
--- TODO: 预制体副卡 role/pats 图标节点绑定待确认，确认后改设 role 头像。
local XUiPunishaarEventSettlementGridSubCard = XClass(XUiNode, "XUiPunishaarEventSettlementGridSubCard")

function XUiPunishaarEventSettlementGridSubCard:OnStart()
    -- 奖励预览不响应点击/选中
    if self.BtnClick then
        self.BtnClick.gameObject:SetActiveEx(false)
    end
end

function XUiPunishaarEventSettlementGridSubCard:OnEnable()
end

function XUiPunishaarEventSettlementGridSubCard:OnDisable()
end

function XUiPunishaarEventSettlementGridSubCard:OnDestroy()
end

function XUiPunishaarEventSettlementGridSubCard:RegisterComponentListeners()
end

function XUiPunishaarEventSettlementGridSubCard:OnBtnClickClick()
end

--- 刷新副卡奖励展示。
---@param data table { CardId: number, Level: number }
function XUiPunishaarEventSettlementGridSubCard:Refresh(data)
    if not data or not XTool.IsNumberValid(data.CardId) then
        return
    end
    -- 显副卡内容、隐空位态
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(false)
    end
    if self.PanelSubCard then
        self.PanelSubCard.gameObject:SetActiveEx(true)
    end
    local cardCfg = XMVCA.XPunishaar:GetTablePunishaarCard(data.CardId)
    if cardCfg and not string.IsNilOrEmpty(cardCfg.Icon) then
        -- 优先 role 头像；预制体 binding 待确认，先用可用的 RawImage 兜底
        if self.GridSubCardPets then
            self.GridSubCardPets:SetRawImage(cardCfg.Icon)
        end
    end
end

return XUiPunishaarEventSettlementGridSubCard
