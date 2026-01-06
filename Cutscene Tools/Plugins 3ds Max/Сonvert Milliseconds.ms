try(DestroyDialog ::frameConverter)catch()

rollout frameConverter "Frame Converter FPS:25" width:250 height:150
(
    editText msInput "Milliseconds:" fieldWidth:50 pos:[15,30]
    label msLabel "" pos:[130,32]
    
    editText frameInput "Frames:" fieldWidth:50 pos:[15,70]
    label frameLabel "" pos:[130,72]
    
    button convertBtn "Convert" width:80 pos:[85,110]
    
    on msInput entered text do
    (
        if text != "" do
        (
            local ms = text as number
            if ms != undefined do
            (
                frames = ms / 40.0  -- 1000ms / 25fps = 40ms per frame
                frameInput.text = frames as string
                msLabel.text = "ms"
                frameLabel.text = "frames"
            )
        )
    )
    
    on frameInput entered text do
    (
        if text != "" do
        (
            local frames = text as number
            if frames != undefined do
            (
                ms = frames * 40.0  -- 25fps = 40ms per frame
                msInput.text = ms as string
                msLabel.text = "ms"
                frameLabel.text = "frames"
            )
        )
    )
    
    on convertBtn pressed do
    (
        if msInput.text != "" then
            msInput.entered msInput.text
        else if frameInput.text != "" then
            frameInput.entered frameInput.text
    )
)

CreateDialog frameConverter
