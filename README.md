# o3d3xx Ruby library

Ruby libray and tools for the ifm Efector O3D3xx series of Time of Flight (ToF) Cameras
This library adds support for the following interfaces:

- XML-RPC, provides an interface for camera configuration and set-up
- PCIC, provides result data and images
- SWUpdate, provides software updates

## Installation

Add this line to your application's Gemfile:

    gem 'o3d3xx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install o3d3xx

## Usage

### PCIC Client
The PCIC is the propritary process interface which is based on TC/IP

```
pcic = O3D3XX::PCIC.new()
pcic.connect('172.25.125.26','50010')
pcic.transfer('p0')
pcic.async_trigger()
```

### Firmware Update

This assumes the device is already bootet in swupdate mode

```
o3d3xx-fwupdate.rb -f ~/Downloads/Goldeneye_1.5.205-unstable.swu -I 172.25.125.26 -r
```
The possible command line options are:
```
Usage: o3d3xx-fwupdate.rb [options]
    -f, --file SWU-IMG               Image file to upload
    -r, --reboot                     Force reboot to productive mode after all other action
    -I, --ip-addr IP-ADDR            Set TCP/IP address of target
    -p, --start-productive           Start productive system only without uploading file
    -h, --help                       Display this help message
```


## Contributors

* [Christian Ege](https://github.com/graugans/)
* [Daniel Schnell](https://github.com/lumpidu)
* [Christoph Freundl](https://github.com/cfreundl)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
