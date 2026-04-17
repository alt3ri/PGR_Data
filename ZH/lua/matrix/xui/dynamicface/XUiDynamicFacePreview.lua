---@class XUiDynamicFacePreview : XLuaUi
local XUiDynamicFacePreview = XLuaUiManager.Register(XLuaUi, "UiDynamicFacePreview")

function XUiDynamicFacePreview:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
end

function XUiDynamicFacePreview:OnStart(package)
    -- 刷新动态表情
    local firstDynamicEmojiId = package:GetFirstDynamicEmojiId()
    if firstDynamicEmojiId then
        -- 名字
        local emojiName = XDataCenter.ChatManager.GetEmojiName(firstDynamicEmojiId)
        self.TxtName.text = emojiName
  
        -- 描述
        self.TxtDesc.text = XDataCenter.ChatManager.GetEmojiWorldDesc(firstDynamicEmojiId) 

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
