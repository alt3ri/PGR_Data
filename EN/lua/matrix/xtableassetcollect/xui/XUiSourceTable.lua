local this = XClass(nil, "XUiSourceTable")

function this:Ctor()
    self.uiKeyToPrefabUrlMap = {}
end

function this:Init(uiSourceTablePath)
    self.uiKeyToPrefabUrlMap = {}

    local tableContent = CS.XTableManager.LoadFileFromDebugDir(uiSourceTablePath)
    local tableLineDataList = string.Split(tableContent, "\r\n")

    local ColNameToIndexMap = {}

    for i = 1, #tableLineDataList do
        local lineData = string.Split(tableLineDataList[i], "\t")

        if i == 1 then
            for col, colName in ipairs(lineData) do
                ColNameToIndexMap[colName] = col
            end
        else
            local uiKey = lineData[ColNameToIndexMap["UiName"]]
            local prefabUrl =  lineData[ColNameToIndexMap["PrefabUrl"]]

            if uiKey ~= nil then
                self.uiKeyToPrefabUrlMap[uiKey] = prefabUrl
            end
        end
    end
end

function this:GetPrefabUrl(uiKey)
    return self.uiKeyToPrefabUrlMap[uiKey]
end

return this