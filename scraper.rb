#! /usr/bin/env ruby
# encoding: utf-8

#0
#import de Java
#include de C
require 'pathname'
require 'mechanize'

# Controla que s'estiguin passant dos paràmetres
#Equivalent a if (ARGV.length != 2) { System.out.println("Cal l'usuari i el password");System.exit(-1);}
abort "Cal l'usuari i el password" if ARGV.length != 2

#1Creem el path, la url
campus_uri = Pathname.new('http://iesriberabaixa.cat/campusvirtual')
login_uri = campus_uri.join('login/index.php')
#Podem pintar la variable
#puts login_uri.inspect


#2agafem pagina login
scraper = Mechanize.new
scraper.get(login_uri) do |page|
  #Per pintar la pàgina HTML que ens està 
  puts  page.search('/').to_xml
  # Investigant la pàgina de login es veu que el formulari de login
  # té com a `action` la mateixa URI que a la que estem accedint.
  # El camp de nom d'usuari s'anomena `username` i el camp de contrasenya
  # `password`.
  #
  # Per tant, seleccionem el formulari pel seu `action`, assignem el primer
  # argument al camp `username` i el segon al camp `password`. Finalment
  # executem el submit del formulari que ens autentica al Moodle.
  #
  # Assignant el resultat de l'autenticació a la variable `main_page` ens assegura
  # que podem seguir la navegació a partir d'aquí.
  main_page = page.form_with(:action => login_uri.to_s) do |f|
    f.username = ARGV[0]
    f.password = ARGV[1]
  end.submit

#3Entrem a la pàgina del taller
  # Seleccionem l'enllaç amb el text començant per “Ruby” i assignem la pàgina resultant
  # a la variable ruby.
  course = main_page.links.find { |link| link.text.match(/Ruby/) }.click
  #puts course.links.inspect

#4Entrem als documents 
  # Seleccionem l'enllaç amb el text “Fitxers” i assignem la pàgina resultant
  # a la variable `m4_files`.
  course_files = course.links.find { |link| link.text.match(/Documents/) }.click
  # Generem un Array on cada element és un Hash amb la forma:
  #     {
  #       :name => nom_del_fitxer,
  #       :url => url_del_fitxer,
  #       :size => tamany_del_fitxer,
  #       :date => data_de_modificació
  #     }
  files = course_files.search('//tr[@class = "file"]').map do |row|
    {
      # elimina el primer caràcter, un espai (U+160) que no elimina el mètode strip
      :name => row.search('td[1]/a').first.content.strip.sub(%r{^.}, ''),
      :url => row.search('td[1]/a/@href').to_s.strip,
      :size => row.search('td[3]').first.content.strip,
      :date => row.search('td[4]').first.content.strip
    }
  end

  # @@TODO@@ Fem quelom amb els fitxers
  # mkdir -p (només el crea si no existeix)	
  
  FileUtils.mkdir_p 'downloads'
  #files.each = for i = file
  files.each do |file|
    scraper.get(file[:url]).save(Pathname.new('downloads').join(file[:name]))
  end
end
