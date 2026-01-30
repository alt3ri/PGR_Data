--- pvp任务领取界面
---@class XUiTheatre5ChooseTask: XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5ChooseTask = XLuaUiManager.Register(XLuaUi, 'UiTheatre5ChooseTask')
local XUiTheatre5GridTaskDetail = require('XUi/XUiTheatre5/XUiTheatre5ChooseTask/XUiTheatre5GridTaskDetail')

function XUiTheatre5ChooseTask:OnAwake()
    self.BtnCharacterDetail:AddEventListener(handler(self, self.OnClickCharacterDetail))
end

function XUiTheatre5ChooseTask:OnStart()
    
end

function XUiTheatre5ChooseTask:OnEnable()
    self:RefreshMissionShow()
end

function XUiTheatre5ChooseTask:RefreshMissionShow()
    local missionData = self._Control.MissionControl:GetChooseMissions()

    if self._GridTaskMap == nil then
        ---@type XUiTheatre5GridTaskDetail[]
        self._GridTaskMap = {}
    else
        for i, v in pairs(self._GridTaskMap) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.UiTheatre5GridTaskDetail.transform.parent, self.UiTheatre5GridTaskDetail, missionData and #missionData or 0, function(index, go)
        local grid = self._GridTaskMap[go]

        if not grid then
            grid = XUiTheatre5GridTaskDetail.New(go, self)
            
            self._GridTaskMap[go] = grid
        end
        
        grid:Open()
        grid:SetPosInChoose(index)
        grid:Refresh(XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InChoose, missionData[index])
    end)
end

function XUiTheatre5ChooseTask:OnClickCharacterDetail()
    XLuaUiManager.Open("UiTheatre5PVECheckCharacter")
end

return XUiTheatre5ChooseTask