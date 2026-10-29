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
- Opcionális `/mnt/autorun.nsh`: ha olvasható, induláskor végrehajtja; ha
  hiányzik vagy nem olvasható, a firmware elindítja a Telnet NSH-t.
- Külön repóban lévő interaktív Gopher kliens: `teensy-nuttx-gopher`.

A megosztott autorun fájl tartalmát ez a projekt nem tartalmazza. A hálózati
konzol jelenleg hitelesítés nélküli: csak megbízható, tűzfallal védett helyi
hálózaton használd, internetre ne tedd ki.

## Rögzített forrásverziók

| Forrás | Rev. |
|---|---|
| Apache NuttX (`apache/nuttx`) | `8caba095575dfa0c47fd6ca4b974dd5e69798535` |
| Apache NuttX Apps (`apache/nuttx-apps`) | `0c56297b043157fccee9a56b2af06aa4c49d1ed0` |
| Gopher kliens | `erixabo/teensy-nuttx-gopher`, `6f8a6fab9ba6363d80b7f6669c7ae548e928fc99` |

A NuttX módosításait a `patches/nuttx-local.patch`, az Apps módosításait a
`patches/apps-local.patch` tartalmazza. A Teensy board `defconfig` a `config/`
könyvtárban van. Ezeket a foltokat csak a fenti alapverziókra alkalmazd.

## Teljes build előkészítése

Linuxon szükséges a Git, GNU Make, Python 3, CMake, `kconfig-frontends`/NuttX
konfigurációs segédeszközök és ARM GNU toolchain. A korábbi helyi build a
PlatformIO által biztosított `arm-none-eabi` toolchainnel készült.

```sh
./scripts/bootstrap-build.sh "$HOME/teensy4-nuttx-build"
```

A szkript tiszta célkönyvtárba klónozza a rögzített Apache forrásokat, alkalmazza
a foltokat, bemásolja a külön Gopher klienst, beállítja a boardot, majd lefordítja
a firmware-t. A saját GitHub-fiók jogosultsága szükséges a privát Gopher repó
klónozásához.

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

2026-10-29-én a `bootstrap-build.sh` egy tiszta, sekély checkoutból sikeresen
összeállította a teljes firmware-t. A NuttX méretjelentése 231 640 bájt flash
(1984 KiB-ból) és 97 680 bájt SRAM (512 KiB-ból) volt. A HEX-et Teensy 4.1-re
feltöltöttük, majd soros és Telnet NSH-n ellenőriztük. A Gopher
kliens menüjét, szöveges lapját, lapozását, UTF-8 ékezeteit és kilépés utáni
NSH/Telnet elérhetőségét is a célhardveren próbáltuk. Ez a hardverpróba nem
ismételhető Teensy nélkül.

## Licenc

Az upstream NuttX és Apps forrása Apache-2.0 licencű. A repóban tárolt diffek az
upstream fákhoz készültek; a Gopher kliens külön repóban van. A fordító és a
feltöltő külön telepítendő, saját licencük szerint.
