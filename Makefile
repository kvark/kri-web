DART_PATH	=../dart/dart
PAGE_PATH	=code/test.html

all:
	python ${DART_PATH}/client/tools/htmlconverter.py ${PAGE_PATH} -o out/
