DART_PATH	=/Volumes/MacExtra/Applications/dart/dart-sdk/bin/frogc
ENTRY_PATH	=test.dart

all:
	cd proj && ${DART_PATH} ${ENTRY_PATH}

deploy:
	cd stage && ./upload.sh code.txt
