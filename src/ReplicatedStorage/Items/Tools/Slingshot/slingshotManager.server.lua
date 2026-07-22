--//Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--//Tool Stuff
local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local startPart = handle:WaitForChild("startPart")

--//Remotes
local shootEvent = tool:WaitForChild("shootEvent")

--//Sounds
local ShootSound = handle:WaitForChild("ShootSound")
local HitSound = handle:WaitForChild("HitSound")

--//Config
local damage = 5

local projectileSize = 0.4
local projectileSpeed = 80         -- ajuste para controlar a velocidade inicial (studs/s)
local projectileLifetime = 4        -- segundos até destruir
local physDensity = 1
local physFriction = 1.5            -- fricção alta para evitar deslize longo no chão
local physElasticity = 0.02
local setNetworkOwnerToPlayer = true

local velocityLossOnImpact = 0.15   -- multiplica velocidade por isso ao colidir (perde 85%)
local downwardImpulseOnImpact = -8  -- força vertical aplicada ao colidir para "desprender" do objeto

local function createProjectile(startPos, hitPos, shooterPlayer)
	local projectile = Instance.new("Part")
	projectile.Size = Vector3.new(projectileSize, projectileSize, projectileSize)
	projectile.Shape = Enum.PartType.Ball
	projectile.Color = Color3.fromRGB(44, 44, 44)
	projectile.Material = Enum.Material.Rock
	projectile.CanCollide = true
	projectile.Anchored = false
	projectile.Massless = false
	projectile.Position = startPos
	projectile.CastShadow = false
	projectile.Parent = workspace

	-- propriedades físicas (fricção maior para reduzir deslize)
	projectile.CustomPhysicalProperties = PhysicalProperties.new(
		physDensity,
		physFriction,
		physElasticity,
		100, -- frictionWeight
		1  -- elasticityWeight
	)

	-- direção simples (sem arco)
	local dir = (hitPos - startPos)
	if dir.Magnitude == 0 then
		dir = Vector3.new(0, 0, 1) -- fallback
	end
	local direction = dir.Unit

	-- velocidade inicial (aplicada apenas no lançamento)
	local initialVelocity = direction * projectileSpeed

	-- melhora simulação para o jogador que atirou (opcional)
	if setNetworkOwnerToPlayer and typeof(shooterPlayer) == "Instance" and shooterPlayer:IsA("Player") then
		pcall(function() projectile:SetNetworkOwner(shooterPlayer) end)
	end

	-- aplica o impulso inicial (apenas aqui)
	projectile.AssemblyLinearVelocity = initialVelocity

	local touchedConn
	local destroyed = false
	local impacted = false

	-- remover a velocidade de rotação total
	local function stopSpinning()
		if not destroyed and projectile and projectile.Parent then
			--projectile.AssemblyLinearVelocity = Vector3.zero
			projectile.AssemblyAngularVelocity = Vector3.zero
		end
	end
	stopSpinning()

	local function cleanUp()
		if destroyed then return end
		destroyed = true
		if touchedConn then
			touchedConn:Disconnect()
			touchedConn = nil
		end
		if projectile and projectile.Parent then
			projectile:Destroy()
		end
	end

	touchedConn = projectile.Touched:Connect(function(hit)
		if not hit or not hit.Parent then return end

		-- ignora o próprio atirador e o tool
		if shooterPlayer and hit:IsDescendantOf(shooterPlayer.Character) then return end
		if hit:IsDescendantOf(tool) then return end

		-- evita processar múltiplos toques: apenas o primeiro válido
		if impacted then return end
		impacted = true

		-- dano se humanoid
		local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
		if humanoid and not Players:GetPlayerFromCharacter(hit.Parent) then
			humanoid:TakeDamage(damage)
			if HitSound then
				local s = HitSound:Clone()
				s.Parent = hit
				s:Play()
				task.delay(2, function() pcall(function() s:Destroy() end) end)
			end
		end

		-- reduz fortemente a velocidade ao colidir para evitar deslize longo
		if projectile and projectile.Parent then
			local cv = projectile.AssemblyLinearVelocity
			-- zera componente horizontal consideravelmente e deixa um pequeno impulso para baixo
			local newVel = Vector3.new(cv.X * velocityLossOnImpact, math.min(cv.Y * velocityLossOnImpact, -1) + downwardImpulseOnImpact, cv.Z * velocityLossOnImpact)
			projectile.AssemblyLinearVelocity = newVel

			-- aumenta fricção para garantir que não deslize muito
			pcall(function()
				projectile.CustomPhysicalProperties = PhysicalProperties.new(
					physDensity,
					5,    -- fricção bem alta após impacto
					physElasticity,
					1,
					1
				)
			end)
		end
		-- cleanup após um pequeno delay para o projétil "cair"
		task.delay(1.2, cleanUp)
	end)

	-- autodestruição se não colidir
	task.delay(projectileLifetime, function()
		if destroyed then return end
		-- faz ele parar de voar e cair antes de destruir
		if projectile and projectile.Parent then
			projectile.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
		end
		task.delay(1, cleanUp)
	end)

	return projectile
end

-- conexão do evento
shootEvent.OnServerEvent:Connect(function(player, hitPosition)
	if not player.Character then return end
	local startPos = startPart.Position

	if ShootSound then
		-- tocar no servidor; se preferir, toque no cliente
		ShootSound:Play()
	end

	createProjectile(startPos, hitPosition, player)
end)
