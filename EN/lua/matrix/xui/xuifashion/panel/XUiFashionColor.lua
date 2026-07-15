local XUiFashionColor = XClass(XUiNode, "XUiFashionColor")

function XUiFashionColor:NormalizeSavedColorId(colorId)
    return XTool.IsNumberValid(colorId) and colorId or 0
end

function XUiFashionColor:OnStart(...)

end

function XUiFashionColor:Refresh(fashionId)
    if not XTool.IsNumberValid(fashionId) then
        self.CurFashionId = nil
        self.CurCharacterId = nil
        self.ColorId = nil
        self.HasFashionColor = false
        self.TxtTipTitle.gameObject:SetActiveEx(false)
        self:Close()
        return
    end

    if self.TxtTipTitle then
        self.TxtTipTitle.gameObject:SetActiveEx(true)
    end

    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.CurFashionId = fashionId
    self.CurCharacterId = template.CharacterId
    self.HasFashionColor = template.FashionColorIds and #template.FashionColorIds > 0

    if self.HasFashionColor then
        local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId)
        self.ColorId = self:NormalizeSavedColorId(fashionData and fashionData.ColorId)
    else
        self.ColorId = nil
    end

    self:RefreshColorDot(template.FashionColorIds)
end

function XUiFashionColor:RefreshColorDot(colorIds)
    if not colorIds or #colorIds <= 0 then
        self:Close()

        if self.TxtTipTitle then
            self.TxtTipTitle.gameObject:SetActiveEx(false)
        end

        return
    end
    self:Open()

    if self.TxtTipTitle then
        self.TxtTipTitle.gameObject:SetActiveEx(true)
    end

    local tempColorIds = { 0 }
    for index, colorId in ipairs(colorIds) do
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
        ui.PreLock.gameObject:SetActiveEx(not hasColor and colorId ~= 0)
        table.insert(btnGroup, ui.BtnDotNormal)
    end, false)
    self.BtnGroup:Init(btnGroup, function(index)
        local colorId = tempColorIds[index]
        self:OnColorDotClick(colorId)
    end)
    local selectIndex = 1
    local currentColorId = self:NormalizeSavedColorId(self.ColorId)
    for index, colorId in ipairs(tempColorIds) do
        if colorId == currentColorId then
            selectIndex = index
            break
        end
    end
    self.BtnGroup:SelectIndex(selectIndex, false)
end

function XUiFashionColor:OnColorDotClick(colorId)
    if not XTool.IsNumberValid(self.CurFashionId) then
        return
    end

    self:SetColorId(colorId)
    self.Parent:OnColorDotClick(colorId)

end

function XUiFashionColor:OnNotify(event, ...)
    if event == XEventId.EVENT_FASHION_COLOR_CHANGE then

    end
end

function XUiFashionColor:SetColorId(colorId)
    self.ColorId = colorId
end

function XUiFashionColor:GetColorId()
    return self.ColorId
end

function XUiFashionColor:IsUseNewColor()
    if not XTool.IsNumberValid(self.CurFashionId) or not self.HasFashionColor then
        return false
    end

    local compareColorId = self:NormalizeSavedColorId(self.ColorId)
    local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(self.CurFashionId)
    local colorId = self:NormalizeSavedColorId(fashionData and fashionData.ColorId)
    return compareColorId ~= colorId
end

return XUiFashionColor
