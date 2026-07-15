local XUiPhotographFashionColor = XClass(XUiNode, "XUiPhotographFashionColor")

function XUiPhotographFashionColor:NormalizeSavedColorId(colorId)
    return XTool.IsNumberValid(colorId) and colorId or 0
end

function XUiPhotographFashionColor:OnStart(...)

end

function XUiPhotographFashionColor:Refresh(fashionId)
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.HasFashionColor = template.FashionColorIds and #template.FashionColorIds > 0

    if self.CurFashionId ~= fashionId then
        if self.HasFashionColor then
            local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId)
            self.SelectColorId = self:NormalizeSavedColorId(fashionData and fashionData.ColorId)
        else
            self.SelectColorId = nil
        end
    end
    self.CurFashionId = fashionId
    self.CurCharacterId = template.CharacterId
    self:RefreshColorDot(template.FashionColorIds)
end

function XUiPhotographFashionColor:RefreshColorDot(colorIds)
    if not colorIds or #colorIds <= 0 then
        self:Close()
        self.TxtTipTitle.gameObject:SetActiveEx(false)
        return
    end

    local ownedColorIds = {}
    for _, colorId in ipairs(colorIds) do
        if XMVCA.XFashion:IsFashionColorHas(self.CurFashionId, colorId) then
            table.insert(ownedColorIds, colorId)
        end
    end

    if #ownedColorIds <= 0 then
        self:Close()
        self.TxtTipTitle.gameObject:SetActiveEx(false)
        return
    end

    self.TxtTipTitle.gameObject:SetActiveEx(true)
    self:Open()

    local tempColorIds = { 0 }
    for _, colorId in ipairs(ownedColorIds) do
        table.insert(tempColorIds, colorId)
    end
    local btnGroup = {}
    XUiHelper.RefreshCustomizedList(self.Transform, self.BtnDotNormal, #tempColorIds, function(index, go)
        local colorHex = ""
        local colorId = tempColorIds[index]
        if colorId == nil or colorId == 0 then
            colorHex = XFashionConfigs.GetFashionTemplate(self.CurFashionId).FashionColorHex
        else
            colorHex = XMVCA.XFashion:GetFashionColorHex(colorId)
        end
        local ui = {}
        XTool.InitUiObjectByUi(ui, go)
        ui.ImgColour.color = XUiHelper.Hexcolor2Color(string.sub(colorHex, 2, #colorHex))     --去#号
        local hasColor = XMVCA.XFashion:IsFashionColorHas(self.CurFashionId, colorId)
        ui.BtnDotNormal:SetDisable(not hasColor and colorId ~= 0)
        table.insert(btnGroup, ui.BtnDotNormal)
    end, false)
    self.PanelDot:Init(btnGroup, function(index)
        local colorId = tempColorIds[index]
        self:OnColorDotClick(colorId)
    end)
    local selectIndex = 1
    local currentColorId = self.SelectColorId
    for index, colorId in ipairs(tempColorIds) do
        if colorId == currentColorId then
            selectIndex = index
            break
        end
    end
    self.PanelDot:SelectIndex(selectIndex, false)
end


function XUiPhotographFashionColor:OnColorDotClick(colorId)
    self.SelectColorId = colorId
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_MODEL, self.CurCharacterId, self.CurFashionId,
        colorId)
end

function XUiPhotographFashionColor:ChangeFashionColor()
    if not self.HasFashionColor then
        return false
    end

    local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(self.CurFashionId)
    local colorId = self:NormalizeSavedColorId(fashionData and fashionData.ColorId)
    return self.SelectColorId ~= colorId
end

function XUiPhotographFashionColor:GetSelectColorId()
    return self.SelectColorId
end

return XUiPhotographFashionColor
