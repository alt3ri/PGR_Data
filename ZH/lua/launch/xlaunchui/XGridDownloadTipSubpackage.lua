---@class XGridDownloadTipSubpackage
local XGridDownloadTipSubpackage = {}
local XLaunchDlcManager = require("XLaunchDlcManager")

function XGridDownloadTipSubpackage.New(gameObj, parentProxy)
    local class = {}
    setmetatable(class, { __index = XGridDownloadTipSubpackage })

    class._DownFlag = true
    class._ClickLock = false
    class.GameObject = gameObj
    class.Parent = parentProxy
    class.XUiButton = gameObj:GetComponent(typeof(CS.XUiComponent.XUiButton))
    class.XUiButton.CallBack = function()
        class:OnBtnClick()
    end

    return class
end

function XGridDownloadTipSubpackage:RegisterClickCb(cb)
    self.Cb = cb
end

function XGridDownloadTipSubpackage:Init(data)
    local totalSize = 0
    local resSizeDic = XLaunchDlcManager.GetResSizeDic()
    
    local validResIds = {}
    for _, resId in ipairs(data.ResIdList) do
        local size = resSizeDic[resId]
        if size then
            totalSize = totalSize + size
            table.insert(validResIds, resId)
        else
            print(string.format("XGridDownloadTipSubpackage:Init resId %s not found", resId))
        end
    end
    self.ResIdList = validResIds

    local num, unit = self:GetSizeAndUnit(totalSize)
    self.TotalNum = num
    self.TotalSize = totalSize
    self.BaseUnit = unit

    local descBase = string.format("<b>%0.2f%s</b>", self.TotalNum, self.BaseUnit)
    self.XUiButton:SetNameByGroup(2, descBase)
    self.XUiButton:SetNameByGroup(1, data.Desc)
    self.XUiButton:SetNameByGroup(0, data.Name)
end

function XGridDownloadTipSubpackage:GetTotalSize()
    return self.TotalSize or 0
end

function XGridDownloadTipSubpackage:GetSizeAndUnit(size)
    local unit = "KB"
    local num = size / 1024
    if (num > 100) then
        unit = "MB"
        num = num / 1024
    end
    return num,unit
end

function XGridDownloadTipSubpackage:OnBtnClick()
    if self._ClickLock then 
        self.XUiButton:SetButtonState(CS.UiButtonState.Normal)
        return 
    end

    self._DownFlag = not self._DownFlag
    self:RefreshWithCb()
end

function XGridDownloadTipSubpackage:RefreshWithCb()
    self:RefreshButtonState()
    if self.Cb then self.Cb() end
end

function XGridDownloadTipSubpackage:Refresh()
    self:RefreshButtonState()
end

function XGridDownloadTipSubpackage:RefreshButtonState()
    if self._DownFlag then
        self.XUiButton:SetButtonState(CS.UiButtonState.Select)
    else
        self.XUiButton:SetButtonState(CS.UiButtonState.Normal)
    end
end

-- 下载标记，为true说明要下载，而且会打勾
function XGridDownloadTipSubpackage:GetDownFlag()
    return self._DownFlag
end

function XGridDownloadTipSubpackage:SetDownFlag(flag)
    self._DownFlag = flag
end

function XGridDownloadTipSubpackage:SetClickLock(flag)
    self._ClickLock = flag
end

return XGridDownloadTipSubpackage