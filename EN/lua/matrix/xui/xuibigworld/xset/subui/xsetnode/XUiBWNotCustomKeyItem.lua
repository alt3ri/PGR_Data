local XUiBWBtnKeyItem = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWBtnKeyItem")
local XUiBWNotCustomKeyItem = XClass(XUiBWBtnKeyItem, "XUiBWNotCustomKeyItem")
local XCSInputManager = CS.XInputManager
local XCSXInputMapId = CS.XInputMapId

function XUiBWNotCustomKeyItem:Refresh(data, cb, resetTextOnly, curInputMapId, curOperationType)
    self:SetData(data, cb, curInputMapId, curOperationType)
    
    local isKeyboard = self:IsKeyboard()
    local operationKey = self.DefaultKeyMapTable and self.DefaultKeyMapTable.OperationKey

    self.TxtTitle.text = self.Data.Title
    if operationKey and self._KeySetType then
        if isKeyboard then
            self.GroupRecommend.gameObject:SetActiveEx(false)
        else
            self.GroupRecommend.gameObject:SetActiveEx(true)
        end
        
        local isCustom = XCSInputManager.IsCustomKey(operationKey, 0, self._KeySetType, self.CurOperationType)
        self.BtnKeyItem.enabled = isCustom
        local name = XCSInputManager.GetKeyCodeString(self._KeySetType, 
            XCSXInputMapId.__CastFrom(self.CurInputMapId), 
            operationKey, 
            XCSInputManager.XOperationType.__CastFrom(self.CurOperationType))
        self.BtnKeyItem:SetName(name)
        if (resetTextOnly == true) then
            return
        end

        self:SetRecommendText(operationKey)
    else
        self.GroupRecommend.gameObject:SetActiveEx(false)
        self.BtnKeyItem.enabled = false
        self.TxtKeyName.text = ""
    end
end

return XUiBWNotCustomKeyItem