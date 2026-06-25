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
    local gridText = uiObj:GetObject("GridText")
    gridText.text = XUiHelper.ConvertLineBreakSymbol(content)
    self:_ApplyChannelOffsetTo(gridText)
    
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
function XUiPanelText:TextPlayAnim(id, time, pos, rotation, scale, ease)
    local uiObj = self.TextDic[id]
    if not uiObj then
        XLog.Error(string.format("暂无文本%s，播放动画失败!", id))
        return
    end

    local second = time
    local rect = uiObj:GetObject("GridTextRect")
    if pos then
        local aimPos = XLuaVector3.New(pos[1], pos[2], pos[3] or 0)
        local tween = rect:DOAnchorPos3D(aimPos, second)
        if ease and tween then
            tween:SetEase(ease)
        end
    end

    if rotation then
        local addRotate = XLuaVector3.New(0, 0, rotation)
        local tween = rect.transform:DORotate(addRotate, second, CS.DG.Tweening.RotateMode.LocalAxisAdd)
        if ease and tween then
            tween:SetEase(ease)
        end
    end

    if scale then
        local tween = rect.transform:DOScale(scale, second)
        if ease and tween then
            tween:SetEase(ease)
        end
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

-- 设置色相偏移:仅存状态,作用于此后 AppearText 新建/复用的文本,不追溯已显示文本
function XUiPanelText:SetChannelOffset(expansionScale, offsetMultiplier, r, g, b)
    self.ChannelOffsetState = {
        ExpansionScale = expansionScale,
        OffsetMultiplier = offsetMultiplier,
        R = r,
        G = g,
        B = b,
    }
end

function XUiPanelText:ClearChannelOffset()
    self.ChannelOffsetState = nil
end

function XUiPanelText:_ApplyChannelOffsetTo(txt)
    if XTool.UObjIsNil(txt) then
        return
    end
    local addon = txt.gameObject:GetComponent("XChannelOffsetTextAddon")
    if XTool.UObjIsNil(addon) then
        return
    end
    local state = self.ChannelOffsetState
    if not state then
        addon:Revert()
        return
    end
    if state.ExpansionScale ~= nil then
        addon.ExpansionScale = state.ExpansionScale
    end
    if state.OffsetMultiplier ~= nil then
        addon.ChannelOffsetMultiplier = state.OffsetMultiplier
    end
    if state.R ~= nil then
        addon.ChannelOffsetR = state.R
    end
    if state.G ~= nil then
        addon.ChannelOffsetG = state.G
    end
    if state.B ~= nil then
        addon.ChannelOffsetB = state.B
    end
    addon:Apply()
end

return XUiPanelText