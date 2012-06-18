DART_PATH	=../../dart-sdk/bin/dart2js -c

code:
	cd app	&& ${DART_PATH} demo.dart -o../deploy/demo.dart.js
units:
	cd test	&& ${DART_PATH} test.dart -o../deploy/test.dart.js

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

validate_xml:
	cd deploy/schema && ./validate.sh

release:
	cd stage && ./upload.sh release.txt
