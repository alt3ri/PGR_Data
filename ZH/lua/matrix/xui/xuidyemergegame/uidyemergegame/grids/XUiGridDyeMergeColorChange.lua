local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

--- 变色方块
---@class XUiGridDyeMergeColorChange: XUiGridDyeMerge
---@field protected _Control XDyeMergeGameControl
---@field Parent
---@field RImgBg @地块UI，设置底色
---@field RImgObject @图标
---@field RImgDiban @长条预制才有的引用
---@field BtnChange @点击切换颜色的按钮
---@field GridColor @可选颜色节点
local XUiGridDyeMergeColorChange = XClass(XUiGridDyeMerge, "XUiGridDyeMergeColorChange")

function XUiGridDyeMergeColorChange:OnStart()
    XUiGridDyeMerge.OnStart(self)
    if self.BtnChange then
        self.BtnChange:AddEventListener(handler(self, self._OnBtnChangeClick))
    end
end

---@overload
function XUiGridDyeMergeColorChange:Refresh(uid)
    self.Uid = uid
    self:EnterNormalDisplay()

    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then return end
    local blockCfg = self._Control.GamingControl:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then return end

    local curColorId = block:GetChangeableColorIndex()
    local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(curColorId)
    if not colorCfg then return end

    self.RImgBg:SetRawImage(colorCfg.IconNormal)
    if self.RImgDiban then
        self.RImgDiban:SetRawImage(colorCfg.IconNormalBig)
    end

    self:SetFlowerVisible(true, colorCfg.IconSupprtTop)

    self:_RefreshColorOptions(blockCfg.Params, curColorId)
end

--- 根据可切换颜色列表动态展示颜色选项节点
---@param colorList number[]
function XUiGridDyeMergeColorChange:_RefreshColorOptions(colorList, curColorId)
    if not self.GridColor then return end

    -- 首次调用：隐藏模板，初始化克隆缓存
    if not self._ColorGrids then
        self._ColorGrids = {}
        self.GridColor.gameObject:SetActiveEx(false)
    end

    local count = colorList and #colorList or 0

    self._GridColorPoints = XUiHelper.RefreshUiObjectList(self._GridColorPoints, self.GridColor.transform.parent, self.GridColor, count, function(index, ui)
        local colorId = colorList[index]
        local color = self._Control.GamingControl:GetCfgDyeMergeBlocksColor(colorId, false)

        if ui.GridColor then
            ui.GridColor.color = color
        end

        if ui.ImgSelect then
            ui.ImgSelect.gameObject:SetActiveEx(curColorId == colorId)
        end
    end)
    
end

function XUiGridDyeMergeColorChange:_OnBtnChangeClick()
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self.Uid)
    end
end

--- 通关后播放供色骨骼动画
function XUiGridDyeMergeColorChange:RefreshOnStagePass(uid)
    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then return end

    local curColorId = block:GetChangeableColorIndex()
    local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(curColorId)
    if not colorCfg then return end

    self:EnterPassDisplay(colorCfg)
end

return XUiGridDyeMergeColorChange