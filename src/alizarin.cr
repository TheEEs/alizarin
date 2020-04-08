require "colorize"
require "uuid"
require "socket"
require "./libs/**"
require "./components/**"

module Alizarin
  VERSION = `shards version #{__DIR__}/../`
end
