-- Export cameras for Mafia (.rep-like JSON) with correct time conversion (3ds Max -> Mafia ticks (ms))
fn convertToMafiaCoordinate maxPos =
(
    [maxPos.x, maxPos.z, maxPos.y]
)

fn formatFloat value =
(
    local str = value as string
    str = substituteString str "," "."
    str
)

fn getCameraKeys camera =
(
    local keys = #()
    if isProperty camera #position and isProperty camera.position.controller #keys then
    (
        for k in camera.position.controller.keys do 
            append keys k.time
    )
    return keys
)

-- Function to convert 3ds Max FOV to radians
fn getFovInRadians camera =
(
    local fovDegrees = camera.fov
    local fovRadians = fovDegrees * (pi / 180.0)
    return fovRadians
)

-- Function to get tangent values from 3ds Max keyframe for Position controllers
fn getPositionKeyTangents controller keyTime =
(
    local inTangent = [0, 0, 0]
    local outTangent = [0, 0, 0]
    
    try
    (
        -- For Position controllers, we need to check each axis separately
        if classOf controller == Position_XYZ then
        (
            -- Get individual controllers for each axis
            local xController = controller.x_controller
            local yController = controller.y_controller
            local zController = controller.z_controller
            
            -- Try to get tangents for each axis
            if classOf xController == Bezier_Float then
            (
                local xKey = getKey xController keyTime
                if xKey != undefined then
                (
                    inTangent.x = xKey.inTangent
                    outTangent.x = xKey.outTangent
                )
            )
            
            if classOf yController == Bezier_Float then
            (
                local yKey = getKey yController keyTime
                if yKey != undefined then
                (
                    inTangent.y = yKey.inTangent
                    outTangent.y = yKey.outTangent
                )
            )
            
            if classOf zController == Bezier_Float then
            (
                local zKey = getKey zController keyTime
                if zKey != undefined then
                (
                    inTangent.z = zKey.inTangent
                    outTangent.z = zKey.outTangent
                )
            )
        )
        else if classOf controller == Bezier_Position then
        (
            -- For Bezier_Position controller, try to get the key directly
            local key = getKey controller keyTime
            if key != undefined then
            (
                if isProperty key #inTangent then inTangent = key.inTangent
                if isProperty key #outTangent then outTangent = key.outTangent
            )
        )
    )
    catch
    (
        -- If any error occurs, return zero tangents
        inTangent = [0, 0, 0]
        outTangent = [0, 0, 0]
    )
    
    return #(inTangent, outTangent)
)

-- Fallback function to calculate tangents when we can't get them from 3ds Max
fn calculateTangent prevPos currentPos nextPos isFirst isLast =
(
    if isFirst and nextPos != undefined then
    (
        -- First key: use forward difference
        (nextPos - currentPos)
    )
    else if isLast and prevPos != undefined then
    (
        -- Last key: use backward difference
        (currentPos - prevPos)
    )
    else if prevPos != undefined and nextPos != undefined then
    (
        -- Middle keys: use central difference
        (nextPos - prevPos) / 2.0
    )
    else
    (
        [0, 0, 0]
    )
)

fn exportCameras =
(
    -- Get all cameras in the scene and sort by name
    allCameras = for obj in objects where superClassOf obj == Camera collect obj
    fn camNameCompare a b = stricmp a.name b.name
    qsort allCameras camNameCompare
    
    if allCameras.count == 0 then
    (
        messageBox "No cameras found in the scene."
        return undefined
    )

   
	fps = frameRate 
    ticksPerSecond = 4800.0
    ticksPerFrame = ticksPerSecond / fps

    -- Collect all keys from all cameras and targets
    globalAllKeys = #()
    for cam in allCameras do
    (
        if cam.target != undefined then
        (
            camKeys = getCameraKeys cam
            targetKeys = getCameraKeys cam.target
            join globalAllKeys camKeys
            join globalAllKeys targetKeys
        )
    )
    globalAllKeys = makeUniqueArray globalAllKeys
    sort globalAllKeys
    if globalAllKeys.count > 0 then
        minTime = globalAllKeys[1]
    else
        minTime = 0

    cameraData = #()
    focusData = #()
    defaultUnkType = 1
    defaultRollView = 0

    -- Process each camera in order
    for cam in allCameras do
    (
        if cam.target == undefined then
        (
            format "Camera % has no target and will be skipped.\n" cam.name
            continue
        )
        
        camTarget = cam.target
        
        -- Get all keyframes for this camera and target
        camKeys = getCameraKeys cam
        targetKeys = getCameraKeys camTarget
        
        -- Combine and sort all keys
        allKeys = makeUniqueArray (join camKeys targetKeys)
        sort allKeys
        
        if allKeys.count == 0 then
            append allKeys (currentTime as float)

        -- Process each keyframe for this camera
        for i = 1 to allKeys.count do
        (
            frameTime = allKeys[i]
            frameTimeFloat = (frameTime as float)
            
            -- Convert 3ds Max ticks to Mafia milliseconds relative to minTime
            timeInMs = ((frameTimeFloat - minTime) / ticksPerSecond) * 1000.0
            timeInMsInt = (timeInMs as integer)

            at time frameTime
            (
                -- Get FOV in radians
                local fovRadians = getFovInRadians(cam)
                
                camPos = convertToMafiaCoordinate cam.pos
                targetPos = convertToMafiaCoordinate camTarget.pos

                -- Try to get real tangents from 3ds Max for camera
                local camInTangent = [0, 0, 0]
                local camOutTangent = [0, 0, 0]
                local useRealTangents = false
                
                if isProperty cam #position then
                (
                    local tangents = getPositionKeyTangents cam.position.controller frameTime
                    camInTangent = convertToMafiaCoordinate tangents[1]
                    camOutTangent = convertToMafiaCoordinate tangents[2]
                    
                    -- Check if we got non-zero tangents
                    if length camInTangent > 0.001 or length camOutTangent > 0.001 then
                        useRealTangents = true
                )
                
                -- If real tangents are zero, calculate them from positions
                if not useRealTangents then
                (
                    -- Calculate tangents for camera based on positions
                    prevCamPos = undefined
                    nextCamPos = undefined
                    
                    if i > 1 then
                        at time allKeys[i-1] prevCamPos = convertToMafiaCoordinate cam.pos
                    if i < allKeys.count then
                        at time allKeys[i+1] nextCamPos = convertToMafiaCoordinate cam.pos
                    
                    isFirst = (i == 1)
                    isLast = (i == allKeys.count)
                    local calculatedTangent = calculateTangent prevCamPos camPos nextCamPos isFirst isLast
                    camInTangent = calculatedTangent
                    camOutTangent = calculatedTangent
                )

                -- Try to get real tangents from 3ds Max for target
                local targetInTangent = [0, 0, 0]
                local targetOutTangent = [0, 0, 0]
                local useRealTargetTangents = false
                
                if isProperty camTarget #position then
                (
                    local tangents = getPositionKeyTangents camTarget.position.controller frameTime
                    targetInTangent = convertToMafiaCoordinate tangents[1]
                    targetOutTangent = convertToMafiaCoordinate tangents[2]
                    
                    -- Check if we got non-zero tangents
                    if length targetInTangent > 0.001 or length targetOutTangent > 0.001 then
                        useRealTargetTangents = true
                )
                
                -- If real tangents are zero, calculate them from positions
                if not useRealTargetTangents then
                (
                    -- Calculate tangents for target based on positions
                    prevTargetPos = undefined
                    nextTargetPos = undefined
                    
                    if i > 1 then
                        at time allKeys[i-1] prevTargetPos = convertToMafiaCoordinate camTarget.pos
                    if i < allKeys.count then
                        at time allKeys[i+1] nextTargetPos = convertToMafiaCoordinate camTarget.pos
                    
                    isFirst = (i == 1)
                    isLast = (i == allKeys.count)
                    local calculatedTangent = calculateTangent prevTargetPos targetPos nextTargetPos isFirst isLast
                    targetInTangent = calculatedTangent
                    targetOutTangent = calculatedTangent
                )

                -- Create camera entry
                camEntry = #()
                append camEntry timeInMsInt
                append camEntry timeInMsInt
                append camEntry defaultUnkType
                append camEntry #(camPos.x, camPos.y, camPos.z)
                append camEntry #(camInTangent.x, camInTangent.y, camInTangent.z)  -- Curve (in tangent)
                append camEntry #(camOutTangent.x, camOutTangent.y, camOutTangent.z) -- SubCurve (out tangent)
                append camEntry defaultRollView
                append camEntry fovRadians
                append camEntry cam.name

                -- Create focus entry
                focusEntry = #()
                append focusEntry timeInMsInt
                append focusEntry timeInMsInt
                append focusEntry defaultUnkType
                append focusEntry #(targetPos.x, targetPos.y, targetPos.z)
                append focusEntry #(targetInTangent.x, targetInTangent.y, targetInTangent.z)  -- Curve (in tangent)
                append focusEntry #(targetOutTangent.x, targetOutTangent.y, targetOutTangent.z) -- SubCurve (out tangent)
                append focusEntry camTarget.name

                append cameraData camEntry
                append focusData focusEntry
            )
        )
    )

    -- Initialize jsonString
    jsonString = ""
    
    -- Build JSON string only if we have camera data
    if cameraData.count > 0 then
    (
        jsonString = "{\"version\":1,\"fps\":" + (fps as string) + ",\"ticksPerSecond\":4800,\"cameras\":["

        for i = 1 to cameraData.count do
        (
            cam = cameraData[i]
            jsonString += "{"
            jsonString += "\"frameA_Chank\":" + (cam[1] as string) + ","
            jsonString += "\"frameB_Chank\":" + (cam[2] as string) + ","
            jsonString += "\"unkType\":" + (cam[3] as string) + ","
            jsonString += "\"position\":[" + (formatFloat cam[4][1]) + "," + (formatFloat cam[4][2]) + "," + (formatFloat cam[4][3]) + "],"
            jsonString += "\"curve\":[" + (formatFloat cam[5][1]) + "," + (formatFloat cam[5][2]) + "," + (formatFloat cam[5][3]) + "],"
            jsonString += "\"subCurve\":[" + (formatFloat cam[6][1]) + "," + (formatFloat cam[6][2]) + "," + (formatFloat cam[6][3]) + "],"
            jsonString += "\"rollView\":" + (formatFloat cam[7]) + ","
            jsonString += "\"fov\":" + (formatFloat cam[8]) + ","
            jsonString += "\"cameraName\":\"" + cam[9] + "\""
            jsonString += "}"

            if i < cameraData.count then jsonString += ","
        )

        jsonString += "],\"focuses\":["

        for i = 1 to focusData.count do
        (
            focus = focusData[i]
            jsonString += "{"
            jsonString += "\"frameA_Focus\":" + (focus[1] as string) + ","
            jsonString += "\"frameB_Focus\":" + (focus[2] as string) + ","
            jsonString += "\"unkType\":" + (focus[3] as string) + ","
            jsonString += "\"position\":[" + (formatFloat focus[4][1]) + "," + (formatFloat focus[4][2]) + "," + (formatFloat focus[4][3]) + "],"
            jsonString += "\"curve\":[" + (formatFloat focus[5][1]) + "," + (formatFloat focus[5][2]) + "," + (formatFloat focus[5][3]) + "],"
            jsonString += "\"subCurve\":[" + (formatFloat focus[6][1]) + "," + (formatFloat focus[6][2]) + "," + (formatFloat focus[6][3]) + "],"
            jsonString += "\"targetName\":\"" + focus[7] + "\""
            jsonString += "}"

            if i < focusData.count then jsonString += ","
        )

        jsonString += "]}"
    )
    else
    (
        messageBox "No camera data to export."
        return undefined
    )

    -- Save to JSON file
    outputFile = getSaveFileName caption:"Export Cameras" types:"JSON (*.json)|*.json"
    if outputFile != undefined then
    (
        file = createFile outputFile
        format "%" jsonString to:file
        close file

        messageBox ("Export completed successfully. FPS: " + (fps as string) + ". Exported " + (cameraData.count as string) + " camera positions from " + (allCameras.count as string) + " cameras.")
    )
)

-- Execute export
exportCameras()




