---@class XUiPanelText
local XUiPanelText = XClass(XUiNode, "XUiPanelText")

function XUiPanelText:OnStart()
    self.GridText1.gameObject:SetActiveEx(false)
    self.GridText2.gameObject:SetActiveEx(false)
    self.GridText3.gameObject:SetActiveEx(false)
    self.TextDic = {}
end

-- 显示文本
function XUiPanelText:AppearText(layer, id, content, posX, posY, scale, rotation, isAnim, anchorType)
    local uiObj = self.TextDic[id]
    if not uiObj then
        uiObj = XUiHelper.Instantiate(self["GridText"..layer], self.TextList.transform)
        self.TextDic[id] = uiObj
    end
    uiObj.gameObject:SetActiveEx(true)
    uiObj:GetObject("GridText").text = XUiHelper.ConvertLineBreakSymbol(content)
    
    -- 对齐方式
    local rect = uiObj:GetObject("GridTextRect")
    local params = XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE_TO_PARAM[anchorType]
    rect.anchorMin = XLuaVector2.New(params[1], params[2])
    rect.anchorMax = XLuaVector2.New(params[3], params[4])

    rect.transform.anchoredPosition3D = XLuaVector3.New(posX, posY, 0)
    rect.transform.localScale = XLuaVector3.New(scale, scale, scale)
    rect.transform.eulerAngles = XLuaVector3.New(0, 0, rotation)
    
    -- 动画
    if isAnim then
        local anim = uiObj:GetObject("GridTextEnable")
        anim.transform:PlayTimelineAnimation()
    else
        uiObj:GetObject("CanvasGroup").alpha = 1
    end
    return uiObj
end

-- 隐藏指定id的文本
function XUiPanelText:DisAppearText(id, isAnim)
    local uiObj = self.TextDic[id]
    if isAnim and uiObj.gameObject.activeSelf then
        local anim = uiObj:GetObject("GridTextDisable")
        anim.transform:PlayTimelineAnimation(function()
            uiObj.gameObject:SetActiveEx(false)
        end)
    else
        uiObj.gameObject:SetActiveEx(false)
    end
end

-- 隐藏所有文本
function XUiPanelText:DisAppearAllText()
    for _, uiObj in pairs(self.TextDic) do
        uiObj.gameObject:SetActiveEx(false)
    end
end

-- 文本播放动画
function XUiPanelText:TextPlayAnim(id, time, pos, rotation, scale)
    local uiObj = self.TextDic[id]
    if not uiObj then
        XLog.Error(string.format("暂无文本%s，播放动画失败!", id))
        return
    end

    local second = time
    local rect = uiObj:GetObject("GridTextRect")
    if pos then
        local aimPos = XLuaVector3.New(pos[1], pos[2], pos[3] or 0)
        rect:DOAnchorPos3D(aimPos, second)
    end

    if rotation then
        local addRotate = XLuaVector3.New(0, 0, rotation)
        rect.transform:DORotate(addRotate, second, CS.DG.Tweening.RotateMode.LocalAxisAdd)
    end

    if scale then
        rect.transform:DOScale(scale, second)
    end
end

function XUiPanelText:GetText(id)
    return self.TextDic[id]
end

function XUiPanelText:SetTextRootLocalPosition(id, pos)
    local uiObj = self.TextDic[id]
    local root = uiObj:GetObject("Root")
    root.localPosition = pos
end

return XUiPanelText