---@class XUiGridSGCardBattleItem
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Card XCafe.XCard
---@field _Control XSkyGardenCafeControl
---@field _PanelCoffee XUiPanelSGValueChange
---@field _PanelReview XUiPanelSGValueChange
local XUiGridSGCardBattleItem = XClass(nil, "XUiGridSGCardBattleItem")

local XUiGridSGCardTag = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardTag")
local XUiGridSGCardTagWithDetail = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardTagWithDetail")
local XUiPanelSGValueChange = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGValueChange")

local DlcEventId = XMVCA.XBigWorldService.DlcEventId
local DealContainer = XMVCA.XSkyGardenCafe.CardContainer.Deal

function XUiGridSGCardBattleItem:Ctor(card, control, parent)
    XTool.InitUiObjectByUi(self, card.transform)
    self._Card = card
    self._Control = control
    self.Parent = parent

    self._Select = false
    self._PanelCoffee = XUiPanelSGValueChange.New(self.PanelCoffee)
    self._PanelReview = XUiPanelSGValueChange.New(self.PanelReview)
    if not self.RImgBg then
        self.RImgBg = self.Transform:FindTransform("RImgBg"):GetComponent("RawImage")
    end

    if self.TxtDetail then
        self.TxtDetail.requestImage = XMVCA.XSkyGardenCafe.RichTextImageCallBackCb
    end

    if self.RImgEffectOutline then
        self.RImgEffectOutline.gameObject:SetActiveEx(false)
    end
end

function XUiGridSGCardBattleItem:Reclaim()
end

---@param card XSkyGardenCafeCardEntity
function XUiGridSGCardBattleItem:Refresh(card, containerType, isDetail)
    if not card or card:IsDisposed() then
        self.PanelNone.gameObject:SetActiveEx(true)
        self.PanelCard.gameObject:SetActiveEx(false)
        return
    end

    self._CardId = card:GetCardId()
    self.PanelCard.gameObject:SetActiveEx(true)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.TxtDetail.gameObject:SetActiveEx(true)
    self.PanelNum.gameObject:SetActiveEx(false)

    local configCoffee, totalCoffee, totalReview, configReview = 0, 0, 0, 0
    if not card:IsNotDisplayResourceType() then
        totalCoffee = card:GetTotalCoffee(containerType ~= DealContainer)
        configCoffee = self._Control:GetCustomerCoffee(self._CardId)

        totalReview = card:GetTotalReview(containerType ~= DealContainer)
        configReview = self._Control:GetCustomerReview(self._CardId)
    end

    self._PanelCoffee:RefreshView(totalCoffee, configCoffee)
    self._PanelReview:RefreshView(totalReview, configReview)

    local cardId = self._CardId

    self.RImgHead:SetRawImage(self._Control:GetCustomerIcon(cardId))
    self.TxtName.text = self._Control:GetCustomerName(cardId)
    if isDetail then
        local worldDesc = self._Control:GetCustomerWorldDesc(cardId)
        local validDesc = not string.IsNilOrEmpty(worldDesc)
        self.PanelStory.gameObject:SetActiveEx(validDesc)
        if validDesc then
            self.TxtWorldDesc.text = worldDesc
        end
        self.TxtDetail.text = card:GetCustomerDetails()
    else
        self.TxtDetail.text = card:GetCustomerDesc()
    end
    self:RefreshTags(self._Control:GetCustomerTags(cardId), isDetail)

    self._Select = false
    self.ImgSelect.gameObject:SetActiveEx(false)
    if self.RImgBg then
        self.RImgBg:SetRawImage(self._Control:GetCustomerQualityIcon(cardId))
    end
end

function XUiGridSGCardBattleItem:RefreshTags(tags, isDetail)
    if not self._GridTags then
        self._GridTags = {}
    end
    local hasTag = not XTool.IsTableEmpty(tags)
    if isDetail then
        if not self._GridTagDetails then
            self._GridTagDetails = {}
        end
        self.ListTagDetail.gameObject:SetActiveEx(hasTag)
    end

    local hideCount = 0
    if hasTag then
        for i, tagId in pairs(tags) do
            local grid = self:GetTagGrid(i, false)
            local tagName = self._Control:GetTagName(tagId)
            grid:Refresh(tagName)
            if isDetail then
                local gridTagWithDetail = self:GetTagGrid(i, true)
                gridTagWithDetail:Refresh(tagName, self._Control:GetTagDesc(tagId))
            end
            hideCount = hideCount + 1
        end
    end

    self:HideTagGrid(self.PanelTag, hideCount, "GridTag")
    if isDetail then
        self:HideTagGrid(self.ListTagDetail, hideCount, "GridTagDetail")
    end
end

function XUiGridSGCardBattleItem:GetTagGrid(index, isDetail)
    local grids = isDetail and self._GridTagDetails or self._GridTags
    local grid = grids[index]
    if not grid then
        local ui
        if index == 1 then
            ui = isDetail and self.GridTagDetail or self.GridTag
        else
            local name = isDetail and "GridTagDetail" .. index or "GridTag" .. index
            ui = self.Transform:FindTransform(name)
            if not ui then
                local prefab = isDetail and self.GridTagDetail or self.GridTag
                local parent = isDetail and self.ListTagDetail or self.PanelTag
                ui = XUiHelper.Instantiate(prefab, parent)
                ui.gameObject.name = name
            end
        end
        grid = isDetail and XUiGridSGCardTagWithDetail.New(ui) or XUiGridSGCardTag.New(ui)
        grids[index] = grid
    end
    return grid
end

function XUiGridSGCardBattleItem:HideTagGrid(parent, hideCount, hideName)
    local total = parent.transform.childCount
    for i = total, hideCount + 1, -1 do
        local grid
        if i == 1 then
            grid = parent:FindTransform(hideName)
        else
            grid = parent:FindTransform(hideName .. i)
        end
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridSGCardBattleItem:SetSelect(index)
    self._Select = not self._Select
    self.ImgSelect.gameObject:SetActiveEx(self._Select)
    self._Control:GetBattle():GetRoundEntity():SetReDrawSelectIndex(index, self._Select)

    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_RE_DRAW_CARD, true)
end

function XUiGridSGCardBattleItem:Open()
    if not self.GameObject then
        return
    end
    self.GameObject:SetActiveEx(true)
end

function XUiGridSGCardBattleItem:Close()
    if not self.GameObject then
        return
    end
    self.GameObject:SetActiveEx(false)
end

function XUiGridSGCardBattleItem:OnBtnCheckClick()
    if not self._CardId or self._CardId <= 0 then
        return
    end
    XLuaUiManager.Open("UiSkyGardenCafePopupCardDetail", self._CardId)
end

function XUiGridSGCardBattleItem:PlayDragEffect(dragState)
    if not self.RImgEffectOutline then
        return
    end
    self.RImgEffectOutline.gameObject:SetActiveEx(dragState == 1)
end

return XUiGridSGCardBattleItem