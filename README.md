# Messagry

This is a fork of the [Relay](https://github.com/agronick/Relay) project,
which is not maintained anymore.

Messagry is an IRC client that attemps to be small, quick, easy to use, elegant, and functional.

![screenshot](http://bit.ly/1M6dYGZ)

## Installation

### Building from source

Install the following dependencies (on Ubuntu-based distros):

`libtool-bin libtool libgtk-3-dev libgee-0.8-dev libsqlite3-dev libgranite-dev valac-0.26 libx11-dev libglib2.0-dev automake libunity-dev`

Now execute the following commands:

```
mkdir build
cd build
../autogen.sh
make
sudo make install
```

## License

This project is licensed under the [GPL-2.0](LICENSE) license.

## Contributors
[Erazem Kokot](https://erazem.eu) - Current maintainer

[Kyle Agronick](https://poisonpacket.wordpress.com/) - Original author
