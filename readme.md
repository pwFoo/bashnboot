# Bash 'n Boot
Extremely minimal Busybox/Linux distribution in a few short bash functions.
```
$ mkdir build
$ cd build
$ ../bashnboot.sh
$ qemu-system-x86_64 -cdrom bashnboot.iso
```

### Optionally
From within your build directory you can create a .env file such as:
```
$ cat > .env << EOL
# Change the busybox version downloaded and compiled.
BUSYBOX="1.25.0"

# Change the Linux kernel version downloaded and compiled.
KERNEL="4.6.5"

# Number of compile jobs used when compiling the above.
JOBS="9"

# Change the resulting iso name (${NAME}.iso)
NAME="bashnboot"
EOL
```
## TODO
- [ ] Support rebuilding.
- [ ] More documentation.
- [ ] Add more options for configuring, cpu arch? init override? mirrors?
