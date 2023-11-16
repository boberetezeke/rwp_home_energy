path = File.dirname(__FILE__)

load "#{path}/objects/brultech_reading.rb"
load "#{path}/objects/power_circuit.rb"

load "#{path}/objects/brultech_store.rb"

load "#{path}/services/scraper.rb"

Obj.classes[:brultech_reading] = Obj::BrultechReading
Obj.classes[:power_circuit] = Obj::PowerCircuit
Obj.classes[:brultech_store] = Obj::BrultechStore