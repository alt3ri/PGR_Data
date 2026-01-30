local XUiAreaWarPanelTips = XLuaUiManager.Register(XLuaUi, "UiAreaWarPanelTips")
function XUiAreaWarPanelTips:OnStart()

    
end

function XUiAreaWarPanelTips:BindDropPanel()
    self.QualityDic = {}
    for index,itemConfig in pairs(self.Parent._Control:GetConfig():GetConfigItem()) do
        if not self.QualityDic[itemConfig.Quality] then
            self.QualityDic[itemConfig.Quality] = {}
        end
        if self.Parent.Parent._Control:IsItemUnlock(self.ItemId) then
            table.insert(self.QualityDic[itemConfig.Quality],itemConfig.ItemId)
        end
    end

      local bindObj = function(panel,v)
        local temp = {}
        local obj = XTool.InitUiObjectByUi(temp,panel)
        obj.TxtNum = "x"..self.Parent.OriginProbability.."%"

        return obj
    end
    for k,v in pairs(self.QualityDic) do
        local prefab = CS.UnityEngine.GameObject.Instantiate(self.PanelCollectionDrop.gameObject, self.PanelCollectionDrop.parent.transform)
        bindObj(prefab,v)
    end

end
return XUiAreaWarPanelTips