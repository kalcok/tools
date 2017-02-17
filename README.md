# tools
Stuff that is usefull but does not justify its own repository. List of available tools:  
* fwloader.sh - script that loads your new firewall configuratio and in case you get locked out, it will load backup config or open firewall wide open
* init_go.sh - script that initializes git-ready golang project in directory you are curently in. Initialization includes:
  * Create pkg and bin and src directories with proper .gitignore
  * Create setup file that you cen `source` to setup GOPATH env variable
