local XUiGridItem = XClass(nil, "XUiGridItem")

function XUiGridItem:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridItem:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridItem:AutoInitUi()
    self.ImgItemCountBg = self.Transform:Find("ImgItemCountBg"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.ImgItemIcon = self.Transform:Find("ImgItemIcon"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.ImgItemBg = self.Transform:Find("ImgItemBg"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.TxtItemCount = self.Transform:Find("TxtItemCount"):GetComponent(typeof(CS.UnityEngine.UI.Text))
end

function XUiGridItem:GetAutoKey(uiNode,eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiGridItem:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGridItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key],eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridItem:AutoAddListener()
    self.AutoCreateListeners = {}
end
-- auto

function XUiGridItem:UpdateItemGrid(itemInfo)
    local itemTemplate = XDataCenter.ItemManager.GetItemTemplate(itemInfo.Id)
    self.RootUi:SetUiSprite(self.ImgItemIcon, itemTemplate.Icon)
    self.TxtItemCount.text = itemInfo.Count
end

return