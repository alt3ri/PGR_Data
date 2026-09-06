-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarEventSettlementGridCard : XUiNode
---@field ImgHeadRole UnityEngine.UI.RawImage
---@field TagCheck UnityEngine.RectTransform
---@field LevelupGroup XUiPanelPunishaarLevelupGroup 升级组（prefab 有此节点时接，OnStart 隐子节点防异常显；Refresh SetCanLevelUp 复用 CardLevel>1）
---@field ImgHeadPats UnityEngine.UI.RawImage
---@field ImgHeadBgPats UnityEngine.UI.RawImage
---@field ImgHeadBgRole UnityEngine.UI.RawImage
-- ======== AUTO FIELDS END ========
--- v2 奖励阶段主卡 grid：纯展示奖励主卡头像。
--- pats 头像/TagCheck 在奖励预览无数据，整组隐藏；LevelupGroup 按 CardLevel>1 显可升级（prefab 有此节点时）。
local XUiPanelPunishaarLevelupGroup = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Com/XUiPanelPunishaarLevelupGroup")
local XUiPunishaarEventSettlementGridCard = XClass(XUiNode, "XUiPunishaarEventSettlementGridCard")

function XUiPunishaarEventSettlementGridCard:OnStart()
    -- LevelupGroup（prefab 有此节点时接，OnStart 隐 CanLevelup/Levelup 防异常显）
    if self.LevelupGroup then
        ---@type XUiPanelPunishaarLevelupGroup
        self._LevelupGroup = XUiPanelPunishaarLevelupGroup.New(self.LevelupGroup, self)
    end
    -- 奖励预览不含 pats，pats 头像及底框整组隐藏
    if self.ImgHeadBgPats then
        self.ImgHeadBgPats.gameObject:SetActiveEx(false)
    end
    -- TagCheck 奖励预览无勾选概念，默认隐藏
    if self.TagCheck then
        self.TagCheck.gameObject:SetActiveEx(false)
    end
end

function XUiPunishaarEventSettlementGridCard:OnEnable()
    -- Open LevelupGroup（触发 OnStart 首次初始隐 CanLevelup/Levelup；#108 不 Open 致 OnStart 不触发 prefab 默认显异常）
    if self._LevelupGroup and not self._LevelupGroup:IsNodeShow() then
        self._LevelupGroup:Open()
    end
end

function XUiPunishaarEventSettlementGridCard:OnDisable()
    if self._LevelupGroup then
        self._LevelupGroup:Close()
    end
end

function XUiPunishaarEventSettlementGridCard:OnDestroy()
end

--- 刷新主卡奖励展示。
---@param data table { CardId: number, Level: number }
function XUiPunishaarEventSettlementGridCard:Refresh(data)
    if not data or not XTool.IsNumberValid(data.CardId) then
        return
    end
    local cardCfg = XMVCA.XPunishaar:GetTablePunishaarCard(data.CardId)
    if self.ImgHeadRole and cardCfg and not string.IsNilOrEmpty(cardCfg.Icon) then
        self.ImgHeadRole:SetRawImage(cardCfg.Icon)
    end
    -- LevelupGroup（prefab 有此节点时）：SetCanLevelUp 按 CardLevel>1 显 CanLevelup + TagLevelupEnable loop
    local showLevelup = XTool.IsNumberValid(data.Level) and data.Level > 1
    if self._LevelupGroup then
        self._LevelupGroup:SetCanLevelUp(showLevelup)
    end
end

return XUiPunishaarEventSettlementGridCard
