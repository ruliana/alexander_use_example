require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'minitest/colorize'
require_relative '../lib/xml_to_html'

class DummyApp
  attr_accessor :xml, :xsl

  def initialize
    self.xml = [
      200, {"Content-type" => "application/xml"}, <<-XML
<?xml version="1.0" encoding="utf-8"?>
<?xml-stylesheet type="text/xsl" href="teste.xsl"?>
<root />
      XML
    ]
    self.xsl = [
      200, {"Content-type" => "application/xslt+xml"}, <<-XSL
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <html><body></body></html>
  </xsl:template>
</xsl:stylesheet>
      XSL
    ]
  end

  def call(env)
    if env["REQUEST_PATH"] =~ /.*\.xsl/
      xsl
    else
      xml
    end
  end
end

CHROME_18 =  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.19 (KHTML, like Gecko) Ubuntu/11.10 Chromium/18.0.1025.151 Chrome/18.0.1025.151 Safari/535.19"
FIREFOX_1 = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/1.0"

describe XmlToHtml do

  def env_with_chrome
    {"HTTP_USER_AGENT" => CHROME_18}
  end

  def env_with_firefox
    {"HTTP_USER_AGENT" => FIREFOX_1}
  end

  before do
    @dummy_app = DummyApp.new
    @filter = XmlToHtml.new(@dummy_app)
  end

  def app
    @filter
  end

  describe "when response is NOT XML" do
    it "should pass the response as is" do
      @dummy_app.xml = [200, {"Content-type" => "text/html"}, "<html></html>"]
      response = @filter.call(env_with_chrome)
      response.must_equal @dummy_app.xml
    end
  end

  describe "when response is XML" do
    describe "when request came from a XSLT enable browser" do
      it "should let response as is" do
        response = @filter.call(env_with_chrome)
        response.must_equal @dummy_app.xml
      end
    end
    describe "when request came from a XSLT NOT enable browser" do
      it "should parse XML to HTML" do
        response = @filter.call(env_with_firefox)
        response[0].must_equal 200
        response[1]["Content-type"].must_equal "text/html"
        response[2].must_equal "<html><body></body></html>\n"
      end
    end
    describe "when response is a XML without stylesheet" do
      it "should let response as is" do
        @dummy_app.xml = [200, {"Content-type" => "application/xml"}, <<-XML
<?xml version="1.0" encoding="utf-8"?>
<root />
        XML
        ]
        response = @filter.call(env_with_firefox)
        response.must_equal @dummy_app.xml
      end
    end
  end
end

