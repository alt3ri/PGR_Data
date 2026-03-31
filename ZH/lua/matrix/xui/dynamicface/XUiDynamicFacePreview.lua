---@class XUiDynamicFacePreview : XLuaUi
local XUiDynamicFacePreview = XLuaUiManager.Register(XLuaUi, "UiDynamicFacePreview")

function XUiDynamicFacePreview:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
end

function XUiDynamicFacePreview:OnStart(package)
    -- 表情包名字
    local name = package:GetName()
    self.TxtName.text = name

    -- 表情包描述
    local desc = package:GetDesc()
    self.TxtDesc.text = desc

    -- 刷新动态表情
    local firstDynamicEmojiId = package:GetFirstDynamicEmojiId()
    if firstDynamicEmojiId then
        self:RefreshDynamicFace(firstDynamicEmojiId)
    end
end

-- 刷新动态表情
function XUiDynamicFacePreview:RefreshDynamicFace(emojiId)
    if not self.dynamicFaceId then
        self.dynamicFaceId = XDataCenter.ChatManager.CreateDynamicFace(self.ImgIcon, emojiId)
    else
        XDataCenter.ChatManager.SetDynamicFaceAtlas(self.dynamicFaceId, emojiId)
    end
end

function XUiDynamicFacePreview:OnRelease()
    -- 释放动态表情
    self:ReleaseDynamicFace()
end

-- 释放动态表情
function XUiDynamicFacePreview:ReleaseDynamicFace()
    if self.dynamicFaceId then
        XDataCenter.ChatManager.ReleaseDynamicFace(self.dynamicFaceId)
        self.dynamicFaceId = nil
    end
end

return XUiDynamicFacePreview
