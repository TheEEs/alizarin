require "./spec_helper"

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
end

exit 0
