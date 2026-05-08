local XUiFashionColor = XClass(XUiNode, "XUiFashionColor")
function XUiFashionColor:OnStart(...)

end

function XUiFashionColor:Refresh(fashionId)
    if not XTool.IsNumberValid(fashionId) then
        self.CurFashionId = nil
        self.CurCharacterId = nil
        self.ColorId = nil
        self.GameObject:SetActiveEx(false)
        self.TxtTipTitle.gameObject:SetActiveEx(false)
        return
    end

    if self.TxtTipTitle then
        self.TxtTipTitle.gameObject:SetActiveEx(true)
    end

    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.CurFashionId = fashionId
    self.CurCharacterId = template.CharacterId
    self:RefreshColorDot(template.FashionColorIds)
    local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId)
    local colorId = fashionData and fashionData.ColorId or nil
    if fashionData and not XTool.IsNumberValid(colorId) then
        colorId = 0
    end
    self.ColorId = colorId
end

function XUiFashionColor:RefreshColorDot(colorIds)
    if not colorIds or #colorIds <= 0 then
        self.GameObject:SetActiveEx(false)

        if self.TxtTipTitle then
            self.TxtTipTitle.gameObject:SetActiveEx(false)
        end

        return
    end
    self.GameObject:SetActiveEx(true)

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
    self.BtnGroup:SelectIndex(1)
end

function XUiFashionColor:OnColorDotClick(colorId)
    if not XTool.IsNumberValid(self.CurFashionId) then
        return
    end

    if colorId == 0 then
        colorId = nil
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
    if not XTool.IsNumberValid(self.CurFashionId) then
        return false
    end

    local compareColorId = self.ColorId ~= nil and self.ColorId or 0
    local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(self.CurFashionId)
    local colorId = fashionData and fashionData.ColorId or nil
    return compareColorId ~= colorId
end

return XUiFashionColor
