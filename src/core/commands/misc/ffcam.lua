local cmd = {
	name = script.Name,
	desc = [[A]],
	usage = "$ A",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local method = args[1]

		local guicam = pCsi.libs.GUICamera
		local camerafolder = workspace.Cameras

		

		if method == "stream" then
            for i, v in ipairs(essentials.Output:GetAllDevices()) do
                if v.SurfaceGui and v.DeviceType == "Monitor" and v.SurfaceGui:FindFirstChild("Background") and v.Resolution.X == 1920 and v.Resolution.Y == 1080 then
                    local newcam = guicam:Clone()
                    newcam.Enabled = false
                    
                    local came = args[2] and tostring(args[2]) or nil
                    if not came then pCsi.io.write("Enter a camera name >"); came = pCsi.io.read() end
                     
                    if camerafolder:FindFirstChild(came) then
                        newcam.CameraValue.Value = camerafolder:FindFirstChild(came)
                        pCsi.io.write("Set camera")
                    end
                    newcam.Adornee = v.SurfaceGui.Parent
                    newcam.ScreenValue.Value = v.SurfaceGui.Parent
                    newcam.Parent = plr.PlayerGui
    
                    pCsi.io.write(
                        "Starting stream.. -- Write anything to stop, write a valid CameraName to change to that camera"
                    )
                    task.wait(4)
                    newcam.ViewportCameraController.Disabled = false
    
                    v.SurfaceGui:FindFirstChild("Background").Visible = false
                    newcam.Enabled = true
                    
                    local oldparse = pCsi.parseCommand
                    function pCsi:parseCommand(...)
                        input = { ... }
                        local plra = input[1]
                        table.remove(input, 1)
                        input = table.concat(input)
                        if camerafolder:FindFirstChild(input) then
                            newcam.ViewportCameraController.Disabled = true
    
                            v.SurfaceGui:FindFirstChild("Background").Visible = true
                            newcam.Enabled = false
                            newcam.CameraValue.Value = camerafolder:FindFirstChild(input)
    
                            task.wait(0.1)
    
                            newcam.ViewportCameraController.Disabled = false
                            v.SurfaceGui:FindFirstChild("Background").Visible = false
                            newcam.Enabled = true
                        else
                            newcam.ViewportCameraController.Disabled = true
                            task.wait(0.1)
                            newcam.Enabled = false
                            v.SurfaceGui:FindFirstChild("Background").Visible = true
                            newcam:Destroy()
                            pCsi.parseCommand = oldparse
                            pCsi.io.write("Stopped stream")
                        end
                    end
    
                    break
                end
            end
		end
	end,
}

return cmd
