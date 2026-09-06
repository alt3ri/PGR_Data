local XUiGridTransfiniteTowerTeachRole = require("XUi/XUiTransfiniteTower/Grid/XUiGridTransfiniteTowerTeachRole")

---@class XUiTransfiniteTowerTeach : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field TopControl UnityEngine.RectTransform
---@field GridFormationRole UnityEngine.GameObject
---@field TxtRoleName UnityEngine.UI.Text
---@field Video XVideoPlayerUGUI
---@field TxtModeBuff UnityEngine.UI.Text
---@field TxtBuffDec UnityEngine.UI.Text
---@field BtnEnterTeach XUiComponent.XUiButton
local XUiTransfiniteTowerTeach = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerTeach")

function XUiTransfiniteTowerTeach:OnAwake()
    self:InitTopControl()
    self:InitVideo()
    self:RegisterButtonEvent()
end

---@param defaultSelectCharId number 可选，打开时默认选中的领航员角色id（从角色详情跳转用）
function XUiTransfiniteTowerTeach:OnStart(defaultSelectCharId)
    self._DefaultSelectCharId = defaultSelectCharId
end

function XUiTransfiniteTowerTeach:OnEnable()
    self:Refresh()
end

function XUiTransfiniteTowerTeach:OnDestroy()
    self:StopVideo()
end

--region 初始化

function XUiTransfiniteTowerTeach:InitTopControl()
    self._TopControl = XUiHelper.NewPanelTopControl(self, self.TopControl)
end

function XUiTransfiniteTowerTeach:InitVideo()
    -- Video 节点已在 prefab 上挂 XVideoPlayerUGUI，直接使用，无需动态加载
    self.Video.IsLooping = true  -- 自动循环播放
    self.Video.VideoPlayerInst.loop = true
end

function XUiTransfiniteTowerTeach:RegisterButtonEvent()
    self.BtnEnterTeach:AddEventListener(handler(self, self.OnBtnEnterTeachClick))
end

--endregion

--region 刷新

function XUiTransfiniteTowerTeach:Refresh()
    self:RefreshRoleList()
end

function XUiTransfiniteTowerTeach:RefreshRoleList()
    self._RoleGrids = self._RoleGrids or {}
    self._RoleDataList = self._Control:GetTeachPilotList()

    XTool.UpdateDynamicItem(self._RoleGrids, self._RoleDataList, self.GridFormationRole,
        XUiGridTransfiniteTowerTeachRole, self)

    -- 默认选中：优先匹配跳转指定的角色，否则第一个（重置保证重复进入生效）
    self._SelectedIndex = nil
    if not XTool.IsTableEmpty(self._RoleDataList) then
        self:OnRoleSelected(self:GetDefaultSelectIndex())
    end
end

---默认选中下标：匹配 _DefaultSelectCharId 对应的领航员，无匹配则第一个
function XUiTransfiniteTowerTeach:GetDefaultSelectIndex()
    if XTool.IsNumberValid(self._DefaultSelectCharId) then
        for i = 1, #self._RoleDataList do
            if self._Control:GetPilotCharacterId(self._RoleDataList[i]) == self._DefaultSelectCharId then
                return i
            end
        end
    end
    return 1
end

---刷新右侧领航员详情（名称/视频/强化名/强化文本）
function XUiTransfiniteTowerTeach:RefreshRoleDetail()
    local data = self._RoleDataList[self._SelectedIndex]
    self.TxtRoleName.text = self._Control:GetPilotName(data)
    self.TxtModeBuff.text = self._Control:GetPilotBuffName(data)
    self.TxtBuffDec.text = XUiHelper.ReplaceTextNewLine(self._Control:GetPilotBuffDesc(data))
    self:RefreshVideo()
end

function XUiTransfiniteTowerTeach:RefreshVideo()
    local videoId = self._Control:GetPilotVideoId(self._RoleDataList[self._SelectedIndex])
    if XTool.IsNumberValid(videoId) then
        self.Video.IsLooping = true
        self.Video:SetInfoByVideoId(videoId)
        self.Video:RePlay()
    end
end

function XUiTransfiniteTowerTeach:StopVideo()
    self.Video:Stop()
end

--endregion

--region 头像选中

function XUiTransfiniteTowerTeach:OnRoleSelected(index)
    if self._SelectedIndex == index then
        return
    end
    self._SelectedIndex = index
    -- 刷新所有头像格子的选中态
    for i = 1, #self._RoleGrids do
        self._RoleGrids[i]:SetSelect(self:IsRoleSelected(i))
    end
    self:RefreshRoleDetail()
end

function XUiTransfiniteTowerTeach:IsRoleSelected(index)
    return self._SelectedIndex == index
end

--endregion

--region 按钮回调

function XUiTransfiniteTowerTeach:OnBtnEnterTeachClick()
    self._Control:EnterTeachStage(self._RoleDataList[self._SelectedIndex])
end

--endregion

return XUiTransfiniteTowerTeach
