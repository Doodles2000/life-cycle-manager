(c) 2018-2022 HomeAccessoryKid

### Instructions for end users:
TBD

### Instructions if you're creating from scratch, including own private key and signatures:
- Foreword: creating this section as learning
- Pre-requisites:
- ESP-OPEN-RTOS framework
- ECC_SIGNER tool by ravensystems
- life-cycle-manager cloned locally
#
- Create keys (basically a copy paste of 'How to make a new signing key pair' section) and prepare certs files
```
mkdir /tmp/ecdsa
cd    /tmp/ecdsa
openssl ecparam -genkey -name secp384r1 -out secp384r1prv.pem
openssl ec -in secp384r1prv.pem -outform DER -out secp384r1prv.der
openssl ec -in secp384r1prv.pem -outform DER -out secp384r1pub.der -pubout
cat    secp384r1prv.pem
xxd -p secp384r1pub.der
```
- Capture the private key .pem and public key .der in a secret place.  Destroy .pem and .der from /tmp
- Note: secp384r1pub.der will be referred to as public*key* for the remainder of these instructions
#
- Use the finder to duplicate the content from the previous versions folder => call it versions1
- Remove all the duplicates that will not change from the previous versions folder like blank.bin ...
- Copy in public*key*
- Create/update the file versions1/latest-pre-release without new-line and setup 2.2.5 version folder
```
cd [life-cycle-manager]/versions1
cp [secret place]/public*key* .
mkdir 2.2.5x
echo -n 2.2.5 > 2.2.5x/latest-pre-release
```
- Create certs.hex, with new keys
```
xxd -i certs.sector > certs.hex
```
- Open certs.hex and replace the first 10 rows with the public key xxd output, then make the new certs.sector.
```
vi certs.hex; xxd -p -r certs.hex > certs.sector
cp certs.sector 2.2.5x/
```
- Note: yet to be determined why, the new certs.sector file ends up being 4099 bytes instead of 4096
- Two bytes (0xed, 0xce) added to beginning of file and one (0xed) to the end.
- Temporary work around - remove the additional bytes with a binary/hex editor

- Create certs.h in life-cycle-manager directory
- Edit to not contain the trailing 0xff entries. 
- Change last line of file to match length (unsigned int certs_sector_len = 2825;) at time of writing.
```
cp certs.hex ../certs.h; cd ..; vi certs.h
```
- (note for self: an alternate way to build certs.sector is to join the three certs into a single file: public*key* + DigiCertGlobalRootCA.pem + DigiCertHighAssuranceEVRootCA.pem)

# 
- Building binaries
- Set local.mk to the ota-main program
```
make -j6 rebuild OTAVERSION=2.2.5
mv firmware/otamain.bin versions1/2.2.5x
```
- Set local.mk back to ota-boot program
```
make -j6 rebuild OTAVERSION=2.2.5
mv firmware/otaboot.bin versions1/2.2.5x
make -j6 rebuild OTAVERSION=2.2.5 OTABETA=1
cp firmware/otaboot.bin versions1/2.2.5x/otabootbeta.bin
```
- Remove the older version files
- Update Changelog
#
- Sign the binaries using ecc_signer
- Note: ecc_signer take three parameters; [file to be signed] [private key.der] [public key.der], generates the hashes, which need to be glued together to create the signature.
- certs.sector
```
cd versions1/2.2.5x
cp ../certs.sector .
[path to ecc_signer]/ecc_signer certs.sector [secret place]/secp384r1prv.der [secret place]/secp384r1pub.der
mv hash certs.sector.sig
printf "%08x" `cat certs.sector | wc -c`| xxd -r -p >>certs.sector.sig
cat sign >>certs.sector.sig
rm sign
```
-otabootbeta.bin
```
[path to ecc_signer]/ecc_signer otabootbeta.bin [secret place]/secp384r1prv.der [secret place]/secp384r1pub.der
mv hash otabootbeta.bin.sig
printf "%08x" `cat otabootbeta.bin | wc -c`| xxd -r -p >>otabootbeta.bin.sig
cat sign >>otabootbeta.bin.sig
rm sign
```
- otaboot.bin
```
[path to ecc_signer]/ecc_signer otaboot.bin [secret place]/secp384r1prv.der [secret place]/secp384r1pub.der
mv hash otaboot.bin.sig
printf "%08x" `cat otaboot.bin | wc -c`| xxd -r -p >>otaboot.bin.sig
cat sign >>otaboot.bin.sig
rm sign
```
- otamain.bin
```
[path to ecc_signer]/ecc_signer otamain.bin [secret place]/secp384r1prv.der [secret place]/secp384r1pub.der
mv hash otamain.bin.sig
printf "%08x" `cat otamain.bin | wc -c`| xxd -r -p >>otamain.bin.sig
cat sign >>otamain.bin.sig
rm sign
```
#
- Test otaboot for basic behaviour
- Commit and sync submodules
- Commit and sync this as version 2.2.5
- Set up a new github release 2.2.5 as a pre-release using the just commited master...
- Upload the binaries and signatures to the pre-release assets on github
- Erase ESP flash
```
esptool.py -p /dev/cu.usbserial-* erase_flash
```
- Upload the ota-boot program to the device
```
esptool.py -p /dev/ttyUSB? write_flash -fs 4MB -ff 26m 0x0 [esp-open-rtos]/bootloader/firmware-prebuilt/rboot.bin 0x1000 [esp-open-rtos]/bootloader/firmware-prebuilt/blank_config.bin 0x2000 otaboot.bin
```
- power cycle to prevent the bug for software reset after flash  
- setup wifi and select the ota-demo repo without pre-release checkbox
- Test
- Once happy, continue with normal deployments


#### These are the steps if not introducing a new key pair
- create/update the file versions1/latest-pre-release without new-line and setup 2.2.5 version folder
```
mkdir versions1/2.2.5v
echo -n 2.2.5 > versions1/2.2.5v/latest-pre-release
cp versions1/certs.sector versions1/certs.sector.sig versions1/2.2.5v
cp versions1/public*key*   versions1/2.2.5v
```
- set local.mk to the ota-main program
```
make -j6 rebuild OTAVERSION=2.2.5
mv firmware/otamain.bin versions1/2.2.5v
```
- set local.mk back to ota-boot program
```
make -j6 rebuild OTAVERSION=2.2.5
mv firmware/otaboot.bin versions1/2.2.5v
make -j6 rebuild OTAVERSION=2.2.5 OTABETA=1
cp firmware/otaboot.bin versions1/2.2.5v/otabootbeta.bin
```
- remove the older version files
#
- update Changelog
- if you can sign the binaries locally, do so, else follow later steps
- test otaboot for basic behaviour
- commit and sync submodules
- commit and sync this as version 2.2.5  
- set up a new github release 2.2.5 as a pre-release using the just commited master...  
- upload the certs and binaries to the pre-release assets on github  
#
- erase the flash and upload the privatekey
```
esptool.py -p /dev/cu.usbserial-* --baud 230400 erase_flash 
esptool.py -p /dev/cu.usbserial-* --baud 230400 write_flash 0xf9000 versions1-privatekey.der
```
- upload the ota-boot BETA program to the device that contains the private key
```
make flash OTAVERSION=2.2.5 OTABETA=1
```
- power cycle to prevent the bug for software reset after flash  
- setup wifi and select the ota-demo repo without pre-release checkbox  
- create the 2 signature files next to the bin file and upload to github one by one  
- verify the hashes on the computer  
```
openssl sha384 versions1/2.2.5v/otamain.bin
xxd versions1/2.2.5v/otamain.bin.sig
```

- upload the file versions1/2.2.5v/latest-pre-release to the 'latest release' assets on github

#### Testing

- test the release with several devices that have the beta flag set  
- if bugs are found, leave this release at pre-release and start a new version
#
- if the results are 100% stable  
- make the release a production release on github  
- remove the private key  
```
esptool.py -p /dev/cu.usbserial-* --baud 230400 write_flash 0xf9000 versions1/blank.bin
```


### How to make a new signing key pair

- use the finder to duplicate the content from the previous versions folder => call it versions1  
- push all existing public-N.key.sig and public-N.key files one number up  
- e.g. if a public-2.key.sig already exists, this would then be renamed to public-3.key.sig etc...  
- rename the duplicated cert.sector to public-2.key
- note the new certs.sector is public-1.key but we never need to call it with that name  
- remove all the duplicates that will not change from the previous versions folder like blank.bin ...  
- note a public-N.key.sig is a signature on a certs.sector file, but using an older key  
- and certs.sector.sig is also a signature on a certs.sector file, but using its own key  
- there is no need to upload or even keep public-N.key for versionsN since it is never needed  
#
- make a new key pair
```
mkdir /tmp/ecdsa
cd    /tmp/ecdsa
openssl ecparam -genkey -name secp384r1 -out secp384r1prv.pem
openssl ec -in secp384r1prv.pem -outform DER -out secp384r1prv.der
openssl ec -in secp384r1prv.pem -outform DER -out secp384r1pub.der -pubout
cat    secp384r1prv.pem
xxd -p secp384r1pub.der
```
- capture the private key pem in a secret place and destroy .pem and .der from /tmp

- open certs.hex and replace the first 4 rows with the public key xxd output, then make the new certs.sector.
```
vi versions1/certs.hex; xxd -p -r versions1/certs.hex > versions1/certs.sector
```
- edit certs.h to not contain the trailing 0xff entries. make the length correct.
```
cd versions1; xxd -i certs.sector > ../certs.h; cd ..; vi certs.h
```
- start a new release as described above, but in the first run, use the previous private key in 0xf9000
```
esptool.py -p /dev/cu.usbserial-* --baud 230400 write_flash 0xf9000 versionsN-1-privatekey.der
```
- collect public-1.key.sig and store it in the new version folder and copy it to versions1
```
cp  versions1/2.2.5v/public-1.key.sig versions1
```
- then flash the new private key
```
esptool.py -p /dev/cu.usbserial-* --baud 230400 write_flash 0xf9000 versions1-privatekey.der
```
- collect cert.sector.sig and store it in the new version folder and copy it to versions1 
```
cp  versions1/2.2.5v/certs.sector.sig versions1
```
- continue with a normal deployment to create the 2 signature files next to the bin files
