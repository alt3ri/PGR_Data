---@class XUiGridTheatre6BossRewardResource : XUiNode Boss奖励Grid - 资源(金币)
---@field _Control XTheatre6Control
local XUiGridTheatre6BossRewardResource = XClass(XUiNode, "XUiGridTheatre6BossRewardResource")

local EventRewardType = XEnumConst.Theatre6.EventRewardType

function XUiGridTheatre6BossRewardResource:OnStart()
    self.GridResource:AddEventListener(handler(self, self.OnGridResourceClick))
end

---@param count number 资源数量
function XUiGridTheatre6BossRewardResource:Refresh(count)
    self.TxtCount.text = tostring(count)
end

---显示金币
function XUiGridTheatre6BossRewardResource:RefreshGold(count)
    self._EventRewardType = EventRewardType.Coin
    self.TxtCount.text = count
    self.RImgResource:SetRawImage(self._Control:GetCoinIcon())
end

---显示材料
function XUiGridTheatre6BossRewardResource:RefreshGoods(id, count)
    self._Id = id
    self._EventRewardType = EventRewardType.Goods
    self.TxtCount.text = count
    self.RImgResource:SetRawImage(self._Control:GetGoodsIcon(id))
end

---显示Buff池
function XUiGridTheatre6BossRewardResource:RefreshBuffPool(id)
    self.TxtCount.text = ""
    self.TxtCountBg.gameObject:SetActiveEx(false)
    self.RImgResource:SetRawImage(self._Control:GetStageBuffPoolShow(id).Icon)
end

---显示技能遗物池
function XUiGridTheatre6BossRewardResource:RefreshRandomPool(id)
    self.TxtCount.text = ""
    self.TxtCountBg.gameObject:SetActiveEx(false)
    self.RImgResource:SetRawImage(self._Control:GetRandomPoolConfig(id).Icon)
end

---显示遗物池/技能池/Buff池
function XUiGridTheatre6BossRewardResource:ShowPool(rewardType, rewardValue)
    if rewardType == EventRewardType.Coin then
        self:RefreshGold(rewardValue)
    elseif rewardType == EventRewardType.BuffPool then
        self:RefreshBuffPool(rewardValue)
    elseif rewardType == EventRewardType.SkillPool then
        self:RefreshRandomPool(rewardValue)
    else
        XLog.Error(string.format("BOSS奖励类型【%s】未支持", rewardType))
        return
    end
    self._IsPool = true
    self._Id = rewardValue
    self._EventRewardType = rewardType
end

function XUiGridTheatre6BossRewardResource:OnGridResourceClick()
    if self._IsPool then
        self._Control:OpenPoolTip(self._EventRewardType, self._Id)
        return
    end
    if self._EventRewardType then
        self._Control:OpenItemTip(self._EventRewardType, self._Id)
    end
end

return XUiGridTheatre6BossRewardResource
