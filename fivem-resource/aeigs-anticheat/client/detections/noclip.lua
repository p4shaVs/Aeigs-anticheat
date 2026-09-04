-- noclip.lua — NoClip tespiti (havada noclip DAHİL, gerçek düşüş false vermez)
-- Sinyaller (2 strike / 8 sn → ban):
--  1) Çarpışma kapalı + kontrollü hareket (klasik noclip)
--  2) Havada KONTROLLÜ süzülme: yüksekte + yatay hareket + dikey hız ~0
--     (yerçekimi düşüşü değil → gerçek düşüş vz<0 olduğundan MUAF)
--  3) Zemin-içi hareket: gerçek yükseklik ile hesaplanan yükseklik uyuşmuyor

local strike = Aeigs.strike(2, 8000)

CreateThread(function()
  while true do
    Wait(400)
    if Aeigs.rule('anti_noclip', true) and not Aeigs.spawnGuard() and not Aeigs.tpGrace() then
      local S = Aeigs.S
      if S.ped and not S.inVeh and not S.dead and not S.ragdoll
        and not S.climbing and not S.jumping and not S.swimming
        and S.parachute <= 0 and not IsPedInParachuteFreeFall(S.ped) then

        local vz = (S.vel and S.vel.z) or 0.0
        local gravityFall = S.falling or vz < -2.0          -- gerçek düşüş → MUAF
        local horiz = math.sqrt((S.vel.x or 0)^2 + (S.vel.y or 0)^2)
        local hit = false

        -- 1) Çarpışma kapalı + hareket
        if S.collisionOff and S.speed > 1.5 and not gravityFall then hit = true end

        -- 2) Havada kontrollü süzülme (yerçekimi yok)
        if not gravityFall and S.height > 3.0 and horiz > 2.0 and math.abs(vz) < 1.5
          and not S.frozen then hit = true end

        -- 3) Zemin-içi / yükseklik uyuşmazlığı (yerde değilken)
        if not gravityFall and not S.frozen and S.speed > 1.5 then
          local ok, gz = GetGroundZFor_3dCoord(S.coords.x, S.coords.y, S.coords.z, false)
          if ok then
            local calc = S.coords.z - gz
            if math.abs(S.height - calc) > 2.5 and S.height < 1.0 then hit = true end
          end
        end

        if hit and strike:hit() then
          Aeigs.report('NOCLIP', 'CRITICAL', { h = math.floor(S.height) })
        end
      end
    end
  end
end)
