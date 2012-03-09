DART_PATH	=../../dart-sdk/bin/frogc
OPTIONS		=--enable_type_checks --enable_asserts
ENTRY_PATH	=test.dart

all:
	cd proj && ${DART_PATH} ${OPTIONS} ${ENTRY_PATH}

deploy:
	cd stage && ./upload.sh code.txt
