DART_PATH	=../../dart-sdk/bin/frogc
OPTIONS		=--enable_type_checks --enable_asserts
ENTRY_PATH	=test.dart

all:
	cd proj && ${DART_PATH} ${OPTIONS} ${ENTRY_PATH}
deploy:	deploy_code

deploy_code:
	cd stage && ./upload.sh code.txt
deploy_shaders:
	cd stage && ./upload.sh shaders.txt
deploy_models:
	cd stage && ./upload.sh models.txt
