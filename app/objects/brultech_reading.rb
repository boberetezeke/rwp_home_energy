class Obj::BrultechReading < Obj
  belongs_to :power_circuit, :power_circuit_id, inverse_of: :brultech_readings

  def self.default_display
    {
      sym_sets: {
        default: [:id,
                  :kwh,
                  :date,
                  { circuit: [:power_circuit, :name] }
        ]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        kwh: { width: 20, type: :float, title: 'KWh' },
        date: { width: 20, type: :date, title: 'Date' }
      }
    }
  end

  def initialize(kwh, date)
    super(:brultech_reading, {
      kwh: kwh,
      date: date
    })
  end
end
