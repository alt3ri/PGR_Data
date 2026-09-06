--- 副卡槽位组件（主卡详情 Tips 内展示单个副卡装配位）。
--- 主卡有且仅有 1 个副卡槽位，不克隆列表，直接挂一个本组件实例。
---@class XUiPanelPunishaarSubCardSlot: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field TxtSubCardName UnityEngine.UI.Text 副卡名称文本（对应副卡 PunishaarCard.Name）
---@field GroupSubTag @副卡标签组根节点（容器，按副卡 cardCfg.Tag 数量显隐，对称主卡 GroupCardTag）
---@field SubCardTag @单个副卡标签模板节点（XUiGridCardTag，对称主卡 CardTag 模板）
---@field private _TagGridDict table<UnityEngine.GameObject, XUiGridCardTag> Tag grid 缓存（按 go 复用，零 GC）
---@field UiPunishaarSubCard @通用符卡 UI 预制体（复用 XUiGridShopSubCard 的副卡图标显示）
---@field BtnClick XUiComponent.XUiButton 点击按钮（点击副卡槽 → 选中/弹出副卡详情）
local XUiPanelPunishaarSubCardSlot = XClass(XUiNode, "XUiPanelPunishaarSubCardSlot")

local XUiGridShopSubCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopSubCard")
local XUiGridCardTag = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/XUiGridCardTag")

function XUiPanelPunishaarSubCardSlot:OnStart()
    -- 复用 XUiGridShopSubCard 风格的副卡图标显示（内含 PanelNone/PanelSubCard 空满切换）
    if self.UiPunishaarSubCard then
        self.SubCard = XUiGridShopSubCard.New(self.UiPunishaarSubCard, self)
        self.SubCard:Open()
    end
    if self.BtnClick then
        self.BtnClick:AddEventListener(handler(self, self._OnBtnClick))
    end
    -- GroupSubTag 容器初始隐，由 Refresh:_RefreshSubCardTags 按 Tag 数量显隐（对称主卡 GroupCardTag）
    if self.GroupSubTag then
        self.GroupSubTag.gameObject:SetActiveEx(false)
    end
end

--- 刷新副卡槽。
---@param masterCard table|nil Server.XPunishaarMasterCard（source=2 已装备态）；nil/无 SubCardId → 空槽
function XUiPanelPunishaarSubCardSlot:Refresh(masterCard)
    local subCardId = masterCard and masterCard.SubCardId or 0
    self._SubCardId = subCardId
    self._MasterCard = masterCard  -- 供 _OnBtnClick 传出（丢弃协议需宿主主卡 Id）
    -- 宿主主卡 Type：空槽时决定显哪张空态底图（意识/共鸣分轨 #71）
    local masterCfg = masterCard and self._Control:GetTablePunishaarCard(masterCard.TemplateId, true)
    self._HostCardType = masterCfg and masterCfg.Type or nil
    if subCardId == 0 then
        self:_ShowEmpty()
        return
    end
    local cardCfg = self._Control:GetTablePunishaarCard(subCardId, true)
    if not cardCfg then
        self:_ShowEmpty()
        return
    end
    if self.TxtSubCardName then
        self.TxtSubCardName.text = cardCfg.Name or ""
    end
    if self.SubCard then
        self.SubCard:Refresh(subCardId, self._HostCardType)
    end
    -- 副卡标签组：按副卡 cardCfg.Tag 克隆 SubCardTag grid 显 Tag 图标+名称（对称主卡 _RefreshCardTags）
    self:_RefreshSubCardTags(cardCfg)
end

function XUiPanelPunishaarSubCardSlot:_ShowEmpty()
    self._SubCardId = 0
    self._MasterCard = nil
    if self.TxtSubCardName then
        self.TxtSubCardName.text = ""
    end
    if self.SubCard then
        -- 传宿主 Type：空槽仍需按宿主显对应空态底图（意识/共鸣分轨 #71）
        self.SubCard:Refresh(nil, self._HostCardType)
    end
    -- 空槽无副卡 → 副卡标签组隐（count=0）
    self:_RefreshSubCardTags(nil)
end

--- 刷新副卡标签组（GroupSubTag）：按副卡 cardCfg.Tag 数组克隆 SubCardTag grid 显 Tag 图标+名称。
--- 对称主卡 XUiPanelPunishaarMainCard:_RefreshCardTags（GroupSubTag 容器/SubCardTag 模板，结构同主卡标签组）。
--- 空 Tag / tagCfg 查不到（PunishaarCardTag 表数据未填）→ GroupSubTag 隐藏。
--- 访问链：self._Control（根 XPunishaarControl）:GetTablePunishaarCardTag 直达根 Control（局外图鉴也走根 Control）。
---@param cardCfg XTablePunishaarCard|nil 副卡配置（取 Tag 数组）；nil → 隐容器
function XUiPanelPunishaarSubCardSlot:_RefreshSubCardTags(cardCfg)
    if not self.GroupSubTag then
        return
    end

    local count = 0
    if cardCfg and not XTool.IsTableEmpty(cardCfg.Tag) then
        count = #cardCfg.Tag
    end

    self.GroupSubTag.gameObject:SetActiveEx(count > 0)
    
    if self.SubCardTag then
        self.SubCardTag.gameObject:SetActiveEx(false)
    end

    if self._TagGridDict == nil then
        self._TagGridDict = {}
    else
        for _, v in pairs(self._TagGridDict) do
            v:Close()
        end
    end

    XUiHelper.RefreshCustomizedList(self.GroupSubTag.transform, self.SubCardTag, count, function(index, go)
        local grid = self._TagGridDict[go]
        if not grid then
            grid = XUiGridCardTag.New(go, self)
            self._TagGridDict[go] = grid
        end
        grid:Open()

        local tagId = cardCfg.Tag[index]
        local tagCfg = self._Control:GetTablePunishaarCardTag(tagId)

        grid:Refresh(tagCfg)
    end)
end

function XUiPanelPunishaarSubCardSlot:_OnBtnClick()
    -- 查看副卡详情（子气泡，不关主卡 #39）：经 MainCardTips.Parent(TipsRoot).ShowSubCardNested
    -- 传 masterCard 供丢弃协议用（DiscardCard 需宿主主卡 Id 定位副卡）
    if not self._SubCardId or self._SubCardId == 0 then
        XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("ExpandSubCardTipsWithNoSubCard"))
        return
    end
    local tipsRoot = self.Parent and self.Parent.Parent
    if tipsRoot and tipsRoot.ShowSubCardNested then
        local subData = { subCardId = self._SubCardId, masterCard = self._MasterCard }
        -- 只读场景（结算复盘，readOnly 经 MainCardTips._Detail 透传）压副卡 operationMode=None（0），
        -- 不显 Discard 等操作按钮，与自动展开路径一致（对齐主卡 readOnly）
        local mainDetail = self.Parent._Detail
        if mainDetail and mainDetail.readOnly then
            subData.operationMode = 0
        end
        tipsRoot:ShowSubCardNested(subData, self.Transform)
    end
end

function XUiPanelPunishaarSubCardSlot:OnDestroy()
    self.SubCard = nil
    self._SubCardId = nil
    self._MasterCard = nil
end

return XUiPanelPunishaarSubCardSlot
