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

## PCIC Client
The PCIC is the propritary process interface which is based on TC/IP

```
pcic = O3D3XX::PCIC.new()
pcic.connect('172.25.125.26','50010')
pcic.transfer('p0')
pcic.async_trigger()
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
