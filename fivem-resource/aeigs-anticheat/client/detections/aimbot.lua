-- aimbot.lua — Aimbot (ani "snap" + kilit tespiti)
-- Aimbot, düşman FOV'a girince kamerayı ANINDA hedefin kafasına çevirir (snap) ve
-- kilitlenir. İnsan bir karede 35°+ dönüp tam kafaya oturamaz. Ateş anında bu
-- snap + düşman oyuncuya kilit birden fazla kez olursa aimbot kabul edilir.
local snapStrike = Aeigs.strike(3, 8000)

CreateThread(function()
  local lastH, lastP, lastT
  while true do
    local S = Aeigs.S
    if Aeigs.rule('anti_aimbot', true) and not Aeigs.spawnGuard()
      and S.ped and IsPlayerFreeAiming(S.id) then
      local rot = GetGameplayCamRot(2)
      local now = GetGameTimer()
      if lastT and (now - lastT) > 0 and (now - lastT) < 60 then
        local dh = math.abs(((rot.z - lastH + 180.0) % 360.0) - 180.0)
        local dp = math.abs(rot.x - lastP)
        if (dh + dp) > 35.0 and IsPedShooting(S.ped) then
          local aiming, ent = GetEntityPlayerIsFreeAimingAt(S.id)
          if aiming and ent and ent ~= 0 and IsEntityAPed(ent) and IsPedAPlayer(ent) then
            if snapStrike:hit() then
              Aeigs.report('AIMBOT', 'CRITICAL', { snap = math.floor(dh + dp) })
            end
          end
        end
      end
      lastH, lastP, lastT = rot.z, rot.x, now
      Wait(0)     -- nişan alırken kare-kare (sadece bu durumda)
    else
      lastT = nil
      Wait(300)
    end
  end
end)
