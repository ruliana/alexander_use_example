require 'rack'
require 'useragent'
require 'nokogiri'

Browser = Struct.new(:browser, :version)

XSLT_ENABLE_BROWSERS = [
  Browser.new("Chrome", "1.0"),
  Browser.new("Firefox", "3.0"),
  Browser.new("Internet Explorer", "6.0"),
  Browser.new("Opera", "9.0"),
  Browser.new("Safari", "3.0")
]

class XmlToHtml
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    return [status, headers, body] unless xml?(headers)
    return [status, headers, body] if xlst_enable_browser?(env)

    html_response = to_html(env, body)
    return [status, headers, body] unless html_response

    headers["Content-type"] = "text/html"
    Rack::Response.new([html_response], status, headers).finish
  end

  def xml?(headers)
    headers["Content-Type"] =~ /\bapplication\/xml\b/
  end

  def xlst_enable_browser?(env)
    return false unless env && env["HTTP_USER_AGENT"]
    user_agent = UserAgent.parse(env["HTTP_USER_AGENT"])
    XSLT_ENABLE_BROWSERS.detect { |browser| user_agent >= browser }
  end

  def to_html(env, body)
    xml = body_to_string(body)
    xslt_request = detect_xslt_processing_instruction(xml)
    return unless xslt_request

    ask_xslt = env.dup
    ask_xslt["PATH_INFO"] = xslt_request
    ask_xslt["REQUEST_PATH"] = xslt_request
    ask_xslt["REQUEST_URI"] = xslt_request
    ask_xslt["QUERY_STRING"] = ""
    status, headers, xslt = @app.call(ask_xslt)
    return unless status == 200

    xml_parsed = Nokogiri::XML(xml)
    xsl_parsed = Nokogiri::XSLT(body_to_string(xslt))
    xsl_parsed.transform(xml_parsed).to_s
  end

  def detect_xslt_processing_instruction(xml)
    match = xml.match(/<\?xml-stylesheet.*href="([^"]+)"/)
    return match[1] if match
  end

  def body_to_string(body)
    result = ""
    body.each { |it| result << it }
    body.close if body.respond_to? :close
    result
  end
end
