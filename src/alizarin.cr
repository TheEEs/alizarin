require "colorize"
require "uuid"
require "socket"
require "./libs/**"
require "./language_extensions/**"
require "./components/**"

module Alizarin
  VERSION = `shards version #{__DIR__}/../`
end
