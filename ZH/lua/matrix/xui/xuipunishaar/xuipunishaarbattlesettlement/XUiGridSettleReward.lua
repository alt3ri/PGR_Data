---@class XUiGridSettleReward: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field RImgTool1 UnityEngine.UI.RawImage 奖励图标（按 RewardType 取，RewardTypeIcons/ClientRewardTypeIcons 两 key；"0"/空占位隐藏）
---@field TxtReward UnityEngine.UI.Text 奖励描述文本（按 RewardType）
---@field Txt UnityEngine.UI.Text 奖励数值变化显示（Amount）
local XUiGridSettleReward = XClass(XUiNode, "XUiGridSettleReward")

--- 刷新奖励 grid。
---@param rewardGoods table XPunishaarRewardGoods（{ RewardType, CardId, Level, MasterCardId, Amount }）
function XUiGridSettleReward:Refresh(rewardGoods)
    if not rewardGoods then
        if self.TxtReward then self.TxtReward.text = "" end
        if self.Txt then self.Txt.text = "" end
        if self.RImgTool1 then self.RImgTool1.gameObject:SetActiveEx(false) end
        return
    end

    local RewardType = XMVCA.XPunishaar.EnumConst.RewardType
    local rt = rewardGoods.RewardType

    local desc = ""

    -- 纯客户端自定义部分需特殊拿
    if rewardGoods.RewardType > 100 then
        local clientRewardType = rewardGoods.RewardType - 100

        desc = XMVCA.XPunishaar:GetClientStringByKey("ClientRewardTypeNames", clientRewardType)
    else
        desc = XMVCA.XPunishaar:GetClientStringByKey("RewardTypeNames", rewardGoods.RewardType)
    end

    -- 数值变化：Amount（金币增量/槽位解锁数/MaxHp 增量等）；卡牌类无 Amount 则显等级
    if self.Txt then
        if rt == RewardType.MasterCard or rt == RewardType.SubCard then
            if self.TxtReward then
                local cardCfg = self._Control:GetTablePunishaarCard(rewardGoods.CardId)
                local cardName = cardCfg and cardCfg.Name or ""
                self.TxtReward.text = XUiHelper.FormatTextEx(desc, cardName)
            end

            self.Txt.text = rewardGoods.Level and tostring(rewardGoods.Level) or ""
        else
            self.Txt.text = tostring(rewardGoods.Amount or 0)

            if self.TxtReward then
                self.TxtReward.text = desc
            end
        end
    end

    -- 图标：同文本两 key 范式（>100 用 ClientRewardTypeIcons[RewardType-100]，≤100 用 RewardTypeIcons[RewardType]）
    -- "0"/空占位=无图，隐藏 RImgTool1；否则 SetRawImage 加载显示
    if self.RImgTool1 then
        local iconUrl
        if rewardGoods.RewardType > 100 then
            iconUrl = XMVCA.XPunishaar:GetClientStringByKey("ClientRewardTypeIcons", rewardGoods.RewardType - 100)
        else
            iconUrl = XMVCA.XPunishaar:GetClientStringByKey("RewardTypeIcons", rewardGoods.RewardType)
        end
        if string.IsNilOrEmpty(iconUrl) or iconUrl == "0" then
            self.RImgTool1.gameObject:SetActiveEx(false)
        else
            self.RImgTool1.gameObject:SetActiveEx(true)
            self.RImgTool1:SetRawImage(iconUrl)
        end
    end
end

return XUiGridSettleReward
