require "./spec_helper"
require "socket"
require "colorize"

describe WebView do
  it "writes body innerHTML to a file using native function" do
    WEBVIEW.load_url "https://crystal-lang.org"
    path = "./htmlBody.txt"
    wait_for_page_fully_loaded
    eval_js "writeHTMLBodyToFile('#{path}')"
    result = script_result
    JSC.is_string(result).should be_truthy
    eval_js "document.body.innerHTML"
    result = script_result
    JSC.is_string(result).should be_truthy
    innerHTML = String.new JSC.to_string result
    fileContent = File.read path
    innerHTML.should eq fileContent
  end

  it "loads raw html" do
    WEBVIEW.load_html <<-HTML
      <h1>Hello</h1>
    HTML
    wait_for_page_fully_loaded
    eval_js "document.body.innerHTML"
    result = script_result
    JSC.is_string(result).should be_truthy
    innerHTML = String.new JSC.to_string result
    innerHTML.should eq "<h1>Hello</h1>"
  end

  it "read page's title using WebView#execute_javascript(js,block)" do
    channel = Channel(String).new
    WEBVIEW.load_url "http://example.com"
    wait_for_page_fully_loaded
    WEBVIEW.execute_javascript "document.title" do |title|
      t = String.new JSC.to_string title
      channel.send t
    end
    channel.receive.should eq "Example Domain"
  end

  it "should get an array from function call to getArray" do
    eval_js "getArray()"
    ret = script_result
    JSC.is_array(ret).should be_truthy
    String.new(JSC.to_string(ret)).should eq "1,2,3,5"
  end

  it "plays with object's accessor" do
    number = 120
    eval_js "my_object.number = #{number}"
    script_result
    eval_js "my_object.number"
    ret = script_result
    JSC.is_number(ret).should be_truthy
    JSC.to_int32(ret).should eq number
    eval_js "my_object.number = 'Hello'"
    script_result
    eval_js "my_object.number"
    ret = script_result
    JSC.is_null(ret).should be_truthy
  end

  it "my_object.string should eq to 'hello'" do
    eval_js "my_object.string"
    ret = script_result
    String.new(JSC.to_string(ret)).should eq "hello"
  end

  it "should get my birthday code" do
    eval_js "my_birthday_code"
    ret = script_result
    JSC.is_object(ret).should be_truthy
    JSC.to_int32(ret).should eq 7498
  end

  it "test_eval function should return 2" do
    eval_js "test_eval()"
    ret = script_result
    JSC.to_int32(ret).should eq 2
  end

  it "should get IPC message via JavaScript call" do
    WEBVIEW.execute_javascript "ipc('Hello')" { }
    value = IPC_CHANNEL.receive
    value.should eq "Hello"
    WEBVIEW.stop_ipc
    File.exists?(WebView.ipc_socket_file_path(WEBVIEW.uuid.hexstring)).should be_falsey
  end
end
