#set this in local.mk
#PROGRAM = main

EXTRA_COMPONENTS = \
	extras/sntp \
	extras/http-parser \
	extras/dhcpserver \
    extras/rboot-ota \
	$(abspath esp-wifi-config) \
	$(abspath esp-wolfssl)

FLASH_SIZE ?= 4MB

EXTRA_WOLFSSL_CFLAGS = \
	-DWOLFSSL_USER_SETTINGS \
	-DWOLFSSL_STATIC_RSA \
	-DUSE_SLOW_SHA \
	-DUSE_SLOW_SHA2 \
	-DHAVE_AESGCM \
    -DHAVE_TLS_EXTENSIONS \
	-DHAVE_SNI \
	-DNO_MD5 \
	-DNO_FILESYSTEM \
	-DNO_WRITEV \
	-DNO_WOLFSSL_SERVER \
	-DNO_RABBIT \
	-DNO_DH \
	-DNO_PWDBASED \
	-DNO_DES3 \
	-DNO_ERROR_STRINGS \
	-DNO_OLD_TLS \
	-DNO_RC4 \
	-DNO_PSK \
	-DNO_MD4 \
	-DNO_HC128 \
	-DNO_DEV_RANDOM \
	-DNO_SESSION_CACHE \
    -DNO_DSA \
 	-DWOLFSSL_SHA512 \
 	-DWOLFSSL_SHA384 \
	-DHAVE_ECC \
	-DHAVE_ECC384 \
	-DHAVE_ECC_SIGN \
	-DHAVE_ECC_VERIFY \
	-DHAVE_ECC_KEY_IMPORT \
	-DHAVE_ECC_DHE \
	-DHAVE_SUPPORTED_CURVES \

#	-DDEBUG_WOLFSSL \

#   -DNO_SHA \
#	-DLARGE_STATIC_BUFFERS \
#	-DSTATIC_CHUNKS_ONLY \
#	-DRECORD_SIZE=1024 \
#	-DHAVE_ONE_TIME_AUTH \
#	-DNO_CODING \
#	-DNO_INLINE \
#	-DBUILD_TLS_RSA_WITH_AES_128_GCM_SHA256 \

esp-wolfssl_CFLAGS += $(EXTRA_WOLFSSL_CFLAGS)

EXTRA_CFLAGS += $(EXTRA_WOLFSSL_CFLAGS)
EXTRA_CFLAGS += -DTCP_MSS=1460 -DTCP_WND=2920

ifdef OTAVERSION
EXTRA_CFLAGS += -DOTAVERSION=\"$(OTAVERSION)\"
endif

ifdef OTABETA
EXTRA_CFLAGS += -DOTABETA
endif

EXTRA_CFLAGS += -DDEFAULT_SYSPARAM_SECTORS=0

#EXTRA_CFLAGS += -DLWIP_DEBUG
EXTRA_CFLAGS += -DDNS_TABLE_SIZE=2

include $(SDK_PATH)/common.mk

monitor:
	$(FILTEROUTPUT) --port $(ESPPORT) --baud 115200 --elf $(PROGRAM_OUT)
