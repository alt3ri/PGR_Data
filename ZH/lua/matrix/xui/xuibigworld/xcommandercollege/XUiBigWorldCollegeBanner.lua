local XUiBigWorldCollegeBanner = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldCollegeBanner")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigWorldGridCollegeStudy = require("XUi/XUiBigWorld/XCommanderCollege/XUiBigWorldGridCollegeStudy")

local FirstTagId = 4
local SecondTagId = 1

function XUiBigWorldCollegeBanner:OnAwake()

end

function XUiBigWorldCollegeBanner:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()

    self:InitData()
    self:_InitUi()
    self:_RegisterButtonClicks()
    self:SetupDynamicTable()
end

function XUiBigWorldCollegeBanner:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldCollegeBanner:OnDestroy()
end

function XUiBigWorldCollegeBanner:_InitUi()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiBigWorldGridCollegeStudy)
    self.CurrentManagerList = self.TagManagerDic[self.AllSecondTag[SecondTagId].Id]
    self.GridCollegeBanner.gameObject:SetActive(false)
end
function XUiBigWorldCollegeBanner:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiBigWorldCollegeBanner:_RegisterSchedules()
end

function XUiBigWorldCollegeBanner:_RegisterListeners()
end

function XUiBigWorldCollegeBanner:_RegisterRedPointEvents()
end

function XUiBigWorldCollegeBanner:_RemoveSchedules()
end

function XUiBigWorldCollegeBanner:_RemoveListeners()
end

function XUiBigWorldCollegeBanner:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldCollegeBanner:InitData()
    self.AllSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(FirstTagId) -- 拿到该模式下所有的二级标签
    self.TagManagerDic = {}
    for _, secondTagconfig in pairs(self.AllSecondTag) do
        if not self.TagManagerDic[secondTagconfig.Id] then
            self.TagManagerDic[secondTagconfig.Id] = {}
        end
        for k, chapterType in pairs(secondTagconfig.ChapterType) do
            -- 需要判断章节是否开启
            local chapterTypeShowCondition = secondTagconfig.ChapterTypeShowCondition[k]

            if not XTool.IsNumberValidEx(chapterTypeShowCondition) or
                XConditionManager.CheckCondition(chapterTypeShowCondition) then
                for k, manager in pairs(XDataCenter.FubenManagerEx.GetManagers(chapterType)) do
                    table.insert(self.TagManagerDic[secondTagconfig.Id], manager) -- 根据2级标签拿到所有manager
                end
            end

        end
        table.sort(self.TagManagerDic[secondTagconfig.Id], function(managerA, managerB)
            return managerA:ExGetConfig().Priority < managerB:ExGetConfig().Priority
        end)
    end
end

-- 设置动态列表
function XUiBigWorldCollegeBanner:SetupDynamicTable(bReload)
    self.DynamicTable:SetDataSource(self.CurrentManagerList)
    self.DynamicTable:ReloadDataSync(bReload and 1 or -1)

end

-- 动态列表事件
function XUiBigWorldCollegeBanner:OnDynamicTableEvent(event, index, grid)
    -- XLog.Error("OnDynamicTableEvent")    
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.CurrentManagerList[index], index, self.DynamicTable:GetFirstUseGridIndexAndUseCount())
    end
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    --     self:OnClickChapterGrid(self.CurrentManagerList[index])
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
    -- end
end

return XUiBigWorldCollegeBanner
