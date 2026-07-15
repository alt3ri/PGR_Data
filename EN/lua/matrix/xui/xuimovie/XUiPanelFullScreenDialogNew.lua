local tableRemove = table.remove
local tableInsert = table.insert
local stringUtf8Len = string.Utf8Len
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local CSDOTween = CS.DG.Tweening.DOTween

---@class XUiPanelFullScreenDialogNew : XUiNode
local XUiPanelFullScreenDialogNew = XClass(XUiNode, "XUiPanelFullScreenDialogNew")

function XUiPanelFullScreenDialogNew:OnStart()
    local width = self.PanelContents.rect.width
    self.GridSingleDialog.sizeDelta = XLuaVector2.New(width, self.GridSingleDialog.sizeDelta.y)
    self.TxtWordsRect.sizeDelta = XLuaVector2.New(width, self.TxtWordsRect.sizeDelta.y)
    self.GridSingleDialog.gameObject:SetActiveEx(false)
    self.FADE_ALPHA = 0.2 -- 淡化透明度
    self.FADE_TIME = 0.3 -- 淡化透明度时间
    self.TextColor = self.TxtWords.color
    
    self.ShowDialogUiObjs = {} -- 当前显示的
    self.RecycleDialogUiObjs = {} -- 回收的
    self.ChannelOffsetState = nil -- 当前色相偏移快照,作用于此后新建/复用的对白行
end

-- 设置色相偏移状态,仅作用于后续 ShowDialog 创建/复用的行,不追溯影响已显示行
function XUiPanelFullScreenDialogNew:SetChannelOffset(expansionScale, offsetMultiplier, r, g, b)
    self.ChannelOffsetState = {
        ExpansionScale = expansionScale,
        OffsetMultiplier = offsetMultiplier,
        R = r,
        G = g,
        B = b,
    }
end

function XUiPanelFullScreenDialogNew:ClearChannelOffset()
    self.ChannelOffsetState = nil
end

function XUiPanelFullScreenDialogNew:_ApplyChannelOffsetTo(txtWords)
    if XTool.UObjIsNil(txtWords) then return end
    local addon = txtWords.gameObject:GetComponent("XChannelOffsetTextAddon")
    if XTool.UObjIsNil(addon) then return end
    local state = self.ChannelOffsetState
    if not state then
        addon:Revert()
        return
    end
    if state.ExpansionScale ~= nil then addon.ExpansionScale = state.ExpansionScale end
    if state.OffsetMultiplier ~= nil then addon.ChannelOffsetMultiplier = state.OffsetMultiplier end
    if state.R ~= nil then addon.ChannelOffsetR = state.R end
    if state.G ~= nil then addon.ChannelOffsetG = state.G end
    if state.B ~= nil then addon.ChannelOffsetB = state.B end
    addon:Apply()
end

function XUiPanelFullScreenDialogNew:OnEnable()
    self.Parent:PlayAnimation("FullScreenDialogNewEnable")
end

function XUiPanelFullScreenDialogNew:OnDisable()
    self:CompleteFadeTween()
    self:RecycleAllDialog()
end

function XUiPanelFullScreenDialogNew:CloseWithAnimation()
    if self.IsClosing then return end

    self.IsClosing = true
    self.Parent:PlayAnimation("FullScreenDialogNewDisable", function()
        self.IsClosing = false
        self:Close()
    end)
end

-- 获取一个文本
function XUiPanelFullScreenDialogNew:ShowDialog(content, isIgnoreTypeWrite, typeWriteTime, typeWriterCb)
    -- 上一个文本淡化
    if #self.ShowDialogUiObjs > 0 then
        self:CompleteFadeTween()
        local lastUiObj = self.ShowDialogUiObjs[#self.ShowDialogUiObjs]
        local lastTxtWords = lastUiObj:GetObject("TxtWords")
        self.FadeTween = CSDOTween.To(function()
            return lastTxtWords.color.a
        end, function(alpha)
            lastTxtWords.color = CS.UnityEngine.Color(self.TextColor.r, self.TextColor.g, self.TextColor.b, alpha)
        end, self.FADE_ALPHA, self.FADE_TIME)
    end
    
    -- 创建新的文本
    local uiObj = tableRemove(self.RecycleDialogUiObjs)
    if not uiObj then
        local go = CSInstantiate(self.GridSingleDialog, self.PanelContents)
        uiObj = go:GetComponent(typeof(CS.UiObject))
    end
    uiObj.gameObject:SetActiveEx(true)
    uiObj.transform:SetAsLastSibling()
    tableInsert(self.ShowDialogUiObjs, uiObj)

    local txtWords = uiObj:GetObject("TxtWords")
    local typeWriter = uiObj:GetObject("TypeWriter")
    txtWords.text = content
    txtWords.color = self.TextColor
    self:_ApplyChannelOffsetTo(txtWords)
    if not isIgnoreTypeWrite then
        typeWriter.CompletedHandle = typeWriterCb
        typeWriter.Duration = typeWriteTime ~= 0 and typeWriteTime or stringUtf8Len(content) * XMovieConfigs.TYPE_WRITER_SPEED
        typeWriter:Play()
    end
    
    local index = #self.ShowDialogUiObjs
    return index
end

-- 创建空文本
function XUiPanelFullScreenDialogNew:CreateEmptyDialog(count)
    for i = 1, count do
        self:ShowDialog("", true)
    end
end

-- 完成一个文本打字
function XUiPanelFullScreenDialogNew:CompleteDialogTypeWriter(index)
    local uiObj = self.ShowDialogUiObjs[index]
    local typeWriter = uiObj:GetObject("TypeWriter")
    typeWriter:Complete()
end

-- 回收所有的文本
function XUiPanelFullScreenDialogNew:RecycleAllDialog()
    for _, uiObj in pairs(self.ShowDialogUiObjs) do
        local typeWriter = uiObj:GetObject("TypeWriter")
        typeWriter:Stop()
        uiObj.gameObject:SetActiveEx(false)
        tableInsert(self.RecycleDialogUiObjs, uiObj)
    end
    self.ShowDialogUiObjs = {}

    self:ShowImgNext(false)
    self.ChannelOffsetState = nil -- Panel 关闭即清状态,下次打开干净
end

-- 显示翻页图标
function XUiPanelFullScreenDialogNew:ShowImgNext(isShow)
    self.ImgNext.gameObject:SetActiveEx(isShow)
end

function XUiPanelFullScreenDialogNew:CompleteFadeTween()
    if self.FadeTween then
        self.FadeTween:Complete()
        self.FadeTween = nil
    end
end

return XUiPanelFullScreenDialogNew