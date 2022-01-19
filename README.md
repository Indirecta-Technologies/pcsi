# pcsi
Open source command line for Indirecta Xinu HSE
Note: This is an execution file/program/application for the Indirecta Xinu HSE platform. This program is free open source software, while the Xinu HSE Platform is a licensed, obfuscated, paid software that costs 60R$, if you are contributing to this project, you can either buy the license and develop directly on Xinu, or make changes that will be tested by me (Lxi099 or FireAlarmManBeta)

Pcsi uses a file system similiar to Block OS' file system. In fact, it is a modification of the module, named xfsm. It can currently compress(?) files, make directories, make files, change current working directory, rename files, delete files, read files, write files, append to files, with last edit, creation date, name, and mode, that can be changed using the chmod command. Soon it could support encryption (AES256)

Xfsm may soon potentially gather a file type, by using string matching --

Commands are similiar if not identical to Unix, with implementations in lua:
- date command
- hexdump
- luajit
- luadbg
- luac
- brainfudge
- http (imitates curl, soon)
- and more

Pcsi has luac included, which is a command that can compile luau source files (usually ending in .luau) into compiled bytecode files (usually ending in .luac), it can also load .luac files, and also strip debug information before compiling, all in a limited environment, all thanks to FiOne, LuaDbg, and Yueliang (luac) in the lib folder.

