-- flyhack.lua — Fly Hack / Havada Asılı Kalma (yerçekimsiz uçuş)
--
-- Mantık: gerçek bir zıplama fiziği yer çekimi yüzünden ~1 sn içinde tepe
-- noktasına ulaşıp düşmeye başlar (dikey hız negatife döner). Paraşüt,
-- araç, merdiven, yüzme dışında hiçbir meşru durumda bir oyuncu HAVADA
-- (yerden yüksekte) 2+ saniye boyunca kesintisiz "düşmüyor" (dikey hız
-- sürekli ≥ -1.0) olamaz. Bu, superjump'tan farklı bir imza: superjump ANLIK
-- aşırı yükseklik/hız verir, flyhack ise SÜRDÜRÜLEBİLİR yerçekimsiz uçuştur.

local ticks = 0

CreateThread(function()
  while true do
    Wait(200)
    if Aeigs.rule('anti_superjump', true) and Aeigs.active() then
      local S = Aeigs.S
      local vz = (S.vel and S.vel.z) or 0.0
      local airborne = S.ped and S.height and S.height > 1.5
      local legit = not S.ped or S.inVeh or S.parachute > 0
        or (S.ped and IsPedInParachuteFreeFall(S.ped))
        or S.climbing or S.swimming or S.dead or S.ragdoll or S.attached
        or S.frozen or (S.ped and IsPedDoingBeastJump(S.ped))

      -- "Düşmüyor" = dikey hız yerçekimine rağmen sürekli ~0 veya pozitif.
      if S.ped and airborne and not legit and vz > -1.0 then
        ticks = ticks + 1
      else
        ticks = 0
      end

      -- 200ms × 12 ≈ 2.4 sn kesintisiz yerçekimsiz uçuş = fiziksel olarak imkânsız.
      if ticks >= 12 then
        ticks = 0
        Aeigs.report('FLYHACK', 'CRITICAL', { vz = math.floor(vz * 100) / 100 })
      end
    else
      ticks = 0
    end
  end
end)
