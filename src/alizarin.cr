require "colorize"
require "./libs/**"
require "./web_view"
require "./js_object_utils"
require "./jsc_primative"
require "./jsc_object"
require "./jsc_function"
require "./jsc_context"
require "./web_extension"
require "./language_extensions/**"

module Alizarin
    VERSION = `shards version #{__DIR__}/../`
end