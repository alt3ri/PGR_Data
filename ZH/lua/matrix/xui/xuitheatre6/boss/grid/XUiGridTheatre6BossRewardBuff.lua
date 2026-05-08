---@class XUiGridTheatre6BossRewardBuff : XUiNode Boss奖励Grid - Buff
---@field _Control XTheatre6Control
local XUiGridTheatre6BossRewardBuff = XClass(XUiNode, "XUiGridTheatre6BossRewardBuff")

function XUiGridTheatre6BossRewardBuff:OnStart()

end

---@param buffId number BuffId (Theatre6StageBuff表)
function XUiGridTheatre6BossRewardBuff:Refresh(buffId)
    self._BuffId = buffId
    local buffConfig = self._Control:GetStageBuffCfgById(buffId)

    if buffConfig == nil then
        self._Control:ShowTip("buffConfig配置为空")
        return
    end
    
    self.UiRImgIcon:SetRawImage(buffConfig.Icon)
    self.UiImgUse.gameObject:SetActiveEx(false)
    self.UiImgSelect.gameObject:SetActiveEx(false)

end

return XUiGridTheatre6BossRewardBuff
