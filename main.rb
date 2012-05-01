require 'sinatra'
require 'sinatra/reloader'
require 'builder'
require 'alexander'
use Rack::Lint
use Alexander::XslProcessor
use Rack::Lint

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

  Rack::Response.new([result], 200, {"Content-Type" => "application/xslt+xml"})
end

get "/*" do
  headers["Content-type"] = "text/plain"
  agent = UserAgent.parse(env["HTTP_USER_AGENT"])
  "#{env.inspect}\n\n#{env["HTTP_USER_AGENT"]}\n#{agent.browser} #{agent.version}"
end
