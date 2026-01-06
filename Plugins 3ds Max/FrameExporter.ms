fn getKeyTimes obj = (
    local keyTimes = #()
    
    try (
        if obj.pos.controller != undefined and isProperty obj.pos.controller #keys do (
            for k in obj.pos.controller.keys do (
                appendIfUnique keyTimes k.time
            )
        )
        
        if obj.rotation.controller != undefined and isProperty obj.rotation.controller #keys do (
            for k in obj.rotation.controller.keys do (
                appendIfUnique keyTimes k.time
            )
        )
    ) catch (
        format "Error in getKeyTimes: %\n" (getCurrentException())
    )
    
    if keyTimes.count > 0 do (
        fn compareTimes a b = (
            if a < b then -1 else if a > b then 1 else 0
        )
        qsort keyTimes compareTimes
    )
    
    return keyTimes
)

fn timeToMilliseconds t = (
    local ticksPerFrame = 160
    local fps = 30.0
    local ticks = t as float
    local frames = ticks / ticksPerFrame
    return (frames / fps * 1000.0) as integer
)

fn formatArrayForJson arr isFloatArray:false = (
    local result = "["
    for i = 1 to arr.count do (
        if isFloatArray then (
            result += formattedPrint arr[i] format:".6f"
        ) else (
            result += arr[i] as string
        )
        if i < arr.count do result += ", "
    )
    result += "]"
    return result
)

fn convertQuaternionToMafiaSystem quat = (
    local tempDummy = Dummy()
    tempDummy.rotation = quat
    
    local transformMatrix = matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0]
    local finalMatrix = transformMatrix * tempDummy.transform * inverse transformMatrix
    
    delete tempDummy
    
    local resultQuat = finalMatrix.rotation
    resultQuat.z = -resultQuat.z  -- ?????????????? z-??????????
    return resultQuat
)


fn getLocalTransform obj = (
    if obj.parent != undefined then (
        local parentInv = inverse obj.parent.transform
        local localTransform = obj.transform * parentInv
        return localTransform
    ) else (
        return obj.transform
    )
)

rollout exportDialog "Export Frames" (
    dropdownlist typeDropdown "Frame Type:" items:#("FrameHumanA", "FrameHumanB", "FrameCar", "FrameActor")
    checkbox allKeysChk "Export All Keyframes" checked:false
    radiobuttons coordSysRadio "Coordinate System:" labels:#("Parent", "World") default:1
    button exportBtn "Export to JSON"

    on exportBtn pressed do (
        local exportData = #()
        local selectionType = typeDropdown.selection
        local exportAll = allKeysChk.state
        local useWorldCoords = (coordSysRadio.state == 2)
        
        -- Get selected object
        if selection.count != 1 then (
            messageBox "Please select exactly one object!" title:"Error"
            return undefined
        )
        
        local targetObj = selection[1]
        local keyTimes = getKeyTimes(targetObj)
        
        if keyTimes.count == 0 then (
            messageBox "No animation keys found!" title:"Error"
            return undefined
        )
        
        local timesToExport = if exportAll then keyTimes else #(keyTimes[1])
        
        for t in timesToExport do (
            animate on (
                at time t (
                    local pos, rot
                    if useWorldCoords then (
                        pos = targetObj.transform.pos
                        rot = convertQuaternionToMafiaSystem(targetObj.transform.rotation)
                    ) else (
                        local localTransform = getLocalTransform targetObj
                        pos = localTransform.pos
                        rot = convertQuaternionToMafiaSystem(localTransform.rotation)
                    )
                    local frameTime = timeToMilliseconds(t)
                    
                    local frameData = #()
                    append frameData ("\"frameA\": " + frameTime as string)
                    
                    case selectionType of (
                        1: (
                            append frameData "\"type\": 1"
                            append frameData ("\"position\": " + formatArrayForJson #(pos.x, pos.z, pos.y) isFloatArray:true)
                            append frameData ("\"rotation\": " + formatArrayForJson #(rot.w, rot.x, rot.y, rot.z) isFloatArray:true)
                            append frameData "\"animationID\": 0"
                        )
                        2: (
                            append frameData "\"type\": 2"
                            append frameData ("\"position\": " + formatArrayForJson #(pos.x, pos.z, pos.y) isFloatArray:true)
                            append frameData ("\"rotation\": " + formatArrayForJson #(rot.w, rot.x, rot.y, rot.z) isFloatArray:true)
                            append frameData "\"animationID\": 0"
                            append frameData "\"animationOffset\": 0"
                        )
                        3: (
                            append frameData "\"type\": 1"
                            append frameData ("\"position\": " + formatArrayForJson #(pos.x, pos.z, pos.y) isFloatArray:true)
                            append frameData ("\"rotation\": " + formatArrayForJson #(rot.w, rot.x, rot.y, rot.z) isFloatArray:true)
                            append frameData "\"unk1\": 0"
                            append frameData "\"unk2\": 0"
                        )
                        4: (
                            append frameData "\"type\": 1"
                            append frameData ("\"position\": " + formatArrayForJson #(pos.x, pos.z, pos.y) isFloatArray:true)
                            append frameData ("\"rotation\": " + formatArrayForJson #(rot.w, rot.x, rot.y, rot.z) isFloatArray:true)
                            append frameData ("\"unks\": " + formatArrayForJson #(0.0, 0.0, 0.0, 0.0, 0.0, 0.0) isFloatArray:true)
                            append frameData "\"unkUInts\": [0, 0, 0, 0, 0, 0, 0, 0]"
                        )
                    )
                    append exportData frameData
                )
            )
        )
        
        local jsonFile = getSaveFileName caption:"Export JSON" types:"JSON (*.json)|*.json"
        if jsonFile == undefined then (
            messageBox "Export cancelled by user!" title:"Info"
            return undefined
        )
        
        local file = createFile jsonFile
        if file == undefined then (
            messageBox "Failed to create file!" title:"Error"
            return undefined
        )
        
        format "{\n" to:file
        format "\t\"version\": 1,\n" to:file
        format "\t\"cameras\": [],\n" to:file
        format "\t\"focuses\": [],\n" to:file
        
        local sectionName = case selectionType of (
            1: "humanFramesA"
            2: "humanFramesB"
            3: "carFrames"
            4: "actorFrames"
        )
        
        format ("\t\"" + sectionName + "\": [\n") to:file
        for i = 1 to exportData.count do (
            format "\t\t{\n" to:file
            for j = 1 to exportData[i].count do (
                if j < exportData[i].count then
                    format "\t\t\t%,\n" exportData[i][j] to:file
                else
                    format "\t\t\t%\n" exportData[i][j] to:file
            )
            if i < exportData.count then
                format "\t\t},\n" to:file
            else
                format "\t\t}\n" to:file
        )
        format "\t]\n" to:file
        format "}" to:file
        
        close file
        messageBox ("Export completed successfully!\nExported " + exportData.count as string + " frames.") title:"Info"
    )
)

createDialog exportDialog width:200 height:160