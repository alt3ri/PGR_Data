--- 角色模型 UI 图标显示根面板（挂 FightMain UiCommonTop，与 ModelShow #63 平级：ModelShow 管 3D 模型，本面板管 UI 图标层）
--- 职责：① 卡牌侧副卡 UI 图标——3D 模型位置→屏幕→UI 坐标换算设位置，节点复用 ② 持敌人侧子面板
---@class XUiPanelPunishaarRoleModelUi: XUiNode
---@field protected _Control
---@field Parent
---@field UiPunishaarEnemyDetail UnityEngine.RectTransform 敌人侧子面板挂载点（挂 XUiPanelPunishaarEnemyDetail）
---@field UiPunishaarSubCard UnityEngine.RectTransform 卡牌侧副卡图标预制挂载点（3D 模型位置→屏幕→UI 坐标换算设位置，节点复用）
local XUiPanelPunishaarEnemyDetail = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiCommonTop/UiRoleModelUiShow/XUiPanelPunishaarEnemyDetail")
local XUiGridShopSubCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopSubCard")

local XUiPanelPunishaarRoleModelUi = XClass(XUiNode, "XUiPanelPunishaarRoleModelUi")

function XUiPanelPunishaarRoleModelUi:OnStart()
    -- 挂点显隐主动管（不靠 prefab 默认）
    if self.UiPunishaarSubCard then
        self.UiPunishaarSubCard.gameObject:SetActiveEx(false)  -- 副卡图标模板默认隐
    end
    -- 建敌人侧子面板（默认 Open；显隐跟敌人模型 Show/Release 走——切走无敌人模型时 HideEnemyDetail 对称关闭）#副卡槽联动
    if self.UiPunishaarEnemyDetail then
        self._EnemyDetail = XUiPanelPunishaarEnemyDetail.New(self.UiPunishaarEnemyDetail, self)
        self._EnemyDetail:Open()
    end
end

--- 订阅卡集合变更（买/卖/移/弃/冻结 + 主卡 notify 回流 + 副卡装配变化 notify）刷我方副卡槽——卡位变化/下场/副卡增删次位 grid 经 RefreshCustomizedList 复用自然隐。#副卡槽联动
function XUiPanelPunishaarRoleModelUi:OnEnable()
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:AddEventListener(gc.ShopEventId.BuySuccess, self._OnCardSetChanged, self)
    end
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self._OnCardSetChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_SUB_CARD_CHANGE, self._OnCardSetChanged, self)
end

function XUiPanelPunishaarRoleModelUi:OnDisable()
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:RemoveEventListener(gc.ShopEventId.BuySuccess, self._OnCardSetChanged, self)
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self._OnCardSetChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_SUB_CARD_CHANGE, self._OnCardSetChanged, self)
end

--- 刷新我方副卡槽（坐标换算，PreFight 进入一次 + 卡集合变更订阅触发）。敌方槽显隐另走 Show/HideEnemyDetail。#70 #副卡槽联动
function XUiPanelPunishaarRoleModelUi:Refresh()
    local modelShow, cam = self:_GetModelShowAndCam()
    if modelShow and cam then
        self:_RefreshCardSubCardIcons(modelShow, cam)
    end
end

--- 卡集合变更 handler（订阅触发）：刷我方副卡槽。
function XUiPanelPunishaarRoleModelUi:_OnCardSetChanged()
    local modelShow, cam = self:_GetModelShowAndCam()
    if modelShow and cam then
        self:_RefreshCardSubCardIcons(modelShow, cam)
    end
end

--- 注入 ModelShow（由 FightMain:InitComponents 调，消除上行读 Parent.Parent.ModelShow）#UI-R3
---@param modelShow XUiPunishaarModelShow
function XUiPanelPunishaarRoleModelUi:SetModelShow(modelShow)
    self._ModelShow = modelShow
end

--- 取 modelShow + UiNearCamera（ModelShow 经 SetModelShow 注入；UiNearCamera 经 ModelShow.Transform=UiModelGo:FindTransform 取）。
---@return XUiPunishaarModelShow|nil, UnityEngine.Camera|nil
function XUiPanelPunishaarRoleModelUi:_GetModelShowAndCam()
    local modelShow = self._ModelShow
    if not modelShow then
        return nil, nil
    end
    return modelShow, self:_GetNearCamera(modelShow)
end

--- 敌方槽对称显（FightMain 切到 PreFight/Fighting RefreshEnemyModel 后平行调）：Open + 刷技能图标 + BtnEnemyDetails。
function XUiPanelPunishaarRoleModelUi:ShowEnemyDetail()
    if not self._EnemyDetail then
        return
    end
    local modelShow, cam = self:_GetModelShowAndCam()
    if modelShow and cam then
        self._EnemyDetail:Show(modelShow, cam)
    end
end

--- 敌方槽对称隐（FightMain 切到 Shopping/Base ReleaseEnemyModel/ShowShopNpcModel 后平行调）：只隐敌方专属元素（BtnEnemyDetails+技能图标），不 Close GO（卡牌侧副卡 grid 可能挂本 GO 下，关 GO 会连带隐卡牌侧）。
function XUiPanelPunishaarRoleModelUi:HideEnemyDetail()
    if self._EnemyDetail then
        self._EnemyDetail:Hide()
    end
end

--- 对话气泡显隐转发（FightMain 切态调 → _EnemyDetail → TalkTips）#对话接入
function XUiPanelPunishaarRoleModelUi:ShowTalkTips(text)
    if self._EnemyDetail then
        self._EnemyDetail:ShowTalkTips(text)
    end
end

function XUiPanelPunishaarRoleModelUi:HideTalkTips()
    if self._EnemyDetail then
        self._EnemyDetail:HideTalkTips()
    end
end

--- 取 UiNearCamera：ModelShow.Transform=UiModelGo，UiNearCamera 在其下（参 XUiPanelRoleModel:774 SetRoleCamera）#70
---@param modelShow XUiPunishaarModelShow
---@return UnityEngine.Camera|nil
function XUiPanelPunishaarRoleModelUi:_GetNearCamera(modelShow)
    local modelNode = modelShow and modelShow.PanelRoleModel1
    if not modelNode then
        return nil
    end
    local uiNearCam = modelShow.Transform:FindTransform("UiNearCamera")
    if not uiNearCam then
        return nil
    end
    return uiNearCam.gameObject:GetComponent(typeof(CS.UnityEngine.Camera))
end

--- 卡牌侧副卡 UI 坐标换算：取 FightArea 主卡（按 StartPos 排序），只有有主卡（=有模型）的挂点才显示副卡图标 #70
--- 坐标换算：挂点 World 位置 → WorldToScreenPoint(UiNearCamera) → ScreenPointToLocalPointInRectangle(UiCamera) → 设 anchoredPosition
---@param modelShow XUiPunishaarModelShow
---@param cam UnityEngine.Camera UiNearCamera
function XUiPanelPunishaarRoleModelUi:_RefreshCardSubCardIcons(modelShow, cam)
    if not self.UiPunishaarSubCard then
        return
    end
    local parent = self.UiPunishaarSubCard.parent
    -- 取 FightArea 主卡（按 StartPos 排序），只有有主卡的挂点才显示副卡位
    local CardAreaType = XMVCA.XPunishaar.EnumConst.CardAreaType
    if not self._CardList then
        self._CardList = XTool.XListNew()
    end
    local count = self._Control:FillAreaCardsSorted(CardAreaType.FightArea, self._CardList)

    -- 先清旧 grid + 隐模板（须在 count==0/#validCards==0 早返前清，否则卡下场/无挂点时 stale 副卡槽残留）#副卡槽联动
    self.UiPunishaarSubCard.gameObject:SetActiveEx(false)
    
    if self._SubCardGridDict == nil then
        self._SubCardGridDict = {}
    else
        for _, v in pairs(self._SubCardGridDict) do
            v:Close()
        end
    end

    if not count or count == 0 then
        return
    end

    -- 过滤：只有对应 PanelRoleModeli 挂点存在的才显示
    local validCards = {}

    for i = 1, count do
        local card = self._CardList:GetValueByIndex(i)
        local node = card and modelShow["PanelRoleModel" .. i]
        if not XTool.IsTableEmpty(card) and node and XTool.IsNumberValidEx(card.SubCardId) then
            validCards[#validCards + 1] = { card = card, node = node }
        end
    end

    if #validCards == 0 then
        return
    end

    XUiHelper.RefreshCustomizedList(parent, self.UiPunishaarSubCard, #validCards, function(index, go)
        ---@type XUiGridShopSubCard
        local grid = self._SubCardGridDict[go]
        
        if not grid then
            grid = XUiGridShopSubCard.New(go, self)
            self._SubCardGridDict[go] = grid
        end

        local card = validCards[index].card
        local subCardId = card.SubCardId
        if not XTool.IsNumberValidEx(subCardId) then
            -- 无副卡：隐模型位副卡槽
            grid:Close()
            return
        end

        -- 有副卡：Open + 坐标换算 + Refresh
        grid:Open()
        local worldPos = validCards[index].node.position
        local screenPos = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(cam, worldPos)
        local ok, localPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
                parent, screenPos, CS.XUiManager.Instance.UiCamera)
        if ok then
            go.transform.anchoredPosition = localPos
        end
        local hostCardCfg = self._Control:GetTablePunishaarCard(card.TemplateId, true)
        local hostCardType = hostCardCfg and hostCardCfg.Type
        grid:Refresh(subCardId, hostCardType)
    end)
end

return XUiPanelPunishaarRoleModelUi