local XUiPhotographFashionColor = XClass(XUiNode, "XUiPhotographFashionColor")

local function NormalizeColorId(colorId)
    return XTool.IsNumberValid(colorId) and colorId or 0
end

function XUiPhotographFashionColor:OnStart(...)

end

function XUiPhotographFashionColor:Refresh(fashionId)
    if self.CurFashionId ~= fashionId then
        local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId)
        local colorId = fashionData and fashionData.ColorId or nil
        if fashionData and not XTool.IsNumberValid(colorId) then
            colorId = 0
        end
        self.SelectColorId = colorId
    end
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
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
    self.TxtTipTitle.gameObject:SetActiveEx(true)
    self:Open()

    local tempColorIds = { 0 }
    for index, colorId in ipairs(colorIds) do
          if not XMVCA.XFashion:IsFashionColorHas(self.CurFashionId, colorId) then
                goto continue
            end
            table.insert(tempColorIds, colorId)
            ::continue::
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
        ui.BtnDotNormal:SetDisable(hasColor)
        table.insert(btnGroup, ui.BtnDotNormal)
    end, false)
    self.PanelDot:Init(btnGroup, function(index)
        local colorId = tempColorIds[index]
        self:OnColorDotClick(colorId)
    end)
    local selectIndex = 1
    local currentColorId = NormalizeColorId(self.SelectColorId)
    for index, colorId in ipairs(tempColorIds) do
        if NormalizeColorId(colorId) == currentColorId then
            selectIndex = index
            break
        end
    end
    self.PanelDot:SelectIndex(selectIndex, false)
end


function XUiPhotographFashionColor:OnColorDotClick(colorId)
    if NormalizeColorId(self.SelectColorId) == NormalizeColorId(colorId) then
        return
    end

    self.SelectColorId = colorId
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_MODEL, self.CurCharacterId, self.CurFashionId,
        colorId)
end

function XUiPhotographFashionColor:ChangeFashionColor()
    local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(self.CurFashionId)
    local colorId = fashionData and fashionData.ColorId or nil
    if fashionData and not XTool.IsNumberValid(colorId) then
        colorId = 0
    end
    return self.SelectColorId ~= colorId
end

function XUiPhotographFashionColor:GetSelectColorId()
    return self.SelectColorId
end

return XUiPhotographFashionColor
