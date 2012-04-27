require 'sinatra'
require 'builder'
require 'sinatra/reloader'

get '/teste.xml' do
  builder do |xml|
    xml.instruct!
    xml.instruct! :"xml-stylesheet", type: "text/xsl", href: "teste.xsl"
    xml.teste do
      xml.wakka "Ronie"
    end
  end
end

get '/teste.xsl' do
  builder do |xsl|
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
end
