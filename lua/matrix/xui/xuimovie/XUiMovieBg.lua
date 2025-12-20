---@class XUiMovieBg
---@field UiMovie XUiMovie
local XUiMovieBg = XClass(nil, "XUiMovieBg")

-- 负责控制剧情界面的背景图
function XUiMovieBg:Ctor(uiMovie)
    self.UiMovie = uiMovie
    self.BgDic = {}
    self:OnAwake()
end

function XUiMovieBg:OnAwake()
    
end

function XUiMovieBg:OnDestroy()
    self.BgDic = nil
end

function XUiMovieBg:GetBgDic()
    return self.BgDic
end

-- 获取背景
---@return XUiGridMovieBg
function XUiMovieBg:GetBg(index)
    local bg = self.BgDic[index]
    if not bg then
        local link = self.UiMovie["RImgBg" .. index]
        if link then
            bg = require("XUi/XUiMovie/XUiGridMovieBg").New(self.UiMovie, link)
            self.BgDic[index] = bg
        end
    end
    return bg
end

return XUiMovieBg

