#!/bin/bash

function install_dependency() {
	yum install -y libtool > /dev/null
	yum install -y PyYAML > /dev/null
	yum install -y python-markupsafe > /dev/null
	yum install -y python-jinja2 > /dev/null
	yum install -y m2crypto > /dev/null
	yum install -y python-cherrypy > /dev/null
	yum install -y MySQL-python > /dev/null
	yum install -y net-tools > /dev/null
}

function libzmq_installed() {
	[ -f /usr/local/lib/libzmq.so.5.1.4 ]
}

function build_libzmq() {
	if libzmq_installed; then
		echo "libzmq already installed."
		return
	fi

	if [ ! -d libzmq ]; then
		git clone git://github.com/zeromq/libzmq.git
	fi

	pushd libzmq
	./autogen.sh &&
	./configure &&
	make -j64 &&
	make check &&
	make install
	popd
}

function pyzmq_installed() {
	pip2 list | grep pyzmq > /dev/null 2>&1
}

function build_pyzmq() {
	if pyzmq_installed; then
		echo "pyzmq already installed."
		return
	fi

	if [ ! -d pyzmq-17.0.0b3 ]; then
		if [ ! -f pyzmq-17.0.0b3.tar.gz ]; then
			wget https://pypi.python.org/packages/b6/ba/7b4d65f104d3371761a268f3a6e9b5a18ddd255af1ffc0af425e7039e307/pyzmq-17.0.0b3.tar.gz
		fi
		tar xf pyzmq-17.0.0b3.tar.gz
	fi

	pushd pyzmq-17.0.0b3
	python setup.py install
	popd
}

function msgpack_installed() {
	pip2 list | grep msgpack > /dev/null 2>&1
}

function build_msgpack() {
	if msgpack_installed; then
		echo "msgpack already installed."
		return
	fi

	if [ ! -d msgpack-0.5.1 ]; then
		if [ ! -f msgpack-0.5.1.tar.gz ]; then
			wget https://pypi.python.org/packages/45/03/642e1e8e154e26ea1561c275960edee95d28fd0d95b60556bf8d73d7ce7b/msgpack-0.5.1.tar.gz
		fi
		tar xf msgpack-0.5.1.tar.gz
	fi
	pushd msgpack-0.5.1
	python setup.py install
	popd
}

function pycrypto_installed() {
	pip2 list | grep pycrypto > /dev/null 2>&1
}

function build_pycrypto() {
	if pycrypto_installed; then
		echo "pycrypto already installed."
		return
	fi

	if [ ! -d pycrypto-2.6.1 ]; then
		if [ ! -f pycrypto-2.6.1.tar.gz ]; then
			wget https://pypi.python.org/packages/60/db/645aa9af249f059cc3a368b118de33889219e0362141e75d4eaf6f80f163/pycrypto-2.6.1.tar.gz
		fi
		tar xf pycrypto-2.6.1.tar.gz
	fi
	pushd pycrypto-2.6.1
	python setup.py install
	popd
}

function tornado_installed() {
	pip2 list | grep tornado > /dev/null 2>&1
}

function build_tornado() {
	if tornado_installed; then
		echo "tornado already installed."
		return
	fi

	if [ ! -d tornado-4.5.3 ]; then
		if [ ! -f tornado-4.5.3.tar.gz ]; then
			wget https://pypi.python.org/packages/e3/7b/e29ab3d51c8df66922fea216e2bddfcb6430fb29620e5165b16a216e0d3c/tornado-4.5.3.tar.gz
		fi
		tar xf tornado-4.5.3.tar.gz
	fi
	pushd tornado-4.5.3
	python setup.py install
	popd
}

function salt_installed() {
	pip2 list | grep salt > /dev/null 2>&1
}

function config_salt_master() {
	cp conf/master /etc/salt/
	sed -i "s/^\#auto_accept:.*/auto_accept: True/g" /etc/salt/master
	sed -i "s/^\#interface: 0.0.0.0/interface: 192.168.1.201/g" /etc/salt/master

	cp pkg/salt-master.service /lib/systemd/system/
	#systemctl start salt-master
}

function config_salt_minion() {
	cp conf/minion /etc/salt/
	sed -i "s/^\#master: salt/master: 192.168.1.201/g" /etc/salt/minion
	sed -i "s/^#id:/id: minion-10-01/g" /etc/salt/minion

	cp pkg/salt-minion.service /lib/systemd/system/
	#systemctl start salt-minion
}

function build_salt() {
	if salt_installed; then
		echo "salt already installed."
		return
	fi

	if [ ! -d salt-2017.7.2 ]; then
		if [ ! -f salt-2017.7.2.tar.gz ]; then
			wget https://pypi.python.org/packages/9e/0d/46336f0b60ba51bbecf91ad401b90f691683fd37b7a18e421198406a7c19/salt-2017.7.2.tar.gz
		fi
		tar xf salt-2017.7.2.tar.gz
	fi
	pushd salt-2017.7.2
	python setup.py install &&
	mkdir -p /etc/salt
	if [ $1 = "master" ]; then
		config_salt_master
	else
		config_salt_minion
	fi
	popd
}

##############################################################

uid=`id -u`
if (( $uid )); then
	echo "need root privilege"
	return
fi

install_dependency
build_libzmq
build_pyzmq
build_msgpack
build_pycrypto
build_tornado
build_salt minion
