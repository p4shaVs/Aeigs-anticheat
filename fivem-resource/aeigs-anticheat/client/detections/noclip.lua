-- noclip.lua — NoClip (GÜVENİLİR, false'suz — eskiden çalışan mantık)
-- Sinyal: çarpışma KAPALI + hareket + araçta değil + düşmüyor/ragdoll değil.
-- ~2 sn (4 örnek) kesintisiz sürerse ban. NoClip (havada dahil) çarpışmayı
-- kapatır → yakalanır. Gerçek düşüş/normal oyun ASLA çarpışmayı kapatmaz → false yok.
CreateThread(function()
  local ticks = 0
  while true do
    Wait(500)
    if Aeigs.rule('anti_noclip', true) and Aeigs.active() and not Aeigs.tpGrace() then
      local S = Aeigs.S
      local vz = (S.vel and S.vel.z) or 0.0
      local dropping = S.falling or vz < -2.0
      if S.ped and S.collisionOff and S.speed > 1.5
        and not S.inVeh and not S.dead and not S.ragdoll
        and not S.climbing and not S.jumping and not S.swimming
        and S.parachute <= 0 and not IsPedInParachuteFreeFall(S.ped)
        and not dropping and not S.frozen then
        ticks = ticks + 1
        if ticks >= 4 then
          ticks = 0
          Aeigs.report('NOCLIP', 'CRITICAL', { source = 'collision' })
        end
      else
        ticks = 0
      end
    else
      ticks = 0
    end
  end
end)
