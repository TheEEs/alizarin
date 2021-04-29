require "./spec_helper"
require "socket"
require "colorize"
require "json"

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

  it "asserts value of namedTupleToJSC" do
    eval_js "JSON.stringify(namedTupleToJSC())"
    ret = String.new JSC.to_string(script_result)
    {
      age:   21,
      songs: [
        {
          name: "A song of ice and fire",
        },
      ],
    }.to_json.should eq ret
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

describe "JSCClass" do
  it "works" do
    eval_js <<-JS
      var file_reader = new MyFileReader("./LICENSE");
      file_reader.read_content();
    JS
    ret = String.new JSC.to_string script_result
    ret.should eq File.read("./LICENSE")
  end
end

describe WebExtension::Chainable do
  it "works" do
    eval_js <<-JS
      var me = new Person();
      me.set_name("TheEEs").greet();
    JS
    ret = String.new JSC.to_string script_result
    ret.should eq "Hello TheEEs"
  end
end

describe Future do
  it "thenable works" do
    eval_js <<-JS
      var future = new Future(function(resolve,reject){
        var file_reader = new MyFileReader("./LICENSE");
        resolve(file_reader.read_content());
      }).then((value)=>{
        console.log(value);
        window.returned_value = value;
      });
      true;
    JS
    script_result
    sleep 0.5
    eval_js <<-JS
      window.returned_value;
    JS
    ret = String.new JSC.to_string script_result
    ret.should eq File.read("./LICENSE")
  end

  it "catch works" do
    eval_js <<-JS
      window.returned_value = undefined;
      var future = new Future(function(resolve,reject){
        var file_reader = new MyFileReader("./LICENSE");
        resolve(file_reader.read_content());
      }).then(function(file_content, resolve, reject){
        reject(file_content);
      }).catch(function(value){
        window.returned_value = value;
      });
      true;
    JS
    script_result
    sleep 0.5
    eval_js <<-JS
      window.returned_value;
    JS
    ret = String.new JSC.to_string script_result
    ret.should eq File.read("./LICENSE")
  end

  it "chain of thens works" do
    eval_js <<-JS
      window.returned_value = undefined;
      var future = new Future(function(resolve,reject){
        var file_reader = new MyFileReader("./LICENSE");
        resolve(file_reader.read_content());
      }).then(function(file_content, resolve, reject){
        resolve(file_content);
      }).then(function(file_content){
        console.log(file_content);
        window.returned_value = file_content;
      });
      true;
    JS
    script_result
    sleep 0.5
    eval_js <<-JS
      window.returned_value;
    JS
    ret = String.new JSC.to_string script_result
    ret.should eq File.read("./LICENSE")
  end

  it "if a then does not resolve , later callbacks will not be executed" do
    eval_js <<-JS
      window.returned_value = undefined;
      var future = new Future(function(resolve,reject){
        var file_reader = new MyFileReader("./LICENSE");
        resolve(file_reader.read_content());
      }).then(function(file_content, resolve, reject){
        //resolve(file_content);
      }).then(function(file_content){
        window.returned_value = file_content;
      });
      true;
    JS
    script_result
    sleep 0.5
    eval_js <<-JS
      window.returned_value;
    JS
    ret = String.new JSC.to_string script_result
    ret.should eq "undefined"
  end
end
