---@class XUiPanelText
local XUiPanelText = XClass(XUiNode, "XUiPanelText")

function XUiPanelText:OnStart()
    self.GridText1.gameObject:SetActiveEx(false)
    self.GridText2.gameObject:SetActiveEx(false)
    self.GridText3.gameObject:SetActiveEx(false)
    self.TextDic = {}
end

-- 显示文本
function XUiPanelText:AppearText(layer, id, content, posX, posY, scale, rotation, isAnim)
    local text = self.TextDic[id]
    if not text then
        text = XUiHelper.Instantiate(self["GridText"..layer], self.TextList.transform)
        self.TextDic[id] = text
    end
    text.gameObject:SetActiveEx(true)
    text.text = XUiHelper.ConvertLineBreakSymbol(content)
    local Vector3 = CS.UnityEngine.Vector3
    text.transform.localPosition = Vector3(posX, posY, 0)
    text.transform.localScale = Vector3(scale, scale, scale)
    text.transform.eulerAngles = Vector3(0, 0, rotation)
    if isAnim then
        local anim = XUiHelper.TryGetComponent(text.transform, "Ainmation/GridTextEnable")
        anim:PlayTimelineAnimation()
    else
        text.transform:GetComponent("CanvasGroup").alpha = 1
    end
    return text
end

-- 隐藏指定id的文本
function XUiPanelText:DisAppearText(id, isAnim)
    local text = self.TextDic[id]
    if isAnim then
        local anim = XUiHelper.TryGetComponent(text.transform, "Ainmation/GridTextDisable")
        anim:PlayTimelineAnimation(function()
            text.gameObject:SetActiveEx(false)
        end)
    else
        text.gameObject:SetActiveEx(false)
    end
end

-- 隐藏所有文本
function XUiPanelText:DisAppearAllText()
    for _, text in pairs(self.TextDic) do
        text.gameObject:SetActiveEx(false)
    end
end

-- 文本播放动画
function XUiPanelText:TextPlayAnim(id, time, pos, rotation, scale)
    local text = self.TextDic[id]
    if not text then
        XLog.Error(string.format("暂无文本%s，播放动画失败!", id))
        return
    end

    local second = time
    if pos then
        local aimPos = XLuaVector3.New(pos[1], pos[2], pos[3] or 0)
        text.transform:DOLocalMove(aimPos, second)
    end

    if rotation then
        local addRotate = XLuaVector3.New(0, 0, rotation)
        text.transform:DORotate(addRotate, second, CS.DG.Tweening.RotateMode.LocalAxisAdd)
    end

    if scale then
        text.transform:DOScale(scale, second)
    end
end

function XUiPanelText:GetText(id)
    return self.TextDic[id]
end

return XUiPanelText