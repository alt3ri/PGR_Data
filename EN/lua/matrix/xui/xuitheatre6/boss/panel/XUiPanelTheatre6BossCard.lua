---@class XUiPanelTheatre6BossCard : XUiNode Boss基础信息卡片
---@field _Control XTheatre6Control
local XUiPanelTheatre6BossCard = XClass(XUiNode, "XUiPanelTheatre6BossCard")

function XUiPanelTheatre6BossCard:OnStart()
    -- 初始化标签Grid列表
    self._TagGrids = {}
    self.GridTag.gameObject:SetActiveEx(false)
end

---设置Boss卡片数据
function XUiPanelTheatre6BossCard:SetData(fightId)
    self._FightId = fightId
    local bossConfig = self._Control:GetBossConfigByRoom(fightId, false)
    if bossConfig == nil then
        self._Control:ShowTip("boss配置为空")
        return
    end
    
    local characterConfig = self._Control:GetCharacterConfig(bossConfig.CharacterId)
    local fashionConfig = self._Control:GetFashionConfig(characterConfig.FashionIds[1])
    self.UiTxtBossName.text = characterConfig.Name
    self.UiRImgBoss:SetRawImage(fashionConfig.BigPortrait)
    self.UiTxtNum.text = math.abs(self._Control:GetBossLoseHp(fightId))
    self:RefreshTags()
end

---刷新Boss标签列表
function XUiPanelTheatre6BossCard:RefreshTags()
    local tagIds = self._Control:GetBossTagIds(self._FightId)
    local isEmpty = XTool.IsTableEmpty(tagIds)
    if self.PanelTag then
        self.PanelTag.gameObject:SetActiveEx(not isEmpty)
    end
    if isEmpty then
        return
    end
    -- 使用UpdateDynamicItem管理标签Grid
    XTool.UpdateDynamicItem(self._TagGrids, tagIds, self.GridTag, require("XUi/XUiTheatre6/Boss/Grid/XUiGridTheatre6BossTag"), self)
end

return XUiPanelTheatre6BossCard
