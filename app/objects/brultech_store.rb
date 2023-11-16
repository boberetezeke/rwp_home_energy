require 'json'

class Obj::BrultechStore < Obj::Store
  def initialize(db, directory)
    super()
    @db = db
    @directory = directory
  end

  def sync
    brultech_readings = []
    power_circuits = {}

    update_readings(@directory, ->(str){ puts "LOG: #{str}"})

    Dir["#{@directory}/*"].each.with_index  do |fn, index|
      m = /(\d+)-(\d+)-(\d+)\.json/.match(fn)
      next unless m

      puts "processing: #{index}"
      json = JSON.parse(File.read(fn))
      date = json['date']
      json['readings'].each do |key, value|
        power_circuit_name = key.strip
        m_kwh = /(\d+(\.\d+)) kWh/.match(value)
        if m_kwh
          kwh = m_kwh[1].to_f
        else
          kwh = 0.0
        end
        brultech_reading = Obj::BrultechReading.new(kwh, date)
        power_circuit = power_circuits[power_circuit_name]
        power_circuit = Obj::PowerCircuit.new(power_circuit_name) unless power_circuit

        brultech_reading.power_circuit = power_circuit
        brultech_readings.push(brultech_reading)
      end
    end

    puts "Brultech readings: #{brultech_readings.size}"
    brultech_readings.each.with_index do |brultech_reading, index|
      db_power_circuit = find_or_add_power_circuit(brultech_reading.power_circuit) if brultech_reading.power_circuit
      db_brultech_reading = find_or_add_brultech_reading(brultech_reading, status_proc: status_proc)
      db_brultech_reading.power_circuit = db_power_circuit
    end

    nil
  end

  def update_readings(directory, status_proc)
    Obj::Scraper.scrape(readings_dir: directory, status_proc: status_proc)
  end

  def find_or_add_brultech_reading(brultech_reading, status_proc: nil)
    db_brultech_reading = @db.find_by(:brultech_reading, {
      date: brultech_reading.date,
      power_circuit_id: brultech_reading.power_circuit_id
    })
    if db_brultech_reading
      db_brultech_reading.update(brultech_reading)
    else
      db_brultech_reading = brultech_reading.dup
      @db.add_obj(db_brultech_reading)
    end
    db_brultech_reading
  end

  def find_or_add_power_circuit(power_circuit, status_proc: nil)
    db_power_circuit = @db.find_by(:power_circuit, {
      name: power_circuit.name
    })
    if !db_power_circuit
      db_power_circuit = power_circuit.dup
      @db.add_obj(db_power_circuit)
    end
    db_power_circuit
  end
end
