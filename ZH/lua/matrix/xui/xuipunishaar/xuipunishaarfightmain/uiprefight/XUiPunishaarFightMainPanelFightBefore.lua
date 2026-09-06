local XUiPunishaarFightMainPanelStateBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarFightMainPanelStateBase")
local XUiPunishaarFightMainPreFightComBottomBag = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiPreFight/XUiPunishaarFightMainPreFightComBottomBag")
local XUiGridPunishaarRoleShow = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiPreFight/XUiGridPunishaarRoleShow")

--- 战前准备面板：展示对战区卡牌布局，玩家确认后点击"开始战斗"进入战中状态。
--- 复用 ComBottomBag 作为装备区（对战区 + 背包暂存区逻辑与商店一致）。
--- 继承 PanelStateBase（DragRoot 拖拽托管 + BuySuccess 刷新订阅），覆写 _OnBuySuccess=Refresh。
--- PanelAsset 由 CommonFightMain.SetShowOnPreFight() Open 后 OnEnable 自动刷新，此处无需处理。
---@class XUiPunishaarFightMainPanelFightBefore : XUiPunishaarFightMainPanelStateBase
---@field ComBottomBag UnityEngine.RectTransform 底部装备区挂载根节点
---@field BtnFight XUiComponent.XUiButton 开始战斗按钮
---@field UiPunishaarRoleHp UnityEngine.RectTransform 玩家方信息展示挂载根（挂 XUiGridPunishaarRoleShow：头像+名称+HP）
---@field UiPunishaarEnemyHp UnityEngine.RectTransform 敌方信息展示挂载根（挂 XUiGridPunishaarRoleShow：头像+名称+HP）
local XUiPunishaarFightMainPanelFightBefore = XClass(XUiPunishaarFightMainPanelStateBase, "XUiPunishaarFightMainPanelFightBefore")

function XUiPunishaarFightMainPanelFightBefore:OnStart()
    self.BtnFight.gameObject:SetActiveEx(true)
    self.BtnFight:AddEventListener(handler(self, self._OnBtnFight))

    ---@type XUiPunishaarFightMainPreFightComBottomBag
    self.BottomBag = XUiPunishaarFightMainPreFightComBottomBag.New(self.ComBottomBag, self)
    self.BottomBag:Open()
    -- 背包开/关联动 BtnFight 显隐（复用 SetBagExclusiveHandler 开前/关后回调；PreFight 无商店栏互斥，此回调专用 BtnFight 联动）#战前背包优化
    self.BottomBag:SetBagExclusiveHandler(handler(self, self._OnBagBeforeOpen), handler(self, self._OnBagAfterClose))

    -- 双方信息展示骨架（玩家方/敌方各一）
    if self.UiPunishaarRoleHp then
        ---@type XUiGridPunishaarRoleShow
        self._RoleShow = XUiGridPunishaarRoleShow.New(self.UiPunishaarRoleHp, self)
        self._RoleShow:Open()
    end
    if self.UiPunishaarEnemyHp then
        ---@type XUiGridPunishaarRoleShow
        self._EnemyShow = XUiGridPunishaarRoleShow.New(self.UiPunishaarEnemyHp, self)
        self._EnemyShow:Open()
    end
end

--- BuySuccess 刷新 = Refresh（BtnFight 可战态 + BottomBag 列表）。
function XUiPunishaarFightMainPanelFightBefore:_OnBuySuccess()
    self:Refresh()
end

function XUiPunishaarFightMainPanelFightBefore:Refresh()
    if self.BtnFight then
        self.BtnFight:SetDisable(not self._Control:CanStartFight())
    end
    if self.BottomBag then
        self.BottomBag:Refresh()
        self.BottomBag:RefreshBagLayoutIfShow()
    end
    self:_RefreshRoleShow()
end

--- 刷新双方信息展示（玩家方 icon/name/HP + 敌方头像/名称/HP）。
function XUiPunishaarFightMainPanelFightBefore:_RefreshRoleShow()
    -- 玩家方：参考战中 PanelFighting——name=XPlayer.Name，icon=当前头像 ImgSrc，hp=GetPlayerBattleHp
    local playerHp = self._Control:GetPlayerBattleHp(self._Control:GetCurrentFightWinCount())
    local playerIcon
    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadPortraitId)
    if headPortraitInfo then
        playerIcon = headPortraitInfo.ImgSrc
    end
    if self._RoleShow then
        self._RoleShow:Refresh(playerIcon, XPlayer.Name, playerHp)
    end
    -- 敌方：fightId → Fight(HP) + Enemy(EnemyHead/EnemyName)；HP 从 Fight 表（同 CreateEnemyEntity 源）
    local fightId = self._Control:GetCurrentFightId()
    local enemyIcon, enemyName, enemyHp
    if fightId then
        local fightCfg = self._Control.GameControl:GetTablePunishaarFight(fightId)
        if fightCfg then
            enemyHp = fightCfg.HP + self._Control:GetEnemyExtraHp()  -- base + 无尽关多轮次加成（同 CreateEnemyEntity 源，经 GetEnemyExtraHp accessor 单源）
            local enemyCfg = self._Control.GameControl:GetTablePunishaarEnemy(fightCfg.EnemyId)
            if enemyCfg then
                enemyIcon = enemyCfg.EnemyHead
                enemyName = enemyCfg.EnemyName
            end
        end
    end
    if self._EnemyShow then
        self._EnemyShow:Refresh(enemyIcon, enemyName, enemyHp)
    end
end

--- 背包展开前：隐"开始战斗"按钮（背包遮挡/误触，专注编排）#战前背包优化
function XUiPunishaarFightMainPanelFightBefore:_OnBagBeforeOpen()
    if self.BtnFight then
        self.BtnFight.gameObject:SetActiveEx(false)
    end
end

--- 背包收起后：显"开始战斗"按钮 + 恢复可战态 Disable（关背包后重判 CanStartFight，与 Refresh:44 同源）。
function XUiPunishaarFightMainPanelFightBefore:_OnBagAfterClose()
    if self.BtnFight then
        self.BtnFight.gameObject:SetActiveEx(true)
        self.BtnFight:SetDisable(not self._Control:CanStartFight())
    end
end

function XUiPunishaarFightMainPanelFightBefore:_OnBtnFight()
    self._Control.GameControl:ConfirmEnterFight()
end

return XUiPunishaarFightMainPanelFightBefore
