require "../spec_helper"
require "socket"
require "colorize"
require "json"

describe StdLib::Task do
  it "exists" do
    eval_js <<-JS
        typeof(window["StdLib::Task"])
    JS
    ret = String.new JSC.to_string script_result
    ret.should eq "function"
  end

  it "works" do
    eval_js <<-JS
        var a = new MyFileReader("README.md");
        var task = a.read_content_async();
        var message = "";
        while(!(message = task.await())); //uses `task.yield();` if build without -Dpreview_mt
        message;
    JS
    msg = String.new JSC.to_string script_result
    msg.should eq File.read("README.md")
  end
end
