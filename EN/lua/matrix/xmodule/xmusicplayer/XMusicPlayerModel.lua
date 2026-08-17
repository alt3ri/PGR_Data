---@class XMusicPlayerModel : XModelBase
local XMusicPlayerModel = XClass(XModelBase, "XMusicPlayerModel")

function XMusicPlayerModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._CdViewModel = self:AddSubModel(require('XModule/XMusicPlayer/Model/XMusicPlayerCDViewModel'))
    self._MusicListModel = self:AddSubModel(require('XModule/XMusicPlayer/Model/XMusicPlayerMusicListModel'))
    self._CommonSystemBgmModel = self:AddSubModel(require('XModule/XMusicPlayer/Model/XMusicPlayerCommonSystemBgmModel'))
end

function XMusicPlayerModel:ClearPrivate()
    --这里执行内部数据清理
end

function XMusicPlayerModel:ResetAll()
    --这里执行重登数据清理
end

---@return XMusicPlayerCDViewModel
function XMusicPlayerModel:GetCDViewModel()
    return self._CdViewModel
end

---@return XMusicPlayerMusicListModel
function XMusicPlayerModel:GetMusicListModel()
    return self._MusicListModel
end

---@return XMusicPlayerCommonSystemBgmModel
function XMusicPlayerModel:GetCommonSystemBgmModel()
    return self._CommonSystemBgmModel
end


  
 
return XMusicPlayerModel