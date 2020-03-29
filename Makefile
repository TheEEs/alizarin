build: libextension.so
	mv ./libextension.so ./webExtensions/libextension.so
libextension.so: 
	mkdir -p ./webExtensions
	crystal build  --single-module --link-flags="-shared -fpic"  -o libextension.so ./webExtensions/extension.cr
