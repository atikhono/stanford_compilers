This repository stores my coursework on the Stanford Compilers course by Alex Aiken. Coursera page: http://www.coursera.org/course/compilers.

The course discusses the major ideas in the implementation of programming language compilers, including lexical analysis, parsing, syntax-directed translation, abstract syntax trees, types and type checking, intermediate languages, dataflow analysis, program optimization, code generation, and runtime systems. 

An optional course project is to write a complete compiler for COOL, the Classroom Object Oriented Language. COOL has the essential features of a realistic programming language, but is small and simple enough that it can be implemented in a few thousand lines of code. The course instructors provide the VirtualBox VM __compilers-vm__ with the environment in which to write the compiler.



**MY SETUP**

__Host:__ VirtualBox 4.3, Mas OS X, SSH-2.0-OpenSSH_6.2

__Guest:__ compilers-vm, Bodhi Linux, OpenSSH_5.3p1


1. Headless virtualbox run.
	```
	user@host$ VBoxManage -q startvm compilers-vm --type headless
    ```
    ```
	user@host$ VBoxManage -q controlvm compilers-vm (poweroff|savestate)
	```

2. Set up host port forwarding.
	```
	user@host$ VBoxManage modifyvm compilers-vm --natpf1 "ssh,tcp,,3022,,22"
	```

3. Install openssh-server on compilers-vm.
	```
	compilers@compilers-vm$ sudo apt-get install openssh-server
	```

4. OpenSSH troubleshooting.
	* Check host debug messages:
		```
		user@host$ ssh -p 3022 compilers@localhost -vvv
		```

	* Check if sshd is running and listening to port 22:
		```
		compilers@compilers-vm$ ps aux | grep sshd && netstat -ant | grep 22
		```

	* Check if the keys are good (permissions, size, etc):
		```
		compilers@compilers-vm$ ls -l /etc/ssh/ssh_host_*
		```

	* Check sshd messages:
		```
		compilers@compilers-vm$ /path/to/sshd -p 44
		```

5. Passwordless authentication. Generate a no-passphrase key on host using ssh-keygen. Insert the public key file contents into compilers-vm:~/.ssh/authorized_keys.