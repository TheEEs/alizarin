require "./spec_helper"

describe WebView do
  it "writes body innerHTML to a file using native function" do
    script_finish = CHANNEL.receive
    JSC.is_string(script_finish).should be_truthy
    path = String.new JSC.to_string(script_finish)
    script_finish = CHANNEL.receive
    JSC.is_string(script_finish).should be_truthy
    inner_html = String.new JSC.to_string script_finish
    File.exists?(path).should be_truthy
    file_content = File.read path
    file_content.should eq inner_html
  end
end

exit 0
