DART_PATH	=../../dart-sdk/bin/frogc
OPTIONS		=--enable_type_checks --enable_asserts

code:
	cd proj && ${DART_PATH} ${OPTIONS} demo.dart && mv *.js ../deploy
units:
	cd test && ${DART_PATH} ${OPTIONS} test.dart && mv *.js ../deploy

deploy:	deploy_code

deploy_code:
	cd stage && ./upload.sh code.txt
deploy_envir:
	cd stage && ./upload.sh envir.txt
deploy_shaders:
	cd stage && ./upload.sh shaders.txt
deploy_models:
	cd stage && ./upload.sh models.txt
deploy_armatures:
	cd stage && ./upload.sh armatures.txt

release:
	cd stage && ./upload.sh release.txt
