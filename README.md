# Teensy 4.1 NuttX build

Reprodukálható projektcsomag a Teensy 4.1-en futó NuttX rendszerhez. Nem
másolja be az Apache NuttX teljes forrásfáját: rögzíti az upstream revíziókat,
a helyi javításokat, a board konfigurációt, a Gopher klienst és a build/feltöltés
menetét. A build másik Linux gépen, a műhely és a Teensy mellett futó Diga nélkül
is előkészíthető; tényleges RF/HW próba természetesen Teensy 4.1-et igényel.

## Tartalom és hardver

- Teensy 4.1 (i.MX RT1062), NuttX `netnsh-4.1` konfiguráció.
- USB CDC soros NSH, DHCP-s Ethernet és Telnet NSH.
- Beépített microSD csatolása `/mnt` alá FAT fájlrendszerként.
- SPI3 felderítése és `/dev/spi3` eszköz regisztrálása.
- A Teensy Loader HalfKay módba léptetése USB CDC 134 baud kéréssel.
- Opcionális `/mnt/autorun.nsh`: a board bring-up előbb felcsatolja az SD-t,
  majd az NSH indulásakor a firmware kiadja a `source /mnt/autorun.nsh`
  parancsot. Az NSH saját szkriptfuttatója dolgozza fel; hiányzó fájlnál az
  NSH `source` hibát ad.
- Az NSH szkriptfuttató minden sor után ütemezési lehetőséget ad a háttérben
  indított programoknak. A Telnet daemon autorunból indításakor utána `sleep 1`
  is szerepeljen, hogy elindulhasson, mielőtt a szkript továbblép.
- Az i.MX RT USDHC meghajtó rövid, nem cache-vonalra igazított olvasásait a
  belső, igazított DMA-pufferen keresztül kezeli. Ez szükséges az NSH
  bájtonként olvasó szkriptbemenetéhez is.
- A Telnet driver nyers terminálmódban elfogadja a `SUPPRESS-GO-AHEAD`
  egyeztetést, így a Gopher menü billentyűi Enter nélkül működnek.
- Külön repóban lévő interaktív Gopher kliens: `teensy-nuttx-gopher`.

A megosztott autorun fájl tartalmát ez a projekt nem tartalmazza. A hálózati
konzol jelenleg hitelesítés nélküli: csak megbízható, tűzfallal védett helyi
hálózaton használd, internetre ne tedd ki.

## Rögzített forrásverziók

| Forrás | Rev. |
|---|---|
| Apache NuttX (`apache/nuttx`) | `8caba095575dfa0c47fd6ca4b974dd5e69798535` |
| Apache NuttX Apps (`apache/nuttx-apps`) | `0c56297b043157fccee9a56b2af06aa4c49d1ed0` |
| Gopher kliens (kísérleti NAWS nézet) | `erixabo/teensy-nuttx-gopher`, `b24577a3d8c08f99e37d0fbab854a2f12c0f754a` |

A NuttX módosításait a `patches/nuttx-local.patch`, az Apps módosításait a
`patches/apps-local.patch` tartalmazza. A Teensy board `defconfig` a `config/`
könyvtárban van. Ezeket a foltokat csak a fenti alapverziókra alkalmazd.

## Kísérleti Gopher-kijelzőméret

Ez az ág kipróbálja a Telnet NAWS ablakméret-egyeztetést és a Gopher kliens
automatikus, illetve kézzel választható tördelését. A `config/defconfig`
bekapcsolja a `CONFIG_TELNET_SUPPORT_NAWS` opciót. Az automatikus méret a
Telnet-kliens által közölt oszlop- és sorszámot veszi át; soros konzolon vagy
hiányzó méretadatnál 80×24 az alapérték. A Gopher kliens `v` menüjében
80×24, 100×30 és 120×40 nézet választható. Ezek csak a kliens elrendezését
állítják, nem tudják átméretezni a távoli terminálablakot.

Kísérleti build: ezen az ágon a NAWS és a méretválasztó együtt fordul le.
2026-10-29-én a Gopher képernyőkimenetének pufferelésével együtt sikeresen
lefordult: 233 152 bájt flash és 118 160 bájt SRAM (512 KiB-ból). A firmware
felkerült a Teensy 4.1-re. Hideg indulás után az autorun lefutott, a
`/mnt/test` tartalma `rendben` lett, a `telnetd` folyamat elindult, és a Telnet
23-as porton kapcsolódni lehetett. A Gopher főmenü megjelent; a nyíllal léptetés
csak a régi és az új sort rajzolta újra, az Enteres lapnyitás is működött.

## Teljes build előkészítése

Linuxon szükséges a Git, GNU Make, Python 3, CMake, `kconfig-frontends`/NuttX
konfigurációs segédeszközök és ARM GNU toolchain. A korábbi helyi build a
PlatformIO által biztosított `arm-none-eabi` toolchainnel készült.

```sh
./scripts/bootstrap-build.sh "$HOME/teensy4-nuttx-build"
```

A szkript tiszta célkönyvtárba klónozza a rögzített Apache forrásokat, alkalmazza
a foltokat, bemásolja a külön Gopher klienst, beállítja a boardot, majd lefordítja
a firmware-t. A Gopher kliens nyilvános Git repóból klónozható; a szkript
rögzített commitot használ.

Kézi build meglévő checkoutokból:

```sh
cd nuttx
./tools/configure.sh teensy-4.x:netnsh-4.1
make -j"$(nproc)"
```

Az elkészült Intel HEX fájl `nuttx.hex`. A szükséges külső NuttX eszközöket és
toolchaint a build hoston kell telepíteni; itt nincs becsomagolva a fordító.

## Feltöltés

Teensy 4.1 USB-n csatlakoztatva, a CDC HalfKay hookot már tartalmazó firmware
futásakor:

```sh
./scripts/flash-teensy41.sh /út/a/nuttx.hex
```

`TEENSY_PORT` és `TEENSY_LOADER` környezeti változóval a soros eszköz és a
`teensy_loader_cli` útvonala felülírható. Az első sikertelen loader után egy
alkalommal újrapróbálkozik. Hook nélküli első firmware-hez a Program gomb kell.

## Ellenőrzés

2026-10-29-én a módosított build sikeresen elkészült és felkerült. A bootpróbán
a Telnet automatikusan elindult, a Gopher menü, a kétsoros kijelölésfrissítés
és a lapnyitás működött. A hardverpróba Teensy 4.1 nélkül nem ismételhető.

## Licenc

Az upstream NuttX és Apps forrása Apache-2.0 licencű. A repóban tárolt diffek az
upstream fákhoz készültek; a Gopher kliens külön repóban van. A fordító és a
feltöltő külön telepítendő, saját licencük szerint.
