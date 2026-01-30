---@class XUiGridFashionSuitFashion : XUiNode
---@field Parent XUiPanelFashionSuitNormal
---@field _Control XFashionSuitControl
local XUiGridFashionSuitFashion = XClass(XUiNode, "XUiGridFashionSuitFashion")

function XUiGridFashionSuitFashion:OnStart()
    self._RImgBgs = { self.RImgBg1, self.RImgBg2, self.RImgBg3, self.RImgBg4 }
    self._Spines = { self.Spine1, self.Spine2, self.Spine3, self.Spine4 }
    self._RImgOwnBoxs = { self.RImgOwnBox1, self.RImgOwnBox2 }
    self._RImgNotOwnBoxs = { self.RImgNotOwnBox1, self.RImgNotOwnBox2 }
end

function XUiGridFashionSuitFashion:OnEnable()
    if XTool.IsNumberValid(self._SuitId) and XTool.IsNumberValid(self._Id) then
        self:Refresh(self._SuitId, self._Id)
    end
end

function XUiGridFashionSuitFashion:Refresh(fashionSuitId, fashionId)
    self._Id = fashionId
    self._SuitId = fashionSuitId
    local config = XFashionConfigs.GetFashionTemplate(fashionId)
    local roleName = XMVCA.XCharacter:GetCharacterTemplate(config.CharacterId).Name
    local rImgPath = config.FashionSuitResourcePicPath
    local spinePath = config.FashionSuitResourceSpinePath
    local isViewed = self._Control:IsFashionViewed(fashionId)
    local isEmptyImg = string.IsNilOrEmpty(rImgPath)
    local isEmptySpine = string.IsNilOrEmpty(spinePath)

    for _, rImg in pairs(self._RImgBgs) do
        if isEmptyImg then
            rImg.gameObject:SetActiveEx(false)
        else
            rImg.gameObject:SetActiveEx(true)
            rImg:SetRawImage(rImgPath)
        end
    end

    for _, spine in pairs(self._Spines) do
        if isEmptySpine then
            spine.gameObject:SetActiveEx(false)
        else
            spine.gameObject:SetActiveEx(true)
            spine:LoadPrefab(spinePath)
        end
    end

    local tex = self._Control:GetClientConfig("SuitImageBorder", config.FashionSuitRare)
    for _, rImg in ipairs(self._RImgOwnBoxs) do
        if string.IsNilOrEmpty(tex) then
            rImg.gameObject:SetActiveEx(false)
        else
            rImg.gameObject:SetActiveEx(true)
            rImg:SetRawImage(tex)
        end
    end

    tex = self._Control:GetClientConfig("LockSuitImageBorder", config.FashionSuitRare)
    for _, rImg in ipairs(self._RImgNotOwnBoxs) do
        if string.IsNilOrEmpty(tex) then
            rImg.gameObject:SetActiveEx(false)
        else
            rImg.gameObject:SetActiveEx(true)
            rImg:SetRawImage(tex)
        end
    end

    self.TxtSkinName1.text = config.Name
    self.TxtSkinName2.text = config.Name
    self.TxtCharacterName1.text = roleName
    self.TxtCharacterName2.text = roleName
    self.ImgTagNew.gameObject:SetActiveEx(not isViewed)
end

function XUiGridFashionSuitFashion:UpdateSelect(isSelected)
    local hasFashion = XDataCenter.FashionManager.CheckHasFashion(self._Id)
    self.PanelSelectOwn.gameObject:SetActiveEx(isSelected and hasFashion)
    self.PanelSelectNotOwn.gameObject:SetActiveEx(isSelected and not hasFashion)
    self.PanelNotSelectOwn.gameObject:SetActiveEx(not isSelected and hasFashion)
    self.PanelNotSelectNotOwn.gameObject:SetActiveEx(not isSelected and not hasFashion)
end

function XUiGridFashionSuitFashion:AddClickEvt()
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OpenDetail)
end

function XUiGridFashionSuitFashion:OpenDetail()
    XMVCA.XShop:OpenFashionDetailUi(self._Id, nil, { suitId = self._SuitId })
end

return XUiGridFashionSuitFashion
