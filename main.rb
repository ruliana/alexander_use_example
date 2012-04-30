require 'sinatra'
require 'sinatra/reloader'
require 'builder'
require_relative './lib/xml_to_html.rb'
use XmlToHtml

def get_url(url)
  self.call(
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => url,
    'rack.input' => StringIO.new
  )[2].join('')
end

def get_xml(url)
  Nokogiri::XML(get_url(url))
end

def get_xsl(url)
  Nokogiri::XSLT(get_url(url))
end

get '/teste.html' do
  xml = get_xml("/teste.xml")
  processing_instruction = xml.children[0].to_s
  if processing_instruction =~ /^<\?xml-stylesheet /
    xsl_path = processing_instruction.match(/href="([^"]+)"/)[1]
    get_xsl(xsl_path).transform(xml).to_xml
  else
    [200, {"Content-type" => "application/xml"}, xml.to_xml]
  end
end

get '/teste.xml' do
  builder do |xml|
    xml.instruct!
    xml.instruct! :"xml-stylesheet", type: "text/xsl", href: "/teste.xsl"
    xml.teste do
      xml.wakka "Ronie"
    end
  end
end

get '/teste.xsl' do
  result = builder do |xsl|
    xsl.instruct!
    xsl.xsl :stylesheet, version: "1.0", :"xmlns:xsl" => "http://www.w3.org/1999/XSL/Transform" do |s|
      s.xsl :output, method: "html", indent: "yes"
      s.xsl :template, match: "/" do
        s.html do
          s.head do
            s.title "Teste"
          end
          s.body do
            s.h1 do
              s.xsl :"value-of", select: "teste/wakka"
            end
          end
        end
      end
    end
  end

  [200, {"Content-type" => "application/xslt+xml"}, result]
end

get "/*" do
  headers["Content-type"] = "text/plain"
  agent = UserAgent.parse(env["HTTP_USER_AGENT"])
  "#{env.inspect}\n\n#{env["HTTP_USER_AGENT"]}\n#{agent.browser} #{agent.version}"
end
