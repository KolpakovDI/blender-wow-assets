-- OtakuCityDistrict - anime hub plaza/alleys/north strip/approach
-- Layout: sidewalks clear; shops set back with open doorways + shallow interiors.
-- Visual refs: Akihabara Electric Town (signage layers, spill light, LED) + stylized JP street packs.
return function(api)
	local makePart = api.makePart
	local addPoster = api.addPoster
	local addStandee = api.addStandee
	local addLEDDisplay = api.addLEDDisplay
	local ZoneConfig = api.ZoneConfig

	-- Does not move Spawn, QuestMaster, Safe/Genkan/Exit/Combat anchors.
	local function build(haven, center, half)
		local old = haven:FindFirstChild("CityDistrict")
		if old then
			old:Destroy()
		end
		local district = Instance.new("Folder")
		district.Name = "CityDistrict"
		district.Parent = haven

		local function surfaceGuiLabel(part, text, color, face)
			local sg = Instance.new("SurfaceGui")
			sg.Name = "SignGui"
			sg.Face = face or Enum.NormalId.Front
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 40
			sg.Parent = part
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextScaled = true
			lbl.Parent = sg
			return sg
		end

		local function neonBillboard(part, text, color, offsetY)
			local bb = Instance.new("BillboardGui")
			bb.Name = "NeonLabel"
			bb.Size = UDim2.new(0, 140, 0, 40)
			bb.StudsOffset = Vector3.new(0, offsetY or 1.2, 0)
			bb.AlwaysOnTop = false
			bb.Parent = part
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = color or Color3.fromRGB(255, 120, 220)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextScaled = true
			lbl.Parent = bb
		end

		local function addPointLight(parent, color, brightness, range)
			local pl = Instance.new("PointLight")
			pl.Color = color
			pl.Brightness = brightness
			pl.Range = range
			pl.Parent = parent
			return pl
		end

		-- Tall cantilever kanban (classic Electric Town vertical blade sign)
		local function addVerticalKanban(name, basePos, faceDir, text, color, height)
			local right = Vector3.new(-faceDir.Z, 0, faceDir.X)
			local pole = makePart({
				Name = name .. "_Pole",
				Size = Vector3.new(0.28, height or 9, 0.28),
				Position = basePos + Vector3.new(0, (height or 9) * 0.5, 0),
				Color = Color3.fromRGB(40, 42, 52),
				Material = Enum.Material.Metal,
				CanCollide = false,
				Parent = district,
			})
			local blade = makePart({
				Name = name,
				Size = Vector3.new(0.35, (height or 9) * 0.72, 1.8),
				Position = basePos + right * 1.15 + Vector3.new(0, (height or 9) * 0.55, 0) + faceDir * 0.2,
				Color = color,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = district,
			})
			surfaceGuiLabel(blade, text, Color3.fromRGB(20, 20, 30), Enum.NormalId.Right)
			surfaceGuiLabel(blade, text, Color3.fromRGB(20, 20, 30), Enum.NormalId.Left)
			addPointLight(blade, color, 0.45, 12)
			return pole
		end

		local function addChochin(name, pos, color)
			local lamp = makePart({
				Name = name,
				Size = Vector3.new(1.1, 1.4, 1.1),
				Position = pos,
				Color = color or Color3.fromRGB(255, 90, 70),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = district,
			})
			lamp.Shape = Enum.PartType.Cylinder
			lamp.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
			addPointLight(lamp, lamp.Color, 0.5, 10)
			return lamp
		end

		local function addLanternPole(name, pos, color)
			local post = makePart({
				Name = name,
				Size = Vector3.new(0.32, 5.2, 0.32),
				Position = pos + Vector3.new(0, 2.7, 0),
				Color = Color3.fromRGB(45, 48, 58),
				Material = Enum.Material.Metal,
				CanCollide = false,
				Parent = district,
			})
			addChochin(name .. "_Lamp", post.Position + Vector3.new(0, 2.5, 0), color or Color3.fromRGB(255, 200, 120))
		end

		local function addVending(name, pos, faceDir)
			faceDir = faceDir or Vector3.new(0, 0, 1)
			local right = Vector3.new(-faceDir.Z, 0, faceDir.X)
			local body = makePart({
				Name = name,
				Size = Vector3.new(2.0, 4.0, 1.5),
				Position = pos + Vector3.new(0, 2.1, 0),
				Color = Color3.fromRGB(220, 45, 75),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_Glass",
				Size = Vector3.new(1.55, 2.3, 0.1),
				Position = pos + faceDir * 0.78 + Vector3.new(0, 2.4, 0),
				Color = Color3.fromRGB(160, 220, 255),
				Material = Enum.Material.Glass,
				Transparency = 0.3,
				CanCollide = false,
				Parent = district,
			})
			local strip = makePart({
				Name = name .. "_Strip",
				Size = Vector3.new(1.85, 0.22, 0.12),
				Position = pos + faceDir * 0.78 + Vector3.new(0, 3.85, 0),
				Color = Color3.fromRGB(80, 255, 200),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = district,
			})
			addPointLight(strip, strip.Color, 0.3, 6)
			-- drink cans silhouette
			for i = -1, 1 do
				makePart({
					Name = name .. "_Can",
					Size = Vector3.new(0.28, 0.45, 0.28),
					Position = pos + faceDir * 0.55 + right * (i * 0.45) + Vector3.new(0, 2.1, 0),
					Color = if i == 0 then Color3.fromRGB(255, 200, 60) else Color3.fromRGB(80, 180, 255),
					Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
					Parent = district,
				})
			end
			return body
		end

		local function addBench(name, pos, yawDeg)
			local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(yawDeg or 0), 0)
			makePart({
				Name = name .. "_Seat",
				Size = Vector3.new(4.2, 0.35, 1.2),
				CFrame = cf * CFrame.new(0, 1.0, 0),
				Color = Color3.fromRGB(120, 80, 50),
				Material = Enum.Material.Wood,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_Back",
				Size = Vector3.new(4.2, 1.4, 0.25),
				CFrame = cf * CFrame.new(0, 1.7, -0.5),
				Color = Color3.fromRGB(100, 70, 45),
				Material = Enum.Material.Wood,
				CanCollide = false,
				Parent = district,
			})
		end

		local function addBannerPole(name, pos, text, color)
			local pole = makePart({
				Name = name,
				Size = Vector3.new(0.28, 6.5, 0.28),
				Position = pos + Vector3.new(0, 3.3, 0),
				Color = Color3.fromRGB(50, 52, 62),
				Material = Enum.Material.Metal,
				CanCollide = false,
				Parent = district,
			})
			local cloth = makePart({
				Name = name .. "_Flag",
				Size = Vector3.new(0.12, 3.2, 1.6),
				Position = pole.Position + Vector3.new(0.9, 0.6, 0),
				Color = color,
				Material = Enum.Material.Fabric,
				CanCollide = false,
				Parent = district,
			})
			neonBillboard(cloth, text, Color3.fromRGB(255, 255, 255), 0.2)
		end

		local function addAnimeCar(name, pos, yawDeg, bodyColor)
			local yaw = math.rad(yawDeg or 0)
			local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
			local body = makePart({
				Name = name .. "_Body",
				Size = Vector3.new(4.4, 1.35, 8.2),
				CFrame = cf * CFrame.new(0, 1.55, 0),
				Color = bodyColor,
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = district,
			})
			makePart({
				Name = name .. "_Cabin",
				Size = Vector3.new(4.0, 1.1, 4.2),
				CFrame = cf * CFrame.new(0, 2.55, -0.4),
				Color = bodyColor:Lerp(Color3.fromRGB(40, 40, 50), 0.25),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = district,
			})
			makePart({
				Name = name .. "_Window",
				Size = Vector3.new(3.6, 0.85, 3.4),
				CFrame = cf * CFrame.new(0, 2.65, -0.35),
				Color = Color3.fromRGB(140, 200, 240),
				Material = Enum.Material.Glass,
				Transparency = 0.4,
				CanCollide = false,
				Parent = district,
			})
			for _, wheelXZ in ipairs({
				Vector3.new(-1.7, 0.55, 2.6),
				Vector3.new(1.7, 0.55, 2.6),
				Vector3.new(-1.7, 0.55, -2.6),
				Vector3.new(1.7, 0.55, -2.6),
			}) do
				local w = makePart({
					Name = name .. "_Wheel",
					Size = Vector3.new(0.7, 1.1, 1.1),
					CFrame = cf * CFrame.new(wheelXZ),
					Color = Color3.fromRGB(25, 25, 30),
					Material = Enum.Material.Rubber,
					CanCollide = false,
					Parent = district,
				})
				w.Shape = Enum.PartType.Cylinder
			end
			return body
		end

		--[[
			Townhouse v6: along sea road; E-open doors; window openings (glass see-through from inside).
			faceDir = inward from front door toward back. Door faces -faceDir.
		]]
		local function addTownHouse(opts)
			local TweenService = game:GetService("TweenService")
			local name = opts.Name
			local pos = opts.Position
			local faceDir = opts.FaceDir.Unit
			local right = Vector3.new(-faceDir.Z, 0, faceDir.X)
			local w = opts.W or 26
			local h = opts.H or 24
			local d = opts.D or 28
			local wallColor = opts.WallColor or Color3.fromRGB(245, 232, 220)
			local accent = opts.Accent or Color3.fromRGB(140, 90, 70)
			local roofColor = opts.RoofColor or Color3.fromRGB(90, 70, 65)
			local signText = opts.SignText or "HOME"
			local theme = opts.Theme or "home"
			local doorClearH = opts.DoorH or 8
			local doorW = math.clamp(w * 0.2, 5.5, 7.0)
			local wallT = 0.7
			local front = pos - faceDir * (d * 0.5)
			local back = pos + faceDir * (d * 0.5)
			local floorY = 1.0
			local midY = h * 0.48 + 0.7
			local winT = 0.28

			-- Right-handed wall CFrames only (left-handed fromMatrix breaks client replication → Look becomes -Z)
			local function wallAt(center, outward, alongHint)
				local vZ = -outward.Unit -- LookVector = outward
				local vX = Vector3.yAxis:Cross(vZ)
				if vX.Magnitude < 1e-4 then
					vX = (alongHint or right).Unit
				else
					vX = vX.Unit
				end
				-- keep alongHint sign when possible
				if alongHint and vX:Dot(alongHint) < 0 then
					vX = -vX
				end
				local vY = vZ:Cross(vX).Unit
				if vY.Y < 0 then
					vX = -vX
					vY = -vY
				end
				return CFrame.fromMatrix(center, vX, vY, vZ)
			end
			local function boxAt(p)
				-- depth=faceDir as local X, thickness along right; outward for sides handled by callers via wallAt
				return wallAt(p, right, faceDir) -- default: faces +right (used for floor/generic)
			end
			local function frontAt(p)
				-- facade faces outward = -faceDir (toward street/door)
				return wallAt(p, -faceDir, right)
			end

			local function addGlass(nm, size, cf)
				-- inset to interior (+local Z) so glass != coplanar frames
				local g = makePart({
					Name = nm,
					Size = size,
					CFrame = cf * CFrame.new(0, 0, 0.18),
					Color = Color3.fromRGB(185, 215, 235),
					Material = Enum.Material.Glass,
					Transparency = winT,
					Reflectance = 0.06,
					CanCollide = false,
					Parent = district,
				})
				g.CastShadow = false
				return g
			end
			local function addWinBorder(nm, cf, winW, winH)
				-- frame inside opening, offset outward — never coplanar with glass
				local fw = 0.22
				local z = 0.16
				local col = Color3.fromRGB(70, 55, 45)
				local function strip(suffix, size, off)
					local p = makePart({
						Name = nm .. suffix,
						Size = size,
						CFrame = cf * CFrame.new(off.X, off.Y, -0.22),
						Color = col,
						Material = Enum.Material.SmoothPlastic,
						CanCollide = false,
						Parent = district,
					})
					p.CastShadow = false
				end
				strip("_FrameT", Vector3.new(winW - 0.05, fw, z), Vector3.new(0, winH * 0.5 - fw * 0.5, 0))
				strip("_FrameB", Vector3.new(winW - 0.05, fw, z), Vector3.new(0, -winH * 0.5 + fw * 0.5, 0))
				strip("_FrameL", Vector3.new(fw, winH - fw * 2, z), Vector3.new(-winW * 0.5 + fw * 0.5, 0, 0))
				strip("_FrameR", Vector3.new(fw, winH - fw * 2, z), Vector3.new(winW * 0.5 - fw * 0.5, 0, 0))
			end

			makePart({
				Name = name .. "_Found",
				Size = Vector3.new(d + 1.0, 0.8, w + 1.0),
				CFrame = boxAt(pos + Vector3.new(0, 0.4, 0)),
				Color = Color3.fromRGB(120, 115, 110),
				Material = Enum.Material.Concrete,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_Floor",
				Size = Vector3.new(d - 0.4, 0.35, w - 0.4),
				CFrame = boxAt(pos + Vector3.new(0, floorY, 0)),
				Color = Color3.fromRGB(190, 160, 125),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = true,
				Parent = district,
			})

			for i = 1, 3 do
				makePart({
					Name = name .. "_Step" .. i,
					Size = Vector3.new(1.2, 0.3, doorW + 0.8),
					CFrame = boxAt(front - faceDir * (0.6 + (i - 1) * 1.0) + Vector3.new(0, 0.2 + (i - 1) * 0.3, 0)),
					Color = Color3.fromRGB(145, 140, 135),
					Material = Enum.Material.Concrete,
					CanCollide = true,
					Parent = district,
				})
			end

						-- ===== Wall box: Front ∥ Back (frontAt), Sides ⊥ (boxAt) =====
			local wallY = h * 0.5 + 0.7
			local frontPlane = front + faceDir * (wallT * 0.5)
			local backPlane = back - faceDir * (wallT * 0.5)

			local function brick(nm, size, cf)
				return makePart({
					Name = nm,
					Size = size,
					CFrame = cf,
					Color = wallColor,
					Material = Enum.Material.SmoothPlastic,
					CanCollide = true,
					Parent = district,
				})
			end

			-- SIDE walls with real window openings (glass see-through from inside)
			for _, side in ipairs({ -1, 1 }) do
				local sidePos = pos + right * (side * (w * 0.5 - wallT * 0.5))
				local sideName = side < 0 and "_SolidLeft" or "_SolidRight"
				local outward = right * side
				local winW, winH = 3.0, 3.2
				local y1, y2 = h * 0.28 + 0.7, h * 0.68 + 0.7
				local gap = winW + 0.4
				local sideDepth = d
				local bandA = (sideDepth - gap) * 0.5
				-- front / back solid bands full height
				brick(name .. sideName, Vector3.new(bandA, h, wallT),
					wallAt(sidePos + faceDir * (-sideDepth * 0.5 + bandA * 0.5) + Vector3.new(0, wallY, 0), outward, faceDir))
				brick(name .. sideName, Vector3.new(bandA, h, wallT),
					wallAt(sidePos + faceDir * (sideDepth * 0.5 - bandA * 0.5) + Vector3.new(0, wallY, 0), outward, faceDir))
				-- window column: sill / mid / head + glass holes
				local col = 0 -- center of side along depth slightly forward
				local botH = math.max(y1 - winH * 0.5 - 0.7, 1.0)
				brick(name .. sideName, Vector3.new(gap, botH, wallT),
					wallAt(sidePos + faceDir * col + Vector3.new(0, 0.7 + botH * 0.5, 0), outward, faceDir))
				local midBot, midTop = y1 + winH * 0.5, y2 - winH * 0.5
				local midH = math.max(midTop - midBot, 0.9)
				brick(name .. sideName, Vector3.new(gap, midH, wallT),
					wallAt(sidePos + faceDir * col + Vector3.new(0, midBot + midH * 0.5, 0), outward, faceDir))
				local topH = math.max((0.7 + h) - (y2 + winH * 0.5), 1.0)
				brick(name .. sideName, Vector3.new(gap, topH, wallT),
					wallAt(sidePos + faceDir * col + Vector3.new(0, y2 + winH * 0.5 + topH * 0.5, 0), outward, faceDir))
				for _, y in ipairs({ y1, y2 }) do
					local wcf = wallAt(sidePos + faceDir * col + Vector3.new(0, y, 0), outward, faceDir)
					addGlass(name .. "_SideWin", Vector3.new(winW - 0.2, winH - 0.2, 0.12), wcf)
					addWinBorder(name .. "_SideWin", wcf, winW, winH)
				end
			end

			-- BACK wall
			brick(name .. "_Back", Vector3.new(w, h, wallT), wallAt(backPlane + Vector3.new(0, wallY, 0), faceDir, right))

			-- FRONT wall with door + window openings
			local panelW = (w - doorW) * 0.5
			for _, side in ipairs({ -1, 1 }) do
				local panelCenter = frontPlane + right * (side * (doorW * 0.5 + panelW * 0.5))
				local winW = math.max(panelW - 1.6, 2.2)
				local winH1, winH2 = 3.2, 2.8
				local y1, y2 = h * 0.28 + 0.7, h * 0.68 + 0.7
				local edge = math.max((panelW - winW) * 0.5, 0.5)

				brick(name .. "_Front", Vector3.new(edge, h, wallT),
					frontAt(panelCenter + right * (side * (panelW * 0.5 - edge * 0.5)) + Vector3.new(0, wallY, 0)))
				brick(name .. "_Front", Vector3.new(edge, h, wallT),
					frontAt(panelCenter - right * (side * (panelW * 0.5 - edge * 0.5)) + Vector3.new(0, wallY, 0)))

				local botH = math.max(y1 - winH1 * 0.5 - 0.7, 1.0)
				brick(name .. "_Front", Vector3.new(winW, botH, wallT),
					frontAt(panelCenter + Vector3.new(0, 0.7 + botH * 0.5, 0)))
				local midBot, midTop = y1 + winH1 * 0.5, y2 - winH2 * 0.5
				local midH = math.max(midTop - midBot, 0.9)
				brick(name .. "_Front", Vector3.new(winW, midH, wallT),
					frontAt(panelCenter + Vector3.new(0, midBot + midH * 0.5, 0)))
				local topH = math.max((0.7 + h) - (y2 + winH2 * 0.5), 1.0)
				brick(name .. "_Front", Vector3.new(winW, topH, wallT),
					frontAt(panelCenter + Vector3.new(0, y2 + winH2 * 0.5 + topH * 0.5, 0)))

				local wcf1 = frontAt(panelCenter + Vector3.new(0, y1, 0))
				local wcf2 = frontAt(panelCenter + Vector3.new(0, y2, 0))
				addGlass(name .. "_Window", Vector3.new(winW - 0.2, winH1 - 0.2, 0.12), wcf1)
				addGlass(name .. "_Window", Vector3.new(winW - 0.2, winH2 - 0.2, 0.12), wcf2)
				addWinBorder(name .. "_Window", wcf1, winW, winH1)
				addWinBorder(name .. "_Window", wcf2, winW, winH2)
			end
			local lintelH = math.max(h - doorClearH, 3.0)
			brick(
				name .. "_Lintel",
				Vector3.new(doorW, lintelH, wallT),
				frontAt(frontPlane + Vector3.new(0, doorClearH + lintelH * 0.5 + 0.7, 0))
			)
			-- Door jambs as exterior trim (leaf fills full opening)
			local jamb = 0.28
			makePart({
				Name = name .. "_DoorJambL",
				Size = Vector3.new(jamb, doorClearH, 0.22),
				CFrame = frontAt(frontPlane - right * (doorW * 0.5) + Vector3.new(0, doorClearH * 0.5 + 0.7, 0)) * CFrame.new(0, 0, -0.2),
				Color = Color3.fromRGB(55, 45, 40),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = district,
			})
			makePart({
				Name = name .. "_DoorJambR",
				Size = Vector3.new(jamb, doorClearH, 0.22),
				CFrame = frontAt(frontPlane + right * (doorW * 0.5) + Vector3.new(0, doorClearH * 0.5 + 0.7, 0)) * CFrame.new(0, 0, -0.2),
				Color = Color3.fromRGB(55, 45, 40),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = district,
			})

-- Hinged door — open/close with E
			local doorHeight = doorClearH - 0.12
			local doorLeafW = doorW - 0.1
			local hingePos = front - faceDir * 0.22 - right * (doorLeafW * 0.5) + Vector3.new(0, doorHeight * 0.5 + 0.7, 0)
			local hingeCF = wallAt(hingePos, -faceDir, right)
			-- local Right may be -world right after upright wallAt; offset along doorway (+right)
			local xSign = (hingeCF.RightVector:Dot(right) >= 0) and 1 or -1
			local closedCF = hingeCF * CFrame.new(xSign * doorLeafW * 0.5, 0, 0)
			local openCF = hingeCF * CFrame.Angles(0, math.rad(-95 * xSign), 0) * CFrame.new(xSign * doorLeafW * 0.5, 0, 0)
			local door = makePart({
				Name = name .. "_Door",
				Size = Vector3.new(doorLeafW, doorHeight, 0.16),
				CFrame = closedCF,
				Color = accent:Lerp(Color3.fromRGB(70, 45, 35), 0.35),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_Knob",
				Size = Vector3.new(0.22, 0.22, 0.22),
				CFrame = closedCF * CFrame.new(xSign * doorLeafW * 0.35, 0, -0.2),
				Color = Color3.fromRGB(220, 190, 90),
				Material = Enum.Material.Metal,
				CanCollide = false,
				Parent = door,
			})
			local sensor = makePart({
				Name = name .. "_DoorSensor",
				Size = Vector3.new(doorW + 1.5, doorClearH, 3.2),
				CFrame = frontAt(front - faceDir * 0.2 + Vector3.new(0, doorClearH * 0.5 + 0.7, 0)),
				Transparency = 1,
				CanCollide = false,
				CanQuery = true,
				Parent = district,
			})
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = name .. "_DoorPrompt"
			prompt.ObjectText = signText
			prompt.ActionText = "Открыть дверь"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Style = Enum.ProximityPromptStyle.Default
			prompt.Parent = sensor
			local doorOpen, doorBusy = false, false
			local doorTween = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local function setDoor(open)
				if doorBusy or open == doorOpen then return end
				doorBusy = true
				doorOpen = open
				TweenService:Create(door, doorTween, { CFrame = open and openCF or closedCF }):Play()
				door.CanCollide = not open
				prompt.ActionText = open and "Закрыть дверь" or "Открыть дверь"
				task.delay(0.45, function() doorBusy = false end)
				if open then
					task.delay(8, function()
						if doorOpen then setDoor(false) end
					end)
				end
			end
			prompt.Triggered:Connect(function() setDoor(not doorOpen) end)

			-- 2F floor + stairs
			local shaftAcross = 4.4
			local shaftAlong = d * 0.48
			local shaftCenter = pos - right * (w * 0.5 - shaftAcross * 0.5 - 1.2) - faceDir * (d * 0.08)
			makePart({
				Name = name .. "_MidFloorBack",
				Size = Vector3.new(d * 0.42, 0.32, w - 0.6),
				CFrame = boxAt(pos + faceDir * (d * 0.24) + Vector3.new(0, midY, 0)),
				Color = Color3.fromRGB(175, 150, 120),
				Material = Enum.Material.WoodPlanks,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_MidFloorFront",
				Size = Vector3.new(d * 0.5, 0.32, w - shaftAcross - 1.6),
				CFrame = boxAt(pos - faceDir * (d * 0.1) + right * ((shaftAcross + 1.0) * 0.35) + Vector3.new(0, midY, 0)),
				Color = Color3.fromRGB(175, 150, 120),
				Material = Enum.Material.WoodPlanks,
				CanCollide = true,
				Parent = district,
			})
			local stepN = 14
			local rise = midY - floorY
			local stepRise = rise / stepN
			local stepRun = (shaftAlong - 1.2) / stepN
			local stairBase = shaftCenter - faceDir * (shaftAlong * 0.45)
			for i = 1, stepN do
				makePart({
					Name = name .. "_Stair" .. i,
					Size = Vector3.new(stepRun * 0.95, math.max(stepRise, 0.22), shaftAcross - 0.5),
					CFrame = boxAt(stairBase + faceDir * ((i - 0.5) * stepRun) + Vector3.new(0, floorY + (i - 0.5) * stepRise, 0)),
					Color = Color3.fromRGB(155, 125, 95),
					Material = Enum.Material.Wood,
					CanCollide = true,
					Parent = district,
				})
			end
			makePart({
				Name = name .. "_StairRail",
				Size = Vector3.new(shaftAlong * 0.9, 0.2, 0.2),
				CFrame = boxAt(shaftCenter + right * (shaftAcross * 0.42) + Vector3.new(0, floorY + rise * 0.55 + 1.4, 0))
					* CFrame.Angles(0, 0, -math.atan2(rise, shaftAlong * 0.85)),
				Color = Color3.fromRGB(90, 70, 55),
				Material = Enum.Material.Wood,
				CanCollide = false,
				Parent = district,
			})

			makePart({
				Name = name .. "_Ceiling",
				Size = Vector3.new(d - 0.3, 0.4, w - 0.3),
				CFrame = boxAt(pos + Vector3.new(0, h + 0.5, 0)),
				Color = Color3.fromRGB(235, 228, 215),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = true,
				Parent = district,
			})

			local roofH = 4.5
			local tilt = math.rad(30)
			-- Pitched roof: ridge along `right`, slopes toward ±faceDir (right-handed wallAt)
			for _, side in ipairs({ -1, 1 }) do
				local outward = (Vector3.yAxis * math.cos(tilt) + faceDir * side * math.sin(tilt)).Unit
				local center = pos + faceDir * (side * (d * 0.24)) + Vector3.new(0, h + 2.6, 0)
				makePart({
					Name = name .. "_Roof",
					Size = Vector3.new(w + 2.6, d * 0.56, 0.5),
					CFrame = wallAt(center, outward, right),
					Color = roofColor,
					Material = Enum.Material.Slate,
					CanCollide = false,
					Parent = district,
				})
			end
			makePart({
				Name = name .. "_Ridge",
				Size = Vector3.new(w + 2.8, 0.45, 0.45),
				CFrame = wallAt(pos + Vector3.new(0, h + roofH + 0.35, 0), Vector3.yAxis, right),
				Color = roofColor:Lerp(Color3.fromRGB(40, 35, 35), 0.35),
				Material = Enum.Material.Metal,
				CanCollide = false,
				Parent = district,
			})

			makePart({
				Name = name .. "_Chimney",
				Size = Vector3.new(2.2, 5.0, 2.2),
				CFrame = boxAt(pos + faceDir * (d * 0.22) + right * (w * 0.28) + Vector3.new(0, h + 3.8, 0)),
				Color = Color3.fromRGB(130, 90, 80),
				Material = Enum.Material.Brick,
				CanCollide = false,
				Parent = district,
			})

			makePart({
				Name = name .. "_PorchRoof",
				Size = Vector3.new(doorW + 1.8, 0.28, 2.4),
				CFrame = frontAt(front - faceDir * 1.15 + Vector3.new(0, doorClearH + 1.1, 0)),
				Color = roofColor,
				Material = Enum.Material.Wood,
				CanCollide = false,
				Parent = district,
			})
			for _, side in ipairs({ -1, 1 }) do
				makePart({
					Name = name .. "_PorchPost",
					Size = Vector3.new(0.4, doorClearH - 0.2, 0.4),
					CFrame = boxAt(front - faceDir * 1.9 + right * (side * (doorW * 0.42)) + Vector3.new(0, (doorClearH - 0.2) * 0.5 + 0.7, 0)),
					Color = Color3.fromRGB(85, 65, 50),
					Material = Enum.Material.Wood,
					CanCollide = true,
					Parent = district,
				})
			end

			local plate = makePart({
				Name = name .. "_Plate",
				Size = Vector3.new(math.min(w * 0.4, 10), 1.2, 0.2),
				CFrame = frontAt(front - faceDir * 0.4 + Vector3.new(0, doorClearH + 1.8, 0)),
				Color = Color3.fromRGB(35, 38, 50),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = district,
			})
			surfaceGuiLabel(plate, signText, accent, Enum.NormalId.Front)

			local lamp = makePart({
				Name = name .. "_Lamp",
				Size = Vector3.new(1.0, 0.4, 1.0),
				CFrame = boxAt(pos + Vector3.new(0, h * 0.85 + 0.7, 0)),
				Color = Color3.fromRGB(255, 230, 180),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = district,
			})
			addPointLight(lamp, Color3.fromRGB(255, 220, 170), 0.8, 28)
			local lamp2 = makePart({
				Name = name .. "_Lamp2",
				Size = Vector3.new(0.8, 0.35, 0.8),
				CFrame = boxAt(pos + faceDir * (d * 0.15) + Vector3.new(0, midY + 3.5, 0)),
				Color = Color3.fromRGB(255, 235, 200),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = district,
			})
			addPointLight(lamp2, Color3.fromRGB(255, 230, 190), 0.55, 18)

			makePart({
				Name = name .. "_Table",
				Size = Vector3.new(2.4, 0.4, 5.0),
				CFrame = boxAt(pos + faceDir * (d * 0.02) + right * (w * 0.12) + Vector3.new(0, 2.0, 0)),
				Color = Color3.fromRGB(120, 85, 55),
				Material = Enum.Material.Wood,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_Sofa",
				Size = Vector3.new(2.4, 1.5, 6.5),
				CFrame = boxAt(pos + faceDir * (d * 0.28) + right * (w * 0.12) + Vector3.new(0, 1.7, 0)),
				Color = accent:Lerp(Color3.fromRGB(80, 80, 100), 0.35),
				Material = Enum.Material.Fabric,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_Bed",
				Size = Vector3.new(4.5, 1.0, 6.5),
				CFrame = boxAt(pos + faceDir * (d * 0.22) + right * (w * 0.15) + Vector3.new(0, midY + 0.7, 0)),
				Color = Color3.fromRGB(230, 220, 240),
				Material = Enum.Material.Fabric,
				CanCollide = true,
				Parent = district,
			})
			if theme == "ramen" then
				makePart({
					Name = name .. "_Kitchen",
					Size = Vector3.new(2.0, 2.6, w * 0.32),
					CFrame = boxAt(pos + right * (w * 0.28) + faceDir * (d * 0.12) + Vector3.new(0, 2.2, 0)),
					Color = Color3.fromRGB(230, 230, 235),
					Material = Enum.Material.SmoothPlastic,
					CanCollide = true,
					Parent = district,
				})
			elseif theme == "figures" then
				for i = -1, 1 do
					makePart({
						Name = name .. "_Shelf",
						Size = Vector3.new(0.6, 4.0, 1.6),
						CFrame = boxAt(pos + faceDir * (d * 0.28) + right * (w * 0.2 + i * 2.4) + Vector3.new(0, 3.0, 0)),
						Color = Color3.fromRGB(70, 60, 90),
						Material = Enum.Material.Wood,
						CanCollide = true,
						Parent = district,
					})
				end
			elseif theme == "konbini" then
				for i = -1, 1 do
					makePart({
						Name = name .. "_Fridge",
						Size = Vector3.new(1.2, 4.0, 1.8),
						CFrame = boxAt(pos + faceDir * (d * 0.22) + right * (w * 0.18 + i * 2.6) + Vector3.new(0, 2.9, 0)),
						Color = Color3.fromRGB(245, 248, 255),
						Material = Enum.Material.Metal,
						CanCollide = true,
						Parent = district,
					})
				end
			end

			makePart({
				Name = name .. "_Mat",
				Size = Vector3.new(1.4, 0.08, doorW * 0.9),
				CFrame = boxAt(front - faceDir * 0.6 + Vector3.new(0, 0.82, 0)),
				Color = accent:Lerp(Color3.fromRGB(40, 40, 50), 0.4),
				Material = Enum.Material.Fabric,
				CanCollide = false,
				Parent = district,
			})
			return true
		end

		-- Garage: 2 solid walls + 2 glass walls (each glass wall has sliding doors)
		local function addSlidingGlassWall(parent, opts)
			local TweenService = game:GetService("TweenService")
			local name = opts.Name
			local center = opts.Center
			local along = opts.Along.Unit
			local outward = opts.Outward.Unit
			local wallW = opts.WallW
			local wallH = opts.WallH
			local wallT = opts.WallT or 0.35
			local doorW = opts.DoorW or math.min(10, wallW * 0.55)
			local slide = opts.Slide or (doorW * 0.48)
			local glassColor = Color3.fromRGB(170, 220, 245)
			local frameColor = Color3.fromRGB(45, 50, 62)

			local wallCF = CFrame.fromMatrix(center, along, Vector3.yAxis, -outward)
			local panelW = math.max(1.2, (wallW - doorW) * 0.5)
			local leafH = wallH - 1.6
			local leafY = leafH * 0.5 + 0.1

			-- fixed glass side panels
			for _, side in ipairs({ -1, 1 }) do
				makePart({
					Name = name .. "_Glass" .. (side < 0 and "L" or "R"),
					Size = Vector3.new(panelW, wallH, wallT),
					CFrame = wallCF * CFrame.new(side * (doorW * 0.5 + panelW * 0.5), wallH * 0.5, 0),
					Color = glassColor,
					Material = Enum.Material.Glass,
					Transparency = 0.55,
					Reflectance = 0.35,
					CanCollide = true,
					Parent = parent,
				})
			end
			-- metal header over door
			makePart({
				Name = name .. "_Header",
				Size = Vector3.new(doorW + 0.4, 1.4, wallT + 0.1),
				CFrame = wallCF * CFrame.new(0, wallH - 0.7, 0),
				Color = frameColor,
				Material = Enum.Material.Metal,
				CanCollide = true,
				Parent = parent,
			})

			local entrance = Instance.new("Model")
			entrance.Name = name .. "_Door"
			entrance.Parent = parent

			local leftClosed = wallCF * CFrame.new(-doorW * 0.25, leafY, 0)
			local rightClosed = wallCF * CFrame.new(doorW * 0.25, leafY, 0)
			local leftOpen = wallCF * CFrame.new(-doorW * 0.25 - slide, leafY, 0)
			local rightOpen = wallCF * CFrame.new(doorW * 0.25 + slide, leafY, 0)

			local leftDoor = makePart({
				Name = name .. "_LeafL",
				Size = Vector3.new(doorW * 0.5 - 0.12, leafH, wallT * 0.9),
				CFrame = leftClosed,
				Color = glassColor,
				Material = Enum.Material.Glass,
				Transparency = 0.45,
				Reflectance = 0.4,
				CanCollide = true,
				Parent = entrance,
			})
			local rightDoor = makePart({
				Name = name .. "_LeafR",
				Size = Vector3.new(doorW * 0.5 - 0.12, leafH, wallT * 0.9),
				CFrame = rightClosed,
				Color = glassColor,
				Material = Enum.Material.Glass,
				Transparency = 0.45,
				Reflectance = 0.4,
				CanCollide = true,
				Parent = entrance,
			})
			-- thin metal stile in middle when closed
			makePart({
				Name = name .. "_Stile",
				Size = Vector3.new(0.18, leafH * 0.95, wallT * 1.05),
				CFrame = wallCF * CFrame.new(0, leafY, 0),
				Color = frameColor,
				Material = Enum.Material.Metal,
				CanCollide = false,
				Parent = entrance,
			})

			local sensor = makePart({
				Name = name .. "_Sensor",
				Size = Vector3.new(doorW, leafH, 2.4),
				CFrame = wallCF * CFrame.new(0, leafY, -0.2),
				Transparency = 1,
				CanCollide = false,
				CanQuery = true,
				CanTouch = false,
				Parent = entrance,
			})
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = name .. "_Prompt"
			prompt.ObjectText = opts.ObjectText or "Гараж"
			prompt.ActionText = "Открыть дверь"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.MaxActivationDistance = 16
			prompt.RequiresLineOfSight = false
			prompt.Style = Enum.ProximityPromptStyle.Default
			prompt.Parent = sensor
			local click = Instance.new("ClickDetector")
			click.Name = name .. "_Click"
			click.MaxActivationDistance = 24
			click.Parent = sensor

			local isOpen, busy, autoCloseToken = false, false, 0
			local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local function setOpen(open)
				if busy or open == isOpen then return end
				busy = true
				isOpen = open
				leftDoor.CanCollide = not open
				rightDoor.CanCollide = not open
				TweenService:Create(leftDoor, tweenInfo, { CFrame = open and leftOpen or leftClosed }):Play()
				TweenService:Create(rightDoor, tweenInfo, { CFrame = open and rightOpen or rightClosed }):Play()
				prompt.ActionText = open and "Закрыть дверь" or "Открыть дверь"
				task.delay(0.5, function() busy = false end)
				if open then
					autoCloseToken += 1
					local token = autoCloseToken
					task.delay(5, function()
						if token == autoCloseToken and isOpen then setOpen(false) end
					end)
				end
			end
			local function toggle() setOpen(not isOpen) end
			prompt.Triggered:Connect(toggle)
			click.MouseClick:Connect(toggle)
			return entrance
		end

		local function addPlayerGarage(opts)
			local name = opts.Name or "PlayerGarage"
			local pos = opts.Position
			local faceDir = opts.FaceDir.Unit -- toward plaza / open approach
			local right = Vector3.new(-faceDir.Z, 0, faceDir.X)
			local w = opts.W or 30
			local h = opts.H or 16
			local d = opts.D or 24
			local wallT = 0.6
			local front = pos - faceDir * (d * 0.5)
			local back = pos + faceDir * (d * 0.5)

			-- clear old garage pieces
			for _, ch in ipairs(district:GetChildren()) do
				if string.sub(ch.Name, 1, #name) == name then
					ch:Destroy()
				end
			end

			-- Oriented box: local X = depth (faceDir), local Z = width (right)
			local boxAt = function(p)
				return CFrame.fromMatrix(p, faceDir, Vector3.yAxis, right)
			end

			makePart({
				Name = name .. "_Floor",
				Size = Vector3.new(d, 0.4, w),
				CFrame = boxAt(pos + Vector3.new(0, 0.2, 0)),
				Color = Color3.fromRGB(55, 58, 68),
				Material = Enum.Material.Asphalt,
				CanCollide = true,
				Parent = district,
			})
			makePart({
				Name = name .. "_Apron",
				Size = Vector3.new(6, 0.2, w + 4),
				CFrame = boxAt(front - faceDir * 3.5 + Vector3.new(0, 0.1, 0)),
				Color = Color3.fromRGB(70, 72, 82),
				Material = Enum.Material.Asphalt,
				CanCollide = false,
				Parent = district,
			})

			-- SOLID sides: left + right — перпендикулярны стеклу (толщина вдоль right, длина вдоль faceDir)
			local glassT = 0.35
			for _, side in ipairs({ -1, 1 }) do
				local sideCenter = pos + right * (side * (w * 0.5 - wallT * 0.5)) + Vector3.new(0, h * 0.5, 0)
				makePart({
					Name = name .. (side < 0 and "_SolidLeft" or "_SolidRight"),
					Size = Vector3.new(d, h, wallT),
					CFrame = boxAt(sideCenter),
					Color = Color3.fromRGB(105, 110, 125),
					Material = Enum.Material.Concrete,
					CanCollide = true,
					Parent = district,
				})
			end

			-- GLASS + sliding doors: front (plaza) + back — замыкают коробку
			addSlidingGlassWall(district, {
				Name = name .. "_Front",
				Center = front + faceDir * (glassT * 0.5),
				Along = right,
				Outward = -faceDir,
				WallW = w - wallT * 2,
				WallH = h,
				WallT = glassT,
				DoorW = math.min(14, (w - wallT * 2) * 0.62),
				ObjectText = "Гараж · въезд",
			})
			addSlidingGlassWall(district, {
				Name = name .. "_Back",
				Center = back - faceDir * (glassT * 0.5),
				Along = -right,
				Outward = faceDir,
				WallW = w - wallT * 2,
				WallH = h,
				WallT = glassT,
				DoorW = math.min(12, (w - wallT * 2) * 0.55),
				ObjectText = "Гараж · задний вход",
			})

			makePart({
				Name = name .. "_Roof",
				Size = Vector3.new(d + 1.2, 0.5, w + 1.2),
				CFrame = boxAt(pos + Vector3.new(0, h + 0.1, 0)),
				Color = Color3.fromRGB(50, 55, 70),
				Material = Enum.Material.Metal,
				CanCollide = true,
				Parent = district,
			})
			local sign = makePart({
				Name = name .. "_Sign",
				Size = Vector3.new(12, 2.0, 0.3),
				Position = front - faceDir * 0.5 + Vector3.new(0, h - 0.4, 0),
				Color = Color3.fromRGB(255, 200, 60),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = district,
			})
			surfaceGuiLabel(sign, "ГАРАЖ", Color3.fromRGB(30, 30, 40), Enum.NormalId.Front)
			addPointLight(sign, Color3.fromRGB(255, 200, 80), 0.5, 20)

			local bayCount = 4
			for i = 1, bayCount do
				local t = (i - 0.5) / bayCount - 0.5
				local bayPos = pos + right * (t * (w - 6))
				makePart({
					Name = name .. "_BayLine",
					Size = Vector3.new(d * 0.7, 0.08, 0.15),
					CFrame = boxAt(bayPos + Vector3.new(0, 0.42, 0)),
					Color = Color3.fromRGB(240, 240, 250),
					Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
					Parent = district,
				})
				local yaw = if math.abs(faceDir.X) > 0.5 then 90 else 0
				local colors = {
					Color3.fromRGB(255, 120, 170),
					Color3.fromRGB(90, 200, 255),
					Color3.fromRGB(160, 100, 255),
					Color3.fromRGB(255, 180, 80),
				}
				addAnimeCar(name .. "_Car" .. i, bayPos + faceDir * 1.5, yaw + (i % 2) * 180, colors[i])
			end
			for i = -1, 1 do
				local fl = makePart({
					Name = name .. "_Light",
					Size = Vector3.new(3.5, 0.2, 0.6),
					Position = pos + right * (i * 7) + Vector3.new(0, h - 1.2, 0),
					Color = Color3.fromRGB(255, 245, 220),
					Material = Enum.Material.Neon,
					CanCollide = false,
					Parent = district,
				})
				addPointLight(fl, Color3.fromRGB(255, 245, 220), 0.6, 22)
			end
		end

		-- ========== South Plaza + Player Garage ==========
		do
			local plazaZ = center.Z - half - 12
			makePart({
				Name = "SouthPlazaPad",
				Size = Vector3.new(52, 0.2, 22),
				Position = Vector3.new(center.X, 0.1, plazaZ),
				Color = Color3.fromRGB(68, 70, 82),
				Material = Enum.Material.Asphalt,
				CanCollide = false,
				Parent = district,
			})
			makePart({
				Name = "SouthSidewalkL",
				Size = Vector3.new(10, 0.22, 20),
				Position = Vector3.new(center.X - 18, 0.11, plazaZ),
				Color = Color3.fromRGB(170, 172, 185),
				Material = Enum.Material.Concrete,
				CanCollide = false,
				Parent = district,
			})
			makePart({
				Name = "SouthSidewalkR",
				Size = Vector3.new(10, 0.22, 20),
				Position = Vector3.new(center.X + 18, 0.11, plazaZ),
				Color = Color3.fromRGB(170, 172, 185),
				Material = Enum.Material.Concrete,
				CanCollide = false,
				Parent = district,
			})
			-- Big garage west of plaza (clear of Spawn -25,-45 / Mika -12,-38); open bay toward plaza
			addPlayerGarage({
				Name = "PlayerGarage",
				Position = Vector3.new(center.X - 98, 0, plazaZ),
				FaceDir = Vector3.new(1, 0, 0),
				W = 30,
				H = 16,
				D = 24,
			})
			for i, ox in ipairs({ -22, -16, 16, 22 }) do
				addLanternPole("PlazaLantern" .. i, Vector3.new(center.X + ox, 0, plazaZ + 8), Color3.fromRGB(255, 180, 220))
			end
			addBench("PlazaBenchL", Vector3.new(center.X - 16, 0, plazaZ + 7), 0)
			addBench("PlazaBenchR", Vector3.new(center.X + 16, 0, plazaZ + 7), 0)
			addBannerPole("PlazaBannerCatch", Vector3.new(center.X - 14, 0, plazaZ + 9), "CATCH", Color3.fromRGB(255, 120, 180))
			addBannerPole("PlazaBannerBattle", Vector3.new(center.X + 14, 0, plazaZ + 9), "BATTLE", Color3.fromRGB(100, 180, 255))
			addStandee(district, Vector3.new(center.X + 8, 3.2, center.Z - half - 2.5))
		end

		-- ========== Side Alleys (path clear; props on OUTER wall) ==========
		do
			local alleyX = half + 10
			for side, sx in ipairs({ -1, 1 }) do
				local pathX = center.X + sx * alleyX
				local outerX = pathX + sx * 5.5 -- buildings/props outside the walk lane
				makePart({
					Name = "AlleyPath" .. side,
					Size = Vector3.new(6, 0.15, 42),
					Position = Vector3.new(pathX, 0.075, center.Z),
					Color = Color3.fromRGB(52, 55, 66),
					Material = Enum.Material.Asphalt,
					CanCollide = false,
					Parent = district,
				})
				-- Outer building wall strip (reads as alley wall, not blocking path)
				makePart({
					Name = "AlleyWall" .. side,
					Size = Vector3.new(1.2, 10, 36),
					Position = Vector3.new(outerX + sx * 2, 5.5, center.Z),
					Color = Color3.fromRGB(55, 58, 75),
					Material = Enum.Material.Brick,
					CanCollide = true,
					Parent = district,
				})
				addVending("Vending" .. side .. "A", Vector3.new(outerX, 0, center.Z - 10), Vector3.new(-sx, 0, 0))
				addVending("Vending" .. side .. "B", Vector3.new(outerX, 0, center.Z + 8), Vector3.new(-sx, 0, 0))
				addVerticalKanban(
					"AlleyKanban" .. side,
					Vector3.new(outerX, 0, center.Z),
					Vector3.new(-sx, 0, 0),
					if side == 1 then "同人" else "フィギュア",
					if side == 1 then Color3.fromRGB(255, 140, 80) else Color3.fromRGB(180, 120, 255),
					10
				)
				makePart({
					Name = "AlleyBin" .. side,
					Size = Vector3.new(1.3, 1.7, 1.3),
					Position = Vector3.new(outerX, 1.85, center.Z + 16),
					Color = Color3.fromRGB(55, 150, 85),
					Material = Enum.Material.Metal,
					CanCollide = true,
					Parent = district,
				})
				addPoster(district, Vector3.new(outerX - sx * 0.8, 4.5, center.Z - 4), Color3.fromRGB(255, 100 + side * 40, 160))
				addPoster(district, Vector3.new(outerX - sx * 0.8, 4.5, center.Z + 4), Color3.fromRGB(100, 180, 255))
				addLanternPole("AlleyLantern" .. side, Vector3.new(pathX - sx * 1.5, 0, center.Z - 18), Color3.fromRGB(255, 210, 140))
				addChochin("AlleyChochin" .. side, Vector3.new(outerX - sx * 1.2, 6.5, center.Z + 2), Color3.fromRGB(255, 70, 90))
			end
		end

		-- ========== North street: townhouses OFF walk corridor ==========
		-- Narrow center path; houses on lots with doors facing the street.
		do
			local streetZ = center.Z + half + 14
			makePart({
				Name = "NorthStreetPad",
				Size = Vector3.new(12, 0.2, 70),
				Position = Vector3.new(center.X, 0.1, streetZ + 22),
				Color = Color3.fromRGB(62, 65, 78),
				Material = Enum.Material.Asphalt,
				CanCollide = false,
				Parent = district,
			})
			makePart({
				Name = "NorthSidewalk",
				Size = Vector3.new(8, 0.22, 70),
				Position = Vector3.new(center.X, 0.11, streetZ + 22),
				Color = Color3.fromRGB(175, 178, 190),
				Material = Enum.Material.Concrete,
				CanCollide = false,
				Parent = district,
			})
			local gate = makePart({
				Name = "AkihabaraDistrictSign",
				Size = Vector3.new(16, 2.4, 0.4),
				Position = Vector3.new(center.X, 7.2, center.Z + half + 5),
				Color = Color3.fromRGB(25, 28, 40),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = district,
			})
			local gateLed = makePart({
				Name = "AkihabaraDistrictSign_Glow",
				Size = Vector3.new(15, 1.9, 0.15),
				Position = gate.Position + Vector3.new(0, 0, -0.25),
				Color = Color3.fromRGB(255, 90, 200),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = district,
			})
			surfaceGuiLabel(gateLed, "Район Акихабара", Color3.fromRGB(20, 15, 30), Enum.NormalId.Front)
			addPointLight(gateLed, Color3.fromRGB(255, 90, 200), 0.6, 18)

			-- Houses moved to Transition path toward sea (see below)
			addVending("NorthVendingL", Vector3.new(center.X - 10, 0, streetZ - 2), Vector3.new(0, 0, -1))
			addVending("NorthVendingR", Vector3.new(center.X + 10, 0, streetZ - 2), Vector3.new(0, 0, -1))
			for i, ox in ipairs({ -8, 8 }) do
				addLanternPole("NorthLantern" .. i, Vector3.new(center.X + ox, 0, streetZ - 4), Color3.fromRGB(255, 170, 220))
			end
			addBannerPole("NorthBannerEvolve", Vector3.new(center.X - 6, 0, streetZ + 32), "EVOLVE", Color3.fromRGB(180, 120, 255))
			addBannerPole("NorthBannerCollect", Vector3.new(center.X + 6, 0, streetZ + 32), "COLLECT", Color3.fromRGB(255, 200, 90))
			addBench("NorthBench", Vector3.new(center.X, 0, streetZ + 10), 0)
		end

		-- ========== Interior density (extra manga shelves) ==========
		do
			for i, ox in ipairs({ -10, -6, 6, 10 }) do
				makePart({
					Name = "MangaShelfExtra" .. i,
					Size = Vector3.new(3.2, 4.0, 0.8),
					Position = center + Vector3.new(ox, 3.2, 16),
					Color = Color3.fromRGB(110, 70, 45),
					Material = Enum.Material.Wood,
					CanCollide = true,
					Parent = district,
				})
				makePart({
					Name = "MangaShelfBooks" .. i,
					Size = Vector3.new(2.9, 3.2, 0.35),
					Position = center + Vector3.new(ox, 3.2, 16.4),
					Color = Color3.fromRGB(255, 140, 180),
					Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
					Parent = district,
				})
			end
			addLEDDisplay(district, center + Vector3.new(0, 6.5, 14), "GACHA\nOPEN")
		end

		-- ========== Houses along Transition road toward sea ==========
		do
			local pathFolder = workspace:FindFirstChild("CoastalShowcase")
				and workspace.CoastalShowcase:FindFirstChild("Transition")
				and workspace.CoastalShowcase.Transition:FindFirstChild("Path")

			local function placeByPath(spec)
				local D = spec.D or 28
				local pp = pathFolder and pathFolder:FindFirstChild("Path_" .. tostring(spec.PathIdx))
				local pos, faceDir
				if pp then
					local sideDir = pp.CFrame.RightVector.Unit * (if spec.Side < 0 then 1 else -1)
					local setback = pp.Size.X * 0.5 + D * 0.5 + 12
					pos = Vector3.new(pp.Position.X, 0, pp.Position.Z) + sideDir * setback
					faceDir = sideDir -- into house; door faces road
				else
					pos = spec.FallbackPos
					faceDir = spec.FallbackFace
				end
				addTownHouse({
					Name = spec.Name,
					Position = pos,
					FaceDir = faceDir,
					W = 26,
					H = 24,
					D = D,
					DoorH = 8,
					WallColor = spec.WallColor,
					Accent = spec.Accent,
					RoofColor = spec.RoofColor,
					SignText = spec.SignText,
					Theme = spec.Theme,
				})
			end

			placeByPath({
				Name = "HouseRamen", PathIdx = 5, Side = -1,
				FallbackPos = Vector3.new(-30, 0, -140), FallbackFace = Vector3.new(-1, 0, 0),
				WallColor = Color3.fromRGB(255, 235, 220), Accent = Color3.fromRGB(220, 80, 70),
				RoofColor = Color3.fromRGB(90, 55, 55), SignText = "ДОМ · RAMEN", Theme = "ramen",
			})
			placeByPath({
				Name = "HouseKonbini", PathIdx = 5, Side = 1,
				FallbackPos = Vector3.new(40, 0, -140), FallbackFace = Vector3.new(1, 0, 0),
				WallColor = Color3.fromRGB(220, 245, 255), Accent = Color3.fromRGB(50, 160, 220),
				RoofColor = Color3.fromRGB(45, 70, 95), SignText = "ДОМ · KONBINI", Theme = "konbini",
			})
			placeByPath({
				Name = "HouseFigures", PathIdx = 12, Side = -1,
				FallbackPos = Vector3.new(-20, 0, -270), FallbackFace = Vector3.new(-1, 0, 0),
				WallColor = Color3.fromRGB(235, 225, 255), Accent = Color3.fromRGB(150, 90, 220),
				RoofColor = Color3.fromRGB(55, 50, 90), SignText = "ДОМ · FIGURES", Theme = "figures",
			})
			placeByPath({
				Name = "HouseCafe", PathIdx = 12, Side = 1,
				FallbackPos = Vector3.new(55, 0, -270), FallbackFace = Vector3.new(1, 0, 0),
				WallColor = Color3.fromRGB(255, 245, 230), Accent = Color3.fromRGB(255, 140, 90),
				RoofColor = Color3.fromRGB(100, 70, 50), SignText = "ДОМ · CAFE", Theme = "home",
			})
			placeByPath({
				Name = "ApproachArcade", PathIdx = 18, Side = -1,
				FallbackPos = Vector3.new(-25, 0, -380), FallbackFace = Vector3.new(-1, 0, 0),
				WallColor = Color3.fromRGB(55, 60, 85), Accent = Color3.fromRGB(70, 220, 180),
				RoofColor = Color3.fromRGB(35, 45, 60), SignText = "ДОМ · ARCADE", Theme = "home",
			})
			placeByPath({
				Name = "ApproachIdol", PathIdx = 18, Side = 1,
				FallbackPos = Vector3.new(50, 0, -380), FallbackFace = Vector3.new(1, 0, 0),
				WallColor = Color3.fromRGB(255, 225, 240), Accent = Color3.fromRGB(255, 110, 190),
				RoofColor = Color3.fromRGB(90, 50, 80), SignText = "ДОМ · IDOL", Theme = "home",
			})
			placeByPath({
				Name = "ApproachGacha", PathIdx = 24, Side = -1,
				FallbackPos = Vector3.new(-35, 0, -485), FallbackFace = Vector3.new(-1, 0, 0),
				WallColor = Color3.fromRGB(255, 248, 220), Accent = Color3.fromRGB(255, 180, 70),
				RoofColor = Color3.fromRGB(100, 80, 40), SignText = "ДОМ · GACHA", Theme = "home",
			})

			-- Remove Transition/coast palms that poke through house footprints
			local function clearPalmsNearHouses()
				local coast = workspace:FindFirstChild("CoastalShowcase")
				if not coast then
					return
				end
				local floors = {}
				for _, ch in ipairs(district:GetChildren()) do
					if ch:IsA("BasePart") and string.sub(ch.Name, -6) == "_Floor" then
						floors[#floors + 1] = ch
					end
				end
				local function tooClose(pos)
					for _, fl in ipairs(floors) do
						local dx = math.abs(pos.X - fl.Position.X)
						local dz = math.abs(pos.Z - fl.Position.Z)
						if dx <= fl.Size.X * 0.5 + 10 and dz <= fl.Size.Z * 0.5 + 10 then
							return true
						end
					end
					return false
				end
				local folders = {}
				if coast:FindFirstChild("Palms") then
					folders[#folders + 1] = coast.Palms
				end
				local tr = coast:FindFirstChild("Transition")
				if tr and tr:FindFirstChild("Palms") then
					folders[#folders + 1] = tr.Palms
				end
				for _, folder in ipairs(folders) do
					for _, p in ipairs(folder:GetChildren()) do
						local pivot
						if p:IsA("Model") then
							pivot = p:GetPivot().Position
						elseif p:IsA("BasePart") then
							pivot = p.Position
						end
						if pivot and tooClose(pivot) then
							p:Destroy()
						end
					end
				end
			end
			clearPalmsNearHouses()

			local combat = ZoneConfig.Zones.Combat
			local cc = combat.Center
			for i = 1, 4 do
				local t = (i - 1) / 3
				local x = -25 + (cc.X + 20 - (-25)) * t
				local z = 70 + (cc.Z - 20 - 70) * t
				addBannerPole("ApproachBanner" .. i, Vector3.new(x - 6, 0, z), if i % 2 == 0 then "SPIRIT" else "OTAKU", Color3.fromRGB(255, 100 + i * 30, 180))
				addLanternPole("ApproachLantern" .. i, Vector3.new(x + 6, 0, z - 2), Color3.fromRGB(255, 210, 150))
			end
		end
	end

	return build
end

