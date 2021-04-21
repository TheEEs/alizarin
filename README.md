![alizarin.png](https://www.upsieutoc.com/images/2020/03/29/alizarin.png)

# Alizarin
![GitHub release (latest by date)](https://img.shields.io/github/v/release/TheEEs/alizarin?style=flat-square)
![LICENSE MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![CRYSTAL 1.0.0](https://img.shields.io/badge/crystal-1.0.0-orange?style=flat-square)
![webkit2gtk](https://img.shields.io/badge/webkit2gtk-4.0-blue?style=flat-square)


**Alizarin** is a Crystal shard that helps you build Linux GUI applications using Web Technologies (HTML5, CSS3, JavaScript). This shard also provides ability to extend JavaScript code with native functionalities.

## Examples
  [Markdown - A markdown editor written with Alizarin](https://github.com/TheEEs/markdown.git)

## Installation

* Add the dependency to your `shard.yml`:
```yaml
   dependencies:
     alizarin:
       github: TheEEs/alizarin
```
* Run `shards install`

NOTE: This shard requires `libwebkit2gtk-4.0` to be installed. Makes sure you have it installed into your system.

```shell
    $ sudo apt-get install -y libwebkit2gtk-4.0
```

## Usage

```crystal
require "alizarin"
```

* Open a browser window and load [Crystal Offical Website](https://crystal-lang.org/)
```crystal 
  require "alizarin"
  require "colorize"

  webview = WebView.new 

  webview.on_close |webview|
    puts "#{webview} is going to close".colorize :green
    exit 0
  end

  webview.default_size 800, 600
  webview.load_url "https://crystal-lang.org/

  webview.run

```

* Show WebInspector (in case if you want to play with page's source code)

```crystal 
  webview["enable-developer-extras"] = true
  webview.show_inspector
```


NOTE: There is also test cases located in `/spec` folder.

To run test case, types:
```shell
$ git clone https://github.com/TheEEs/alizarin
$ cd alizarin
$ make
$ crystal spec
```

See [Alizarin API](https://theees.github.io/alizarin-docs/) for more.

## Development

TODO: Write Development instructions here.


## Contributing

1. Fork it [https://github.com/TheEEs/alizarin/fork](https://github.com/TheEEs/alizarin/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [TheEEs](https://github.com/TheEEs) - creator and maintainer
