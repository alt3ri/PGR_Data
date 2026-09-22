--- 副卡内容显示组件（详情 Tips 内的卡牌本体展示）。
--- 对称于 UiShop/Com/XUiComShopCardShow 的卡牌内容部分，但不带商品/装备模式分支。
--- 副卡无等级/ATK/CD（已约定 #43），本面板只显 Icon/名称。
---@class XUiPanelPunishaarSubCard: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field GroupControl XUiGroupControl 头像分组控制器（Role/Pet 两 Group，按副卡关联约束映射 Type 切状态 + SetRawImage 设图）#67
---@field GroupCardTag @效果/构筑标签组根节点（按 cardCfg.Tag 数量克隆 GroupCardTag 显 Tag 图标+名称 #78）
---@field private _TagGridDict table<UnityEngine.GameObject, XUiGridCardTag> Tag grid 缓存（按 go 复用，零 GC #78）
---@field TxtCardName UnityEngine.UI.Text 副卡名称文本（对应 PunishaarCard.Name）
local XUiPanelPunishaarSubCard = XClass(XUiNode, "XUiPanelPunishaarSubCard")
local XUiGridCardTag = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/XUiGridCardTag")

function XUiPanelPunishaarSubCard:OnStart()
    if self.GroupCardTag then
        -- GroupCardTag 容器默认隐藏，由 Refresh:_RefreshCardTags 按 Tag 数量显隐 #78
        self.GroupCardTag.gameObject:SetActiveEx(false)
    end

    if self.PanelKeepPlace  then
        self.PanelKeepPlace.gameObject:SetActiveEx(true) 
    end

    if self.PanelBuy        then self.PanelBuy.gameObject:SetActiveEx(false) end
    if self.PanelDiscard    then self.PanelDiscard.gameObject:SetActiveEx(false) end
    if self.PanelBuyReplace then self.PanelBuyReplace.gameObject:SetActiveEx(false) end
    if self.PanelBuyPlace   then self.PanelBuyPlace.gameObject:SetActiveEx(false) end
    if self.PanelPlace      then self.PanelPlace.gameObject:SetActiveEx(false) end

    if self.BtnKeepPlace then
        self.BtnKeepPlace:AddEventListener(handler(self, self._OnBtnKeepPlaceClick))
    end
end

--- 刷新副卡内容（GroupControl 切 Role/Pet 头像 + 名称，无等级/星级 #43 #67）。
---@param cardId number PunishaarCard.Id
function XUiPanelPunishaarSubCard:Refresh(cardId)
    if not cardId or cardId == 0 then
        return
    end
    local cardCfg = self._Control:GetTablePunishaarCard(cardId)

    self:_RefreshCardHead(cardCfg)

    if self.TxtCardName and cardCfg then
        self.TxtCardName.text = cardCfg.Name or ""
    end

    -- 效果/构筑标签组：按 cardCfg.Tag 数量克隆 GroupCardTag grid #78
    self:_RefreshCardTags(cardCfg)
    
    self.CardId = cardId

    -- 副卡不显示 ATK/CD（已约定不再读取 level 表 #43）
    -- 描述文本走 PunishaarCard.Desc（对齐主卡 TxtDesc），DescParams 占位符替换经 GetCardDesc 统一处理
    if self.TxtCardSkillInfo then
        self.TxtCardSkillInfo.text = self._Control:GetCardDesc(cardId)
    end

end

--- 刷新卡牌标签组（GroupCardTag）：按 cardCfg.Tag 数组克隆 GroupCardTag grid 显 Tag 图标+名称 #78。
--- 对称主卡 XUiPanelPunishaarMainCard:_RefreshCardTags，逻辑同（Tag 数组读取/空 Tag/访问链）。
--- 访问链：self._Control（根 XPunishaarControl）:GetTablePunishaarCardTag 直达根 Control #78 修正，
---   局外图鉴模式（collectionMode）也走根 Control，无需 GameControl 存在性守卫。
---@param cardCfg XTablePunishaarCard|nil
function XUiPanelPunishaarSubCard:_RefreshCardTags(cardCfg)
    if not self.GroupCardTag then
        return
    end

    self.GroupCardTag.gameObject:SetActiveEx(false)

    if self._TagGridDict == nil then
        self._TagGridDict = {}
    else
        for _, v in pairs(self._TagGridDict) do
            v:Close()
        end
    end
    
    local count = 0

    if cardCfg and not XTool.IsTableEmpty(cardCfg.Tag) then
        count = #cardCfg.Tag
    end
    
    XUiHelper.RefreshCustomizedList(self.GroupCardTag.transform.parent, self.GroupCardTag, count, function(index, go)
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

--- 副卡头像按关联约束映射 Role/Pet 状态 + 设图（GroupControl）。#67
--- 副卡 Type 是 Awareness/Resonance（非 Role/Pet），用 Agency:GetSubCardHostCardType(Type) 映射到主卡小类
---   （Awareness→Character / Resonance→Weapon），再判 Role/Pet 切 GroupControl 组 + SetRawImage 设图（C# 已接 string 路径）。
---@param cardCfg XTablePunishaarCard|nil
function XUiPanelPunishaarSubCard:_RefreshCardHead(cardCfg)
    if not self.GroupControl then
        return
    end
    local hostCardType = XMVCA.XPunishaar:GetSubCardHostCardType(cardCfg and cardCfg.Type)
    local isRole = hostCardType == XMVCA.XPunishaar.EnumConst.CardType.Character
    self.GroupControl:ChangeGroup(isRole and "Role" or "Pet")
    if cardCfg and not string.IsNilOrEmpty(cardCfg.Icon) then
        self.GroupControl:SetRawImage(0, cardCfg.Icon)
    end
end

function XUiPanelPunishaarSubCard:OnDestroy()
end

--- 设置"保留并放入"确认回调（自上而下注入，由使用 KeepPlace 模式的父面板提供，如副卡保留 UI）。
--- 未注入时 _OnBtnKeepPlace 为 no-op（上游协议未支持，待策划定）。
---@param cb function(cardId:number) 确认保留当前展示副卡的回调
function XUiPanelPunishaarSubCard:SetKeepPlaceConfirm(cb)
    self._KeepPlaceCb = cb
end

function XUiPanelPunishaarSubCard:_OnBtnKeepPlaceClick()
    if self._KeepPlaceCb then
        self._KeepPlaceCb(self.CardId)
    end
end

return XUiPanelPunishaarSubCard
