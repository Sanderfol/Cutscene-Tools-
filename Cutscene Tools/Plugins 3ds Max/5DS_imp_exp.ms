--by ABC_Przyrody (mafiascene.com forum name: Duelist)

If ie5ds != undefined then destroydialog ie5ds

rollout ie5ds "5DS Tools: v1" width:240 height:100
(
	GroupBox grp1 "Animation" pos:[4,5] width:232 height:65
	button doImp "Import" pos:[13,25] width:100 height:35
	button doExp "Export" pos:[127,25] width:100 height:35
	label bout "Author ABC_Przyrody" pos:[70,80] width:110 height:15

	on doImp pressed do
	(
		file = GetOpenFileName types:"5DS animations (*.5ds)|*.5ds|All files (*.*)|*.*"
		if file != undefined do
		(
			undo on
			(
				max create mode
				clearlistener()
				sceneArray = #()
				objNameArray = #()
				linksArray = #()
				frmArray1 = #()
				frmArray2 = #()
				frmArray3 = #()
				frmArray4 = #()
				rotArray = #()
				posArray = #()
				sclArray = #()
				idArray = #()
				
				f = fOpen file "rb"
				header = ReadLong f
				fileVer = ReadShort f
				if fileVer != 20 then return messageBox "Wrong file version"
				fSeek f 0x08 #seek_cur
				dataSize = ReadLong f
				--print header
				--print fileVer
				--print dataSize
				
				numLinks = ReadShort f
				numFrames = ReadShort f
				--print numLinks
				--print numFrames
				
				linkOffSkip = numLinks * 8
				fSeek f linkOffSkip #seek_cur
				
				--test = fTell f
				--print test
				
				--
				for nA = 1 to numLinks do
				(
					--frmArray = #()
					tmpFrmArray1 = #()
					tmpFrmArray2 = #()
					tmpFrmArray3 = #()
					tmpFrmArray4 = #()
					tmpRotArray = #()
					tmpPosArray = #()
					tmpSclArray = #()
					tmpIdArray = #()
					animFlags = ReadLong f
					--print animFlags
					
					--x = bit.and animFlags 8
					--print "--"
					--print nA
					--print "--"
					
					if animFlags == 4 or animFlags == 6 or animFlags == 12 or animFlags == 14 do
					(
						--print "rotation"
						
						numRotKeys = ReadShort f
						--if numRotKeys != undefined then nKeys = numRotKeys
						--print numRotKeys
						
						for nRF = 1 to numRotKeys do
						(
							rotFrame = ReadShort f
							--print rotFrame
							tmpFrmArray1 = append tmpFrmArray1 rotFrame
						)
						
						if mod numRotKeys 2 == 0 then fSeek f 0x02 #seek_cur
						
						for nRF = 1 to numRotKeys do
						(
							rotW = ReadFloat f
							rotX = ReadFloat f
							rotY = ReadFloat f
							rotZ = ReadFloat f
							--print rotW
							--print rotX
							--print rotY
							--print rotZ
							rot = quatToEuler (inverse (quat rotX rotZ rotY rotW))
							tmpRotArray = append tmpRotArray rot
						)
					)
					
					if animFlags == 2 or animFlags == 6 or animFlags == 10 or animFlags == 14 do
					(
						--print "position"
						
						numPosKeys = ReadShort f
						--if numPosKeys != undefined then nKeys = numPosKeys
						--print numPosKeys
						
						for nPF = 1 to numPosKeys do
						(
							posFrame = ReadShort f
							--print posFrame
							tmpFrmArray2 = append tmpFrmArray2 posFrame
						)
						
						if mod numPosKeys 2 == 0 then fSeek f 0x02 #seek_cur
						
						for nPF = 1 to numPosKeys do
						(
							posX = ReadFloat f
							posY = ReadFloat f
							posZ = ReadFloat f
							--print posX
							--print posY
							--print posZ
							pos = Point3 posX posZ posY
							tmpPosArray = append tmpPosArray pos
						)
					)
					
					if animFlags == 8 or animFlags == 10 or animFlags == 12 or animFlags == 14 do
					(
						--print "scale"
						
						numSclKeys = ReadShort f
						--if numSclKeys != undefined then nKeys = numSclKeys
						--print numSclKeys
						
						for nSF = 1 to numSclKeys do
						(
							sclFrame = ReadShort f
							--print sclFrame
							tmpFrmArray3 = append tmpFrmArray3 sclFrame
						)
						
						if mod numSclKeys 2 == 0 then fSeek f 0x02 #seek_cur
						
						for nSF = 1 to numSclKeys do
						(
							sclX = ReadFloat f
							sclY = ReadFloat f
							sclZ = ReadFloat f
							--print sclX
							--print sclY
							--print sclZ
							scl = Point3 sclX sclZ sclY
							tmpSclArray = append tmpSclArray (scl * 100)
						)
					)
					
					if animFlags == 16 do
					(
						--print "niewiadoma"
						
						numUnkKeys = ReadShort f
						--if numPosKeys != undefined then nKeys = numPosKeys
						--print numPosKeys
						
						for nUF = 1 to numUnkKeys do
						(
							unkFrame = ReadShort f
							--print posFrame
							tmpFrmArray4 = append tmpFrmArray4 unkFrame
						)
						
						--if mod numPosKeys 2 == 0 then fseek f 0x02 #seek_cur
						
						for nUF = 1 to numUnkKeys do
						(
							unkValue = ReadShort f
							--pos = Point3 posX posZ posY
							tmpIdArray = append tmpIdArray unkValue
							--print unkValue
						)
						fSeek f 0x02 #seek_cur
					)
					
					--print tmpFrmArray1.count
					--print tmpFrmArray2.count
					--print tmpFrmArray3.count
					--if tmpFrmArray1.count > 0 then 
					frmArray1 = append frmArray1 tmpFrmArray1
					frmArray2 = append frmArray2 tmpFrmArray2
					frmArray3 = append frmArray3 tmpFrmArray3
					frmArray4 = append frmArray4 tmpFrmArray4
					rotArray = append rotArray tmpRotArray
					posArray = append posArray tmpPosArray
					sclArray = append sclArray tmpSclArray
					idArray = append idArray tmpIdArray
				)
				
				for nL = 1 to numLinks do
				(
					meshname = ""
					do
					(
						meshname = meshname + (bit.intAsChar (ReadByte f))
						charTest = fTell f
						--print test
						fSeek f (charTest - 1) #seek_set
					)
					while ReadByte f != 0
					--print meshname
					
					linksArray = append linksArray meshname
				)
				
				--print linksArray
				--print frmArray
				--print rotArray
				--print posArray
				--print sclArray
				--print idArray
				
				fClose f
				--
				
				--/*
				for i = 0 to layerManager.count - 1 do
				(
					ilayer = layerManager.getLayer i
					layerName = ilayer.name
					layer = ILayerManager.getLayerObject i
					layerNodes = refs.dependents layer --nie jest potrzebne
					--if (ilayer.on == true) do
					(
						--numBases += 1
						--baseNameArray = append baseNameArray layerName
						layer.nodes &theNodes
						--print theNodes
						sceneArray = append sceneArray theNodes
					)
					--format "Layer: %; nodes: %\n" layerName layerNodes
				)
				--print sceneArray
				for x = 1 to sceneArray.count do
				(
					for y = 1 to sceneArray[x].count do
					(
						objName = sceneArray[x][y].name
						objNameArray = append objNameArray objName
					)
					--objNameArray = for obj in sceneArray[x] collect obj.name
				)
				--print objNameArray
				--*/
				
				
				animationRange = interval 0 numFrames
				
				for nL = 1 to numLinks do
				(
					linkNode = getNodeByName linksArray[nL]
					--format "Number: %; Node: %\n" nL linksArray[nL]
					--format "Node: %\n" linksArray[nL]
					--print linksArray[nL]
					
					if linkNode != undefined do
					(
						rotC = Euler_XYZ()
						posC = Position_XYZ()
						sclC = ScaleXYZ()
						linkNode.rotation.controller = rotC
						linkNode.position.controller = posC
						linkNode.scale.controller = sclC
						
						if frmArray1[nL].count > 0 do
						(
							--print "rotacja jest"
							--print frmArray1[nL].count
							for nK = 1 to frmArray1[nL].count do
							(
								with animate on
								(
									at time frmArray1[nL][nK] linkNode.rotation.controller.x_rotation = rotArray[nL][nK].x
									at time frmArray1[nL][nK] linkNode.rotation.controller.y_rotation = rotArray[nL][nK].y
									at time frmArray1[nL][nK] linkNode.rotation.controller.z_rotation = rotArray[nL][nK].z
								)
							)
						)
						
						if frmArray2[nL].count > 0 do
						(
							--print "pozycja jest"
							--print frmArray2[nL].count
							for nK = 1 to frmArray2[nL].count do
							(
								with animate on
								(
									at time frmArray2[nL][nK] linkNode.position.controller.x_position = posArray[nL][nK].x
									at time frmArray2[nL][nK] linkNode.position.controller.y_position = posArray[nL][nK].y
									at time frmArray2[nL][nK] linkNode.position.controller.z_position = posArray[nL][nK].z
								)
							)
						)
						
						if frmArray3[nL].count > 0 do
						(
							--print "skala jest"
							--print frmArray2[nL].count
							for nK = 1 to frmArray3[nL].count do
							(
								with animate on
								(
									at time frmArray3[nL][nK] linkNode.scale.controller.x_scale = sclArray[nL][nK].x
									at time frmArray3[nL][nK] linkNode.scale.controller.y_scale = sclArray[nL][nK].y
									at time frmArray3[nL][nK] linkNode.scale.controller.z_scale = sclArray[nL][nK].z
								)
							)
						)
						
						if frmArray4[nL].count > 0 do
						(
							--print "dzwiek jest"
							--print frmArray2[nL].count
							--print frmArray4[nL]
							--print idArray[nL]
							
							addModifier linkNode (emptymodifier())
							unkData = attributes unkData
							(
								parameters main rollout:params
								(
									unkID type:#integer ui:ids default:0
								)
								rollout params "Unknown Parameters"
								( 
									spinner ids "Unk ID" range:[0,65535,0]
								)
							)
							custAttributes.add linkNode.modifiers["Attribute Holder"] unkData
							linkNode.modifiers["Attribute Holder"].unkID.controller = Bezier_Float()
							
							for nK = 1 to frmArray4[nL].count do
							(
								with animate on
								(
									at time frmArray4[nL][nK] linkNode.modifiers["Attribute Holder"].unkID.controller.value = idArray[nL][nK]
								)
							)
							--deleteKey linkNode.modifiers["Attribute Holder"].unkID.controller 1
						)
					)
				)
				--fClose f
			)
		)
	)
	
	on doExp pressed do
	(
		file = GetSaveFileName types:"5DS file (*.5ds)|*.5ds|All files (*.*)|*.*"
		if file != undefined do
		(
			clearlistener()
			sceneArray = #()
			objNameArray = #()
			linksArray = #()
			flagsArray = #()
			frmArray1 = #()
			frmArray2 = #()
			frmArray3 = #()
			frmArray4 = #()
			rotArray = #()
			posArray = #()
			sclArray = #()
			idArray = #()
			nameOffArray = #()
			dataOffArray = #()
			
			for i = 0 to layerManager.count - 1 do
			(
				ilayer = layerManager.getLayer i
				layerName = ilayer.name
				layer = ILayerManager.getLayerObject i
				layerNodes = refs.dependents layer --nie jest potrzebne
				--if (ilayer.on == true) do
				(
					--numBases += 1
					--baseNameArray = append baseNameArray layerName
					layer.nodes &theNodes
					--print theNodes
					sceneArray = append sceneArray theNodes
				)
				--format "Layer: %; nodes: %\n" layerName layerNodes
			)
			--print sceneArray[1]
			
			--/*
			for x = 1 to sceneArray.count do
			(
				for y = 1 to sceneArray[x].count do
				(
					if sceneArray[x][y].ishidden == false then
					(
						objName = sceneArray[x][y].name
						objNameArray = append objNameArray objName
					)
				)
				--objNameArray = for obj in sceneArray[x] collect obj.name
			)
			--print objNameArray
			--*/
			
			for nO = 1 to objNameArray.count do
			(
				sceneNode = getNodeByName objNameArray[nO]
				--print sceneNode
				--print nO
				
				--if sceneNode.rotation.controller.keys.count > 0 or sceneNode.position.controller.keys.count > 0 or sceneNode.scale.controller.keys.count > 0 or sceneNode.modifiers["Attribute Holder"] != undefined do
				if sceneNode.isAnimated == true or sceneNode.modifiers["Attribute Holder"] != undefined do
				(
					--print "cos jest"
					appendifunique linksArray objNameArray[nO]
				)
			)
			--print linksArray
			--print linksArray.count
			
			numLinks = linksArray.count
			numFrames = 0
			dataSize = 4 + (numLinks * 8) --offsets + linki + klatki
			
			for nL = 1 to linksArray.count do
			(
				tmpFrmArray1 = #()
				tmpFrmArray2 = #()
				tmpFrmArray3 = #()
				tmpFrmArray4 = #()
				tmpRotArray = #()
				tmpPosArray = #()
				tmpSclArray = #()
				tmpIdArray = #()
				
				animFlags = 0
				
				linkNode = getNodeByName linksArray[nL]
				--print linkNode
				--print nL
				
				if (linkNode.rotation.controller.keys.count > 0) and (classOf linkNode.rotation.controller == Euler_XYZ) do
				(
					animFlags += 4
					
					for nK = 1 to linkNode.rotation.controller.keys.count do
					(
						rotFrame = (getKeyTime linkNode.rotation.controller nK) as integer / TicksPerFrame
						if rotFrame > numFrames then numFrames = rotFrame
						tmpFrmArray1 = append tmpFrmArray1 rotFrame
						
						rotX = linkNode.rotation.x_rotation.controller.keys[nK].value
						rotY = linkNode.rotation.y_rotation.controller.keys[nK].value
						rotZ = linkNode.rotation.z_rotation.controller.keys[nK].value
						rot = (eulerAngles rotX rotY rotZ) as quat
						tmpRotArray = append tmpRotArray (inverse rot)
					)
					dataSize += 2 + (tmpFrmArray1.count * 2) + (tmpFrmArray1.count * 16)
					if mod tmpFrmArray1.count 2 == 0 then dataSize += 2
				)
				
				if (linkNode.position.controller.keys.count > 0) and (classOf linkNode.position.controller == Position_XYZ) do
				(
					animFlags += 2
					
					for nK = 1 to linkNode.position.controller.keys.count do
					(
						posFrame = (getKeyTime linkNode.position.controller nK) as integer / TicksPerFrame
						if posFrame > numFrames then numFrames = posFrame
						tmpFrmArray2 = append tmpFrmArray2 posFrame
						
						posX = linkNode.position.x_position.controller.keys[nK].value
						posY = linkNode.position.y_position.controller.keys[nK].value
						posZ = linkNode.position.z_position.controller.keys[nK].value
						pos = Point3 posX posY posZ
						tmpPosArray = append tmpPosArray pos
					)
					dataSize += 2 + (tmpFrmArray2.count * 2) + (tmpFrmArray2.count * 12)
					if mod tmpFrmArray2.count 2 == 0 then dataSize += 2
				)
				
				if (linkNode.scale.controller.keys.count > 0) and (classOf linkNode.scale.controller == ScaleXYZ) do
				(
					animFlags += 8
					
					for nK = 1 to linkNode.scale.controller.keys.count do
					(
						sclFrame = (getKeyTime linkNode.scale.controller nK) as integer / TicksPerFrame
						if sclFrame > numFrames then numFrames = sclFrame
						tmpFrmArray3 = append tmpFrmArray3 sclFrame
						
						sclX = linkNode.scale.x_scale.controller.keys[nK].value
						sclY = linkNode.scale.y_scale.controller.keys[nK].value
						sclZ = linkNode.scale.z_scale.controller.keys[nK].value
						scl = Point3 sclX sclY sclZ
						tmpSclArray = append tmpSclArray (scl / 100)
					)
					dataSize += 2 + (tmpFrmArray3.count * 2) + (tmpFrmArray3.count * 12)
					if mod tmpFrmArray3.count 2 == 0 then dataSize += 2
				)
				
				if linkNode.modifiers["Attribute Holder"] != undefined and linkNode.modifiers["Attribute Holder"].unkID.controller.keys.count > 0 do
				(
					animFlags += 16
					
					for nK = 2 to linkNode.modifiers["Attribute Holder"].unkID.controller.keys.count do
					(
						unkFrame = (getKeyTime linkNode.modifiers["Attribute Holder"].unkID.controller nK) as integer / TicksPerFrame
						if unkFrame > numFrames then numFrames = unkFrame
						tmpFrmArray4 = append tmpFrmArray4 unkFrame
						
						unkIdVal = linkNode.modifiers["Attribute Holder"].unkID.controller.keys[nK].value
						tmpIdArray = append tmpIdArray unkIdVal
					)
					dataSize += 2 + (tmpFrmArray4.count * 2) + (tmpFrmArray4.count * 2) + 2
				)
				
				dataSize += 4 + (linksArray[nL].count + 1) --flagi + dl nazw
				
				flagsArray = append flagsArray animFlags
				frmArray1 = append frmArray1 tmpFrmArray1
				frmArray2 = append frmArray2 tmpFrmArray2
				frmArray3 = append frmArray3 tmpFrmArray3
				frmArray4 = append frmArray4 tmpFrmArray4
				rotArray = append rotArray tmpRotArray
				posArray = append posArray tmpPosArray
				sclArray = append sclArray tmpSclArray
				idArray = append idArray tmpIdArray
				
				--print animFlags
			)
			--print frmArray1[1][1][1]
			--print (getkeytime $.rotation.controller 3)
			
			--print linksArray
			--print flagsArray
			--print rotArray
			--print frmArray1
			--print frmArray2
			--print frmArray3
			--print dataSize
			
			--write block
			f = fOpen file "wb"
			
			WriteString f "5DS"
			WriteShort f 0x0014
			WriteLong f 0x7D2D0000
			WriteLong f 0x01D47951
			WriteLong f dataSize
			WriteShort f numLinks
			WriteShort f numFrames
			
			for nL = 1 to numLinks do --offsets placeholder
			(
				WriteLong f 0x00
				WriteLong f 0x00
			)
			
			for nL = 1 to numLinks do
			(
				dataOff = fTell f
				dataOffArray = append dataOffArray (dataOff - 18)
				
				WriteLong f flagsArray[nL]
				
				if frmArray1[nL].count > 0 do
				(
					WriteShort f frmArray1[nL].count
					
					for nF = 1 to frmArray1[nL].count do
					(
						WriteShort f frmArray1[nL][nF]
					)
					
					if mod frmArray1[nL].count 2 == 0 then WriteShort f 0x00
					
					for nF = 1 to frmArray1[nL].count do
					(
						WriteFloat f rotArray[nL][nF].w
						WriteFloat f rotArray[nL][nF].x
						WriteFloat f rotArray[nL][nF].z
						WriteFloat f rotArray[nL][nF].y
					)
				)
				
				if frmArray2[nL].count > 0 do
				(
					WriteShort f frmArray2[nL].count
					
					for nF = 1 to frmArray2[nL].count do
					(
						WriteShort f frmArray2[nL][nF]
					)
					
					if mod frmArray2[nL].count 2 == 0 then WriteShort f 0x00
					
					for nF = 1 to frmArray2[nL].count do
					(
						WriteFloat f posArray[nL][nF].x
						WriteFloat f posArray[nL][nF].z
						WriteFloat f posArray[nL][nF].y
					)
				)
				
				if frmArray3[nL].count > 0 do
				(
					WriteShort f frmArray3[nL].count
					
					for nF = 1 to frmArray3[nL].count do
					(
						WriteShort f frmArray3[nL][nF]
					)
					
					if mod frmArray3[nL].count 2 == 0 then WriteShort f 0x00
					
					for nF = 1 to frmArray3[nL].count do
					(
						WriteFloat f sclArray[nL][nF].x
						WriteFloat f sclArray[nL][nF].z
						WriteFloat f sclArray[nL][nF].y
					)
				)
				
				if frmArray4[nL].count > 0 do
				(
					WriteShort f frmArray4[nL].count
					
					for nF = 1 to frmArray4[nL].count do
					(
						WriteShort f frmArray4[nL][nF]
					)
					
					for nF = 1 to frmArray4[nL].count do
					(
						WriteShort f idArray[nL][nF]
					)
					
					WriteShort f 0x00
				)
			)
			
			for nL = 1 to numLinks do
			(
				nameOff = fTell f
				nameOffArray = append nameOffArray (nameOff - 18)
				
				WriteString f linksArray[nL]
			)
			
			fSeek f 0x16 #seek_set
			for nL = 1 to numLinks do
			(
				WriteLong f nameOffArray[nL]
				WriteLong f dataOffArray[nL]
			)
			
			--print nameOffArray
			--print dataOffArray
			
			fClose f
			
			messageBox "Animation(s) successfully exported." title:"Animation export"
		)
	)
)
createDialog ie5ds;
